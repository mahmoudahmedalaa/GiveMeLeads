import Foundation
import Observation
import Supabase

/// Edge Function scan response
private struct ScanResponse: Codable {
    let message: String?
    let leads_found: Int?
    let profiles_scanned: Int?
    let error: String?
}

/// Profile-aware lead feed — server-side scanning via Edge Function, auto-monitoring via cron
@Observable
final class LeadFeedViewModel {
    var leads: [Lead] = []
    var savedLeads: [Lead] = []
    var profiles: [TrackingProfile] = []
    var selectedProfile: TrackingProfile?
    var isLoading = false
    var isRefreshing = false
    var isScanning = false
    var scanMessage: String?
    var error: String?
    var selectedLead: Lead?
    var hasLoadedOnce = false
    
    private let leadRepo: LeadRepositoryProtocol
    private let keywordRepo: KeywordRepositoryProtocol
    private var currentOffset = 0
    private let pageSize = 20
    
    init(
        leadRepo: LeadRepositoryProtocol = LeadRepository(),
        keywordRepo: KeywordRepositoryProtocol = KeywordRepository()
    ) {
        self.leadRepo = leadRepo
        self.keywordRepo = keywordRepo
    }
    
    // MARK: - Initial Load (called on .task — NO auto-scan)
    
    /// Load profiles + leads for the active profile. NEVER auto-scans.
    func initialLoad() async {
        guard !hasLoadedOnce else {
            // On subsequent appearances, just refresh profiles in case one was deleted
            await refreshProfiles()
            return
        }
        hasLoadedOnce = true
        isLoading = true
        
        do {
            profiles = try await keywordRepo.fetchProfiles()
            
            // Auto-select: first active, or first profile
            selectedProfile = profiles.first(where: \.isActive) ?? profiles.first
            
            // Fetch leads for selected profile (if any)
            if selectedProfile != nil {
                await fetchLeadsForSelectedProfile()
            }
        } catch {
            self.error = "Failed to load profiles"
        }
        
        isLoading = false
    }
    
    /// Refresh profiles from DB (catches deleted profiles, new profiles from setup)
    func refreshProfiles() async {
        do {
            let freshProfiles = try await keywordRepo.fetchProfiles()
            profiles = freshProfiles
            
            // If selected profile was deleted, clear it
            if let selected = selectedProfile {
                if !freshProfiles.contains(where: { $0.id == selected.id }) {
                    // Profile was deleted — reset
                    selectedProfile = freshProfiles.first(where: \.isActive) ?? freshProfiles.first
                    leads = []
                    scanMessage = nil
                    error = nil
                    currentOffset = 0
                    
                    if selectedProfile != nil {
                        await fetchLeadsForSelectedProfile()
                    }
                } else {
                    // Profile still exists — update it with fresh data (keyword count etc.)
                    selectedProfile = freshProfiles.first { $0.id == selected.id }
                }
            } else {
                // No profile selected — pick one
                selectedProfile = freshProfiles.first(where: \.isActive) ?? freshProfiles.first
                if selectedProfile != nil {
                    await fetchLeadsForSelectedProfile()
                }
            }
        } catch {
            // Silently fail — we already have cached profiles
        }
    }
    
    // MARK: - Profile Switching
    
    /// Switch to a different profile — clears old results and loads new ones
    func switchToProfile(_ profile: TrackingProfile) async {
        guard profile.id != selectedProfile?.id else { return }
        selectedProfile = profile
        scanMessage = nil
        error = nil
        leads = []
        currentOffset = 0
        await fetchLeadsForSelectedProfile()
    }
    
    /// Clear all new leads for current profile
    func clearResults() async {
        guard let profile = selectedProfile else { return }
        do {
            try await leadRepo.clearLeadsForProfile(profileId: profile.id)
            leads = []
            currentOffset = 0
            scanMessage = "Results cleared. Tap 🔍 to find new leads."
        } catch {
            self.error = "Failed to clear results"
        }
    }
    
    // MARK: - Scanning (calls server-side Edge Function)
    
    /// Trigger a server-side scan via Edge Function
    func scanForNewLeads() async {
        guard selectedProfile != nil else {
            error = "No profile selected. Go to Profiles tab to create one."
            return
        }
        
        isScanning = true
        scanMessage = nil
        error = nil
        
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let token = session.accessToken
            
            // Call the server-side Edge Function
            let response: ScanResponse = try await SupabaseManager.shared.client
                .functions
                .invoke(
                    "scan-reddit",
                    options: .init(
                        headers: ["Authorization": "Bearer \(token)"]
                    )
                )
            
            if let err = response.error {
                self.error = err
            } else {
                let found = response.leads_found ?? 0
                if found > 0 {
                    scanMessage = "🎯 \(found) new lead\(found == 1 ? "" : "s") found!"
                } else {
                    scanMessage = "No new leads right now. We'll keep monitoring and notify you when new leads appear."
                }
            }
            
            await fetchLeadsForSelectedProfile()
            
        } catch {
            self.error = "Scan failed: \(error.localizedDescription)"
        }
        
        isScanning = false
    }
    
    // MARK: - Fetching
    
    /// Fetch leads for the selected profile
    func fetchLeadsForSelectedProfile() async {
        guard let profile = selectedProfile else {
            isLoading = false
            return
        }
        
        isLoading = leads.isEmpty
        error = nil
        
        do {
            let fetched = try await leadRepo.fetchLeads(
                profileId: profile.id,
                status: .new,
                limit: pageSize,
                offset: 0
            )
            leads = fetched
            currentOffset = fetched.count
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Legacy fetch (all leads regardless of profile)
    func fetchLeads() async {
        isLoading = leads.isEmpty
        error = nil
        
        do {
            let fetched = try await leadRepo.fetchLeads(status: .new, limit: pageSize, offset: 0)
            leads = fetched
            currentOffset = fetched.count
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Pull to refresh
    func refresh() async {
        isRefreshing = true
        await refreshProfiles()
        await fetchLeadsForSelectedProfile()
        isRefreshing = false
    }
    
    /// Load more leads
    func loadMore() async {
        guard let profile = selectedProfile else { return }
        do {
            let more = try await leadRepo.fetchLeads(
                profileId: profile.id,
                status: .new,
                limit: pageSize,
                offset: currentOffset
            )
            leads.append(contentsOf: more)
            currentOffset += more.count
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    // MARK: - Lead Actions
    
    func saveLead(_ lead: Lead) async {
        do {
            try await leadRepo.updateLeadStatus(leadId: lead.id, status: .saved)
            leads.removeAll { $0.id == lead.id }
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func dismissLead(_ lead: Lead) async {
        do {
            try await leadRepo.updateLeadStatus(leadId: lead.id, status: .dismissed)
            leads.removeAll { $0.id == lead.id }
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func markContacted(_ lead: Lead) async {
        do {
            try await leadRepo.updateLeadStatus(leadId: lead.id, status: .contacted)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func fetchSavedLeads() async {
        do {
            savedLeads = try await leadRepo.fetchLeads(status: .saved, limit: 50, offset: 0)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
