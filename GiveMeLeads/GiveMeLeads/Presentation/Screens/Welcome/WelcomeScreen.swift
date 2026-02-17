import SwiftUI
import AuthenticationServices
import UIKit

/// Welcome & sign-in screen — first thing new users see
struct WelcomeScreen: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: AuthViewModel?
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            if let vm = viewModel {
                if vm.otpSent {
                    OTPVerificationScreen(viewModel: vm)
                } else {
                    mainContent(vm)
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = AuthViewModel(router: router)
            }
        }
    }
    
    // MARK: - Main Welcome Content
    
    @ViewBuilder
    private func mainContent(_ vm: AuthViewModel) -> some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Logo & Branding
            VStack(spacing: AppSpacing.spacing3) {
                ZStack {
                    Circle()
                        .fill(AppColors.primary500.opacity(0.15))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "target")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(AppColors.primaryGradient)
                }
                
                Text("GiveMeLeads")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Find your ideal customers\non Reddit, automatically")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Spacer()
                .frame(height: 40)
            
            // Feature Highlights
            VStack(spacing: AppSpacing.spacing4) {
                featureRow(icon: "sparkles", text: "AI-powered lead discovery")
                featureRow(icon: "bolt.fill", text: "Smart relevance scoring")
                featureRow(icon: "text.bubble.fill", text: "AI reply suggestions")
            }
            .padding(.horizontal, AppSpacing.spacing6)
            
            Spacer()
            
            // Auth Section
            VStack(spacing: AppSpacing.spacing4) {
                // Sign in with Apple (primary)
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.email, .fullName]
                } onCompletion: { result in
                    Task {
                        await vm.handleAppleSignIn(result: result)
                    }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                
                // Divider
                HStack(spacing: AppSpacing.spacing3) {
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 1)
                    Text("or")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textTertiary)
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 1)
                }
                
                // Email OTP
                VStack(spacing: AppSpacing.spacing3) {
                    HStack(spacing: AppSpacing.spacing2) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(AppColors.textTertiary)
                            .font(.system(size: 16))
                        
                        TextField("Your email address", text: Bindable(vm).emailText)
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textPrimary)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding(AppSpacing.spacing3)
                    .background(AppColors.bg700)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    
                    Button(action: {
                        Task { await vm.sendOTP() }
                    }) {
                        HStack(spacing: 6) {
                            if vm.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            }
                            Text(vm.isLoading ? "Sending..." : "Send Login Code")
                                .font(AppTypography.bodyMedium)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.md)
                                .fill(AppColors.primaryGradient)
                        )
                    }
                    .disabled(vm.emailText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isLoading)
                    .opacity(vm.emailText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                }
                
                if let error = vm.error {
                    Text(error)
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.error)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, AppSpacing.spacing4)
            
            // Footer
            HStack(spacing: 4) {
                Text("By continuing, you agree to our")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
                Button("Terms") {
                    if let url = URL(string: AppConfig.termsOfServiceURL) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(AppTypography.caption)
                .foregroundColor(AppColors.primary400)
                Text("&")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
                Button("Privacy") {
                    if let url = URL(string: AppConfig.privacyPolicyURL) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(AppTypography.caption)
                .foregroundColor(AppColors.primary400)
            }
            .padding(.top, AppSpacing.spacing4)
            .padding(.bottom, AppSpacing.spacing6)
        }
        .padding(.horizontal, AppSpacing.spacing4)
    }
    
    // MARK: - Feature Row
    
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: AppSpacing.spacing3) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(AppColors.primaryGradient)
                .frame(width: 32, height: 32)
                .background(AppColors.primary500.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(text)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
        }
    }
}

#Preview {
    WelcomeScreen()
        .environment(AppRouter())
        .preferredColorScheme(.dark)
}
