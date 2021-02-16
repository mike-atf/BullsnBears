//
//  WBValuationController.swift
//  Bulls'N'Bears
//
//  Created by aDav on 16/02/2021.
//

import Foundation
import CoreData

class WBValuationController {
    
    var sectionTitles = ["Key ratios","WB Value"]
    var sectionSubTitles = ["from Yahoo finance",""]
    var rowTitles: [[String]]!
    var stock: Stock
    var valuation: WBValuation?
    
    //MARK: - init

    init(stock: Stock) {
        self.stock = stock
        
        if let valuation = WBValuationController.returnWBValuations(company: stock.symbol)?.first {
            self.valuation = valuation
        }
        else {
            self.valuation = WBValuationController.createWBValuation(company: stock.symbol)
        }
        
        rowTitles = buildRowTitles()
    }
    
    //MARK: - class functions
    
    static func returnWBValuations(company: String? = nil) -> [WBValuation]? {
        
        var valuations: [WBValuation]?
        
        let fetchRequest = NSFetchRequest<WBValuation>(entityName: "WBValuation")
        if let validName = company {
            let predicate = NSPredicate(format: "company BEGINSWITH %@", argumentArray: [validName])
            fetchRequest.predicate = predicate
        }
        
        do {
            valuations = try managedObjectContext.fetch(fetchRequest)
            } catch let error {
                ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: error, errorInfo: "error fetching Rule1Valuation")
        }

        return valuations
    }

    static func createWBValuation(company: String) -> WBValuation? {
        
        let newValuation:WBValuation? = {
            NSEntityDescription.insertNewObject(forEntityName: "WBValuation", into: managedObjectContext) as? WBValuation
        }()
        newValuation?.company = company
        do {
            try  managedObjectContext.save()
        } catch {
            let error = error
            ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: error, errorInfo: "error creating and saving Rule1Valuation")
        }

        return newValuation
    }
    
    //MARK: - TVC controller functions
    
    public func rowTitle(path: IndexPath) -> String {
        return rowTitles[path.section][path.row]
    }
    
    public func sectionHeaderText(section: Int) -> (String, String) {
        return (sectionTitles[section], sectionSubTitles[section])
    }

    public func value$(path: IndexPath) -> (String,[String]?) {
        
        guard valuation != nil else {
            return ("--", ["no valuation"])
        }
        
        var value$: String?
        var errors: [String]?
        
        if path.section == 0 {
            switch path.row {
            case 0:
                if let valid = stock.peRatio {
                    value$ = currencyFormatterGapWithPence.string(from: valid as NSNumber)
                }
            case 1:
                if let valid = stock.eps {
                    value$ = currencyFormatterGapWithPence.string(from: valid as NSNumber)
                }
            case 2:
                if let valid = stock.beta {
                    value$ = numberFormatterDecimals.string(from: valid as NSNumber)
                }
            default:
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "undefined row in path \(path)")
            }
            
            return (value$ ?? "no value", nil)
        }
        
        if path.section == 1 {
            let (value, errors) = valuation!.ivalue()
            if errors.count == 0 {
                if let valid = value {
                    return (currencyFormatterGapNoPence.string(from: valid as NSNumber) ?? "no value", nil)
                }
                else {
                    return ("no value", nil)
                }
            }
            else { // errors
                if let valid = value {
                    return (currencyFormatterGapNoPence.string(from: valid as NSNumber) ?? "no value", errors)
                }
                else {
                    return ("no value", errors)
                }
            }
        }
        
        return ("no value", nil)
        
    }
    
    // MARK: - internal functions
    
    private func buildRowTitles() -> [[String]] {
        
//        var rowTitles = [[String]]()
//
//        let titles = [["P/E ratio", "EPS", "beta"], ["Intrinsic value"]]
//        for _ in sectionTitles {
//            rowTitles.append(titles)
//        }
//
        return [["P/E ratio", "EPS", "beta"], ["Intrinsic value"]]
    }
    

}
