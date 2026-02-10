import SwiftUI

struct LeadFeedScreen: View {
    @State private var viewModel = LeadFeedViewModel()
    @State private var showScanResult = false
    @State private var showClearConfirm = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Profile Selector
                    if viewModel.profiles.count > 1 {
                        profileSelector
                    } else if let profile = viewModel.selectedProfile {
                        singleProfileHeader(profile)
                    }
                    
                    // Content
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.leads.isEmpty {
                        emptyState
                    } else {
                        feedContent
                    }
                }
            }
            .navigationTitle("Leads")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !viewModel.leads.isEmpty {
                        Button(action: { showClearConfirm = true }) {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
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
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadProfiles()
                await viewModel.fetchLeadsForSelectedProfile()
                await viewModel.autoScanIfNeeded()
            }
            .alert(
                viewModel.error != nil ? "Scan Issue" : "Scan Complete",
                isPresented: $showScanResult
            ) {
                Button("OK") {
                    viewModel.scanMessage = nil
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error)
                } else {
                    Text(viewModel.scanMessage ?? "Done")
                }
            }
            .alert("Clear Results?", isPresented: $showClearConfirm) {
                Button("Clear", role: .destructive) {
                    Task { await viewModel.clearResults() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove all unsaved leads for this profile. Saved leads will remain.")
            }
        }
    }
    
    private func triggerScan() {
        Task {
            await viewModel.scanForNewLeads()
            showScanResult = true
        }
    }
    
    // MARK: - Profile Selector
    
    private var profileSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.spacing2) {
                ForEach(viewModel.profiles) { profile in
                    Button(action: {
                        Task { await viewModel.switchToProfile(profile) }
                    }) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(profile.id == viewModel.selectedProfile?.id
                                      ? AppColors.primary400
                                      : AppColors.textTertiary.opacity(0.3))
                                .frame(width: 8, height: 8)
                            
                            Text(profile.name)
                                .font(AppTypography.buttonMedium)
                                .foregroundColor(
                                    profile.id == viewModel.selectedProfile?.id
                                    ? .white
                                    : AppColors.textSecondary
                                )
                        }
                        .padding(.horizontal, AppSpacing.spacing4)
                        .padding(.vertical, AppSpacing.spacing2)
                        .background(
                            profile.id == viewModel.selectedProfile?.id
                            ? AnyShapeStyle(AppColors.primaryGradient)
                            : AnyShapeStyle(AppColors.bg700)
                        )
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, AppSpacing.spacing4)
            .padding(.vertical, AppSpacing.spacing3)
        }
        .background(AppColors.bg800.opacity(0.5))
    }
    
    private func singleProfileHeader(_ profile: TrackingProfile) -> some View {
        HStack {
            Circle()
                .fill(AppColors.primary400)
                .frame(width: 8, height: 8)
            Text(profile.name)
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textSecondary)
            
            Text("·")
                .foregroundColor(AppColors.textTertiary)
            
            Text("\(profile.keywords?.count ?? 0) keywords")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textTertiary)
            
            Spacer()
        }
        .padding(.horizontal, AppSpacing.spacing4)
        .padding(.vertical, AppSpacing.spacing2)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: AppSpacing.spacing6) {
            Spacer()
            
            Image(systemName: "target")
                .font(.system(size: 56))
                .foregroundStyle(AppColors.primaryGradient)
            
            VStack(spacing: AppSpacing.spacing2) {
                if let profile = viewModel.selectedProfile {
                    Text("No Leads for \"\(profile.name)\"")
                        .font(AppTypography.heading2)
                        .foregroundColor(AppColors.textPrimary)
                } else {
                    Text("No Leads Yet")
                        .font(AppTypography.heading2)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                if let msg = viewModel.scanMessage {
                    Text(msg)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Tap scan to search Reddit for\npeople looking for products like yours")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            PrimaryButton(
                viewModel.isScanning ? "Scanning Reddit..." : "🔍 Scan Reddit Now",
                isLoading: viewModel.isScanning
            ) {
                triggerScan()
            }
            .frame(maxWidth: 280)
            .disabled(viewModel.isScanning || viewModel.selectedProfile == nil)
            
            if viewModel.isScanning {
                VStack(spacing: AppSpacing.spacing2) {
                    Text("Searching across your keywords...")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textTertiary)
                    Text("This may take 10-15 seconds")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            Spacer()
        }
        .padding(AppSpacing.spacing8)
    }
    
    // MARK: - Feed Content
    
    private var feedContent: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.spacing4) {
                // Scan result banner
                if let msg = viewModel.scanMessage {
                    HStack {
                        Image(systemName: msg.contains("🎯") ? "checkmark.circle.fill" : "info.circle.fill")
                            .foregroundColor(msg.contains("🎯") ? AppColors.success : AppColors.accentCyan)
                        Text(msg)
                            .font(AppTypography.bodySmall)
                            .foregroundColor(msg.contains("🎯") ? AppColors.success : AppColors.accentCyan)
                        Spacer()
                        Button(action: { viewModel.scanMessage = nil }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                    .padding(AppSpacing.spacing3)
                    .background((msg.contains("🎯") ? AppColors.success : AppColors.accentCyan).opacity(0.1))
                    .cornerRadius(AppRadius.sm)
                }
                
                // Lead count
                HStack {
                    Text("\(viewModel.leads.count) lead\(viewModel.leads.count == 1 ? "" : "s")")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                    Spacer()
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
                            onTap: {}
                        )
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        if lead.id == viewModel.leads.last?.id {
                            Task { await viewModel.loadMore() }
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.spacing4)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Loading
    
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
