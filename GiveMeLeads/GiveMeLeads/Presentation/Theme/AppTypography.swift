import SwiftUI

/// Typography system from FRONTEND_GUIDELINES.md
enum AppTypography {
    // Headings — Poppins (fallback to system rounded if not available)
    static let heading1 = Font.system(size: 28, weight: .bold, design: .rounded)
    static let heading2 = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let heading3 = Font.system(size: 18, weight: .semibold, design: .rounded)
    
    // Body — SF Pro (system)
    static let bodyLarge  = Font.system(size: 16, weight: .regular)
    static let bodyMedium = Font.system(size: 14, weight: .regular)
    static let bodySmall  = Font.system(size: 12, weight: .regular)
    
    // Special
    static let scoreBadge = Font.system(size: 14, weight: .bold, design: .rounded)
    static let scoreTitle = Font.system(size: 32, weight: .bold, design: .rounded)
    static let mono       = Font.system(size: 12, design: .monospaced)
    static let caption    = Font.system(size: 11, weight: .medium)
    
    static let buttonLarge  = Font.system(size: 16, weight: .semibold)
    static let buttonMedium = Font.system(size: 14, weight: .semibold)
    static let buttonSmall  = Font.system(size: 12, weight: .semibold)
}
