import Foundation

/// A Reddit post identified as a potential lead
struct Lead: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    let profileId: UUID?
    let keywordId: UUID?
    let redditPostId: String
    let subreddit: String
    let author: String
    let title: String
    let body: String?
    let url: String
    var score: Int?
    var scoreBreakdown: ScoreBreakdown?
    let upvotes: Int
    let commentCount: Int
    var status: LeadStatus
    let postedAt: Date
    let discoveredAt: Date
    var relevanceInsight: String?
    var matchingSnippet: String?
    var suggestedApproach: String?
    
    enum CodingKeys: String, CodingKey {
        case id
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

struct ScoreBreakdown: Codable, Equatable {
    let intent: Int
    let urgency: Int
    let fit: Int
}

enum LeadStatus: String, Codable, CaseIterable {
    case new
    case saved
    case contacted
    case dismissed
    case converted
    
    var displayName: String {
        switch self {
        case .new: "New"
        case .saved: "Saved"
        case .contacted: "Contacted"
        case .dismissed: "Dismissed"
        case .converted: "Converted"
        }
    }
}

// MARK: - Sample Data

extension Lead {
    static let sample = Lead(
        id: UUID(),
        userId: UUID(),
        profileId: nil,
        keywordId: UUID(),
        redditPostId: "t3_abc123",
        subreddit: "SaaS",
        author: "techguy42",
        title: "Looking for a project management tool that handles dependencies and has a good mobile app",
        body: "Currently using Asana but it's too expensive for our small team. We need something that handles task dependencies well and has a decent mobile experience. Budget is under $50/user/month. Any recommendations?",
        url: "https://reddit.com/r/SaaS/comments/abc123",
        score: 92,
        scoreBreakdown: ScoreBreakdown(intent: 95, urgency: 88, fit: 94),
        upvotes: 47,
        commentCount: 12,
        status: .new,
        postedAt: Date().addingTimeInterval(-7200),
        discoveredAt: Date(),
        relevanceInsight: "User is actively seeking a project management alternative — mentions budget constraints and mobile needs, which align with your product.",
        matchingSnippet: "Looking for a project management tool that handles dependencies and has a good mobile app",
        suggestedApproach: "Position your tool as a cost-effective Asana alternative. Highlight mobile experience and dependency features."
    )
    
    static let samples: [Lead] = [
        .sample,
        Lead(
            id: UUID(), userId: UUID(), profileId: nil, keywordId: UUID(),
            redditPostId: "t3_def456", subreddit: "startup", author: "founder99",
            title: "Can anyone recommend a CRM for small teams?",
            body: "We're a 5-person startup and need a CRM that doesn't cost a fortune.",
            url: "https://reddit.com/r/startup/comments/def456",
            score: 67, scoreBreakdown: ScoreBreakdown(intent: 70, urgency: 55, fit: 75),
            upvotes: 23, commentCount: 8, status: .new,
            postedAt: Date().addingTimeInterval(-18000), discoveredAt: Date()
        ),
        Lead(
            id: UUID(), userId: UUID(), profileId: nil, keywordId: UUID(),
            redditPostId: "t3_ghi789", subreddit: "Entrepreneur", author: "StartUpJourney",
            title: "How do you validate your B2B product idea with potential leads?",
            body: nil,
            url: "https://reddit.com/r/Entrepreneur/comments/ghi789",
            score: 34, scoreBreakdown: ScoreBreakdown(intent: 30, urgency: 25, fit: 45),
            upvotes: 45, commentCount: 11, status: .new,
            postedAt: Date().addingTimeInterval(-28800), discoveredAt: Date()
        ),
    ]
}
