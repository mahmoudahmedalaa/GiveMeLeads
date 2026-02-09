import Foundation
import Observation

/// ViewModel for keyword/profile management
@Observable
final class KeywordViewModel {
    var profiles: [TrackingProfile] = []
    var isLoading = false
    var error: String?
    var showAddProfile = false
    
    // New profile form
    var newProfileName = ""
    var newProfileSubreddits = ""
    var newKeywordText = ""
    
    private let keywordRepo: KeywordRepositoryProtocol
    
    init(keywordRepo: KeywordRepositoryProtocol = KeywordRepository()) {
        self.keywordRepo = keywordRepo
    }
    
    var totalKeywords: Int {
        profiles.reduce(0) { $0 + ($1.keywords?.count ?? 0) }
    }
    
    var canAddProfile: Bool {
        profiles.count < AppConfig.maxProfiles
    }
    
    /// Fetch all profiles with keywords
    func fetchProfiles() async {
        isLoading = profiles.isEmpty
        error = nil
        
        do {
            profiles = try await keywordRepo.fetchProfiles()
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Create a new tracking profile
    func createProfile() async {
        guard !newProfileName.trimmingCharacters(in: .whitespaces).isEmpty else {
            error = "Profile name is required"
            return
        }
        
        guard canAddProfile else {
            error = "Maximum \(AppConfig.maxProfiles) profiles allowed"
            return
        }
        
        let subreddits = newProfileSubreddits
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "r/", with: "") }
            .filter { !$0.isEmpty }
        
        do {
            let profile = try await keywordRepo.createProfile(
                name: newProfileName.trimmingCharacters(in: .whitespaces),
                subreddits: subreddits
            )
            profiles.insert(profile, at: 0)
            newProfileName = ""
            newProfileSubreddits = ""
            showAddProfile = false
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    /// Add keyword to a profile
    func addKeyword(to profileId: UUID) async {
        let text = newKeywordText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !text.isEmpty else { return }
        
        do {
            let keyword = try await keywordRepo.addKeyword(
                profileId: profileId,
                keyword: text,
                isExactMatch: false
            )
            
            if let idx = profiles.firstIndex(where: { $0.id == profileId }) {
                var updated = profiles[idx]
                var keywords = updated.keywords ?? []
                keywords.append(keyword)
                // Since TrackingProfile is a struct, we need to reconstruct
                profiles[idx] = TrackingProfile(
                    id: updated.id,
                    userId: updated.userId,
                    name: updated.name,
                    subreddits: updated.subreddits,
                    isActive: updated.isActive,
                    createdAt: updated.createdAt,
                    updatedAt: updated.updatedAt,
                    keywords: keywords
                )
            }
            newKeywordText = ""
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    /// Delete a keyword
    func deleteKeyword(_ keyword: Keyword, from profileId: UUID) async {
        do {
            try await keywordRepo.deleteKeyword(id: keyword.id)
            
            if let idx = profiles.firstIndex(where: { $0.id == profileId }) {
                var keywords = profiles[idx].keywords ?? []
                keywords.removeAll { $0.id == keyword.id }
                profiles[idx] = TrackingProfile(
                    id: profiles[idx].id,
                    userId: profiles[idx].userId,
                    name: profiles[idx].name,
                    subreddits: profiles[idx].subreddits,
                    isActive: profiles[idx].isActive,
                    createdAt: profiles[idx].createdAt,
                    updatedAt: profiles[idx].updatedAt,
                    keywords: keywords
                )
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    /// Toggle profile active state
    func toggleProfile(_ profileId: UUID) async {
        guard let idx = profiles.firstIndex(where: { $0.id == profileId }) else { return }
        
        var updated = profiles[idx]
        updated = TrackingProfile(
            id: updated.id,
            userId: updated.userId,
            name: updated.name,
            subreddits: updated.subreddits,
            isActive: !updated.isActive,
            createdAt: updated.createdAt,
            updatedAt: updated.updatedAt,
            keywords: updated.keywords
        )
        profiles[idx] = updated
        
        do {
            try await keywordRepo.updateProfile(updated)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    /// Delete profile
    func deleteProfile(_ profileId: UUID) async {
        do {
            try await keywordRepo.deleteProfile(id: profileId)
            profiles.removeAll { $0.id == profileId }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
