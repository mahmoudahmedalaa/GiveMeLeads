import SwiftUI

// MARK: - Display helpers for Entitlements / Plan

extension Plan {
    var displayName: String {
        switch self {
        case .free: "Free"
        case .starter: "Starter"
        case .pro: "Pro"
        }
    }
    
    var monthlyPrice: String {
        switch self {
        case .free: "$0"
        case .starter: "$9"
        case .pro: "$19"
        }
    }
    
    var priceSubtitle: String {
        switch self {
        case .free: "forever"
        case .starter: "/month"
        case .pro: "/month"
        }
    }
    
    var icon: String {
        switch self {
        case .free: "person.crop.circle"
        case .starter: "bolt.circle.fill"
        case .pro: "crown.fill"
        }
    }
    
    var tagline: String {
        switch self {
        case .free: "Get started"
        case .starter: "For growing teams"
        case .pro: "Unlimited power"
        }
    }
}

// MARK: - Feature row data

private struct FeatureRow: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let free: String
    let starter: String
    let pro: String
}

private let featureRows: [FeatureRow] = [
    FeatureRow(icon: "person.2",       label: "Profiles",       free: "1",     starter: "5",         pro: "20"),
    FeatureRow(icon: "magnifyingglass",label: "Daily scans",    free: "1",     starter: "10",        pro: "100"),
    FeatureRow(icon: "eye",            label: "Visible leads",  free: "5",     starter: "500",       pro: "5,000"),
    FeatureRow(icon: "text.word.spacing", label: "Keywords",    free: "5",     starter: "100",       pro: "1,000"),
    FeatureRow(icon: "square.and.arrow.up", label: "CSV export", free: "—",   starter: "✓",         pro: "✓"),
    FeatureRow(icon: "bell.badge",     label: "Alerts",         free: "—",     starter: "✓",         pro: "✓"),
    FeatureRow(icon: "bookmark",       label: "Saved searches", free: "—",     starter: "—",         pro: "✓"),
    FeatureRow(icon: "link",           label: "Webhooks",       free: "—",     starter: "—",         pro: "✓"),
]

// MARK: - PaywallScreen

struct PaywallScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: Plan = .pro
    @State private var isLoading = false
    
    private let currentPlan = GatingService.shared.currentPlan
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppSpacing.spacing5) {
                    header
                    planSelector
                    featureMatrix
                    ctaSection
                }
                .padding(.horizontal, AppSpacing.spacing5)
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: AppSpacing.spacing3) {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.premiumGradient)
                .padding(.top, AppSpacing.spacing4)
            
            Text("Choose Your Plan")
                .font(AppTypography.heading1)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Unlock more leads, scans, and features")
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Plan Selector Cards
    
    private var planSelector: some View {
        HStack(spacing: AppSpacing.spacing3) {
            ForEach([Plan.starter, Plan.pro], id: \.self) { plan in
                planCard(plan)
            }
        }
    }
    
    private func planCard(_ plan: Plan) -> some View {
        let isSelected = selectedPlan == plan
        let isPro = plan == .pro
        
        return Button(action: { withAnimation(.spring(response: 0.3)) { selectedPlan = plan } }) {
            VStack(spacing: AppSpacing.spacing2) {
                if isPro {
                    Text("BEST VALUE")
                        .font(.system(size: 9, weight: .heavy))
                        .tracking(1)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppColors.primaryGradient)
                        .clipShape(Capsule())
                } else {
                    Text(" ")
                        .font(.system(size: 9, weight: .heavy))
                        .padding(.vertical, 3)
                }
                
                Image(systemName: plan.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(isPro ? AppColors.premiumGradient : LinearGradient(
                        colors: [AppColors.accentCyan, AppColors.accentCyan],
                        startPoint: .leading, endPoint: .trailing
                    ))
                
                Text(plan.displayName)
                    .font(AppTypography.heading3)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(plan.monthlyPrice)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    Text(plan.priceSubtitle)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Text(plan.tagline)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.spacing4)
            .padding(.horizontal, AppSpacing.spacing3)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .fill(isSelected ? AppColors.bg600 : AppColors.bg700)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .strokeBorder(
                        isSelected
                            ? (isPro ? AnyShapeStyle(AppColors.premiumGradient) : AnyShapeStyle(AppColors.accentCyan))
                            : AnyShapeStyle(Color.clear),
                        lineWidth: 2
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Feature Comparison Matrix
    
    private var featureMatrix: some View {
        VStack(spacing: 0) {
            // Column headers
            HStack {
                Text("Features")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Free")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
                    .frame(width: 50)
                
                Text("Starter")
                    .font(AppTypography.caption)
                    .foregroundColor(selectedPlan == .starter ? AppColors.accentCyan : AppColors.textTertiary)
                    .frame(width: 55)
                
                Text("Pro")
                    .font(AppTypography.caption)
                    .foregroundColor(selectedPlan == .pro ? AppColors.primary400 : AppColors.textTertiary)
                    .frame(width: 50)
            }
            .padding(.horizontal, AppSpacing.spacing4)
            .padding(.vertical, AppSpacing.spacing3)
            
            Divider().overlay(AppColors.bg600)
            
            // Feature rows
            ForEach(featureRows) { row in
                HStack(spacing: AppSpacing.spacing2) {
                    Image(systemName: row.icon)
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textTertiary)
                        .frame(width: 18)
                    
                    Text(row.label)
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    cellText(row.free, dimmed: true)
                        .frame(width: 50)
                    
                    cellText(row.starter, highlight: selectedPlan == .starter)
                        .frame(width: 55)
                    
                    cellText(row.pro, highlight: selectedPlan == .pro)
                        .frame(width: 50)
                }
                .padding(.horizontal, AppSpacing.spacing4)
                .padding(.vertical, 10)
                
                if row.id != featureRows.last?.id {
                    Divider().overlay(AppColors.bg600.opacity(0.5))
                        .padding(.horizontal, AppSpacing.spacing4)
                }
            }
        }
        .background(AppColors.bg700)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }
    
    private func cellText(_ text: String, dimmed: Bool = false, highlight: Bool = false) -> some View {
        Group {
            if text == "✓" {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(highlight ? AppColors.success : AppColors.success.opacity(0.5))
            } else if text == "—" {
                Text("—")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary.opacity(0.4))
            } else {
                Text(text)
                    .font(AppTypography.bodySmall)
                    .fontWeight(highlight ? .semibold : .regular)
                    .foregroundColor(
                        dimmed ? AppColors.textTertiary :
                        highlight ? AppColors.textPrimary : AppColors.textSecondary
                    )
            }
        }
    }
    
    // MARK: - CTA
    
    private var ctaSection: some View {
        VStack(spacing: AppSpacing.spacing3) {
            if currentPlan == selectedPlan {
                HStack(spacing: AppSpacing.spacing2) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(AppColors.success)
                    Text("This is your current plan")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.success)
                }
                .padding(.vertical, AppSpacing.spacing3)
            } else {
                PrimaryButton(
                    "Start 7-Day Free Trial — \(selectedPlan.displayName)",
                    isLoading: isLoading
                ) {
                    // TODO: Integrate StoreKit 2
                    isLoading = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        isLoading = false
                        dismiss()
                    }
                }
                
                Text("Then \(selectedPlan.monthlyPrice)\(selectedPlan.priceSubtitle) · Cancel anytime")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            HStack(spacing: AppSpacing.spacing4) {
                GhostButton("Privacy Policy") {
                    // TODO: Open privacy policy
                }
                Text("·").foregroundColor(AppColors.textTertiary)
                GhostButton("Terms of Use") {
                    // TODO: Open terms
                }
                Text("·").foregroundColor(AppColors.textTertiary)
                GhostButton("Restore") {
                    // TODO: Restore purchases
                }
            }
            .font(AppTypography.bodySmall)
        }
        .padding(.top, AppSpacing.spacing2)
    }
}

#Preview {
    PaywallScreen()
        .preferredColorScheme(.dark)
}
