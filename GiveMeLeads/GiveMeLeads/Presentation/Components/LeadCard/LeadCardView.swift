import SwiftUI

/// A card displaying a Reddit lead with actionable intelligence
struct LeadCardView: View {
    let lead: Lead
    let onSave: () -> Void
    let onDismiss: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing3) {
            // Top row: Score badge + Subreddit + Source type + Time
            HStack(spacing: AppSpacing.spacing2) {
                if let score = lead.score {
                    ScoreBadge(score: score, size: .small)
                }
                
                Text("r/\(lead.subreddit)")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.primary400)
                    .padding(.horizontal, AppSpacing.spacing2)
                    .padding(.vertical, 2)
                    .background(AppColors.primary500.opacity(0.15))
                    .clipShape(Capsule())
                
                if lead.redditPostId.hasPrefix("t1_") {
                    Text("💬 Comment")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.accentCyan)
                        .padding(.horizontal, AppSpacing.spacing2)
                        .padding(.vertical, 2)
                        .background(AppColors.accentCyan.opacity(0.15))
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                Text(lead.postedAt.timeAgoDisplay())
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            // Title — the Reddit post/comment title
            Text(lead.title)
                .font(AppTypography.heading3)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(2)
            
            // ★ KEY INSIGHT — why this lead matters (the most important part)
            if let insight = lead.relevanceInsight {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.warning)
                    
                    Text(insight)
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                }
                .padding(AppSpacing.spacing3)
                .background(AppColors.warning.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
            }
            
            // Matching snippet — the exact sentence that triggered the match
            if let snippet = lead.matchingSnippet {
                HStack(alignment: .top, spacing: 6) {
                    Rectangle()
                        .fill(AppColors.accentCyan)
                        .frame(width: 3)
                    
                    Text("\"\(snippet)\"")
                        .font(.system(size: 13, weight: .regular, design: .serif))
                        .italic()
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                }
                .padding(.vertical, AppSpacing.spacing2)
            }
            
            // Bottom row: Author + Quick actions
            HStack {
                Text("u/\(lead.author)")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textTertiary)
                
                Spacer()
                
                HStack(spacing: AppSpacing.spacing3) {
                    Label("\(lead.upvotes)", systemImage: "arrow.up")
                    Label("\(lead.commentCount)", systemImage: "bubble.right")
                }
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textTertiary)
                
                // Quick action buttons
                HStack(spacing: AppSpacing.spacing2) {
                    Button(action: onSave) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.success)
                            .padding(6)
                            .background(AppColors.success.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.error)
                            .padding(6)
                            .background(AppColors.error.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.leading, AppSpacing.spacing2)
            }
        }
        .padding(AppSpacing.spacing5)
        .background(AppColors.bg700)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(leadBorderGradient, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 2)
    }
    
    private var leadBorderGradient: some ShapeStyle {
        if let score = lead.score, score >= 70 {
            return AnyShapeStyle(AppColors.scoreHighGradient.opacity(0.4))
        }
        return AnyShapeStyle(Color.white.opacity(0.06))
    }
}

// MARK: - Date Extension

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - Mini Score Indicator

struct MiniScoreIndicator: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(AppColors.textTertiary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.15))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(value) / 100)
                }
            }
            .frame(width: 24, height: 4)
            Text("\(value)")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(color)
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            ForEach(Lead.samples) { lead in
                LeadCardView(
                    lead: lead,
                    onSave: {},
                    onDismiss: {},
                    onTap: {}
                )
            }
        }
        .padding()
    }
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}
