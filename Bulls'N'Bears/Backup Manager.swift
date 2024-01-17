//
//  Backup Manager.swift
//  Bulls'N'Bears
//
//  Created by aDav on 28/12/2021.
//

import UIKit
import CoreData


class BackupManager {
    
    var context: NSManagedObjectContext!
    
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
    
    /// default context is main thread context; for using background process send a background context
    init(context: NSManagedObjectContext?) {
        self.context = context ?? PersistenceController.shared.persistentContainer.viewContext
    }

    class func shared() -> BackupManager {
        return backupManager
    }
    
    class func deleteBackup(fileURL: URL) {
        
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "Failed to delete backup after export")
        }
    }
    
    class func backupData() async -> URL? {
        
        guard let backupFolderURL = localBackupFolderURL else {
            alertController.showDialog(title: "Backup failed", alertMessage: "Failed to get local backup folder", viewController: nil, delegate: nil)
            return nil
        }
        
        let backupName = "BnB Backup.bbf"

        let backupURL = backupFolderURL.appending(component: backupName)
        
        var saveOperation: UIDocument.SaveOperation!
        do {
            if FileManager.default.fileExists(atPath: backupURL.path()) {
                saveOperation = .forOverwriting
            }
            else {
                saveOperation = .forCreating
            }
        }
        
        let backupDocument = await BNB_Archive(fileURL: backupURL)
        
        if await !backupDocument.save(to: backupURL, for: saveOperation) {
            alertController.showDialog(title: "Backup failed", alertMessage: "The backup file couldn't be saved", viewController: nil, delegate: nil)
            return nil
        }

        do {
            
            try await backupDocument.backupAll()
            
            // important - keep this step.
            if await !backupDocument.save(to: backupURL, for: saveOperation) {
                alertController.showDialog(title: "Backup failed", alertMessage: "The backup file couldn't be saved", viewController: nil, delegate: nil)
                return nil
            }

            
            if await !backupDocument.close() {
                alertController.showDialog(title: "Backup failed", alertMessage: "The backup file couldn't be closed", viewController: nil, delegate: nil)
                return nil
            }            
            
            return backupURL
            
        } catch {
            alertController.showDialog(title: "Backup failed", alertMessage: "The archiving process failed", viewController: nil, delegate: nil)
            return nil
        }
                
    }
    
    /// restores data from backup file stored inside the App's localBackupDirectoryPath or any file provided
    class func restoreData(fromURL: URL?=nil) async throws {
        
        var sourceURL = fromURL
        
        if sourceURL == nil {
            guard let localFolderPath = localBackupFolderURL?.path() else {
                throw InternalError()
            }
            let backupName = "/BnB Backup" + ".bbf"

            sourceURL = URL(fileURLWithPath: localFolderPath + backupName)
        }
        
        guard sourceURL != nil else {
            alertController.showDialog(title: "Restore failed", alertMessage: "The App's backup directory couldn't be found", viewController: nil, delegate: nil)
            return
        }
        
        if FileManager.default.fileExists(atPath: sourceURL!.path) {
            let backupDocument = await BNB_Archive(fileURL: sourceURL!)
            if await backupDocument.open() {
                try await backupDocument.decodeShares()
            }
            else {
                alertController.showDialog(title: "Restore failed", alertMessage: "An existing backup file couldn't be opened", viewController: nil, delegate: nil)
            }
        }
        else {
            print("missing import file at \(sourceURL!)")
            alertController.showDialog(title: "Restore failed", alertMessage: "A backup file couldn't be found at the provided source or in the App's backup directory", viewController: nil, delegate: nil)
            return
        }

    }

    class func deleteAllData() async throws {
        
        let context = PersistenceController.shared.persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        
        let sharesFR = Share.fetchRequest()
        let healthFR = HealthData.fetchRequest()
        let keyStatsFR = Key_stats.fetchRequest()
        let incomeFR = Income_statement.fetchRequest()
        let balanceFR = Balance_sheet.fetchRequest()
        let cashFR = Cash_flow.fetchRequest()
        let analysisFR = Analysis.fetchRequest()
        let ratiosFR = Ratios.fetchRequest()
        let infoFR = Company_Info.fetchRequest()
        let transactionsFR = ShareTransaction.fetchRequest()
        let researchFDR = StockResearch.fetchRequest()
        let userFR = UserEvaluation.fetchRequest()
        let wbvFR = WBValuation.fetchRequest()
        let dcfFR = DCFValuation.fetchRequest()
        let r1FR = Rule1Valuation.fetchRequest()

        let allRequest = [sharesFR, healthFR, keyStatsFR, incomeFR, balanceFR, cashFR, analysisFR, ratiosFR, infoFR, transactionsFR, researchFDR, userFR, wbvFR, dcfFR, r1FR]
        
        for request in allRequest {
            let objects = try context.fetch(request as! NSFetchRequest<any NSFetchRequestResult>)
            for object in objects {
                context.delete(object as! NSManagedObject)
            }
        }
        
        try context.save()

    }
    
}

let backupManager = BackupManager(context: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)
