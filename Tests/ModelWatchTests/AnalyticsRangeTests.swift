import Foundation
import XCTest
@testable import ModelWatch

final class AnalyticsRangeTests: XCTestCase {
    func testDayIntervalUsesCalendarAndHandlesSpringDSTTransition() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))
        let date = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026,
            month: 3,
            day: 8,
            hour: 12
        )))

        let interval = try XCTUnwrap(AnalyticsRange.day.dateInterval(containing: date, calendar: calendar))

        XCTAssertEqual(interval.duration, 23 * 60 * 60, accuracy: 0.001)
        XCTAssertEqual(calendar.component(.hour, from: interval.start), 0)
        XCTAssertEqual(calendar.component(.day, from: interval.start), 8)
        XCTAssertEqual(calendar.component(.day, from: interval.end), 9)
    }

    func testWeekIntervalRespectsConfiguredFirstWeekday() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        calendar.firstWeekday = 2
        let date = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026,
            month: 9,
            day: 25,
            hour: 12
        )))

        let interval = try XCTUnwrap(AnalyticsRange.week.dateInterval(containing: date, calendar: calendar))

        XCTAssertEqual(calendar.component(.weekday, from: interval.start), 2)
        XCTAssertEqual(calendar.component(.day, from: interval.start), 21)
        XCTAssertEqual(calendar.component(.day, from: interval.end), 28)
    }

    func testMonthIntervalUsesCalendarMonthBoundaries() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let date = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2024,
            month: 2,
            day: 14,
            hour: 12
        )))

        let interval = try XCTUnwrap(AnalyticsRange.month.dateInterval(containing: date, calendar: calendar))

        XCTAssertEqual(calendar.component(.month, from: interval.start), 2)
        XCTAssertEqual(calendar.component(.day, from: interval.start), 1)
        XCTAssertEqual(calendar.component(.month, from: interval.end), 3)
        XCTAssertEqual(calendar.component(.day, from: interval.end), 1)
        XCTAssertEqual(interval.duration, 29 * 24 * 60 * 60, accuracy: 0.001)
    }
}
