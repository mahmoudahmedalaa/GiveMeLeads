import SwiftUI

struct WelcomeScreen: View {
    @Environment(AppRouter.self) private var router
    @State private var showLogin = false
    @State private var animateContent = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
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
                    
                    // CTA buttons
                    VStack(spacing: AppSpacing.spacing4) {
                        PrimaryButton("Get Started", icon: "arrow.right") {
                            // TODO: Navigate to onboarding
                            router.handleAuthStateChange(isAuthenticated: true)
                        }
                        
                        GhostButton("Already have an account? Sign In") {
                            showLogin = true
                        }
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 30)
                    .padding(.bottom, AppSpacing.spacing8)
                }
                .padding(.horizontal, AppSpacing.spacing6)
            }
            .navigationDestination(isPresented: $showLogin) {
                Text("Login Screen") // TODO: Replace with LoginScreen
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animateContent = true
            }
        }
    }
}

#Preview {
    WelcomeScreen()
        .environment(AppRouter())
}
