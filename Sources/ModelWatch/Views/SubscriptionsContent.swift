import SwiftUI

struct SubscriptionsContent: View {
    let viewModel: DashboardViewModel

    @State private var editor: SubscriptionEditorPresentation?
    @State private var subscriptionPendingDeletion: Subscription?
    @State private var focusAfterPresentation: FocusedControl?
    @FocusState private var focusedControl: FocusedControl?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                if let error = viewModel.subscriptionMutationError {
                    errorBanner(error)
                }

                subscriptionsContent
            }
            .padding(24)
        }
        .navigationTitle("Subscriptions")
        .sheet(item: $editor, onDismiss: restoreFocusAfterPresentation) { presentation in
            NavigationStack {
                SubscriptionEditorView(
                    subscription: presentation.subscription,
                    viewModel: viewModel
                )
            }
        }
        .alert(
            "Delete Subscription?",
            isPresented: Binding(
                get: { subscriptionPendingDeletion != nil },
                set: { isPresented in
                    if !isPresented {
                        subscriptionPendingDeletion = nil
                        restoreFocusAfterPresentation()
                    }
                }
            ),
            presenting: subscriptionPendingDeletion
        ) { subscription in
            Button("Delete", role: .destructive) {
                focusAfterPresentation = .addSubscription
                Task {
                    _ = await viewModel.deleteSubscription(subscription)
                    subscriptionPendingDeletion = nil
                    restoreFocusAfterPresentation()
                }
            }
            Button("Cancel", role: .cancel) {
                subscriptionPendingDeletion = nil
                restoreFocusAfterPresentation()
            }
        } message: { subscription in
            Text("This permanently deletes \(subscription.serviceName).")
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Subscriptions")
                    .font(.title)
                    .fontWeight(.semibold)
                Text(subscriptionSubtitle)
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                presentEditor(subscription: nil, returningFocusTo: .addSubscription)
            } label: {
                Label("Add Subscription", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isMutatingSubscription)
            .focusable()
            .focused($focusedControl, equals: .addSubscription)
        }
    }

    private var subscriptionSubtitle: String {
        switch viewModel.subscriptionsState {
        case .idle, .loading:
            "Loading subscriptions…"
        case .loaded:
            viewModel.activeSubscriptionCount == 1
                ? "1 active subscription"
                : "\(viewModel.activeSubscriptionCount) active subscriptions"
        case .empty:
            "No subscriptions"
        case .failed:
            "Subscriptions unavailable"
        }
    }

    @ViewBuilder
    private var subscriptionsContent: some View {
        switch viewModel.subscriptionsState {
        case .idle, .loading:
            DashboardLoadingView(title: "Loading subscriptions…")
        case .loaded:
            monthlyTotals
            subscriptionList
        case .empty:
            DashboardStatusView(
                title: "No Subscriptions",
                message: "Add a recurring AI service to track its monthly cost.",
                systemImage: "creditcard",
                actionTitle: "Add Subscription"
            ) {
                presentEditor(subscription: nil, returningFocusTo: .addSubscription)
            }
        case let .failed(message):
            DashboardStatusView(
                title: "Subscriptions Unavailable",
                message: message,
                systemImage: "exclamationmark.triangle",
                actionTitle: "Try Again"
            ) {
                Task { await viewModel.reloadSubscriptions() }
            }
        }
    }

    @ViewBuilder
    private var monthlyTotals: some View {
        if !viewModel.subscriptionTotals.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Active Monthly Totals")
                    .font(.headline)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 180), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(viewModel.subscriptionTotals) { total in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(total.currencyCode)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(total.monthlyCost, format: .currency(code: total.currencyCode))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .monospacedDigit()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(.background.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }

    private var subscriptionList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("All Subscriptions")
                .font(.headline)

            ForEach(viewModel.subscriptions, id: \.id) { subscription in
                subscriptionRow(subscription)
            }
        }
    }

    private func subscriptionRow(_ subscription: Subscription) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "creditcard.fill")
                .foregroundStyle(subscription.isActive ? .primary : .secondary)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(subscription.serviceName)
                        .font(.headline)

                    if !subscription.isActive {
                        Text("Inactive")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary)
                            .clipShape(Capsule())
                    }
                }

                if let renewalDate = subscription.renewalDate {
                    Text("Renews \(renewalDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(subscription.monthlyCost, format: .currency(code: subscription.currencyCode))
                .fontWeight(.semibold)
                .monospacedDigit()

            Menu {
                Button("Edit", systemImage: "pencil") {
                    presentEditor(
                        subscription: subscription,
                        returningFocusTo: .subscriptionActions(subscription.id)
                    )
                }

                Button(
                    subscription.isActive ? "Deactivate" : "Reactivate",
                    systemImage: subscription.isActive ? "pause.circle" : "play.circle"
                ) {
                    Task {
                        _ = await viewModel.setSubscriptionActive(
                            !subscription.isActive,
                            subscription: subscription
                        )
                    }
                }

                Divider()

                Button("Delete", systemImage: "trash", role: .destructive) {
                    focusAfterPresentation = .subscriptionActions(subscription.id)
                    subscriptionPendingDeletion = subscription
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
            }
            .menuStyle(.borderlessButton)
            .accessibilityLabel("Actions for \(subscription.serviceName)")
            .disabled(viewModel.isMutatingSubscription)
            .focusable()
            .focused($focusedControl, equals: .subscriptionActions(subscription.id))
        }
        .padding(16)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func errorBanner(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .foregroundStyle(.red)
            .accessibilityLabel("Error: \(message)")
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func presentEditor(
        subscription: Subscription?,
        returningFocusTo control: FocusedControl
    ) {
        viewModel.clearSubscriptionMutationError()
        focusAfterPresentation = control
        editor = SubscriptionEditorPresentation(subscription: subscription)
    }

    private func restoreFocusAfterPresentation() {
        guard let focusAfterPresentation else { return }
        self.focusAfterPresentation = nil

        Task { @MainActor in
            // Wait until the sheet or alert releases its separate focus scope.
            try? await Task.sleep(for: .milliseconds(100))
            focusedControl = focusAfterPresentation
        }
    }
}

private enum FocusedControl: Hashable {
    case addSubscription
    case subscriptionActions(UUID)
}

private struct SubscriptionEditorPresentation: Identifiable {
    let id = UUID()
    let subscription: Subscription?
}
