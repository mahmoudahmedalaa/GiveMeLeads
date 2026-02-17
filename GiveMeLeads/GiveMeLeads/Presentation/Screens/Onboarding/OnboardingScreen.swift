import SwiftUI

// MARK: - Onboarding Data

private struct OnboardingSlide: Identifiable {
    let id: Int
    let icon: String
    let iconColors: [Color]
    let title: String
    let subtitle: String
    let features: [(icon: String, text: String)]
}

private let onboardingSlides: [OnboardingSlide] = [
    OnboardingSlide(
        id: 0,
        icon: "target",
        iconColors: [Color(hex: "#8B5CF6"), Color(hex: "#3B82F6")],
        title: "Find Your Ideal\nCustomers",
        subtitle: "Scan Reddit to find people actively looking for what you offer.",
        features: [
            (icon: "magnifyingglass", text: "Smart keyword matching"),
            (icon: "clock.arrow.circlepath", text: "Fresh leads every scan"),
            (icon: "person.3.fill", text: "Real people, real intent"),
        ]
    ),
    OnboardingSlide(
        id: 1,
        icon: "chart.bar.fill",
        iconColors: [Color(hex: "#10B981"), Color(hex: "#06B6D4")],
        title: "Smart Scoring\n& Filtering",
        subtitle: "Every lead gets a smart relevance score so you focus only on the hottest prospects.",
        features: [
            (icon: "star.fill", text: "Smart relevance scoring"),
            (icon: "line.3.horizontal.decrease.circle", text: "Filter by score & recency"),
            (icon: "bookmark.fill", text: "Save the best leads"),
        ]
    ),
    OnboardingSlide(
        id: 2,
        icon: "text.bubble.fill",
        iconColors: [Color(hex: "#F59E0B"), Color(hex: "#EF4444")],
        title: "Reply &\nConvert",
        subtitle: "AI crafts contextual replies for each lead. Engage naturally, convert more.",
        features: [
            (icon: "sparkles", text: "AI-generated reply suggestions"),
            (icon: "hand.tap.fill", text: "One-tap copy & engage"),
            (icon: "chart.line.uptrend.xyaxis", text: "Track your outreach"),
        ]
    ),
]

// MARK: - OnboardingScreen

struct OnboardingScreen: View {
    let onComplete: () -> Void
    
    @State private var currentPage = 0
    @State private var showPaywall = false
    
    var body: some View {
        ZStack {
            // Background
            AppColors.background.ignoresSafeArea()
            
            // Subtle radial glow behind icon
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            onboardingSlides[currentPage].iconColors[0].opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(y: -120)
                .animation(.easeInOut(duration: 0.6), value: currentPage)
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button(action: { finishOnboarding() }) {
                        Text("Skip")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                .padding(.horizontal, AppSpacing.spacing5)
                .padding(.top, AppSpacing.spacing3)
                
                Spacer()
                
                // Slide Content
                slideContent(onboardingSlides[currentPage])
                    .id(currentPage)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                
                Spacer()
                
                // Page Indicator
                pageIndicator
                    .padding(.bottom, AppSpacing.spacing5)
                
                // CTA Button
                ctaButton
                    .padding(.horizontal, AppSpacing.spacing5)
                    .padding(.bottom, AppSpacing.spacing6)
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallScreen()
                .onDisappear {
                    onComplete()
                }
        }
    }
    
    // MARK: - Slide Content
    
    @ViewBuilder
    private func slideContent(_ slide: OnboardingSlide) -> some View {
        VStack(spacing: AppSpacing.spacing5) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: slide.iconColors.map { $0.opacity(0.15) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: slide.icon)
                    .font(.system(size: 52, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: slide.iconColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(color: slide.iconColors[0].opacity(0.3), radius: 30, y: 10)
            
            // Title
            Text(slide.title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            // Subtitle
            Text(slide.subtitle)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, AppSpacing.spacing4)
            
            // Feature list
            VStack(spacing: AppSpacing.spacing3) {
                ForEach(slide.features, id: \.text) { feature in
                    HStack(spacing: AppSpacing.spacing3) {
                        Image(systemName: feature.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: slide.iconColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(slide.iconColors[0].opacity(0.1))
                            )
                        
                        Text(feature.text)
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, AppSpacing.spacing6)
            .padding(.top, AppSpacing.spacing2)
        }
        .padding(.horizontal, AppSpacing.spacing4)
    }
    
    // MARK: - Page Indicator
    
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<onboardingSlides.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage
                          ? AnyShapeStyle(AppColors.primaryGradient)
                          : AnyShapeStyle(AppColors.textTertiary.opacity(0.3)))
                    .frame(width: index == currentPage ? 28 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: currentPage)
            }
        }
    }
    
    // MARK: - CTA Button
    
    private var ctaButton: some View {
        Button(action: { advancePage() }) {
            HStack(spacing: 8) {
                Text(currentPage == onboardingSlides.count - 1 ? "Get Started" : "Next")
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.semibold)
                
                Image(systemName: currentPage == onboardingSlides.count - 1 ? "arrow.right" : "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .fill(AppColors.primaryGradient)
            )
            .shadow(color: AppColors.primary500.opacity(0.3), radius: 12, y: 6)
        }
    }
    
    // MARK: - Actions
    
    private func advancePage() {
        if currentPage < onboardingSlides.count - 1 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                currentPage += 1
            }
        } else {
            finishOnboarding()
        }
    }
    
    private func finishOnboarding() {
        showPaywall = true
    }
}

#Preview {
    OnboardingScreen(onComplete: {})
        .preferredColorScheme(.dark)
}
