import Foundation
import XCTest
@testable import Chronicle

final class HearingChartDataTests: XCTestCase {
    func testPureToneAverageRequiresExpectedFrequencies() {
        let incomplete = HearingTestRecord(right500: 10, right1000: 15)
        let complete = HearingTestRecord(right500: 10, right1000: 15, right2000: 20)

        XCTAssertNil(incomplete.pureToneAverage(for: .right))
        XCTAssertEqual(complete.pureToneAverage(for: .right), 15)
    }

    func testChartPointsFilterMissingThresholdsWithoutZeroFilling() {
        let record = HearingTestRecord(right250: nil, right500: 10, right1000: nil, right2000: 20)

        let points = HearingChartData.thresholdPoints(from: record, ear: .right)

        XCTAssertEqual(points.map(\.frequencyHz), [500, 2000])
        XCTAssertEqual(points.map(\.hearingLevelDBHL), [10, 20])
    }

    func testTrendUsesFirstAndLastComparableRealAveragesOnly() {
        let records = [
            HearingTestRecord(testedAt: year(2022), right500: 10, right1000: 15, right2000: 20),
            HearingTestRecord(testedAt: year(2023), right500: 10, right1000: nil, right2000: 20),
            HearingTestRecord(testedAt: year(2024), right500: 20, right1000: 20, right2000: 20)
        ]

        let description = HearingChartData.pureToneAverageTrendDescription(from: records, ear: .right)

        XCTAssertEqual(description, "Right ear pure-tone average changed by +5 dB HL between 2022 and 2024.")
    }

    private func year(_ year: Int) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: year, month: 1, day: 1))!
    }
}

