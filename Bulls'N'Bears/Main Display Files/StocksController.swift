//
//  StocksController.swift
//  Bulls'N'Bears
//
//  Created by aDav on 10/02/2021.
//

import UIKit
import CoreData

/// StocksController calls this delegate when all shares have updated their price to inform StocksListVC
/// then update the stockChartVC - > chartView candleStick chart
protocol StocksControllerDelegate {
    func allSharesHaveUpdatedTheirPrices() // all shares prices have been updated
}

/// Share calls this when it wants to inform StocksController that the price update is complete
protocol StockDelegate {
    func priceUpdateComplete(symbol: String)
}

/// Share calls this when it wants to inform StocksController or ValueListTVC  that the price update is complete
/// StocksListVC picks this up from StocksController to add any Error to the centrsal Error log
/// ValueLIstTVC picks this up to update it's section [0]
protocol StockKeyratioDownloadDelegate {
    func keyratioDownloadComplete(errors: [String])
}


class StocksController: NSFetchedResultsController<Share> {
    
    var pricesUpdateDelegate: StocksControllerDelegate?
    var keyratioUpdateDelegate: StockKeyratioDownloadDelegate?
    var stockDelegate: StockDelegate?
    lazy var yahooRefDate: Date = getYahooRefDate()
            
    //Mark:- shares price update functions
    
    func updateStockFiles() {
        
        // don't update on Sundays and Mondays when there's no data
        guard (Calendar.current.component(.weekday, from: Date()) > 2) else {
            return
        }
        
                
        for share in fetchedObjects ?? [] {
            if !(share.priceUpdateComplete ?? false) {
                share.startPriceUpdate(yahooRefDate: yahooRefDate, delegate: self)
                // returns to 'priceUpdateComplete()' just below via the delegate
            }
        }
    }
                
    private func getYahooRefDate() -> Date {
        let calendar = Calendar.current
        let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]
        var dateComponents = calendar.dateComponents(components, from: Date())
        dateComponents.second = 0
        dateComponents.minute = 0
        dateComponents.hour = 0
        dateComponents.year = 1970
        dateComponents.day = 1
        dateComponents.month = 1
        return calendar.date(from: dateComponents) ?? Date()

    }
    
    class func createShare(from file: URL?, deleteFile: Bool?=false) -> Share? {
        
        guard let fileURL = file else {
            return nil
        }
        
        guard let lastPathComponent = fileURL.lastPathComponent.split(separator: ".").first else {
            return nil
        }
        let stockName = String(lastPathComponent)
        
        let newShare = Share.init(context: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)
        
        newShare.symbol = stockName
        newShare.creationDate = Date()
        let pricePoints = CSVImporter.extractPricePointsFromFile(url: file, symbol: stockName)
        newShare.dailyPrices = newShare.convertDailyPricesToData(dailyPrices: pricePoints)
        
        if let dictionary = stockTickerDictionary {
            newShare.name_long = dictionary[stockName]
            
            if let longNameComponents = newShare.name_long?.split(separator: " ") {
                let removeTerms = ["Inc.","Incorporated" , "Ltd", "Ltd.", "LTD", "Limited","plc." ,"Corp.", "Corporation","Company" ,"International", "NV","&", "The", "Walt", "Co."] // "Group",
                let replaceTerms = ["S.A.": "sa "]
                var cleanedName = String()
                for component in longNameComponents {
                    if replaceTerms.keys.contains(String(component)) {
                        cleanedName += replaceTerms[String(component)] ?? ""
                    } else if !removeTerms.contains(String(component)) {
                        cleanedName += String(component) + " "
                    }
                }
                newShare.name_short = String(cleanedName.dropLast())
            }
        }
        
        if deleteFile ?? false {
            removeFile(file)
        }
        
        // check for any exisisting valuations
        newShare.wbValuation = WBValuationController.returnWBValuations(share: newShare)
        newShare.dcfValuation = CombinedValuationController.returnDCFValuations(company: newShare.symbol!)
        newShare.rule1Valuation = CombinedValuationController.returnR1Valuations(company: newShare.symbol)
        
        newShare.downloadKeyRatios(delegate: nil)
        return newShare
    }
    
    static func removeFile(_ atURL: URL?) {
       
        guard atURL != nil else {
            return
        }
        
        do {
            try FileManager.default.removeItem(at: atURL!)
        } catch let error {
            DispatchQueue.main.async {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error trying to remove existing file in the Document folder to be able to move new file of same name from Inbox folder ")
            }
        }
    }

}

extension StocksController: StockKeyratioDownloadDelegate, StockDelegate {
    
    func priceUpdateComplete(symbol: String) {
        
        guard let shares = fetchedObjects else { return }
        
        if !(shares.compactMap { $0.priceUpdateComplete! }.contains(false)) {
            pricesUpdateDelegate?.allSharesHaveUpdatedTheirPrices()

            DispatchQueue.global(qos: .background).async {
                for share in self.fetchedObjects ?? [] {
                    share.downloadKeyRatios(delegate: self)
                }
            }
        }
    }
    
    
    func keyratioDownloadComplete(errors: [String]) {
        
        if errors.count > 0 {
            for error in errors {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: error)

            }
        }
    }
}
