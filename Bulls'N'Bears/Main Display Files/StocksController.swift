//
//  StocksController.swift
//  Bulls'N'Bears
//
//  Created by aDav on 10/02/2021.
//

import Foundation

protocol StockControllerDelegate {
    func openStocksComplete()
    func updateStocksComplete()
}

class StocksController: StockDelegate {
    
    var delegate: StockControllerDelegate?
    lazy var yahooRefDate: Date = getYahooRefDate()
    
    init(delegate: StockControllerDelegate) {
        self.delegate = delegate
    }
    
    func priceUpdateComplete(symbol: String) {
        // gather info from all stock reporting their updates are complete then call the TVC delegte to update it's view
        
        var updatesComplete = [Bool]()
        for stock in stocks {
            updatesComplete.append(stock.needsUpdate)
        }
        
        if !updatesComplete.contains(true) {
            DispatchQueue.main.async {
                self.delegate?.updateStocksComplete()
            }
        }
    }
    
    func loadStockFiles() {
        
        let appDocumentPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if let documentFolder = appDocumentPaths.first {
            
        DispatchQueue.main.async {

            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: documentFolder), includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                
                for url in fileURLs {
                    if url.lastPathComponent.contains(".csv") {
                        // dont use 'fileURL.startAccessingSecurityScopedResource()' on App sandbox /Documents folder as access is always granted and the access request will alwys return false
                        if let stock = CSVImporter.csvExtractor(url: url) {
                            stock.delegate = self
                            stocks.append(stock)
                        }
                   }
                }
                } catch let error {
                    ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "can't access contens of directory \(documentFolder)")
                }
                self.delegate?.openStocksComplete()
            }
        }
    }
    
    func updateStockFiles() {
        
        stocks = sortStocksByRatings(stocks: stocks)
        
        guard (Calendar.current.component(.weekday, from: Date()) > 2) else {
            return
        }
                
        for stock in stocks {
            if stock.needsUpdate {
                stock.startPriceUpdate(yahooRefDate: yahooRefDate)
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
}
