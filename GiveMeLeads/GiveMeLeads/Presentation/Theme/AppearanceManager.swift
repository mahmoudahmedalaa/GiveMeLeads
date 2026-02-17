import SwiftUI

/// Manages the user's appearance preference (System / Light / Dark).
/// Persisted via UserDefaults so it survives app restarts.
@Observable
final class AppearanceManager {
    static let shared = AppearanceManager()
    
    enum Mode: String, CaseIterable {
        case system
        case light
        case dark
        
        var displayName: String {
            switch self {
            case .system: "System"
            case .light: "Light"
            case .dark: "Dark"
            }
        }
    }
    
    /// The current appearance mode — persisted via UserDefaults
    var mode: Mode {
        get {
            let stored = UserDefaults.standard.string(forKey: "appearanceMode") ?? "system"
            return Mode(rawValue: stored) ?? .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "appearanceMode")
        }
    }
    
    /// Returns the SwiftUI ColorScheme to apply, or nil for system default
    var colorScheme: ColorScheme? {
        switch mode {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
    
    private init() {}
}
