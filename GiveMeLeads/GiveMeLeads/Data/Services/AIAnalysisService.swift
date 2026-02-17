import Foundation

/// Service for AI-powered lead analysis via Supabase Edge Function
final class AIAnalysisService {
    static let shared = AIAnalysisService()
    
    private let baseURL: String
    
    private init() {
        baseURL = AppConfig.supabaseURL
    }
    
    /// Analyze a Reddit post using Gemini AI via the analyze-lead Edge Function
    /// Returns AI-powered scoring and insights
    func analyzeLead(
        title: String,
        body: String,
        subreddit: String,
        author: String,
        productDescription: String,
        keywords: [String],
        comments: [String]? = nil
    ) async throws -> AILeadAnalysis {
        guard let url = URL(string: "\(baseURL)/functions/v1/analyze-lead") else {
            throw AppError.networkError("Invalid URL")
        }
        
        guard let session = try? await SupabaseManager.shared.client.auth.session else {
            throw AppError.authFailed("Not authenticated")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(AppConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.timeoutInterval = 30
        
        let requestBody: [String: Any] = [
            "title": title,
            "body": body,
            "subreddit": subreddit,
            "author": author,
            "product_description": productDescription,
            "keywords": keywords,
            "comments": comments ?? []
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.networkError("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AppError.networkError("AI analysis failed (\(httpResponse.statusCode)): \(errorBody)")
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(AILeadAnalysis.self, from: data)
    }
}

/// Result from AI lead analysis
struct AILeadAnalysis: Codable {
    let score: Int
    let relevanceInsight: String
    let suggestedApproach: String
    let matchingSnippet: String
    let intentSignals: [String]?
    
    enum CodingKeys: String, CodingKey {
        case score
        case relevanceInsight = "relevance_insight"
        case suggestedApproach = "suggested_approach"
        case matchingSnippet = "matching_snippet"
        case intentSignals = "intent_signals"
    }
}
