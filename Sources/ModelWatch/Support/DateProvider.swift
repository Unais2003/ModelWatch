import Foundation

@MainActor
protocol DateProvider {
    var now: Date { get }
}

struct SystemDateProvider: DateProvider {
    var now: Date { Date() }
}

