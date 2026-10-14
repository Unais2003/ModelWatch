import Foundation
import OSLog

@MainActor
enum AppPerformanceProbe {
    static let benchmarkEnvironmentKey = "MODELWATCH_PERFORMANCE_BENCHMARK"
    static let outputEnvironmentKey = "MODELWATCH_PERFORMANCE_OUTPUT"

    private static let logger = Logger(
        subsystem: AppConstants.bundleIdentifier,
        category: "PerformanceProbe"
    )
    private static var launchStartUptime: TimeInterval?

    static func isBenchmarkEnabled(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> Bool {
        environment[benchmarkEnvironmentKey] == "1"
    }

    static func markLaunchStarted(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        uptime: TimeInterval = ProcessInfo.processInfo.systemUptime
    ) {
        guard isBenchmarkEnabled(environment: environment) else { return }
        launchStartUptime = uptime
    }

    static func recordLaunchReady(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        uptime: TimeInterval = ProcessInfo.processInfo.systemUptime,
        fileManager: FileManager = .default
    ) {
        guard isBenchmarkEnabled(environment: environment),
              let launchStartUptime,
              let outputPath = environment[outputEnvironmentKey],
              let outputURL = validatedOutputURL(
                path: outputPath,
                fileManager: fileManager
              )
        else {
            return
        }

        let measurement = LaunchMeasurement(
            launchReadyMilliseconds: durationMilliseconds(
                from: launchStartUptime,
                to: uptime
            )
        )

        do {
            let data = try JSONEncoder().encode(measurement)
            try data.write(to: outputURL, options: .atomic)
            self.launchStartUptime = nil
        } catch {
            logger.error("Unable to write the requested performance measurement.")
        }
    }

    static func durationMilliseconds(
        from startUptime: TimeInterval,
        to endUptime: TimeInterval
    ) -> Double {
        max(0, endUptime - startUptime) * 1_000
    }

    private static func validatedOutputURL(
        path: String,
        fileManager: FileManager
    ) -> URL? {
        let outputURL = URL(fileURLWithPath: path)
            .standardizedFileURL
            .resolvingSymlinksInPath()
        let temporaryDirectory = fileManager.temporaryDirectory
            .standardizedFileURL
            .resolvingSymlinksInPath()
        let temporaryPath = temporaryDirectory.path.hasSuffix("/")
            ? temporaryDirectory.path
            : temporaryDirectory.path + "/"

        guard outputURL.path.hasPrefix(temporaryPath) else {
            logger.error("Performance output must be inside the temporary directory.")
            return nil
        }

        return outputURL
    }
}

private struct LaunchMeasurement: Encodable {
    let schemaVersion = 1
    let launchReadyMilliseconds: Double
}
