import SwiftUI

/// Sheet allowing users to edit an existing tracking profile's name, subreddits, and keywords
struct ProfileEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let profile: TrackingProfile
    let viewModel: KeywordViewModel
    var onSaved: () -> Void
    
    @State private var editName: String = ""
    @State private var editSubreddits: String = ""
    @State private var newKeywordText: String = ""
    @State private var isSaving = false
    @State private var error: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.spacing5) {
                        // Profile Name
                        sectionCard("Profile Name") {
                            TextField("e.g. My SaaS", text: $editName)
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(AppSpacing.spacing3)
                                .background(AppColors.bg800)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                        }
                        
                        // Subreddits
                        sectionCard("Subreddits") {
                            VStack(alignment: .leading, spacing: AppSpacing.spacing2) {
                                TextField("e.g. SaaS, startup, smallbusiness", text: $editSubreddits)
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.textPrimary)
                                    .padding(AppSpacing.spacing3)
                                    .background(AppColors.bg800)
                                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                                
                                Text("Separate with commas. Leave empty to search all of Reddit.")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textTertiary)
                            }
                        }
                        
                        // Keywords
                        sectionCard("Keywords") {
                            VStack(spacing: AppSpacing.spacing3) {
                                // Existing keywords
                                if let keywords = profile.keywords, !keywords.isEmpty {
                                    FlowLayout(spacing: 8) {
                                        ForEach(keywords) { keyword in
                                            keywordChip(keyword)
                                        }
                                    }
                                } else {
                                    Text("No keywords yet")
                                        .font(AppTypography.bodySmall)
                                        .foregroundColor(AppColors.textTertiary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                
                                // Add keyword field
                                HStack(spacing: AppSpacing.spacing2) {
                                    TextField("Add keyword...", text: $newKeywordText)
                                        .font(AppTypography.bodyMedium)
                                        .foregroundColor(AppColors.textPrimary)
                                        .padding(AppSpacing.spacing3)
                                        .background(AppColors.bg800)
                                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                                        .onSubmit { addKeyword() }
                                    
                                    Button(action: addKeyword) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(AppColors.primaryGradient)
                                            .font(.system(size: 28))
                                    }
                                    .disabled(newKeywordText.trimmingCharacters(in: .whitespaces).isEmpty)
                                }
                                
                                Text("\(profile.keywords?.count ?? 0)/\(GatingService.shared.entitlements.maxKeywordsTotal) keywords")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textTertiary)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                        
                        // Error
                        if let error {
                            Text(error)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.error)
                        }
                    }
                    .padding(AppSpacing.spacing5)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveChanges) {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(AppColors.primary500)
                    .disabled(isSaving || editName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear {
            editName = profile.name
            editSubreddits = profile.subreddits.joined(separator: ", ")
        }
    }
    
    // MARK: - Keyword Chip
    
    private func keywordChip(_ keyword: Keyword) -> some View {
        HStack(spacing: 4) {
            Text(keyword.keyword)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
            
            Button(action: {
                Task {
                    await viewModel.deleteKeyword(keyword, from: profile.id)
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppColors.bgGlass)
        .clipShape(Capsule())
    }
    
    // MARK: - Section Card
    
    private func sectionCard(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing2) {
            Text(title.uppercased())
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textTertiary)
            
            VStack(alignment: .leading, spacing: AppSpacing.spacing3) {
                content()
            }
            .padding(AppSpacing.spacing4)
            .background(AppColors.bg700)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
    }
    
    // MARK: - Actions
    
    private func addKeyword() {
        let text = newKeywordText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !text.isEmpty else { return }
        
        Task {
            viewModel.newKeywordText = text
            await viewModel.addKeyword(to: profile.id)
            newKeywordText = ""
        }
    }
    
    private func saveChanges() {
        let name = editName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else {
            error = "Profile name is required"
            return
        }
        
        let subreddits = editSubreddits
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "r/", with: "") }
            .filter { !$0.isEmpty }
        
        isSaving = true
        error = nil
        
        Task {
            do {
                let updated = TrackingProfile(
                    id: profile.id,
                    userId: profile.userId,
                    name: name,
                    subreddits: subreddits,
                    isActive: profile.isActive,
                    createdAt: profile.createdAt,
                    updatedAt: Date(),
                    keywords: profile.keywords
                )
                
                try await KeywordRepository().updateProfile(updated)
                await viewModel.fetchProfiles()
                onSaved()
                dismiss()
            } catch {
                self.error = "Failed to save: \(error.localizedDescription)"
                isSaving = false
            }
        }
    }
}

#Preview {
    ProfileEditSheet(
        profile: .sample,
        viewModel: KeywordViewModel(),
        onSaved: {}
    )
    .preferredColorScheme(.dark)
}
