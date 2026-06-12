import Foundation
import SwiftData

enum SampleData {
    private static let seededKey = "com.modelwatch.sampleDataSeeded"

    static let subscriptionTemplates: [(name: String, cost: Double, renewal: Date)] = [
        ("ChatGPT Plus", 20.0, Date().addingTimeInterval(86400 * 14)),
        ("Claude Pro", 20.0, Date().addingTimeInterval(86400 * 10)),
        ("GitHub Copilot", 10.0, Date().addingTimeInterval(86400 * 20)),
        ("Cursor Pro", 20.0, Date().addingTimeInterval(86400 * 7)),
    ]

    static let appNames = ["ChatGPT", "Claude", "Cursor", "VS Code", "GitHub Copilot"]

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: seededKey) else { return }

        seedSubscriptions(context: context)
        seedActivitySessions(context: context)

        defaults.set(true, forKey: seededKey)
    }

    @MainActor
    private static func seedSubscriptions(context: ModelContext) {
        for template in subscriptionTemplates {
            let subscription = Subscription(
                serviceName: template.name,
                monthlyCost: template.cost,
                currencyCode: "USD",
                renewalDate: template.renewal,
                isActive: true
            )
            context.insert(subscription)
        }
        try? context.save()
    }

    @MainActor
    private static func seedActivitySessions(context: ModelContext) {
        let calendar = Calendar.current
        let now = Date()
        let daysBack = 14

        for dayOffset in 0...daysBack {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: day)
            let sessionsPerDay = Int.random(in: 2...6)

            for _ in 0..<sessionsPerDay {
                let appName = appNames.randomElement()!
                let hour = Int.random(in: 8...22)
                let minute = Int.random(in: 0...59)
                guard let sessionStart = calendar.date(byAdding: .hour, value: hour, to: startOfDay),
                      let sessionStart = calendar.date(byAdding: .minute, value: minute, to: sessionStart)
                else { continue }

                let durationMinutes = Double.random(in: 3...45)
                let sessionEnd = sessionStart.addingTimeInterval(durationMinutes * 60)

                let session = ActivitySession(
                    applicationBundleIdentifier: "com.\(appName.lowercased().replacingOccurrences(of: " ", with: ""))",
                    applicationName: appName,
                    startedAt: sessionStart,
                    endedAt: sessionEnd
                )
                context.insert(session)
            }
        }
        try? context.save()
    }
}
