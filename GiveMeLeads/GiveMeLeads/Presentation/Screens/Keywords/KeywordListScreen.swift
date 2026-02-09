import SwiftUI

struct KeywordListScreen: View {
    @State private var profiles = [TrackingProfile.sample]
    @State private var showAddProfile = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if profiles.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No Keywords",
                        message: "Add keyword profiles to start\ntracking leads on Reddit",
                        actionTitle: "Create Profile",
                        action: { showAddProfile = true }
                    )
                } else {
                    profilesList
                }
            }
            .navigationTitle("Keywords")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddProfile = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(AppColors.primary400)
                    }
                }
            }
            .sheet(isPresented: $showAddProfile) {
                Text("Add Profile Sheet") // TODO: AddProfileSheet
                    .presentationDetents([.medium])
            }
        }
    }
    
    private var profilesList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.spacing4) {
                ForEach(profiles) { profile in
                    profileCard(profile)
                }
                
                // Counter
                Text("\(totalKeywords)/\(AppConfig.maxKeywordsPerProfile * AppConfig.maxProfiles) keywords · \(profiles.count)/\(AppConfig.maxProfiles) profiles")
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
                
                Toggle("", isOn: .constant(profile.isActive))
                    .labelsHidden()
                    .tint(AppColors.primary500)
            }
            
            // Keywords
            FlowLayout(spacing: AppSpacing.spacing2) {
                ForEach(profile.keywords ?? []) { keyword in
                    ChipView(keyword.keyword, onDelete: {
                        // TODO: Delete keyword
                    })
                }
            }
            
            // Subreddits
            HStack(spacing: AppSpacing.spacing2) {
                ForEach(profile.subreddits, id: \.self) { sub in
                    ChipView("r/\(sub)", style: .subreddit)
                }
            }
        }
        .padding(AppSpacing.spacing5)
        .background(AppColors.bg700)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }
    
    private var totalKeywords: Int {
        profiles.reduce(0) { $0 + ($1.keywords?.count ?? 0) }
    }
}

/// Simple flow layout for wrapping chips
struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposableSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposableSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: ProposableSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func arrange(proposal: ProposableSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
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
