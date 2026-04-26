import XCTest

@testable import Chronicle

final class SleepNightBuilderTests: XCTestCase {
    func testInBedSamplesDefineWindowAndAreExcludedFromStageTotals() {
        let samples = [
            RawSleepSample(kind: .inBed, start: date(hour: 22), end: date(hour: 7, day: 2)),
            RawSleepSample(kind: .stage(.core), start: date(hour: 23), end: date(hour: 1, day: 2)),
            RawSleepSample(kind: .stage(.deep), start: date(hour: 1, day: 2), end: date(hour: 3, day: 2)),
            RawSleepSample(kind: .stage(.awake), start: date(hour: 3, day: 2), end: date(hour: 3, minute: 30, day: 2))
        ]

        let night = SleepNightBuilder.makeNights(from: samples).first

        XCTAssertEqual(night?.inBedStart, date(hour: 22))
        XCTAssertEqual(night?.inBedEnd, date(hour: 7, day: 2))
        XCTAssertEqual(night?.totalInBed, 9 * 60 * 60)
        XCTAssertEqual(night?.totalAsleep, 4 * 60 * 60)
    }

    func testUnspecifiedSleepIsUsedOnlyWhenWatchStagesAreAbsent() {
        let samples = [
            RawSleepSample(kind: .stage(.unspecified), start: date(hour: 22), end: date(hour: 7, day: 2)),
            RawSleepSample(kind: .stage(.core), start: date(hour: 23), end: date(hour: 1, day: 2))
        ]

        let night = SleepNightBuilder.makeNights(from: samples).first

        XCTAssertEqual(night?.stages.count, 1)
        XCTAssertEqual(night?.stages.first?.stage, .core)
    }

    func testStageBoundsAreUsedWhenInBedWindowIsMissing() {
        let samples = [
            RawSleepSample(kind: .stage(.core), start: date(hour: 23), end: date(hour: 1, day: 2)),
            RawSleepSample(kind: .stage(.rem), start: date(hour: 1, day: 2), end: date(hour: 2, day: 2))
        ]

        let night = SleepNightBuilder.makeNights(from: samples).first

        XCTAssertEqual(night?.inBedStart, date(hour: 23))
        XCTAssertEqual(night?.inBedEnd, date(hour: 2, day: 2))
    }

    func testHeartRatePointsFilterMissingAveragesRatherThanZeroFilling() {
        let nights = [
            SleepNight(date: date(day: 1), inBedStart: date(hour: 22), inBedEnd: date(hour: 6, day: 2), stages: [stage()], heartRateSamples: []),
            SleepNight(date: date(day: 2), inBedStart: date(hour: 22, day: 2), inBedEnd: date(hour: 6, day: 3), stages: [stage()], heartRateSamples: [HeartRateSample(timestamp: date(day: 2), bpm: 60)]),
            SleepNight(date: date(day: 3), inBedStart: date(hour: 22, day: 3), inBedEnd: date(hour: 6, day: 4), stages: [stage()], heartRateSamples: [HeartRateSample(timestamp: date(day: 3), bpm: 57)])
        ]

        let points = SleepChartDataBuilder.heartRatePoints(from: nights)

        XCTAssertEqual(points.map(\.value), [60, 57])
    }

    func testHeartRateTrendUsesFirstAndLastRealValuesOnly() {
        let nights = [
            SleepNight(date: date(day: 1), inBedStart: date(hour: 22), inBedEnd: date(hour: 6, day: 2), stages: [stage()], heartRateSamples: []),
            SleepNight(date: date(day: 2), inBedStart: date(hour: 22, day: 2), inBedEnd: date(hour: 6, day: 3), stages: [stage()], heartRateSamples: [HeartRateSample(timestamp: date(day: 2), bpm: 60)]),
            SleepNight(date: date(day: 3), inBedStart: date(hour: 22, day: 3), inBedEnd: date(hour: 6, day: 4), stages: [stage()], heartRateSamples: []),
            SleepNight(date: date(day: 4), inBedStart: date(hour: 22, day: 4), inBedEnd: date(hour: 6, day: 5), stages: [stage()], heartRateSamples: [HeartRateSample(timestamp: date(day: 4), bpm: 57)])
        ]

        XCTAssertEqual(
            SleepChartDataBuilder.heartRateTrendDescription(from: nights),
            "Overnight heart rate changed by -3 bpm over this range"
        )
    }

    func testDurationPointsTrackSelectedSleepMetricOverTime() {
        let nights = [
            SleepNight(
                date: date(day: 1),
                inBedStart: date(hour: 22),
                inBedEnd: date(hour: 6, day: 2),
                stages: [
                    SleepStage(stage: .deep, start: date(hour: 23), end: date(hour: 0, day: 2)),
                    SleepStage(stage: .core, start: date(hour: 0, day: 2), end: date(hour: 4, day: 2))
                ]
            ),
            SleepNight(
                date: date(day: 2),
                inBedStart: date(hour: 22, day: 2),
                inBedEnd: date(hour: 6, day: 3),
                stages: [
                    SleepStage(stage: .deep, start: date(hour: 23, day: 2), end: date(hour: 1, day: 3)),
                    SleepStage(stage: .core, start: date(hour: 1, day: 3), end: date(hour: 5, day: 3))
                ]
            )
        ]

        let deepPoints = SleepChartDataBuilder.durationPoints(for: .deep, from: nights)
        let totalPoints = SleepChartDataBuilder.durationPoints(for: .total, from: nights)

        XCTAssertEqual(deepPoints.map(\.hours), [1, 2])
        XCTAssertEqual(totalPoints.map(\.hours), [5, 6])
    }

    func testStageDurationPointsSkipUnspecifiedSleepRatherThanInventingStageValues() {
        let nights = [
            SleepNight(
                date: date(day: 1),
                inBedStart: date(hour: 22),
                inBedEnd: date(hour: 6, day: 2),
                stages: [SleepStage(stage: .unspecified, start: date(hour: 22), end: date(hour: 6, day: 2))]
            ),
            SleepNight(
                date: date(day: 2),
                inBedStart: date(hour: 22, day: 2),
                inBedEnd: date(hour: 6, day: 3),
                stages: [SleepStage(stage: .rem, start: date(hour: 1, day: 3), end: date(hour: 2, day: 3))]
            )
        ]

        let points = SleepChartDataBuilder.durationPoints(for: .rem, from: nights)

        XCTAssertEqual(points.count, 1)
        XCTAssertEqual(points.first?.hours, 1)
    }

    func testDurationTrendUsesFirstAndLastRealStageValuesOnly() {
        let nights = [
            SleepNight(
                date: date(day: 1),
                inBedStart: date(hour: 22),
                inBedEnd: date(hour: 6, day: 2),
                stages: [SleepStage(stage: .unspecified, start: date(hour: 22), end: date(hour: 6, day: 2))]
            ),
            SleepNight(
                date: date(day: 2),
                inBedStart: date(hour: 22, day: 2),
                inBedEnd: date(hour: 6, day: 3),
                stages: [SleepStage(stage: .deep, start: date(hour: 23, day: 2), end: date(hour: 0, day: 3))]
            ),
            SleepNight(
                date: date(day: 3),
                inBedStart: date(hour: 22, day: 3),
                inBedEnd: date(hour: 6, day: 4),
                stages: [SleepStage(stage: .deep, start: date(hour: 23, day: 3), end: date(hour: 1, day: 4))]
            )
        ]

        XCTAssertEqual(
            SleepChartDataBuilder.durationTrendDescription(for: .deep, from: nights),
            "Deep sleep changed by +1h over this range"
        )
    }

    private func stage() -> SleepStage {
        SleepStage(stage: .core, start: date(hour: 23), end: date(hour: 1, day: 2))
    }

    private func date(hour: Int = 12, minute: Int = 0, day: Int = 1) -> Date {
        DateComponents(
            calendar: Calendar(identifier: .gregorian),
            year: 2026,
            month: 1,
            day: day,
            hour: hour,
            minute: minute
        ).date!
    }
}
