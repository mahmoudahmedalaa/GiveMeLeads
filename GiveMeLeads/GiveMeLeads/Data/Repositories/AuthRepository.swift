import Foundation
import Supabase
import Auth

/// Supabase-backed authentication repository
final class AuthRepository: AuthRepositoryProtocol {
    private let client = SupabaseManager.shared.client
    
    func signInWithApple(idToken: String, nonce: String) async throws -> UserProfile {
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
        
        guard let profile = try await fetchUserProfile(userId: session.user.id) else {
            throw AppError.authFailed("Failed to create user profile")
        }
        return profile
    }
    
    func sendMagicLink(email: String) async throws {
        try await client.auth.signInWithOTP(
            email: email,
            redirectTo: URL(string: "givemeleads://auth/callback")
        )
    }
    
    func getCurrentSession() async throws -> UserProfile? {
        guard let session = try? await client.auth.session else {
            return nil
        }
        return try await fetchUserProfile(userId: session.user.id)
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    func deleteAccount() async throws {
        // Delete user data first (RLS will only allow own data)
        guard let userId = try? await client.auth.session.user.id else { return }
        
        try await client.from("leads").delete().eq("user_id", value: userId.uuidString).execute()
        try await client.from("keywords").delete().eq("user_id", value: userId.uuidString).execute()
        try await client.from("tracking_profiles").delete().eq("user_id", value: userId.uuidString).execute()
        try await client.from("users").delete().eq("id", value: userId.uuidString).execute()
        try await client.auth.signOut()
    }
    
    // MARK: - Private
    
    private func fetchUserProfile(userId: UUID) async throws -> UserProfile? {
        let response: [UserProfile] = try await client
            .from("users")
            .select()
            .eq("id", value: userId.uuidString)
            .execute()
            .value
        return response.first
    }
}

/// App-specific errors
enum AppError: LocalizedError {
    case authFailed(String)
    case networkError(String)
    case notFound(String)
    case subscriptionRequired
    case limitReached(String)
    
    var errorDescription: String? {
        switch self {
        case .authFailed(let msg): "Authentication failed: \(msg)"
        case .networkError(let msg): "Network error: \(msg)"
        case .notFound(let msg): "Not found: \(msg)"
        case .subscriptionRequired: "Active subscription required"
        case .limitReached(let msg): "Limit reached: \(msg)"
        }
    }
}
