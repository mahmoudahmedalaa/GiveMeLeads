import SwiftUI

/// Smart onboarding: Describe your product → AI suggests keywords → Scan Reddit → Find leads
struct ProductSetupScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ProductSetupViewModel()
    @State private var newKeywordInput = ""
    @State private var newSubredditInput = ""
    
    var isModal: Bool = false
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.spacing6) {
                    if isModal {
                        // Close button for modal presentation
                        HStack {
                            Spacer()
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(AppColors.textTertiary)
                            }
                        }
                        .padding(.top, AppSpacing.spacing2)
                    }
                    
                    headerSection
                    
                    switch viewModel.phase {
                    case .describe:
                        describePhase
                    case .analyzing:
                        analyzingPhase
                    case .review:
                        reviewPhase
                    case .scanning:
                        scanningPhase
                    case .complete:
                        completePhase
                    }
                }
                .padding(AppSpacing.spacing5)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: AppSpacing.spacing3) {
            Image(systemName: phaseIcon)
                .font(.system(size: 48))
                .foregroundStyle(AppColors.primaryGradient)
                .symbolEffect(.bounce, value: viewModel.phase)
            
            Text(phaseTitle)
                .font(AppTypography.heading1)
                .foregroundColor(AppColors.textPrimary)
            
            Text(phaseSubtitle)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, isModal ? AppSpacing.spacing2 : AppSpacing.spacing6)
    }
    
    private var phaseIcon: String {
        switch viewModel.phase {
        case .describe: "sparkles"
        case .analyzing: "brain.head.profile"
        case .review: "checklist"
        case .scanning: "antenna.radiowaves.left.and.right"
        case .complete: "checkmark.circle.fill"
        }
    }
    
    private var phaseTitle: String {
        switch viewModel.phase {
        case .describe: "What do you offer?"
        case .analyzing: "Analyzing..."
        case .review: "Review Your Setup"
        case .scanning: "Scanning Reddit..."
        case .complete: "You're All Set!"
        }
    }
    
    private var phaseSubtitle: String {
        switch viewModel.phase {
        case .describe: "Describe your product or service\nand we'll find people looking for it"
        case .analyzing: "Finding the best keywords and\nsubreddits for your product"
        case .review: "Edit the keywords and subreddits\nwe'll use to find leads"
        case .scanning: viewModel.scanProgress
        case .complete: "\(viewModel.leadsFound) leads found and ready to review"
        }
    }
    
    // MARK: - Phase 1: Describe
    
    private var describePhase: some View {
        VStack(spacing: AppSpacing.spacing5) {
            // Text input
            VStack(alignment: .leading, spacing: AppSpacing.spacing2) {
                Text("Product Description")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                
                TextEditor(text: $viewModel.productDescription)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
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
            
            // Quick examples
            VStack(alignment: .leading, spacing: AppSpacing.spacing2) {
                Text("Quick Start Ideas")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.spacing2) {
                        exampleChip("SaaS project management tool")
                        exampleChip("Handmade candles on Etsy")
                        exampleChip("AI-powered writing assistant")
                        exampleChip("Freelance design agency")
                    }
                }
            }
            
            if let error = viewModel.error {
                Text(error)
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.scoreLow)
            }
            
            PrimaryButton("✨ Analyze My Product") {
                viewModel.analyzeProduct()
            }
            .disabled(viewModel.productDescription.trimmingCharacters(in: .whitespacesAndNewlines).count < 10)
        }
    }
    
    private func exampleChip(_ text: String) -> some View {
        Button(action: {
            viewModel.productDescription = text
        }) {
            Text(text)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.primary400)
                .padding(.horizontal, AppSpacing.spacing3)
                .padding(.vertical, AppSpacing.spacing2)
                .background(AppColors.primary500.opacity(0.1))
                .clipShape(Capsule())
        }
    }
    
    // MARK: - Phase 2: Analyzing
    
    private var analyzingPhase: some View {
        VStack(spacing: AppSpacing.spacing5) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(AppColors.primary500)
                .padding()
            
            Text("Reading your description and\nfinding the best search strategy...")
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, AppSpacing.spacing8)
    }
    
    // MARK: - Phase 3: Review
    
    private var reviewPhase: some View {
        VStack(spacing: AppSpacing.spacing5) {
            // Keywords section
            VStack(alignment: .leading, spacing: AppSpacing.spacing3) {
                HStack {
                    Label("Keywords", systemImage: "tag.fill")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Text("\(viewModel.suggestedKeywords.count)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Text("These are the search terms we'll use to find leads")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
                
                FlowLayout(spacing: 8) {
                    ForEach(viewModel.suggestedKeywords, id: \.self) { keyword in
                        ChipView(keyword, style: .keyword) {
                            viewModel.removeKeyword(keyword)
                        }
                    }
                }
                
                // Add keyword input
                HStack(spacing: AppSpacing.spacing2) {
                    TextField("Add keyword...", text: $newKeywordInput)
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, AppSpacing.spacing3)
                        .padding(.vertical, AppSpacing.spacing2)
                        .background(AppColors.bg700)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                        .onSubmit {
                            viewModel.addKeyword(newKeywordInput)
                            newKeywordInput = ""
                        }
                    
                    Button(action: {
                        viewModel.addKeyword(newKeywordInput)
                        newKeywordInput = ""
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(AppColors.primaryGradient)
                            .font(.system(size: 24))
                    }
                    .disabled(newKeywordInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(AppSpacing.spacing4)
            .background(AppColors.bg800)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            
            // Subreddits section
            VStack(alignment: .leading, spacing: AppSpacing.spacing3) {
                HStack {
                    Label("Subreddits", systemImage: "globe")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Text("\(viewModel.suggestedSubreddits.count)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Text("Reddit communities we'll search in")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
                
                FlowLayout(spacing: 8) {
                    ForEach(viewModel.suggestedSubreddits, id: \.self) { sub in
                        ChipView("r/\(sub)", style: .subreddit) {
                            viewModel.removeSubreddit(sub)
                        }
                    }
                }
                
                // Add subreddit input
                HStack(spacing: AppSpacing.spacing2) {
                    TextField("Add subreddit...", text: $newSubredditInput)
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, AppSpacing.spacing3)
                        .padding(.vertical, AppSpacing.spacing2)
                        .background(AppColors.bg700)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                        .onSubmit {
                            viewModel.addSubreddit(newSubredditInput)
                            newSubredditInput = ""
                        }
                    
                    Button(action: {
                        viewModel.addSubreddit(newSubredditInput)
                        newSubredditInput = ""
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(AppColors.primaryGradient)
                            .font(.system(size: 24))
                    }
                    .disabled(newSubredditInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(AppSpacing.spacing4)
            .background(AppColors.bg800)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            
            // Profile name
            VStack(alignment: .leading, spacing: AppSpacing.spacing2) {
                Text("Profile Name")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                TextField("Profile name", text: $viewModel.profileName)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(AppSpacing.spacing3)
                    .background(AppColors.bg700)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
            }
            
            if let error = viewModel.error {
                Text(error)
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.scoreLow)
            }
            
            // Action buttons
            VStack(spacing: AppSpacing.spacing3) {
                PrimaryButton("🚀 Start Finding Leads") {
                    Task { await viewModel.confirmAndScan() }
                }
                
                Button("← Edit Description") {
                    viewModel.phase = .describe
                }
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
            }
        }
    }
    
    // MARK: - Phase 4: Scanning
    
    private var scanningPhase: some View {
        VStack(spacing: AppSpacing.spacing5) {
            // Animated radar
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(AppColors.primary500.opacity(0.3), lineWidth: 2)
                        .frame(width: CGFloat(60 + i * 40), height: CGFloat(60 + i * 40))
                        .scaleEffect(1.0)
                        .opacity(0.7)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.3),
                            value: viewModel.phase
                        )
                }
                
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 32))
                    .foregroundStyle(AppColors.primaryGradient)
            }
            .frame(height: 160)
            
            Text(viewModel.scanProgress)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .animation(.easeInOut, value: viewModel.scanProgress)
            
            ProgressView()
                .tint(AppColors.primary500)
            
            if let error = viewModel.error {
                Text(error)
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.scoreLow)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, AppSpacing.spacing6)
    }
    
    // MARK: - Phase 5: Complete
    
    private var completePhase: some View {
        VStack(spacing: AppSpacing.spacing5) {
            // Success stats
            HStack(spacing: AppSpacing.spacing5) {
                statBadge(value: "\(viewModel.leadsFound)", label: "Leads Found")
                statBadge(value: "\(viewModel.suggestedKeywords.count)", label: "Keywords")
                statBadge(value: "\(viewModel.suggestedSubreddits.count)", label: "Subreddits")
            }
            
            if viewModel.leadsFound == 0 {
                VStack(spacing: AppSpacing.spacing2) {
                    Text("No leads matched your keywords this time")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                    Text("Your profile is set up — leads will appear as new posts match your keywords")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textTertiary)
                        .multilineTextAlignment(.center)
                }
            }
            
            PrimaryButton(viewModel.leadsFound > 0 ? "🎯 View Your Leads" : "Go to Dashboard") {
                onComplete()
            }
        }
        .padding(.vertical, AppSpacing.spacing4)
    }
    
    private func statBadge(value: String, label: String) -> some View {
        VStack(spacing: AppSpacing.spacing1) {
            Text(value)
                .font(AppTypography.heading1)
                .foregroundStyle(AppColors.primaryGradient)
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.spacing3)
        .background(AppColors.bg800)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
    }
}
