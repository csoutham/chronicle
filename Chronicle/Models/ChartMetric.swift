import Charts
import Foundation

enum EyeSide: String, CaseIterable, Identifiable {
    case right
    case left

    var id: String { rawValue }

    var title: String {
        switch self {
        case .right:
            "Right eye"
        case .left:
            "Left eye"
        }
    }

    var shortTitle: String {
        switch self {
        case .right:
            "Right"
        case .left:
            "Left"
        }
    }
}

struct ChartPoint: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let value: Double
}

enum ChartMetric: String, CaseIterable, Identifiable {
    case sph
    case cyl
    case axis
    case add

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sph:
            "SPH"
        case .cyl:
            "CYL"
        case .axis:
            "Axis"
        case .add:
            "ADD"
        }
    }

    var detailText: String {
        switch self {
        case .sph:
            "Sphere"
        case .cyl:
            "Cylinder"
        case .axis:
            "Axis"
        case .add:
            "Reading addition"
        }
    }

    var unit: String {
        switch self {
        case .axis:
            "°"
        case .sph, .cyl, .add:
            "DS"
        }
    }

    var interpolationMethod: InterpolationMethod {
        switch self {
        case .axis:
            .linear
        case .sph, .cyl, .add:
            .catmullRom
        }
    }

    var yDomain: ClosedRange<Double> {
        switch self {
        case .sph:
            -20...10
        case .cyl:
            -10...0
        case .axis:
            0...180
        case .add:
            0...4
        }
    }

    func value(for record: PrescriptionRecord, eye: EyeSide) -> Double? {
        switch (self, eye) {
        case (.sph, .right):
            record.reSph
        case (.sph, .left):
            record.leSph
        case (.cyl, .right):
            record.reCyl
        case (.cyl, .left):
            record.leCyl
        case (.axis, .right):
            record.reAxis.map(Double.init)
        case (.axis, .left):
            record.leAxis.map(Double.init)
        case (.add, .right):
            record.reAdd
        case (.add, .left):
            record.leAdd
        }
    }

    func points(from records: [PrescriptionRecord], eye: EyeSide) -> [ChartPoint] {
        records.compactMap { record in
            guard let value = value(for: record, eye: eye) else {
                return nil
            }

            return ChartPoint(id: record.id, date: record.testedAt, value: value)
        }
    }

    func trendDescription(for records: [PrescriptionRecord], eye: EyeSide, calendar: Calendar = .current) -> String? {
        let points = points(from: records, eye: eye)
        guard let first = points.first, let last = points.last, points.count >= 2 else {
            return nil
        }

        let startYear = calendar.component(.year, from: first.date)
        let endYear = calendar.component(.year, from: last.date)

        return "\(eye.title) changed by \(formattedValue(last.value - first.value, includeUnit: true, alwaysShowSign: true)) between \(startYear) and \(endYear)."
    }

    func formattedValue(_ value: Double, includeUnit: Bool = false, alwaysShowSign: Bool = false) -> String {
        let body: String

        switch self {
        case .axis:
            body = "\(Int(value.rounded()))"
        case .sph, .cyl, .add:
            let sign = value > 0 || (alwaysShowSign && value == 0) ? "+" : ""
            body = "\(sign)\(String(format: "%.2f", value))"
        }

        if includeUnit {
            return "\(body) \(unit)"
        }

        return body
    }
}
