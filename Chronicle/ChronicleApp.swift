import SwiftData
import SwiftUI

@main
struct ChronicleApp: App {
    private let sharedModelContainer = ModelContainerFactory.makeContainer()

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
