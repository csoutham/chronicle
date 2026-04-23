import Foundation
import UserNotifications

protocol UserNotificationCenterManaging: AnyObject {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func currentAuthorizationStatus() async -> UNAuthorizationStatus
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
}

extension UNUserNotificationCenter: UserNotificationCenterManaging {
    func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationSettings()
        return settings.authorizationStatus
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

@MainActor
final class ReminderScheduler {
    static let reminderIdentifier = "chronicle.optical-test-reminder"

    private let notificationCenter: UserNotificationCenterManaging
    private let calendar: Calendar

    init(notificationCenter: UserNotificationCenterManaging = UNUserNotificationCenter.current(), calendar: Calendar = .current) {
        self.notificationCenter = notificationCenter
        self.calendar = calendar
    }

    func requestAuthorisationIfNeeded() async {
        let status = await notificationCenter.currentAuthorizationStatus()
        guard status == .notDetermined else {
            return
        }

        _ = try? await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func cancelPendingReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [Self.reminderIdentifier])
    }

    func reschedule(lastTestedAt: Date?, intervalMonths: Int, remindDaysBefore: Int) async {
        cancelPendingReminder()

        guard let lastTestedAt else {
            return
        }

        let status = await notificationCenter.currentAuthorizationStatus()
        guard [.authorized, .provisional, .ephemeral].contains(status) else {
            return
        }

        guard let fireDate = Self.reminderDate(
            lastTestedAt: lastTestedAt,
            intervalMonths: intervalMonths,
            remindDaysBefore: remindDaysBefore,
            calendar: calendar
        ) else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Book your next eye test"
        content.body = "Your reminder window has arrived. Chronicle is ready for the next prescription update."
        content.sound = .default

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: Self.reminderIdentifier, content: content, trigger: trigger)

        try? await notificationCenter.add(request)
    }

    static func reminderDate(lastTestedAt: Date, intervalMonths: Int, remindDaysBefore: Int, calendar: Calendar = .current) -> Date? {
        guard let nextTestDate = calendar.date(byAdding: .month, value: intervalMonths, to: lastTestedAt) else {
            return nil
        }

        return calendar.date(byAdding: .day, value: -remindDaysBefore, to: nextTestDate)
    }
}
