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
}


class StocksController2: NSFetchedResultsController<Share> {
    
    var treasuryBondYields: [PriceDate]?
    var viewController: StocksListTVC?
    var backgroundMoc: NSManagedObjectContext?
    
    var tbRatesDelegate: StocksController2Delegate?
    
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

    class func createShare(with pricePoints: [PricePoint]?, symbol: String, companyName: String?=nil) throws -> Share? {
        
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
                newShare.name_short = String(cleanedName.dropLast())
            }
        }
        
        // check for any exisisting valuations
        newShare.wbValuation = WBValuationController.returnWBValuations(share: newShare)
        newShare.dcfValuation = CombinedValuationController.returnDCFValuations(company: newShare.symbol!)
        newShare.rule1Valuation = CombinedValuationController.returnR1Valuations(company: newShare.symbol)
        
        return newShare
    }

    class func createShare(from file: URL?, companyName: String?=nil, deleteFile: Bool?=false) throws -> Share? {
        
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


    // MARK: - update functions

    func updateStocksData() async throws {
        
        backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc!.automaticallyMergesChangesFromParent = true

        guard let validBackgroundMOC = backgroundMoc else {
            throw DownloadAndAnalysisError.noBackgroundMOC
        }

        NotificationCenter.default.addObserver(self, selector: #selector(backgroundContextDidSave(notification:)), name: .NSManagedObjectContextDidSave, object: nil)
        
        var shareIDs_prices = [ShareID_Value]()
        var currentPriceIDSymbols = [ShareID_Symbol_sName]()
        var qEarningsIDSymbols = [ShareID_Symbol_sName]()
        var shareIDs_datedEPS = [ShareID_DatedValues]()
        
        for share in fetchedObjects ?? [] {
            
            let newObject = ShareID_Symbol_sName(id: share.objectID, symbol: share.symbol, shortName: share.name_short)
            currentPriceIDSymbols.append(newObject)
            
            guard share.watchStatus < 2 else {
                continue
            }
            
            guard let wbv = share.wbValuation else {
                continue
            }
            
            guard let historicEPS = wbv.epsWithDates() else {
                continue
            }
            
            if (historicEPS.last?.date ?? Date()) > Date().addingTimeInterval(-91*24*3600) { continue }
            
            qEarningsIDSymbols.append(newObject)
        }
            
        for object in currentPriceIDSymbols {
            shareIDs_prices.append(try await updateCurrentPrice(shareSymbol: object.symbol, shareID: object.id))
        }
        
        for object in qEarningsIDSymbols {
            do {
                shareIDs_datedEPS.append(try await quarterlyEarningsUpdate(shareSymbol: object.symbol, shortName: object.shortName, shareID: object.id))
            } catch let error {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "qEarnings update error \(error) for \(object.shortName ?? "missing")")
            }
        }
            
        await validBackgroundMOC.perform {
            
            do {
                let request = NSFetchRequest<Share>(entityName: "Share")
                let backgroundShares = try validBackgroundMOC.fetch(request)
                
                for backgroundShare in backgroundShares {
                    if let match = shareIDs_prices.filter({ object in
                        if object.id == backgroundShare.objectID { return true }
                        else { return false }
                    }).first {
                        if let validPrice = match.value {
                            backgroundShare.lastLivePrice = validPrice
                            backgroundShare.lastLivePriceDate = Date()
                       }
                    }
                    
                    if let match = shareIDs_datedEPS.filter({ object in
                        if object.id == backgroundShare.objectID { return true }
                        else { return false }
                    }).first {
                        if let datedEPS = match.values {
                            backgroundShare.wbValuation?.saveEPSWithDateArray(datesValuesArray: datedEPS,saveToMOC: false)
                       }
                    }
                }
                
                try self.backgroundMoc?.save()
            } catch let error {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "couldn't save background MOC")
            }
        }
        
        treasuryBondYields = try await updateTreasuryBondYields()
        DispatchQueue.main.async {
            self.tbRatesDelegate?.treasuryBondRatesDownloaded()
        }
        
    }
    
    //MARK: - specific update task functions
    
    func updateCurrentPrice(shareSymbol: String?, shareID: NSManagedObjectID) async throws -> ShareID_Value {
        
        guard let symbol = shareSymbol else {
            throw DownloadAndAnalysisError.shareSymbolMissing
        }
        
        var components: URLComponents?
                
        components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)")
        components?.queryItems = [URLQueryItem(name: "p", value: symbol), URLQueryItem(name: ".tsrc", value: "fin-srch")]
        
        guard let validURL = components?.url else {
            throw DownloadAndAnalysisError.urlError
        }
        
        var price: Double?
        do {
            try await price = WebPageScraper2.getCurrentPrice(url: validURL)
            return (shareID, price)

        } catch let error as DownloadAndAnalysisError {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "a background download or analysis error for \(symbol) occurred: \(error)")
        }
        return (shareID, nil)
    }
    
    func quarterlyEarningsUpdate(shareSymbol: String?, shortName: String? , shareID: NSManagedObjectID) async throws -> ShareID_DatedValues {
        
        guard let symbol = shareSymbol else {
            throw DownloadAndAnalysisError.shareSymbolMissing
        }
        
        guard var shortName = shortName else {
            throw DownloadAndAnalysisError.shareShortNameMissing
        }
        
        if shortName.contains(" ") {
            shortName = shortName.replacingOccurrences(of: " ", with: "-")
        }
        
        guard let components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(symbol)/\(shortName)/pe-ratio") else {
            throw DownloadAndAnalysisError.urlInvalid
            }
        
        guard let url = components.url else {
            throw DownloadAndAnalysisError.urlError
        }
        
        var values: [Dated_EPS_PER_Values]?
        
        do {
            values = try await WebPageScraper2.getHxEPSandPEData(url: url, companyName: shortName, until: nil)
        }  catch let error as DownloadAndAnalysisError {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "a background download or analysis error for \(shareSymbol ?? "missing") occurred: \(error)")
        }
        
        let epsDates = values?.compactMap{ DatedValue(date: $0.date, value: $0.epsTTM) }
        return ShareID_DatedValues(id: shareID, values: epsDates)

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
