import Foundation

/// Plans supported by the app. Defaults to `.free` until StoreKit wires real purchases.
enum Plan: String, Codable, CaseIterable {
    case free
    case starter
    case pro
    
    var displayName: String {
        switch self {
        case .free: "Free"
        case .starter: "Starter"
        case .pro: "Pro"
        }
    }
}

/// Entitlements describe the caps and features available to the current plan.
struct Entitlements: Codable, Equatable {
    let plan: Plan
    let maxProfiles: Int
    let maxKeywordsTotal: Int
    let maxScansPerDay: Int
    let canExportCSV: Bool
    let hasSavedSearches: Bool
    let hasAlerts: Bool
    let hasWebhooks: Bool
    
    /// Convenience for unlimited values
    static let unlimited = 999
}

extension Entitlements {
    static func forPlan(_ plan: Plan) -> Entitlements {
        switch plan {
        case .free:
            return Entitlements(
                plan: .free,
                maxProfiles: 1,
                maxKeywordsTotal: 5,
                maxScansPerDay: 3,
                canExportCSV: false,
                hasSavedSearches: false,
                hasAlerts: false,
                hasWebhooks: false
            )
        case .starter:
            return Entitlements(
                plan: .starter,
                maxProfiles: 3,
                maxKeywordsTotal: 30,
                maxScansPerDay: 15,
                canExportCSV: true,
                hasSavedSearches: false,
                hasAlerts: true,
                hasWebhooks: false
            )
        case .pro:
            return Entitlements(
                plan: .pro,
                maxProfiles: 10,
                maxKeywordsTotal: Entitlements.unlimited,
                maxScansPerDay: Entitlements.unlimited,
                canExportCSV: true,
                hasSavedSearches: true,
                hasAlerts: true,
                hasWebhooks: true
            )
        }
    }
}
