import SwiftUI

/// Paywall screen for subscription management
struct PaywallScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.spacing6) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                
                Spacer()
                
                // Hero
                VStack(spacing: AppSpacing.spacing4) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(AppColors.premiumGradient)
                    
                    Text("Upgrade to Pro")
                        .font(AppTypography.heading1)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Unlock unlimited leads and\nAI-powered replies")
                        .font(AppTypography.bodyLarge)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                // Features
                VStack(alignment: .leading, spacing: AppSpacing.spacing3) {
                    featureRow("Unlimited lead tracking")
                    featureRow("AI reply suggestions")
                    featureRow("Real-time notifications")
                    featureRow("Priority support")
                }
                .padding(AppSpacing.spacing5)
                .background(AppColors.bg700)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                
                Spacer()
                
                // CTA
                VStack(spacing: AppSpacing.spacing3) {
                    PrimaryButton("Start 7-Day Free Trial", isLoading: isLoading) {
                        // TODO: Integrate StoreKit 2 / RevenueCat
                        isLoading = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            isLoading = false
                            dismiss()
                        }
                    }
                    
                    Text("Then $19/month · Cancel anytime")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textTertiary)
                    
                    HStack(spacing: AppSpacing.spacing4) {
                        GhostButton("Privacy Policy") {
                            // TODO: Open privacy policy
                        }
                        Text("·")
                            .foregroundColor(AppColors.textTertiary)
                        GhostButton("Terms of Use") {
                            // TODO: Open terms
                        }
                        Text("·")
                            .foregroundColor(AppColors.textTertiary)
                        GhostButton("Restore") {
                            // TODO: Restore purchases
                        }
                    }
                    .font(AppTypography.bodySmall)
                }
                .padding(.bottom, AppSpacing.spacing4)
            }
            .padding(.horizontal, AppSpacing.spacing6)
        }
    }
    
    private func featureRow(_ text: String) -> some View {
        HStack(spacing: AppSpacing.spacing3) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppColors.primaryGradient)
            Text(text)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

#Preview {
    PaywallScreen()
        .preferredColorScheme(.dark)
}
