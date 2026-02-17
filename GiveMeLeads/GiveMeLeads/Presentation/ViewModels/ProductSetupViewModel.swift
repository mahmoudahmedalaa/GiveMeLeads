import Foundation
import Observation
import Supabase

/// ViewModel orchestrating product analysis → keyword setup → Reddit scan
@Observable
final class ProductSetupViewModel {
    
    // MARK: - State
    
    enum SetupPhase {
        case describe    // User types product description
        case analyzing   // Running analysis
        case review      // User reviews keywords + subreddits
        case saving      // Creating profile (fast — 1-2 seconds)
        case scanning    // Searching Reddit (slow — 10-20 seconds)
        case complete    // Done — profile created, optionally scanned
    }
    
    var phase: SetupPhase = .describe
    var productDescription: String = ""
    var error: String?
    
    // Analysis results (editable)
    var suggestedKeywords: [String] = []
    var suggestedSubreddits: [String] = []
    var profileName: String = ""
    
    // Scan results
    var leadsFound: Int = 0
    var scanProgress: String = ""
    var scanElapsed: Int = 0
    var createdProfileId: UUID?
    var isSaving = false
    
    // Internal
    private let keywordRepo: KeywordRepositoryProtocol
    private let leadRepo: LeadRepositoryProtocol
    private let redditSearch = RedditSearchService()
    
    init(
        keywordRepo: KeywordRepositoryProtocol = KeywordRepository(),
        leadRepo: LeadRepositoryProtocol = LeadRepository()
    ) {
        self.keywordRepo = keywordRepo
        self.leadRepo = leadRepo
    }
    
    // MARK: - Actions
    
    /// Analyze product description → generate keywords + subreddits
    func analyzeProduct() {
        guard productDescription.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10 else {
            error = "Please describe your product in more detail (at least 10 characters)"
            return
        }
        
        error = nil
        phase = .analyzing
        
        // Quick on-device analysis
        let result = ProductAnalyzer.analyze(description: productDescription)
        
        suggestedKeywords = result.keywords
        suggestedSubreddits = result.subreddits
        profileName = result.profileName
        
        // Short delay so the animation feels intentional
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 800_000_000)
            phase = .review
        }
    }
    
    /// Remove a keyword from suggestions
    func removeKeyword(_ keyword: String) {
        suggestedKeywords.removeAll { $0 == keyword }
    }
    
    /// Remove a subreddit from suggestions
    func removeSubreddit(_ sub: String) {
        suggestedSubreddits.removeAll { $0 == sub }
    }
    
    /// Add a custom keyword
    func addKeyword(_ keyword: String) {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty, !suggestedKeywords.contains(trimmed) else { return }
        suggestedKeywords.append(trimmed)
    }
    
    /// Add a custom subreddit
    func addSubreddit(_ sub: String) {
        let trimmed = sub.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "r/", with: "")
        guard !trimmed.isEmpty, !suggestedSubreddits.contains(trimmed) else { return }
        suggestedSubreddits.append(trimmed)
    }
    
    /// Create profile + keywords ONLY (fast — 1-2 seconds). No scanning.
    func confirmAndSave() async {
        guard !isSaving else { return }  // Prevent duplicate taps
        isSaving = true
        defer { isSaving = false }
        
        // Check profile cap against current plan
        do {
            let existingProfiles = try await keywordRepo.fetchProfiles()
            let gate = GatingService.shared.canCreateProfile(existingCount: existingProfiles.count)
            if !gate.isAllowed {
                if case .blocked(let reason) = gate {
                    error = reason
                } else {
                    error = "Profile limit reached."
                }
                return
            }
        } catch {
            // If we can't check, proceed — don't block on network errors
        }
        
        guard !suggestedKeywords.isEmpty else {
            error = "Add at least one keyword"
            return
        }
        guard !suggestedSubreddits.isEmpty else {
            error = "Add at least one subreddit"
            return
        }
        
        error = nil
        phase = .saving
        scanProgress = "Creating profile..."
        
        do {
            // 1. Create tracking profile with subreddits
            let profile = try await keywordRepo.createProfile(
                name: profileName,
                subreddits: suggestedSubreddits
            )
            
            createdProfileId = profile.id
            
            // Notify app that a new profile was created so Leads can auto-select it
            NotificationCenter.default.post(
                name: .profileCreated,
                object: nil,
                userInfo: ["profileId": profile.id]
            )
            
            // 2. Add keywords to profile
            scanProgress = "Adding keywords..."
            for keyword in suggestedKeywords {
                _ = try await keywordRepo.addKeyword(
                    profileId: profile.id,
                    keyword: keyword,
                    isExactMatch: false
                )
            }
            
            // Done! Profile saved — user can scan from the Leads tab
            phase = .complete
            
        } catch {
            self.error = error.localizedDescription
            phase = .review // Go back to review so they can retry
        }
    }
    
    /// Optionally scan Reddit right after profile creation
    func scanNow() async {
        guard let profileId = createdProfileId else { return }
        
        phase = .scanning
        scanProgress = "Searching Reddit..."
        scanElapsed = 0
        error = nil
        
        do {
            guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else {
                throw AppError.authFailed("Not authenticated")
            }
            
            // Search Reddit posts AND comments
            scanProgress = "Searching Reddit posts..."
            let posts = try await redditSearch.search(
                keywords: suggestedKeywords,
                subreddits: suggestedSubreddits,
                limit: 25
            )
            
            scanProgress = "Searching Reddit comments..."
            let comments = try await redditSearch.searchComments(
                keywords: suggestedKeywords,
                subreddits: suggestedSubreddits,
                limit: 15
            )
            
            scanProgress = "Analyzing \(posts.count) posts + \(comments.count) comments..."
            
            // Build all leads in memory, then batch insert
            var leadsToSave: [NewLead] = []
            
            // Analyze posts
            for post in posts {
                guard let intel = redditSearch.analyzePost(
                    post,
                    keywords: suggestedKeywords,
                    productDescription: productDescription
                ) else { continue }
                
                leadsToSave.append(NewLead(
                    userId: userId,
                    profileId: profileId,
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
                    comment,
                    keywords: suggestedKeywords,
                    productDescription: productDescription
                ) else { continue }
                
                leadsToSave.append(NewLead(
                    userId: userId,
                    profileId: profileId,
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
            scanProgress = "Saving \(leadsToSave.count) leads..."
            if !leadsToSave.isEmpty {
                do {
                    try await SupabaseManager.shared.client
                        .from("leads")
                        .insert(leadsToSave)
                        .execute()
                } catch {
                    for lead in leadsToSave {
                        _ = try? await SupabaseManager.shared.client
                            .from("leads")
                            .insert(lead)
                            .execute()
                    }
                }
            }
            
            leadsFound = leadsToSave.count
            phase = .complete
            
        } catch {
            self.error = error.localizedDescription
            phase = .complete // Stay on complete — profile is already saved
        }
    }
    
    // MARK: - Private
    
    private func saveLead(_ lead: NewLead) async throws {
        try await SupabaseManager.shared.client
            .from("leads")
            .insert(lead)
            .execute()
    }
}

// MARK: - Insert DTO

struct NewLead: Encodable {
    let userId: UUID
    let profileId: UUID?
    let keywordId: UUID?
    let redditPostId: String
    let subreddit: String
    let author: String
    let title: String
    let body: String?
    let url: String
    let score: Int
    let scoreBreakdown: ScoreBreakdown
    let upvotes: Int
    let commentCount: Int
    let status: LeadStatus
    let postedAt: Date
    let discoveredAt: Date
    let relevanceInsight: String?
    let matchingSnippet: String?
    let suggestedApproach: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case profileId = "profile_id"
        case keywordId = "keyword_id"
        case redditPostId = "reddit_post_id"
        case subreddit, author, title, body, url, score
        case scoreBreakdown = "score_breakdown"
        case upvotes
        case commentCount = "comment_count"
        case status
        case postedAt = "posted_at"
        case discoveredAt = "discovered_at"
        case relevanceInsight = "relevance_insight"
        case matchingSnippet = "matching_snippet"
        case suggestedApproach = "suggested_approach"
    }
}
