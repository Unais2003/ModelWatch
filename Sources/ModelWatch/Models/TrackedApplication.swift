import Foundation

struct TrackedApplication: Codable, Hashable, Identifiable, Sendable {
    let bundleIdentifier: String
    let displayName: String

    var id: String { bundleIdentifier }
}

