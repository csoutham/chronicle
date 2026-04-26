#if DEBUG
import CoreData
import SwiftData

enum CloudKitSchemaInitializer {
    static func initializeIfNeeded(configuration: ModelConfiguration) throws {
        try autoreleasepool {
            let storeDescription = NSPersistentStoreDescription(url: configuration.url)
            storeDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: CloudKitConfiguration.containerIdentifier
            )
            storeDescription.shouldAddStoreAsynchronously = false

            guard let managedObjectModel = NSManagedObjectModel.makeManagedObjectModel(for: [PrescriptionRecord.self]) else {
                return
            }

            let persistentContainer = NSPersistentCloudKitContainer(
                name: "Chronicle",
                managedObjectModel: managedObjectModel
            )
            persistentContainer.persistentStoreDescriptions = [storeDescription]

            var loadError: Error?
            persistentContainer.loadPersistentStores { _, error in
                loadError = error
            }

            if let loadError {
                throw loadError
            }

            try persistentContainer.initializeCloudKitSchema()

            if let store = persistentContainer.persistentStoreCoordinator.persistentStores.first {
                try persistentContainer.persistentStoreCoordinator.remove(store)
            }
        }
    }
}
#endif
