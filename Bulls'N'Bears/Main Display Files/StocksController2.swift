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
    func singleShareUpdateComplete(atPath: IndexPath)
}


class StocksController2: NSFetchedResultsController<Share> {
    
    let renewInterval: TimeInterval = 365*24*3600/12
    var treasuryBondYields: [DatedValue]?
    var viewController: StocksListTVC?
//    var backgroundMoc: NSManagedObjectContext?
    var sharesAwaitingUpdateDownload: [Share]? // to check if/when all share update download are complete
    var controllerDelegate: StocksController2Delegate?
    var shareInfosToDownload = 0
    var webViewDownloader: WebViewDownloader?

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
                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "error fetching Shares")
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
                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "error fetching Share \(symbol)")
        }
        
        return share
    }
    
    /// using yahoo as source; gets profile, Hx dividends and return data
    /// send either url, OR pricePoints with symbol. companyName is an optional long name for the company to override the name found in the stocksDictionary
    func getDataForNewShare(objectID: NSManagedObjectID, url: URL?, symbol: String?, progressDelegate: ProgressViewDelegate?) async throws {
        
        let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc.automaticallyMergesChangesFromParent = true
        
        guard let newShare = backgroundMoc.object(with: objectID) as? Share else {
            AlertController.shared().showDialog(title: "Not completed", alertMessage: "new share object couldn;t fetched from background MOC")
            return
        }
        
        guard symbol != nil else {
            AlertController.shared().showDialog(title: "Not completed", alertMessage: "new share object did not have valid symbol")
            return
        }
        
        guard symbol != nil else {
            AlertController.shared().showDialog(title: "Not completed", alertMessage: "new share object did not have valid symbol")
            return
        }

        guard newShare.name_short != nil else {
            AlertController.shared().showDialog(title: "Not completed", alertMessage: "new share object did not have valid short name")
            return

        }
        
        guard newShare.name_long != nil else {
            AlertController.shared().showDialog(title: "Not completed", alertMessage: "new share object \(String(describing: symbol)) did not have valid long name \(String(describing: newShare.name_long))")
            return

        }

        // download company profile data
        // Download data first
        shareInfosToDownload = 1
        
        progressDelegate?.allTasks = 1 + MacrotrendsScraper.countOfRowsToDownload(option: .screeningInfos) + YahooPageScraper.countOfRowsToDownload(option: .screeningInfos)
        
        async let datedDividends = YahooPageScraper.dividendsHxFileDownload(symbol: symbol!, companyName: newShare.name_short ?? "missing", years: 10)
                        
        await YahooPageScraper.dataDownloadAnalyseSave(symbol: symbol!, shortName: newShare.name_short ?? "missing", shareID: objectID, option: .screeningInfos, progressDelegate: progressDelegate, downloadRedirectDelegate: self)
        
        await dividendsAndReturns(shareID: newShare.objectID, pricesCsvURL: url)
        
        if (newShare.currency ?? "USD") == "USD" {
            await MacrotrendsScraper.dataDownloadAnalyseSave(shareSymbol: newShare.symbol ?? "", shortName: newShare.name_short ?? "missing", shareID: objectID, downloadOption: .screeningInfos, progressDelegate: progressDelegate,downloadRedirectDelegate: self)
        }
        else {
            // non-macrotrends screening data download options here
            await WebPageScraper2.nonUSDataDownload(symbol: newShare.symbol ?? "", shortName: newShare.name_short ?? "missing", shareID: objectID)
            let longName = newShare.name_long!
            let cu = newShare.currency
            
            DispatchQueue.main.async {
                
                self.webViewDownloader = WebViewDownloader.newWebViewDownloader(delegate: self.viewController!)
                self.webViewDownloader?.downloadPage(domain: "https://www.boerse-frankfurt.de/equity", companyName: longName, pageName: "key-data", currency: cu, shareID: objectID, in: self.viewController!)
            }
            
        }
        
        newShare.saveDividendData(datedValues: await datedDividends, save: true)
        
        do {
            try backgroundMoc.save()
        } catch {
            ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "error trying to save new share \(String(describing: symbol))")
        }
                
        // update all other share data
        DispatchQueue.main.async {

            progressDelegate?.downloadComplete()
            
            do {
                try self.updateStocksData(singleShareID: newShare.objectID)
            } catch {
                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "couldn't update data for \(newShare.symbol!)")
            }
        }
        
        if let validURL = url {
            removeFile(validURL)
        }
        
    }
    
    /// using yahoo as source
    func dividendsAndReturns(shareID: NSManagedObjectID, pricesCsvURL: URL?) async {
        
        let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc.automaticallyMergesChangesFromParent = true

        
        guard let share = backgroundMoc.object(with: shareID) as? Share else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "Failed to convert shareID to Share from background MOC")
            return
        }
        
        var pricesCSVurl = pricesCsvURL
        
        if pricesCsvURL == nil {
            
            let nowSinceRefDate = yahooPricesStartDate.timeIntervalSince(yahooRefDate) // 10 years back!
            let yearAgoSinceRefDate = yahooPricesEndDate.timeIntervalSince(yahooRefDate)

            let start$ = numberFormatter.string(from: nowSinceRefDate as NSNumber) ?? ""
            let end$ = numberFormatter.string(from: yearAgoSinceRefDate as NSNumber) ?? ""
            
            var urlComponents = URLComponents(string: "https://query1.finance.yahoo.com/v7/finance/download/\(share.symbol!)")
            urlComponents?.queryItems = [URLQueryItem(name: "period1", value: start$),URLQueryItem(name: "period2", value: end$),URLQueryItem(name: "interval", value: "1d"), URLQueryItem(name: "events", value: "history"), URLQueryItem(name: "includeAdjustedClose", value: "true") ]
            
            
            if let sourceURL = urlComponents?.url {
                
                // first try to download historical prices from Yahoo finance as CSV file
                let expectedHeaderTitles = ["Date","Open","High","Low","Close","Adj Close","Volume"]
                
                do {
                    if let csvURL = try await Downloader.downloadCSVFile2(url: sourceURL, symbol: share.symbol!, type: "_PPoints") {
                        if CSVImporter.matchesExpectedFormat(url: csvURL, expectedHeaderTitles: expectedHeaderTitles) {
                            pricesCSVurl = csvURL
                        }
                    }
                }
                catch {
                    ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "error downloading and analysing dividend payment data")
                }
            }
            
            }
        
            async let datedDividends = YahooPageScraper.dividendsHxFileDownload(symbol: share.symbol!, companyName: share.name_short ?? "", years: 10)
            share.saveDividendData(datedValues: await datedDividends, save: false) // saved in bgMOC below
        
            // if pricePoint csv file is available calculate 3 and 10 year returns
            if let fileURL = pricesCSVurl {
                
                do {
                    if let dDivs = await datedDividends {
                        
                        let threeYearsAgo = Date().addingTimeInterval(-3*year)
                        let tenYearsAgo = Date().addingTimeInterval(-10*year)
                        
                        let price3yAgo = CSVImporter.extractPricePointsFromFile(url: fileURL,symbol: share.symbol!,specificDate: threeYearsAgo)?.first
                        let price10yAgo = CSVImporter.extractPricePointsFromFile(url: fileURL, symbol: share.symbol!, specificDate: tenYearsAgo)?.first

                        if let latestClose = share.latestPrice(option: .close)  {
                            
                            if let valid = price3yAgo?.close {

                                let divSum3Y = dDivs.filter { dv in
                                    if dv.date > threeYearsAgo { return true }
                                    else { return false }
                                }.compactMap{ $0.value }.reduce(0, +)
                                
                                share.return3y = (latestClose + divSum3Y) / valid
                            }
                            else {
                                ErrorController.addInternalError(errorLocation: #function, errorInfo: "can't find 3 year closing price from \(String(describing: price3yAgo)) to work out 3-year-return")
                            }
                        
                            if let valid = price10yAgo?.close {
                                
                                let divSum10Y = dDivs.filter { dv in
                                    if dv.date > tenYearsAgo { return true }
                                    else { return false }
                                }.compactMap{ $0.value }.reduce(0, +)
                                
                                share.return10y = (latestClose + divSum10Y) / valid
                          }
                            else {
                                ErrorController.addInternalError(errorLocation: #function, errorInfo: "can't find 10 year closing price \(String(describing: price10yAgo)) to work out 10-year-return")
                            }
                        }
                        else {
                            ErrorController.addInternalError(errorLocation: #function, errorInfo: "failed 3- and 10 year return due to missing latest close price")
                        }
                        
                        try backgroundMoc.save()

                    }
                    else {
                        ErrorController.addInternalError(errorLocation: #function, errorInfo: "trying to get 10 and 3 years dividend returns but no dated historical dividend data available")
                    }
                    
                } catch {
                    ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "Error update stocks data or download dividends within create New Share")
                }
            }
            else {
                ErrorController.addInternalError(errorLocation: #function, errorInfo: "trying to get dividend returns but no prices file available")
            }

    }
    
    /// check if MT name correct; if not the website may respond with a redirection which contains the correct MT name
    func checkMTRedirection(symbol: String, shortName: String?) async {
        
        let mtShortname = shortName?.replacingOccurrences(of: " ", with: "-")
        let components =  URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(symbol)/\(mtShortname ?? "")/revenue")

        // will receive redirect delegate call if shortName wrong in MT
            
        if let url = components?.url {
//            NotificationCenter.default.addObserver(self, selector: #selector(awaitingRedirection(notification:)), name: Notification.Name(rawValue: "Redirection"), object: nil) // for MT download redirects
            
            // testing if MT redirects to another symbol/name. This is then picked up by then delegate sent here.
//            do {
                async let test = Downloader.downloadDataWithRedirectionOption(url: url)
//                return await test
//            } catch {
//                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "Error running MT test download with new share \(symbol)")
//            }
        }
            
//        return false

    }
    

//    func fetchSpecificShare(symbol: String, fromBackgroundContext: Bool? = false) -> Share? {
//
//        let request = NSFetchRequest<Share>(entityName:"Share")
//        let predicate = NSPredicate(format: "symbol == %@", argumentArray: [symbol])
//        request.predicate = predicate
//
//        request.sortDescriptors = [NSSortDescriptor(key:  "symbol" , ascending:  true )]
//
//        if fromBackgroundContext ?? false {
//            setBackgroundMOC()
//        }
//
//        let theContext = (fromBackgroundContext ?? false) ? backgroundMoc! : (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
//
//        var shares: [Share]?
//        do {
//            shares  =  try theContext.fetch(request)
//        } catch let error as NSError{
//            ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "error fetching Shares")
//        }
//
//        return shares?.first
//    }
    
    // MARK: - other general functions
    
    /*
    /// Downloads sector, industry and employee count from Yahoo
    /// saves this to shareID in background
    func downloadAndSaveProfile(symbol: String, shareID: NSManagedObjectID) async throws {

        guard let share = managedObjectContext.object(with: shareID) as? Share else {
            throw InternalError()
        }
        
        var profile: ProfileData?
        do {
            profile = try await YahooPageScraper.downloadAndAnalyseProfile(share: share)
        }
        
        var components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)/pfile")
        components?.queryItems = [URLQueryItem(name: "p", value: (symbol))]
        
//        guard let validURL = components?.url else {
//            throw InternalErrorType.urlError
//        }
//
//        var profile: ProfileData?
//        do {
//            profile = try await YahooPageScraper.downloadAndAnalyseProfile(url: validURL)
//        } catch let error {
//            ErrorController.addInternalError(errorLocation: "StocksController2 - downloadProfile", systemError: nil, errorInfo: "error downloading profile for \(symbol): \(error)")
//        }
        
//        guard profile != nil else {
//            throw InternalErrorType.couldNotFindCompanyProfileData
//        }

// then save these to the share in the background
        
        if profile != nil {
            let backgroundMOC = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
            
            do {
                try await backgroundMOC.perform {
                    
                    guard let backgroundShare = backgroundMOC.object(with: shareID) as? Share else {
                        throw InternalErrorType.mocReadError
                    }
                    
                    backgroundShare.sector = profile!.sector
                    backgroundShare.industry = profile!.industry
                    backgroundShare.employees = profile!.employees
                    
                    try backgroundShare.managedObjectContext?.save()
                }
            }
        }
                
    }
    */
    
    func removeFile(_ atURL: URL?) {
       
        guard atURL != nil else {
            return
        }
        
        do {
            try FileManager.default.removeItem(at: atURL!)
        } catch let error {
            DispatchQueue.main.async {
                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "StocksController2 - error trying to remove existing file \(atURL!) in the Document folder to be able to move new file of same name from Inbox folder ")
            }
        }
    }


    // MARK: - update functions

    /// downloads daily prices, EPS/ qEPS, PER, live prices and tBond data
    /// updates MAC-Ds
    func updateStocksData(singleShareID: NSManagedObjectID?=nil) throws {
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "DownloadStarted"), object: nil, userInfo: nil)
        
        if singleShareID == nil {
            Task.init(priority: .background) {
                NotificationCenter.default.addObserver(self, selector: #selector(tBondDownloadAndAnalysisComplete(notification:)), name: Notification.Name(rawValue: "TBOND csv file downloaded"), object: nil)
                try await updateTreasuryBondYields()
            }
        }
        
        var singleShare: Share?
        if singleShareID != nil {
            singleShare = managedObjectContext.object(with: singleShareID!) as? Share
        }
        
        var sharesToUpdate: [Share]?
        let now = Date()
        let dateForNil = now.addingTimeInterval(-301)
        
        if let validShare = singleShare {
            sharesToUpdate = [validShare]
        } else {
            sharesToUpdate = fetchedObjects?.filter({ share in
                if share.watchStatus > 2 { return false }
                else if now.timeIntervalSince(share.lastLivePriceDate ?? dateForNil) < nonRefreshTimeInterval { return false }
                else { return true }
                
            })
        }
        
        sharesAwaitingUpdateDownload = sharesToUpdate
        
        let compDate = Date()
        sharesToUpdate = sharesToUpdate?.sorted(by: { s0, s1 in
            if (s0.lastLivePriceDate ?? compDate) < (s1.lastLivePriceDate ?? compDate) { return true
            }  else { return false }
        })
                
        let backgroundMoc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc.automaticallyMergesChangesFromParent = true

        NotificationCenter.default.addObserver(self, selector: #selector(backgroundContextDidSave(notification:)), name: .NSManagedObjectContextDidSave, object: nil)
        
        for share in sharesToUpdate ?? [] {
                    
            let symbol = share.symbol ?? ""
            let shortName = share.name_short ?? ""
            let shareID = share.objectID
            let minDate = share.priceDateRange()?.first?.addingTimeInterval(-365*24*3600)
            let latestQEPSDate = share.income_statement?.eps_quarter.datedValues(dateOrder: .ascending)?.dropZeros().last?.date ?? Date().addingTimeInterval(-365*24*3600/2)
//            let temp = Date().addingTimeInterval(-365*24*3600/4)
            
            Task.init(priority: .background, operation: {
                
                await currentPriceDownloadAnalyseSave(symbol: symbol, shareID: shareID)
                
                if share.currency == "USD" || share.currency == nil {
                    
                    await quarterlyEarningsUpdateDownloadAnalyseSave(shareSymbol: symbol, shortName: shortName, shareID: shareID, minDate: minDate, latestQEPSDate: latestQEPSDate, progressDelegate: viewController)
                } else {
                    // TODO: - non-US stocks
                    // alternatice source required
                }
                
                // uses Yahoo so should work for (Some) non-US stocks
                let existingPrices = share.getDailyPrices()
                await YahooPageScraper.dailyPricesDownloadAnalyseSave(symbol: symbol, shareID: shareID, existingPricePoints: existingPrices)
                
                DispatchQueue.main.async {
                    self.updateUserAndValueScores(share: share)
                    self.updateCompleteToDelegate(id: shareID)
                }
            })
        }
    }
    
    /// checks up-to-date status , and if older than 1 month downloads dividend/return, DCF-, R1- and WB-Valuation data
    /// updates trends; called after share price and eps updates complete, from 'updateCompleteToDelegate()'
    func refreshStockInformation(singleShare: Share?=nil) {
                
        var sharesToUpdate: [Share]?
        
        if let validShare = singleShare {
            sharesToUpdate = [validShare]
        } else {
            sharesToUpdate = fetchedObjects?.filter({ share in
                if share.watchStatus < 3 { return true }
                else { return false }
            })
        }
        
        var canStopDownloadSpinner = [true]
        shareInfosToDownload = sharesToUpdate?.count ?? 0
        
        NotificationCenter.default.addObserver(self, selector: #selector(singleShareInfoDownloadComplete(notification:)), name: Notification.Name(rawValue: "SingleShareInfoDownloadComplete"), object: nil)
        
        for share in sharesToUpdate ?? [] {
            
            let symbol = share.symbol
            var latestUpdate = (share.dcfValuation?.creationDate ?? Date().addingTimeInterval(-renewInterval-1))
            
            let shareID = share.objectID
            
// 1 DCF Valuation
            if latestUpdate.timeIntervalSinceNow > renewInterval {
                // refresh dcf valuation
                // save new dcfvalue as trend
                canStopDownloadSpinner.append(false)
                
                if let dcfValuation = share.dcfValuation {
                    let (value,_) = dcfValuation.returnIValueNew()
                    if value != nil {
                        if let existing = share.trend_DCFValue.datedValues(dateOrder: .ascending)?.dropZeros() {
                            share.trend_DCFValue = existing.mergeIn(newDV: [DatedValue(date: Date(), value: value!)])?.convertToData()
                        } else {
                            share.trend_DCFValue = [DatedValue(date: Date(), value: value!)].convertToData()
                        }
                        
                    }

                    Task(priority: .background) {
                            //TODO: - check: uses Yahoo so should work for some non-US stocks
                        
                            await YahooPageScraper.dataDownloadAnalyseSave(symbol: symbol ?? "", shortName: share.name_short ?? "", shareID: shareID, option: .dcfOnly, progressDelegate: viewController, downloadRedirectDelegate: self)

                            NotificationCenter.default.post(name: Notification.Name(rawValue: "SingleShareInfoDownloadComplete"), object: nil, userInfo: nil)
                    }
                }
            }
            else {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "SingleShareInfoDownloadComplete"), object: nil, userInfo: nil)
            }
            
// 2 Rule 1 Valuation
            latestUpdate = (share.rule1Valuation?.creationDate ?? Date().addingTimeInterval(-renewInterval-1))
            if latestUpdate.timeIntervalSinceNow > renewInterval {
                // refresh rule 1 valuation
                // save new r1 moat and sticker price as trend
                canStopDownloadSpinner.append(false)

                let shortName = share.name_short
                let longName = share.name_long ?? "no longName"
                let shareID = share.objectID
                let currency = share.currency ?? "none"
                    
                // save existing values if necessary
                if  let r1v = share.rule1Valuation {
                    let (_, moat) = r1v.moatScore()
                    
                    if moat != nil {
                        
                        if let existing = share.trend_MoatScore.datedValues(dateOrder: .ascending)?.dropZeros() {
                            share.trend_MoatScore = existing.mergeIn(newDV: [DatedValue(date: Date(), value: moat!)])?.convertToData()
                        } else {
                            share.trend_MoatScore = [DatedValue(date: Date(), value: moat!)].convertToData()
                        }
 
                    }

                    let (value2, _) = r1v.stickerPrice()
                    if value2 != nil {
                        
                        if let existing = share.trend_StickerPrice.datedValues(dateOrder: .ascending)?.dropZeros() {
                            share.trend_StickerPrice = existing.mergeIn(newDV: [DatedValue(date: Date(), value: value2!)])?.convertToData()
                        } else {
                            share.trend_StickerPrice = [DatedValue(date: Date(), value: value2!)].convertToData()
                        }
 
                    }
                    
                    
                    Task {
                        
                        if (share.currency ?? "USD") == "USD" {
                                // US Stocks
                                await MacrotrendsScraper.dataDownloadAnalyseSave(shareSymbol: symbol, shortName: shortName, shareID: shareID, downloadOption: .rule1Only, downloadRedirectDelegate: self)
                                await YahooPageScraper.dataDownloadAnalyseSave(symbol: symbol ?? "missing", shortName: shortName ?? "missing", shareID: shareID, option: .rule1Only, downloadRedirectDelegate: self)
                                
                            } else {
                                // non-US Stocks
                                await YahooPageScraper.dataDownloadAnalyseSave(symbol: symbol ?? "missing", shortName: shortName ?? "missing", shareID: shareID, option: .nonUS, downloadRedirectDelegate: self)
                                
                                DispatchQueue.main.async {
                                    
                                    self.webViewDownloader = WebViewDownloader.newWebViewDownloader(delegate: self.viewController!)
                                    self.webViewDownloader?.downloadPage(domain: "https://www.boerse-frankfurt.de/equity", companyName: longName, pageName: "key-data", currency: currency, shareID: shareID, in: self.viewController!)
                                }
                                
                                await WebPageScraper2.nonUSDataDownload(symbol: symbol, shortName: share.name_short, shareID: shareID)
                                
                                await FinanzenScraper.downloadAnalyseAndSavePredictions(shareSymbol: symbol, companyName: longName, shareID: shareID)
                                
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "SingleShareInfoDownloadComplete"), object: nil, userInfo: nil)
                            }
                    }
                }
            }
            else {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "SingleShareInfoDownloadComplete"), object: nil, userInfo: nil)
            }
            
// 3 WB Valuation
            latestUpdate = (share.wbValuation?.date ?? Date().addingTimeInterval(-renewInterval-1)) // positive is past date
            if latestUpdate.timeIntervalSinceNow > renewInterval {
                // refresh WB valuation 
                // save intrinsic value as trend in Share
                canStopDownloadSpinner.append(false)
                shareInfosToDownload += 1

                let shortName = share.name_short
                let shareID = share.objectID
                if let wbValuationID = share.wbValuation?.objectID {
                    
                    let wbv = managedObjectContext.object(with: wbValuationID) as! WBValuation
                    let (_,lynch) = share.lynchRatio()
                    if lynch != nil {
                        let trendValue = DatedValue(date: wbv.date!, value: lynch!)
                        share.saveTrendsData(datedValuesToAdd: [trendValue], trendName: .lynchScore)
                    }
                    let (value2, _) = wbv.ivalue()
                    if value2 != nil {
                        
                        if let existing = share.trend_intrinsicValue.datedValues(dateOrder: .ascending)?.dropZeros() {
                            share.trend_intrinsicValue = existing.mergeIn(newDV: [DatedValue(date: Date(), value: value2!)])?.convertToData()
                        } else {
                            share.trend_intrinsicValue = [DatedValue(date: Date(), value: value2!)].convertToData()
                        }
 
                    }

                    Task(priority: .background) {
                            // TODO: - find alternative data source for non-US Stocks

                        await MacrotrendsScraper.dataDownloadAnalyseSave(shareSymbol: symbol, shortName: shortName!, shareID: shareID, downloadOption: .wbvOnly, progressDelegate: viewController, downloadRedirectDelegate: self)
                            
                        await YahooPageScraper.dataDownloadAnalyseSave(symbol: symbol!, shortName: shortName!, shareID: shareID, option: .yahooKeyStatistics, progressDelegate: viewController, downloadRedirectDelegate: self)

                        let singleShareID = singleShare != nil ? shareID : nil
                            await dividendsAndReturns(shareID: singleShareID ?? shareID, pricesCsvURL: nil)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "SingleShareInfoDownloadComplete"), object: nil, userInfo: nil)
                    }
                }
            }
            else {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "SingleShareInfoDownloadComplete"), object: nil, userInfo: nil)
            }
            
        }
        
        if !canStopDownloadSpinner.contains(false) {
            
            var shareID: NSManagedObjectID?
            if let share = singleShare {
                shareID = share.objectID
            }
            NotificationCenter.default.post(name: Notification.Name(rawValue: "DownloadEnded"), object: shareID, userInfo: nil)
        }
    }
    
    @objc
    func singleShareInfoDownloadComplete(notification: Notification) {
        
        shareInfosToDownload -= 1
        if shareInfosToDownload <= 0 {
            shareInfosToDownload = 0
            NotificationCenter.default.removeObserver(self)
            
            let singleShareID = notification.object as? NSManagedObjectID
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: "DownloadEnded"), object: singleShareID, userInfo: nil)
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
            controllerDelegate?.singleShareUpdateComplete(atPath: path)
        }
        
        if (sharesAwaitingUpdateDownload?.count ?? 0) == 0 {
            do {
                try self.managedObjectContext.save()
            } catch {
                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "Error trying to save main MOC after completing all shares updates")
            }
            
            refreshStockInformation()
        }
    }
    
    //MARK: - specific update task functions
    
    /// returns (shareSymbol, current tickerPrice)
    func currentPriceDownloadAnalyseSave(symbol: String, shareID: NSManagedObjectID) async {
        
        var components: URLComponents?
        
        components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)")
        components?.queryItems = [URLQueryItem(name: "p", value: symbol)]
        
        guard let validURL = components?.url else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "invalid url for \(symbol) current price download")
            return
        }
        
        let htmlText = await Downloader.downloadDataNoThrow(url: validURL)

        guard let price = YahooPageScraper.singleNumberExtraction(htmlText: htmlText, parameterTitle: "regularMarketPrice", numberStart: ">", numberEnd:  "</fin-streamer>") else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "unable to find current live price for \(symbol)")
            return
        }
        
        
        let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc.automaticallyMergesChangesFromParent = true
        
        do {
            if let bgShare = backgroundMoc.object(with: shareID) as? Share {
                
                bgShare.lastLivePrice = price
                bgShare.lastLivePriceDate = Date()
                try backgroundMoc.save()
            }
        }
        catch {
            ErrorController.addInternalError(errorLocation: #function, systemError: error ,errorInfo: "error downloading and saving current live price")
        }
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
            ErrorController.addInternalError(errorLocation: "StocksController2.updateUserAndValueScores", systemError: error, errorInfo: "error trying to save updated user and value scores")
        }
    }
    
    func getQuarterlyEarningsTTMForUpdate(shareSymbol: String, shortName: String, minDate: Date?=nil) async throws -> Labelled_DatedValues? {
                
        var sn = shortName
        if sn.contains(" ") {
            sn = sn.replacingOccurrences(of: " ", with: "-").lowercased()
        }
        
        guard let components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(shareSymbol)/\(sn)/pe-ratio") else {
            throw InternalErrorType.urlInvalid
        }
        
        guard let url = components.url else {
            throw InternalErrorType.urlError
        }

        let  values = await MacrotrendsScraper.getHxEPSandPEData(url: url, companyName: sn, until: minDate, downloadRedirectDelegate: self)

        let epsDates = values?.compactMap({ DatedValue(date: $0.date, value: $0.epsTTM) })
        let labelledValues = Labelled_DatedValues(label: shareSymbol, datedValues: epsDates ?? [])
                
        return labelledValues
    }
    
    func quarterlyEarningsUpdateDownloadAnalyseSave(shareSymbol: String, shortName: String, shareID: NSManagedObjectID,minDate: Date?=nil, latestQEPSDate: Date?, progressDelegate: ProgressViewDelegate?) async {
                        
        var sn = shortName
        if sn.contains(" ") {
            sn = sn.replacingOccurrences(of: " ", with: "-").lowercased()
        }
        
        if Date().timeIntervalSince(latestQEPSDate ?? Date()) < 365*24*3600/4 {
            return
        }
         
        await YChartsScraper.dataDownloadAnalyseSave(symbol: shareSymbol, downloadOption: .qEPS, shareID: shareID, progressDelegate: progressDelegate)
//        await YChartsScraper.qepsDownloadAnalyseSave(symbol: shareSymbol, shortName: sn, shareID: shareID, progressDelegate: progressDelegate, downloadRedirectDelegate: self)
            
    }

    /*
    /// returns [PricePoints] sorted by date  with new daily trading prices added
    /// or nil if there were no new price points
    func getDailyPricesForUpdate(shareSymbol: String, shareID: NSManagedObjectID, existingDailyPrices: [PricePoint]?) async -> [PricePoint]? {
        
        if let lastPriceDate = existingDailyPrices?.last?.tradingDate {
            
            guard (Date().timeIntervalSince(lastPriceDate) > 12 * 3600) else {
                return nil
            }
        }
        

        let minDate = existingDailyPrices?.last?.tradingDate
        
        await YahooPageScraper.dailyPricesDownloadAnalyseSave(symbol: shareSymbol, shareID: shareID, existingPricePoints: existingDailyPrices)

//        if let downloadedDailyPrices = await YahooPageScraper.dailyPricesDownloadAndAnalyse(shareSymbol: shareSymbol, minDate: minDate) {
//
//            guard let existingPricePoints = existingDailyPrices else {
//                return downloadedDailyPrices
//            }
//
//            var pricePointsSet = Set<PricePoint>(existingPricePoints)
//            pricePointsSet = pricePointsSet.union(downloadedDailyPrices)
//
//            let sorted = Array(pricePointsSet).sorted { e0, e1 in
//                if e0.tradingDate < e1.tradingDate { return true }
//                else { return false }
//            }
//            return sorted
//        }
    
        return nil
    }
    */
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
            formatter.dateFormat = "yyyy"
            return formatter
        }()
        let year$ = dateFormatter.string(from: Date())
        
        guard let url = URL(string: "https://home.treasury.gov/resource-center/data-chart-center/interest-rates/daily-treasury-rates.csv/"+year$+"/all?type=daily_treasury_yield_curve&field_tdr_date_value="+year$+"&page&_format=csv") else {
            throw InternalErrorType.urlError
        }
        
        await WebPageScraper2.downloadAndAnalyseTreasuryYields(url: url)
        
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
        let backgroundMoc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc.automaticallyMergesChangesFromParent = true
    }
    
//    func saveBackgroundMOC(share: Share) throws {
//
//        guard let moc = backgroundMoc else {
//            throw InternalErrorType.noValidBackgroundMOC
//        }
//
//        if share.hasChanges {
//            moc.performAndWait {
//                do {
//                    try moc.save()
//                } catch let error {
//                    ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "a background update error for \(share.symbol ?? "missing") occurred: can't save to background MOC: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
    
    @objc
    func backgroundContextDidSave(notification: Notification) {
                
        if let _ = notification.object as? NSManagedObjectContext {
            
            DispatchQueue.main.async {
                (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.perform {
                    (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.mergeChanges(fromContextDidSave: notification)
                    
//                    do {
//                        try (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.save()
//                    } catch {
//                        ErrorController.addInternalError(errorLocation: "StocksController 2.backgroundContextDidSave", systemError: error, errorInfo: "Can't save main MOC after merging changes from background MOC")
//                    }
                    
                }
            }
        }

    }

}


extension StocksController2: DownloadRedirectionDelegate {
    
    func redirectTo(url: URL?) {
        guard let validURL = url else { return }
    }
    
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
                                    ErrorController.addInternalError(errorLocation: "StocksController2.awaitingRedirection", systemError: error, errorInfo: "couldn't save \(symbol) in it's MOC after downlaod re-direction")
                                }
                                
                                if let info = notification.userInfo as? [String:Any] {
                                    if let task = info["task"] as? DownloadTask {
                                        switch task {
                                        case .epsPER:
                                            do {
                                                try self.updateStocksData(singleShareID: share.objectID)
                                            } catch let error {
                                                ErrorController.addInternalError(errorLocation: "StocksController2.awaitingRedirection", systemError: error, errorInfo: "error updating \(symbol) after redirect")
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

