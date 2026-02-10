import SwiftUI

struct KeywordListScreen: View {
    @State private var viewModel = KeywordViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .tint(AppColors.primary400)
                } else if viewModel.profiles.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No Keywords",
                        message: "Add keyword profiles to start\ntracking leads on Reddit",
                        actionTitle: "Create Profile",
                        action: { viewModel.showAddProfile = true }
                    )
                } else {
                    profilesList
                }
            }
            .navigationTitle("Keywords")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.canAddProfile {
                        Button(action: { viewModel.showAddProfile = true }) {
                            Image(systemName: "plus")
                                .foregroundColor(AppColors.primary400)
                        }
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { viewModel.showAddProfile },
                set: { viewModel.showAddProfile = $0 }
            )) {
                AddProfileSheet(viewModel: viewModel)
                    .presentationDetents([.medium])
            }
            .task {
                await viewModel.fetchProfiles()
            }
        }
    }
    
    private var profilesList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.spacing4) {
                ForEach(viewModel.profiles) { profile in
                    profileCard(profile)
                }
                
                // Counter
                Text("\(viewModel.totalKeywords)/\(AppConfig.maxKeywordsPerProfile * AppConfig.maxProfiles) keywords · \(viewModel.profiles.count)/\(AppConfig.maxProfiles) profiles")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textTertiary)
                    .padding(.top, AppSpacing.spacing4)
            }
            .padding(.horizontal, AppSpacing.spacing4)
            .padding(.bottom, AppSpacing.spacing12)
        }
    }
    
    private func profileCard(_ profile: TrackingProfile) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing3) {
            // Header
            HStack {
                Text(profile.name)
                    .font(AppTypography.heading3)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Button(action: {
                    Task { await viewModel.toggleProfile(profile.id) }
                }) {
                    Image(systemName: profile.isActive ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(profile.isActive ? AppColors.success : AppColors.textTertiary)
                        .font(.system(size: 22))
                }
                
                Button(action: {
                    Task { await viewModel.deleteProfile(profile.id) }
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(AppColors.error.opacity(0.7))
                        .font(.system(size: 14))
                }
            }
            
            // Keywords
            if let keywords = profile.keywords, !keywords.isEmpty {
                FlowLayout(spacing: AppSpacing.spacing2) {
                    ForEach(keywords) { keyword in
                        ChipView(keyword.keyword, onDelete: {
                            Task { await viewModel.deleteKeyword(keyword, from: profile.id) }
                        })
                    }
                }
            }
            
            // Add keyword input
            HStack(spacing: AppSpacing.spacing2) {
                TextField("Add keyword...", text: Binding(
                    get: { viewModel.newKeywordText },
                    set: { viewModel.newKeywordText = $0 }
                ))
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.spacing3)
                .padding(.vertical, AppSpacing.spacing2)
                .background(AppColors.background)
                .cornerRadius(AppRadius.sm)
                .onSubmit {
                    Task { await viewModel.addKeyword(to: profile.id) }
                }
                
                Button(action: {
                    Task { await viewModel.addKeyword(to: profile.id) }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(AppColors.primaryGradient)
                        .font(.system(size: 24))
                }
                .disabled(viewModel.newKeywordText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            
            // Subreddits
            if !profile.subreddits.isEmpty {
                HStack(spacing: AppSpacing.spacing2) {
                    ForEach(profile.subreddits, id: \.self) { sub in
                        ChipView("r/\(sub)", style: .subreddit)
                    }
                }
            }
            
            if let error = viewModel.error {
                Text(error)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.error)
            }
        }
        .padding(AppSpacing.spacing5)
        .background(AppColors.bg700)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }
}

/// Simple flow layout for wrapping chips
struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += maxHeight + spacing
                maxHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            maxHeight = max(maxHeight, size.height)
            x += size.width + spacing
        }
        
        return (CGSize(width: maxWidth, height: y + maxHeight), positions)
    }
}

#Preview {
    KeywordListScreen()
        .preferredColorScheme(.dark)
}
