import Foundation
import SwiftData

enum ModelContainerFactory {
    static let schema = Schema([PrescriptionRecord.self, HearingTestRecord.self])

    static func productionConfiguration() -> ModelConfiguration {
        ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .private(CloudKitConfiguration.containerIdentifier)
        )
    }

    static func testingConfiguration() -> ModelConfiguration {
        ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    }

    @MainActor
    static func makeContainer(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> ModelContainer {
        if shouldUseTestingContainer(arguments: arguments, environment: environment) {
            return PrescriptionRecord.testingContainer()
        }

        do {
            #if DEBUG
            if arguments.contains("-initialize-cloudkit-schema") {
                try CloudKitSchemaInitializer.initializeIfNeeded(configuration: productionConfiguration())
            }
            #endif

            return try ModelContainer(for: schema, configurations: [productionConfiguration()])
        } catch {
            fatalError("Unable to create model container: \(error)")
        }
    }

    static func shouldUseTestingContainer(arguments: [String], environment: [String: String]) -> Bool {
        arguments.contains("-ui-testing")
            || environment["CHRONICLE_USE_IN_MEMORY_STORE"] == "1"
            || environment["CHRONICLE_TEST_COLOUR_SCHEME"] != nil
            || environment.keys.contains { key in
                key.localizedCaseInsensitiveContains("xctest")
                    || key.localizedCaseInsensitiveContains("xcinject")
            }
    }
}
