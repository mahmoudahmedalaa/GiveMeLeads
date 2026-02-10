import SwiftUI
import AuthenticationServices

struct WelcomeScreen: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: AuthViewModel?
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [AppColors.background, AppColors.bg700],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.spacing6) {
                Spacer()
                
                // Logo & branding
                VStack(spacing: AppSpacing.spacing4) {
                    Image(systemName: "target")
                        .font(.system(size: 72))
                        .foregroundStyle(AppColors.primaryGradient)
                        .scaleEffect(animateContent ? 1 : 0.8)
                    
                    Text("GiveMeLeads")
                        .font(AppTypography.heading1)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Find leads that want\nwhat you offer")
                        .font(AppTypography.bodyLarge)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
                
                Spacer()
                
                // Features list
                VStack(alignment: .leading, spacing: AppSpacing.spacing3) {
                    FeatureRow(icon: "magnifyingglass", text: "Track keywords across subreddits")
                    FeatureRow(icon: "chart.bar.fill", text: "AI-powered lead scoring")
                    FeatureRow(icon: "text.bubble.fill", text: "Smart reply suggestions")
                }
                .padding(.horizontal, AppSpacing.spacing4)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 15)
                
                Spacer()
                
                // Auth Section
                VStack(spacing: AppSpacing.spacing4) {
                    // Sign in with Apple
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.email, .fullName]
                    } onCompletion: { result in
                        Task {
                            await viewModel?.handleAppleSignIn(result: result)
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 52)
                    .cornerRadius(AppSpacing.spacing3)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(AppColors.textTertiary.opacity(0.3))
                            .frame(height: 1)
                        Text("or")
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppColors.textTertiary)
                        Rectangle()
                            .fill(AppColors.textTertiary.opacity(0.3))
                            .frame(height: 1)
                    }
                    
                    // Email magic link
                    if let vm = viewModel {
                        if vm.magicLinkSent {
                            // Success state
                            HStack(spacing: AppSpacing.spacing2) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppColors.success)
                                Text("Check your email for the sign-in link!")
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.success)
                            }
                            .padding(.vertical, AppSpacing.spacing3)
                            
                            Button("Use a different email") {
                                vm.magicLinkSent = false
                                vm.emailText = ""
                            }
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppColors.primary400)
                        } else {
                            // Email input
                            HStack(spacing: AppSpacing.spacing2) {
                                TextField("Enter your email", text: Binding(
                                    get: { vm.emailText },
                                    set: { vm.emailText = $0 }
                                ))
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal, AppSpacing.spacing4)
                                .padding(.vertical, AppSpacing.spacing3)
                                .background(AppColors.bg700)
                                .cornerRadius(AppSpacing.spacing3)
                                
                                Button(action: {
                                    Task { await vm.sendMagicLink() }
                                }) {
                                    if vm.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                            .frame(width: 52, height: 48)
                                    } else {
                                        Image(systemName: "arrow.right.circle.fill")
                                            .font(.system(size: 32))
                                            .foregroundStyle(AppColors.primaryGradient)
                                            .frame(width: 52, height: 48)
                                    }
                                }
                                .disabled(vm.isLoading)
                            }
                        }
                    }
                    
                    if let error = viewModel?.error {
                        Text(error)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.error)
                    }
                    
                    Text("By continuing, you agree to our Terms and Privacy Policy")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 30)
                .padding(.bottom, AppSpacing.spacing6)
            }
            .padding(.horizontal, AppSpacing.spacing6)
        }
        .onAppear {
            viewModel = AuthViewModel(router: router)
            
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animateContent = true
            }
        }
    }
}

// MARK: - Feature Row
private struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: AppSpacing.spacing3) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.primary500)
                .frame(width: 28, height: 28)
                .background(AppColors.primary500.opacity(0.12))
                .cornerRadius(8)
            
            Text(text)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

#Preview {
    WelcomeScreen()
        .environment(AppRouter())
}
