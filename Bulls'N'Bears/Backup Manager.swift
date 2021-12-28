//
//  Backup Manager.swift
//  Bulls'N'Bears
//
//  Created by aDav on 28/12/2021.
//

import UIKit


class BackupManager {
    
    
    var localBackupDirectoryPath: String? = {
        
        let applicationSupportDirectoryPaths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        let localFolderPath = applicationSupportDirectoryPaths[0] + "/LocalBackups"
        if FileManager.default.fileExists(atPath: localFolderPath) {
            return localFolderPath
        } else {
            do {
                try FileManager.default.createDirectory(atPath: localFolderPath, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                alertController.showDialog(title: "Backup unavailable", alertMessage: "System can't create backups: \(error.localizedDescription)")
            }
            return localFolderPath
        }
    }()

    class func shared() -> BackupManager {
        return backupManager
    }
    
    public func backupData() {
        
        guard localBackupDirectoryPath != nil else {
            return
        }
        
        let newbackupName = "/Backup \(UIDevice.current.name) " + "(\(String(describing: UserDefaults.standard.value(forKey: "BackupNumbering")!)))" + ".bbf"

        let newBackupPath = localBackupDirectoryPath! + newbackupName
        let newBackupURL = URL(fileURLWithPath: newBackupPath)
        
        let backupDocument = Backup_Document(fileURL: newBackupURL)
        
    }
    
}

let backupManager = BackupManager()
