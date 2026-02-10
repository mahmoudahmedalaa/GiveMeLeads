import SwiftUI

struct KeywordListScreen: View {
    @Environment(AppRouter.self) private var router
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
                    emptyState
                } else {
                    profilesList
                }
            }
            .navigationTitle("Profiles")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.canAddProfile {
                        Button(action: {
                            router.showProductSetup = true
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(AppColors.primary400)
                        }
                    }
                }
            }
            .task {
                await viewModel.fetchProfiles()
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: AppSpacing.spacing6) {
            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(AppColors.primaryGradient)
            
            VStack(spacing: AppSpacing.spacing2) {
                Text("No Profiles Yet")
                    .font(AppTypography.heading2)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Describe your product and we'll\nfind people looking for it on Reddit")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            PrimaryButton("✨ Describe My Product") {
                router.showProductSetup = true
            }
            .frame(maxWidth: 280)
        }
        .padding(AppSpacing.spacing8)
    }
    
    // MARK: - Profiles List
    
    private var profilesList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.spacing4) {
                ForEach(viewModel.profiles) { profile in
                    profileCard(profile)
                }
                
                // Add another profile button
                if viewModel.canAddProfile {
                    Button(action: {
                        router.showProductSetup = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(AppColors.primaryGradient)
                            Text("Add Another Product")
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColors.primary400)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(AppSpacing.spacing4)
                        .background(AppColors.primary500.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md)
                                .strokeBorder(AppColors.primary500.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [6]))
                        )
                    }
                }
                
                // Counter
                Text("\(viewModel.profiles.count)/\(AppConfig.maxProfiles) profiles")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textTertiary)
                    .padding(.top, AppSpacing.spacing2)
            }
            .padding(.horizontal, AppSpacing.spacing4)
            .padding(.bottom, AppSpacing.spacing12)
        }
    }
    
    // MARK: - Profile Card
    
    private func profileCard(_ profile: TrackingProfile) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing4) {
            // Header row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppSpacing.spacing1) {
                    Text(profile.name)
                        .font(AppTypography.heading3)
                        .foregroundColor(AppColors.textPrimary)
                    
                    if profile.isActive {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(AppColors.success)
                                .frame(width: 6, height: 6)
                            Text("Active")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.success)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(AppColors.textTertiary)
                                .frame(width: 6, height: 6)
                            Text("Inactive")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                }
                
                Spacer()
                
                // Delete button
                Button(action: {
                    Task { await viewModel.deleteProfile(profile.id) }
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(AppColors.error.opacity(0.7))
                        .font(.system(size: 14))
                        .padding(8)
                }
            }
            
            // Stats row
            HStack(spacing: AppSpacing.spacing4) {
                statPill(
                    icon: "tag.fill",
                    value: "\(profile.keywords?.count ?? 0)",
                    label: "keywords"
                )
                
                statPill(
                    icon: "globe",
                    value: "\(profile.subreddits.count)",
                    label: "subreddits"
                )
            }
            
            // Keywords preview
            if let keywords = profile.keywords, !keywords.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(keywords.prefix(6)) { keyword in
                        Text(keyword.keyword)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(AppColors.bgGlass)
                            .clipShape(Capsule())
                    }
                    if keywords.count > 6 {
                        Text("+\(keywords.count - 6) more")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textTertiary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                    }
                }
            }
            
            // Subreddits preview
            if !profile.subreddits.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "globe")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.primary400)
                    Text(profile.subreddits.prefix(3).map { "r/\($0)" }.joined(separator: " · "))
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                    if profile.subreddits.count > 3 {
                        Text("+\(profile.subreddits.count - 3)")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }
            
            // Action buttons
            HStack(spacing: AppSpacing.spacing3) {
                Button(action: {
                    Task { await viewModel.scanProfile(profile) }
                }) {
                    HStack(spacing: 6) {
                        if viewModel.isScanningProfile == profile.id {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.white)
                        } else {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 12))
                        }
                        Text(viewModel.isScanningProfile == profile.id ? "Scanning..." : "Scan Now")
                            .font(AppTypography.bodySmall)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppColors.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                }
                .disabled(viewModel.isScanningProfile != nil)
            }
            
            // Scan result message
            if let msg = viewModel.scanMessage, viewModel.lastScannedProfileId == profile.id {
                HStack(spacing: 6) {
                    Image(systemName: msg.contains("🎯") ? "checkmark.circle.fill" : "info.circle.fill")
                        .foregroundColor(msg.contains("🎯") ? AppColors.success : AppColors.textTertiary)
                        .font(.system(size: 12))
                    Text(msg)
                        .font(AppTypography.caption)
                        .foregroundColor(msg.contains("🎯") ? AppColors.success : AppColors.textTertiary)
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
    
    // MARK: - Helpers
    
    private func statPill(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(AppColors.primary400)
            Text(value)
                .font(AppTypography.scoreBadge)
                .foregroundColor(AppColors.textPrimary)
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(AppColors.bg800)
        .clipShape(Capsule())
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
        .environment(AppRouter())
        .preferredColorScheme(.dark)
}
