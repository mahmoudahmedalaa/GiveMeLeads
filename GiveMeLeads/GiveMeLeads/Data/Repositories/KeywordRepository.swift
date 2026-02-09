import Foundation
import Supabase

/// Supabase-backed keyword & profile repository
final class KeywordRepository: KeywordRepositoryProtocol {
    private let client = SupabaseManager.shared.client
    
    func fetchProfiles() async throws -> [TrackingProfile] {
        let response: [TrackingProfile] = try await client
            .from("tracking_profiles")
            .select("*, keywords(*)")
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }
    
    func createProfile(name: String, subreddits: [String]) async throws -> TrackingProfile {
        guard let userId = try? await client.auth.session.user.id else {
            throw AppError.authFailed("Not authenticated")
        }
        
        let newProfile = NewTrackingProfile(
            userId: userId,
            name: name,
            subreddits: subreddits
        )
        
        let response: TrackingProfile = try await client
            .from("tracking_profiles")
            .insert(newProfile)
            .select("*, keywords(*)")
            .single()
            .execute()
            .value
        
        return response
    }
    
    func updateProfile(_ profile: TrackingProfile) async throws {
        let update = ProfileUpdate(
            name: profile.name,
            subreddits: profile.subreddits,
            isActive: profile.isActive
        )
        
        try await client
            .from("tracking_profiles")
            .update(update)
            .eq("id", value: profile.id.uuidString)
            .execute()
    }
    
    func deleteProfile(id: UUID) async throws {
        try await client
            .from("tracking_profiles")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    func addKeyword(profileId: UUID, keyword: String, isExactMatch: Bool) async throws -> Keyword {
        guard let userId = try? await client.auth.session.user.id else {
            throw AppError.authFailed("Not authenticated")
        }
        
        let newKeyword = NewKeyword(
            profileId: profileId,
            userId: userId,
            keyword: keyword,
            isExactMatch: isExactMatch
        )
        
        let response: Keyword = try await client
            .from("keywords")
            .insert(newKeyword)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    func deleteKeyword(id: UUID) async throws {
        try await client
            .from("keywords")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}

// MARK: - Insert DTOs

private struct NewTrackingProfile: Encodable {
    let userId: UUID
    let name: String
    let subreddits: [String]
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name
        case subreddits
    }
}

private struct ProfileUpdate: Encodable {
    let name: String
    let subreddits: [String]
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case name
        case subreddits
        case isActive = "is_active"
    }
}

private struct NewKeyword: Encodable {
    let profileId: UUID
    let userId: UUID
    let keyword: String
    let isExactMatch: Bool
    
    enum CodingKeys: String, CodingKey {
        case profileId = "profile_id"
        case userId = "user_id"
        case keyword
        case isExactMatch = "is_exact_match"
    }
}
