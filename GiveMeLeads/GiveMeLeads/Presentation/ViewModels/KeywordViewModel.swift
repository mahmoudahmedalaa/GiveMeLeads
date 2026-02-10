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
        profiles.count < AppConfig.maxProfiles
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
            
            // Search Reddit
            let posts = try await redditSearch.search(
                keywords: keywords,
                subreddits: subreddits,
                limit: 25
            )
            
            // Score and save
            let productDesc = keywords.joined(separator: " ")
            var totalFound = 0
            
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
            
            scanMessage = totalFound > 0
                ? "🎯 \(totalFound) new lead\(totalFound == 1 ? "" : "s") found!"
                : "No new leads right now. Searched \(posts.count) posts."
            
        } catch {
            self.error = "Scan failed: \(error.localizedDescription)"
        }
        
        isScanningProfile = nil
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
        
        guard canAddProfile else {
            error = "Maximum \(AppConfig.maxProfiles) profiles allowed"
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
