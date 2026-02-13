import Foundation

/// Plans supported by the app. Defaults to `.free` until StoreKit wires real purchases.
enum Plan: String, Codable, CaseIterable {
    case free
    case starter
    case pro
}

/// Entitlements describe the caps and features available to the current plan.
struct Entitlements: Codable, Equatable {
    let plan: Plan
    let maxProfiles: Int
    let maxKeywordsTotal: Int
    let maxScansPerDay: Int
    let maxVisibleLeads: Int
    let canExportCSV: Bool
    let hasSavedSearches: Bool
    let hasAlerts: Bool
    let hasWebhooks: Bool
}

extension Entitlements {
    static func forPlan(_ plan: Plan) -> Entitlements {
        switch plan {
        case .free:
            return Entitlements(
                plan: .free,
                maxProfiles: 1,
                maxKeywordsTotal: 5,
                maxScansPerDay: 1,
                maxVisibleLeads: 5,
                canExportCSV: false,
                hasSavedSearches: false,
                hasAlerts: false,
                hasWebhooks: false
            )
        case .starter:
            return Entitlements(
                plan: .starter,
                maxProfiles: 5,
                maxKeywordsTotal: 100,
                maxScansPerDay: 10,
                maxVisibleLeads: 500,
                canExportCSV: true,
                hasSavedSearches: false,
                hasAlerts: true,
                hasWebhooks: false
            )
        case .pro:
            return Entitlements(
                plan: .pro,
                maxProfiles: 20,
                maxKeywordsTotal: 1000,
                maxScansPerDay: 100,
                maxVisibleLeads: 5000,
                canExportCSV: true,
                hasSavedSearches: true,
                hasAlerts: true,
                hasWebhooks: true
            )
        }
    }
}
