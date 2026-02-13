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
    var isLoading = false
    var isRefreshing = false
    var isScanning = false
    var scanProgress: String?
    var scanSummary: String?
    var error: AppError?
    var selectedLead: Lead?
    var hasLoadedOnce = false
    private(set) var hasMore = true
    
    /// User-facing error string for bindings that expect String?
    var errorMessage: String? { error?.userMessage }
    
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
        
        // Observe profile creation events to auto-select and load the new profile
        NotificationCenter.default.publisher(for: .profileCreated)
            .compactMap { $0.userInfo?["profileId"] as? UUID }
            .sink { [weak self] profileId in
                Task { await self?.selectProfileAndLoad(profileId: profileId) }
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
            } else {
                // No profile selected — pick one
                selectedProfile = freshProfiles.first(where: \.isActive) ?? freshProfiles.first
                if selectedProfile != nil {
                    await fetchLeadsForSelectedProfile()
                }
            }
        } catch {
            // Silently fail — we already have cached profiles
        }
    }
    
    // MARK: - Profile Switching
    
    /// Switch to a different profile — cancels in-flight work, clears old results, loads new
    func switchToProfile(_ profile: TrackingProfile) async {
        guard profile.id != selectedProfile?.id else { return }
        
        // Cancel any in-flight work
        scanTask?.cancel()
        scanTask = nil
        fetchTask?.cancel()
        fetchTask = nil
        
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
        scanSummary = nil
        scanProgress = nil
        error = nil
        leads = []
        currentOffset = 0
        hasMore = true
        isScanning = false
        
        await fetchLeadsForSelectedProfile()
    }
    
    /// Clear all new leads for current profile
    func clearResults() async {
        guard let profile = selectedProfile else { return }
        
        // Cancel any in-flight work
        scanTask?.cancel()
        scanTask = nil
        fetchTask?.cancel()
        fetchTask = nil
        
        do {
            try await leadRepo.clearLeadsForProfile(profileId: profile.id)
            leads = []
            currentOffset = 0
            hasMore = true
            scanSummary = "Results cleared. Tap 🔍 to find new leads."
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
    
    /// Core scan logic — runs in a Task, supports cancellation
    private func performScan() async {
        guard let profile = selectedProfile else {
            error = .invalidInput("No profile selected. Go to Profiles tab to create one.")
            return
        }
        
        let keywords = profile.keywords?.map(\.keyword) ?? []
        guard !keywords.isEmpty else {
            error = .invalidInput("This profile has no keywords. Edit it to add some.")
            return
        }
        
        let subreddits = profile.subreddits.isEmpty ? ["all"] : profile.subreddits
        guard !subreddits.isEmpty else {
            error = .invalidInput("This profile has no subreddits. Edit it to add some.")
            return
        }
        
        // Cooldown check — prevent spamming Reddit
        if let lastScan = lastScanAtByProfile[profile.id] {
            let elapsed = Date().timeIntervalSince(lastScan)
            if elapsed < 60 {
                let remaining = Int(60 - elapsed)
                scanSummary = "⏳ Please wait \(remaining)s before scanning again."
                return
            }
        }
        
        isScanning = true
        scanSummary = nil
        error = nil
        scanProgress = "Searching Reddit..."
        defer {
            scanProgress = nil
            isScanning = false
        }
        
        do {
            guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else {
                error = .authFailed("Not authenticated")
                return
            }
            
            // Search posts
            try Task.checkCancellation()
            scanProgress = "Searching Reddit posts..."
            let posts = try await redditSearch.search(
                keywords: keywords,
                subreddits: subreddits,
                limit: 25
            )
            
            // Search comments
            try Task.checkCancellation()
            scanProgress = "Searching Reddit comments..."
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
            var failureCount = 0
            
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
                    // Duplicate key or other insert error
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
            
            // Record cooldown timestamp
            lastScanAtByProfile[profile.id] = Date()
            
            // Build rich summary
            var summaryParts: [String] = []
            if savedCount > 0 {
                summaryParts.append("🎯 \(savedCount) new lead\(savedCount == 1 ? "" : "s") found!")
            }
            if duplicateCount > 0 {
                summaryParts.append("\(duplicateCount) duplicate\(duplicateCount == 1 ? "" : "s") skipped")
            }
            if summaryParts.isEmpty {
                scanSummary = "No new leads right now. Searched \(posts.count) posts + \(comments.count) comments."
            } else {
                scanSummary = summaryParts.joined(separator: " · ")
            }
            
            await fetchLeadsForSelectedProfile()
            
        } catch is CancellationError {
            scanSummary = "Scan cancelled."
        } catch {
            self.error = .from(error)
        }
    }
    
    // MARK: - Fetching
    
    /// Fetch leads for the selected profile
    func fetchLeadsForSelectedProfile() async {
        guard let profile = selectedProfile else {
            isLoading = false
            return
        }
        
        isLoading = leads.isEmpty
        error = nil
        defer { isLoading = false }
        
        do {
            let fetched = try await leadRepo.fetchLeads(
                profileId: profile.id,
                status: .new,
                limit: pageSize,
                offset: 0
            )
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
            let fetched = try await leadRepo.fetchLeads(status: .new, limit: pageSize, offset: 0)
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
        guard let profile = selectedProfile else { return }
        
        isLoadingMore = true
        defer { isLoadingMore = false }
        
        do {
            let more = try await leadRepo.fetchLeads(
                profileId: profile.id,
                status: .new,
                limit: pageSize,
                offset: currentOffset
            )
            
            // Deduplicate by id
            let existingIds = Set(leads.map(\.id))
            let unique = more.filter { !existingIds.contains($0.id) }
            leads.append(contentsOf: unique)
            currentOffset += more.count // must track server rows (not deduped count) for Supabase offset pagination
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
        } catch {
            self.error = .from(error)
        }
    }
    
    func dismissLead(_ lead: Lead) async {
        do {
            try await leadRepo.updateLeadStatus(leadId: lead.id, status: .dismissed)
            leads.removeAll { $0.id == lead.id }
        } catch {
            self.error = .from(error)
        }
    }
    
    func markContacted(_ lead: Lead) async {
        do {
            try await leadRepo.updateLeadStatus(leadId: lead.id, status: .contacted)
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

