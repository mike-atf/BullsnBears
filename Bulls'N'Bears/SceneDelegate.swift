//
//  SceneDelegate.swift
//  TrendMyStocks
//
//  Created by aDav on 01/12/2020.
//

import UIKit
import CoreData
import UserNotifications

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    /// check if any new .csv documents have been placed into the Documents/Inbox folder
    /// if so, try to move to Document folder
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        
//        buildTickerDictionary()
        
        var filesImported = [String]()
        let appDocumentPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        
        if let documentFolder = appDocumentPaths.first {
            
            guard documentFolder != "{}" else {
                return
            }
            
            // dont use 'fileURL.startAccessingSecurityScopedResource()' on App sandbox /Documents folder as access is always granted and the access request will alwys return false
            if let lastForegroundDate = UserDefaults.standard.value(forKey: "LastForegroundDate") as? Date {
                if Date().timeIntervalSince(lastForegroundDate) > 10 {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "ActivatedFromBackground"), object:   nil, userInfo: nil) // send to
                }
            }
            
            UserDefaults.standard.setValue(Date(), forKey: "LastForegroundDate")
            
            let inboxFolder = documentFolder + "/Inbox"
            
            var pointer: ObjCBool = true
            guard FileManager.default.fileExists(atPath: inboxFolder, isDirectory: &pointer) else {
                return
            }
                        
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: inboxFolder), includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                
                // dont use 'fileURL.startAccessingSecurityScopedResource()' on App sandbox /Documents folder as access is always granted and the access request will alwys return false

                for url in fileURLs {
                    if url.lastPathComponent.contains(".csv") {
                        do {
                            let targetPath = documentFolder + "/" + url.lastPathComponent
                            if FileManager.default.fileExists(atPath: targetPath) {
                                removeFile(atPath: targetPath)
                            }
                            try FileManager.default.moveItem(at: url, to: URL(fileURLWithPath: targetPath))
                            filesImported.append(targetPath)
                        }
                        catch let error {
                            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error trying to move file out of the Inbox into the Document folder")
                        }
                    }
                }
            } catch let error {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error checking the Inbox folder ")
            }
            
            if filesImported.count > 0 {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "NewFilesArrived"), object: filesImported, userInfo: nil)
            }
        }
    }
    
    /*
    private func buildTickerDictionary() {
        
        if let path = tickerDictionaryPath() { // doesn't exist
            
            guard let content = CSVImporter.openCSVFile(url: nil, fileName:"StockTickerDictionary") else {
                ErrorController.addErrorLog(errorLocation: "SceneDelegate.buildTickerDictionary", systemError: nil, errorInfo: "can't find ticker name csv file")
                return
            }
            
            let rows = content.components(separatedBy: NSMutableCharacterSet.newlines)
            
            if rows.count < 1 {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "csvExtraction error - no file content")
                return
            }

            let expectedOrder = ["Ticker","Name","Exchange"]
            var headerError = false
            if let headerArray = rows.first?.components(separatedBy: ",") {
                var count = 0
                headerArray.forEach { (header) in
                    if header != expectedOrder[count] {
                        ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: " trying to read .csv file - header not in required format \(expectedOrder).\nInstead is \(headerArray) " )
                        headerError = true
                    }
                    count += 1
                }
            }
            
            if headerError { return }

            stockTickerDictionary = [String:String]()
            let dictPath = path + "/StockTickerDictionary.csv"
            var count = 2 // for reasons beyond me the .csv file has every other line empty, starting with 1,3...
            while count < rows.count {
                let array = rows[count].components(separatedBy: ",")
                stockTickerDictionary![array[0]] = array[1]
                count += 2
            }
            
            do {
                let fileData = try NSKeyedArchiver.archivedData(withRootObject: stockTickerDictionary!, requiringSecureCoding: true)
                try fileData.write(to: URL(fileURLWithPath: dictPath))
            } catch let error {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "Error trying to create Stoxk ticker ditionary at path \(dictPath) " )
            }
            
        }
    }
    */
    
    private func tickerDictionaryPath() -> String? {

        if let appSupportDirectoryPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first {
        
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: appSupportDirectoryPath), includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                
                // dont use 'fileURL.startAccessingSecurityScopedResource()' on App sandbox /Documents folder as access is always granted and the access request will alwys return false

                for url in fileURLs {
                    if url.path.contains("StockTickerDictionary") {
                        if let data = FileManager.default.contents(atPath: url.path) {
                            stockTickerDictionary = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String: String]
                            return nil
                        }
                    }
                }
            } catch let error {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error checking the Support Directory folder ")
            }
            
            return appSupportDirectoryPath
        }

        return nil
    }
    
    private func removeFile(atPath: String) {
       
        do {
            try FileManager.default.removeItem(atPath: atPath)
        } catch let error {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error trying to remove existing file in the Document folder to be able to move new file of same name from Inbox folder ")
        }
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        
        // updating ratingScore for fast display on next launch
        let request = NSFetchRequest<Share>(entityName: "Share")
        request.sortDescriptors = [NSSortDescriptor(key: "symbol", ascending: true)]
                
        do {
//            let shares = try (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.fetch(request)
            let shares = try request.execute()
            for share in shares {
            
                let valueRatingData = share.wbValuation?.valuesSummaryScores()
                let userRatingData = share.wbValuation?.userEvaluationScore()
                
                if let score = valueRatingData?.ratingScore() {
                    share.valueScore = score
                }
                if let score = userRatingData?.ratingScore() {
                    share.userEvaluationScore = score
                }
            }
        } catch let error as NSError {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "can't fetch files")
        }

    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext(context: (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext)
    }


}

