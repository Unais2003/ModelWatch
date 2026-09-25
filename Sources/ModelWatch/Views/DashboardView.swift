import SwiftUI

struct DashboardView: View {
    let viewModel: DashboardViewModel
    @SceneStorage("selectedDestination") private var selectedDestinationRawValue = AppDestination.overview.rawValue
    @AppStorage("hasCompletedPrivacyOnboarding") private var hasCompletedPrivacyOnboarding = false

    private var selectedDestination: Binding<AppDestination?> {
        Binding {
            AppDestination(rawValue: selectedDestinationRawValue)
        } set: { newValue in
            selectedDestinationRawValue = newValue?.rawValue ?? AppDestination.overview.rawValue
        }
    }

    var body: some View {
        NavigationSplitView {
            List(AppDestination.allCases, selection: selectedDestination) { destination in
                Label(destination.title, systemImage: destination.systemImage)
                    .tag(destination)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 220)
        } detail: {
            DashboardDetailView(
                destination: selectedDestination.wrappedValue ?? .overview,
                viewModel: viewModel
            )
        }
        .task {
            await viewModel.loadData()
        }
        .task {
            await viewModel.refreshActiveSessionPeriodically()
        }
        .onChange(of: viewModel.analyticsRevision) {
            Task {
                await viewModel.reloadAnalytics()
            }
        }
        .sheet(
            isPresented: Binding(
                get: { !hasCompletedPrivacyOnboarding },
                set: { isPresented in
                    if !isPresented {
                        hasCompletedPrivacyOnboarding = true
                    }
                }
            )
        ) {
            PrivacyOnboardingView {
                hasCompletedPrivacyOnboarding = true
            }
        }
    }
}
