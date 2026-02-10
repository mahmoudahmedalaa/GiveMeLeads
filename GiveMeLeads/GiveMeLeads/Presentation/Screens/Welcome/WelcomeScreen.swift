import SwiftUI
import AuthenticationServices

struct WelcomeScreen: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: AuthViewModel?
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [AppColors.background, AppColors.bg700],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.spacing8) {
                Spacer()
                
                // Logo & branding
                VStack(spacing: AppSpacing.spacing4) {
                    Image(systemName: "target")
                        .font(.system(size: 72))
                        .foregroundStyle(AppColors.primaryGradient)
                        .scaleEffect(animateContent ? 1 : 0.8)
                    
                    Text("GiveMeLeads")
                        .font(AppTypography.heading1)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Find leads that want\nwhat you offer")
                        .font(AppTypography.bodyLarge)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
                
                Spacer()
                
                // Features list
                VStack(alignment: .leading, spacing: AppSpacing.spacing3) {
                    FeatureRow(icon: "magnifyingglass", text: "Track keywords across subreddits")
                    FeatureRow(icon: "chart.bar.fill", text: "AI-powered lead scoring")
                    FeatureRow(icon: "text.bubble.fill", text: "Smart reply suggestions")
                }
                .padding(.horizontal, AppSpacing.spacing4)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 15)
                
                Spacer()
                
                // Sign in with Apple
                VStack(spacing: AppSpacing.spacing4) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.email, .fullName]
                    } onCompletion: { result in
                        Task {
                            await viewModel?.handleAppleSignIn(result: result)
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 52)
                    .cornerRadius(AppSpacing.spacing3)
                    
                    if let error = viewModel?.error {
                        Text(error)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.error)
                    }
                    
                    if viewModel?.isLoading == true {
                        ProgressView()
                            .tint(AppColors.primary500)
                    }
                    
                    Text("By continuing, you agree to our Terms and Privacy Policy")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 30)
                .padding(.bottom, AppSpacing.spacing8)
            }
            .padding(.horizontal, AppSpacing.spacing6)
        }
        .onAppear {
            viewModel = AuthViewModel(router: router)
            
            // Check existing session first
            Task {
                await viewModel?.checkSession()
            }
            
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animateContent = true
            }
        }
    }
}

// MARK: - Feature Row
private struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: AppSpacing.spacing3) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.primary500)
                .frame(width: 28, height: 28)
                .background(AppColors.primary500.opacity(0.12))
                .cornerRadius(8)
            
            Text(text)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

#Preview {
    WelcomeScreen()
        .environment(AppRouter())
}
