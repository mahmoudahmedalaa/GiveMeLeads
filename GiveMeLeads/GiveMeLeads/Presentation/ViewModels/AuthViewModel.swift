import Foundation
import AuthenticationServices
import Observation

/// ViewModel for authentication flow
@Observable
final class AuthViewModel {
    var isLoading = false
    var error: String?
    
    private let authRepo: AuthRepositoryProtocol
    private let router: AppRouter
    
    init(authRepo: AuthRepositoryProtocol = AuthRepository(), router: AppRouter) {
        self.authRepo = authRepo
        self.router = router
    }
    
    /// Check for existing session on app launch
    func checkSession() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            if let _ = try await authRepo.getCurrentSession() {
                router.handleAuthStateChange(isAuthenticated: true)
            } else {
                router.handleAuthStateChange(isAuthenticated: false)
            }
        } catch {
            router.handleAuthStateChange(isAuthenticated: false)
        }
    }
    
    /// Handle Sign in with Apple result
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let identityToken = credential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8) else {
                error = "Invalid Apple credentials"
                return
            }
            
            do {
                let _ = try await authRepo.signInWithApple(
                    idToken: tokenString,
                    nonce: "" // Supabase handles nonce internally
                )
                router.handleAuthStateChange(isAuthenticated: true)
            } catch {
                self.error = error.localizedDescription
            }
            
        case .failure(let err):
            if (err as NSError).code != ASAuthorizationError.canceled.rawValue {
                error = err.localizedDescription
            }
        }
    }
    
    /// Sign out
    func signOut() async {
        do {
            try await authRepo.signOut()
            router.signOut()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    /// Delete account
    func deleteAccount() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await authRepo.deleteAccount()
            router.signOut()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
