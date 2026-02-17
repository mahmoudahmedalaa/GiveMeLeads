import Foundation
import Supabase

/// Supabase-backed lead repository
final class LeadRepository: LeadRepositoryProtocol {
    private let client = SupabaseManager.shared.client
    
    func fetchLeads(status: LeadStatus?, limit: Int = 20, offset: Int = 0) async throws -> [Lead] {
        var query = client
            .from("leads")
            .select()
        
        if let status {
            query = query.eq("status", value: status.rawValue)
        }
        
        let response: [Lead] = try await query
            .order("score", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return response
    }
    
    func updateLeadStatus(leadId: UUID, status: LeadStatus) async throws {
        try await client
            .from("leads")
            .update(["status": status.rawValue])
            .eq("id", value: leadId.uuidString)
            .execute()
    }
    
    func getLead(id: UUID) async throws -> Lead? {
        let response: [Lead] = try await client
            .from("leads")
            .select()
            .eq("id", value: id.uuidString)
            .execute()
            .value
        return response.first
    }
    
    func getLeadCount(status: LeadStatus?) async throws -> Int {
        var query = client
            .from("leads")
            .select("id", head: true, count: .exact)
        
        if let status {
            query = query.eq("status", value: status.rawValue)
        }
        
        let response = try await query.execute()
        return response.count ?? 0
    }
    
    func fetchLeads(profileId: UUID, status: LeadStatus?, limit: Int = 20, offset: Int = 0) async throws -> [Lead] {
        var query = client
            .from("leads")
            .select()
            .eq("profile_id", value: profileId.uuidString)
        
        if let status {
            query = query.eq("status", value: status.rawValue)
        }
        
        let response: [Lead] = try await query
            .order("score", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return response
    }
    
    func getLeadCount(profileId: UUID, status: LeadStatus?) async throws -> Int {
        var query = client
            .from("leads")
            .select("id", head: true, count: .exact)
            .eq("profile_id", value: profileId.uuidString)
        
        if let status {
            query = query.eq("status", value: status.rawValue)
        }
        
        let response = try await query.execute()
        return response.count ?? 0
    }
    
    func clearLeadsForProfile(profileId: UUID) async throws {
        try await client
            .from("leads")
            .delete()
            .eq("profile_id", value: profileId.uuidString)
            .eq("status", value: LeadStatus.new.rawValue)
            .execute()
    }
    
    func deleteLead(leadId: UUID) async throws {
        try await client
            .from("leads")
            .delete()
            .eq("id", value: leadId.uuidString)
            .execute()
    }
}
