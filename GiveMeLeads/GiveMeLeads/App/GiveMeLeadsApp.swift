import SwiftUI

@main
struct GiveMeLeadsApp: App {
    @State private var appRouter = AppRouter()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appRouter)
                .preferredColorScheme(.dark)
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
