//
//  Backup Document.swift
//  Bulls'N'Bears
//
//  Created by aDav on 28/12/2021.
//

import UIKit

class Backup_Document: UIDocument {
    
    var sharesData: Data?
    var researchData: Data?
    var transactionData: Data?
    var userEvaluationData: Data?
    var wbValuationData: Data?
    var dcfValuationData: Data?
    var r1ValuationData: Data?

    override func contents(forType typeName: String) throws -> Any {
        
        var dataDictionaries: [String:Data?]
                
        dataDictionaries = [String:Data]()
        dataDictionaries["SharesData"] = sharesData
        dataDictionaries["TransactionData"] = transactionData
        dataDictionaries["ResearchData"] = researchData
        dataDictionaries["UserEvaluationData"] = userEvaluationData
        dataDictionaries["WBValuationData"] = wbValuationData
        dataDictionaries["DCFValuationData"] = dcfValuationData
        dataDictionaries["R1ValuationData"] = r1ValuationData

        return archiveObject(object: dataDictionaries) as Any
    }
    
    func archiveObject(object: Any?) -> NSData? {
        
        var data = NSData()
        
        guard object != nil else {
            return nil
        }
        
        do {
            data = try NSKeyedArchiver.archivedData(withRootObject: object!, requiringSecureCoding: false) as Data as NSData
        } catch let error {
            alertController.showDialog(title: "Backup failed", alertMessage: "backup data couldn't be archived: \(error.localizedDescription)", viewController: nil, delegate: nil)
        }
        
        return data
    }
    
    func unarchiveObject(data: Data?) -> Any? {
        
        guard data != nil else {
            return nil
        }
        
        var object: Any?
        do {
            object = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data!)
        } catch let error {
            alertController.showDialog(title: "Restore failed", alertMessage: "backup data couldn't be unarchived frim file: \(error.localizedDescription)", viewController: nil, delegate: nil)
        }
        
        return object
    }


    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        
        let dictionariesData = contents as? Data
        var dictionaries:[String:Data]?
        
        guard dictionariesData != nil else {
            alertController.showDialog(title: "Restore failed", alertMessage: "Backup file has no readable content", viewController: nil, delegate: nil)
            return
        }
        
        dictionaries = unarchiveObject(data: dictionariesData) as? [String : Data]
        
        guard dictionaries != nil else {
            alertController.showDialog(title: "Restore failed", alertMessage: "Unable to read data from backup file", viewController: nil, delegate: nil)
            return
        }
        
        sharesData = dictionaries!["SharesData"]
        transactionData = dictionaries!["TransactionData"]
        researchData = dictionaries!["ResearchData"]
        userEvaluationData = dictionaries!["UserEvaluationData"]
        wbValuationData = dictionaries!["WBValuationData"]
        dcfValuationData = dictionaries!["DCFValuationData"]
        r1ValuationData = dictionaries!["R1ValuationData"]

    }
}
