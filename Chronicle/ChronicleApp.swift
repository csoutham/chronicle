import SwiftData
import SwiftUI

@main
struct ChronicleApp: App {
    private let sharedModelContainer: ModelContainer = {
        if ProcessInfo.processInfo.arguments.contains("-ui-testing") {
            return PrescriptionRecord.previewContainer
        }

        do {
            return try ModelContainer(for: PrescriptionRecord.self)
        } catch {
            fatalError("Unable to create model container: \(error)")
        }
    }()

    private var testColourScheme: ColorScheme? {
        switch ProcessInfo.processInfo.environment["CHRONICLE_TEST_COLOUR_SCHEME"] {
        case "light":
            .light
        case "dark":
            .dark
        default:
            nil
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(testColourScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}
