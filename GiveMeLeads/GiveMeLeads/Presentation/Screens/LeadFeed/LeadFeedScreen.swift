import SwiftUI

struct LeadFeedScreen: View {
    @State private var leads = Lead.samples
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if isLoading {
                    loadingView
                } else if leads.isEmpty {
                    EmptyStateView(
                        icon: "target",
                        title: "No Leads Yet",
                        message: "Set up keywords to start\ndiscovering leads on Reddit",
                        actionTitle: "Add Keywords",
                        action: { /* TODO: Switch to keywords tab */ }
                    )
                } else {
                    feedContent
                }
            }
            .navigationTitle("GiveMeLeads")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { /* TODO: Filter sheet */ }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(AppColors.primary400)
                    }
                }
            }
            .refreshable {
                // TODO: Fetch new leads
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }
    
    private var feedContent: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.spacing4) {
                ForEach(leads) { lead in
                    LeadCardView(
                        lead: lead,
                        onSave: {
                            withAnimation {
                                leads.removeAll { $0.id == lead.id }
                            }
                        },
                        onDismiss: {
                            withAnimation {
                                leads.removeAll { $0.id == lead.id }
                            }
                        },
                        onTap: {
                            // TODO: Navigate to detail
                        }
                    )
                }
            }
            .padding(.horizontal, AppSpacing.spacing4)
            .padding(.bottom, AppSpacing.spacing12)
        }
    }
    
    private var loadingView: some View {
        ScrollView {
            VStack(spacing: AppSpacing.spacing4) {
                ForEach(0..<4, id: \.self) { _ in
                    SkeletonCard()
                }
            }
            .padding(.horizontal, AppSpacing.spacing4)
        }
    }
}

#Preview {
    LeadFeedScreen()
        .preferredColorScheme(.dark)
}
