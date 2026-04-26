import CloudKit
import XCTest
@testable import Chronicle

final class SyncStatusProviderTests: XCTestCase {
    func testAvailableAccountMapsToAvailableSyncStatus() async {
        let provider = SyncStatusProvider(accountStatusProvider: FakeCloudKitAccountStatusProvider(status: .available))

        let status = await provider.currentStatus()

        XCTAssertEqual(status, .available)
    }

    func testNoAccountMapsToNotSignedIn() async {
        let provider = SyncStatusProvider(accountStatusProvider: FakeCloudKitAccountStatusProvider(status: .noAccount))

        let status = await provider.currentStatus()

        XCTAssertEqual(status, .notSignedIn)
    }

    func testRestrictedAccountMapsToRestricted() async {
        let provider = SyncStatusProvider(accountStatusProvider: FakeCloudKitAccountStatusProvider(status: .restricted))

        let status = await provider.currentStatus()

        XCTAssertEqual(status, .restricted)
    }

    func testCouldNotDetermineMapsToCouldNotDetermine() async {
        let provider = SyncStatusProvider(accountStatusProvider: FakeCloudKitAccountStatusProvider(status: .couldNotDetermine))

        let status = await provider.currentStatus()

        XCTAssertEqual(status, .couldNotDetermine)
    }

    func testAccountStatusErrorMapsToTemporarilyUnavailable() async {
        let provider = SyncStatusProvider(accountStatusProvider: FakeCloudKitAccountStatusProvider(error: TestError.failure))

        let status = await provider.currentStatus()

        XCTAssertEqual(status, .temporarilyUnavailable)
    }
}

private struct FakeCloudKitAccountStatusProvider: CloudKitAccountStatusProviding {
    let status: CKAccountStatus?
    let error: Error?

    init(status: CKAccountStatus) {
        self.status = status
        self.error = nil
    }

    init(error: Error) {
        self.status = nil
        self.error = error
    }

    func accountStatus() async throws -> CKAccountStatus {
        if let error {
            throw error
        }

        return status ?? .couldNotDetermine
    }
}

private enum TestError: Error {
    case failure
}
