import SwiftUI

struct LeadFeedScreen: View {
    @State private var viewModel = LeadFeedViewModel()
    @State private var showScanAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.leads.isEmpty {
                    EmptyStateView(
                        icon: "target",
                        title: "No Leads Yet",
                        message: "Set up keywords and scan Reddit\nto discover leads",
                        actionTitle: "Scan Now",
                        action: { triggerScan() }
                    )
                } else {
                    feedContent
                }
            }
            .navigationTitle("GiveMeLeads")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: AppSpacing.spacing3) {
                        // Scan button
                        Button(action: { triggerScan() }) {
                            if viewModel.isScanning {
                                ProgressView()
                                    .tint(AppColors.primary400)
                            } else {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .foregroundColor(AppColors.primary400)
                            }
                        }
                        .disabled(viewModel.isScanning)
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.fetchLeads()
            }
            .alert("Scan Complete", isPresented: $showScanAlert) {
                Button("OK") {}
            } message: {
                Text(viewModel.scanMessage ?? "Scan finished")
            }
        }
    }
    
    private func triggerScan() {
        Task {
            // Get access token from current session
            if let session = try? await SupabaseManager.shared.client.auth.session {
                await viewModel.scanForNewLeads(accessToken: session.accessToken)
                if viewModel.scanMessage != nil {
                    showScanAlert = true
                }
            }
        }
    }
    
    private var feedContent: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.spacing4) {
                // Scan message banner
                if let msg = viewModel.scanMessage {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.success)
                        Text(msg)
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppColors.success)
                        Spacer()
                        Button(action: { viewModel.scanMessage = nil }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                    .padding(AppSpacing.spacing3)
                    .background(AppColors.success.opacity(0.1))
                    .cornerRadius(AppRadius.sm)
                }
                
                // Error banner
                if let error = viewModel.error {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppColors.error)
                        Text(error)
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppColors.error)
                        Spacer()
                    }
                    .padding(AppSpacing.spacing3)
                    .background(AppColors.error.opacity(0.1))
                    .cornerRadius(AppRadius.sm)
                }
                
                ForEach(viewModel.leads) { lead in
                    NavigationLink(destination: LeadDetailScreen(
                        lead: lead,
                        onStatusChange: { newStatus in
                            Task {
                                switch newStatus {
                                case .saved:
                                    await viewModel.saveLead(lead)
                                case .dismissed:
                                    await viewModel.dismissLead(lead)
                                case .contacted:
                                    await viewModel.markContacted(lead)
                                default:
                                    break
                                }
                            }
                        }
                    )) {
                        LeadCardView(
                            lead: lead,
                            onSave: {
                                Task { await viewModel.saveLead(lead) }
                            },
                            onDismiss: {
                                Task { await viewModel.dismissLead(lead) }
                            },
                            onTap: {} // NavigationLink handles this
                        )
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        // Load more when near the end
                        if lead.id == viewModel.leads.last?.id {
                            Task { await viewModel.loadMore() }
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.spacing4)
            .padding(.bottom, AppSpacing.spacing12)
        }
    }
    
    private var loadingView: some View {
        ScrollView {
            VStack(spacing: AppSpacing.spacing4) {
                ForEach(0..<4, id: \.self) { _ in
                    SkeletonCard()
                }
            }
            .padding(.horizontal, AppSpacing.spacing4)
        }
    }
}

#Preview {
    LeadFeedScreen()
        .preferredColorScheme(.dark)
}
