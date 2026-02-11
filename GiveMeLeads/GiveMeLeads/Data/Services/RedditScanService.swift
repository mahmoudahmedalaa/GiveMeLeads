import Foundation

/// Service to call the scan-reddit Edge Function
final class RedditScanService {
    private let supabaseURL = AppConfig.supabaseURL
    
    /// Trigger a Reddit scan for the authenticated user's active profiles
    func scanReddit(accessToken: String) async throws -> ScanResult {
        guard let url = URL(string: "\(supabaseURL)/functions/v1/scan-reddit") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(AppConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["trigger": "manual"])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode == 401 {
            throw ServiceError.unauthorized
        }
        
        guard httpResponse.statusCode == 200 else {
            throw ServiceError.serverError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(ScanResult.self, from: data)
    }
}

struct ScanResult: Codable {
    let message: String
    let leadsFound: Int
    let profilesScanned: Int?
    
    enum CodingKeys: String, CodingKey {
        case message
        case leadsFound = "leads_found"
        case profilesScanned = "profiles_scanned"
    }
}

enum ServiceError: LocalizedError {
    case unauthorized
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Please sign in again"
        case .serverError(let code): return "Server error (\(code))"
        }
    }
}
