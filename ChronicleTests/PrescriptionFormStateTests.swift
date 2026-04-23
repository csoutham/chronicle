import XCTest
@testable import Chronicle

final class PrescriptionFormStateTests: XCTestCase {
    func testEmptyFormCannotSave() {
        let formState = PrescriptionFormState()

        XCTAssertFalse(formState.canSave)
        XCTAssertEqual(formState.validationMessage(), "Add at least one eye before saving.")
    }

    func testOneEyeEntryMapsToModel() {
        var formState = PrescriptionFormState()
        formState.includesRightEye = true
        formState.rightSph = -1.75

        let record = formState.makeRecord()

        XCTAssertEqual(record.reSph, -1.75)
        XCTAssertNil(record.leSph)
    }

    func testTwoEyeEntryMapsToBothEyes() {
        var formState = PrescriptionFormState()
        formState.includesRightEye = true
        formState.rightSph = -2.00
        formState.includesLeftEye = true
        formState.leftSph = -2.50

        let record = formState.makeRecord()

        XCTAssertEqual(record.reSph, -2.00)
        XCTAssertEqual(record.leSph, -2.50)
    }

    func testSeparateAddTogglesPersistPerEye() {
        var formState = PrescriptionFormState()
        formState.includesRightEye = true
        formState.rightSph = -2.00
        formState.includesRightAdd = true
        formState.rightAdd = 1.25
        formState.includesLeftEye = true
        formState.leftSph = -2.50
        formState.includesLeftAdd = false

        let record = formState.makeRecord()

        XCTAssertEqual(record.reAdd, 1.25)
        XCTAssertNil(record.leAdd)
    }
}
