enum DashboardLoadState: Equatable {
    case idle
    case loading
    case loaded
    case empty
    case failed(message: String)
}
