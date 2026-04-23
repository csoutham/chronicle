import Foundation
import XCTest
@testable import Chronicle

final class ChartMetricTests: XCTestCase {
    func testMetricPointsFilterNilValuesRatherThanZeroFilling() {
        let records = [
            PrescriptionRecord(testedAt: Date(timeIntervalSince1970: 0), reAdd: nil, leAdd: nil),
            PrescriptionRecord(testedAt: Date(timeIntervalSince1970: 10), reAdd: 1.00, leAdd: nil),
            PrescriptionRecord(testedAt: Date(timeIntervalSince1970: 20), reAdd: 1.25, leAdd: 1.25)
        ]

        let rightPoints = ChartMetric.add.points(from: records, eye: .right)
        let leftPoints = ChartMetric.add.points(from: records, eye: .left)

        XCTAssertEqual(rightPoints.map(\.value), [1.00, 1.25])
        XCTAssertEqual(leftPoints.map(\.value), [1.25])
    }

    func testTrendDescriptionUsesFirstAndLastRealValuesOnly() {
        let records = [
            PrescriptionRecord(testedAt: year(2021), reAdd: 0.75),
            PrescriptionRecord(testedAt: year(2022), reAdd: nil),
            PrescriptionRecord(testedAt: year(2024), reAdd: 1.50)
        ]

        let description = ChartMetric.add.trendDescription(for: records, eye: .right)

        XCTAssertEqual(description, "Right eye changed by +0.75 DS between 2021 and 2024.")
    }

    func testTrendDescriptionIsNilWhenFewerThanTwoValuesExist() {
        let records = [
            PrescriptionRecord(testedAt: year(2024), reAdd: 1.50)
        ]

        XCTAssertNil(ChartMetric.add.trendDescription(for: records, eye: .right))
    }

    private func year(_ year: Int) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: year, month: 1, day: 1))!
    }
}
