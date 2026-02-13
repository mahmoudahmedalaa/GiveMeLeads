import SwiftUI
import AuthenticationServices

/// Settings screen
struct SettingsScreen: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: AuthViewModel?
    @State private var showDeleteConfirm = false
    @State private var notificationThreshold: Double = 8
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.spacing6) {
                        // Subscription section
                        settingsSection("Subscription") {
                            settingsRow(icon: "crown.fill", label: "Plan", value: GatingService.shared.currentPlan.displayName)
                            settingsRow(icon: "creditcard.fill", label: "Manage", value: "") {
                                // TODO: Open paywall
                                router.showPaywall = true
                            }
                        }
                        
                        // Notifications section
                        settingsSection("Notifications") {
                            VStack(alignment: .leading, spacing: AppSpacing.spacing2) {
                                HStack {
                                    Image(systemName: "bell.badge.fill")
                                        .foregroundColor(AppColors.primary400)
                                    Text("Score Threshold")
                                        .font(AppTypography.bodyMedium)
                                        .foregroundColor(AppColors.textPrimary)
                                    Spacer()
                                    Text("\(Int(notificationThreshold))")
                                        .font(AppTypography.scoreBadge)
                                        .foregroundColor(AppColors.scoreColor(for: Int(notificationThreshold)))
                                }
                                
                                Slider(value: $notificationThreshold, in: 0...10, step: 1)
                                    .tint(AppColors.primary500)
                                
                                Text("Only notify for leads scoring ≥\(Int(notificationThreshold))/10")
                                    .font(AppTypography.bodySmall)
                                    .foregroundColor(AppColors.textTertiary)
                            }
                            .padding(AppSpacing.spacing4)
                        }
                        
                        // Product section
                        settingsSection("Your Product") {
                            settingsRow(icon: "doc.text.fill", label: "Product Description", value: "Not set") {
                                // TODO: Product description sheet
                            }
                        }
                        
                        // Account section
                        settingsSection("Account") {
                            settingsRow(icon: "arrow.right.square", label: "Sign Out", value: "") {
                                Task { await viewModel?.signOut() }
                            }
                            
                            Button(action: { showDeleteConfirm = true }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(AppColors.error)
                                    Text("Delete Account")
                                        .font(AppTypography.bodyMedium)
                                        .foregroundColor(AppColors.error)
                                    Spacer()
                                }
                                .padding(AppSpacing.spacing4)
                            }
                        }
                        
                        // Debug section (remove before release)
                        #if DEBUG
                        settingsSection("🛠 Debug") {
                            VStack(alignment: .leading, spacing: AppSpacing.spacing2) {
                                HStack {
                                    Image(systemName: "wrench.and.screwdriver")
                                        .foregroundColor(.orange)
                                        .frame(width: 24)
                                    Text("Override Plan")
                                        .font(AppTypography.bodyMedium)
                                        .foregroundColor(AppColors.textPrimary)
                                    Spacer()
                                    Picker("", selection: Bindable(GatingService.shared).currentPlan) {
                                        ForEach(Plan.allCases, id: \.self) { plan in
                                            Text(plan.displayName).tag(plan)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 200)
                                }
                                
                                Text("Current: \(GatingService.shared.currentPlan.displayName) — \(GatingService.shared.entitlements.maxVisibleLeads) leads, \(GatingService.shared.entitlements.maxScansPerDay) scans/day")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.orange.opacity(0.7))
                            }
                            .padding(AppSpacing.spacing4)
                        }
                        #endif
                        
                        // App info
                        VStack(spacing: AppSpacing.spacing1) {
                            Text("GiveMeLeads v\(AppConfig.appVersion)")
                                .font(AppTypography.bodySmall)
                            Text("Made with 💜")
                                .font(AppTypography.bodySmall)
                        }
                        .foregroundColor(AppColors.textTertiary)
                        .padding(.top, AppSpacing.spacing4)
                    }
                    .padding(.horizontal, AppSpacing.spacing4)
                    .padding(.bottom, AppSpacing.spacing12)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if viewModel == nil {
                    viewModel = AuthViewModel(router: router)
                }
            }
            .alert("Delete Account?", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task { await viewModel?.deleteAccount() }
                }
            } message: {
                Text("This will permanently delete your account and all data. This cannot be undone.")
            }
        }
    }
    
    // MARK: - Setting Components
    
    private func settingsSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing2) {
            Text(title.uppercased())
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textTertiary)
                .padding(.leading, AppSpacing.spacing2)
            
            VStack(spacing: 1) {
                content()
            }
            .background(AppColors.bg700)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
    }
    
    private func settingsRow(icon: String, label: String, value: String, action: (() -> Void)? = nil) -> some View {
        Button(action: { action?() }) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppColors.primary400)
                    .frame(width: 24)
                
                Text(label)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                if !value.isEmpty {
                    Text(value)
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .padding(AppSpacing.spacing4)
        }
        .disabled(action == nil)
    }
}

#Preview {
    SettingsScreen()
        .environment(AppRouter())
        .preferredColorScheme(.dark)
}
