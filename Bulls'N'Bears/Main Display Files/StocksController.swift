//
//  StocksController.swift
//  Bulls'N'Bears
//
//  Created by aDav on 10/02/2021.
//

import UIKit
import CoreData

protocol SharesUpdaterDelegate {
//    func openStocksComplete()
    func updateStocksComplete()
    func updateShares()
}

protocol StockKeyratioDownloadDelegate {
    func keyratioDownloadComplete(errors: [String])
}


class StocksController: NSFetchedResultsController<Share>, StockDelegate {
    
    var controllerDelegate: SharesUpdaterDelegate?
    var stocksDelegate: StockDelegate?
    lazy var yahooRefDate: Date = getYahooRefDate()
        
    
//    func loadStockFiles() {
//
//        let appDocumentPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
//        if let documentFolder = appDocumentPaths.first {
//
//        DispatchQueue.main.async {
//
//            do {
//                let fileURLs = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: documentFolder), includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
//
//                for url in fileURLs {
//                    if url.lastPathComponent.contains(".csv") {
//                        // dont use 'fileURL.startAccessingSecurityScopedResource()' on App sandbox /Documents folder as access is always granted and the access request will alwys return false
//                        StocksController.createShare(from: url, deleteFile: true)
////                        if let stock = CSVImporter.csvExtractor(url: url) {
////                            stock.delegate = self
////                            stocks.append(stock)
////                        }
//                   }
//                }
//                } catch let error {
//                    ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "can't access contens of directory \(documentFolder)")
//                }
//                self.delegate?.openStocksComplete()
//            }
//        }
//    }
    
    
    //Mark:- shares price update functions
    
    func updateStockFiles() {
        
//        stocks = sortStocksByRatings(stocks: stocks)
        
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
    
    func priceUpdateComplete(symbol: String) {
        // gather info from all stock reporting their updates are complete then call the TVC delegte to update it's view
        
        let allUpdated = fetchedObjects?.compactMap{ $0.priceUpdateComplete } ?? [true]
        
        if !allUpdated.contains(false) {
            
            DispatchQueue.main.async {

                do {
                    try (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.save()
                } catch let error {
                    fatalError("Unresolved context saving error \(error.localizedDescription)")
                }

                self.controllerDelegate?.updateStocksComplete()
            }
            
            // then update key ratios at leisure; display needed in WBVlautionListTVC only
            DispatchQueue.global(qos: .userInteractive).async {
                for share in self.fetchedObjects ?? [] {
                    share.downloadKeyRatios()
                }
            }
        }
    }
        
    
    public func sortStocksByRatings(stocks: [Stock]) -> [Stock] {
        
        let sortedStocks = stocks.sorted(by: { (e0, e1) -> Bool in
            if (e0.userRatingScore?.ratingScore() ?? 0) > (e1.userRatingScore?.ratingScore() ?? 0) { return true }
            else if (e0.userRatingScore?.ratingScore() ?? 0) < (e1.userRatingScore?.ratingScore() ?? 0) { return false }
            else {
                if (e0.fundamentalsScore?.ratingScore() ?? 0) > (e1.fundamentalsScore?.ratingScore() ?? 0)  { return true }
                else if (e0.fundamentalsScore?.ratingScore() ?? 0) < (e1.fundamentalsScore?.ratingScore() ?? 0)  { return false }
                else { return false }
            }
        })
        
        return sortedStocks
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

        do {
            try  (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }

        if deleteFile ?? false {
            removeFile(file)
        }
        
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

extension StocksController: StockKeyratioDownloadDelegate {
        
    func keyratioDownloadComplete(errors: [String]) {
        
        if errors.count > 0 {
            for error in errors {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: error)

            }
        }
    }
}
