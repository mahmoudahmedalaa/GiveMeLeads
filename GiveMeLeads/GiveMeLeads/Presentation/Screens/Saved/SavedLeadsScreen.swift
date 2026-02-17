import SwiftUI

/// Saved leads list screen
struct SavedLeadsScreen: View {
    @State private var viewModel = LeadFeedViewModel()
    @State private var csvFileURL: URL?
    @State private var showShareSheet = false
    @State private var showUpgradeAlert = false
    @State private var exportError: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .tint(AppColors.primary400)
                } else if viewModel.savedLeads.isEmpty {
                    EmptyStateView(
                        icon: "bookmark",
                        title: "No Saved Leads",
                        message: "Swipe right on leads in the\nfeed to save them here"
                    )
                } else {
                    savedList
                }
            }
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !viewModel.savedLeads.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: exportCSV) {
                            HStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export")
                                    .font(AppTypography.bodySmall)
                            }
                            .foregroundColor(AppColors.primary400)
                        }
                    }
                }
            }
            .task {
                await viewModel.fetchSavedLeads()
                // Also load profiles so we can show profile names
                do {
                    let repo = KeywordRepository()
                    viewModel.profiles = try await repo.fetchProfiles()
                } catch {}
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = csvFileURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Upgrade Required", isPresented: $showUpgradeAlert) {
                Button("OK") {}
            } message: {
                Text("CSV export is available on Starter and Pro plans.")
            }
            .alert("Export Error", isPresented: .constant(exportError != nil)) {
                Button("OK") { exportError = nil }
            } message: {
                Text(exportError ?? "")
            }
        }
    }
    
    private var savedList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.spacing3) {
                ForEach(viewModel.savedLeads) { lead in
                    NavigationLink(destination: LeadDetailScreen(
                        lead: lead,
                        onAction: { action in
                            Task {
                                switch action {
                                case .save: break // already saved
                                case .unsave: await viewModel.unsaveLead(lead)
                                case .dismiss: await viewModel.dismissLead(lead)
                                case .delete: await viewModel.deleteLead(lead)
                                case .contacted: await viewModel.markContacted(lead)
                                case .reply: break // handled by sheet in detail
                                }
                                // Refresh saved leads
                                await viewModel.fetchSavedLeads()
                            }
                        }
                    )) {
                        savedLeadRow(lead)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.spacing4)
            .padding(.bottom, AppSpacing.spacing12)
        }
    }
    
    private func savedLeadRow(_ lead: Lead) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing2) {
            HStack {
                if let score = lead.score {
                    ScoreBadge(score: score, size: .small)
                }
                
                Text("r/\(lead.subreddit)")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.primary400)
                
                if let name = viewModel.profileName(for: lead.profileId) {
                    Text(name)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, AppSpacing.spacing2)
                        .padding(.vertical, 2)
                        .background(AppColors.bg800)
                        .clipShape(Capsule())
                        .lineLimit(1)
                }
                
                Spacer()
                
                ChipView(lead.status.displayName, style: .status(lead.status))
            }
            
            Text(lead.title)
                .font(AppTypography.heading3)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(2)
            
            HStack {
                Text("u/\(lead.author)")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textTertiary)
                
                Spacer()
                
                Text(lead.postedAt.timeAgoDisplay())
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(AppSpacing.spacing4)
        .background(AppColors.bg700)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }
    
    // MARK: - CSV Export
    
    private func exportCSV() {
        let gateResult = GatingService.shared.canExportCSV()
        guard gateResult.isAllowed else {
            showUpgradeAlert = true
            return
        }
        
        do {
            csvFileURL = try CSVExportService.generateCSVFile(from: viewModel.savedLeads)
            showShareSheet = true
        } catch {
            exportError = "Failed to export: \(error.localizedDescription)"
        }
    }
}

#Preview {
    SavedLeadsScreen()
        .preferredColorScheme(.dark)
}
