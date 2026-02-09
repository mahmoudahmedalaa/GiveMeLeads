import SwiftUI

/// Lead detail view with score breakdown, post content, and actions
struct LeadDetailScreen: View {
    let lead: Lead
    let onStatusChange: (LeadStatus) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var showReplySheet = false
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.spacing6) {
                    // Score Section
                    scoreSection
                    
                    // Post Content
                    contentSection
                    
                    // Actions
                    actionSection
                }
                .padding(.horizontal, AppSpacing.spacing4)
                .padding(.bottom, AppSpacing.spacing12)
            }
        }
        .navigationTitle("Lead Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { openRedditPost() }) {
                    Image(systemName: "safari")
                        .foregroundColor(AppColors.primary400)
                }
            }
        }
        .sheet(isPresented: $showReplySheet) {
            ReplySheetView(lead: lead)
                .presentationDetents([.medium, .large])
        }
    }
    
    // MARK: - Score Section
    
    private var scoreSection: some View {
        VStack(spacing: AppSpacing.spacing4) {
            HStack {
                if let score = lead.score {
                    ScoreBadge(score: score, size: .large)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: AppSpacing.spacing1) {
                    Text("r/\(lead.subreddit)")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.primary400)
                    
                    Text(lead.postedAt.timeAgoDisplay())
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textTertiary)
                    
                    Text("by u/\(lead.author)")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            if let breakdown = lead.scoreBreakdown {
                ScoreBreakdownView(breakdown: breakdown)
            }
        }
        .padding(AppSpacing.spacing5)
        .background(AppColors.bg700)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing3) {
            Text(lead.title)
                .font(AppTypography.heading2)
                .foregroundColor(AppColors.textPrimary)
            
            if let body = lead.body, !body.isEmpty {
                Text(body)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(4)
            }
            
            // Engagement stats
            HStack(spacing: AppSpacing.spacing6) {
                Label("\(lead.upvotes) upvotes", systemImage: "arrow.up")
                Label("\(lead.commentCount) comments", systemImage: "bubble.right")
            }
            .font(AppTypography.bodySmall)
            .foregroundColor(AppColors.textTertiary)
        }
        .padding(AppSpacing.spacing5)
        .background(AppColors.bg700)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }
    
    // MARK: - Action Section
    
    private var actionSection: some View {
        VStack(spacing: AppSpacing.spacing3) {
            PrimaryButton("Generate AI Reply", icon: "sparkles") {
                showReplySheet = true
            }
            
            HStack(spacing: AppSpacing.spacing3) {
                SecondaryButton("Save", icon: "bookmark.fill") {
                    onStatusChange(.saved)
                    dismiss()
                }
                
                SecondaryButton("Dismiss", icon: "xmark") {
                    onStatusChange(.dismissed)
                    dismiss()
                }
            }
            
            if lead.status != .contacted {
                GhostButton("Mark as Contacted") {
                    onStatusChange(.contacted)
                }
            }
        }
    }
    
    private func openRedditPost() {
        if let url = URL(string: lead.url) {
            UIApplication.shared.open(url)
        }
    }
}

/// Sheet for AI reply suggestions
struct ReplySheetView: View {
    let lead: Lead
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTone: ReplyTone = .professional
    @State private var generatedReply = ""
    @State private var isGenerating = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: AppSpacing.spacing5) {
                    // Tone selector
                    HStack(spacing: AppSpacing.spacing3) {
                        ForEach(ReplyTone.allCases, id: \.self) { tone in
                            Button(action: { selectedTone = tone }) {
                                Text(tone.displayName)
                                    .font(AppTypography.buttonMedium)
                                    .foregroundColor(selectedTone == tone ? .white : AppColors.textSecondary)
                                    .padding(.horizontal, AppSpacing.spacing4)
                                    .padding(.vertical, AppSpacing.spacing2)
                                    .background(
                                        selectedTone == tone
                                        ? AnyShapeStyle(AppColors.primaryGradient)
                                        : AnyShapeStyle(AppColors.bgGlass)
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                    if isGenerating {
                        VStack(spacing: AppSpacing.spacing4) {
                            ProgressView()
                                .tint(AppColors.primary400)
                            Text("Generating reply...")
                                .font(AppTypography.bodySmall)
                                .foregroundColor(AppColors.textTertiary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if !generatedReply.isEmpty {
                        ScrollView {
                            Text(generatedReply)
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(AppSpacing.spacing4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppColors.bg700)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                        }
                        
                        HStack(spacing: AppSpacing.spacing3) {
                            PrimaryButton("Copy Reply", icon: "doc.on.doc") {
                                UIPasteboard.general.string = generatedReply
                            }
                            
                            SecondaryButton("Regenerate", icon: "arrow.clockwise") {
                                Task { await generateReply() }
                            }
                        }
                    } else {
                        VStack(spacing: AppSpacing.spacing4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 40))
                                .foregroundStyle(AppColors.primaryGradient)
                            
                            Text("AI will generate a reply based on the post content and your selected tone")
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        PrimaryButton("Generate Reply", icon: "sparkles") {
                            Task { await generateReply() }
                        }
                    }
                    
                    Spacer()
                }
                .padding(AppSpacing.spacing5)
            }
            .navigationTitle("AI Reply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppColors.primary400)
                }
            }
        }
    }
    
    private func generateReply() async {
        isGenerating = true
        // TODO: Call AI reply generation edge function
        // For now, use a placeholder
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        let replies: [ReplyTone: String] = [
            .professional: "Hi there! I noticed you're looking for a solution to \(lead.title.prefix(50))... I've been working on something that might help. Would love to share more details if you're interested.",
            .casual: "Hey! Saw your post and thought I could help out. I've built something that handles exactly this. Happy to chat more about it if you want! 🚀",
            .helpful: "Great question! There are several approaches you could take here. Based on my experience, I'd recommend looking into tools that specifically address \(lead.title.prefix(30))... Let me know if you'd like more specific guidance."
        ]
        
        generatedReply = replies[selectedTone] ?? ""
        isGenerating = false
    }
}

#Preview {
    NavigationStack {
        LeadDetailScreen(
            lead: Lead.samples[0],
            onStatusChange: { _ in }
        )
    }
    .preferredColorScheme(.dark)
}
