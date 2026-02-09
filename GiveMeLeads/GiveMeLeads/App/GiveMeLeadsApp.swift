import SwiftUI

@main
struct GiveMeLeadsApp: App {
    @State private var appRouter = AppRouter()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appRouter)
                .preferredColorScheme(.dark)
        }
    }
}
