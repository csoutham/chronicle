import SwiftUI
import UserNotifications
import UIKit

struct SettingsView: View {
    @AppStorage(AppStorageKeys.reminderIntervalMonths) private var reminderIntervalMonths = 24
    @AppStorage(AppStorageKeys.remindDaysBefore) private var remindDaysBefore = 30

    let latestRecord: PrescriptionRecord?

    @State private var notificationStatus: UNAuthorizationStatus?

    var body: some View {
        NavigationStack {
            Form {
                Section("Reminder schedule") {
                    Stepper("Test interval: \(reminderIntervalMonths) months", value: $reminderIntervalMonths, in: 1...48)
                    Stepper("Remind \(remindDaysBefore) days before", value: $remindDaysBefore, in: 1...120)
                }

                Section("Latest record") {
                    if let latestRecord {
                        Text(Formatters.recordDate.string(from: latestRecord.testedAt))
                        if let practice = latestRecord.practice {
                            Text(practice)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("No records yet")
                            .foregroundStyle(.secondary)
                    }
                }

                if notificationStatus == .denied {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notifications are turned off")
                                .font(.headline)
                            Text("Open Settings to re-enable reminder notifications for your next eye test.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Button("Open Settings") {
                                guard let url = URL(string: UIApplication.openSettingsURLString) else {
                                    return
                                }

                                UIApplication.shared.open(url)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Settings")
            .task {
                await refreshNotificationStatus()
            }
        }
    }

    private func refreshNotificationStatus() async {
        notificationStatus = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }
}
