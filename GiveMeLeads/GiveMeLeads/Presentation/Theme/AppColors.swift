import SwiftUI

/// Design system colors from FRONTEND_GUIDELINES.md — adaptive for light/dark mode
enum AppColors {
    
    // MARK: - Primary Colors (Electric Purple)
    // Brand colors stay the same in both modes
    static let primary50  = Color(hex: "#F5F3FF")
    static let primary100 = Color(hex: "#EDE9FE")
    static let primary200 = Color(hex: "#DDD6FE")
    static let primary300 = Color(hex: "#C4B5FD")
    static let primary400 = Color(hex: "#A78BFA")
    static let primary500 = Color(hex: "#8B5CF6") // Main brand
    static let primary600 = Color(hex: "#7C3AED") // CTA buttons
    static let primary700 = Color(hex: "#6D28D9")
    static let primary800 = Color(hex: "#5B21B6")
    static let primary900 = Color(hex: "#4C1D95")
    
    // MARK: - Background Colors — adaptive
    static let bg900  = Color(light: "#F8F8FC", dark: "#06060B")
    static let bg800  = Color(light: "#F0F0F7", dark: "#0A0A12")  // Screen background ★
    static let bg700  = Color(light: "#FFFFFF", dark: "#111119")  // Card background
    static let bg600  = Color(light: "#F5F5FA", dark: "#1A1A24")  // Elevated card / sheet
    static let bg500  = Color(light: "#EAEAF0", dark: "#252530")  // Input background
    static let bgGlass = Color(light: .black.opacity(0.04), dark: .white.opacity(0.06))
    
    /// Primary screen background
    static let background = bg800
    
    // MARK: - Accent Colors
    static let accentCyan = Color(hex: "#06B6D4")
    static let accentBlue = Color(hex: "#3B82F6")
    
    // MARK: - Score Colors
    static let scoreHigh   = Color(hex: "#10B981") // ≥8
    static let scoreMedium = Color(hex: "#F59E0B") // 5-7
    static let scoreLow    = Color(hex: "#6B7280") // <5
    
    static func scoreColor(for score: Int) -> Color {
        switch score {
        case 8...10:  return scoreHigh
        case 5..<8:   return scoreMedium
        default:      return scoreLow
        }
    }
    
    // MARK: - Semantic Colors
    static let success = Color(hex: "#10B981")
    static let warning = Color(hex: "#F59E0B")
    static let error   = Color(hex: "#EF4444")
    static let info    = Color(hex: "#3B82F6")
    
    // MARK: - Text Colors — adaptive
    static let textPrimary   = Color(light: .black.opacity(0.88), dark: .white.opacity(0.92))
    static let textSecondary = Color(light: .black.opacity(0.56), dark: .white.opacity(0.64))
    static let textTertiary  = Color(light: .black.opacity(0.36), dark: .white.opacity(0.40))
    static let textInverse   = Color(light: .white, dark: Color(hex: "#06060B"))
    
    // MARK: - Gradients
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "#8B5CF6"), Color(hex: "#3B82F6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let scoreHighGradient = LinearGradient(
        colors: [Color(hex: "#10B981"), Color(hex: "#06B6D4")],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let backgroundGradient = LinearGradient(
        colors: [bg800, bg900],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let premiumGradient = LinearGradient(
        colors: [Color(hex: "#F59E0B"), Color(hex: "#EF4444")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Create an adaptive color that changes based on light/dark mode
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
    
    /// Convenience: adaptive color from hex strings
    init(light lightHex: String, dark darkHex: String) {
        self.init(light: Color(hex: lightHex), dark: Color(hex: darkHex))
    }
}
