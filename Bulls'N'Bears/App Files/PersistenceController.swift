//
//  PersistenceController.swift
//  Bulls'N'Bears
//
//  Created by aDav on 21/03/2023.
//

import UIKit
import CoreData

class PersistenceController: NSObject, ObservableObject {
    
    static let shared = PersistenceController()

    // MARK: - Core Data stack

      // Storage for Core Data
    let persistentContainer: NSPersistentContainer
    /// A test configuration for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(isInMemory: true)
        return controller
    }()

    // MARK: - Initializers

    /// An initializer to load Core Data
    /// to use an in-memory store.
    init(isInMemory: Bool = false) {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        persistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
        if isInMemory {
            persistentContainer.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        persistentContainer.loadPersistentStores(completionHandler: { storeDescription, error in
            if let error = error as NSError? {
                fatalError("\(storeDescription),Unresolved error \(error), \(error.userInfo)")
            }
        })
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.name = "viewContext"
        /// - Tag: viewContextMergePolicy
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        persistentContainer.viewContext.shouldDeleteInaccessibleFaults = true
     
//        if isInMemory {
//            // For preview limit the max trips to 2 to avoid loading time.
//            SampleData.generateSampleDataIfNeeded(context: self.persistentContainer.viewContext, maxTrips: 2)
//        }
    }

    // MARK: - Core Data Saving support
    
    func makeChildViewContext() -> NSManagedObjectContext {
        let childViewContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        childViewContext.parent = persistentContainer.viewContext
        return childViewContext
    }

    func makeBackgroundContext() -> NSManagedObjectContext {
        // Create a private queue context.
        /// - Tag: newBackgroundContext
        let taskContext = persistentContainer.newBackgroundContext()
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return taskContext
    }

    func saveContext (context: NSManagedObjectContext, mergeToParent: Bool = true) {
        if context.hasChanges {
            do {
                try context.save()
                if (mergeToParent && context.parent != nil) {
                    try context.parent?.save()
                }
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
