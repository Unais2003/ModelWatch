import Foundation
import SwiftData

@Model
final class Subscription {
    @Attribute(.unique) var id: UUID
    var serviceName: String
    var monthlyCost: Double
    var currencyCode: String
    var renewalDate: Date?
    var isActive: Bool

    init(
        id: UUID = UUID(),
        serviceName: String,
        monthlyCost: Double,
        currencyCode: String,
        renewalDate: Date? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.serviceName = serviceName
        self.monthlyCost = monthlyCost
        self.currencyCode = currencyCode
        self.renewalDate = renewalDate
        self.isActive = isActive
    }
}
