import SwiftData
import XCTest
@testable import Chronicle

@MainActor
final class SwiftDataIntegrationTests: XCTestCase {
    func testInsertEditDeleteAndOrderingWithInMemoryContainer() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PrescriptionRecord.self, configurations: configuration)
        let context = ModelContext(container)

        let older = PrescriptionRecord(testedAt: .distantPast, reSph: -1.00)
        let newer = PrescriptionRecord(testedAt: .now, reSph: -2.00)

        context.insert(older)
        context.insert(newer)
        try context.save()

        var fetchDescriptor = FetchDescriptor<PrescriptionRecord>(
            sortBy: [SortDescriptor(\.testedAt, order: .reverse)]
        )
        var fetchedRecords = try context.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedRecords.map(\.id), [newer.id, older.id])

        older.notes = "Updated note"
        try context.save()

        fetchDescriptor = FetchDescriptor<PrescriptionRecord>()
        fetchedRecords = try context.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedRecords.first(where: { $0.id == older.id })?.notes, "Updated note")

        context.delete(newer)
        try context.save()

        fetchedRecords = try context.fetch(FetchDescriptor<PrescriptionRecord>())
        XCTAssertEqual(fetchedRecords.count, 1)
        XCTAssertEqual(fetchedRecords.first?.id, older.id)
    }
}
