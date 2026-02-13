import SwiftUI

/// A blurred placeholder lead card shown below the upgrade banner.
/// Tapping it opens the paywall. Uses a fixed fake layout so the blur
/// doesn't depend on real data.
struct BlurredLeadCard: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.spacing3) {
                // Fake top row
                HStack(spacing: AppSpacing.spacing2) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppColors.primary500.opacity(0.3))
                        .frame(width: 36, height: 20)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.primary500.opacity(0.15))
                        .frame(width: 60, height: 20)
                    
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.textTertiary.opacity(0.2))
                        .frame(width: 40, height: 14)
                }
                
                // Fake title
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.textPrimary.opacity(0.15))
                    .frame(height: 18)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.textPrimary.opacity(0.1))
                    .frame(width: 200, height: 18)
                
                // Fake insight row
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.accentCyan.opacity(0.08))
                    .frame(height: 40)
                
                // Fake action buttons
                HStack(spacing: AppSpacing.spacing2) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppColors.bg600.opacity(0.3))
                            .frame(height: 28)
                    }
                }
            }
            .padding(AppSpacing.spacing4)
            .background(AppColors.bg700)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .strokeBorder(
                        (AppColors.scoreColor(for: 7)).opacity(0.15),
                        lineWidth: 1
                    )
            )
            .blur(radius: 6)
            .overlay(
                // Lock icon overlay on top of blur
                VStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AppColors.premiumGradient)
                    Text("Upgrade to view")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 12) {
        BlurredLeadCard {}
        BlurredLeadCard {}
    }
    .padding()
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}
