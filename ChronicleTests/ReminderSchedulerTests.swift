import Foundation
import UserNotifications
import XCTest
@testable import Chronicle

@MainActor
final class ReminderSchedulerTests: XCTestCase {
    func testReminderDateUsesIntervalAndLeadTime() {
        let calendar = Calendar(identifier: .gregorian)
        let sourceDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15))!

        let reminderDate = ReminderScheduler.reminderDate(
            lastTestedAt: sourceDate,
            intervalMonths: 24,
            remindDaysBefore: 30,
            calendar: calendar
        )

        XCTAssertEqual(reminderDate, calendar.date(from: DateComponents(year: 2025, month: 12, day: 16)))
    }

    func testRescheduleAddsRequestWhenAuthorised() async {
        let notificationCenter = FakeNotificationCenter(status: .authorized)
        let scheduler = ReminderScheduler(notificationCenter: notificationCenter, calendar: Calendar(identifier: .gregorian))

        await scheduler.reschedule(
            lastTestedAt: Calendar(identifier: .gregorian).date(from: DateComponents(year: 2024, month: 1, day: 15)),
            intervalMonths: 24,
            remindDaysBefore: 30
        )

        XCTAssertEqual(notificationCenter.removedIdentifiers, [ReminderScheduler.reminderIdentifier])
        XCTAssertEqual(notificationCenter.addedRequests.count, 1)
    }

    func testRescheduleDoesNotAddRequestWhenPermissionIsDenied() async {
        let notificationCenter = FakeNotificationCenter(status: .denied)
        let scheduler = ReminderScheduler(notificationCenter: notificationCenter)

        await scheduler.reschedule(lastTestedAt: Date(), intervalMonths: 24, remindDaysBefore: 30)

        XCTAssertEqual(notificationCenter.addedRequests.count, 0)
        XCTAssertEqual(notificationCenter.removedIdentifiers, [ReminderScheduler.reminderIdentifier])
    }

    func testRescheduleCancelsReminderWhenNoRecordsExist() async {
        let notificationCenter = FakeNotificationCenter(status: .authorized)
        let scheduler = ReminderScheduler(notificationCenter: notificationCenter)

        await scheduler.reschedule(lastTestedAt: nil, intervalMonths: 24, remindDaysBefore: 30)

        XCTAssertEqual(notificationCenter.addedRequests.count, 0)
        XCTAssertEqual(notificationCenter.removedIdentifiers, [ReminderScheduler.reminderIdentifier])
    }

    func testSettingsChangesProduceANewRequest() async {
        let notificationCenter = FakeNotificationCenter(status: .authorized)
        let scheduler = ReminderScheduler(notificationCenter: notificationCenter, calendar: Calendar(identifier: .gregorian))
        let sourceDate = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2024, month: 1, day: 15))!

        await scheduler.reschedule(lastTestedAt: sourceDate, intervalMonths: 24, remindDaysBefore: 30)
        await scheduler.reschedule(lastTestedAt: sourceDate, intervalMonths: 12, remindDaysBefore: 14)

        XCTAssertEqual(notificationCenter.addedRequests.count, 2)
        XCTAssertEqual(notificationCenter.removedIdentifiers, [ReminderScheduler.reminderIdentifier, ReminderScheduler.reminderIdentifier])
    }
}

private final class FakeNotificationCenter: UserNotificationCenterManaging {
    let status: UNAuthorizationStatus
    private(set) var addedRequests: [UNNotificationRequest] = []
    private(set) var removedIdentifiers: [String] = []

    init(status: UNAuthorizationStatus) {
        self.status = status
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        true
    }

    func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        status
    }

    func add(_ request: UNNotificationRequest) async throws {
        addedRequests.append(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedIdentifiers.append(contentsOf: identifiers)
    }
}
