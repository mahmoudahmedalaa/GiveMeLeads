import Foundation
import Observation
import Supabase

/// Profile-aware lead feed — scans per-profile, clears on profile switch, shows 'up to date' on re-scan
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
    var error: String?
    var selectedLead: Lead?
    
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
    
    // MARK: - Profile Management
    
    /// Load all user profiles and auto-select the first active one
    func loadProfiles() async {
        do {
            profiles = try await keywordRepo.fetchProfiles()
            // Auto-select the first active profile if none selected
            if selectedProfile == nil {
                selectedProfile = profiles.first(where: \.isActive) ?? profiles.first
            }
        } catch {
            self.error = "Failed to load profiles"
        }
    }
    
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
            scanMessage = "Results cleared. Tap scan to find new leads."
        } catch {
            self.error = "Failed to clear results"
        }
    }
    
    // MARK: - Scanning
    
    /// Scan Reddit for the selected profile only
    func scanForNewLeads() async {
        guard let profile = selectedProfile else {
            error = "No profile selected. Go to Profiles tab to create one."
            return
        }
        
        let keywords = profile.keywords?.map(\.keyword) ?? []
        guard !keywords.isEmpty else {
            error = "No keywords in this profile. Add keywords first."
            return
        }
        
        isScanning = true
        scanMessage = nil
        error = nil
        
        do {
            guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else {
                error = "Session expired. Please sign in again."
                isScanning = false
                return
            }
            
            let subreddits = profile.subreddits.isEmpty ? ["all"] : profile.subreddits
            let productDesc = keywords.joined(separator: " ")
            
            // Search Reddit
            let posts = try await redditSearch.search(
                keywords: keywords,
                subreddits: subreddits,
                limit: 25
            )
            
            let comments = try await redditSearch.searchComments(
                keywords: keywords,
                subreddits: subreddits,
                limit: 15
            )
            
            var leadsToSave: [NewLead] = []
            
            // Analyze posts
            for post in posts {
                guard let intel = redditSearch.analyzePost(
                    post, keywords: keywords, productDescription: productDesc
                ) else { continue }
                
                leadsToSave.append(NewLead(
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
                ))
            }
            
            // Analyze comments
            for comment in comments {
                guard let intel = redditSearch.analyzeComment(
                    comment, keywords: keywords, productDescription: productDesc
                ) else { continue }
                
                leadsToSave.append(NewLead(
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
                ))
            }
            
            // Batch insert
            var totalFound = 0
            if !leadsToSave.isEmpty {
                do {
                    try await SupabaseManager.shared.client
                        .from("leads")
                        .insert(leadsToSave)
                        .execute()
                    totalFound = leadsToSave.count
                } catch {
                    for lead in leadsToSave {
                        do {
                            try await SupabaseManager.shared.client
                                .from("leads")
                                .insert(lead)
                                .execute()
                            totalFound += 1
                        } catch { continue }
                    }
                }
            }
            
            if totalFound > 0 {
                scanMessage = "🎯 \(totalFound) new lead\(totalFound == 1 ? "" : "s") found for \(profile.name)!"
            } else {
                scanMessage = "✅ You're up to date! No new Reddit posts matching \"\(profile.name)\" right now. Check back later."
            }
            
            await fetchLeadsForSelectedProfile()
            
        } catch {
            self.error = "Scan failed: \(error.localizedDescription)"
        }
        
        isScanning = false
    }
    
    /// Auto-scan on first load if leads are empty and profiles exist
    func autoScanIfNeeded() async {
        guard leads.isEmpty, !isScanning, selectedProfile != nil else { return }
        
        // Only auto-scan if the profile has keywords
        guard let profile = selectedProfile,
              let keywords = profile.keywords, !keywords.isEmpty else { return }
        
        await scanForNewLeads()
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
