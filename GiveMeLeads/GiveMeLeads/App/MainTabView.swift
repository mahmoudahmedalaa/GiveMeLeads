import SwiftUI

struct MainTabView: View {
    @Environment(AppRouter.self) private var router
    
    var body: some View {
        @Bindable var router = router
        
        TabView(selection: $router.selectedTab) {
            LeadFeedScreen()
                .tabItem {
                    Label(AppTab.leads.title, systemImage: AppTab.leads.icon)
                }
                .tag(AppTab.leads)
            
            KeywordListScreen()
                .tabItem {
                    Label(AppTab.profiles.title, systemImage: AppTab.profiles.icon)
                }
                .tag(AppTab.profiles)
            
            SavedLeadsScreen()
                .tabItem {
                    Label(AppTab.saved.title, systemImage: AppTab.saved.icon)
                }
                .tag(AppTab.saved)
            
            SettingsScreen()
                .tabItem {
                    Label(AppTab.settings.title, systemImage: AppTab.settings.icon)
                }
                .tag(AppTab.settings)
        }
        .tint(AppColors.primary500)
        .fullScreenCover(isPresented: $router.showPaywall) {
            PaywallScreen()
        }
        .fullScreenCover(isPresented: $router.showProductSetup) {
            ProductSetupScreen(isModal: true) {
                router.setupComplete()
            }
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppRouter())
        .preferredColorScheme(.dark)
}
