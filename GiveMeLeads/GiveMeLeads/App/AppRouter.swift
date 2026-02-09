import SwiftUI
import Observation

enum AuthState: Equatable {
    case loading
    case unauthenticated
    case authenticated
}

@Observable
final class AppRouter {
    var authState: AuthState = .loading
    var selectedTab: AppTab = .leads
    var showPaywall: Bool = false
    
    func handleAuthStateChange(isAuthenticated: Bool) {
        withAnimation(.easeInOut(duration: 0.3)) {
            authState = isAuthenticated ? .authenticated : .unauthenticated
        }
    }
    
    func signOut() {
        withAnimation(.easeInOut(duration: 0.3)) {
            authState = .unauthenticated
        }
    }
}

enum AppTab: Int, CaseIterable, Identifiable {
    case leads = 0
    case keywords = 1
    case saved = 2
    case settings = 3
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .leads: "Leads"
        case .keywords: "Keywords"
        case .saved: "Saved"
        case .settings: "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .leads: "target"
        case .keywords: "magnifyingglass"
        case .saved: "bookmark.fill"
        case .settings: "gearshape.fill"
        }
    }
}
