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
    func treasuryBondRatesDownloaded()
    func livePriceUpdated(indexPath: IndexPath?)
}

/// Share calls this when it wants to inform StocksController that the price update is complete
protocol StockDelegate {
    func keyratioDownloadComplete(share: SharePlaceHolder, errors: [String])
    func livePriceDownloadCompleted(share: SharePlaceHolder?, errors: [String])
}


class StocksController: NSFetchedResultsController<Share> {
    
    var pricesUpdateDelegate: StocksControllerDelegate?
    var stockDelegate: StockDelegate?
    lazy var yahooRefDate: Date = getYahooRefDate()
    var downloadErrors = [String]()
    var webDownLoader: WebDataDownloader?
    var sortParameter = UserDefaults.standard.value(forKey: userDefaultTerms.sortParameter) as! String
    
    var backgroundContext: NSManagedObjectContext?
    /// in time-DESCENDING order
    var treasuryBondYields: [PriceDate]?
    var viewController: StocksListTVC?
            
    //Mark:- shares price update functions
    
    func updateLivePrices(selectedShare: Share) {
        // runs on backGround queue!
        
//
//        print()
//        print(#function)
        for share in fetchedObjects ?? [] {
            let placeholder = SharePlaceHolder(share: share)

            if share.watchStatus < 2 || share.isEqual(selectedShare) {
                if placeholder.lastLivePriceDate == nil {
//                    print("\(share.symbol!) start live price update process...")
                    placeholder.startLivePriceUpdate(delegate: self)
                }
                else if Date().timeIntervalSince(placeholder.lastLivePriceDate!) > 10 {
//                    print("\(share.symbol!) start live price update process...")
                    placeholder.startLivePriceUpdate(delegate: self)
                }
                else if share.isEqual(selectedShare) {
//                    print("\(share.symbol!) is currently selected . Live price update <300 secs. Ending refresh...")
                    livePriceDownloadCompleted(share: nil, errors: [])
                    // ends tableView refresh process if last update <300sec ago
                }
            }
            else {
                updateDailyPrices(share: share)
            }
        }
    }
    
    func updateDailyPrices(share: Share) {
        // called after livePriceDownloadCompleted()
        // to avoid creating two parallel placeholder objects while separate downloads are in process that cancel the updated values out
        
        let weekDay = Calendar.current.component(.weekday, from: Date())
        guard (weekDay > 1 && weekDay < 7) else {
            return
        }
        
        let placeholder = SharePlaceHolder(share: share)
        
        var sharePriceNeedsUpdate = true
        if let lastPriceDate = placeholder.getDailyPrices()?.last?.tradingDate {
            if (Date().timeIntervalSince(lastPriceDate) < 12 * 3600) {
                sharePriceNeedsUpdate = false
            }
        }
        if sharePriceNeedsUpdate {
            placeholder.startDailyPriceUpdate(yahooRefDate: yahooRefDate, delegate: self)
            // returns to 'keyRatioDownloadComplete()' just below via the delegate
        }
        

    }
    
    func updateTreasuryBondYields() {
        
        if let lastDate = treasuryBondYields?.compactMap({ $0.date }).sorted().last {
            if Date().timeIntervalSince(lastDate) < 14*3600 {
                return
            }
        }
        
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = NSLocale.current
            formatter.timeZone = NSTimeZone.local
            formatter.dateFormat = "YYYY"
            return formatter
        }()
        let year$ = dateFormatter.string(from: Date())
        
        var urlComponents = URLComponents(string: "https://www.treasury.gov/resource-center/data-chart-center/interest-rates/pages/TextView.aspx")
        urlComponents?.queryItems = [URLQueryItem(name: "data", value: "yieldYear"),URLQueryItem(name: "year", value: year$)]
        
        guard let url = urlComponents?.url else {
            return
        }
        
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpShouldSetCookies = true
        let session = URLSession(configuration: configuration)
        var downloadTask: URLSessionDataTask? // URLSessionDataTask stores downloaded data in memory, DownloadTask as File

        downloadTask = session.dataTask(with: url) { [self]
            data, responseOrNil, errorOrNil in
            
            guard errorOrNil == nil else {
                DispatchQueue.main.async {
                    alertController.showDialog(title: "Download error", alertMessage: "couldn't download Treasury Bond Yields due to error \(errorOrNil!.localizedDescription)", viewController: viewController?.splitViewController, delegate: nil)
                }
                return
            }
            
            guard responseOrNil != nil else {
                DispatchQueue.main.async {
                    alertController.showDialog(title: "Download error", alertMessage: "couldn't download Treasury Bond Yieldsdue to error \(String(describing: responseOrNil!.textEncodingName))", viewController: viewController?.splitViewController, delegate: nil)
                }
                return
            }
            
            guard let validData = data else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "stock keyratio download error - empty website data")
                return
            }

            let html$ = String(decoding: validData, as: UTF8.self)
            (self.treasuryBondYields, _) = WebpageScraper.scrapeTreasuryYields(html$: html$) // in time-DESCENDING order
            DispatchQueue.main.async {
                self.pricesUpdateDelegate?.treasuryBondRatesDownloaded()
            }

        }
        downloadTask?.resume()
    }
    
    func updateCompanyResearchData(share: Share) {
        
        // this can safely be done using the main viewContext on the main thread as the function does not involve downloads and background tasks
        
        let allShares = StocksController.allShares()
        
        if let competitors = share.research?.competitors {
            for competitor in competitors {
                
                if let storedCompetitors = allShares?.filter({ (aShare) -> Bool in
                    if aShare.symbol == competitor { return true }
                    else { return false }
                }) {
                    for company in storedCompetitors {
                        
                        if company.research == nil {
                            let newResearch = StockResearch.init(context: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)
                            newResearch.symbol = company.symbol
                            newResearch.competitors = [share.symbol!]
                            share.research = newResearch
                            newResearch.save()
                        }
                        else {
                            if company.research!.competitors != nil {
                                if !company.research!.competitors!.contains(share.symbol!) {
                                    company.research!.competitors!.append(share.symbol!)
                                    company.research?.save()
                                }
                            }
                            else {
                                company.research!.competitors = [share.symbol!]
                            }
                        }
                        
                        if share.industry == nil {
                            share.industry = company.industry
                            share.save()
                        }
                        else if company.industry == nil {
                            company.industry = share.industry
                            company.save()
                        }
                    }
                }
            }
        }
    }
    
    class func allShares() -> [Share]? {

        var shares: [Share]?
        
        let fetchRequest = NSFetchRequest<Share>(entityName: "Share")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "symbol", ascending: true)]
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            shares = try (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.fetch(fetchRequest)
            } catch let error {
                ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: error, errorInfo: "error fetching Shares")
        }
        
        return shares
    }
    
    func fetchShare(symbol: String) -> Share? {

        var share: Share?
        
        let fetchRequest = NSFetchRequest<Share>(entityName: "Share")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "symbol", ascending: true)]
        let predicate = NSPredicate(format: "symbol == %@", argumentArray: [symbol])
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.predicate = predicate
        
        do {
            share = try (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.fetch(fetchRequest).first
            } catch let error {
                ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: error, errorInfo: "error fetching Shares")
        }
        
        return share
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
    
    class func createShare(from file: URL?, companyName: String?=nil, deleteFile: Bool?=false) -> Share? {
        
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
        let macds = newShare.calculateMACDs(shortPeriod: 8, longPeriod: 17)
        newShare.macd = newShare.convertMACDToData(macds: macds)
                
        if let dictionary = stockTickerDictionary {
            newShare.name_long = companyName ?? dictionary[stockName]
            
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
        
        return newShare
    }
    
    class func createShare(with pricePoints: [PricePoint]?, symbol: String, companyName: String?=nil) -> Share? {
        
        guard let validPrices = pricePoints else {
            return nil
        }
        
        let stockName = symbol
        
        let newShare = Share.init(context: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)
        
        newShare.symbol = stockName
        newShare.creationDate = Date()
        newShare.dailyPrices = newShare.convertDailyPricesToData(dailyPrices: validPrices)
        let macds = newShare.calculateMACDs(shortPeriod: 8, longPeriod: 17)
        newShare.macd = newShare.convertMACDToData(macds: macds)
                
        if let dictionary = stockTickerDictionary {
            newShare.name_long = companyName ?? dictionary[stockName]
            
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
        
        // check for any exisisting valuations
        newShare.wbValuation = WBValuationController.returnWBValuations(share: newShare)
        newShare.dcfValuation = CombinedValuationController.returnDCFValuations(company: newShare.symbol!)
        newShare.rule1Valuation = CombinedValuationController.returnR1Valuations(company: newShare.symbol)
        
        return newShare
    }
    
    class func fetchSpecificShare(symbol: String, context: NSManagedObjectContext?=nil) -> Share? {
        
        let request = NSFetchRequest<Share>(entityName:"Share")
        let predicate = NSPredicate(format: "symbol == %@", argumentArray: [symbol])
        request.predicate = predicate

        request.sortDescriptors = [NSSortDescriptor(key:  "symbol" , ascending:  true )]
        
        let theContext = context ?? (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        var shares: [Share]?
        do {
            shares  =  try theContext.fetch(request)
        } catch let error as NSError{
            ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: error, errorInfo: "error fetching Shares")
        }
        
        return shares?.first
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

    // MARK: - download functions
    
}

extension StocksController: StockDelegate {
    
    func livePriceDownloadCompleted(share: SharePlaceHolder?, errors: [String]) {
        
        if share == nil {
            print(#function + "no share placeHolder returned from live price download. Sending request to end refresh process to StocksListTVC")

            pricesUpdateDelegate?.livePriceUpdated(indexPath: nil)
            // ends tableView refresh process if last update <300sec ago
            
            return
        }
        
        if let matchingShare = fetchedObjects?.filter({ (shareObject) -> Bool in
            if share!.symbol == shareObject.symbol { return true }
            else { return false }
        }).first {
            share!.shareFromPlaceholder(share: matchingShare)
            
            if let path = self.indexPath(forObject: matchingShare) {
                print(#function + "\(matchingShare.symbol!) live price download complete. Sending info to StocksListTVC")
                pricesUpdateDelegate?.livePriceUpdated(indexPath: path)
            }
            
            updateDailyPrices(share: matchingShare)
        }
        
        if errors.count > 0 {
            for error in errors {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: error)
            }
        }

    }
    
    /// caller must have dispatched this fucntion call on the main thread!!
    func keyratioDownloadComplete(share: SharePlaceHolder, errors: [String]) {
        
        if let matchingShare = fetchedObjects?.filter({ (shareObject) -> Bool in
            if share.symbol == shareObject.symbol { return true }
            else { return false }
        }).first {
            share.shareFromPlaceholder(share: matchingShare)
            matchingShare.save() // will trigger update of StocksListTVC via FRC functionality
        }
        
        if errors.count > 0 {
            for error in errors {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: error)
            }
        }
    }
    
    func research() {
        for share in self.fetchedObjects ?? [] {
            share.priceIncreaseAfterMCDCrossings()
            share.priceIncreaseAfterOscCrossings()
        }
    }
}
