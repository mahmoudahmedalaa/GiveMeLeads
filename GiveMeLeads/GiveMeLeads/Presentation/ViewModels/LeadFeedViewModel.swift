import Foundation
import Observation
import Supabase

/// Profile-aware lead feed — client-side scanning via Reddit JSON API
@Observable
final class LeadFeedViewModel {
    var leads: [Lead] = []
    var savedLeads: [Lead] = []
    var profiles: [TrackingProfile] = []
    var selectedProfile: TrackingProfile?
    var isLoading = false
    var isRefreshing = false
    var isScanning = false
    var scanMessage: String?
    var scanProgress: String?
    var error: String?
    var selectedLead: Lead?
    var hasLoadedOnce = false
    
    private let leadRepo: LeadRepositoryProtocol
    private let keywordRepo: KeywordRepositoryProtocol
    private let redditSearch = RedditSearchService()
    private var currentOffset = 0
    private let pageSize = 20
    
    init(
        leadRepo: LeadRepositoryProtocol = LeadRepository(),
        keywordRepo: KeywordRepositoryProtocol = KeywordRepository()
    ) {
        self.leadRepo = leadRepo
        self.keywordRepo = keywordRepo
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
        
        do {
            profiles = try await keywordRepo.fetchProfiles()
            
            // Auto-select: first active, or first profile
            selectedProfile = profiles.first(where: \.isActive) ?? profiles.first
            
            // Fetch leads for selected profile (if any)
            if selectedProfile != nil {
                await fetchLeadsForSelectedProfile()
            }
        } catch {
            self.error = "Failed to load profiles"
        }
        
        isLoading = false
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
                    scanMessage = nil
                    error = nil
                    currentOffset = 0
                    
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
    
    /// Switch to a different profile — clears old results and loads new ones
    func switchToProfile(_ profile: TrackingProfile) async {
        guard profile.id != selectedProfile?.id else { return }
        selectedProfile = profile
        scanMessage = nil
        error = nil
        leads = []
        currentOffset = 0
        await fetchLeadsForSelectedProfile()
    }
    
    /// Clear all new leads for current profile
    func clearResults() async {
        guard let profile = selectedProfile else { return }
        do {
            try await leadRepo.clearLeadsForProfile(profileId: profile.id)
            leads = []
            currentOffset = 0
            scanMessage = "Results cleared. Tap 🔍 to find new leads."
        } catch {
            self.error = "Failed to clear results"
        }
    }
    
    // MARK: - Scanning (client-side — Reddit blocks cloud IPs)
    
    /// Scan Reddit from the device and save leads to Supabase
    func scanForNewLeads() async {
        guard let profile = selectedProfile else {
            error = "No profile selected. Go to Profiles tab to create one."
            return
        }
        
        let keywords = profile.keywords?.map(\.keyword) ?? []
        guard !keywords.isEmpty else {
            error = "This profile has no keywords. Edit it to add some."
            return
        }
        
        isScanning = true
        scanMessage = nil
        scanProgress = "Searching Reddit..."
        error = nil
        
        do {
            guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else {
                error = "Session expired. Please sign in again."
                isScanning = false
                return
            }
            
            let subreddits = profile.subreddits.isEmpty ? ["all"] : profile.subreddits
            
            // Search posts
            scanProgress = "Searching Reddit posts..."
            let posts = try await redditSearch.search(
                keywords: keywords,
                subreddits: subreddits,
                limit: 25
            )
            
            // Search comments
            scanProgress = "Searching Reddit comments..."
            let comments = try await redditSearch.searchComments(
                keywords: keywords,
                subreddits: subreddits,
                limit: 15
            )
            
            scanProgress = "Analyzing \(posts.count) posts + \(comments.count) comments..."
            let productDesc = keywords.joined(separator: " ")
            var totalFound = 0
            
            // Analyze and save posts
            for post in posts {
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
                    totalFound += 1
                } catch {
                    continue // Skip duplicates
                }
            }
            
            // Analyze and save comments
            for comment in comments {
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
                    totalFound += 1
                } catch {
                    continue // Skip duplicates
                }
            }
            
            if totalFound > 0 {
                scanMessage = "🎯 \(totalFound) new lead\(totalFound == 1 ? "" : "s") found!"
            } else {
                scanMessage = "No new leads right now. Searched \(posts.count) posts + \(comments.count) comments."
            }
            
            await fetchLeadsForSelectedProfile()
            
        } catch {
            self.error = "Scan failed: \(error.localizedDescription)"
        }
        
        scanProgress = nil
        isScanning = false
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
        
        do {
            let fetched = try await leadRepo.fetchLeads(
                profileId: profile.id,
                status: .new,
                limit: pageSize,
                offset: 0
            )
            leads = fetched
            currentOffset = fetched.count
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Legacy fetch (all leads regardless of profile)
    func fetchLeads() async {
        isLoading = leads.isEmpty
        error = nil
        
        do {
            let fetched = try await leadRepo.fetchLeads(status: .new, limit: pageSize, offset: 0)
            leads = fetched
            currentOffset = fetched.count
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Pull to refresh
    func refresh() async {
        isRefreshing = true
        await refreshProfiles()
        await fetchLeadsForSelectedProfile()
        isRefreshing = false
    }
    
    /// Load more leads
    func loadMore() async {
        guard let profile = selectedProfile else { return }
        do {
            let more = try await leadRepo.fetchLeads(
                profileId: profile.id,
                status: .new,
                limit: pageSize,
                offset: currentOffset
            )
            leads.append(contentsOf: more)
            currentOffset += more.count
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    // MARK: - Lead Actions
    
    func saveLead(_ lead: Lead) async {
        do {
            try await leadRepo.updateLeadStatus(leadId: lead.id, status: .saved)
            leads.removeAll { $0.id == lead.id }
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func dismissLead(_ lead: Lead) async {
        do {
            try await leadRepo.updateLeadStatus(leadId: lead.id, status: .dismissed)
            leads.removeAll { $0.id == lead.id }
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func markContacted(_ lead: Lead) async {
        do {
            try await leadRepo.updateLeadStatus(leadId: lead.id, status: .contacted)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func fetchSavedLeads() async {
        do {
            savedLeads = try await leadRepo.fetchLeads(status: .saved, limit: 50, offset: 0)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
