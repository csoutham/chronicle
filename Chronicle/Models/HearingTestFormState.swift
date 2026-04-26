import Foundation

struct HearingThresholdFormValue: Equatable, Identifiable {
    let frequencyHz: Int
    var isIncluded: Bool
    var hearingLevelDBHL: Double

    var id: Int { frequencyHz }
}

struct HearingTestFormState: Equatable {
    var testedAt = Date()
    var provider = ""
    var notes = ""
    var rightThresholds: [HearingThresholdFormValue]
    var leftThresholds: [HearingThresholdFormValue]

    init(record: HearingTestRecord? = nil) {
        rightThresholds = Self.makeThresholds(for: .right, record: record)
        leftThresholds = Self.makeThresholds(for: .left, record: record)

        guard let record else {
            return
        }

        testedAt = record.testedAt
        provider = record.provider ?? ""
        notes = record.notes ?? ""
    }

    var canSave: Bool {
        rightThresholds.contains(where: \.isIncluded) || leftThresholds.contains(where: \.isIncluded)
    }

    func validationMessage() -> String? {
        guard canSave else {
            return "Add at least one hearing threshold before saving."
        }

        return nil
    }

    func makeRecord() -> HearingTestRecord {
        let record = HearingTestRecord()
        apply(to: record)
        return record
    }

    func apply(to record: HearingTestRecord) {
        record.testedAt = testedAt
        record.provider = provider.trimmedOrNil
        record.notes = notes.trimmedOrNil

        for entry in rightThresholds {
            record.setThreshold(entry.isIncluded ? entry.hearingLevelDBHL : nil, for: .right, frequencyHz: entry.frequencyHz)
        }

        for entry in leftThresholds {
            record.setThreshold(entry.isIncluded ? entry.hearingLevelDBHL : nil, for: .left, frequencyHz: entry.frequencyHz)
        }
    }

    private static func makeThresholds(for ear: HearingEarSide, record: HearingTestRecord?) -> [HearingThresholdFormValue] {
        HearingTestRecord.defaultFrequencies.map { frequency in
            let value = record?.threshold(for: ear, frequencyHz: frequency)
            return HearingThresholdFormValue(
                frequencyHz: frequency,
                isIncluded: value != nil,
                hearingLevelDBHL: value ?? 20
            )
        }
    }
}

private extension String {
    var trimmedOrNil: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
