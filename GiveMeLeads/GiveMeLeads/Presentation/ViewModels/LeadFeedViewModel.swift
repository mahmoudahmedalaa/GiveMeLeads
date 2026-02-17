import Foundation
import Observation
import Supabase
import Combine

/// Profile-aware lead feed — client-side scanning via Reddit JSON API
@MainActor
@Observable
final class LeadFeedViewModel {
    
    // MARK: - Public State
    
    var leads: [Lead] = []
    var savedLeads: [Lead] = []
    var profiles: [TrackingProfile] = []
    var selectedProfile: TrackingProfile?
    var showAllProfiles = false
    var isLoading = false
    var isRefreshing = false
    var isScanning = false
    var scanProgress: String?
    var scanSummary: String?
    var error: AppError?
    var selectedLead: Lead?
    var hasLoadedOnce = false
    private(set) var hasMore = true
    
    /// Lead counts per profile (for badge display)
    var leadCountByProfile: [UUID: Int] = [:]
    
    /// Total lead count across all profiles
    var totalLeadCount: Int { leadCountByProfile.values.reduce(0, +) }
    
    /// Current status filter (nil = show all statuses, default = .new)
    var statusFilter: LeadStatus? = .new
    
    /// User-facing error string for bindings that expect String?
    var errorMessage: String? { error?.userMessage }
    
    // MARK: - Gated Properties
    
    private let gatingService = GatingService.shared
    
    /// Leads visible under the current plan cap
    var visibleLeads: [Lead] {
        Array(leads.prefix(gatingService.visibleLeadCount()))
    }
    
    /// Number of leads hidden behind the paywall
    var hiddenLeadCount: Int {
        max(0, leads.count - gatingService.visibleLeadCount())
    }
    
    /// Whether the lead limit has been reached
    var isLeadLimitReached: Bool { hiddenLeadCount > 0 }
    
    // MARK: - Private
    
    private let leadRepo: LeadRepositoryProtocol
    private let keywordRepo: KeywordRepositoryProtocol
    private let redditSearch: RedditSearchServiceProtocol
    private var currentOffset = 0
    private let pageSize = 20
    
    private var scanTask: Task<Void, Never>?
    private var fetchTask: Task<Void, Never>?
    private var lastScanAtByProfile: [UUID: Date] = [:]
    private var isLoadingMore = false
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    
    init(
        leadRepo: LeadRepositoryProtocol = LeadRepository(),
        keywordRepo: KeywordRepositoryProtocol = KeywordRepository(),
        redditSearch: RedditSearchServiceProtocol = RedditSearchService()
    ) {
        self.leadRepo = leadRepo
        self.keywordRepo = keywordRepo
        self.redditSearch = redditSearch
        
        // Observe profile creation events — only auto-switch if this was the FIRST profile
        NotificationCenter.default.publisher(for: .profileCreated)
            .compactMap { $0.userInfo?["profileId"] as? UUID }
            .sink { [weak self] profileId in
                Task {
                    guard let self else { return }
                    let hadProfiles = !self.profiles.isEmpty
                    // Refresh profiles list to pick up the new one
                    do {
                        let fresh = try await self.keywordRepo.fetchProfiles()
                        self.profiles = fresh
                    } catch { /* keep cached */ }
                    
                    if !hadProfiles {
                        // First profile ever — auto-select it
                        await self.selectProfileAndLoad(profileId: profileId)
                    }
                    // Otherwise: keep current selection, pills updated
                    await self.refreshLeadCounts()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Initial Load (called on .task — NO auto-scan)
    
    /// Load profiles + leads for the active profile. NEVER auto-scans.
    func initialLoad() async {
        guard !hasLoadedOnce else {
            // On subsequent appearances, just refresh profiles in case one was deleted
            await refreshProfiles()
            return
        }
        hasLoadedOnce = true
        isLoading = true
        defer { isLoading = false }
        
        do {
            profiles = try await keywordRepo.fetchProfiles()
            
            // Auto-select: first active, or first profile
            selectedProfile = profiles.first(where: \.isActive) ?? profiles.first
            
            // Fetch leads for selected profile (if any)
            if selectedProfile != nil {
                await fetchLeadsForSelectedProfile()
            }
            
            // Fetch lead counts for all profiles
            await refreshLeadCounts()
        } catch {
            self.error = .from(error)
        }
    }
    
    /// Refresh profiles from DB (catches deleted profiles, new profiles from setup)
    func refreshProfiles() async {
        do {
            let freshProfiles = try await keywordRepo.fetchProfiles()
            profiles = freshProfiles
            
            // If selected profile was deleted, clear it
            if let selected = selectedProfile {
                if !freshProfiles.contains(where: { $0.id == selected.id }) {
                    // Profile was deleted — reset
                    selectedProfile = freshProfiles.first(where: \.isActive) ?? freshProfiles.first
                    leads = []
                    scanSummary = nil
                    error = nil
                    currentOffset = 0
                    hasMore = true
                    
                    if selectedProfile != nil {
                        await fetchLeadsForSelectedProfile()
                    }
                } else {
                    // Profile still exists — update it with fresh data (keyword count etc.)
                    selectedProfile = freshProfiles.first { $0.id == selected.id }
                }
            } else if !showAllProfiles {
                // No profile selected — pick one
                selectedProfile = freshProfiles.first(where: \.isActive) ?? freshProfiles.first
                if selectedProfile != nil {
                    await fetchLeadsForSelectedProfile()
                }
            }
            
            await refreshLeadCounts()
        } catch {
            // Silently fail — we already have cached profiles
        }
    }
    
    // MARK: - Lead Count Badges
    
    /// Fetch lead counts for all profiles (for badge display on pills)
    func refreshLeadCounts() async {
        var counts: [UUID: Int] = [:]
        for profile in profiles {
            do {
                let count = try await leadRepo.getLeadCount(profileId: profile.id, status: .new)
                counts[profile.id] = count
            } catch {
                counts[profile.id] = 0
            }
        }
        leadCountByProfile = counts
    }
    
    // MARK: - Status Filter
    
    /// Switch the status filter and reload leads
    func switchStatusFilter(_ status: LeadStatus?) async {
        statusFilter = status
        leads = []
        currentOffset = 0
        hasMore = true
        await fetchLeadsForSelectedProfile()
    }
    
    // MARK: - Profile Switching
    
    /// Switch to a different profile — cancels in-flight work, clears old results, loads new
    func switchToProfile(_ profile: TrackingProfile) async {
        guard profile.id != selectedProfile?.id || showAllProfiles else { return }
        
        // Cancel any in-flight work
        scanTask?.cancel()
        scanTask = nil
        fetchTask?.cancel()
        fetchTask = nil
        
        showAllProfiles = false
        selectedProfile = profile
        scanSummary = nil
        scanProgress = nil
        error = nil
        leads = []
        currentOffset = 0
        hasMore = true
        isScanning = false
        
        await fetchLeadsForSelectedProfile()
    }
    
    /// Switch to "All Profiles" view — shows leads across all profiles
    func switchToAllProfiles() async {
        guard !showAllProfiles else { return }
        
        // Cancel any in-flight work
        scanTask?.cancel()
        scanTask = nil
        fetchTask?.cancel()
        fetchTask = nil
        
        showAllProfiles = true
        selectedProfile = nil
        scanSummary = nil
        scanProgress = nil
        error = nil
        leads = []
        currentOffset = 0
        hasMore = true
        isScanning = false
        
        await fetchLeadsForSelectedProfile()
    }
    
    /// Look up profile name by ID (for display on lead cards)
    func profileName(for profileId: UUID?) -> String? {
        guard let id = profileId else { return nil }
        return profiles.first { $0.id == id }?.name
    }
    
    /// Select a profile by id (e.g., after creation) and load its leads
    func selectProfileAndLoad(profileId: UUID) async {
        // Cancel any in-flight work
        scanTask?.cancel()
        scanTask = nil
        fetchTask?.cancel()
        fetchTask = nil
        
        // Find the profile in current list; if not present, refresh profiles first
        if let found = profiles.first(where: { $0.id == profileId }) {
            selectedProfile = found
        } else {
            do {
                let fresh = try await keywordRepo.fetchProfiles()
                profiles = fresh
                selectedProfile = fresh.first(where: { $0.id == profileId }) ?? fresh.first(where: \.isActive) ?? fresh.first
            } catch {
                // If we cannot refresh, bail gracefully
            }
        }
        
        // Reset state and load
        showAllProfiles = false
        scanSummary = nil
        scanProgress = nil
        error = nil
        leads = []
        currentOffset = 0
        hasMore = true
        isScanning = false
        
        await fetchLeadsForSelectedProfile()
    }
    
    /// Clear all new leads for current profile (or all profiles in "All" mode)
    func clearResults() async {
        // Cancel any in-flight work
        scanTask?.cancel()
        scanTask = nil
        fetchTask?.cancel()
        fetchTask = nil
        
        do {
            if showAllProfiles {
                // Clear new leads for ALL profiles
                for profile in profiles {
                    try await leadRepo.clearLeadsForProfile(profileId: profile.id)
                }
            } else if let profile = selectedProfile {
                try await leadRepo.clearLeadsForProfile(profileId: profile.id)
            }
            
            leads = []
            currentOffset = 0
            hasMore = true
            scanSummary = "Results cleared. Tap 🔍 to find new leads."
            
            await refreshLeadCounts()
        } catch {
            self.error = .from(error)
        }
    }
    
    // MARK: - Scanning (client-side — Reddit blocks cloud IPs)
    
    /// Kickoff a scan — cancels any existing scan and starts a new one
    func scanForNewLeads() {
        scanTask?.cancel()
        scanTask = Task { await performScan() }
    }
    
    /// Scan all profiles sequentially (for "All" mode)
    func scanAllProfiles() {
        scanTask?.cancel()
        scanTask = Task { await performScanAll() }
    }
    
    /// Scan all profiles one by one
    private func performScanAll() async {
        guard !profiles.isEmpty else {
            error = .invalidInput("No profiles to scan.")
            return
        }
        
        isScanning = true
        scanSummary = nil
        error = nil
        defer { isScanning = false; scanProgress = nil }
        
        var totalSaved = 0
        var totalDuplicates = 0
        var scannedCount = 0
        
        for profile in profiles {
            try? Task.checkCancellation()
            if Task.isCancelled { break }
            
            scannedCount += 1
            scanProgress = "Scanning \(profile.name) (\(scannedCount)/\(profiles.count))..."
            
            let (saved, dupes) = await performScanForProfile(profile)
            totalSaved += saved
            totalDuplicates += dupes
        }
        
        // Build summary
        var parts: [String] = []
        if totalSaved > 0 {
            parts.append("🎯 \(totalSaved) new lead\(totalSaved == 1 ? "" : "s") found!")
        }
        if totalDuplicates > 0 {
            parts.append("\(totalDuplicates) duplicate\(totalDuplicates == 1 ? "" : "s") skipped")
        }
        if parts.isEmpty {
            scanSummary = "No new leads right now across \(profiles.count) profiles."
        } else {
            scanSummary = parts.joined(separator: " · ")
        }
        
        await fetchLeadsForSelectedProfile()
        await refreshLeadCounts()
    }
    
    /// Core scan logic — runs in a Task, supports cancellation
    private func performScan() async {
        guard let profile = selectedProfile else {
            error = .invalidInput("No profile selected. Go to Profiles tab to create one.")
            return
        }
        
        isScanning = true
        scanSummary = nil
        error = nil
        scanProgress = "Searching Reddit..."
        defer {
            scanProgress = nil
            isScanning = false
        }
        
        let (saved, dupes) = await performScanForProfile(profile)
        
        // Build summary
        if saved > 0 || dupes > 0 {
            var parts: [String] = []
            if saved > 0 { parts.append("🎯 \(saved) new lead\(saved == 1 ? "" : "s") found!") }
            if dupes > 0 { parts.append("\(dupes) duplicate\(dupes == 1 ? "" : "s") skipped") }
            scanSummary = parts.joined(separator: " · ")
        } else {
            scanSummary = "No new leads right now."
        }
        
        await fetchLeadsForSelectedProfile()
        await refreshLeadCounts()
    }
    
    /// Scan a single profile and return (savedCount, duplicateCount)
    private func performScanForProfile(_ profile: TrackingProfile) async -> (Int, Int) {
        let keywords = profile.keywords?.map(\.keyword) ?? []
        guard !keywords.isEmpty else { return (0, 0) }
        
        let subreddits = profile.subreddits.isEmpty ? ["all"] : profile.subreddits
        guard !subreddits.isEmpty else { return (0, 0) }
        
        // Daily scan limit check
        let scanGate = gatingService.canScan()
        if !scanGate.isAllowed {
            if case .blocked(let reason) = scanGate {
                error = .limitReached(reason)
            }
            return (0, 0)
        }
        
        // Cooldown check — prevent spamming Reddit
        if let lastScan = lastScanAtByProfile[profile.id] {
            let elapsed = Date().timeIntervalSince(lastScan)
            if elapsed < 60 {
                let remaining = Int(60 - elapsed)
                scanSummary = "⏳ Please wait \(remaining)s before scanning \(profile.name) again."
                return (0, 0)
            }
        }
        
        do {
            guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else {
                error = .authFailed("Not authenticated")
                return (0, 0)
            }
            
            // Search posts
            try Task.checkCancellation()
            scanProgress = "Searching Reddit posts for \(profile.name)..."
            let posts = try await redditSearch.search(
                keywords: keywords,
                subreddits: subreddits,
                limit: 25
            )
            
            // Search comments
            try Task.checkCancellation()
            scanProgress = "Searching Reddit comments for \(profile.name)..."
            let comments = try await redditSearch.searchComments(
                keywords: keywords,
                subreddits: subreddits,
                limit: 15
            )
            
            try Task.checkCancellation()
            scanProgress = "Analyzing \(posts.count) posts + \(comments.count) comments..."
            let productDesc = keywords.joined(separator: " ")
            
            var savedCount = 0
            var duplicateCount = 0
            
            // Analyze and save posts
            for post in posts {
                try Task.checkCancellation()
                
                guard let intel = redditSearch.analyzePost(
                    post,
                    keywords: keywords,
                    productDescription: productDesc
                ) else { continue }
                
                let newLead = NewLead(
                    userId: userId,
                    profileId: profile.id,
                    keywordId: nil,
                    redditPostId: "t3_\(post.id)",
                    subreddit: post.subreddit,
                    author: post.author,
                    title: post.title,
                    body: post.selftext,
                    url: "https://reddit.com\(post.permalink)",
                    score: intel.score,
                    scoreBreakdown: intel.breakdown,
                    upvotes: post.ups,
                    commentCount: post.numComments,
                    status: .new,
                    postedAt: Date(timeIntervalSince1970: post.createdUtc),
                    discoveredAt: Date(),
                    relevanceInsight: intel.relevanceInsight,
                    matchingSnippet: intel.matchingSnippet,
                    suggestedApproach: intel.suggestedApproach
                )
                
                do {
                    try await SupabaseManager.shared.client
                        .from("leads")
                        .insert(newLead)
                        .execute()
                    savedCount += 1
                } catch {
                    duplicateCount += 1
                }
            }
            
            // Analyze and save comments
            for comment in comments {
                try Task.checkCancellation()
                
                guard let intel = redditSearch.analyzeComment(
                    comment,
                    keywords: keywords,
                    productDescription: productDesc
                ) else { continue }
                
                let newLead = NewLead(
                    userId: userId,
                    profileId: profile.id,
                    keywordId: nil,
                    redditPostId: "t1_\(comment.id)",
                    subreddit: comment.subreddit,
                    author: comment.author,
                    title: comment.linkTitle ?? "Reddit Comment",
                    body: comment.body,
                    url: "https://reddit.com\(comment.permalink)",
                    score: intel.score,
                    scoreBreakdown: intel.breakdown,
                    upvotes: comment.ups,
                    commentCount: 0,
                    status: .new,
                    postedAt: Date(timeIntervalSince1970: comment.createdUtc),
                    discoveredAt: Date(),
                    relevanceInsight: intel.relevanceInsight,
                    matchingSnippet: intel.matchingSnippet,
                    suggestedApproach: intel.suggestedApproach
                )
                
                do {
                    try await SupabaseManager.shared.client
                        .from("leads")
                        .insert(newLead)
                        .execute()
                    savedCount += 1
                } catch {
                    duplicateCount += 1
                }
            }
            
            // Record cooldown timestamp + daily scan count
            lastScanAtByProfile[profile.id] = Date()
            gatingService.recordScan()
            
            return (savedCount, duplicateCount)
            
        } catch is CancellationError {
            return (0, 0)
        } catch {
            self.error = .from(error)
            return (0, 0)
        }
    }
    
    // MARK: - Fetching
    
    /// Fetch leads for the selected profile (or all profiles)
    func fetchLeadsForSelectedProfile() async {
        isLoading = leads.isEmpty
        error = nil
        defer { isLoading = false }
        
        do {
            let fetched: [Lead]
            if showAllProfiles {
                // Fetch from all profiles
                fetched = try await leadRepo.fetchLeads(status: statusFilter, limit: pageSize, offset: 0)
            } else if let profile = selectedProfile {
                fetched = try await leadRepo.fetchLeads(
                    profileId: profile.id,
                    status: statusFilter,
                    limit: pageSize,
                    offset: 0
                )
            } else {
                leads = []
                return
            }
            leads = fetched
            currentOffset = fetched.count
            hasMore = fetched.count == pageSize
        } catch {
            self.error = .from(error)
        }
    }
    
    /// Legacy fetch (all leads regardless of profile)
    func fetchLeads() async {
        isLoading = leads.isEmpty
        error = nil
        defer { isLoading = false }
        
        do {
            let fetched = try await leadRepo.fetchLeads(status: statusFilter, limit: pageSize, offset: 0)
            leads = fetched
            currentOffset = fetched.count
            hasMore = fetched.count == pageSize
        } catch {
            self.error = .from(error)
        }
    }
    
    /// Pull to refresh
    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        await refreshProfiles()
        await fetchLeadsForSelectedProfile()
    }
    
    /// Load more leads (pagination)
    func loadMore() async {
        guard !isLoadingMore, hasMore else { return }
        
        isLoadingMore = true
        defer { isLoadingMore = false }
        
        do {
            let more: [Lead]
            if showAllProfiles {
                more = try await leadRepo.fetchLeads(status: statusFilter, limit: pageSize, offset: currentOffset)
            } else if let profile = selectedProfile {
                more = try await leadRepo.fetchLeads(
                    profileId: profile.id,
                    status: statusFilter,
                    limit: pageSize,
                    offset: currentOffset
                )
            } else {
                return
            }
            
            // Deduplicate by id
            let existingIds = Set(leads.map(\.id))
            let unique = more.filter { !existingIds.contains($0.id) }
            leads.append(contentsOf: unique)
            currentOffset += more.count
            hasMore = more.count == pageSize
        } catch {
            self.error = .from(error)
        }
    }
    
    // MARK: - Lead Actions
    
    func saveLead(_ lead: Lead) async {
        do {
            try await leadRepo.updateLeadStatus(leadId: lead.id, status: .saved)
            leads.removeAll { $0.id == lead.id }
            // Update lead counts
            if let profileId = lead.profileId {
                leadCountByProfile[profileId] = max(0, (leadCountByProfile[profileId] ?? 1) - 1)
            }
        } catch {
            self.error = .from(error)
        }
    }
    
    func dismissLead(_ lead: Lead) async {
        do {
            try await leadRepo.updateLeadStatus(leadId: lead.id, status: .dismissed)
            leads.removeAll { $0.id == lead.id }
            // Update lead counts
            if let profileId = lead.profileId {
                leadCountByProfile[profileId] = max(0, (leadCountByProfile[profileId] ?? 1) - 1)
            }
        } catch {
            self.error = .from(error)
        }
    }
    
    func markContacted(_ lead: Lead) async {
        do {
            try await leadRepo.updateLeadStatus(leadId: lead.id, status: .contacted)
            leads.removeAll { $0.id == lead.id }
        } catch {
            self.error = .from(error)
        }
    }
    
    /// Move a saved/contacted lead back to "new" status
    func unsaveLead(_ lead: Lead) async {
        do {
            try await leadRepo.updateLeadStatus(leadId: lead.id, status: .new)
            leads.removeAll { $0.id == lead.id }
            // Increment new count for this profile
            if let profileId = lead.profileId {
                leadCountByProfile[profileId] = (leadCountByProfile[profileId] ?? 0) + 1
            }
        } catch {
            self.error = .from(error)
        }
    }
    
    /// Permanently delete a lead from the database
    func deleteLead(_ lead: Lead) async {
        do {
            try await leadRepo.deleteLead(leadId: lead.id)
            leads.removeAll { $0.id == lead.id }
        } catch {
            self.error = .from(error)
        }
    }
    
    func fetchSavedLeads() async {
        do {
            savedLeads = try await leadRepo.fetchLeads(status: .saved, limit: 50, offset: 0)
        } catch {
            self.error = .from(error)
        }
    }
}
extension Notification.Name {
    static let profileCreated = Notification.Name("ProfileCreatedNotification")
}
