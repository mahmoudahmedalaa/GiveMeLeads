import SwiftUI

@main
struct GiveMeLeadsApp: App {
    @State private var appRouter = AppRouter()
    @State private var appearance = AppearanceManager.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appRouter)
                .preferredColorScheme(appearance.colorScheme)
                .onOpenURL { url in
                    // Handle magic link deep link callback
                    Task {
                        let authVM = AuthViewModel(router: appRouter)
                        await authVM.handleDeepLink(url: url)
                    }
                }
        }
    }
}
