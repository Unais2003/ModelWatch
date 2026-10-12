import SwiftUI

struct SubscriptionEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let subscription: Subscription?
    let viewModel: DashboardViewModel

    @State private var serviceName: String
    @State private var monthlyCost: Double?
    @State private var currencyCode: String
    @State private var includesRenewalDate: Bool
    @State private var renewalDate: Date
    @State private var isActive: Bool
    @State private var localError: String?
    @State private var isSaving = false

    init(subscription: Subscription?, viewModel: DashboardViewModel) {
        self.subscription = subscription
        self.viewModel = viewModel
        _serviceName = State(initialValue: subscription?.serviceName ?? "")
        _monthlyCost = State(initialValue: subscription?.monthlyCost)
        _currencyCode = State(initialValue: subscription?.currencyCode ?? Self.defaultCurrencyCode)
        _includesRenewalDate = State(initialValue: subscription?.renewalDate != nil)
        _renewalDate = State(initialValue: subscription?.renewalDate ?? Date())
        _isActive = State(initialValue: subscription?.isActive ?? true)
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                TextField("Service name", text: $serviceName)
                    .textContentType(.organizationName)

                TextField(
                    "Monthly cost",
                    value: $monthlyCost,
                    format: .number.precision(.fractionLength(0...2))
                )

                Picker("Currency", selection: $currencyCode) {
                    ForEach(Self.currencyCodes, id: \.self) { code in
                        Text(code).tag(code)
                    }
                }

                Toggle("Has renewal date", isOn: $includesRenewalDate)

                if includesRenewalDate {
                    DatePicker("Renewal date", selection: $renewalDate, displayedComponents: .date)
                }

                Toggle("Active", isOn: $isActive)

                if let error = localError ?? viewModel.subscriptionMutationError {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .accessibilityLabel("Error: \(error)")
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button {
                    save()
                } label: {
                    HStack(spacing: 6) {
                        if isSaving {
                            ProgressView()
                                .controlSize(.small)
                                .accessibilityHidden(true)
                            Text("Saving…")
                        } else {
                            Text(subscription == nil ? "Add" : "Save")
                        }
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(isSaving)
            }
            .padding()
        }
        .frame(
            minWidth: 440,
            idealWidth: 440,
            minHeight: includesRenewalDate ? 390 : 340,
            idealHeight: includesRenewalDate ? 390 : 340
        )
        .navigationTitle(subscription == nil ? "Add Subscription" : "Edit Subscription")
        .onAppear {
            viewModel.clearSubscriptionMutationError()
        }
    }

    private func save() {
        guard let monthlyCost else {
            localError = SubscriptionValidationError.invalidMonthlyCost.localizedDescription
            return
        }

        localError = nil
        isSaving = true
        let input = SubscriptionInput(
            serviceName: serviceName,
            monthlyCost: monthlyCost,
            currencyCode: currencyCode,
            renewalDate: includesRenewalDate ? renewalDate : nil,
            isActive: isActive
        )

        Task {
            let succeeded: Bool
            if let subscription {
                succeeded = await viewModel.updateSubscription(subscription, with: input)
            } else {
                succeeded = await viewModel.addSubscription(input)
            }

            isSaving = false
            if succeeded {
                dismiss()
            }
        }
    }

    private static let currencyCodes = Locale.commonISOCurrencyCodes.sorted()

    private static var defaultCurrencyCode: String {
        let localCurrency = Locale.current.currency?.identifier ?? "USD"
        return currencyCodes.contains(localCurrency) ? localCurrency : "USD"
    }
}
