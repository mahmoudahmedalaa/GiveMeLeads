import SwiftUI

/// Primary CTA button with gradient background
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            HStack(spacing: AppSpacing.spacing2) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    if let icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                }
            }
            .font(AppTypography.buttonLarge)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AppColors.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
        }
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .opacity(isLoading ? 0.8 : 1.0)
        .disabled(isLoading)
        .animation(.easeOut(duration: 0.15), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

/// Secondary bordered button
struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.spacing2) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(AppTypography.buttonMedium)
            .foregroundColor(AppColors.primary400)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(AppColors.bgGlass)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .stroke(AppColors.primary500.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

/// Ghost text button for tertiary actions
struct GhostButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.buttonMedium)
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton("Get Started", icon: "arrow.right") {}
        SecondaryButton("Copy Reply", icon: "doc.on.doc") {}
        GhostButton("Skip") {}
    }
    .padding()
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}
