import CloudKit
import Foundation

enum SyncStatus: Equatable {
    case available
    case notSignedIn
    case restricted
    case couldNotDetermine
    case temporarilyUnavailable

    var displayText: String {
        switch self {
        case .available:
            "Available"
        case .notSignedIn:
            "Not signed in"
        case .restricted:
            "Restricted"
        case .couldNotDetermine:
            "Could not determine status"
        case .temporarilyUnavailable:
            "Temporarily unavailable"
        }
    }
}

protocol CloudKitAccountStatusProviding {
    func accountStatus() async throws -> CKAccountStatus
}

extension CKContainer: CloudKitAccountStatusProviding {
    func accountStatus() async throws -> CKAccountStatus {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CKAccountStatus, Error>) in
            accountStatus { status, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: status)
                }
            }
        }
    }
}

struct SyncStatusProvider {
    private let accountStatusProvider: CloudKitAccountStatusProviding

    init(accountStatusProvider: CloudKitAccountStatusProviding = CKContainer(identifier: CloudKitConfiguration.containerIdentifier)) {
        self.accountStatusProvider = accountStatusProvider
    }

    func currentStatus() async -> SyncStatus {
        do {
            return try await map(accountStatusProvider.accountStatus())
        } catch {
            return .temporarilyUnavailable
        }
    }

    private func map(_ accountStatus: CKAccountStatus) -> SyncStatus {
        switch accountStatus {
        case .available:
            .available
        case .noAccount:
            .notSignedIn
        case .restricted:
            .restricted
        case .couldNotDetermine:
            .couldNotDetermine
        case .temporarilyUnavailable:
            .temporarilyUnavailable
        @unknown default:
            .couldNotDetermine
        }
    }
}
