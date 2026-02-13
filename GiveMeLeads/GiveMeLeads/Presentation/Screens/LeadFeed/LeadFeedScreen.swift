import SwiftUI

struct LeadFeedScreen: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = LeadFeedViewModel()
    @State private var showScanResult = false
    @State private var showClearConfirm = false
    @State private var showReplySheet = false
    @State private var replyLead: Lead?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Profile Selector (only when multiple profiles)
                    if viewModel.profiles.count > 1 {
                        profileSelector
                    } else if let profile = viewModel.selectedProfile {
                        singleProfileHeader(profile)
                    }
                    
                    // Content
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.profiles.isEmpty {
                        noProfileState
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
                // Clear button (always visible when there are leads)
                ToolbarItem(placement: .topBarLeading) {
                    if !viewModel.leads.isEmpty {
                        Button(action: { showClearConfirm = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.system(size: 13))
                                Text("Clear")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(AppColors.scoreLow)
                        }
                    }
                }
                // Scan button
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
                    .disabled(viewModel.isScanning || viewModel.selectedProfile == nil)
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                // NO auto-scan — just load profiles + existing leads
                await viewModel.initialLoad()
            }
            .onAppear {
                // ALWAYS refresh profiles on tab switch — catches new/deleted profiles
                Task { await viewModel.refreshProfiles() }
            }
            // Show alert when scan completes (scanSummary or error becomes non-nil)
            .onChange(of: viewModel.scanSummary) { _, newValue in
                if newValue != nil { showScanResult = true }
            }
            .onChange(of: viewModel.error) { _, newValue in
                if newValue != nil && !viewModel.isScanning { showScanResult = true }
            }
            .alert(
                viewModel.error != nil ? "Scan Issue" : "Scan Complete",
                isPresented: $showScanResult
            ) {
                Button("OK") {
                    viewModel.scanSummary = nil
                    viewModel.error = nil
                }
            } message: {
                if let errorMsg = viewModel.errorMessage {
                    Text(errorMsg)
                } else {
                    Text(viewModel.scanSummary ?? "Done")
                }
            }
            .alert("Clear Results?", isPresented: $showClearConfirm) {
                Button("Clear All", role: .destructive) {
                    Task { await viewModel.clearResults() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove all unsaved leads for this profile. Saved leads won't be affected.")
            }
            .sheet(isPresented: $showReplySheet) {
                if let lead = replyLead {
                    ReplySheetView(lead: lead)
                        .presentationDetents([.medium, .large])
                }
            }
        }
    }
    
    private func triggerScan() {
        viewModel.scanForNewLeads()
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
    
    /// Single profile — show name only (no keyword count to avoid stale data)
    private func singleProfileHeader(_ profile: TrackingProfile) -> some View {
        HStack {
            Circle()
                .fill(AppColors.primary400)
                .frame(width: 8, height: 8)
            Text(profile.name)
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
        }
        .padding(.horizontal, AppSpacing.spacing4)
        .padding(.vertical, AppSpacing.spacing2)
    }
    
    // MARK: - No Profile State
    
    private var noProfileState: some View {
        VStack(spacing: AppSpacing.spacing6) {
            Spacer()
            
            Image(systemName: "plus.circle.dashed")
                .font(.system(size: 56))
                .foregroundStyle(AppColors.primaryGradient)
            
            VStack(spacing: AppSpacing.spacing2) {
                Text("No Profiles Yet")
                    .font(AppTypography.heading2)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Create a profile in the Profiles tab\nto start finding leads")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(AppSpacing.spacing8)
    }
    
    // MARK: - Empty State (has a profile but no leads)
    
    private var emptyState: some View {
        VStack(spacing: AppSpacing.spacing6) {
            Spacer()
            
            Image(systemName: "target")
                .font(.system(size: 56))
                .foregroundStyle(AppColors.primaryGradient)
            
            VStack(spacing: AppSpacing.spacing2) {
                if let profile = viewModel.selectedProfile {
                    Text("No leads for \"\(profile.name)\"")
                        .font(AppTypography.heading2)
                        .foregroundColor(AppColors.textPrimary)
                } else {
                    Text("No Leads Yet")
                        .font(AppTypography.heading2)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                if let msg = viewModel.scanSummary {
                    Text(msg)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("We're monitoring Reddit automatically.\nTap below for an instant scan.")
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
                ScanTimerView()
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
                if let msg = viewModel.scanSummary {
                    HStack {
                        Image(systemName: msg.contains("🎯") ? "checkmark.circle.fill" : "info.circle.fill")
                            .foregroundColor(msg.contains("🎯") ? AppColors.success : AppColors.accentCyan)
                        Text(msg)
                            .font(AppTypography.bodySmall)
                            .foregroundColor(msg.contains("🎯") ? AppColors.success : AppColors.accentCyan)
                        Spacer()
                        Button(action: { viewModel.scanSummary = nil }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                    .padding(AppSpacing.spacing3)
                    .background((msg.contains("🎯") ? AppColors.success : AppColors.accentCyan).opacity(0.1))
                    .cornerRadius(AppRadius.sm)
                }
                
                // Lead count + clear
                HStack {
                    Text("\(viewModel.leads.count) lead\(viewModel.leads.count == 1 ? "" : "s")")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                    Spacer()
                    
                    Button(action: { showClearConfirm = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                            Text("Clear all")
                                .font(AppTypography.caption)
                        }
                        .foregroundColor(AppColors.textTertiary)
                    }
                }
                
                ForEach(viewModel.visibleLeads) { lead in
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
                            onReply: {
                                replyLead = lead
                                showReplySheet = true
                            },
                            onTap: {}
                        )
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        if lead.id == viewModel.visibleLeads.last?.id {
                            Task { await viewModel.loadMore() }
                        }
                    }
                }
                
                // Upgrade banner + blurred cards when lead limit reached
                if viewModel.isLeadLimitReached {
                    UpgradeBanner(
                        hiddenCount: viewModel.hiddenLeadCount,
                        onUpgrade: { router.showPaywall = true }
                    )
                    
                    ForEach(0..<min(3, viewModel.hiddenLeadCount), id: \.self) { _ in
                        BlurredLeadCard {
                            router.showPaywall = true
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

// MARK: - Scan Timer View

/// Shows an elapsed timer during scanning so user knows the app is working
struct ScanTimerView: View {
    @State private var elapsed: Int = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: AppSpacing.spacing2) {
            ProgressView()
                .tint(AppColors.primary400)
            
            Text("Scanning Reddit... \(elapsed)s")
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textTertiary)
            
            Text("Server is searching — usually takes a few seconds")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textTertiary.opacity(0.7))
        }
        .onReceive(timer) { _ in
            elapsed += 1
        }
    }
}

#Preview {
    LeadFeedScreen()
        .preferredColorScheme(.dark)
}
