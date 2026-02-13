import SwiftUI

/// Banner shown after visible leads when the user has hit their plan's lead cap.
/// Tapping it opens the paywall.
struct UpgradeBanner: View {
    let hiddenCount: Int
    let onUpgrade: () -> Void
    
    var body: some View {
        Button(action: onUpgrade) {
            HStack(spacing: AppSpacing.spacing3) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(AppColors.premiumGradient)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("+\(hiddenCount) more lead\(hiddenCount == 1 ? "" : "s") found")
                        .font(AppTypography.heading3)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Upgrade to unlock all your leads")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.primary400)
            }
            .padding(AppSpacing.spacing4)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .fill(AppColors.bg700)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .strokeBorder(AppColors.primary500.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    UpgradeBanner(hiddenCount: 12) {}
        .padding()
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}
