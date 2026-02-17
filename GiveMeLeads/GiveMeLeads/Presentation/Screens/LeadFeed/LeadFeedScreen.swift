import SwiftUI

struct LeadFeedScreen: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = LeadFeedViewModel()
    @State private var showScanResult = false
    @State private var showClearConfirm = false
    @State private var showReplySheet = false
    @State private var replyLead: Lead?
    @State private var replyComments: [RedditSearchService.PostComment] = []
    private let redditSearch = RedditSearchService()
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Profile Selector (always visible when multiple profiles)
                    if viewModel.profiles.count > 1 {
                        profileSelector
                    } else if let profile = viewModel.selectedProfile {
                        singleProfileHeader(profile)
                    }
                    
                    // Status filter tabs
                    if !viewModel.profiles.isEmpty {
                        statusFilterBar
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
                    if viewModel.showAllProfiles {
                        // Scan All button in All mode
                        Button(action: { viewModel.scanAllProfiles() }) {
                            if viewModel.isScanning {
                                ProgressView()
                                    .tint(AppColors.primary400)
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                    Text("Scan All")
                                        .font(AppTypography.caption)
                                }
                                .foregroundColor(AppColors.primary400)
                            }
                        }
                        .disabled(viewModel.isScanning || viewModel.profiles.isEmpty)
                    } else {
                        Button(action: { triggerScan() }) {
                            if viewModel.isScanning {
                                ProgressView()
                                    .tint(AppColors.primary400)
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                    if let name = viewModel.selectedProfile?.name {
                                        Text(name)
                                            .font(AppTypography.caption)
                                            .lineLimit(1)
                                    }
                                }
                                .foregroundColor(AppColors.primary400)
                            }
                        }
                        .disabled(viewModel.isScanning || viewModel.selectedProfile == nil)
                    }
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
                if viewModel.showAllProfiles {
                    Text("This will remove all unsaved leads across all profiles. Saved leads won't be affected.")
                } else {
                    Text("This will remove all unsaved leads for this profile. Saved leads won't be affected.")
                }
            }
            .sheet(isPresented: $showReplySheet) {
                if let lead = replyLead {
                    ReplySheetView(lead: lead, topComments: replyComments)
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
                // "All" pill
                profilePill(
                    label: "All",
                    icon: "square.grid.2x2",
                    count: viewModel.totalLeadCount,
                    isSelected: viewModel.showAllProfiles
                ) {
                    Task { await viewModel.switchToAllProfiles() }
                }
                
                ForEach(viewModel.profiles) { profile in
                    profilePill(
                        label: profile.name,
                        icon: nil,
                        count: viewModel.leadCountByProfile[profile.id] ?? 0,
                        isSelected: !viewModel.showAllProfiles && profile.id == viewModel.selectedProfile?.id
                    ) {
                        Task { await viewModel.switchToProfile(profile) }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.spacing4)
            .padding(.vertical, AppSpacing.spacing3)
        }
        .background(AppColors.bg800.opacity(0.5))
    }
    
    /// Reusable profile pill with optional count badge
    private func profilePill(label: String, icon: String?, count: Int, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                } else {
                    Circle()
                        .fill(isSelected ? Color.white.opacity(0.8) : AppColors.textTertiary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
                
                Text(label)
                    .font(AppTypography.buttonMedium)
                    .lineLimit(1)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? AppColors.primary600 : .white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(
                            isSelected
                                ? Color.white.opacity(0.9)
                                : AppColors.primary500.opacity(0.8)
                        )
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(isSelected ? .white : AppColors.textSecondary)
            .padding(.horizontal, AppSpacing.spacing4)
            .padding(.vertical, AppSpacing.spacing2)
            .background(
                isSelected
                ? AnyShapeStyle(AppColors.primaryGradient)
                : AnyShapeStyle(AppColors.bg700)
            )
            .clipShape(Capsule())
        }
    }
    
    // MARK: - Status Filter Bar
    
    private var statusFilterBar: some View {
        HStack(spacing: 0) {
            statusTab("New", status: .new)
            statusTab("Saved", status: .saved)
            statusTab("Contacted", status: .contacted)
        }
        .background(AppColors.bg700.opacity(0.5))
    }
    
    private func statusTab(_ label: String, status: LeadStatus) -> some View {
        Button {
            Task { await viewModel.switchStatusFilter(status) }
        } label: {
            VStack(spacing: 6) {
                Text(label)
                    .font(AppTypography.buttonMedium)
                    .foregroundColor(
                        viewModel.statusFilter == status
                            ? AppColors.primary400
                            : AppColors.textTertiary
                    )
                
                Rectangle()
                    .fill(viewModel.statusFilter == status ? AppColors.primary400 : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.spacing2)
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
            
            if let count = viewModel.leadCountByProfile[profile.id], count > 0 {
                Text("\(count) lead\(count == 1 ? "" : "s")")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            
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
            
            Image(systemName: statusEmptyIcon)
                .font(.system(size: 56))
                .foregroundStyle(AppColors.primaryGradient)
            
            VStack(spacing: AppSpacing.spacing2) {
                Text(statusEmptyTitle)
                    .font(AppTypography.heading2)
                    .foregroundColor(AppColors.textPrimary)
                
                if let msg = viewModel.scanSummary {
                    Text(msg)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text(statusEmptyMessage)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Only show scan button for "New" status
            if viewModel.statusFilter == .new {
                if viewModel.showAllProfiles {
                    PrimaryButton(
                        viewModel.isScanning ? "Scanning..." : "🔍 Scan All Profiles",
                        isLoading: viewModel.isScanning
                    ) {
                        viewModel.scanAllProfiles()
                    }
                    .frame(maxWidth: 280)
                    .disabled(viewModel.isScanning)
                } else {
                    PrimaryButton(
                        viewModel.isScanning ? "Scanning Reddit..." : "🔍 Scan Reddit Now",
                        isLoading: viewModel.isScanning
                    ) {
                        triggerScan()
                    }
                    .frame(maxWidth: 280)
                    .disabled(viewModel.isScanning || viewModel.selectedProfile == nil)
                }
                
                if viewModel.isScanning {
                    ScanTimerView()
                }
            }
            
            Spacer()
        }
        .padding(AppSpacing.spacing8)
    }
    
    private var statusEmptyIcon: String {
        switch viewModel.statusFilter {
        case .saved: "bookmark"
        case .contacted: "envelope.open"
        case .dismissed: "xmark.circle"
        default: "target"
        }
    }
    
    private var statusEmptyTitle: String {
        let profileName = viewModel.showAllProfiles ? nil : viewModel.selectedProfile?.name
        let suffix = profileName.map { " for \"\($0)\"" } ?? ""
        
        switch viewModel.statusFilter {
        case .saved: return "No saved leads\(suffix)"
        case .contacted: return "No contacted leads\(suffix)"
        case .dismissed: return "No dismissed leads\(suffix)"
        default:
            if let name = profileName {
                return "No leads for \"\(name)\""
            }
            return "No Leads Yet"
        }
    }
    
    private var statusEmptyMessage: String {
        switch viewModel.statusFilter {
        case .saved: "Bookmark leads you're interested in.\nThey'll appear here."
        case .contacted: "Leads you've reached out to\nwill appear here."
        case .dismissed: "Dismissed leads will appear here."
        default: "We're monitoring Reddit automatically.\nTap below for an instant scan."
        }
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
                
                // Scanning progress
                if viewModel.isScanning, let progress = viewModel.scanProgress {
                    HStack {
                        ProgressView()
                            .tint(AppColors.primary400)
                        Text(progress)
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                    }
                    .padding(AppSpacing.spacing3)
                    .background(AppColors.primary500.opacity(0.1))
                    .cornerRadius(AppRadius.sm)
                }
                
                // Lead count
                Text("\(viewModel.leads.count) lead\(viewModel.leads.count == 1 ? "" : "s")")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
                
                ForEach(viewModel.visibleLeads) { lead in
                    NavigationLink(destination: LeadDetailScreen(
                        lead: lead,
                        onAction: { action in
                            Task {
                                switch action {
                                case .save: await viewModel.saveLead(lead)
                                case .unsave: await viewModel.unsaveLead(lead)
                                case .dismiss: await viewModel.dismissLead(lead)
                                case .delete: await viewModel.deleteLead(lead)
                                case .contacted: await viewModel.markContacted(lead)
                                case .reply: break // handled by sheet in detail
                                }
                            }
                        }
                    )) {
                        LeadCardView(
                            lead: lead,
                            profileName: viewModel.profiles.count > 1 ? viewModel.profileName(for: lead.profileId) : nil,
                            actions: { action in
                                Task {
                                    switch action {
                                    case .save: await viewModel.saveLead(lead)
                                    case .unsave: await viewModel.unsaveLead(lead)
                                    case .dismiss: await viewModel.dismissLead(lead)
                                    case .delete: await viewModel.deleteLead(lead)
                                    case .contacted: await viewModel.markContacted(lead)
                                    case .reply:
                                        replyLead = lead
                                        replyComments = []
                                        showReplySheet = true
                                        // Load comments in background
                                        Task {
                                            if lead.redditPostId.hasPrefix("t3_") {
                                                replyComments = (try? await redditSearch.fetchTopComments(
                                                    postId: lead.redditPostId,
                                                    subreddit: lead.subreddit,
                                                    limit: 5
                                                )) ?? []
                                            }
                                        }
                                    }
                                }
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
