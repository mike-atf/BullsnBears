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
    
    class func backupData() async -> URL? {
        
        guard let backupFolderURL = localBackupFolderURL else {
            print("backup failed - there's no local backup directory")
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
            //        backupDocument.transactionData = createTransactionsData()
            //        backupDocument.wbValuationData = createWBVData()
            //        backupDocument.researchData = createResearchData()
            //        backupDocument.dcfValuationData = createDCFVData()
            //        backupDocument.r1ValuationData = createR1VData()
            
            // important - keep this step.
            if await !backupDocument.save(to: backupURL, for: saveOperation) {
                alertController.showDialog(title: "Backup failed", alertMessage: "The backup file couldn't be saved", viewController: nil, delegate: nil)
                return nil
            }

            
            if await !backupDocument.close() {
                alertController.showDialog(title: "Backup failed", alertMessage: "The backup file couldn't be closed", viewController: nil, delegate: nil)
                return nil
            }            
            print("...archive closed")

            
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
    
    //MARK: - backup methods
    /*
    private func createSharesData() -> [Data]? {
        
            
        var shares: [Share]?
        var sharesData: [Data]?
        
        let request = NSFetchRequest<Share>(entityName: "Share" )
        
        do {
            shares = try self.context.fetch(request)
            for share in shares ?? [] {
                let data = try NSKeyedArchiver.archivedData(withRootObject: share, requiringSecureCoding: false)
                sharesData?.append(data)
            }
        } catch {
            ErrorController.addInternalError(errorLocation: "Backup Manager", systemError: error, errorInfo: "error trying to archive shares")
        }
        
        return  sharesData
        
    }
    
    private func createTransactionsData() -> Data? {
        
            
        var transactions: [ShareTransaction]?
        var transactionsData: Data?
        
        let request = NSFetchRequest<ShareTransaction>(entityName: "ShareTransaction" )
        
        do {
            transactions = try self.context.fetch(request)
            transactionsData = try NSKeyedArchiver.archivedData(withRootObject: transactions ?? [], requiringSecureCoding: false)
        } catch let error {
            ErrorController.addInternalError(errorLocation: "Backup Manager", systemError: error, errorInfo: "error trying to archive transactions")
        }
        
        return  transactionsData
        
    }
    
    private func createWBVData() -> Data? {
        
            
        var wbvs: [WBValuation]?
        var wbvsData: Data?
        
        let request = NSFetchRequest<WBValuation>(entityName: "WBValuation" )
        
        do {
            wbvs = try self.context.fetch(request)
            wbvsData = try NSKeyedArchiver.archivedData(withRootObject: wbvs ?? [], requiringSecureCoding: false)
        } catch let error {
            ErrorController.addInternalError(errorLocation: "Backup Manager", systemError: error, errorInfo: "error trying to archive WB Valuations")
        }
        
        return  wbvsData
        
    }
    
    private func createResearchData() -> Data? {
        
            
        var research: [StockResearch]?
        var researchData: Data?
        
        let request = NSFetchRequest<StockResearch>(entityName: "StockResearch" )
        
        do {
            research = try self.context.fetch(request)
            researchData = try NSKeyedArchiver.archivedData(withRootObject: research ?? [], requiringSecureCoding: false)
        } catch let error {
            ErrorController.addInternalError(errorLocation: "Backup Manager", systemError: error, errorInfo: "error trying to archive stock research entries")
        }
        
        return  researchData
        
    }
    
    private func createDCFVData() -> Data? {
        
            
        var dcfv: [DCFValuation]?
        var dcfvData: Data?
        
        let request = NSFetchRequest<DCFValuation>(entityName: "DCFValuation" )
        
        do {
            dcfv = try self.context.fetch(request)
            dcfvData = try NSKeyedArchiver.archivedData(withRootObject: dcfv ?? [], requiringSecureCoding: false)
        } catch let error {
            ErrorController.addInternalError(errorLocation: "Backup Manager", systemError: error, errorInfo: "error trying to archive DCF Valuations")
        }
        
        return  dcfvData
        
    }

    private func createR1VData() -> Data? {
        
            
        var r1v: [Rule1Valuation]?
        var r1vData: Data?
        
        let request = NSFetchRequest<Rule1Valuation>(entityName: "Rule1Valuation" )
        
        do {
            r1v = try self.context.fetch(request)
            r1vData = try NSKeyedArchiver.archivedData(withRootObject: r1v ?? [], requiringSecureCoding: false)
        } catch let error {
            ErrorController.addInternalError(errorLocation: "Backup Manager", systemError: error, errorInfo: "error trying to archive Rule1 Valuations")
        }
        
        return  r1vData
        
    }
    */
    
    //MARK: - restore methods
    
    /// retrieves all data via Shares from backup
//    public func retrieveShares(document: BNB_Archive) async {
//        
//            do {
//                try await deleteAllData()
//            } catch {
//                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "Failure to delete old data before retreiving shares from backup")
//            }
//            
//            await restoreData()
//
//    }
    
    
//    private func restoreShares(data: Data?) -> [Share]? {
//        
//        guard let validData = data else {
//            return nil
//        }
//        
//        var shares: [Share]?
//        
//        do {
//            shares = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(validData) as? [Share]
//        } catch {
//            return nil
//        }
//        
//        return shares
//    }
    
//    private func restoreTransactions(data: Data?) -> [ShareTransaction]? {
//        
//        guard let validData = data else {
//            return nil
//        }
//        
//        var transactions: [ShareTransaction]?
//        
//        do {
//            transactions = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(validData) as? [ShareTransaction]
//        } catch {
//            return nil
//        }
//        
//        return transactions
//    }

    
    
    //MARK: - moc delete and save functions
//    private func saveRestoredShares(shares: [Share]) -> Bool {
//        
//        if deleteAllShares() {
//            for share in shares {
//                context.insert(share)
//            }
//            
//            do {
//                try context.save()
//            } catch {
//                return false
//            }
//            
//            return true
//            
//        } else {
//            return false
//        }
//        
//    }
    
//    private func saveRestoredTransactions(transactions: [ShareTransaction]) -> Bool {
//        
//        if deleteAllShares() {
//            for transaction in transactions {
//                //TODO: - may need to re-create relationship to share!
//                context.insert(transaction)
//            }
//            
//            do {
//                try context.save()
//            } catch {
//                return false
//            }
//            
//            return true
//            
//        } else {
//            return false
//        }
//        
//    }
//    
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
