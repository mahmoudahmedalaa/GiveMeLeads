import SwiftUI

/// Sheet for creating a new tracking profile
struct AddProfileSheet: View {
    @Bindable var viewModel: KeywordViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: AppSpacing.spacing5) {
                    // Profile Name
                    VStack(alignment: .leading, spacing: AppSpacing.spacing2) {
                        Text("Profile Name")
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppColors.textTertiary)
                        
                        TextField("e.g. My SaaS Product", text: $viewModel.newProfileName)
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(AppSpacing.spacing3)
                            .background(AppColors.bg700)
                            .cornerRadius(AppRadius.sm)
                    }
                    
                    // Subreddits
                    VStack(alignment: .leading, spacing: AppSpacing.spacing2) {
                        Text("Subreddits (comma-separated)")
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppColors.textTertiary)
                        
                        TextField("e.g. startups, SaaS, smallbusiness", text: $viewModel.newProfileSubreddits)
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(AppSpacing.spacing3)
                            .background(AppColors.bg700)
                            .cornerRadius(AppRadius.sm)
                    }
                    
                    if let error = viewModel.error {
                        Text(error)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.error)
                    }
                    
                    Spacer()
                    
                    PrimaryButton("Create Profile") {
                        Task {
                            await viewModel.createProfile()
                        }
                    }
                }
                .padding(AppSpacing.spacing5)
            }
            .navigationTitle("New Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.primary400)
                }
            }
        }
    }
}

#Preview {
    AddProfileSheet(viewModel: KeywordViewModel())
        .preferredColorScheme(.dark)
}
