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
                    Label(AppTab.keywords.title, systemImage: AppTab.keywords.icon)
                }
                .tag(AppTab.keywords)
            
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
    }
}

#Preview {
    MainTabView()
        .environment(AppRouter())
        .preferredColorScheme(.dark)
}
