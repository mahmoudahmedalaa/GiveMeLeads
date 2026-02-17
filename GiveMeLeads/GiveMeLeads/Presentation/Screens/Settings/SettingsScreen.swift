import SwiftUI
import AuthenticationServices

/// Settings screen
struct SettingsScreen: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: AuthViewModel?
    @State private var showDeleteConfirm = false
    @State private var notificationThreshold: Double = Double(UserDefaults.standard.object(forKey: "notificationThreshold") as? Int ?? 8)
    @State private var showProductDescription = false
    @State private var productDescription: String = ""
    @State private var isLoadingDescription = false
    
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
                                    Text("Coming Soon")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(AppColors.primaryGradient)
                                        .clipShape(Capsule())
                                    Text("\(Int(notificationThreshold))")
                                        .font(AppTypography.scoreBadge)
                                        .foregroundColor(AppColors.scoreColor(for: Int(notificationThreshold)))
                                }
                                
                                Slider(value: $notificationThreshold, in: 0...10, step: 1)
                                    .tint(AppColors.primary500)
                                    .onChange(of: notificationThreshold) { _, newValue in
                                        UserDefaults.standard.set(Int(newValue), forKey: "notificationThreshold")
                                    }
                                
                                Text("Only notify for leads scoring ≥\(Int(notificationThreshold))/10")
                                    .font(AppTypography.bodySmall)
                                    .foregroundColor(AppColors.textTertiary)
                            }
                            .padding(AppSpacing.spacing4)
                        }
                        
                        // Appearance section
                        settingsSection("Appearance") {
                            VStack(alignment: .leading, spacing: AppSpacing.spacing2) {
                                HStack {
                                    Image(systemName: "circle.lefthalf.filled")
                                        .foregroundColor(AppColors.primary400)
                                        .frame(width: 24)
                                    Text("Theme")
                                        .font(AppTypography.bodyMedium)
                                        .foregroundColor(AppColors.textPrimary)
                                    Spacer()
                                    Picker("", selection: Binding(
                                        get: { AppearanceManager.shared.mode },
                                        set: { AppearanceManager.shared.mode = $0 }
                                    )) {
                                        ForEach(AppearanceManager.Mode.allCases, id: \.self) { mode in
                                            Text(mode.displayName).tag(mode)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 200)
                                }
                            }
                            .padding(AppSpacing.spacing4)
                        }
                        
                        // Product section
                        settingsSection("Your Product") {
                            settingsRow(
                                icon: "doc.text.fill",
                                label: "Product Description",
                                value: productDescription.isEmpty ? "Not set" : "Edit"
                            ) {
                                showProductDescription = true
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
            .task {
                await loadProductDescription()
            }
            .alert("Delete Account?", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task { await viewModel?.deleteAccount() }
                }
            } message: {
                Text("This will permanently delete your account and all data. This cannot be undone.")
            }
            .sheet(isPresented: $showProductDescription) {
                ProductDescriptionSheet(
                    description: $productDescription,
                    onSave: { newDescription in
                        Task { await saveProductDescription(newDescription) }
                    }
                )
            }
        }
    }
    
    // MARK: - Product Description
    
    private func loadProductDescription() async {
        do {
            guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else { return }
            
            struct UserRow: Decodable {
                let productDescription: String?
                enum CodingKeys: String, CodingKey {
                    case productDescription = "product_description"
                }
            }
            
            let result: UserRow = try await SupabaseManager.shared.client
                .from("users")
                .select("product_description")
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            productDescription = result.productDescription ?? ""
        } catch {
            // Silently fail — field may not be set yet
        }
    }
    
    private func saveProductDescription(_ description: String) async {
        do {
            guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else { return }
            
            try await SupabaseManager.shared.client
                .from("users")
                .update(["product_description": description])
                .eq("id", value: userId.uuidString)
                .execute()
            
            productDescription = description
        } catch {
            // Silently fail
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

// MARK: - Product Description Sheet

struct ProductDescriptionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var description: String
    var onSave: (String) -> Void
    @State private var editText: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: AppSpacing.spacing5) {
                    VStack(alignment: .leading, spacing: AppSpacing.spacing2) {
                        Text("Describe your product or service so our AI can better analyze and score leads for you.")
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppColors.textSecondary)
                        
                        TextEditor(text: $editText)
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textPrimary)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 150)
                            .padding(AppSpacing.spacing3)
                            .background(AppColors.bg700)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.md)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        
                        Text("Example: \"I built a project management tool for small teams that handles task dependencies and has a mobile app\"")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textTertiary)
                            .italic()
                    }
                    
                    Spacer()
                }
                .padding(AppSpacing.spacing5)
            }
            .navigationTitle("Product Description")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(editText)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.primary500)
                }
            }
        }
        .onAppear {
            editText = description
        }
    }
}

#Preview {
    SettingsScreen()
        .environment(AppRouter())
        .preferredColorScheme(.dark)
}
