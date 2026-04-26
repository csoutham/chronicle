import Foundation
import SwiftData

@Model
final class PrescriptionRecord: Identifiable {
    var id: UUID = UUID()
    var testedAt: Date = Date.now
    var practice: String?
    var notes: String?

    var reSph: Double?
    var reCyl: Double?
    var reAxis: Int?
    var reAdd: Double?

    var leSph: Double?
    var leCyl: Double?
    var leAxis: Int?
    var leAdd: Double?

    init(
        id: UUID = UUID(),
        testedAt: Date = .now,
        practice: String? = nil,
        notes: String? = nil,
        reSph: Double? = nil,
        reCyl: Double? = nil,
        reAxis: Int? = nil,
        reAdd: Double? = nil,
        leSph: Double? = nil,
        leCyl: Double? = nil,
        leAxis: Int? = nil,
        leAdd: Double? = nil
    ) {
        self.id = id
        self.testedAt = testedAt
        self.practice = practice
        self.notes = notes
        self.reSph = reSph
        self.reCyl = reCyl
        self.reAxis = reAxis
        self.reAdd = reAdd
        self.leSph = leSph
        self.leCyl = leCyl
        self.leAxis = leAxis
        self.leAdd = leAdd
    }
}

extension PrescriptionRecord {
    static let previews: [PrescriptionRecord] = [
        PrescriptionRecord(testedAt: DateComponents.calendar.date(from: DateComponents(year: 2015, month: 5, day: 14))!, practice: "Specsavers, Manchester", reSph: -1.75, reCyl: -0.50, reAxis: 90, leSph: -2.00, leCyl: -0.75, leAxis: 85),
        PrescriptionRecord(testedAt: DateComponents.calendar.date(from: DateComponents(year: 2016, month: 5, day: 20))!, practice: "Specsavers, Manchester", reSph: -2.00, reCyl: -0.50, reAxis: 90, leSph: -2.25, leCyl: -0.75, leAxis: 85),
        PrescriptionRecord(testedAt: DateComponents.calendar.date(from: DateComponents(year: 2017, month: 6, day: 2))!, practice: "Vision Express, Leeds", reSph: -2.00, reCyl: -0.50, reAxis: 92, leSph: -2.25, leCyl: -0.75, leAxis: 87),
        PrescriptionRecord(testedAt: DateComponents.calendar.date(from: DateComponents(year: 2018, month: 6, day: 10))!, practice: "Vision Express, Leeds", reSph: -2.25, reCyl: -0.50, reAxis: 90, leSph: -2.50, leCyl: -0.75, leAxis: 85),
        PrescriptionRecord(testedAt: DateComponents.calendar.date(from: DateComponents(year: 2019, month: 7, day: 1))!, practice: "Vision Express, Leeds", reSph: -2.25, reCyl: -0.75, reAxis: 90, leSph: -2.50, leCyl: -1.00, leAxis: 85),
        PrescriptionRecord(testedAt: DateComponents.calendar.date(from: DateComponents(year: 2020, month: 7, day: 15))!, practice: "Independent, York", reSph: -2.25, reCyl: -0.75, reAxis: 92, leSph: -2.75, leCyl: -1.00, leAxis: 85),
        PrescriptionRecord(testedAt: DateComponents.calendar.date(from: DateComponents(year: 2021, month: 8, day: 3))!, practice: "Independent, York", reSph: -2.50, reCyl: -0.75, reAxis: 90, reAdd: 0.75, leSph: -2.75, leCyl: -1.00, leAxis: 87, leAdd: 0.75),
        PrescriptionRecord(testedAt: DateComponents.calendar.date(from: DateComponents(year: 2022, month: 8, day: 9))!, practice: "Independent, York", reSph: -2.50, reCyl: -0.75, reAxis: 90, reAdd: 1.00, leSph: -3.00, leCyl: -1.00, leAxis: 85, leAdd: 1.00),
        PrescriptionRecord(testedAt: DateComponents.calendar.date(from: DateComponents(year: 2023, month: 9, day: 8))!, practice: "Independent, York", reSph: -2.50, reCyl: -0.75, reAxis: 90, reAdd: 1.25, leSph: -3.00, leCyl: -1.25, leAxis: 85, leAdd: 1.25),
        PrescriptionRecord(testedAt: DateComponents.calendar.date(from: DateComponents(year: 2024, month: 9, day: 18))!, practice: "Independent, York", reSph: -2.50, reCyl: -0.75, reAxis: 92, reAdd: 1.50, leSph: -3.00, leCyl: -1.25, leAxis: 87, leAdd: 1.50)
    ]

    @MainActor
    static func testingContainer(seedPreviews: Bool = false) -> ModelContainer {
        do {
            let configuration = ModelContainerFactory.testingConfiguration()
            let container = try ModelContainer(for: ModelContainerFactory.schema, configurations: [configuration])

            if seedPreviews {
                previews.forEach { preview in
                    container.mainContext.insert(preview.copy())
                }
                try container.mainContext.save()
            }

            return container
        } catch {
            fatalError("Unable to create preview container: \(error)")
        }
    }

    @MainActor
    static let previewContainer: ModelContainer = testingContainer(seedPreviews: true)

    func copy() -> PrescriptionRecord {
        PrescriptionRecord(
            id: id,
            testedAt: testedAt,
            practice: practice,
            notes: notes,
            reSph: reSph,
            reCyl: reCyl,
            reAxis: reAxis,
            reAdd: reAdd,
            leSph: leSph,
            leCyl: leCyl,
            leAxis: leAxis,
            leAdd: leAdd
        )
    }
}

private extension DateComponents {
    static let calendar = Calendar(identifier: .gregorian)
}
