import XCTest
@testable import Chronicle

final class HearingTestFormStateTests: XCTestCase {
    func testEmptyFormCannotSave() {
        let formState = HearingTestFormState()

        XCTAssertFalse(formState.canSave)
        XCTAssertEqual(formState.validationMessage(), "Add at least one hearing threshold before saving.")
    }

    func testOneEarEntryMapsToModel() {
        var formState = HearingTestFormState()
        formState.rightThresholds[1].isIncluded = true
        formState.rightThresholds[1].hearingLevelDBHL = 15

        let record = formState.makeRecord()

        XCTAssertEqual(record.right500, 15)
        XCTAssertNil(record.left500)
    }

    func testMissingFrequenciesStayNil() {
        var formState = HearingTestFormState()
        formState.leftThresholds[2].isIncluded = true
        formState.leftThresholds[2].hearingLevelDBHL = 20

        let record = formState.makeRecord()

        XCTAssertNil(record.left500)
        XCTAssertEqual(record.left1000, 20)
        XCTAssertNil(record.left2000)
    }
}

