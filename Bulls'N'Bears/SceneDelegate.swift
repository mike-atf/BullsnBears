//
//  SceneDelegate.swift
//  TrendMyStocks
//
//  Created by aDav on 01/12/2020.
//

import UIKit
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
        
        var filesImported = [String]()
        let appDocumentPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        
        if let documentFolder = appDocumentPaths.first {
            
            guard URL(fileURLWithPath: documentFolder).startAccessingSecurityScopedResource() else {
                ErrorController.addErrorLog(errorLocation: "SceneDelagate.sceneDidBecomeActive", systemError: nil, errorInfo: "Accessing App Document Folder was not possible: lacking access rights")
                return
            }


            let inboxFolder = documentFolder + "/Inbox"
            
            if !FileManager.default.fileExists(atPath: inboxFolder) {
                do {
                    try FileManager.default.createDirectory(atPath: inboxFolder, withIntermediateDirectories: true, attributes: nil)
                } catch let error {
                    ErrorController.addErrorLog(errorLocation: "SceneDelagate.sceneDidBecomeActive", systemError: error, errorInfo: "Error trying to create new /Inbox folder")
                }
            }

            
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: inboxFolder), includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                
                guard URL(fileURLWithPath: inboxFolder).startAccessingSecurityScopedResource() else {
                    ErrorController.addErrorLog(errorLocation: "SceneDelagate.sceneDidBecomeActive", systemError: nil, errorInfo: "Accessing App Document/Inbox Folder was not possible: lacking access rights")
                    return
                }

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
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error trying to move file out of the Inbox into the Document folder ")
            }
            
            if filesImported.count > 0 {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "NewFilesArrived"), object: filesImported, userInfo: nil)
            }
        }
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
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }


}

