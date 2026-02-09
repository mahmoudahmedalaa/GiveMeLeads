import SwiftUI

/// A card displaying a Reddit lead with score, metadata, and swipe actions
struct LeadCardView: View {
    let lead: Lead
    let onSave: () -> Void
    let onDismiss: () -> Void
    let onTap: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1
    
    private var swipeColor: Color {
        if offset > 50 { return AppColors.success.opacity(0.3) }
        if offset < -50 { return AppColors.error.opacity(0.3) }
        return .clear
    }
    
    var body: some View {
        ZStack {
            // Swipe indicator background
            HStack {
                if offset > 50 {
                    HStack(spacing: AppSpacing.spacing2) {
                        Image(systemName: "bookmark.fill")
                        Text("Save")
                    }
                    .font(AppTypography.buttonMedium)
                    .foregroundColor(AppColors.success)
                    Spacer()
                } else if offset < -50 {
                    Spacer()
                    HStack(spacing: AppSpacing.spacing2) {
                        Text("Dismiss")
                        Image(systemName: "xmark")
                    }
                    .font(AppTypography.buttonMedium)
                    .foregroundColor(AppColors.error)
                }
            }
            .padding(.horizontal, AppSpacing.spacing6)
            
            // Card content
            cardContent
                .offset(x: offset)
                .opacity(opacity)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            offset = gesture.translation.width
                        }
                        .onEnded { gesture in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if offset > 100 {
                                    offset = 400
                                    opacity = 0
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    onSave()
                                } else if offset < -100 {
                                    offset = -400
                                    opacity = 0
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    onDismiss()
                                } else {
                                    offset = 0
                                }
                            }
                        }
                )
        }
        .onTapGesture(perform: onTap)
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing3) {
            // Top row: Score + Subreddit + Time
            HStack {
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
                
                Spacer()
                
                Text(lead.postedAt.timeAgoDisplay())
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            // Title
            Text(lead.title)
                .font(AppTypography.heading3)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(3)
            
            // Bottom row: Author + Engagement
            HStack {
                Text("u/\(lead.author)")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textTertiary)
                
                Spacer()
                
                HStack(spacing: AppSpacing.spacing4) {
                    Label("\(lead.upvotes)", systemImage: "arrow.up")
                    Label("\(lead.commentCount)", systemImage: "bubble.right")
                }
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(AppSpacing.spacing5)
        .background(AppColors.bg700)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(
                    leadBorderGradient,
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 2)
    }
    
    private var leadBorderGradient: some ShapeStyle {
        if let score = lead.score, score >= 80 {
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
