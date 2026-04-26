import Foundation

enum SleepNightBuilder {
    private static let nightGap: TimeInterval = 4 * 60 * 60

    static func makeNights(from samples: [RawSleepSample]) -> [SleepNight] {
        groupIntoNights(samples).compactMap(makeNight)
    }

    static func groupIntoNights(_ samples: [RawSleepSample]) -> [[RawSleepSample]] {
        let sorted = samples.sorted { $0.start < $1.start }
        var nights: [[RawSleepSample]] = []
        var current: [RawSleepSample] = []

        for sample in sorted {
            if let last = current.last, sample.start.timeIntervalSince(last.end) > nightGap {
                if !current.isEmpty {
                    nights.append(current)
                }
                current = [sample]
            } else {
                current.append(sample)
            }
        }

        if !current.isEmpty {
            nights.append(current)
        }

        return nights
    }

    private static func makeNight(from samples: [RawSleepSample]) -> SleepNight? {
        let inBedSamples = samples.filter { sample in
            if case .inBed = sample.kind {
                return true
            }
            return false
        }
        let stagedSamples = samples.compactMap(makeStage)
        let watchStages = stagedSamples.filter { $0.stage != .unspecified }
        let selectedStages = watchStages.isEmpty ? stagedSamples : watchStages

        guard !selectedStages.isEmpty else {
            return nil
        }

        let fallbackStart = selectedStages.map(\.start).min()!
        let fallbackEnd = selectedStages.map(\.end).max()!
        let inBedStart = inBedSamples.map(\.start).min() ?? fallbackStart
        let inBedEnd = inBedSamples.map(\.end).max() ?? fallbackEnd

        return SleepNight(
            date: inBedEnd,
            inBedStart: inBedStart,
            inBedEnd: inBedEnd,
            stages: selectedStages.sorted { $0.start < $1.start }
        )
    }

    private static func makeStage(from sample: RawSleepSample) -> SleepStage? {
        guard case let .stage(stage) = sample.kind else {
            return nil
        }

        return SleepStage(stage: stage, start: sample.start, end: sample.end)
    }
}

enum SleepChartDataBuilder {
    static func durationPoints(for metric: SleepChartMetric, from nights: [SleepNight]) -> [SleepDurationPoint] {
        nights
            .compactMap { night -> SleepDurationPoint? in
                guard let duration = metric.duration(from: night) else {
                    return nil
                }

                return SleepDurationPoint(date: night.date, seconds: duration)
            }
            .sorted { $0.date < $1.date }
    }

    static func durationTrendDescription(for metric: SleepChartMetric, from nights: [SleepNight]) -> String? {
        let points = durationPoints(for: metric, from: nights)
        guard let first = points.first, let last = points.last, points.count >= 2 else {
            return nil
        }

        let change = last.seconds - first.seconds
        let formattedChange = signedDuration(change)
        return "\(metric.title) sleep changed by \(formattedChange) over this range"
    }

    static func durationAverageDescription(for metric: SleepChartMetric, from nights: [SleepNight]) -> String? {
        let points = durationPoints(for: metric, from: nights)
        guard !points.isEmpty else {
            return nil
        }

        let average = points.map(\.seconds).reduce(0, +) / Double(points.count)
        let formattedAverage = Formatters.duration.string(from: average) ?? "\(Int(average / 60))m"
        return "Average \(metric.title.lowercased()) sleep \(formattedAverage) over \(points.count) nights"
    }

    static func heartRatePoints(from nights: [SleepNight]) -> [SleepHeartRatePoint] {
        nights
            .compactMap { night -> SleepHeartRatePoint? in
                guard let averageHeartRate = night.averageHeartRate else {
                    return nil
                }

                return SleepHeartRatePoint(date: night.date, value: averageHeartRate)
            }
            .sorted { $0.date < $1.date }
    }

    static func heartRateTrendDescription(from nights: [SleepNight]) -> String? {
        let points = heartRatePoints(from: nights)
        guard let first = points.first, let last = points.last, points.count >= 2 else {
            return nil
        }

        let change = last.value - first.value
        return "Overnight heart rate changed by \(Formatters.signedDecimal.string(from: NSNumber(value: change)) ?? "\(change)") bpm over this range"
    }

    static func durationInsight(from nights: [SleepNight]) -> String? {
        guard !nights.isEmpty else {
            return nil
        }

        let average = nights.map(\.totalAsleep).reduce(0, +) / Double(nights.count)
        let formattedAverage = Formatters.duration.string(from: average) ?? "\(Int(average / 60))m"
        return "Average \(formattedAverage) over \(nights.count) nights"
    }

    static func stagesInsight(from nights: [SleepNight]) -> String? {
        let asleep = nights.map(\.totalAsleep).reduce(0, +)
        guard asleep > 0 else {
            return nil
        }

        let deep = nights.map { $0.minutes(for: .deep) * 60 }.reduce(0, +)
        let percentage = deep / asleep * 100
        return "Deep sleep averaged \(Formatters.percent.string(from: NSNumber(value: percentage / 100)) ?? "\(percentage)%") of sleep time"
    }

    static func efficiencyInsight(from nights: [SleepNight]) -> String? {
        guard !nights.isEmpty else {
            return nil
        }

        let efficientNights = nights.filter { $0.efficiency >= 0.85 }.count
        return "Above 85% efficiency on \(efficientNights) of \(nights.count) nights"
    }

    private static func signedDuration(_ seconds: TimeInterval) -> String {
        let roundedMinutes = Int((abs(seconds) / 60).rounded())
        if roundedMinutes == 0 {
            return "0m"
        }

        let sign = seconds > 0 ? "+" : "-"
        let hours = roundedMinutes / 60
        let minutes = roundedMinutes % 60

        if hours > 0, minutes > 0 {
            return "\(sign)\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(sign)\(hours)h"
        } else {
            return "\(sign)\(minutes)m"
        }
    }
}
