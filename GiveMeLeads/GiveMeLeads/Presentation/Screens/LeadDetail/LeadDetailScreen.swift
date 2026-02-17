import SwiftUI

/// Action-oriented lead detail — shows WHY this lead matters, the key snippet, and HOW to engage
struct LeadDetailScreen: View {
    let lead: Lead
    let onAction: (LeadCardAction) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var showReplySheet = false
    @State private var showDeleteConfirm = false
    @State private var topComments: [RedditSearchService.PostComment] = []
    @State private var isLoadingComments = false
    private let redditSearch = RedditSearchService()
    
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
                    
                    // 5. Hot Comments
                    hotCommentsSection
                    
                    // 6. Actions (context-aware)
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
            ReplySheetView(lead: lead, topComments: topComments)
                .presentationDetents([.medium, .large])
        }
        .alert("Delete Lead?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                onAction(.delete)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove this lead. This cannot be undone.")
        }
        .task {
            await loadTopComments()
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
                    ScoreBar(label: "Intent", value: breakdown.intentDisplay, color: AppColors.scoreHigh)
                    ScoreBar(label: "Fit", value: breakdown.fitDisplay, color: AppColors.accentCyan)
                    ScoreBar(label: "Urgency", value: breakdown.urgencyDisplay, color: AppColors.warning)
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
    
    // MARK: - Hot Comments
    
    private var hotCommentsSection: some View {
        Group {
            if isLoadingComments {
                VStack(spacing: AppSpacing.spacing3) {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .foregroundColor(AppColors.primary400)
                        Text("Hot Comments")
                            .font(AppTypography.heading3)
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        ProgressView()
                            .tint(AppColors.primary400)
                    }
                }
                .padding(AppSpacing.spacing5)
                .background(AppColors.bg700)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            } else if !topComments.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.spacing3) {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .foregroundColor(AppColors.primary400)
                        Text("Hot Comments")
                            .font(AppTypography.heading3)
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Text("\(topComments.count)")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(AppColors.bg600)
                            .clipShape(Capsule())
                    }
                    
                    Text("Top replies that may reveal buying signals")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                    
                    ForEach(topComments) { comment in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("u/\(comment.author)")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.primary400)
                                Spacer()
                                HStack(spacing: 3) {
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 10))
                                    Text("\(comment.ups)")
                                        .font(AppTypography.caption)
                                }
                                .foregroundColor(AppColors.textTertiary)
                            }
                            
                            Text(String(comment.body.prefix(300)))
                                .font(AppTypography.bodySmall)
                                .foregroundColor(AppColors.textSecondary)
                                .lineSpacing(3)
                        }
                        .padding(AppSpacing.spacing3)
                        .background(AppColors.bg600.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                    }
                }
                .padding(AppSpacing.spacing5)
                .background(AppColors.primary400.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(AppColors.primary400.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
    
    private func loadTopComments() async {
        // Only fetch for posts (t3_) with score >= 5
        guard lead.redditPostId.hasPrefix("t3_"),
              (lead.score ?? 0) >= 5 else { return }
        
        isLoadingComments = true
        defer { isLoadingComments = false }
        
        do {
            topComments = try await redditSearch.fetchTopComments(
                postId: lead.redditPostId,
                subreddit: lead.subreddit,
                limit: 5
            )
        } catch {
            // Silently fail — comments are optional enrichment
        }
    }
    
    // MARK: - Context-Aware Actions
    
    private var actionSection: some View {
        VStack(spacing: AppSpacing.spacing3) {
            // Primary CTA — open Reddit to engage
            PrimaryButton("Open in Reddit", icon: "safari") {
                openRedditPost()
            }
            
            PrimaryButton("Generate AI Reply", icon: "sparkles") {
                showReplySheet = true
            }
            
            // Context-aware secondary actions
            switch lead.status {
            case .new:
                HStack(spacing: AppSpacing.spacing3) {
                    SecondaryButton("Save", icon: "bookmark.fill") {
                        onAction(.save)
                        dismiss()
                    }
                    
                    SecondaryButton("Dismiss", icon: "xmark") {
                        onAction(.dismiss)
                        dismiss()
                    }
                }
                
                GhostButton("Mark as Contacted") {
                    onAction(.contacted)
                    dismiss()
                }
                
            case .saved:
                HStack(spacing: AppSpacing.spacing3) {
                    SecondaryButton("Contacted", icon: "envelope.fill") {
                        onAction(.contacted)
                        dismiss()
                    }
                    
                    SecondaryButton("Unsave", icon: "bookmark.slash") {
                        onAction(.unsave)
                        dismiss()
                    }
                }
                
                GhostButton("Delete Permanently") {
                    showDeleteConfirm = true
                }
                
            case .contacted:
                GhostButton("Delete Permanently") {
                    showDeleteConfirm = true
                }
                
            default:
                EmptyView()
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
                        .frame(width: geo.size.width * CGFloat(value) / 10)
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
    var topComments: [RedditSearchService.PostComment] = []
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTone: ReplyTone = .professional
    @State private var generatedReply = ""
    @State private var isGenerating = false
    @State private var error: String?
    @State private var productDescription: String?
    @State private var replyTarget: ReplyTarget = .post
    @State private var selectedComment: RedditSearchService.PostComment?
    
    private let replyRepo = AIReplyRepository()
    
    enum ReplyTarget: String, CaseIterable {
        case post = "Reply to Post"
        case comment = "Reply to Comment"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.spacing5) {
                        // Reply target selector (post vs comment)
                        if !topComments.isEmpty {
                            Picker("Reply to", selection: $replyTarget) {
                                ForEach(ReplyTarget.allCases, id: \.self) { target in
                                    Text(target.rawValue).tag(target)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: replyTarget) { _, newValue in
                                generatedReply = ""
                                if newValue == .post { selectedComment = nil }
                                else if selectedComment == nil { selectedComment = topComments.first }
                            }
                        }
                        
                        // Comment selector
                        if replyTarget == .comment && !topComments.isEmpty {
                            VStack(alignment: .leading, spacing: AppSpacing.spacing2) {
                                Text("Select comment to reply to:")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textTertiary)
                                
                                ForEach(topComments, id: \.id) { comment in
                                    Button {
                                        selectedComment = comment
                                        generatedReply = ""
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("u/\(comment.author)")
                                                .font(AppTypography.caption)
                                                .foregroundColor(AppColors.primary400)
                                            Text(comment.body.prefix(120) + (comment.body.count > 120 ? "..." : ""))
                                                .font(AppTypography.bodySmall)
                                                .foregroundColor(AppColors.textSecondary)
                                                .lineLimit(3)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(AppSpacing.spacing3)
                                        .background(selectedComment?.id == comment.id ? AppColors.primary400.opacity(0.1) : AppColors.bg700)
                                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppRadius.sm)
                                                .stroke(selectedComment?.id == comment.id ? AppColors.primary400.opacity(0.4) : Color.clear, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
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
                                Text(replyTarget == .comment ? "Crafting comment reply..." : "Generating reply...")
                                    .font(AppTypography.bodySmall)
                                    .foregroundColor(AppColors.textTertiary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 120)
                        } else if !generatedReply.isEmpty {
                            Text(generatedReply)
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(AppSpacing.spacing4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppColors.bg700)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                            
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
                                
                                Text(replyTarget == .comment
                                     ? "AI will generate a natural reply to the selected comment"
                                     : "AI will generate a reply based on the post content and your product")
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 100)
                            
                            PrimaryButton("Generate Reply", icon: "sparkles") {
                                Task { await generateReply() }
                            }
                        }
                        
                        if let error {
                            Text(error)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.error)
                        }
                    }
                    .padding(AppSpacing.spacing5)
                }
            }
            .navigationTitle("AI Reply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppColors.primary400)
                }
            }
            .task {
                // Pre-fetch product description for context
                productDescription = await fetchProductDescription()
            }
        }
    }
    
    private func generateReply() async {
        isGenerating = true
        error = nil
        
        // Build rich context string for the Edge Function
        var contextParts: [String] = []
        if let desc = productDescription, !desc.isEmpty {
            contextParts.append(desc)
        }
        if replyTarget == .comment, let comment = selectedComment {
            contextParts.append("[REPLY_TO_COMMENT] Author: u/\(comment.author) | Comment: \(comment.body)")
        }
        let context = contextParts.joined(separator: "\n\n")
        
        do {
            let reply = try await replyRepo.generateReply(
                leadId: lead.id,
                tone: selectedTone,
                context: context
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
    
    private func fetchProductDescription() async -> String? {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            
            struct UserProfile: Decodable {
                let productDescription: String?
                enum CodingKeys: String, CodingKey {
                    case productDescription = "product_description"
                }
            }
            
            let response: UserProfile = try await SupabaseManager.shared.client
                .from("users")
                .select("product_description")
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            return response.productDescription
        } catch {
            return nil
        }
    }
}

#Preview {
    NavigationStack {
        LeadDetailScreen(
            lead: Lead.samples[0],
            onAction: { _ in }
        )
    }
    .preferredColorScheme(.dark)
}
