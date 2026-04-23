import Foundation

struct PrescriptionFormState: Equatable {
    var testedAt = Date()
    var practice = ""
    var notes = ""

    var includesRightEye = false
    var rightSph = 0.00
    var includesRightCylinder = false
    var rightCyl = -0.50
    var rightAxisText = "90"
    var includesRightAdd = false
    var rightAdd = 1.00

    var includesLeftEye = false
    var leftSph = 0.00
    var includesLeftCylinder = false
    var leftCyl = -0.75
    var leftAxisText = "85"
    var includesLeftAdd = false
    var leftAdd = 1.00

    init(record: PrescriptionRecord? = nil) {
        guard let record else {
            return
        }

        testedAt = record.testedAt
        practice = record.practice ?? ""
        notes = record.notes ?? ""

        includesRightEye = record.reSph != nil
        rightSph = record.reSph ?? 0.00
        includesRightCylinder = record.reCyl != nil || record.reAxis != nil
        rightCyl = record.reCyl ?? -0.50
        rightAxisText = String(record.reAxis ?? 90)
        includesRightAdd = record.reAdd != nil
        rightAdd = record.reAdd ?? 1.00

        includesLeftEye = record.leSph != nil
        leftSph = record.leSph ?? 0.00
        includesLeftCylinder = record.leCyl != nil || record.leAxis != nil
        leftCyl = record.leCyl ?? -0.75
        leftAxisText = String(record.leAxis ?? 85)
        includesLeftAdd = record.leAdd != nil
        leftAdd = record.leAdd ?? 1.00
    }

    var canSave: Bool {
        includesRightEye || includesLeftEye
    }

    func validationMessage() -> String? {
        guard canSave else {
            return "Add at least one eye before saving."
        }

        if includesRightCylinder, rightAxis == nil {
            return "Right eye axis must be a whole number between 0 and 180."
        }

        if includesLeftCylinder, leftAxis == nil {
            return "Left eye axis must be a whole number between 0 and 180."
        }

        return nil
    }

    var rightAxis: Int? {
        parsedAxis(from: rightAxisText)
    }

    var leftAxis: Int? {
        parsedAxis(from: leftAxisText)
    }

    func makeRecord() -> PrescriptionRecord {
        let record = PrescriptionRecord()
        apply(to: record)
        return record
    }

    func apply(to record: PrescriptionRecord) {
        record.testedAt = testedAt
        record.practice = practice.trimmedOrNil
        record.notes = notes.trimmedOrNil

        record.reSph = includesRightEye ? rightSph : nil
        record.reCyl = includesRightEye && includesRightCylinder ? rightCyl : nil
        record.reAxis = includesRightEye && includesRightCylinder ? rightAxis : nil
        record.reAdd = includesRightEye && includesRightAdd ? rightAdd : nil

        record.leSph = includesLeftEye ? leftSph : nil
        record.leCyl = includesLeftEye && includesLeftCylinder ? leftCyl : nil
        record.leAxis = includesLeftEye && includesLeftCylinder ? leftAxis : nil
        record.leAdd = includesLeftEye && includesLeftAdd ? leftAdd : nil
    }

    private func parsedAxis(from text: String) -> Int? {
        guard let axis = Int(text), (0...180).contains(axis) else {
            return nil
        }

        return axis
    }
}

private extension String {
    var trimmedOrNil: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
