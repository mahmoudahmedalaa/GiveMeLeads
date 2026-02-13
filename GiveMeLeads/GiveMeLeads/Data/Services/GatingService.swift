import Foundation
import Observation

/// Gate check result — either allowed or blocked with a user-facing reason.
enum GateResult {
    case allowed
    case blocked(reason: String)
    
    var isAllowed: Bool {
        if case .allowed = self { return true }
        return false
    }
    
    var blockedReason: String? {
        if case .blocked(let reason) = self { return reason }
        return nil
    }
}

/// Centralized enforcement of plan caps.
/// All checks are local — no network calls. Plan defaults to `.free`
/// and will be upgraded by `SubscriptionManager` once StoreKit is wired.
@MainActor
@Observable
final class GatingService {
    
    // MARK: - Singleton
    
    static let shared = GatingService()
    
    // MARK: - State
    
    /// Current plan — defaults to .free, updated by SubscriptionManager
    var currentPlan: Plan = .free
    
    /// Derived entitlements for the current plan
    var entitlements: Entitlements {
        Entitlements.forPlan(currentPlan)
    }
    
    // MARK: - Daily Scan Tracking
    
    private let scansKey = "daily_scan_count"
    private let scanDateKey = "daily_scan_date"
    
    /// Number of scans performed today
    var scansToday: Int {
        resetIfNewDay()
        return UserDefaults.standard.integer(forKey: scansKey)
    }
    
    /// Record that a scan was performed
    func recordScan() {
        resetIfNewDay()
        let current = UserDefaults.standard.integer(forKey: scansKey)
        UserDefaults.standard.set(current + 1, forKey: scansKey)
    }
    
    // MARK: - Gate Checks
    
    /// Check if user can create a new profile
    func canCreateProfile(existingCount: Int) -> GateResult {
        if existingCount >= entitlements.maxProfiles {
            return .blocked(reason: "Free plan allows \(entitlements.maxProfiles) profile. Upgrade to create more.")
        }
        return .allowed
    }
    
    /// Check if user can add a keyword (total across all profiles)
    func canAddKeyword(totalCount: Int) -> GateResult {
        if totalCount >= entitlements.maxKeywordsTotal {
            return .blocked(reason: "Free plan allows \(entitlements.maxKeywordsTotal) keywords. Upgrade to add more.")
        }
        return .allowed
    }
    
    /// Check if user can perform a scan today
    func canScan() -> GateResult {
        resetIfNewDay()
        let count = UserDefaults.standard.integer(forKey: scansKey)
        if count >= entitlements.maxScansPerDay {
            return .blocked(reason: "You've reached your daily scan limit (\(entitlements.maxScansPerDay)). Upgrade for more scans.")
        }
        return .allowed
    }
    
    /// Maximum number of leads visible for the current plan
    func visibleLeadCount() -> Int {
        entitlements.maxVisibleLeads
    }
    
    /// Check if CSV export is available
    func canExportCSV() -> GateResult {
        entitlements.canExportCSV ? .allowed : .blocked(reason: "CSV export requires a Starter or Pro plan.")
    }
    
    // MARK: - Private
    
    private init() {}
    
    /// Reset scan count if the stored date is not today
    private func resetIfNewDay() {
        let today = Calendar.current.startOfDay(for: Date())
        let storedDate = UserDefaults.standard.object(forKey: scanDateKey) as? Date ?? .distantPast
        let storedDay = Calendar.current.startOfDay(for: storedDate)
        
        if today != storedDay {
            UserDefaults.standard.set(0, forKey: scansKey)
            UserDefaults.standard.set(today, forKey: scanDateKey)
        }
    }
}
