import SwiftUI

/// Circular badge showing lead AI intent score (0-10)
struct ScoreBadge: View {
    let score: Int
    let size: BadgeSize
    
    enum BadgeSize {
        case small  // In card
        case large  // In detail view
        
        var diameter: CGFloat {
            switch self {
            case .small: 40
            case .large: 80
            }
        }
        
        var font: Font {
            switch self {
            case .small: AppTypography.scoreBadge
            case .large: AppTypography.scoreTitle
            }
        }
        
        var strokeWidth: CGFloat {
            switch self {
            case .small: 2
            case .large: 4
            }
        }
    }
    
    var scoreColor: Color {
        AppColors.scoreColor(for: score)
    }
    
    /// Human-readable tier label
    static func tierLabel(for score: Int) -> String {
        if score >= 8 { return "🔥 Hot Lead" }
        if score >= 6 { return "🎯 Strong" }
        if score >= 4 { return "👍 Decent" }
        return "🔍 Low"
    }
    
    var body: some View {
        VStack(spacing: size == .large ? 4 : 0) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(scoreColor.opacity(0.2), lineWidth: size.strokeWidth)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 10)
                    .stroke(
                        scoreColor,
                        style: StrokeStyle(lineWidth: size.strokeWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                // Score number
                Text("\(score)")
                    .font(size.font)
                    .foregroundColor(scoreColor)
            }
            .frame(width: size.diameter, height: size.diameter)
            
            if size == .large {
                Text(ScoreBadge.tierLabel(for: score))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(scoreColor)
            }
        }
    }
}

/// Score breakdown showing intent, urgency, fit
struct ScoreBreakdownView: View {
    let breakdown: ScoreBreakdown
    
    var body: some View {
        HStack(spacing: AppSpacing.spacing4) {
            ScoreChip(label: "Intent", value: breakdown.intentDisplay, color: AppColors.scoreHigh)
            ScoreChip(label: "Urgency", value: breakdown.urgencyDisplay, color: AppColors.warning)
            ScoreChip(label: "Fit", value: breakdown.fitDisplay, color: AppColors.accentCyan)
        }
    }
}

struct ScoreChip: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: AppSpacing.spacing1) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(label): \(value)/10")
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.horizontal, AppSpacing.spacing2)
        .padding(.vertical, AppSpacing.spacing1)
        .background(AppColors.bgGlass)
        .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 24) {
        ScoreBadge(score: 9, size: .large)
        ScoreBadge(score: 7, size: .small)
        ScoreBadge(score: 3, size: .small)
        ScoreBreakdownView(breakdown: ScoreBreakdown(intent: 9, urgency: 8, fit: 9))
    }
    .padding()
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}
