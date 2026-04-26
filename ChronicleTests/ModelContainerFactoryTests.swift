import SwiftData
import XCTest
@testable import Chronicle

final class ModelContainerFactoryTests: XCTestCase {
    func testProductionConfigurationUsesPrivateCloudKitContainer() {
        let configuration = ModelContainerFactory.productionConfiguration()

        XCTAssertEqual(configuration.cloudKitContainerIdentifier, CloudKitConfiguration.containerIdentifier)
    }

    func testTestingConfigurationIsInMemoryAndDoesNotUseCloudKit() {
        let configuration = ModelContainerFactory.testingConfiguration()

        XCTAssertTrue(configuration.isStoredInMemoryOnly)
        XCTAssertNil(configuration.cloudKitContainerIdentifier)
    }
}
