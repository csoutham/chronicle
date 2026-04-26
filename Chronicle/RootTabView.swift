import SwiftData
import SwiftUI

struct RootTabView: View {
    @AppStorage(AppStorageKeys.reminderIntervalMonths) private var reminderIntervalMonths = 24
    @AppStorage(AppStorageKeys.remindDaysBefore) private var remindDaysBefore = 30
    @Query(sort: \PrescriptionRecord.testedAt, order: .reverse) private var records: [PrescriptionRecord]

    private var latestRecord: PrescriptionRecord? {
        records.first
    }

    private var reminderSignature: String {
        [
            String(records.count),
            latestRecord?.id.uuidString ?? "none",
            String(latestRecord?.testedAt.timeIntervalSinceReferenceDate ?? 0),
            String(reminderIntervalMonths),
            String(remindDaysBefore)
        ].joined(separator: "|")
    }

    var body: some View {
        TabView {
            OpticalView()
                .tabItem {
                    Label("Optical", systemImage: "eye")
                }

            HearingView()
                .tabItem {
                    Label("Hearing", systemImage: "ear")
                }

            SleepView()
                .tabItem {
                    Label("Sleep", systemImage: "bed.double")
                }

            SettingsView(latestRecord: latestRecord)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(AppPalette.rightEye)
        .task(id: reminderSignature) {
            guard !ModelContainerFactory.shouldUseTestingContainer(
                arguments: ProcessInfo.processInfo.arguments,
                environment: ProcessInfo.processInfo.environment
            ) else {
                return
            }

            let reminderScheduler = ReminderScheduler()
            await reminderScheduler.requestAuthorisationIfNeeded()
            await reminderScheduler.reschedule(
                lastTestedAt: latestRecord?.testedAt,
                intervalMonths: reminderIntervalMonths,
                remindDaysBefore: remindDaysBefore
            )
        }
    }
}
