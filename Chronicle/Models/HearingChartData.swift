import Foundation

enum HearingChartData {
    static func thresholdPoints(from record: HearingTestRecord, ear: HearingEarSide) -> [HearingThresholdPoint] {
        record.thresholdPoints(for: ear)
    }

    static func pureToneAverageTrendDescription(
        from records: [HearingTestRecord],
        ear: HearingEarSide,
        calendar: Calendar = .current
    ) -> String? {
        let points = records.compactMap { record -> (date: Date, value: Double)? in
            guard let value = record.pureToneAverage(for: ear) else {
                return nil
            }

            return (record.testedAt, value)
        }

        guard let first = points.first, let last = points.last, points.count >= 2 else {
            return nil
        }

        let change = last.value - first.value
        let startYear = calendar.component(.year, from: first.date)
        let endYear = calendar.component(.year, from: last.date)
        return "\(ear.title) pure-tone average changed by \(formattedDecibels(change, includeSign: true)) between \(startYear) and \(endYear)."
    }

    static func latestSummary(for record: HearingTestRecord) -> String {
        HearingEarSide.allCases.map { ear in
            guard let average = record.pureToneAverage(for: ear) else {
                return "\(ear.shortTitle): not enough data for average"
            }

            return "\(ear.shortTitle): \(formattedDecibels(average, includeSign: false)) average"
        }
        .joined(separator: "\n")
    }

    static func formattedDecibels(_ value: Double, includeSign: Bool) -> String {
        let sign = includeSign && value > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.0f", value)) dB HL"
    }
}

