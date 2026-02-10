import Foundation
import Supabase

/// Repository for AI reply generation via Edge Function
final class AIReplyRepository: AIReplyRepositoryProtocol {
    private let client = SupabaseManager.shared.client
    private let supabaseURL = AppConfig.supabaseURL
    
    func generateReply(leadId: UUID, tone: ReplyTone, context: String) async throws -> AIReply {
        guard let session = try? await client.auth.session else {
            throw ServiceError.unauthorized
        }
        
        guard let url = URL(string: "\(supabaseURL)/functions/v1/generate-reply") else {
            throw URLError(.badURL)
        }
        
        var body: [String: String] = [
            "lead_id": leadId.uuidString,
            "tone": tone.rawValue
        ]
        if !context.isEmpty {
            body["product_description"] = context
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ServiceError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)
        }
        
        struct ReplyResponse: Codable {
            let reply: AIReply
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ReplyResponse.self, from: data)
        return decoded.reply
    }
    
    func fetchReplies(leadId: UUID) async throws -> [AIReply] {
        let response: [AIReply] = try await client
            .from("ai_replies")
            .select()
            .eq("lead_id", value: leadId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }
}
