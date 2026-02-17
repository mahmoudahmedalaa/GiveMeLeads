import SwiftUI
import Observation

enum AuthState: Equatable {
    case loading
    case unauthenticated
    case needsOnboarding // First-time user → show onboarding slides
    case needsSetup      // Authenticated but no tracking profiles yet
    case authenticated   // Authenticated and has profiles → show main tabs
}

@Observable
final class AppRouter {
    var authState: AuthState = .loading
    var selectedTab: AppTab = .leads
    var showPaywall: Bool = false
    var showProductSetup: Bool = false  // For creating new profile from Profiles tab
    
    private static let hasSeenOnboardingKey = "hasSeenOnboarding"
    
    var hasSeenOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: Self.hasSeenOnboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.hasSeenOnboardingKey) }
    }
    
    func handleAuthStateChange(isAuthenticated: Bool) {
        if isAuthenticated {
            // First-time user → show onboarding first
            if !hasSeenOnboarding {
                withAnimation(.easeInOut(duration: 0.3)) {
                    authState = .needsOnboarding
                }
            } else {
                Task { @MainActor in
                    await checkNeedsSetup()
                }
            }
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                authState = .unauthenticated
            }
        }
    }
    
    /// Called when onboarding finishes (after paywall shown/dismissed)
    func onboardingComplete() {
        hasSeenOnboarding = true
        Task { @MainActor in
            await checkNeedsSetup()
        }
    }
    
    /// Check if user has any tracking profiles. If not → setup screen.
    func checkNeedsSetup() async {
        do {
            let profiles: [TrackingProfile] = try await SupabaseManager.shared.client
                .from("tracking_profiles")
                .select()
                .limit(1)
                .execute()
                .value
            
            withAnimation(.easeInOut(duration: 0.3)) {
                authState = profiles.isEmpty ? .needsSetup : .authenticated
            }
        } catch {
            // If check fails, go to main view anyway
            withAnimation(.easeInOut(duration: 0.3)) {
                authState = .authenticated
            }
        }
    }
    
    func setupComplete() {
        withAnimation(.easeInOut(duration: 0.3)) {
            authState = .authenticated
            selectedTab = .leads
            showProductSetup = false
        }
    }
    
    /// Skip setup — go directly to main tabs (for returning users who don't want to create a profile right now)
    func skipSetup() {
        withAnimation(.easeInOut(duration: 0.3)) {
            authState = .authenticated
            selectedTab = .leads
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
    case profiles = 1
    case saved = 2
    case settings = 3
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .leads: "Leads"
        case .profiles: "Profiles"
        case .saved: "Saved"
        case .settings: "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .leads: "target"
        case .profiles: "person.crop.rectangle.stack"
        case .saved: "bookmark.fill"
        case .settings: "gearshape.fill"
        }
    }
}
