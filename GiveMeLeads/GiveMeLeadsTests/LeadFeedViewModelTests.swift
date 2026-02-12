import Testing
import Foundation
@testable import GiveMeLeads

// MARK: - Mock Services

@MainActor
final class MockLeadRepository: LeadRepositoryProtocol {
    var leadsToReturn: [Lead] = []
    var fetchCallCount = 0
    var clearedProfiles: [UUID] = []
    var statusUpdates: [(UUID, LeadStatus)] = []
    var shouldThrow: Error?
    
    func fetchLeads(status: LeadStatus?, limit: Int, offset: Int) async throws -> [Lead] {
        if let err = shouldThrow { throw err }
        fetchCallCount += 1
        let start = min(offset, leadsToReturn.count)
        let end = min(start + limit, leadsToReturn.count)
        return Array(leadsToReturn[start..<end])
    }
    
    func fetchLeads(profileId: UUID, status: LeadStatus?, limit: Int, offset: Int) async throws -> [Lead] {
        if let err = shouldThrow { throw err }
        fetchCallCount += 1
        let profileLeads = leadsToReturn.filter { $0.profileId == profileId }
        let start = min(offset, profileLeads.count)
        let end = min(start + limit, profileLeads.count)
        return Array(profileLeads[start..<end])
    }
    
    func updateLeadStatus(leadId: UUID, status: LeadStatus) async throws {
        if let err = shouldThrow { throw err }
        statusUpdates.append((leadId, status))
    }
    
    func getLead(id: UUID) async throws -> Lead? {
        leadsToReturn.first { $0.id == id }
    }
    
    func getLeadCount(status: LeadStatus?) async throws -> Int {
        leadsToReturn.filter { status == nil || $0.status == status }.count
    }
    
    func clearLeadsForProfile(profileId: UUID) async throws {
        if let err = shouldThrow { throw err }
        clearedProfiles.append(profileId)
        leadsToReturn.removeAll { $0.profileId == profileId }
    }
}

@MainActor
final class MockKeywordRepository: KeywordRepositoryProtocol {
    var profilesToReturn: [TrackingProfile] = []
    var shouldThrow: Error?
    
    func fetchProfiles() async throws -> [TrackingProfile] {
        if let err = shouldThrow { throw err }
        return profilesToReturn
    }
    
    func createProfile(name: String, subreddits: [String]) async throws -> TrackingProfile {
        fatalError("not used in tests")
    }
    
    func updateProfile(_ profile: TrackingProfile) async throws {}
    func deleteProfile(id: UUID) async throws {}
    
    func addKeyword(profileId: UUID, keyword: String, isExactMatch: Bool) async throws -> Keyword {
        fatalError("not used in tests")
    }
    
    func deleteKeyword(id: UUID) async throws {}
}

final class MockRedditSearchService: RedditSearchServiceProtocol {
    var postsToReturn: [RedditSearchService.RedditPost] = []
    var commentsToReturn: [RedditSearchService.RedditComment] = []
    var intelligenceToReturn: RedditSearchService.LeadIntelligence?
    var shouldThrow: Error?
    var searchCallCount = 0
    
    func search(keywords: [String], subreddits: [String], limit: Int) async throws -> [RedditSearchService.RedditPost] {
        if let err = shouldThrow { throw err }
        searchCallCount += 1
        return postsToReturn
    }
    
    func searchComments(keywords: [String], subreddits: [String], limit: Int) async throws -> [RedditSearchService.RedditComment] {
        if let err = shouldThrow { throw err }
        return commentsToReturn
    }
    
    func analyzePost(_ post: RedditSearchService.RedditPost, keywords: [String], productDescription: String) -> RedditSearchService.LeadIntelligence? {
        intelligenceToReturn
    }
    
    func analyzeComment(_ comment: RedditSearchService.RedditComment, keywords: [String], productDescription: String) -> RedditSearchService.LeadIntelligence? {
        intelligenceToReturn
    }
}

// MARK: - Test Helpers

private let testProfileId = UUID()
private let testUserId = UUID()

private func makeProfile(
    id: UUID = testProfileId,
    name: String = "Test Profile",
    isActive: Bool = true,
    keywords: [Keyword]? = [Keyword(id: UUID(), profileId: testProfileId, userId: testUserId, keyword: "swift", isExactMatch: false, createdAt: Date())]
) -> TrackingProfile {
    TrackingProfile(
        id: id, userId: testUserId,
        name: name,
        subreddits: ["iOSProgramming"],
        isActive: isActive,
        createdAt: Date(), updatedAt: Date(),
        keywords: keywords
    )
}

private func makeLead(
    id: UUID = UUID(),
    profileId: UUID? = testProfileId,
    score: Int = 80
) -> Lead {
    Lead(
        id: id,
        userId: testUserId,
        profileId: profileId,
        keywordId: nil,
        redditPostId: "t3_\(id.uuidString.prefix(6))",
        subreddit: "iOSProgramming",
        author: "tester",
        title: "Test lead \(score)",
        body: "Body text",
        url: "https://reddit.com/r/test",
        score: score,
        scoreBreakdown: ScoreBreakdown(intent: 80, urgency: 70, fit: 90),
        upvotes: 10,
        commentCount: 3,
        status: .new,
        postedAt: Date(),
        discoveredAt: Date()
    )
}

// MARK: - Tests

@Suite("LeadFeedViewModel")
struct LeadFeedViewModelTests {
    
    // MARK: - Initial Load
    
    @MainActor
    @Test("initialLoad selects first active profile and fetches leads")
    func initialLoadSelectsActiveProfile() async {
        let leadRepo = MockLeadRepository()
        let kwRepo = MockKeywordRepository()
        let profile = makeProfile()
        let lead = makeLead()
        
        kwRepo.profilesToReturn = [profile]
        leadRepo.leadsToReturn = [lead]
        
        let vm = LeadFeedViewModel(leadRepo: leadRepo, keywordRepo: kwRepo, redditSearch: MockRedditSearchService())
        
        await vm.initialLoad()
        
        #expect(vm.selectedProfile?.id == profile.id)
        #expect(vm.leads.count == 1)
        #expect(vm.hasLoadedOnce == true)
    }
    
    @MainActor
    @Test("initialLoad with no profiles shows empty state")
    func initialLoadNoProfiles() async {
        let kwRepo = MockKeywordRepository()
        kwRepo.profilesToReturn = []
        
        let vm = LeadFeedViewModel(leadRepo: MockLeadRepository(), keywordRepo: kwRepo, redditSearch: MockRedditSearchService())
        await vm.initialLoad()
        
        #expect(vm.selectedProfile == nil)
        #expect(vm.profiles.isEmpty)
        #expect(vm.leads.isEmpty)
    }
    
    @MainActor
    @Test("initialLoad second call only refreshes profiles")
    func initialLoadIdempotent() async {
        let leadRepo = MockLeadRepository()
        let kwRepo = MockKeywordRepository()
        kwRepo.profilesToReturn = [makeProfile()]
        
        let vm = LeadFeedViewModel(leadRepo: leadRepo, keywordRepo: kwRepo, redditSearch: MockRedditSearchService())
        await vm.initialLoad()
        
        let fetchCountAfterFirst = leadRepo.fetchCallCount
        await vm.initialLoad()
        
        // Should NOT double-fetch leads — just refreshes profiles
        #expect(leadRepo.fetchCallCount == fetchCountAfterFirst)
    }
    
    // MARK: - Profile Switching
    
    @MainActor
    @Test("switchToProfile resets state and loads new leads")
    func switchToProfileResetsState() async {
        let leadRepo = MockLeadRepository()
        let kwRepo = MockKeywordRepository()
        
        let p1 = makeProfile(id: UUID(), name: "Profile 1")
        let p2id = UUID()
        let p2 = makeProfile(id: p2id, name: "Profile 2")
        let lead2 = makeLead(profileId: p2id)
        
        kwRepo.profilesToReturn = [p1, p2]
        leadRepo.leadsToReturn = [lead2]
        
        let vm = LeadFeedViewModel(leadRepo: leadRepo, keywordRepo: kwRepo, redditSearch: MockRedditSearchService())
        await vm.initialLoad()
        
        await vm.switchToProfile(p2)
        
        #expect(vm.selectedProfile?.id == p2.id)
        #expect(vm.scanSummary == nil)
        #expect(vm.error == nil)
        #expect(vm.isScanning == false)
    }
    
    @MainActor
    @Test("switchToProfile to same profile is no-op")
    func switchToSameProfileNoOp() async {
        let leadRepo = MockLeadRepository()
        let kwRepo = MockKeywordRepository()
        let profile = makeProfile()
        kwRepo.profilesToReturn = [profile]
        
        let vm = LeadFeedViewModel(leadRepo: leadRepo, keywordRepo: kwRepo, redditSearch: MockRedditSearchService())
        await vm.initialLoad()
        
        let initialFetchCount = leadRepo.fetchCallCount
        await vm.switchToProfile(profile)
        
        // No additional fetch since profile didn't change
        #expect(leadRepo.fetchCallCount == initialFetchCount)
    }
    
    // MARK: - Pagination
    
    @MainActor
    @Test("loadMore respects hasMore flag")
    func loadMoreRespectsHasMore() async {
        let leadRepo = MockLeadRepository()
        let kwRepo = MockKeywordRepository()
        let profile = makeProfile()
        kwRepo.profilesToReturn = [profile]
        // Return 5 leads (< pageSize of 20) so hasMore = false
        let leads = (0..<5).map { _ in makeLead() }
        leadRepo.leadsToReturn = leads
        
        let vm = LeadFeedViewModel(leadRepo: leadRepo, keywordRepo: kwRepo, redditSearch: MockRedditSearchService())
        await vm.initialLoad()
        
        #expect(vm.hasMore == false) // 5 < 20, so no more
        
        let fetchCountBefore = leadRepo.fetchCallCount
        await vm.loadMore()
        
        // Should NOT fetch again since hasMore is false
        #expect(leadRepo.fetchCallCount == fetchCountBefore)
    }
    
    @MainActor
    @Test("loadMore deduplicates leads")
    func loadMoreDeduplicates() async {
        let leadRepo = MockLeadRepository()
        let kwRepo = MockKeywordRepository()
        let profile = makeProfile()
        kwRepo.profilesToReturn = [profile]
        
        // Create exactly 20 leads so hasMore = true
        let leads = (0..<20).map { _ in makeLead() }
        leadRepo.leadsToReturn = leads
        
        let vm = LeadFeedViewModel(leadRepo: leadRepo, keywordRepo: kwRepo, redditSearch: MockRedditSearchService())
        await vm.initialLoad()
        
        #expect(vm.hasMore == true) // 20 == pageSize
        #expect(vm.leads.count == 20)
        
        // Trying to load more with same leads should not duplicate
        await vm.loadMore()
        
        // All 20 leads should have unique IDs — no duplicates added
        let uniqueIds = Set(vm.leads.map(\.id))
        #expect(uniqueIds.count == vm.leads.count)
    }
    
    // MARK: - Error Mapping
    
    @Test("AppError.from maps URLError to networkError")
    func errorMappingURLError() {
        let urlError = URLError(.notConnectedToInternet)
        let appError = AppError.from(urlError)
        
        if case .networkError = appError {
            // Expected
        } else {
            Issue.record("Expected .networkError but got \(appError)")
        }
    }
    
    @Test("AppError.from preserves existing AppError")
    func errorMappingPreservesAppError() {
        let original = AppError.authFailed("test")
        let mapped = AppError.from(original)
        #expect(mapped == original)
    }
    
    @Test("AppError.from maps unknown errors to .unknown")
    func errorMappingUnknown() {
        struct CustomError: Error {}
        let mapped = AppError.from(CustomError())
        if case .unknown = mapped {
            // Expected
        } else {
            Issue.record("Expected .unknown but got \(mapped)")
        }
    }
    
    @Test("AppError.userMessage returns actionable strings")
    func userMessageActionable() {
        #expect(AppError.rateLimited.userMessage.contains("wait"))
        #expect(AppError.authFailed("x").userMessage.contains("sign in"))
        #expect(AppError.networkError("x").userMessage.contains("connection"))
    }
    
    // MARK: - Scan Guards
    
    @MainActor
    @Test("scan with no profile sets invalidInput error")
    func scanNoProfile() async {
        let vm = LeadFeedViewModel(
            leadRepo: MockLeadRepository(),
            keywordRepo: MockKeywordRepository(),
            redditSearch: MockRedditSearchService()
        )
        
        vm.scanForNewLeads()
        // Give the task time to complete
        try? await Task.sleep(for: .milliseconds(100))
        
        if case .invalidInput = vm.error {
            // Expected
        } else {
            Issue.record("Expected .invalidInput error but got \(String(describing: vm.error))")
        }
    }
    
    @MainActor
    @Test("scan with empty keywords sets invalidInput error")
    func scanEmptyKeywords() async {
        let kwRepo = MockKeywordRepository()
        let profile = makeProfile(keywords: []) // No keywords
        kwRepo.profilesToReturn = [profile]
        
        let vm = LeadFeedViewModel(
            leadRepo: MockLeadRepository(),
            keywordRepo: kwRepo,
            redditSearch: MockRedditSearchService()
        )
        await vm.initialLoad()
        
        vm.scanForNewLeads()
        try? await Task.sleep(for: .milliseconds(100))
        
        if case .invalidInput = vm.error {
            // Expected
        } else {
            Issue.record("Expected .invalidInput for empty keywords but got \(String(describing: vm.error))")
        }
    }
    
    // MARK: - Clear Results
    
    @MainActor
    @Test("clearResults empties leads and sets summary")
    func clearResultsEmptiesLeads() async {
        let leadRepo = MockLeadRepository()
        let kwRepo = MockKeywordRepository()
        let profile = makeProfile()
        kwRepo.profilesToReturn = [profile]
        leadRepo.leadsToReturn = [makeLead()]
        
        let vm = LeadFeedViewModel(leadRepo: leadRepo, keywordRepo: kwRepo, redditSearch: MockRedditSearchService())
        await vm.initialLoad()
        #expect(vm.leads.count == 1)
        
        await vm.clearResults()
        
        #expect(vm.leads.isEmpty)
        #expect(vm.scanSummary?.contains("Clear") == true || vm.scanSummary?.contains("clear") == true || vm.scanSummary?.contains("Tap") == true)
        #expect(leadRepo.clearedProfiles.contains(profile.id))
    }
    
    // MARK: - Lead Actions
    
    @MainActor
    @Test("saveLead removes it from the list")
    func saveLeadRemovesFromList() async {
        let leadRepo = MockLeadRepository()
        let kwRepo = MockKeywordRepository()
        let profile = makeProfile()
        kwRepo.profilesToReturn = [profile]
        
        let lead = makeLead()
        leadRepo.leadsToReturn = [lead]
        
        let vm = LeadFeedViewModel(leadRepo: leadRepo, keywordRepo: kwRepo, redditSearch: MockRedditSearchService())
        await vm.initialLoad()
        #expect(vm.leads.count == 1)
        
        await vm.saveLead(lead)
        
        #expect(vm.leads.isEmpty)
        #expect(leadRepo.statusUpdates.first?.0 == lead.id)
        #expect(leadRepo.statusUpdates.first?.1 == .saved)
    }
    
    @MainActor
    @Test("dismissLead removes it from the list")
    func dismissLeadRemovesFromList() async {
        let leadRepo = MockLeadRepository()
        let kwRepo = MockKeywordRepository()
        let profile = makeProfile()
        kwRepo.profilesToReturn = [profile]
        
        let lead = makeLead()
        leadRepo.leadsToReturn = [lead]
        
        let vm = LeadFeedViewModel(leadRepo: leadRepo, keywordRepo: kwRepo, redditSearch: MockRedditSearchService())
        await vm.initialLoad()
        
        await vm.dismissLead(lead)
        
        #expect(vm.leads.isEmpty)
        #expect(leadRepo.statusUpdates.first?.1 == .dismissed)
    }
    
    // MARK: - Fetch Error Handling
    
    @MainActor
    @Test("fetch error sets typed AppError")
    func fetchErrorSetsTypedError() async {
        let leadRepo = MockLeadRepository()
        let kwRepo = MockKeywordRepository()
        kwRepo.profilesToReturn = [makeProfile()]
        leadRepo.shouldThrow = URLError(.timedOut)
        
        let vm = LeadFeedViewModel(leadRepo: leadRepo, keywordRepo: kwRepo, redditSearch: MockRedditSearchService())
        await vm.initialLoad()
        
        if case .networkError = vm.error {
            // Expected — timed out → networkError
        } else {
            Issue.record("Expected .networkError but got \(String(describing: vm.error))")
        }
    }
}
