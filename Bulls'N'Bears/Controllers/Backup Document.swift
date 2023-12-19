//
//  Backup Document.swift
//  Bulls'N'Bears
//
//  Created by aDav on 28/12/2021.
//

import UIKit
import CoreData

class BNB_Archive: UIDocument {
    
    var sharesData: [Data]?
        
    override func handleError(_ error: Error, userInteractionPermitted: Bool) {
        print("BNB Archive encountered error \(error.localizedDescription)")
        print()
    }

    /// returns the document data to be saved
    override func contents(forType typeName: String) throws -> Any {
        
        var dataDictionaries: [String:[Data]?]
                
        dataDictionaries = [String:[Data]]()
        dataDictionaries["SharesData"] = sharesData

        if let data = archiveContentDictionaries(object: dataDictionaries) {
            print("contents for archive with \((data as NSData).length) bytes")
            return data as Any
        }
        else {
            throw InternalError(location: #function, errorInfo: "archive save failure - no shares data archived for saving")
        }
    }
    
    private func archiveContentDictionaries(object: Any?) -> Data? {

        guard object != nil else {
            return nil
        }
        
        do {
            return try NSKeyedArchiver.archivedData(withRootObject: object!, requiringSecureCoding: true)
        } catch let error {
            alertController.showDialog(title: "Backup failed", alertMessage: "backup data couldn't be archived: \(error.localizedDescription)", viewController: nil, delegate: nil)
        }
        
        return nil
    }

    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        
        guard let contentData = contents as? NSData else {
            throw InternalError(location: #function, errorInfo: "Loading backup data from file failed")
        }
        
        print("loaded \(contentData.length) bytes of data from backup file")

        if let dictionaries = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSDictionary.self, NSData.self, NSString.self, NSArray.self], from: (contentData as Data)) as? [String: [Data]] {
            sharesData = dictionaries["SharesData"]
            print("loaded backup file data and transferred to 'sharesData' dictionary")
            return
        } else {
            print("Restore failed - Unable to unarchive dictionary from backup data")
            return
        }
    }
    
    public func backupAll() async throws {
        
        let context = PersistenceController.shared.persistentContainer.newBackgroundContext()
        
        try context.performAndWait {
            let shareFR = Share.fetchRequest()
            let shares = try context.fetch(shareFR)
            sharesData = try encode(objects: shares)
        }
        
    }
    
    /// runs on background thread
    private func encode(objects: [NSManagedObject]?) throws -> [Data]? {
        
        guard let validObjects = objects else { return nil }
        
        var archivedata = [Data]()
        
        let encoder = JSONEncoder()
        
        guard validObjects.count > 0 else {
            return [Data]()
        }
        
        if validObjects.first is Share {
            for share in validObjects as? [Share] ?? [] {
                let data = try encoder.encode(share)
                archivedata.append(data)
                print("encoded \(share.symbol!) with \((data as NSData).length) bytes")
            }
        }
   
        return archivedata
    }
    
    /// decodes all stored Share objects from data and inserts into background context; DELETE old data before calling this function
    func decodeShares() async throws {
        
        let context = PersistenceController.shared.persistentContainer.newBackgroundContext()
        
        let decoder = JSONDecoder()
        decoder.userInfo[CodingUserInfoKey.managedObjectContext] = context

        guard let validSharesData = sharesData else {
            throw InternalError.init(location: #function, errorInfo: "backup document has no shares data to decode")
        }
        
        do { // for debugging - remove later
            for data in validSharesData {
                print("decoding a share from \((data as NSData).length) of bytes data...")
                let share = try decoder.decode(Share.self, from: data)
                context.insert(share)
            }
        } catch {
            print("error with \(sharesData?.count ?? 0 ) shares decoding from data array: \(error.localizedDescription)")
            print()
        }
        
        try context.save()
     }

}
