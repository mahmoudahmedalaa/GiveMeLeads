import SwiftUI

/// Action-oriented lead detail — shows WHY this lead matters, the key snippet, and HOW to engage
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
                VStack(alignment: .leading, spacing: AppSpacing.spacing5) {
                    // 1. Why This Lead Matters
                    insightSection
                    
                    // 2. The Key Snippet
                    snippetSection
                    
                    // 3. How To Approach
                    approachSection
                    
                    // 4. Original Post
                    contentSection
                    
                    // 5. Actions
                    actionSection
                }
                .padding(.horizontal, AppSpacing.spacing4)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("Lead Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { openRedditPost() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "safari")
                        Text("Open")
                    }
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.primary400)
                }
            }
        }
        .sheet(isPresented: $showReplySheet) {
            ReplySheetView(lead: lead)
                .presentationDetents([.medium, .large])
        }
    }
    
    // MARK: - Why This Lead Matters
    
    private var insightSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing3) {
            HStack {
                Image(systemName: "sparkle")
                    .foregroundColor(AppColors.warning)
                Text("Why This Lead Matters")
                    .font(AppTypography.heading3)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                if let score = lead.score {
                    ScoreBadge(score: score, size: .large)
                }
            }
            
            if let insight = lead.relevanceInsight {
                Text(insight)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(4)
            } else {
                Text("This lead matched your tracking keywords.")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            // Score breakdown
            if let breakdown = lead.scoreBreakdown {
                HStack(spacing: AppSpacing.spacing5) {
                    ScoreBar(label: "Intent", value: breakdown.intent, color: AppColors.scoreHigh)
                    ScoreBar(label: "Fit", value: breakdown.fit, color: AppColors.accentCyan)
                    ScoreBar(label: "Urgency", value: breakdown.urgency, color: AppColors.warning)
                }
                .padding(.top, AppSpacing.spacing2)
            }
        }
        .padding(AppSpacing.spacing5)
        .background(AppColors.warning.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(AppColors.warning.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Key Snippet
    
    private var snippetSection: some View {
        Group {
            if let snippet = lead.matchingSnippet {
                VStack(alignment: .leading, spacing: AppSpacing.spacing3) {
                    HStack {
                        Image(systemName: "text.quote")
                            .foregroundColor(AppColors.accentCyan)
                        Text("Key Snippet")
                            .font(AppTypography.heading3)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        Rectangle()
                            .fill(AppColors.accentCyan)
                            .frame(width: 3)
                        
                        Text("\"\(snippet)\"")
                            .font(.system(size: 15, weight: .regular, design: .serif))
                            .italic()
                            .foregroundColor(AppColors.textPrimary)
                            .lineSpacing(4)
                    }
                }
                .padding(AppSpacing.spacing5)
                .background(AppColors.accentCyan.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(AppColors.accentCyan.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - How To Approach
    
    private var approachSection: some View {
        Group {
            if let approach = lead.suggestedApproach {
                VStack(alignment: .leading, spacing: AppSpacing.spacing3) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(AppColors.success)
                        Text("Suggested Approach")
                            .font(AppTypography.heading3)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    Text(approach)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                        .lineSpacing(4)
                }
                .padding(AppSpacing.spacing5)
                .background(AppColors.success.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(AppColors.success.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Original Post
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing3) {
            HStack {
                Text("Original Post")
                    .font(AppTypography.heading3)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("r/\(lead.subreddit)")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.primary400)
                    Text("by u/\(lead.author) · \(lead.postedAt.timeAgoDisplay())")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            Text(lead.title)
                .font(AppTypography.heading2)
                .foregroundColor(AppColors.textPrimary)
            
            if let body = lead.body, !body.isEmpty {
                Text(body)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(4)
            }
            
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
    
    // MARK: - Actions
    
    private var actionSection: some View {
        VStack(spacing: AppSpacing.spacing3) {
            // Primary CTA — open Reddit to engage
            PrimaryButton("Open in Reddit", icon: "safari") {
                openRedditPost()
            }
            
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

// MARK: - Score Bar Component

struct ScoreBar: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.15))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(value) / 100)
                }
            }
            .frame(height: 6)
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppColors.textTertiary)
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
    @State private var error: String?
    
    private let replyRepo = AIReplyRepository()
    
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
                    
                    if let error {
                        Text(error)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.error)
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
        error = nil
        
        do {
            let reply = try await replyRepo.generateReply(
                leadId: lead.id,
                tone: selectedTone,
                context: ""
            )
            generatedReply = reply.suggestion
        } catch {
            let replies: [ReplyTone: String] = [
                .professional: "Hi there! I noticed you're looking for a solution to \(lead.title.prefix(50))... I've been working on something that might help. Would love to share more details if you're interested.",
                .casual: "Hey! Saw your post and thought I could help out. I've built something that handles exactly this. Happy to chat more about it if you want! 🚀",
                .helpful: "Great question! There are several approaches you could take here. Based on my experience, I'd recommend looking into tools that specifically address \(lead.title.prefix(30))... Let me know if you'd like more specific guidance."
            ]
            generatedReply = replies[selectedTone] ?? ""
            self.error = "Used offline template (Edge Function unavailable)"
        }
        
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
