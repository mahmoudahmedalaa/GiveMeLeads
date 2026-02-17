import SwiftUI

/// Context-aware card actions per lead status
enum LeadCardAction {
    case save       // New → Saved
    case unsave     // Saved → New
    case dismiss    // New → Dismissed
    case delete     // Permanent delete
    case reply      // Generate AI reply
    case contacted  // Mark as contacted
}

/// A card displaying a Reddit lead with actionable intelligence.
/// Actions adapt based on the lead's current status.
struct LeadCardView: View {
    let lead: Lead
    var profileName: String? = nil
    let actions: (LeadCardAction) -> Void
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
                
                if let name = profileName {
                    Text(name)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, AppSpacing.spacing2)
                        .padding(.vertical, 2)
                        .background(AppColors.bg800)
                        .clipShape(Capsule())
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Status badge for non-new leads
                if lead.status == .saved {
                    Text("Saved")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(AppColors.success)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppColors.success.opacity(0.15))
                        .clipShape(Capsule())
                } else if lead.status == .contacted {
                    Text("Contacted")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(AppColors.accentCyan)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppColors.accentCyan.opacity(0.15))
                        .clipShape(Capsule())
                }
                
                Text(lead.postedAt.timeAgoDisplay())
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            // Title — the Reddit post/comment title
            Text(lead.title)
                .font(AppTypography.heading3)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(2)
            
            // ★ KEY INSIGHT — why this lead matters
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
            
            // Bottom row: Author + Context-aware actions
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
                
                // Context-aware action buttons
                HStack(spacing: AppSpacing.spacing2) {
                    switch lead.status {
                    case .new:
                        // New leads: Save / Reply / Dismiss
                        actionButton(icon: "bookmark", color: AppColors.success) { actions(.save) }
                        actionButton(icon: "sparkles", color: AppColors.primary400) { actions(.reply) }
                        actionButton(icon: "xmark", color: AppColors.error, iconSize: 12) { actions(.dismiss) }
                        
                    case .saved:
                        // Saved leads: Reply / Contacted / Unsave / Delete
                        actionButton(icon: "sparkles", color: AppColors.primary400) { actions(.reply) }
                        actionButton(icon: "envelope", color: AppColors.accentCyan) { actions(.contacted) }
                        actionButton(icon: "bookmark.slash", color: AppColors.warning) { actions(.unsave) }
                        actionButton(icon: "trash", color: AppColors.error, iconSize: 12) { actions(.delete) }
                        
                    case .contacted:
                        // Contacted leads: Reply / Delete
                        actionButton(icon: "sparkles", color: AppColors.primary400) { actions(.reply) }
                        actionButton(icon: "trash", color: AppColors.error, iconSize: 12) { actions(.delete) }
                        
                    default:
                        EmptyView()
                    }
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
    
    private func actionButton(icon: String, color: Color, iconSize: CGFloat = 14, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: iconSize))
                .foregroundColor(color)
                .padding(6)
                .background(color.opacity(0.1))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
    
    private var leadBorderGradient: some ShapeStyle {
        if let score = lead.score, score >= 7 {
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
                    actions: { _ in },
                    onTap: {}
                )
            }
        }
        .padding()
    }
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}
