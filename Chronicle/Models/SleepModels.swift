import Foundation
import SwiftUI

struct SleepNight: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let inBedStart: Date
    let inBedEnd: Date
    let stages: [SleepStage]
    let heartRateSamples: [HeartRateSample]

    init(
        id: UUID = UUID(),
        date: Date,
        inBedStart: Date,
        inBedEnd: Date,
        stages: [SleepStage],
        heartRateSamples: [HeartRateSample] = []
    ) {
        self.id = id
        self.date = date
        self.inBedStart = inBedStart
        self.inBedEnd = inBedEnd
        self.stages = stages
        self.heartRateSamples = heartRateSamples
    }

    var totalInBed: TimeInterval {
        max(0, inBedEnd.timeIntervalSince(inBedStart))
    }

    var totalAsleep: TimeInterval {
        stages.filter(\.isAsleep).reduce(0) { $0 + $1.duration }
    }

    var efficiency: Double {
        totalInBed > 0 ? totalAsleep / totalInBed : 0
    }

    var averageHeartRate: Double? {
        guard !heartRateSamples.isEmpty else {
            return nil
        }

        return heartRateSamples.map(\.bpm).reduce(0, +) / Double(heartRateSamples.count)
    }

    func minutes(for stage: SleepStageType) -> Double {
        stages.filter { $0.stage == stage }.reduce(0) { $0 + $1.duration } / 60
    }

    func replacingHeartRateSamples(_ samples: [HeartRateSample]) -> SleepNight {
        SleepNight(
            id: id,
            date: date,
            inBedStart: inBedStart,
            inBedEnd: inBedEnd,
            stages: stages,
            heartRateSamples: samples
        )
    }
}

enum SleepStageType: CaseIterable, Equatable {
    case core
    case deep
    case rem
    case awake
    case unspecified

    var title: String {
        switch self {
        case .core:
            "Core"
        case .deep:
            "Deep"
        case .rem:
            "REM"
        case .awake:
            "Awake"
        case .unspecified:
            "Asleep"
        }
    }

    var colour: Color {
        switch self {
        case .core:
            AppPalette.sleepCore
        case .deep:
            AppPalette.sleepDeep
        case .rem:
            AppPalette.sleepREM
        case .awake:
            AppPalette.sleepAwake
        case .unspecified:
            AppPalette.sleepUnspecified
        }
    }

    var isAsleep: Bool {
        self != .awake
    }
}

struct SleepStage: Identifiable, Equatable {
    let id: UUID
    let stage: SleepStageType
    let start: Date
    let end: Date

    init(id: UUID = UUID(), stage: SleepStageType, start: Date, end: Date) {
        self.id = id
        self.stage = stage
        self.start = start
        self.end = end
    }

    var duration: TimeInterval {
        max(0, end.timeIntervalSince(start))
    }

    var isAsleep: Bool {
        stage.isAsleep
    }
}

struct HeartRateSample: Equatable {
    let timestamp: Date
    let bpm: Double
}

enum SleepChartMetric: String, CaseIterable, Identifiable {
    case total
    case deep
    case rem
    case core
    case awake

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .total:
            "Total"
        case .deep:
            "Deep"
        case .rem:
            "REM"
        case .core:
            "Core"
        case .awake:
            "Awake"
        }
    }

    var colour: Color {
        switch self {
        case .total:
            AppPalette.sleepCore
        case .deep:
            AppPalette.sleepDeep
        case .rem:
            AppPalette.sleepREM
        case .core:
            AppPalette.sleepCore
        case .awake:
            AppPalette.sleepAwake
        }
    }

    func duration(from night: SleepNight) -> TimeInterval? {
        switch self {
        case .total:
            night.totalAsleep
        case .deep:
            stagedDuration(.deep, from: night)
        case .rem:
            stagedDuration(.rem, from: night)
        case .core:
            stagedDuration(.core, from: night)
        case .awake:
            stagedDuration(.awake, from: night)
        }
    }

    private func stagedDuration(_ stage: SleepStageType, from night: SleepNight) -> TimeInterval? {
        guard night.stages.contains(where: { $0.stage != .unspecified }) else {
            return nil
        }

        return night.minutes(for: stage) * 60
    }
}
enum SleepRange: String, CaseIterable, Identifiable {
    case thirtyDays
    case threeMonths
    case sixMonths
    case twelveMonths

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .thirtyDays:
            "30 days"
        case .threeMonths:
            "3 months"
        case .sixMonths:
            "6 months"
        case .twelveMonths:
            "12 months"
        }
    }

    var component: DateComponents {
        switch self {
        case .thirtyDays:
            DateComponents(day: -30)
        case .threeMonths:
            DateComponents(month: -3)
        case .sixMonths:
            DateComponents(month: -6)
        case .twelveMonths:
            DateComponents(year: -1)
        }
    }
}

struct RawSleepSample: Equatable {
    enum Kind: Equatable {
        case inBed
        case stage(SleepStageType)
    }

    let kind: Kind
    let start: Date
    let end: Date
}

struct SleepHeartRatePoint: Identifiable, Equatable {
    let date: Date
    let value: Double

    var id: Date {
        date
    }
}

struct SleepDurationPoint: Identifiable, Equatable {
    let date: Date
    let seconds: TimeInterval

    var id: Date {
        date
    }

    var hours: Double {
        seconds / 3600
    }
}
