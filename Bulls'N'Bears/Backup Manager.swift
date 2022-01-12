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
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }

    class func shared() -> BackupManager {
        return backupManager
    }
    
    public func backupData() {
        
        guard localBackupDirectoryPath != nil else {
            return
        }
        
        let backupName = "/BnB Backup " + ".bbf"

        let backupPath = localBackupDirectoryPath! + backupName
        let backupURL = URL(fileURLWithPath: backupPath)
        
        var saveOperation: UIDocument.SaveOperation!
        do {
            if FileManager.default.fileExists(atPath: backupPath) {
                saveOperation = .forOverwriting
            }
            else {
                saveOperation = .forCreating
            }
        }
        
        let backupDocument = Backup_Document(fileURL: backupURL)
        
        backupDocument.sharesData = createSharesData()
        backupDocument.transactionData = createTransactionsData()
        backupDocument.wbValuationData = createWBVData()
        backupDocument.researchData = createResearchData()
        backupDocument.dcfValuationData = createDCFVData()
        backupDocument.r1ValuationData = createR1VData()
        
        backupDocument.save(to: backupURL, for: saveOperation) { (success: Bool) in
            if !success {
                alertController.showDialog(title: "Backup failed", alertMessage: "The backup file couldn't be saved", viewController: nil, delegate: nil)
            }
        }
        
        backupDocument.close { (success: Bool) in
            alertController.showDialog(title: "Backup failed", alertMessage: "The backup file couldn't be closed", viewController: nil, delegate: nil)
        }

                
    }
    
    public func restoreData() {
        
        guard localBackupDirectoryPath != nil else {
            alertController.showDialog(title: "Restore failed", alertMessage: "The App's backup directory couldn't be found", viewController: nil, delegate: nil)
            return
        }
        
        let backupName = "/BnB Backup " + ".bbf"

        let backupPath = localBackupDirectoryPath! + backupName
        let backupURL = URL(fileURLWithPath: backupPath)
        

            var errors = [String]()
            if FileManager.default.fileExists(atPath: backupPath) {
                let backupDocument = Backup_Document(fileURL: backupURL)
                
                if let shares = restoreShares(data: backupDocument.sharesData) {
                    if !saveRestoredShares(shares: shares) {
                        errors.append("Shares")
                    }
                } else {
                    errors.append("Shares")
                }
                
                if let transactions = restoreTransactions(data: backupDocument.transactionData) {
                    if !saveRestoredTransactions(transactions: transactions) {
                        errors.append("Transactions")
                    }
                } else {
                    errors.append("Transactions")
                }

                
                
            }
            else {
                alertController.showDialog(title: "Restore failed", alertMessage: "A backup file couldn't be found in the App's backup directory", viewController: nil, delegate: nil)
                return
            }

    }
    
    //MARK: - backup methods
    private func createSharesData() -> Data? {
        
            
        var shares: [Share]?
        var sharesData: Data?
        
        let request = NSFetchRequest<Share>(entityName: "Share" )
        
        do {
            shares = try self.context.fetch(request)
            sharesData = try NSKeyedArchiver.archivedData(withRootObject: shares ?? [], requiringSecureCoding: false)
        } catch let error {
            ErrorController.addErrorLog(errorLocation: "Backup Manager", systemError: error, errorInfo: "error trying to archive shares")
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
            ErrorController.addErrorLog(errorLocation: "Backup Manager", systemError: error, errorInfo: "error trying to archive transactions")
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
            ErrorController.addErrorLog(errorLocation: "Backup Manager", systemError: error, errorInfo: "error trying to archive WB Valuations")
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
            ErrorController.addErrorLog(errorLocation: "Backup Manager", systemError: error, errorInfo: "error trying to archive stock research entries")
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
            ErrorController.addErrorLog(errorLocation: "Backup Manager", systemError: error, errorInfo: "error trying to archive DCF Valuations")
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
            ErrorController.addErrorLog(errorLocation: "Backup Manager", systemError: error, errorInfo: "error trying to archive Rule1 Valuations")
        }
        
        return  r1vData
        
    }
    
    //MARK: - restore methods
    private func restoreShares(data: Data?) -> [Share]? {
        
        guard let validData = data else {
            return nil
        }
        
        var shares: [Share]?
        
        do {
            shares = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(validData) as? [Share]
        } catch {
            return nil
        }
        
        return shares
    }
    
    private func restoreTransactions(data: Data?) -> [ShareTransaction]? {
        
        guard let validData = data else {
            return nil
        }
        
        var transactions: [ShareTransaction]?
        
        do {
            transactions = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(validData) as? [ShareTransaction]
        } catch {
            return nil
        }
        
        return transactions
    }

    
    
    //MARK: - moc delete and save functions
    private func saveRestoredShares(shares: [Share]) -> Bool {
        
        if deleteAllShares() {
            for share in shares {
                context.insert(share)
            }
            
            do {
                try context.save()
            } catch {
                return false
            }
            
            return true
            
        } else {
            return false
        }
        
    }
    
    private func saveRestoredTransactions(transactions: [ShareTransaction]) -> Bool {
        
        if deleteAllShares() {
            for transaction in transactions {
                //TODO: - may need to re-create relationship to share!
                context.insert(transaction)
            }
            
            do {
                try context.save()
            } catch {
                return false
            }
            
            return true
            
        } else {
            return false
        }
        
    }

    
    private func deleteAllShares() -> Bool {
        
        let allShares = NSFetchRequest<NSFetchRequestResult>(entityName: "Share")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: allShares)
        
        do {
            try self.context.execute(deleteRequest)
        } catch let error as NSError {
            ErrorController.addErrorLog(errorLocation: "Backup Controller", systemError: error, errorInfo: "Error deleting existing shares prior to Backup/ Import")
            return false
        }

        return true
    }
    
    private func deleteAllTransactions() -> Bool {
        
        let allTransactions = NSFetchRequest<NSFetchRequestResult>(entityName: "ShareTransaction")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: allTransactions)
        
        do {
            try self.context.execute(deleteRequest)
        } catch let error as NSError {
            ErrorController.addErrorLog(errorLocation: "Backup Controller", systemError: error, errorInfo: "Error deleting existing share transactions prior to Backup/ Import")
            return false
        }

        return true
    }

    
}

let backupManager = BackupManager(context: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)
