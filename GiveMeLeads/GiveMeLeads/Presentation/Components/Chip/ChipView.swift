import SwiftUI

/// Chip/tag component for keywords and subreddits
struct ChipView: View {
    let text: String
    let style: ChipStyle
    let onDelete: (() -> Void)?
    
    enum ChipStyle {
        case keyword
        case subreddit
        case status(LeadStatus)
        
        var backgroundColor: Color {
            switch self {
            case .keyword: AppColors.bgGlass
            case .subreddit: AppColors.primary500.opacity(0.15)
            case .status(let status):
                switch status {
                case .new: AppColors.accentBlue.opacity(0.15)
                case .saved: AppColors.primary500.opacity(0.15)
                case .contacted: AppColors.success.opacity(0.15)
                case .dismissed: AppColors.scoreLow.opacity(0.15)
                case .converted: AppColors.scoreHigh.opacity(0.15)
                }
            }
        }
        
        var textColor: Color {
            switch self {
            case .keyword: AppColors.textSecondary
            case .subreddit: AppColors.primary400
            case .status(let status):
                switch status {
                case .new: AppColors.accentBlue
                case .saved: AppColors.primary400
                case .contacted: AppColors.success
                case .dismissed: AppColors.scoreLow
                case .converted: AppColors.scoreHigh
                }
            }
        }
    }
    
    init(_ text: String, style: ChipStyle = .keyword, onDelete: (() -> Void)? = nil) {
        self.text = text
        self.style = style
        self.onDelete = onDelete
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.spacing1) {
            Text(text)
                .font(AppTypography.bodySmall)
                .foregroundColor(style.textColor)
            
            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(style.textColor.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, AppSpacing.spacing3)
        .padding(.vertical, AppSpacing.spacing1 + 2)
        .background(style.backgroundColor)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }
}

#Preview {
    VStack(spacing: 12) {
        HStack {
            ChipView("project management", onDelete: {})
            ChipView("task app")
        }
        HStack {
            ChipView("r/SaaS", style: .subreddit)
            ChipView("r/productivity", style: .subreddit)
        }
        HStack {
            ChipView("New", style: .status(.new))
            ChipView("Saved", style: .status(.saved))
            ChipView("Contacted", style: .status(.contacted))
        }
    }
    .padding()
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}
