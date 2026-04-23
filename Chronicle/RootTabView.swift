import SwiftData
import SwiftUI

struct RootTabView: View {
    @AppStorage(AppStorageKeys.reminderIntervalMonths) private var reminderIntervalMonths = 24
    @AppStorage(AppStorageKeys.remindDaysBefore) private var remindDaysBefore = 30
    @Query(sort: \PrescriptionRecord.testedAt, order: .reverse) private var records: [PrescriptionRecord]

    private let reminderScheduler = ReminderScheduler()

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
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                }

            ChartsView()
                .tabItem {
                    Label("Charts", systemImage: "chart.xyaxis.line")
                }

            SettingsView(latestRecord: latestRecord)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(AppPalette.rightEye)
        .task(id: reminderSignature) {
            await reminderScheduler.requestAuthorisationIfNeeded()
            await reminderScheduler.reschedule(
                lastTestedAt: latestRecord?.testedAt,
                intervalMonths: reminderIntervalMonths,
                remindDaysBefore: remindDaysBefore
            )
        }
    }
}
