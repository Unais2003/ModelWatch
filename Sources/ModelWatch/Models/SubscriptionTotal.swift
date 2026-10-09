import Foundation

struct SubscriptionTotal: Identifiable, Equatable, Sendable {
    let currencyCode: String
    let monthlyCost: Double

    var id: String { currencyCode }
}
