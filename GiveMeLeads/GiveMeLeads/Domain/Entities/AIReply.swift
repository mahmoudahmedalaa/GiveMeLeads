import Foundation

/// An AI-generated reply suggestion for a lead
struct AIReply: Identifiable, Codable, Equatable {
    let id: UUID
    let leadId: UUID
    let userId: UUID
    let tone: ReplyTone
    let suggestion: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case leadId = "lead_id"
        case userId = "user_id"
        case tone, suggestion
        case createdAt = "created_at"
    }
}

enum ReplyTone: String, Codable, CaseIterable {
    case professional
    case casual
    case helpful
    
    var icon: String {
        switch self {
        case .professional: "🎯"
        case .casual: "💬"
        case .helpful: "💡"
        }
    }
    
    var displayName: String {
        switch self {
        case .professional: "Professional"
        case .casual: "Casual"
        case .helpful: "Helpful"
        }
    }
}

// MARK: - Sample Data

extension AIReply {
    static let samples: [AIReply] = [
        AIReply(
            id: UUID(), leadId: UUID(), userId: UUID(),
            tone: .professional,
            suggestion: "Hi! Based on what you're describing, you might want to check out our tool. It handles task dependencies really well and has a highly-rated mobile app. We're also well under your budget at $15/user/month.",
            createdAt: Date()
        ),
        AIReply(
            id: UUID(), leadId: UUID(), userId: UUID(),
            tone: .casual,
            suggestion: "Hey! I've been using exactly this kind of tool for my team. Handles dependencies great and the mobile app is solid. Worth checking out!",
            createdAt: Date()
        ),
        AIReply(
            id: UUID(), leadId: UUID(), userId: UUID(),
            tone: .helpful,
            suggestion: "I had the same challenge when we outgrew Asana. What worked for us was finding a tool that prioritized mobile and dependency tracking. Happy to share more details if you're interested!",
            createdAt: Date()
        ),
    ]
}
