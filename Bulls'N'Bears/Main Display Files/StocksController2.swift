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
    
    var treasuryBondYields: [DatedValue]?
    var viewController: StocksListTVC?
    var backgroundMoc: NSManagedObjectContext?
    var sharesAwaitingUpdateDownload: [Share]? // to check if/when all share update download are complete
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

    /// downloads daily prices, EPS/ qEPS, PER, live prices and tBond data
    /// updates MAC-Ds
    func updateStocksData(singleShare: Share?=nil) throws {
        
        if singleShare == nil {
            Task.init(priority: .background) {
                NotificationCenter.default.addObserver(self, selector: #selector(tBondDownloadAndAnalysisComplete(notification:)), name: Notification.Name(rawValue: "TBOND csv file downloaded"), object: nil)
                try await updateTreasuryBondYields()
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
        
        sharesAwaitingUpdateDownload = sharesToUpdate
        
        let now = Date()
        let dateForNil = now.addingTimeInterval(-301)
        sharesToUpdate = sharesToUpdate?.filter({ share in
            if now.timeIntervalSince(share.lastLivePriceDate ?? dateForNil) < nonRefreshTimeInterval { return false }
            else { return true }
        })
        
        
        let compDate = Date()
        sharesToUpdate = sharesToUpdate?.sorted(by: { s0, s1 in
            if (s0.lastLivePriceDate ?? compDate) < (s1.lastLivePriceDate ?? compDate) { return true
            }  else { return false }
        })
                
        backgroundMoc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc!.automaticallyMergesChangesFromParent = true

        NotificationCenter.default.addObserver(self, selector: #selector(backgroundContextDidSave(notification:)), name: .NSManagedObjectContextDidSave, object: nil)
        
        for share in sharesToUpdate ?? [] {
            
            updateUserAndValueScores(share: share)
        
            let symbol = share.symbol ?? ""
            let shortName = share.name_short ?? ""
            let existingPricePoints = share.getDailyPrices()
            let shareID = share.objectID
            let minDate = share.priceDateRange()?.first?.addingTimeInterval(-365*24*3600)
            let latestQEPSDate = share.wbValuation?.epsQWithDates()?.last?.date
            
            Task.init(priority: .background, operation: {
                
                let labelledPrice = try await getCurrentPriceForUpdate(shareSymbol: symbol)
                
                let labelled_datedQEPS = try await getQuarterlyEarningsForUpdate(shareSymbol: symbol, shortName: shortName, minDate: minDate, latestQEPSDate: latestQEPSDate)
                
                let updatedPricePoints = try await getDailyPricesForUpdate(shareSymbol: symbol, existingDailyPrices: existingPricePoints)
                
                await backgroundMoc?.perform({
                    
                    do {
                        guard let backgroundShare = self.backgroundMoc?.object(with: shareID) as? Share else {
                            throw DownloadAndAnalysisError.noBackgroundShareWithSymbol
                        }
                        
                        if let valid = labelledPrice.value {
                            backgroundShare.lastLivePrice = valid
                            backgroundShare.lastLivePriceDate = Date()
                        }
                                                
                        if let valid = labelled_datedQEPS?.datedValues {
                            backgroundShare.wbValuation?.saveQEPSWithDateArray(datesValuesArray: valid, saveToMOC: false)
                        }

                        if let valid = backgroundShare.wbValuation?.epsTTMFromQEPSArray(datedValues:labelled_datedQEPS?.datedValues) {
                            backgroundShare.wbValuation?.saveEPSTTMWithDateArray(datesValuesArray: valid, saveToMOC: false)
                        }

                        if let valid = updatedPricePoints {
                            backgroundShare.setDailyPrices(pricePoints: valid, saveInMOC: false)
                            backgroundShare.reCalculateMACDs(newPricePoints: valid, shortPeriod: 8, longPeriod: 17)
                        }
                        
                        try backgroundShare.managedObjectContext?.save()
                        
                        DispatchQueue.main.async {
                           self.updateCompleteToDelegate(id: shareID)
                        }
                    } catch let error {
                        ErrorController.addErrorLog(errorLocation: "StocksController2.updateStocksData", systemError: error, errorInfo: "error fetching from and/or saving backgroundMOC")
                    }
                    
                })
            })
        }
    }
    
    /// checks up-to-date status of, and downloads DCF-, R1- and WB-Valuation data
    /// updates trends
    func updateStockInformation(singleShare: Share?=nil) {
        
        print("beginning to update share background infos...")
        
        var sharesToUpdate: [Share]?
        if let validShare = singleShare {
            sharesToUpdate = [validShare]
        } else {
            sharesToUpdate = fetchedObjects?.filter({ share in
                if share.watchStatus < 2 { return true }
                else { return false }
            })
        }

        for share in sharesToUpdate ?? [] {
            
            let symbol = share.symbol
            
            if (share.dcfValuation?.creationDate ?? Date()).timeIntervalSince(Date()) > 365*24*3600/12 {
                // refresh dcf valuation
                // save new dcfvalue as trend
                
                if let dcfValuationID = share.dcfValuation?.objectID {
                    let dcfv = managedObjectContext.object(with: dcfValuationID) as! DCFValuation
                    let (value,_) = dcfv.returnIValue()
                    if value != nil {
                        let trendValue = DatedValue(date: dcfv.creationDate!, value: value!)
                        share.saveTrendsData(datedValuesToAdd: [trendValue], trendName: .dCFValue)
                    }

                    Task(priority: .background) {
                        do {
                            try await WebPageScraper2.dcfDataDownloadAndSave(shareSymbol: symbol, valuationID: dcfValuationID, progressDelegate: nil)
                            //                        try Task.checkCancellation()
                        } catch let error {
                            ErrorController.addErrorLog(errorLocation: "StocksController2.updateStockInformation.dcfValuation", systemError: error, errorInfo: "Error downloading DCF valuation: \(error)")
                        }
                    }
                }
            }
            
            if (share.rule1Valuation?.creationDate ?? Date()).timeIntervalSince(Date()) > 365*24*3600/12 {
                // refresh rule 1 valuation
                // save new r1 moat and sticker price as trend
                
                let shortName = share.name_short
                if let r1ValuationID = share.rule1Valuation?.objectID {
                    
                    // save existing values if necessary
                    let r1v = managedObjectContext.object(with: r1ValuationID) as! Rule1Valuation
                    if let moat = r1v.moatScore() {
                        let trendValue = DatedValue(date: r1v.creationDate!, value: moat)
                        share.saveTrendsData(datedValuesToAdd: [trendValue], trendName: .moatScore)
                    }
                    let (value2, _) = r1v.stickerPrice()
                    if value2 != nil {
                        let trendValue = DatedValue(date: r1v.creationDate!, value: value2!)
                        share.saveTrendsData(datedValuesToAdd: [trendValue], trendName: .stickerPrice)
                    }
                    
                    
                    Task(priority: .background) {
                        
                        do {
                            let _ = try await WebPageScraper2.r1DataDownloadAndSave(shareSymbol: symbol, shortName: shortName, valuationID: r1ValuationID, progressDelegate: nil, downloadRedirectDelegate: self)
                            try Task.checkCancellation()
                        } catch let error {
                            ErrorController.addErrorLog(errorLocation: "StocksController2.updateSharesInfo.r1Valuation", systemError: error, errorInfo: "Error downloading R1 valuation: \(error)")
                        }
                        
                    }
                }
            }
            
            if (share.wbValuation?.date ?? Date()).timeIntervalSince(Date()) > 365*24*3600/12 {
                // refresh WB valuation 
                // save intrinsic value as trend in Share
                
                let shortName = share.name_short
                let shareID = share.objectID
                if let wbValuationID = share.wbValuation?.objectID {
                    
                    let wbv = managedObjectContext.object(with: wbValuationID) as! WBValuation
                    if let lynch = wbv.lynchRatio() {
                        let trendValue = DatedValue(date: wbv.date!, value: lynch)
                        share.saveTrendsData(datedValuesToAdd: [trendValue], trendName: .lynchScore)
                    }
                    let (value2, _) = wbv.ivalue()
                    if value2 != nil {
                        let trendValue = DatedValue(date: wbv.date!, value: value2!)
                        share.saveTrendsData(datedValuesToAdd: [trendValue], trendName: .intrinsicValue)
                    }

                    Task(priority: .background) {
                        do {
                            try await WebPageScraper2.downloadAnalyseSaveWBValuationData(shareSymbol: symbol, shortName: shortName, valuationID: wbValuationID, downloadRedirectDelegate: self)
                            try await WebPageScraper2.keyratioDownloadAndSave(shareSymbol: symbol, shortName: shortName, shareID: shareID)
                        } catch let error {
                            ErrorController.addErrorLog(errorLocation: "StocksController2.updateSharesInfo.wbValuation", systemError: error, errorInfo: "Error downloading R1 valuation: \(error)")
                        }

                    }
                }
            }

            
        }
        
        
    }
    
    /// must be called on main thread
    func updateCompleteToDelegate(id: NSManagedObjectID) {
        
        let updatedShare = managedObjectContext.object(with: id) as! Share
        
        if let sau = sharesAwaitingUpdateDownload {
            for i in 0..<sau.count {
                if sau[i].isEqual(updatedShare) {
                    sharesAwaitingUpdateDownload?.remove(at: i)
                }
            }
        }
        
        if let path = self.indexPath(forObject: updatedShare) {
            controllerDelegate?.shareUpdateComplete(atPath: path)
        }
        
        if (sharesAwaitingUpdateDownload?.count ?? 0) == 0 {
            updateStockInformation()
        }
    }
    
    //MARK: - specific update task functions
    
    /// returns (shareSymbol, current tickerPrice)
    func getCurrentPriceForUpdate(shareSymbol: String) async throws -> LabelledValue {
                
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
    
    func updateUserAndValueScores(share: Share) {
        
        let calendar = Calendar.current
        let components: Set<Calendar.Component> = [.day]
        let dateComponents = calendar.dateComponents(components, from: Date())
        
        if (dateComponents.day ?? 0) > 3 { return } // routinel update only during first 3 days each month

        let valueRatingData = share.wbValuation?.valuesSummaryScores()
        let userRatingData = share.wbValuation?.userEvaluationScore()
        
        if let score = valueRatingData?.ratingScore() {
            share.valueScore = score
        }
        if let score = userRatingData?.ratingScore() {
            share.userEvaluationScore = score
        }
        
        
        do {
            try share.managedObjectContext?.save()
        } catch let error {
            ErrorController.addErrorLog(errorLocation: "StocksController2.updateUserAndValueScores", systemError: error, errorInfo: "error trying to save updated user and value scores")
        }
    }
    
    func getQuarterlyEarningsTTMForUpdate(shareSymbol: String, shortName: String, minDate: Date?=nil) async throws -> Labelled_DatedValues? {
                
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
        
        let epsDates = values?.compactMap({ DatedValue(date: $0.date, value: $0.epsTTM) })
        let labelledValues = Labelled_DatedValues(label: shareSymbol, datedValues: epsDates ?? [])
                
        return labelledValues

    }
    
    func getQuarterlyEarningsForUpdate(shareSymbol: String, shortName: String, minDate: Date?=nil, latestQEPSDate: Date?) async throws -> Labelled_DatedValues? {
                
        if let valid = latestQEPSDate {
            if Date().timeIntervalSince(valid) < 80*24*3600 {
                return nil
            }
        }
        
        var sn = shortName
        if sn.contains(" ") {
            sn = sn.replacingOccurrences(of: " ", with: "-").lowercased()
        }
        
//        guard let components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(shareSymbol)/\(sn)/eps-earnings-per-share-diluted") else {
//            throw DownloadAndAnalysisError.urlInvalid
//        }
        
        guard let ycharts_url = URL(string: ("https://ycharts.com/companies/" + shareSymbol.uppercased() + "/eps")) else {
            throw DownloadAndAnalysisError.urlError
        }
                
        var values: [DatedValue]?
        
        do {
            values = try await WebPageScraper2.getqEPSDataFromYCharts(url: ycharts_url, companyName: sn, until: minDate, downloadRedirectDelegate: self)
        }  catch let error as DownloadAndAnalysisError {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "a background download or analysis error for \(shareSymbol) occurred: \(error)")
        }
        

        return Labelled_DatedValues(label: shareSymbol, datedValues: values ?? [])

    }

    /// returns [PricePoints] sorted by date  with new daily trading prices added
    /// or nil if there were no new price points
    func getDailyPricesForUpdate(shareSymbol: String, existingDailyPrices: [PricePoint]?) async throws -> [PricePoint]? {

//        let weekDay = Calendar.current.component(.weekday, from: Date())
//        guard (weekDay > 1 && weekDay < 7) else {
//            return nil
//        }
        
        
        if let lastPriceDate = existingDailyPrices?.last?.tradingDate {
            guard (Date().timeIntervalSince(lastPriceDate) > 12 * 3600) else {
                return nil
            }
        }
        

        let minDate = existingDailyPrices?.last?.tradingDate

//        print("downloading daily prices for \(shareSymbol) last price date \(minDate!)")

        if let downloadedDailyPrices = try await WebPageScraper2.downloadAndAnalyseDailyTradingPrices(shareSymbol: shareSymbol, minDate: minDate) {
            
            guard let existingPricePoints = existingDailyPrices else {
                return downloadedDailyPrices
            }

            var pricePointsSet = Set<PricePoint>(existingPricePoints)
            pricePointsSet = pricePointsSet.union(downloadedDailyPrices)
            
            let sorted = Array(pricePointsSet).sorted { e0, e1 in
                if e0.tradingDate < e1.tradingDate { return true }
                else { return false }
            }

//            print(sorted)
            
            
            return sorted
        }
        
        return nil
    }

    /// requests CSV file download from WebScraper 2, involving Downloaeder with completion handler
    /// returns Notification with object [DatedValue], with name "TBOND csv file downloaded"
    func updateTreasuryBondYields() async throws {
        
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
        
        // to download .html file: "https://home.treasury.gov/resource-center/data-chart-center/interest-rates/TextView?type=daily_treasury_yield_curve&field_tdr_date_value=2022"
        
//        var urlComponents = URLComponents(string: "https://home.treasury.gov/resource-center/data-chart-center/interest-rates/daily-treasury-rates.csv/2022/all?type=daily_treasury_yield_curve&field_tdr_date_value=2022&page&_format=csv" )
//        urlComponents?.queryItems = [URLQueryItem(name: "data", value: "yieldYear"),URLQueryItem(name: "year", value: year$)]
//        // until 4.2.22: "https://www.treasury.gov/resource-center/data-chart-center/interest-rates/pages/TextView.aspx"
//
//        guard let url = urlComponents?.url else {
//            throw DownloadAndAnalysisError.urlError
//        }
        
        guard let url = URL(string: "https://home.treasury.gov/resource-center/data-chart-center/interest-rates/daily-treasury-rates.csv/"+year$+"/all?type=daily_treasury_yield_curve&field_tdr_date_value="+year$+"&page&_format=csv") else {
            throw DownloadAndAnalysisError.urlError
        }
        
        await WebPageScraper2.downloadAndAanalyseTreasuryYields(url: url)
        
    }
    
    @objc
    func tBondDownloadAndAnalysisComplete(notification: Notification) {
        if let datedValues = notification.object as? [DatedValue] {
            self.treasuryBondYields = datedValues
            
            DispatchQueue.main.async {
                self.controllerDelegate?.treasuryBondRatesDownloaded()
            }

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
        
        if let _ = notification.object as? NSManagedObjectContext {
            
            DispatchQueue.main.async {
                (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.perform {
                    (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.mergeChanges(fromContextDidSave: notification)
                    
//                    do {
//                        try (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.save()
//                    } catch {
//                        ErrorController.addErrorLog(errorLocation: "StocksController 2.backgroundContextDidSave", systemError: error, errorInfo: "Can't save main MOC after merging changes from background MOC")
//                    }
                    
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
                                                ErrorController.addErrorLog(errorLocation: "StocksController2.awaitingRedirection", systemError: error, errorInfo: "error updating \(symbol) after redirect")
                                            }
                                        case .test:
                                            print("StocksController2: redirect for \(symbol) test task recevied")
                                        case .wbValuation:
                                            print("StocksController2: redirect for \(symbol) wbValuation task recevied")
                                        case .r1Valuation:
                                            print("StocksController2: redirect for \(symbol) r1V task recevied")
                                        case .qEPS:
                                            print("WBValuationController: redirect for \(symbol) qEPS task received")
                                        case .healthData:
                                            print("FinHealthController: redirect for \(symbol) healthData task received")
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
