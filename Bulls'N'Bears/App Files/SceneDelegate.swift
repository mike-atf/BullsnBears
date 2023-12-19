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
        
        /*
         // unused as downloading dividend csv files from Yahoo alos triggers this to create a new share
        var filesImported = [String]()
        let appDocumentPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        
        if let documentFolder = appDocumentPaths.first {
            
            guard documentFolder != "{}" else {
                return
            }
            
            // dont use 'fileURL.startAccessingSecurityScopedResource()' on App sandbox /Documents folder as access is always granted and the access request will alwys return false
            if let lastForegroundDate = UserDefaults.standard.value(forKey: "LastForegroundDate") as? Date {
                if Date().timeIntervalSince(lastForegroundDate) > nonRefreshTimeInterval {
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
                            ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error trying to move file out of the Inbox into the Document folder")
                        }
                    }
                }
            } catch let error {
                ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error checking the Inbox folder ")
            }
            
            if filesImported.count > 0 {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "NewFilesArrived"), object: filesImported, userInfo: nil)
            }
        }
        */
    }
    
    //MARK: - file import
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        
        guard let urlContext = URLContexts.first else {
          return
        }
        
        let fileURL = urlContext.url
        
        do {
            let fileResources = try fileURL.resourceValues(forKeys: [.localizedNameKey,.localizedTypeDescriptionKey])
            let type = fileResources.localizedTypeDescription ?? "nil"
            guard type == "Bulls N Bears Backup" else {
                print("incompatible file import failed for type \(type)")
                return
            }

        } catch {
            print("error trying to get fileResources from imported file")
            return
        }
        
        
        if !urlContext.options.openInPlace {
            //file needs to be copied in order to be opened
            if fileURL.startAccessingSecurityScopedResource() {
                do {
                    
                    guard let localFolderURL = localBackupFolderURL else {
                        return
                    }
                    
                    // add 'imported' as otherwise safety backup will overwrite the imported one
                    let importedFileName = localFolderURL.path() + "/Imported " + fileURL.lastPathComponent
                    let localURL = URL(fileURLWithPath: importedFileName)

                    // move file into local backup folder
                    print(localURL.path())
                    if FileManager.default.fileExists(atPath: localURL.path()){
                        try FileManager.default.removeItem(at: localURL)
                    }
                    try FileManager.default.copyItem(at: fileURL, to: localURL)
                    let _ = ImportManager(fileURL: localURL)
                    fileURL.stopAccessingSecurityScopedResource()

                } catch {
                    print("an error during import process: \(error.localizedDescription)")
                    print("source file url: \(fileURL.path())")
                    fileURL.stopAccessingSecurityScopedResource()
                    return
                }

            }
            else {
                print("can't access file to import")
            }
        } 
        else {
            // file doesn't need to to be copies, ca be opened in place
            let _ = ImportManager(fileURL: fileURL)
        }

    }
    
    /*
    private func buildTickerDictionary() {
        
        if let path = tickerDictionaryPath() { // doesn't exist
            
            guard let content = CSVImporter.openCSVFile(url: nil, fileName:"StockTickerDictionary") else {
                ErrorController.addInternalError(errorLocation: "SceneDelegate.buildTickerDictionary", systemError: nil, errorInfo: "can't find ticker name csv file")
                return
            }
            
            let rows = content.components(separatedBy: NSMutableCharacterSet.newlines)
            
            if rows.count < 1 {
                ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "csvExtraction error - no file content")
                return
            }

            let expectedOrder = ["Ticker","Name","Exchange"]
            var headerError = false
            if let headerArray = rows.first?.components(separatedBy: ",") {
                var count = 0
                headerArray.forEach { (header) in
                    if header != expectedOrder[count] {
                        ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: nil, errorInfo: " trying to read .csv file - header not in required format \(expectedOrder).\nInstead is \(headerArray) " )
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
                ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: error, errorInfo: "Error trying to create Stoxk ticker ditionary at path \(dictPath) " )
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
                ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error checking the Support Directory folder ")
            }
            
            return appSupportDirectoryPath
        }

        return nil
    }
    
    private func removeFile(atPath: String) {
       
        do {
            try FileManager.default.removeItem(atPath: atPath)
        } catch let error {
            ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "SceneDelegate - error trying to remove existing file \(atPath) in the  Document folder to be able to move new file of same name from Inbox folder ")
        }
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).

    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
//        
//        let context = PersistenceController.shared.persistentContainer.viewContext
//        do {
//            try context.save()
//        } catch {
//            print("context saving error when going to background - bakup not undertaken")
//        }
//        
////        let backupController = BackupManager(context: context)
//        Task {
//            await BackupManager.backupData()
//        }
//        
    }


}

