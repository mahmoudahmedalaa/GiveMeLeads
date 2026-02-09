import Foundation

/// Protocol for authentication operations
protocol AuthRepositoryProtocol {
    /// Sign in with Apple using identity token
    func signInWithApple(idToken: String, nonce: String) async throws -> UserProfile
    /// Get current session, nil if not authenticated
    func getCurrentSession() async throws -> UserProfile?
    /// Sign out the current user
    func signOut() async throws
    /// Delete account and all data
    func deleteAccount() async throws
}

/// Protocol for lead data operations
protocol LeadRepositoryProtocol {
    /// Fetch leads for the current user, sorted by score
    func fetchLeads(status: LeadStatus?, limit: Int, offset: Int) async throws -> [Lead]
    /// Update a lead's status
    func updateLeadStatus(leadId: UUID, status: LeadStatus) async throws
    /// Get a single lead by ID
    func getLead(id: UUID) async throws -> Lead?
    /// Get count of leads by status
    func getLeadCount(status: LeadStatus?) async throws -> Int
}

/// Protocol for keyword/profile operations
protocol KeywordRepositoryProtocol {
    /// Fetch all tracking profiles for the current user
    func fetchProfiles() async throws -> [TrackingProfile]
    /// Create a new tracking profile
    func createProfile(name: String, subreddits: [String]) async throws -> TrackingProfile
    /// Update a tracking profile
    func updateProfile(_ profile: TrackingProfile) async throws
    /// Delete a tracking profile
    func deleteProfile(id: UUID) async throws
    /// Add a keyword to a profile
    func addKeyword(profileId: UUID, keyword: String, isExactMatch: Bool) async throws -> Keyword
    /// Delete a keyword
    func deleteKeyword(id: UUID) async throws
}

/// Protocol for AI reply operations
protocol AIReplyRepositoryProtocol {
    /// Fetch existing replies for a lead
    func fetchReplies(leadId: UUID) async throws -> [AIReply]
    /// Generate a new AI reply
    func generateReply(leadId: UUID, tone: ReplyTone, context: String) async throws -> AIReply
}

/// User profile from Supabase
struct UserProfile: Codable, Equatable {
    let id: UUID
    let email: String
    var displayName: String?
    var productDescription: String?
    var trialEndsAt: Date
    var subscriptionStatus: String
    var notificationScoreThreshold: Int
    var maxNotificationsPerDay: Int
    
    enum CodingKeys: String, CodingKey {
        case id, email
        case displayName = "display_name"
        case productDescription = "product_description"
        case trialEndsAt = "trial_ends_at"
        case subscriptionStatus = "subscription_status"
        case notificationScoreThreshold = "notification_score_threshold"
        case maxNotificationsPerDay = "max_notifications_per_day"
    }
    
    var isTrialActive: Bool {
        subscriptionStatus == "trial" && trialEndsAt > Date()
    }
    
    var hasActiveSubscription: Bool {
        subscriptionStatus == "active" || isTrialActive
    }
}
