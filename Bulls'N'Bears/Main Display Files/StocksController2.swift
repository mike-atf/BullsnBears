//
//  StocksController2.swift
//  Bulls'N'Bears
//
//  Created by aDav on 04/11/2021.
//

import UIKit
import CoreData

protocol StocksController2Delegate {
    func treasuryBondRatesDownloaded()
    func shareUpdateComplete(atPath: IndexPath)
}


class StocksController2: NSFetchedResultsController<Share> {
    
    var treasuryBondYields: [PriceDate]?
    var viewController: StocksListTVC?
    var backgroundMoc: NSManagedObjectContext?
    
    var controllerDelegate: StocksController2Delegate?
    
    // MARK: - FRC functions
    // these use the main MOC
    
    class func allShares() -> [Share]? {

        var shares: [Share]?
        
        let fetchRequest = NSFetchRequest<Share>(entityName: "Share")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "symbol", ascending: true)]
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            shares = try fetchRequest.execute()
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
        fetchRequest.fetchLimit = 1
        
        do {
            share = try fetchRequest.execute().first
            } catch let error {
                ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: error, errorInfo: "error fetching Shares")
        }
        
        return share
    }

    func createShare(with pricePoints: [PricePoint]?, symbol: String, companyName: String?=nil) throws -> Share? {
        
        guard let validPrices = pricePoints else {
            throw InternalErrors.missingPricePointsInShareCreation
        }
        
        let stockName = symbol
        
        let newShare = Share.init(context: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)
        
        newShare.symbol = stockName
        newShare.creationDate = Date()
        newShare.dailyPrices = newShare.convertDailyPricesToData(dailyPrices: validPrices)
        let macds = newShare.calculateMACDs(shortPeriod: 8, longPeriod: 17)
        newShare.macd = newShare.convertMACDToData(macds: macds)
                
        var shortName: String?
        if let dictionary = stockTickerDictionary {
            
            newShare.name_long = companyName ?? dictionary[stockName]
            
            // some dictionary values start with "\" for some reason or other
            // this doesn't work with web addresses when downloading data so needs to be removed
            if (newShare.name_long ?? "").starts(with: "\"") {
                    newShare.name_long = String(newShare.name_long!.dropFirst())
            }

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
                shortName = String(cleanedName.dropLast())
                newShare.name_short = shortName
            }
        }
        
// correct name_short to match MacroTrends requirements.
// if no match will receive re-direction URLRequest via delegate method at bottom leading to corretion of shortName
        shortName = shortName?.replacingOccurrences(of: " ", with: "-")
        let components =  URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(symbol)/\(newShare.name_short ?? "")/revenue")

        Task.init(priority: .background) {
            // will receive redirect delegate call if shortName wrong in MT
            
                if let url = components?.url {
                    NotificationCenter.default.addObserver(self, selector: #selector(awaitingRedirection(notification:)), name: Notification.Name(rawValue: "Redirection"), object: nil) // for MT download redirects

                let test = try await Downloader.mtTestDownload(url: url, delegate: self)
                if (test ?? false) {
                    // correct pageTExt received -> no re-direct delegate call expected
                    NotificationCenter.default.removeObserver(self)
                }
            }
        }

        
        
        // check for any exisisting valuations
        newShare.wbValuation = WBValuationController.returnWBValuations(share: newShare)
        newShare.dcfValuation = CombinedValuationController.returnDCFValuations(company: newShare.symbol!)
        newShare.rule1Valuation = CombinedValuationController.returnR1Valuations(company: newShare.symbol)
        
        return newShare
    }

    func createShare(from file: URL?, companyName: String?=nil, deleteFile: Bool?=false) throws -> Share? {
        
        guard let fileURL = file else {
            throw InternalErrors.missingPricePointsInShareCreation
        }
        
        guard let lastPathComponent = fileURL.lastPathComponent.split(separator: ".").first else {
            throw InternalErrors.urlPathError
        }
        
        let stockName = String(lastPathComponent)
        
        let newShare = Share.init(context: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)
        
        newShare.symbol = stockName
        newShare.creationDate = Date()
        let pricePoints = CSVImporter.extractPricePointsFromFile(url: file, symbol: stockName)
        newShare.dailyPrices = newShare.convertDailyPricesToData(dailyPrices: pricePoints)
        let macds = newShare.calculateMACDs(shortPeriod: 8, longPeriod: 17)
        newShare.macd = newShare.convertMACDToData(macds: macds)
                
        var shortName: String?
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
                shortName = String(cleanedName.dropLast())
                newShare.name_short = shortName
            }
        }
        
        if deleteFile ?? false {
            removeFile(file)
        }
        
        // correct name_short to match MacroTrends requirements.
        // if no match will receive re-direction URLRequest via delegate method at bottom leading to corretion of shortName
        shortName = shortName?.replacingOccurrences(of: " ", with: "-")
        let components =  URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(stockName)/\(shortName ?? "")/revenue")

        Task.init(priority: .background) {
            // will receive redirect delegate call if shortName wrong in MT
            
                if let url = components?.url {
                    NotificationCenter.default.addObserver(self, selector: #selector(awaitingRedirection(notification:)), name: Notification.Name(rawValue: "Redirection"), object: nil) // for MT download redirects

                let test = try await Downloader.mtTestDownload(url: url, delegate: self)
                if (test ?? false) {
                    // correct pageTExt received -> no re-direct delegate call expected
                    NotificationCenter.default.removeObserver(self)
                }
            }
        }

        
        // check for any exisisting valuations
        newShare.wbValuation = WBValuationController.returnWBValuations(share: newShare)
        newShare.dcfValuation = CombinedValuationController.returnDCFValuations(company: newShare.symbol!)
        newShare.rule1Valuation = CombinedValuationController.returnR1Valuations(company: newShare.symbol)
        
        return newShare
    }

    func fetchSpecificShare(symbol: String, fromBackgroundContext: Bool? = false) -> Share? {
        
        let request = NSFetchRequest<Share>(entityName:"Share")
        let predicate = NSPredicate(format: "symbol == %@", argumentArray: [symbol])
        request.predicate = predicate

        request.sortDescriptors = [NSSortDescriptor(key:  "symbol" , ascending:  true )]
        
        if fromBackgroundContext ?? false {
            setBackgroundMOC()
        }
        
        let theContext = (fromBackgroundContext ?? false) ? backgroundMoc! : (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        var shares: [Share]?
        do {
            shares  =  try theContext.fetch(request)
        } catch let error as NSError{
            ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: error, errorInfo: "error fetching Shares")
        }
        
        return shares?.first
    }
    
    // MARK: - other general functions
    
    /// Downloads sector, industry and employee count from Yahoo
    /// saves this to shareID in background
    func downloadProfile(symbol: String, shareID: NSManagedObjectID) async throws {

// Download data first
        var components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)/pfile")
        components?.queryItems = [URLQueryItem(name: "p", value: (symbol))]
        
        guard let validURL = components?.url else {
            throw DownloadAndAnalysisError.urlError
        }

        var profile: ProfileData?
        do {
            profile = try await WebPageScraper2.downloadAndAnalyseProfile(url: validURL)
        } catch let error {
            ErrorController.addErrorLog(errorLocation: "StocksController2 - downloadProfile", systemError: nil, errorInfo: "error downloading profile for \(symbol): \(error)")
        }
        
        guard profile != nil else {
            throw DownloadAndAnalysisError.couldNotFindCompanyProfileData
        }

// then save these to the share in the background
        let backgroundMOC = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        
        do {
            try await backgroundMOC.perform {
            
            guard let backgroundShare = backgroundMOC.object(with: shareID) as? Share else {
                throw InternalErrors.mocReadError
            }
            
            backgroundShare.sector = profile!.sector
            backgroundShare.industry = profile!.industry
            backgroundShare.employees = profile!.employees
            
            try backgroundShare.managedObjectContext?.save()
            }
        } catch let error {
            ErrorController.addErrorLog(errorLocation: "StocksController2 - downloadProfile", systemError: nil, errorInfo: "error saving profile for \(symbol): \(error.localizedDescription)")
        }
                
    }

    
    func removeFile(_ atURL: URL?) {
       
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


    // MARK: - update functions

    func updateStocksData(singleShare: Share?=nil) throws {
        
        if singleShare == nil {
            Task.init(priority: .background) {
                treasuryBondYields = try await updateTreasuryBondYields()
                DispatchQueue.main.async {
                    self.controllerDelegate?.treasuryBondRatesDownloaded()
                }
            }
        }
        
        var sharesToUpdate: [Share]?
        if let validShare = singleShare {
            sharesToUpdate = [validShare]
        } else {
            sharesToUpdate = fetchedObjects?.filter({ share in
                if share.watchStatus < 2 { return true }
                else { return false }
            })
        }
        
        let now = Date()
        sharesToUpdate = sharesToUpdate?.filter({ share in
            if now.timeIntervalSince(share.lastLivePriceDate ?? now) < 300 { return false }
            else { return true }
        })
        
        //TODO: - create two methods: livePriceupdate() and qEarningsUpdate
        // two groups of filetere shares: 1. as here if last lic price date < 300
        // the other to be passed to qEarningsUpdate filtered by last qEarnigsDate > 3 months
        
        let compDate = Date()
        sharesToUpdate = sharesToUpdate?.sorted(by: { s0, s1 in
            if (s0.lastLivePriceDate ?? compDate) < (s1.lastLivePriceDate ?? compDate) { return true
            }  else { return false }
        })
        
        var dateDict = [String: Date?]()
        var orderedDict = [ShareNamesDictionary]() // ordered by lastLivePriceUPdate
        
        for share in sharesToUpdate ?? [] {
            let new = ShareNamesDictionary(symbol: share.symbol ?? "", shortName: share.name_short ?? "")
            orderedDict.append(new)
            dateDict[share.symbol ?? ""] = share.priceDateRange()?.first
        }
        
        backgroundMoc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc!.automaticallyMergesChangesFromParent = true

//        guard let validBackgroundMOC = backgroundMoc else {
//            throw DownloadAndAnalysisError.noBackgroundMOC
//        }

        NotificationCenter.default.addObserver(self, selector: #selector(backgroundContextDidSave(notification:)), name: .NSManagedObjectContextDidSave, object: nil)
        
        let dict = orderedDict
        let dDict = dateDict
        
        let cookieStore = HTTPCookieStorage.shared
        for cookie in cookieStore.cookies ?? [] {
            cookieStore.deleteCookie(cookie)
        }
        
        
        Task.init(priority: .background, operation: {
            
            for dictionaryObject in dict {

                let time = Date()
                print("updating share \(dictionaryObject.symbol)")
                          
                let labelledPrice = try await updateCurrentPrice(shareSymbol: dictionaryObject.symbol)
                let minDate = dDict[dictionaryObject.symbol] ?? nil
                let labelled_datedqEarnings = try await quarterlyEarningsUpdate(shareSymbol: dictionaryObject.symbol, shortName: dictionaryObject.shortName, minDate: minDate)
                
                guard labelledPrice.value != nil || labelled_datedqEarnings?.datedValues != nil else {
                    continue
                }
                
                await backgroundMoc?.perform({
                    let request = NSFetchRequest<Share>(entityName: "Share")
                    let predicate = NSPredicate(format: "symbol == %@", argumentArray: [dictionaryObject.symbol])
                    
                    request.predicate = predicate
                    do {
                        guard let backgroundShare = try self.backgroundMoc?.fetch(request).first else {
                            throw DownloadAndAnalysisError.noBackgroundShareWithSymbol
                        }
                        
                        if let valid = labelledPrice.value {
                            backgroundShare.lastLivePrice = valid
                            backgroundShare.lastLivePriceDate = Date()
                        }
                        if let valid = labelled_datedqEarnings?.datedValues {
                            backgroundShare.wbValuation?.saveEPSWithDateArray(datesValuesArray: valid, saveToMOC: false)
                        }
                        
                        try backgroundShare.managedObjectContext?.save()
                        print("updating \(dictionaryObject.symbol) took \(Date().timeIntervalSince(time))")
                        
                        let id = backgroundShare.objectID
                        
                        DispatchQueue.main.async {
                            self.updateCompleteToDelegate(id: id)
                        }
                    } catch let error {
                        ErrorController.addErrorLog(errorLocation: "StocksController2.updateStocksData", systemError: error, errorInfo: "error fetching from and/or saving backgroundMOC")
                    }
                    
                })
            }
        })
    }
    
    /// must be called on main thread
    func updateCompleteToDelegate(id: NSManagedObjectID) {
        
        let updatedShare = managedObjectContext.object(with: id) as! Share
        if let path = self.indexPath(forObject: updatedShare) {
            controllerDelegate?.shareUpdateComplete(atPath: path)
        }
    }
    
    //MARK: - specific update task functions
    
    func updateCurrentPrice(shareSymbol: String) async throws -> LabelledValue {
                
        var components: URLComponents?
                
        components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(shareSymbol)")
        components?.queryItems = [URLQueryItem(name: "p", value: shareSymbol), URLQueryItem(name: ".tsrc", value: "fin-srch")]
        
        guard let validURL = components?.url else {
            throw DownloadAndAnalysisError.urlError
        }
        
        var price: Double?
        do {
            try await price = WebPageScraper2.getCurrentPrice(url: validURL)
            return (shareSymbol, price)

        } catch let error as DownloadAndAnalysisError {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "a background download or analysis error for \(shareSymbol) occurred: \(error)")
        }
        return (shareSymbol, nil)
    }
    
    func quarterlyEarningsUpdate(shareSymbol: String, shortName: String, minDate: Date?=nil) async throws -> Labelled_DatedValues? {
                
        var sn = shortName
        if sn.contains(" ") {
            sn = sn.replacingOccurrences(of: " ", with: "-").lowercased()
        }
        
        guard let components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(shareSymbol)/\(sn)/pe-ratio") else {
            throw DownloadAndAnalysisError.urlInvalid
        }
        
        guard let url = components.url else {
            throw DownloadAndAnalysisError.urlError
        }
        
        var values: [Dated_EPS_PER_Values]?
        
        do {
            values = try await WebPageScraper2.getHxEPSandPEData(url: url, companyName: sn, until: minDate, downloadRedirectDelegate: self)
        }  catch let error as DownloadAndAnalysisError {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "a background download or analysis error for \(shareSymbol) occurred: \(error)")
        }
        
        guard let epsDates = values?.compactMap({ DatedValue(date: $0.date, value: $0.epsTTM) }) else {
            return nil
        }
        return Labelled_DatedValues(label: shareSymbol, datedValues: epsDates)

    }

    func updateTreasuryBondYields() async throws -> [PriceDate]? {
        
        if let lastDate = treasuryBondYields?.compactMap({ $0.date }).sorted().last {
            if Date().timeIntervalSince(lastDate) < 14*3600 {
                return nil
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
            throw DownloadAndAnalysisError.urlError
        }
        
        do {
            return try await WebPageScraper2.downloadAndAanalyseTreasuryYields(url: url)
        } catch let error {
            throw error
        }
        

    }
        
    
    // MARK: - ManagedObjectContext
    func setBackgroundMOC() {
        backgroundMoc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc!.automaticallyMergesChangesFromParent = true
    }
    
    func saveBackgroundMOC(share: Share) throws {
        
        guard let moc = backgroundMoc else {
            throw InternalErrors.noValidBackgroundMOC
        }
        
        if share.hasChanges {
            moc.performAndWait {
                do {
                    try moc.save()
                } catch let error {
                    ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "a background update error for \(share.symbol ?? "missing") occurred: can't save to background MOC: \(error.localizedDescription)")
                }
            }
        }

    }
    
    @objc
    func backgroundContextDidSave(notification: Notification) {
        
//        print("moc did save notification received")
        if let _ = notification.object as? NSManagedObjectContext {
            
            DispatchQueue.main.async {
                (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.perform {
                    (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.mergeChanges(fromContextDidSave: notification)
                    
                }
            }
        }

    }

}

extension StocksController2: DownloadRedirectionDelegate {
    
    func awaitingRedirection(notification: Notification) {
        
        NotificationCenter.default.removeObserver(self)
        
        if let request = notification.object as? URLRequest {
            if let url = request.url {
                var components = url.pathComponents.dropLast()
                if let component = components.last {
                    let mtShortName = String(component)
                    components = components.dropLast()
                    if let symbolComponent = components.last {
                        let symbol = String(symbolComponent)
                        
                        DispatchQueue.main.async {
                            if let share = self.fetchedObjects?.filter({ share in
                                if share.symbol == symbol { return true }
                                else { return false }
                            }).first {
                                share.name_short = mtShortName
                                do {
                                    try share.managedObjectContext?.save()
                                } catch let error {
                                    ErrorController.addErrorLog(errorLocation: "StocksController2.awaitingRedirection", systemError: error, errorInfo: "couldn't save \(symbol) in it's MOC after downlaod re-direction")
                                }
                                
                                if let info = notification.userInfo as? [String:Any] {
                                    if let task = info["task"] as? DownloadTask {
                                        switch task {
                                        case .epsPER:
                                            do {
                                                try self.updateStocksData(singleShare: share)
                                            } catch let error {
                                                print("StocksController2: error updating \(symbol) after redirect \(error.localizedDescription)")
                                            }
                                            print("StocksController2: redirect for \(symbol) epsPER task recevied")
                                        case .test:
                                            print("StocksController2: redirect for \(symbol) test task recevied")
                                        case .wbValuation:
                                            print("StocksController2: redirect for \(symbol) wbValuation task recevied")
                                        case .r1Valuation:
                                            print("StocksController2: redirect for \(symbol) r1V task recevied")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? {
           
        let object = request
        let notification = Notification(name: Notification.Name(rawValue: "Redirection"), object: object, userInfo: nil)
        NotificationCenter.default.post(notification)

        return nil
    }
}
