import Foundation
import SwiftData

enum HearingEarSide: String, CaseIterable, Identifiable {
    case right
    case left

    var id: String { rawValue }

    var title: String {
        switch self {
        case .right:
            "Right ear"
        case .left:
            "Left ear"
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

struct HearingThresholdPoint: Identifiable, Equatable {
    let recordID: UUID
    let testedAt: Date
    let ear: HearingEarSide
    let frequencyHz: Int
    let hearingLevelDBHL: Double

    var id: String {
        "\(recordID.uuidString)-\(ear.rawValue)-\(frequencyHz)"
    }
}

@Model
final class HearingTestRecord: Identifiable {
    static let defaultFrequencies = [250, 500, 1000, 2000, 3000, 4000, 6000, 8000]
    static let pureToneAverageFrequencies = [500, 1000, 2000]

    var id: UUID = UUID()
    var testedAt: Date = Date.now
    var provider: String?
    var notes: String?

    var right250: Double?
    var right500: Double?
    var right1000: Double?
    var right2000: Double?
    var right3000: Double?
    var right4000: Double?
    var right6000: Double?
    var right8000: Double?

    var left250: Double?
    var left500: Double?
    var left1000: Double?
    var left2000: Double?
    var left3000: Double?
    var left4000: Double?
    var left6000: Double?
    var left8000: Double?

    init(
        id: UUID = UUID(),
        testedAt: Date = .now,
        provider: String? = nil,
        notes: String? = nil,
        right250: Double? = nil,
        right500: Double? = nil,
        right1000: Double? = nil,
        right2000: Double? = nil,
        right3000: Double? = nil,
        right4000: Double? = nil,
        right6000: Double? = nil,
        right8000: Double? = nil,
        left250: Double? = nil,
        left500: Double? = nil,
        left1000: Double? = nil,
        left2000: Double? = nil,
        left3000: Double? = nil,
        left4000: Double? = nil,
        left6000: Double? = nil,
        left8000: Double? = nil
    ) {
        self.id = id
        self.testedAt = testedAt
        self.provider = provider
        self.notes = notes
        self.right250 = right250
        self.right500 = right500
        self.right1000 = right1000
        self.right2000 = right2000
        self.right3000 = right3000
        self.right4000 = right4000
        self.right6000 = right6000
        self.right8000 = right8000
        self.left250 = left250
        self.left500 = left500
        self.left1000 = left1000
        self.left2000 = left2000
        self.left3000 = left3000
        self.left4000 = left4000
        self.left6000 = left6000
        self.left8000 = left8000
    }

    func threshold(for ear: HearingEarSide, frequencyHz: Int) -> Double? {
        switch (ear, frequencyHz) {
        case (.right, 250): right250
        case (.right, 500): right500
        case (.right, 1000): right1000
        case (.right, 2000): right2000
        case (.right, 3000): right3000
        case (.right, 4000): right4000
        case (.right, 6000): right6000
        case (.right, 8000): right8000
        case (.left, 250): left250
        case (.left, 500): left500
        case (.left, 1000): left1000
        case (.left, 2000): left2000
        case (.left, 3000): left3000
        case (.left, 4000): left4000
        case (.left, 6000): left6000
        case (.left, 8000): left8000
        default: nil
        }
    }

    func setThreshold(_ value: Double?, for ear: HearingEarSide, frequencyHz: Int) {
        switch (ear, frequencyHz) {
        case (.right, 250): right250 = value
        case (.right, 500): right500 = value
        case (.right, 1000): right1000 = value
        case (.right, 2000): right2000 = value
        case (.right, 3000): right3000 = value
        case (.right, 4000): right4000 = value
        case (.right, 6000): right6000 = value
        case (.right, 8000): right8000 = value
        case (.left, 250): left250 = value
        case (.left, 500): left500 = value
        case (.left, 1000): left1000 = value
        case (.left, 2000): left2000 = value
        case (.left, 3000): left3000 = value
        case (.left, 4000): left4000 = value
        case (.left, 6000): left6000 = value
        case (.left, 8000): left8000 = value
        default: break
        }
    }

    func thresholdPoints(for ear: HearingEarSide) -> [HearingThresholdPoint] {
        Self.defaultFrequencies.compactMap { frequency in
            guard let value = threshold(for: ear, frequencyHz: frequency) else {
                return nil
            }

            return HearingThresholdPoint(
                recordID: id,
                testedAt: testedAt,
                ear: ear,
                frequencyHz: frequency,
                hearingLevelDBHL: value
            )
        }
    }

    func pureToneAverage(for ear: HearingEarSide) -> Double? {
        let values = Self.pureToneAverageFrequencies.compactMap { threshold(for: ear, frequencyHz: $0) }
        guard values.count == Self.pureToneAverageFrequencies.count else {
            return nil
        }

        return values.reduce(0, +) / Double(values.count)
    }

    var hasAnyThreshold: Bool {
        HearingEarSide.allCases.contains { ear in
            !thresholdPoints(for: ear).isEmpty
        }
    }

    func copy() -> HearingTestRecord {
        HearingTestRecord(
            id: id,
            testedAt: testedAt,
            provider: provider,
            notes: notes,
            right250: right250,
            right500: right500,
            right1000: right1000,
            right2000: right2000,
            right3000: right3000,
            right4000: right4000,
            right6000: right6000,
            right8000: right8000,
            left250: left250,
            left500: left500,
            left1000: left1000,
            left2000: left2000,
            left3000: left3000,
            left4000: left4000,
            left6000: left6000,
            left8000: left8000
        )
    }
}

extension HearingTestRecord {
    static let previews: [HearingTestRecord] = [
        HearingTestRecord(
            testedAt: DateComponents.calendar.date(from: DateComponents(year: 2024, month: 4, day: 11))!,
            provider: "Local audiology clinic",
            right250: 10,
            right500: 10,
            right1000: 15,
            right2000: 15,
            right4000: 20,
            left250: 15,
            left500: 15,
            left1000: 20,
            left2000: 20,
            left4000: 25
        ),
        HearingTestRecord(
            testedAt: DateComponents.calendar.date(from: DateComponents(year: 2026, month: 4, day: 15))!,
            provider: "Local audiology clinic",
            right250: 10,
            right500: 15,
            right1000: 15,
            right2000: 20,
            right4000: 25,
            left250: 15,
            left500: 15,
            left1000: 20,
            left2000: 25,
            left4000: 30
        )
    ]
}

private extension DateComponents {
    static let calendar = Calendar(identifier: .gregorian)
}
