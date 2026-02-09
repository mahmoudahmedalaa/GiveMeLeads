import Foundation

/// A keyword being tracked on Reddit
struct Keyword: Identifiable, Codable, Equatable {
    let id: UUID
    let profileId: UUID
    let userId: UUID
    var keyword: String
    var isExactMatch: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case profileId = "profile_id"
        case userId = "user_id"
        case keyword
        case isExactMatch = "is_exact_match"
        case createdAt = "created_at"
    }
}

/// A group of keywords that are tracked together
struct TrackingProfile: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    var name: String
    var subreddits: [String]
    var isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    
    // Not from database — populated after fetch
    var keywords: [Keyword]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name, subreddits
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case keywords
    }
}

// MARK: - Sample Data

extension Keyword {
    static let sample = Keyword(
        id: UUID(), profileId: UUID(), userId: UUID(),
        keyword: "project management", isExactMatch: false,
        createdAt: Date()
    )
}

extension TrackingProfile {
    static let sample = TrackingProfile(
        id: UUID(), userId: UUID(),
        name: "My SaaS",
        subreddits: ["SaaS", "productivity", "startup"],
        isActive: true,
        createdAt: Date(), updatedAt: Date(),
        keywords: [
            Keyword(id: UUID(), profileId: UUID(), userId: UUID(),
                    keyword: "project management", isExactMatch: false, createdAt: Date()),
            Keyword(id: UUID(), profileId: UUID(), userId: UUID(),
                    keyword: "task app recommendation", isExactMatch: false, createdAt: Date()),
            Keyword(id: UUID(), profileId: UUID(), userId: UUID(),
                    keyword: "Asana alternative", isExactMatch: true, createdAt: Date()),
        ]
    )
}
