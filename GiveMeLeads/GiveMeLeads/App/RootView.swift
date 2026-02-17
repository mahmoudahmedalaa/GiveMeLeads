import SwiftUI

struct RootView: View {
    @Environment(AppRouter.self) private var router
    @State private var authViewModel: AuthViewModel?
    
    var body: some View {
        Group {
            switch router.authState {
            case .loading:
                SplashView()
            case .unauthenticated:
                WelcomeScreen()
            case .needsOnboarding:
                OnboardingScreen {
                    router.onboardingComplete()
                }
            case .needsSetup:
                ProductSetupScreen(isModal: false, onSkip: {
                    router.skipSetup()
                }) {
                    router.setupComplete()
                }
            case .authenticated:
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: router.authState)
        .task {
            // Reuse the same AuthViewModel instance across re-renders
            if authViewModel == nil {
                authViewModel = AuthViewModel(router: router)
            }
            await authViewModel?.checkSession()
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.spacing4) {
                Image(systemName: "target")
                    .font(.system(size: 64))
                    .foregroundStyle(AppColors.primaryGradient)
                
                Text("GiveMeLeads")
                    .font(AppTypography.heading1)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
    }
}

#Preview {
    RootView()
        .environment(AppRouter())
}
