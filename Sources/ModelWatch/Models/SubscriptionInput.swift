import Foundation

struct SubscriptionInput: Equatable, Sendable {
    let serviceName: String
    let monthlyCost: Double
    let currencyCode: String
    let renewalDate: Date?
    let isActive: Bool
}

enum SubscriptionValidationError: LocalizedError, Equatable {
    case emptyServiceName
    case invalidMonthlyCost
    case unsupportedCurrencyCode

    var errorDescription: String? {
        switch self {
        case .emptyServiceName:
            "Enter a service name."
        case .invalidMonthlyCost:
            "Enter a monthly cost of zero or more."
        case .unsupportedCurrencyCode:
            "Choose a supported currency."
        }
    }
}
