import SwiftUI

/// Empty state view with illustration and CTA
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.spacing6) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(AppColors.primaryGradient)
            
            VStack(spacing: AppSpacing.spacing2) {
                Text(title)
                    .font(AppTypography.heading2)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(message)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle, let action {
                PrimaryButton(actionTitle, action: action)
                    .frame(maxWidth: 240)
            }
        }
        .padding(AppSpacing.spacing8)
    }
}

/// Loading skeleton placeholder
struct SkeletonCard: View {
    @State private var opacity: Double = 0.3
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing3) {
            HStack {
                Circle()
                    .fill(AppColors.bg500)
                    .frame(width: 40, height: 40)
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.bg500)
                    .frame(width: 80, height: 16)
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.bg500)
                    .frame(width: 40, height: 12)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.bg500)
                    .frame(height: 16)
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.bg500)
                    .frame(width: 200, height: 16)
            }
            
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.bg500)
                    .frame(width: 100, height: 12)
                Spacer()
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.bg500)
                        .frame(width: 40, height: 12)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.bg500)
                        .frame(width: 40, height: 12)
                }
            }
        }
        .padding(AppSpacing.spacing5)
        .background(AppColors.bg700)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                opacity = 0.6
            }
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            EmptyStateView(
                icon: "target",
                title: "No Leads Yet",
                message: "Set up keywords to start discovering\nhigh-intent leads on Reddit",
                actionTitle: "Add Keywords",
                action: {}
            )
            
            ForEach(0..<3, id: \.self) { _ in
                SkeletonCard()
            }
        }
        .padding()
    }
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}
