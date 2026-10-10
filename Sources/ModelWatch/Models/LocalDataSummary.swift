struct LocalDataSummary: Equatable, Sendable {
    let activitySessionCount: Int
    let subscriptionCount: Int

    static let empty = LocalDataSummary(
        activitySessionCount: 0,
        subscriptionCount: 0
    )

    var isEmpty: Bool {
        activitySessionCount == 0 && subscriptionCount == 0
    }
}
