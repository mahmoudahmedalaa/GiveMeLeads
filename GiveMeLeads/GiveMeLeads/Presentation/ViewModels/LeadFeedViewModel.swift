import Foundation
import Observation

/// ViewModel for lead feed and saved leads
@Observable
final class LeadFeedViewModel {
    var leads: [Lead] = []
    var savedLeads: [Lead] = []
    var isLoading = false
    var isRefreshing = false
    var isScanning = false
    var scanMessage: String?
    var error: String?
    var selectedLead: Lead?
    
    private let leadRepo: LeadRepositoryProtocol
    private let scanService = RedditScanService()
    private var currentOffset = 0
    private let pageSize = 20
    
    init(leadRepo: LeadRepositoryProtocol = LeadRepository()) {
        self.leadRepo = leadRepo
    }
    
    /// Trigger a Reddit scan for new leads
    func scanForNewLeads(accessToken: String) async {
        isScanning = true
        scanMessage = nil
        error = nil
        
        do {
            let result = try await scanService.scanReddit(accessToken: accessToken)
            scanMessage = "\(result.leadsFound) new lead\(result.leadsFound == 1 ? "" : "s") found"
            
            // Refresh leads list after scan
            if result.leadsFound > 0 {
                await fetchLeads()
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        isScanning = false
    }
    
    /// Fetch new leads
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
        await fetchLeads()
        isRefreshing = false
    }
    
    /// Load more leads (pagination)
    func loadMore() async {
        do {
            let more = try await leadRepo.fetchLeads(status: .new, limit: pageSize, offset: currentOffset)
            leads.append(contentsOf: more)
            currentOffset += more.count
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    /// Save a lead (swipe right)
    func saveLead(_ lead: Lead) async {
        do {
            try await leadRepo.updateLeadStatus(leadId: lead.id, status: .saved)
            leads.removeAll { $0.id == lead.id }
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    /// Dismiss a lead (swipe left)
    func dismissLead(_ lead: Lead) async {
        do {
            try await leadRepo.updateLeadStatus(leadId: lead.id, status: .dismissed)
            leads.removeAll { $0.id == lead.id }
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    /// Mark as contacted
    func markContacted(_ lead: Lead) async {
        do {
            try await leadRepo.updateLeadStatus(leadId: lead.id, status: .contacted)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    /// Fetch saved leads
    func fetchSavedLeads() async {
        do {
            savedLeads = try await leadRepo.fetchLeads(status: .saved, limit: 50, offset: 0)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
