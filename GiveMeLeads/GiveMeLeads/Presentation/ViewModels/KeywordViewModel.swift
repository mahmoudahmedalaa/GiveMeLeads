import Foundation
import Observation

/// ViewModel for profile management and scanning
@Observable
final class KeywordViewModel {
    var profiles: [TrackingProfile] = []
    var isLoading = false
    var error: String?
    
    // Scanning state
    var isScanningProfile: UUID?
    var scanMessage: String?
    var lastScannedProfileId: UUID?
    
    // Kept for compatibility but no longer used by AddProfileSheet
    var newKeywordText = ""
    var showAddProfile = false
    var newProfileName = ""
    var newProfileSubreddits = ""
    
    private let keywordRepo: KeywordRepositoryProtocol
    private let redditSearch = RedditSearchService()
    
    init(keywordRepo: KeywordRepositoryProtocol = KeywordRepository()) {
        self.keywordRepo = keywordRepo
    }
    
    var totalKeywords: Int {
        profiles.reduce(0) { $0 + ($1.keywords?.count ?? 0) }
    }
    
    var canAddProfile: Bool {
        GatingService.shared.canCreateProfile(existingCount: profiles.count).isAllowed
    }
    
    var profileGatingMessage: String? {
        let result = GatingService.shared.canCreateProfile(existingCount: profiles.count)
        if case .blocked(let reason) = result {
            return reason
        }
        return nil
    }
    
    /// Fetch all profiles with keywords
    func fetchProfiles() async {
        isLoading = profiles.isEmpty
        error = nil
        
        do {
            profiles = try await keywordRepo.fetchProfiles()
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Scan Reddit for a specific profile
    func scanProfile(_ profile: TrackingProfile) async {
        guard isScanningProfile == nil else { return }
        
        isScanningProfile = profile.id
        lastScannedProfileId = profile.id
        scanMessage = nil
        error = nil
        
        do {
            let keywords = profile.keywords?.map(\.keyword) ?? []
            
            guard !keywords.isEmpty else {
                error = "This profile has no keywords. Edit it to add some."
                isScanningProfile = nil
                return
            }
            
            guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else {
                error = "Session expired. Please sign in again."
                isScanningProfile = nil
                return
            }
            
            let subreddits = profile.subreddits.isEmpty ? ["all"] : profile.subreddits
            
            // Get user's product description for AI context
            let productDesc = await fetchProductDescription() ?? keywords.joined(separator: " ")
            
            // Phase 1: Search Reddit
            scanMessage = "🔍 Searching r/\(subreddits.first ?? "all")..."
            let posts = try await redditSearch.search(
                keywords: keywords,
                subreddits: subreddits,
                limit: 25
            )
            
            guard !posts.isEmpty else {
                scanMessage = "No posts found. Try different keywords or subreddits."
                isScanningProfile = nil
                return
            }
            
            // Phase 2: Score and save leads
            var totalFound = 0
            
            for (index, post) in posts.enumerated() {
                scanMessage = "🤖 Analyzing \(index + 1)/\(posts.count)..."
                
                // Try AI analysis first, fall back to local
                let (score, breakdown, insight, snippet, approach) = await analyzePostWithAI(
                    post: post,
                    keywords: keywords,
                    productDescription: productDesc
                )
                
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
                    score: score,
                    scoreBreakdown: breakdown,
                    upvotes: post.ups,
                    commentCount: post.numComments,
                    status: .new,
                    postedAt: Date(timeIntervalSince1970: post.createdUtc),
                    discoveredAt: Date(),
                    relevanceInsight: insight,
                    matchingSnippet: snippet,
                    suggestedApproach: approach
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
            
            scanMessage = totalFound > 0
                ? "🎯 \(totalFound) new lead\(totalFound == 1 ? "" : "s") found!"
                : "No new leads right now. Searched \(posts.count) posts."
            
        } catch {
            self.error = "Scan failed: \(error.localizedDescription)"
        }
        
        isScanningProfile = nil
    }
    
    /// Analyze a post using AI (Gemini) with local fallback
    private func analyzePostWithAI(
        post: RedditSearchService.RedditPost,
        keywords: [String],
        productDescription: String
    ) async -> (score: Int, breakdown: ScoreBreakdown, insight: String?, snippet: String?, approach: String?) {
        // Try AI analysis via Edge Function
        do {
            let analysis = try await AIAnalysisService.shared.analyzeLead(
                title: post.title,
                body: post.selftext ?? "",
                subreddit: post.subreddit,
                author: post.author,
                productDescription: productDescription,
                keywords: keywords
            )
            
            // Map AI score to breakdown (divide evenly across intent/urgency/fit)
            let third = max(1, analysis.score / 3)
            let remainder = analysis.score - (third * 3)
            let breakdown = ScoreBreakdown(
                intent: min(10, third + (remainder > 0 ? 1 : 0)),
                urgency: min(10, third + (remainder > 1 ? 1 : 0)),
                fit: min(10, third)
            )
            
            return (analysis.score, breakdown, analysis.relevanceInsight, analysis.matchingSnippet, analysis.suggestedApproach)
        } catch {
            // Fallback to local rule-based analysis
            if let intel = redditSearch.analyzePost(
                post,
                keywords: keywords,
                productDescription: productDescription
            ) {
                return (intel.score, intel.breakdown, intel.relevanceInsight, intel.matchingSnippet, intel.suggestedApproach)
            }
            
            // Absolute fallback
            return (3, ScoreBreakdown(intent: 3, urgency: 3, fit: 3), nil, nil, nil)
        }
    }
    
    /// Fetch the user's product description from their profile
    private func fetchProductDescription() async -> String? {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            
            struct UserProfile: Decodable {
                let productDescription: String?
                enum CodingKeys: String, CodingKey {
                    case productDescription = "product_description"
                }
            }
            
            let response: UserProfile = try await SupabaseManager.shared.client
                .from("users")
                .select("product_description")
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            return response.productDescription
        } catch {
            return nil
        }
    }
    
    /// Toggle profile active state
    func toggleProfile(_ profileId: UUID) async {
        guard let idx = profiles.firstIndex(where: { $0.id == profileId }) else { return }
        
        let updated = TrackingProfile(
            id: profiles[idx].id,
            userId: profiles[idx].userId,
            name: profiles[idx].name,
            subreddits: profiles[idx].subreddits,
            isActive: !profiles[idx].isActive,
            createdAt: profiles[idx].createdAt,
            updatedAt: profiles[idx].updatedAt,
            keywords: profiles[idx].keywords
        )
        profiles[idx] = updated
        
        do {
            try await keywordRepo.updateProfile(updated)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    /// Delete profile
    func deleteProfile(_ profileId: UUID) async {
        do {
            try await keywordRepo.deleteProfile(id: profileId)
            profiles.removeAll { $0.id == profileId }
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    /// Create a new tracking profile (legacy — kept for compatibility)
    func createProfile() async {
        guard !newProfileName.trimmingCharacters(in: .whitespaces).isEmpty else {
            error = "Profile name is required"
            return
        }
        
        let gateResult = GatingService.shared.canCreateProfile(existingCount: profiles.count)
        guard gateResult.isAllowed else {
            if case .blocked(let reason) = gateResult {
                error = reason
            }
            return
        }
        
        let subreddits = newProfileSubreddits
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "r/", with: "") }
            .filter { !$0.isEmpty }
        
        do {
            let profile = try await keywordRepo.createProfile(
                name: newProfileName.trimmingCharacters(in: .whitespaces),
                subreddits: subreddits
            )
            profiles.insert(profile, at: 0)
            newProfileName = ""
            newProfileSubreddits = ""
            showAddProfile = false
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    /// Add keyword to a profile
    func addKeyword(to profileId: UUID) async {
        let text = newKeywordText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !text.isEmpty else { return }
        
        do {
            let keyword = try await keywordRepo.addKeyword(
                profileId: profileId,
                keyword: text,
                isExactMatch: false
            )
            
            if let idx = profiles.firstIndex(where: { $0.id == profileId }) {
                var keywords = profiles[idx].keywords ?? []
                keywords.append(keyword)
                profiles[idx] = TrackingProfile(
                    id: profiles[idx].id,
                    userId: profiles[idx].userId,
                    name: profiles[idx].name,
                    subreddits: profiles[idx].subreddits,
                    isActive: profiles[idx].isActive,
                    createdAt: profiles[idx].createdAt,
                    updatedAt: profiles[idx].updatedAt,
                    keywords: keywords
                )
            }
            newKeywordText = ""
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    /// Delete a keyword
    func deleteKeyword(_ keyword: Keyword, from profileId: UUID) async {
        do {
            try await keywordRepo.deleteKeyword(id: keyword.id)
            
            if let idx = profiles.firstIndex(where: { $0.id == profileId }) {
                var keywords = profiles[idx].keywords ?? []
                keywords.removeAll { $0.id == keyword.id }
                profiles[idx] = TrackingProfile(
                    id: profiles[idx].id,
                    userId: profiles[idx].userId,
                    name: profiles[idx].name,
                    subreddits: profiles[idx].subreddits,
                    isActive: profiles[idx].isActive,
                    createdAt: profiles[idx].createdAt,
                    updatedAt: profiles[idx].updatedAt,
                    keywords: keywords
                )
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
