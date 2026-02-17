import SwiftUI

/// OTP Code verification screen — user enters 6-digit code from email
struct OTPVerificationScreen: View {
    @Bindable var viewModel: AuthViewModel
    @FocusState private var isCodeFocused: Bool
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: AppSpacing.spacing6) {
                Spacer()
                
                // Icon
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AppColors.primaryGradient)
                
                // Header
                VStack(spacing: AppSpacing.spacing2) {
                    Text("Check Your Email")
                        .font(AppTypography.heading1)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("We sent a 6-digit code to")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text(viewModel.emailText)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.primary400)
                        .fontWeight(.semibold)
                }
                .multilineTextAlignment(.center)
                
                // Code input
                VStack(spacing: AppSpacing.spacing3) {
                    TextField("000000", text: $viewModel.otpCode)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .focused($isCodeFocused)
                        .padding(AppSpacing.spacing4)
                        .background(AppColors.bg700)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md)
                                .stroke(AppColors.primary500.opacity(0.3), lineWidth: 1)
                        )
                        .frame(maxWidth: 220)
                        .onChange(of: viewModel.otpCode) { _, newValue in
                            // Strip non-digit characters (spaces, dashes from autofill/paste)
                            let digitsOnly = newValue.filter { $0.isNumber }
                            let capped = String(digitsOnly.prefix(6))
                            if capped != newValue {
                                viewModel.otpCode = capped
                                return // onChange will re-fire with clean value
                            }
                            // Auto-verify when 6 digits entered
                            if capped.count == 6 && !viewModel.isLoading {
                                Task { await viewModel.verifyOTP() }
                            }
                        }
                    
                    if let error = viewModel.error {
                        Text(error)
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppColors.error)
                    }
                }
                
                // Verify button
                PrimaryButton(
                    viewModel.isLoading ? "Verifying..." : "Verify Code",
                    isLoading: viewModel.isLoading
                ) {
                    Task { await viewModel.verifyOTP() }
                }
                .disabled(viewModel.otpCode.count < 6 || viewModel.isLoading)
                .frame(maxWidth: 280)
                
                // Resend / Go back
                VStack(spacing: AppSpacing.spacing3) {
                    Button(action: {
                        Task { await viewModel.sendOTP() }
                    }) {
                        Text("Didn't receive it? Resend")
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppColors.primary400)
                    }
                    .disabled(viewModel.isLoading)
                    
                    Button(action: {
                        viewModel.resetOTP()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Use a different email")
                        }
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textTertiary)
                    }
                }
                
                Spacer()
                Spacer()
            }
            .padding(AppSpacing.spacing5)
        }
        .onAppear {
            isCodeFocused = true
        }
    }
}
