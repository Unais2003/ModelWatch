import Foundation
import SwiftData

@Model
final class ActivitySession {
    @Attribute(.unique) var id: UUID
    var applicationBundleIdentifier: String
    var applicationName: String
    var startedAt: Date
    var endedAt: Date?

    init(
        id: UUID = UUID(),
        applicationBundleIdentifier: String,
        applicationName: String,
        startedAt: Date,
        endedAt: Date? = nil
    ) {
        self.id = id
        self.applicationBundleIdentifier = applicationBundleIdentifier
        self.applicationName = applicationName
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
}
