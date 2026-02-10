import SwiftUI

/// Saved leads list screen
struct SavedLeadsScreen: View {
    @State private var viewModel = LeadFeedViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .tint(AppColors.primary400)
                } else if viewModel.savedLeads.isEmpty {
                    EmptyStateView(
                        icon: "bookmark",
                        title: "No Saved Leads",
                        message: "Swipe right on leads in the\nfeed to save them here"
                    )
                } else {
                    savedList
                }
            }
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.fetchSavedLeads()
            }
        }
    }
    
    private var savedList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.spacing3) {
                ForEach(viewModel.savedLeads) { lead in
                    NavigationLink(destination: LeadDetailScreen(
                        lead: lead,
                        onStatusChange: { newStatus in
                            Task {
                                switch newStatus {
                                case .contacted:
                                    await viewModel.markContacted(lead)
                                case .dismissed:
                                    await viewModel.dismissLead(lead)
                                default:
                                    break
                                }
                                // Refresh saved leads
                                await viewModel.fetchSavedLeads()
                            }
                        }
                    )) {
                        savedLeadRow(lead)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.spacing4)
            .padding(.bottom, AppSpacing.spacing12)
        }
    }
    
    private func savedLeadRow(_ lead: Lead) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing2) {
            HStack {
                if let score = lead.score {
                    ScoreBadge(score: score, size: .small)
                }
                
                Text("r/\(lead.subreddit)")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.primary400)
                
                Spacer()
                
                ChipView(lead.status.displayName, style: .status(lead.status))
            }
            
            Text(lead.title)
                .font(AppTypography.heading3)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(2)
            
            HStack {
                Text("u/\(lead.author)")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textTertiary)
                
                Spacer()
                
                Text(lead.postedAt.timeAgoDisplay())
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(AppSpacing.spacing4)
        .background(AppColors.bg700)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }
}

#Preview {
    SavedLeadsScreen()
        .preferredColorScheme(.dark)
}
