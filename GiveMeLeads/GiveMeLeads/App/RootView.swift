import SwiftUI

struct RootView: View {
    @Environment(AppRouter.self) private var router
    
    var body: some View {
        Group {
            switch router.authState {
            case .loading:
                SplashView()
            case .unauthenticated:
                WelcomeScreen()
            case .needsSetup:
                ProductSetupScreen(isModal: false) {
                    router.setupComplete()
                }
            case .authenticated:
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: router.authState)
        .task {
            // Check for existing session on app launch
            let authVM = AuthViewModel(router: router)
            await authVM.checkSession()
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
