import Foundation
import Observation

/// Lightweight local gating for plan-based limits.
/// Defaults to `.free` until StoreKit delivers a real plan.
@Observable
final class GatingService {
    static let shared = GatingService()
    
    var currentPlan: Plan = .free {
        didSet {
            entitlements = Entitlements.forPlan(currentPlan)
        }
    }
    
    var entitlements: Entitlements
    
    private static let scansTodayKey = "gating_scansToday"
    private static let scanResetDateKey = "gating_scanResetDate"
    
    private init() {
        self.entitlements = Entitlements.forPlan(.free)
    }
    
    // MARK: - Daily Scan Tracking (persisted)
    
    var scansToday: Int {
        get {
            resetDailyScansIfNeeded()
            return UserDefaults.standard.integer(forKey: Self.scansTodayKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.scansTodayKey)
        }
    }
    
    private var scanResetDate: Date {
        get {
            let stored = UserDefaults.standard.object(forKey: Self.scanResetDateKey) as? Date
            return stored ?? Date()
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.scanResetDateKey)
        }
    }
    
    func recordScan() {
        resetDailyScansIfNeeded()
        scansToday += 1
    }
    
    private func resetDailyScansIfNeeded() {
        let stored = UserDefaults.standard.object(forKey: Self.scanResetDateKey) as? Date ?? Date()
        if !Calendar.current.isDateInToday(stored) {
            UserDefaults.standard.set(0, forKey: Self.scansTodayKey)
            UserDefaults.standard.set(Date(), forKey: Self.scanResetDateKey)
        }
    }
    
    /// How many leads to show (no cap — all leads visible)
    func visibleLeadCount() -> Int {
        return Int.max
    }
    
    // MARK: - Gating Checks
    
    enum GateResult {
        case allowed
        case blocked(reason: String)
        
        var isAllowed: Bool {
            if case .allowed = self { return true }
            return false
        }
    }
    
    /// Can the user create another profile?
    func canCreateProfile(existingCount: Int) -> GateResult {
        if existingCount >= entitlements.maxProfiles {
            return .blocked(reason: "Your \(currentPlan.displayName) plan allows \(entitlements.maxProfiles) profile\(entitlements.maxProfiles == 1 ? "" : "s"). Upgrade to create more.")
        }
        return .allowed
    }
    
    /// Can the user add another keyword?
    func canAddKeyword(existingCount: Int) -> GateResult {
        if entitlements.maxKeywordsTotal == Entitlements.unlimited {
            return .allowed
        }
        if existingCount >= entitlements.maxKeywordsTotal {
            return .blocked(reason: "Your \(currentPlan.displayName) plan allows \(entitlements.maxKeywordsTotal) keywords. Upgrade to add more.")
        }
        return .allowed
    }
    
    /// Can the user run another scan today? (called with explicit count)
    func canScan(todaysScans: Int) -> GateResult {
        if entitlements.maxScansPerDay == Entitlements.unlimited {
            return .allowed
        }
        if todaysScans >= entitlements.maxScansPerDay {
            return .blocked(reason: "You've used all \(entitlements.maxScansPerDay) scans for today. Upgrade for more.")
        }
        return .allowed
    }
    
    /// Convenience — uses internal scan counter
    func canScan() -> GateResult {
        resetDailyScansIfNeeded()
        return canScan(todaysScans: scansToday)
    }
    
    /// Can the user export to CSV?
    func canExportCSV() -> GateResult {
        entitlements.canExportCSV ? .allowed : .blocked(reason: "CSV export is available on Starter and Pro plans.")
    }
}
