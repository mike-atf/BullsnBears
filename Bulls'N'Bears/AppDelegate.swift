//
//  AppDelegate.swift
//  TrendMyStocks
//
//  Created by aDav on 01/12/2020.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        setUserDefaults()
        print("app folder path is \(NSHomeDirectory())")
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func setUserDefaults() {
        if UserDefaults.standard.value(forKey: "10YUSTreasuryBondRate") as? Double == nil {
            UserDefaults.standard.set(0.0082, forKey: "10YUSTreasuryBondRate")
        }
        if UserDefaults.standard.value(forKey: "PerpetualGrowthRate") as? Double == nil {
            UserDefaults.standard.set(0.022, forKey: "PerpetualGrowthRate")
        }
        if UserDefaults.standard.value(forKey: "LongTermMarketReturn") as? Double == nil {
            UserDefaults.standard.set(0.1, forKey: "LongTermMarketReturn")
        }
        if UserDefaults.standard.value(forKey: "LongTermCoporateInterestRate") as? Double == nil {
            UserDefaults.standard.set(0.021, forKey: "LongTermCoporateInterestRate")
        }
        if UserDefaults.standard.value(forKey: userDefaultTerms.emaPeriodAnnualData) as? Int == nil {
            UserDefaults.standard.set(7, forKey: userDefaultTerms.emaPeriodAnnualData)
        }
        if (UserDefaults.standard.value(forKey: userDefaultTerms.sortParameter) as? String) == nil {
            UserDefaults.standard.set("userEvaluationScore", forKey: userDefaultTerms.sortParameter)
        }
        if UserDefaults.standard.value(forKey: userDefaultTerms.sortParameter) as? String == nil {
            UserDefaults.standard.set("userEvaluationScore", forKey: userDefaultTerms.sortParameter)
        }

    }
        
    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentCloudKitContainer = {

        let container = NSPersistentCloudKitContainer(name: "TrendMyStocks")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    // MARK: - Core Data Saving support

    // using this elsewhere 
    func saveContext (context: NSManagedObjectContext?) {
//        let context = persistentContainer.viewContext
        
        guard context != nil else {
            return
        }
        if context!.hasChanges {
            do {
                try context!.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    
    
    func application(_ app: UIApplication, open inputURL: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Ensure the URL is a file URL
        guard inputURL.isFileURL else { return false }
                
        // Reveal / import the document at the URL
        guard let masterSplitView = window?.rootViewController as? MasterSplitView else { return false }
        
        masterSplitView.openRemoteDocument(inputURL, importIfNeeded: true)

        return true
    }


}

