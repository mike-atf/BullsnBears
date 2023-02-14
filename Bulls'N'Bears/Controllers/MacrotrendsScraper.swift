//
//  MacrotrendsScraper.swift
//  Bulls'N'Bears
//
//  Created by aDav on 13/01/2023.
//

import UIKit
import CoreData

enum DownloadOptions {
    case allPossible
    case rule1Only
    case dcfOnly
    case wbvOnly
    case yahooKeyStatistics
    case yahooProfile
    case lynchParameters
    case wbvIntrinsicValue
}

struct MTDownloadJobs {
    
    var pageNameForURL = String()
    var rowTitles = [String]()
    var url: URL?
    
    init(pageNameForURL: String, symbol: String, shortName: String, rowTitles: [String]) {
        self.pageNameForURL = pageNameForURL
        self.rowTitles = rowTitles
        
        var shareShortName = shortName.lowercased()
        if shortName.contains(" ") {
            shareShortName = shareShortName.replacingOccurrences(of: " ", with: "-")
        }
        let components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(symbol)/\(shareShortName)/\(pageNameForURL)")
        url = components?.url
     }
}



class MacrotrendsScraper {
    
    class func mtDownloadJobs(symbol: String, shortName: String, option: DownloadOptions) -> [MTDownloadJobs]? {
        
        let pages = mtPageNames(options: option)
        let mtRowTitles = mtAnnualDataRowTitles(options: option)
        
        guard pages.count == mtRowTitles.count else {
            ErrorController.addInternalError(errorLocation: "MTDownloadJobs struct", errorInfo: "mismatch between pages to download \(pages) and rowTitle groups \(mtRowTitles)")
            return nil
        }
        
        var allJobs = [MTDownloadJobs]()

        for i in 0..<pages.count {
            let job = MTDownloadJobs(pageNameForURL: pages[i], symbol: symbol, shortName: shortName, rowTitles: mtRowTitles[i])
            allJobs.append(job)
        }
        
        return allJobs
    }
    
    class func mtPageNames(options: DownloadOptions) -> [String] {
        
        var pageNames = [String]()
        
        switch options {
            
        case .allPossible:
            pageNames =  ["financial-statements", "balance-sheet", "cash-flow-statement" ,"financial-ratios", "pe-ratio","stock-price-history"]
        case .wbvOnly:
            pageNames =  ["financial-statements", "balance-sheet", "cash-flow-statement" ,"financial-ratios"]
        case .dcfOnly:
            pageNames =  ["financial-statements", "balance-sheet", "cash-flow-statement"]
        case .rule1Only:
            pageNames =  ["financial-statements", "balance-sheet","financial-ratios","pe-ratio"]
        case .lynchParameters:
            pageNames = ["financial-statements", "pe-ratio"]
        case .wbvIntrinsicValue:
            pageNames = ["financial-statements", "pe-ratio"]
        default:
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "MacrotrendScraper has been asked to download Yahoo KeyStats data")
        }
        
        return pageNames
        
    }
    
    class func mtAnnualDataRowTitles(options: DownloadOptions) -> [[String]] {
        
        var rowTitles = [[String]]()
        
        switch options {
            
        case .allPossible:
            rowTitles  =  [
                ["Revenue","Gross Profit","Research And Development Expenses","SG&A Expenses","Net Income", "Operating Income", "EPS - Earnings Per Share"],
                 ["Long Term Debt", "Retained Earnings (Accumulated Deficit)", "Share Holder Equity"],
                 ["Cash Flow From Operating Activities"],
                 ["ROE - Return On Equity", "ROA - Return On Assets", "ROI - Return On Investment","Book Value Per Share","Operating Cash Flow Per Share", "Free Cash Flow Per Share"],
                ["none"],
                ["none"]]
        case .wbvOnly:
            rowTitles = [["Revenue","Gross Profit","Research And Development Expenses","SG&A Expenses","Net Income", "Operating Income", "EPS - Earnings Per Share"],
             ["Long Term Debt", "Retained Earnings (Accumulated Deficit)", "Share Holder Equity"],
             ["Cash Flow From Operating Activities"],
             ["ROE - Return On Equity", "ROA - Return On Assets", "ROI - Return On Investment","Book Value Per Share","Operating Cash Flow Per Share", "Free Cash Flow Per Share"]]
        case .dcfOnly:
            rowTitles = [["Revenue","Gross Profit", "Net Income"],
             ["Long Term Debt", "Share Holder Equity"],
             ["Cash Flow From Operating Activities"]]
        case .rule1Only:
            rowTitles = [["Revenue","Net Income", "EPS - Earnings Per Share"],
             ["Long Term Debt"],
             ["ROI - Return On Investment","Book Value Per Share","Free Cash Flow Per Share"],
            ["none"]]
        case .lynchParameters:
            rowTitles = [["Net Income"],["pe-ratio"]] // 'pre-ratio' irrelavant here but rowTitle.count must match pageTitle.count
        case .wbvIntrinsicValue:
            rowTitles = [["Net Income", "EPS - Earnings Per Share"],["pe-ratio"]]
        default:
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "MacrotrendScraper has been asked to download Yahoo KeyStats data")

        }

        
        return rowTitles
    }
    /// fetches ALL annual data from horizontal row tables from Macrotrend, for Rule1, WBV and DCF
    ///
    class func countOfRowsToDownload(option: DownloadOptions) -> Int {
        
        return mtAnnualDataRowTitles(options: option).flatMap{ $0 }.count
    }
    
    class func countPagesToDownload(option: DownloadOptions) -> Int {
        
        return mtPageNames(options: option).flatMap{ $0 }.count
    }

    ///
    class func dataDownloadAnalyseSave(shareSymbol: String?, shortName: String?, shareID: NSManagedObjectID, downloadOption: DownloadOptions ,progressDelegate: ProgressViewDelegate?=nil, downloadRedirectDelegate: DownloadRedirectionDelegate?) async {
        
        guard let symbol = shareSymbol else {
            progressDelegate?.allTasks -= (mtAnnualDataRowTitles(options: downloadOption).count + 2)
            ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "missing share symbol")
            return
        }
        
        guard let sn = shortName else {
            progressDelegate?.allTasks -= (mtAnnualDataRowTitles(options: downloadOption).count + 2)
            ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "Emissing shortname for \(symbol)")
            return
        }
        
        guard let jobs = mtDownloadJobs(symbol: symbol, shortName: sn, option: downloadOption) else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "failure to create MT download jobs")
            return
        }
        
        if let delegate = downloadRedirectDelegate {
            NotificationCenter.default.addObserver(delegate, selector: #selector(DownloadRedirectionDelegate.awaitingRedirection(notification:)), name: Notification.Name(rawValue: "Redirection"), object: nil)
        }

        var labelledDatedResults = [Labelled_DatedValues]()
        var sectionCount = 0
        let downloader = Downloader()
        
        for job in jobs {
            
            guard let url = job.url else {
                ErrorController.addInternalError(errorLocation: #function, errorInfo: "invalid URL from job \(job)")
                continue
            }
            
            if job.pageNameForURL == "pe-ratio" {
                var pe_datedValues: [DatedValue]?
                var eps_datedValues: [DatedValue]?

                let perAndEPSvalues = await MacrotrendsScraper.getHxEPSandPEData(url: url, companyName: sn, until: nil, downloadRedirectDelegate: downloadRedirectDelegate)
                
                pe_datedValues = perAndEPSvalues?.compactMap({ element in
                    return DatedValue(date: element.date, value: element.peRatio)
                })
                if pe_datedValues?.count ?? 0 > 0 {
                    labelledDatedResults.append(Labelled_DatedValues(label: "PE Ratio Historical data", datedValues: pe_datedValues!))
                }
                eps_datedValues = perAndEPSvalues?.compactMap({ element in
                    return DatedValue(date: element.date, value: element.epsTTM)
                })
                if eps_datedValues?.count ?? 0 > 0 {
                    labelledDatedResults.append(Labelled_DatedValues(label: "eps - earnings per share", datedValues: eps_datedValues!))
                }
            }
            else if job.pageNameForURL == "stock-price-history" {
                guard let htmlText = await Downloader.downloadDataNoThrow(url: url) else {
                    continue
                }
                if let datedValues = numbersFromColumn(html$: htmlText, tableHeader: "Historical Annual Stock Price Data</th>", targetColumnsFromLeft: [1]) {
                    labelledDatedResults.append(Labelled_DatedValues(label: "Historical average annual stock prices", datedValues: datedValues))
                }
            }
            else {
                guard let htmlText = await downloader.downloadDataWithRedirectionOption(url: url) else {
                    continue
                }
                if let labelledDatedValues = await MacrotrendsScraper.extractDatedValuesFromTable(htmlText: htmlText, rowTitles: job.rowTitles) {
                    labelledDatedResults.append(contentsOf: labelledDatedValues)
                }
            }
            
            sectionCount += 1
            progressDelegate?.taskCompleted()

        }
        
        
// Historical PE and EPS with dates
        
//        let peEPSJob = MTDownloadJobs(pageNameForURL: "pe-ratio", symbol: symbol, shortName: sn, rowTitles: ["none"])
//        var pe_datedValues: [DatedValue]?
//        var eps_datedValues: [DatedValue]?
//        if let url = peEPSJob.url {
//            let perAndEPSvalues = await MacrotrendsScraper.getHxEPSandPEData(url: url, companyName: sn, until: nil, downloadRedirectDelegate: downloadRedirectDelegate)
//
//            pe_datedValues = perAndEPSvalues?.compactMap({ element in
//                return DatedValue(date: element.date, value: element.peRatio)
//            })
//            if pe_datedValues?.count ?? 0 > 0 {
//                labelledDatedResults.append(Labelled_DatedValues(label: "PE Ratio Historical data", datedValues: pe_datedValues!))
//            }
//            eps_datedValues = perAndEPSvalues?.compactMap({ element in
//                return DatedValue(date: element.date, value: element.epsTTM)
//            })
//            if eps_datedValues?.count ?? 0 > 0 {
//                labelledDatedResults.append(Labelled_DatedValues(label: "eps - earnings per share", datedValues: eps_datedValues!))
//            }
//        }
//
//        progressDelegate?.taskCompleted()
            
// Historical stock prices
//        let historicalPricesJob = MTDownloadJobs(pageNameForURL: "stock-price-history", symbol: symbol, shortName: sn, rowTitles: ["none"])
//        if let url = historicalPricesJob.url {
//
//            do {
//                if let htmlText = await Downloader.downloadDataNoThrow(url: url) {
//
//                    if let datedValues = try numbersFromColumn(html$: htmlText, tableHeader: "Historical Annual Stock Price Data</th>", targetColumnsFromLeft: [1]) {
//                        labelledDatedResults.append(Labelled_DatedValues(label: "Historical average annual stock prices", datedValues: datedValues))
//                    }
//                }
//            } catch  {
//                ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "Error downloading historical price WB Valuation data: \(error.localizedDescription)")
//           }
//        }
//
//        progressDelegate?.taskCompleted()
        
        
        do {
            let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
            backgroundMoc.automaticallyMergesChangesFromParent = true
            
            if let bgShare = backgroundMoc.object(with: shareID) as? Share {
                try await bgShare.mergeInDownloadedData(labelledDatedValues: labelledDatedResults)
            }
        } catch {
            ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "couldn't save background MOC")
        }
    }

    
    /// uses MacroTrends webpage
    class func wbvDataDownloadAnalyseSave(shareSymbol: String?, shortName: String?, shareID: NSManagedObjectID, progressDelegate: ProgressViewDelegate?=nil, downloadRedirectDelegate: DownloadRedirectionDelegate) async throws {
        
        
        
        guard let symbol = shareSymbol else {
            throw InternalErrorType.shareSymbolMissing
        }
        
        guard var sn = shortName else {
            throw InternalErrorType.shareShortNameMissing
        }
        
        if sn.contains(" ") {
            sn = sn.replacingOccurrences(of: " ", with: "-")
        }
        
        
        await dataDownloadAnalyseSave(shareSymbol: symbol, shortName: sn, shareID: shareID, downloadOption: .wbvOnly, progressDelegate: progressDelegate ,downloadRedirectDelegate: downloadRedirectDelegate)

        /*
        var downloadErrors = [RunTimeError]()
        
        let webPageNames = ["financial-statements", "balance-sheet", "cash-flow-statement" ,"financial-ratios"]
        
        let rowNames = [["Revenue","Gross Profit","Research And Development Expenses","SG&A Expenses","Net Income", "Operating Income", "EPS - Earnings Per Share"],["Long Term Debt","Property, Plant, And Equipment","Retained Earnings (Accumulated Deficit)", "Share Holder Equity"],["Cash Flow From Operating Activities"],["ROE - Return On Equity", "ROA - Return On Assets", "Book Value Per Share"]]
        
//        var results = [LabelledValues]()
        var labelledDatedResults = [Labelled_DatedValues]()
        var resultDates = [Date]()
        var sectionCount = 0
        let downloader: Downloader? = Downloader(task: .wbValuation)
        for section in webPageNames {
            
            if let components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(symbol)/\(sn)/\(section)")  {
                if let url = components.url  {
                    
                    NotificationCenter.default.addObserver(downloadRedirectDelegate, selector: #selector(DownloadRedirectionDelegate.awaitingRedirection(notification:)), name: Notification.Name(rawValue: "Redirection"), object: nil)

                    guard let htmlText = await downloader?.downloadDataWithRedirectionOption(url: url) else {
                        downloadErrors.append(RunTimeError.specificError(description: "downloaded empty page/ failure for section \(section)"))
                        continue
                    }
                                                                    
                    if let labelledDatedValues = await MacrotrendsScraper.extractDatedValuesFromTable(htmlText: htmlText, rowTitles: rowNames[sectionCount]) {
                        
                        labelledDatedResults.append(contentsOf: labelledDatedValues)
                        var dates = [Date]()
                        for ldv in labelledDatedValues {
                            let extractedDates = ldv.datedValues.compactMap { $0.date }
                            dates.append(contentsOf: extractedDates)
                        }
                        resultDates.append(contentsOf: dates)
                    }

                    sectionCount += 1
                }
            }
        }
        
        // capEx = net PPE for capEx from Yahoo
        var components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)/balance-sheet")
        components?.queryItems = [URLQueryItem(name: "p", value: symbol)]
        
        if let url = components?.url  {
            
            let netPPE = "Net property, plant and equipment"
            let htmlText = try await Downloader.downloadData(url: url)
            
            if let extractionResults = YahooPageScraper.extractPageData(html: htmlText, pageType: .balance_sheet, tableHeaders: ["Balance sheet"], rowTitles: [[netPPE]]) {
                labelledDatedResults.append(contentsOf: extractionResults)
            }
        }
        
        
// Historical PE and EPS with dates
//        var perAndEPSvalues: [Dated_EPS_PER_Values]?
        var pe_datedValues: [DatedValue]?
        var eps_datedValues: [DatedValue]?
        if let components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(symbol)/\(sn)/pe-ratio") {
            if let url = components.url {
                let perAndEPSvalues = await MacrotrendsScraper.getHxEPSandPEData(url: url, companyName: sn, until: nil, downloadRedirectDelegate: downloadRedirectDelegate)
                pe_datedValues = perAndEPSvalues?.compactMap({ element in
                    return DatedValue(date: element.date, value: element.peRatio)
                })
                if pe_datedValues?.count ?? 0 > 0 {
                    labelledDatedResults.append(Labelled_DatedValues(label: "PE Ratio Historical data", datedValues: pe_datedValues!))
                }
                eps_datedValues = perAndEPSvalues?.compactMap({ element in
                    return DatedValue(date: element.date, value: element.epsTTM)
                })
                if eps_datedValues?.count ?? 0 > 0 {
                    labelledDatedResults.append(Labelled_DatedValues(label: "eps - earnings per share", datedValues: eps_datedValues!))
                }

            }
        }
            
// Historical stock prices
//        var hxPriceDatedValues: Labelled_DatedValues?
//
        if let components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(symbol)/\(sn)/stock-price-history") {
            if let url = components.url {
                
                var htmlText = String()
                do {
                    htmlText = try await Downloader.downloadData(url: url)

                    if let datedValues = numbersFromColumn(html$: htmlText, tableHeader: "Historical Annual Stock Price Data</th>", targetColumnsFromLeft: [1]) {
                        labelledDatedResults.append(Labelled_DatedValues(label: "Historical average annual stock prices", datedValues: datedValues))
                    }
                } catch let error as InternalErrorType {
                    if error == .generalDownloadError {
                        
                        let info = ["Redirection": "Object"]
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "Redirection"), object: info)
                        return
                    } else {
                        ErrorController.addInternalError(errorLocation: "WPS2.downloadAnalyseSaveWBValuationData", systemError: nil, errorInfo: "Error downloading historical price WB Valuation data: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc.automaticallyMergesChangesFromParent = true
        
        do {
            if let bgShare = backgroundMoc.object(with: shareID) as? Share {
                try await bgShare.mergeInDownloadedData(labelledDatedValues: labelledDatedResults)
            }
        } catch {
            ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "couldn't save background MOC")
        }
        */
        /*
        let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc.automaticallyMergesChangesFromParent = true

        try await backgroundMoc.perform {

            do {

                if let share = backgroundMoc.object(with: shareID) as? Share {
                    
// OLD - replace eventually
                    let wbv = share.wbValuation ?? WBValuation(context: backgroundMoc)
                    wbv.share = share
                    for result in results {
                        switch result.label {
                        case "Revenue":
                            wbv.revenue = result.values
                        case "Gross Profit":
                            wbv.grossProfit = result.values
                        case "Research And Development Expenses":
                            wbv.rAndDexpense = result.values
                        case "SG&A Expenses":
                            wbv.sgaExpense = result.values
                        case "Net Income":
                            wbv.netEarnings = result.values
                        case "Operating Income":
                            wbv.operatingIncome = result.values
                        case "EPS - Earnings Per Share":
                            wbv.eps = result.values
                        case "Long Term Debt":
                            wbv.debtLT = result.values
                        case "Property, Plant, And Equipment":
                            wbv.ppe = result.values
                        case "Retained Earnings (Accumulated Deficit)":
                            wbv.equityRepurchased = result.values
                        case "Share Holder Equity":
                            wbv.shareholdersEquity = result.values
                        case "Net property, plant and equipment":
                            var capEx = [Double]()
                            for i in 0..<result.values.count-1 {
                                // assumes time DESCENDING values, as is the case on MT financials pages
                                // proper CapEx is yoy-delta-PPE + depreciation (pr net PPE) - NA on MT
                                capEx.append(result.values[i] - result.values[i+1])
                            }
                            wbv.capExpend = capEx
                        case "Cash Flow From Operating Activities":
                            wbv.opCashFlow = result.values
                        case "ROE - Return On Equity":
                            wbv.roe = result.values
                        case "ROA - Return On Assets":
                            wbv.roa = result.values
                        case "Book Value Per Share":
                            wbv.bvps = result.values
                        default:
                            ErrorController.addInternalError(errorLocation: "WebScraper2.downloadAndAnalyseWBVData", systemError: nil, errorInfo: "undefined download result with title \(result.label)")
                        }
                    
                        
                    wbv.latestDataDate = resultDates.max()
                    wbv.savePERWithDateArray(datesValuesArray: pe_datedValues, saveInContext: false)
                    wbv.saveEPSTTMWithDateArray(datesValuesArray: eps_datedValues, saveToMOC: false)
                    wbv.avAnStockPrice = hxPriceDatedValues?.extractValuesOnly(dateOrder: .ascending)
                    wbv.date = Date()
                    
                    if let vShare = wbv.share {
                        if let lynch = wbv.lynchRatio() {
                            let dv = DatedValue(date:wbv.date!, value: lynch)
                            vShare.saveTrendsData(datedValuesToAdd: [dv], trendName: .lynchScore)
                        }
                        let (ivalue,_) = wbv.ivalue()
                        if ivalue != nil {
                            let dv = DatedValue(date:wbv.date!, value: ivalue!)
                            vShare.saveTrendsData(datedValuesToAdd: [dv], trendName: .intrinsicValue)
                        }
                    }
                }
                    
// NEW
                    // 1 save current values for internal trends
                    if let wbv = share.wbValuation {
                        if let lynch = wbv.lynchRatio() {
                            let dv = DatedValue(date:wbv.date!, value: lynch) // value so far
                            share.saveTrendsData(datedValuesToAdd: [dv], trendName: .lynchScore)
                        }
                        let (ivalue,_) = wbv.ivalue()
                        if ivalue != nil {
                            let dv = DatedValue(date:wbv.date!, value: ivalue!)
                            share.saveTrendsData(datedValuesToAdd: [dv], trendName: .intrinsicValue)
                        }
                    }
                    
                    if let r1 = share.rule1Valuation {
                        let (_, moat) = r1.moatScore()
                        
                        if moat != nil {
                            let dv = DatedValue(date: r1.creationDate!, value: moat!)
//                            share.saveTrendsData(datedValuesToAdd: [dv], trendName: .moatScore)
                            r1.addMoatTrend(date: Date(), moat: moat!)
                        }
                        
                        let (price,_) = r1.stickerPrice()
                        if price != nil {
                            let dv = DatedValue(date: r1.creationDate!, value: price!)
//                            share.saveTrendsData(datedValuesToAdd: [dv], trendName: .stickerPrice)
                            r1.addStickerPriceTrend(date: Date(), price: price!)
                        }
                    }

                    // 2 save new prices
                    share.avgAnnualPrices = hxPriceDatedValues?.convertToData()
                    
                    let incomeStatement = share.income_statement ?? Income_statement(context: backgroundMoc)
                    incomeStatement.share = share
                    
                    let balanceSheet = share.balance_sheet ?? Balance_sheet(context: backgroundMoc)
                    balanceSheet.share = share
                    
                    let cashFlowStatement = share.cash_flow ?? Cash_flow(context: backgroundMoc)
                    cashFlowStatement.share = share
                    
                    let ratios = share.ratios ?? Ratios(context: backgroundMoc)
                    ratios.share = share
                    
                    ratios.pe_ratios = pe_datedValues?.convertToData()
                    incomeStatement.eps_annual = eps_datedValues?.convertToData()

                    for datedResult in labelledDatedResults {
                        
                        switch datedResult.label {
                        case "Revenue":
                            incomeStatement.revenue = datedResult.datedValues.convertToData()
                        case "Gross Profit":
                            incomeStatement.grossProfit = datedResult.datedValues.convertToData()
                        case "Research And Development Expenses":
                            incomeStatement.rdExpense = datedResult.datedValues.convertToData()
                        case "SG&A Expenses":
                            incomeStatement.sgaExpense = datedResult.datedValues.convertToData()
                        case "Net Income":
                            incomeStatement.netIncome = datedResult.datedValues.convertToData()
                        case "Operating Income":
                            incomeStatement.operatingIncome = datedResult.datedValues.convertToData()
                        case "EPS - Earnings Per Share":
                            incomeStatement.eps_annual = datedResult.datedValues.convertToData()
                        case "Long Term Debt":
                            balanceSheet.debt_longTerm = datedResult.datedValues.convertToData()
                        case "Property, Plant, And Equipment":
                            balanceSheet.ppe_net = datedResult.datedValues.convertToData()
                        case "Retained Earnings (Accumulated Deficit)":
                            balanceSheet.retained_earnings = datedResult.datedValues.convertToData()
                        case "Share Holder Equity":
                            balanceSheet.sh_equity = datedResult.datedValues.convertToData()
                        case "Net property, plant and equipment":
                            var capEx = [DatedValue]()
                            for i in 0..<datedResult.datedValues.count-1 {
                                // assumes time DESCENDING values, as is the case on MT financials pages
                                // proper CapEx is yoy-delta-PPE + depreciation (pr net PPE) - NA on MT
                                let change = datedResult.datedValues[i].value - datedResult.datedValues[i+1].value
                                capEx.append(DatedValue(date: datedResult.datedValues[i].date, value: change))
                            }
                            cashFlowStatement.capEx = capEx.convertToData()
                        case "Cash Flow From Operating Activities":
                            cashFlowStatement.opCashFlow = datedResult.datedValues.convertToData()
                        case "ROE - Return On Equity":
                            ratios.roe = datedResult.datedValues.convertToData()
                        case "ROA - Return On Assets":
                            ratios.roa = datedResult.datedValues.convertToData()
                        case "Book Value Per Share":
                            ratios.bvps = datedResult.datedValues.convertToData()
                        default:
                            ErrorController.addInternalError(errorLocation: "WebScraper2.downloadAndAnalyseWBVData", systemError: nil, errorInfo: "undefined download result with title \(datedResult.label)")
                        }
                        }
                    
                }

                try backgroundMoc.save()
            } catch let error {
                ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: error, errorInfo: "couldn't save background MOC")
            }
            
            
            if (downloadErrors ?? []).contains(InternalErrorType.generalDownloadError) {
                throw InternalErrorType.generalDownloadError
            }
        }
        */
    }
    
    
    /// fetches [["Revenue","EPS - Earnings Per Share","Net Income"],["ROI - Return On Investment","Book Value Per Share","Operating Cash Flow Per Share"],["Long Term Debt"]]. Does NOT fetch: OCF (single), Debt (single),  growthEstimates, hx PE,  insider stocks, -buys and - sells; these come from Yahoo
     class func rule1DownloadAndAnalyse(symbol: String, shortName: String, pageNames: [String], rowTitles: [[String]], progressDelegate: ProgressViewDelegate?=nil, downloadRedirectDelegate: DownloadRedirectionDelegate) async  -> [Labelled_DatedValues]? {
         
         var hyphenatedShortName = String()
         let shortNameComponents = shortName.split(separator: " ")
         hyphenatedShortName = String(shortNameComponents.first ?? "").lowercased()
         
         guard hyphenatedShortName != "" else {
             ErrorController.addInternalError(errorLocation: #function, errorInfo: "missing hyphenated short name for \(symbol)")
             return nil
         }
         
         for index in 1..<shortNameComponents.count {
             if !shortNameComponents[index].contains("(") {
                 hyphenatedShortName += "-" + String(shortNameComponents[index]).lowercased()
             }
         }

         var errors = [RunTimeError]()
         var results = [Labelled_DatedValues]()
         var sectionCount = 0
         let downloader = Downloader(task: .r1Valuation)
         for pageName in pageNames {
             
             var components: URLComponents?
             components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(symbol)/\(hyphenatedShortName)/" + pageName)
             
             guard let url = components?.url else {
                 progressDelegate?.taskCompleted()
                 continue
             }

             NotificationCenter.default.addObserver(downloadRedirectDelegate, selector: #selector(DownloadRedirectionDelegate.awaitingRedirection(notification:)), name: Notification.Name(rawValue: "Redirection"), object: nil)
             
             guard let htmlText = await downloader.downloadDataWithRedirectionOption(url: url) else {
                 errors.append(RunTimeError.specificError(description: "empty page / download failure for \(pageName) "))
                 progressDelegate?.taskCompleted()
                 continue
             }
                              
             if let labelledDatedValues = await MacrotrendsScraper.extractDatedValuesFromTable(htmlText: htmlText, rowTitles: rowTitles[sectionCount]) {
                 
                 results.append(contentsOf: labelledDatedValues)
             }
             
             progressDelegate?.taskCompleted()
             
             sectionCount += 1
         }
         
 // MT download for PE Ratio in different format than 'Financials'
         for pageName in ["pe-ratio"] {
             var components: URLComponents?
             components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(symbol)/\(hyphenatedShortName)/" + pageName)
             
             guard let url = components?.url else {
                 progressDelegate?.taskCompleted()
                 continue
             }
             
             // the following values are NOT ANNUAL but quarterly, sort of!
             if let values = await MacrotrendsScraper.getHxEPSandPEData(url: url, companyName: hyphenatedShortName.capitalized, until: nil, downloadRedirectDelegate: downloadRedirectDelegate) {
                 let pe_datedValues: [DatedValue] = values.compactMap({ element in
                     return (DatedValue(date: element.date, value: element.peRatio))
                 })
                 let eps_datedValues: [DatedValue] = values.compactMap({ element in
                     return (DatedValue(date: element.date, value: element.epsTTM))
                 })
                 
                 results.append(Labelled_DatedValues(label: "PE Ratio Historical Data", datedValues: pe_datedValues))
                 results.append(Labelled_DatedValues(label: "EPS - Earnings Per Share", datedValues: eps_datedValues))
             }
             progressDelegate?.taskCompleted()
         }

         return results
     }
    
    /// downloads row data from the horizontal tables in MT, NOT the vertical tables for PE or EPS
    class func selectMTDataDownloadAnalyse(symbol: String, shortName: String, pageNames: [String], rowTitles: [[String]], progressDelegate: ProgressViewDelegate?=nil, downloadRedirectDelegate: DownloadRedirectionDelegate?) async throws -> [Labelled_DatedValues]? {
        
        var hyphenatedShortName = String()
        let shortNameComponents = shortName.split(separator: " ")
        hyphenatedShortName = String(shortNameComponents.first ?? "").lowercased()
        
        guard hyphenatedShortName != "" else {
            throw InternalErrorType.shareShortNameMissing
        }
        
        for index in 1..<shortNameComponents.count {
            if !shortNameComponents[index].contains("(") {
                hyphenatedShortName += "-" + String(shortNameComponents[index]).lowercased()
            }
        }

        var results = [Labelled_DatedValues]()
        var sectionCount = 0
        let downloader = Downloader(task: .r1Valuation)
        for pageName in pageNames {
            
            var components: URLComponents?
            components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(symbol)/\(hyphenatedShortName)/" + pageName)
            
            guard let url = components?.url else {
                progressDelegate?.downloadError(error: InternalErrorType.urlInvalid.localizedDescription)
                continue
            }
            
            var htmlText: String?

            do {
                if downloadRedirectDelegate != nil {
                    NotificationCenter.default.addObserver(downloadRedirectDelegate!, selector: #selector(DownloadRedirectionDelegate.awaitingRedirection(notification:)), name: Notification.Name(rawValue: "Redirection"), object: nil)
                }
                
                htmlText = try await downloader.downloadDataWithRedirection(url: url)
                
            } catch let error as InternalErrorType {
                progressDelegate?.downloadError(error: error.localizedDescription)
                continue
            }
            
            guard let pageText = htmlText else {
                progressDelegate?.downloadError(error: InternalErrorType.emptyWebpageText.localizedDescription)
                continue
            }
            
            if let labelledDatedValues = await MacrotrendsScraper.extractDatedValuesFromTable(htmlText: pageText, rowTitles: rowTitles[sectionCount]) {
                
                results.append(contentsOf: labelledDatedValues)
            }
            
            progressDelegate?.taskCompleted()
            
            sectionCount += 1
        }
        
        return results
        
    }

    /// returns historical pe ratios and eps TTM with dates from macro trends website
    /// in form of [DatedValues] = (date, epsTTM, peRatio )
    /// ; optional parameter 'date' returns values back to this date and the first set before.
    /// ; throws downlad and analysis errors, which need to be caught by cailler
    class func getHxEPSandPEData(url: URL, companyName: String, until date: Date?=nil, downloadRedirectDelegate: DownloadRedirectionDelegate?) async -> [Dated_EPS_PER_Values]? {
        
            var tableText = String()
            var tableHeaderTexts = [String]()
            var datedValues = [Dated_EPS_PER_Values]()
            let downloader = Downloader(task: .epsPER)
        
            if let delegate = downloadRedirectDelegate {
                NotificationCenter.default.addObserver(delegate, selector: #selector(DownloadRedirectionDelegate.awaitingRedirection(notification:)), name: Notification.Name(rawValue: "Redirection"), object: nil)
            }
            
            guard let validPageText = await downloader.downloadDataWithRedirectionOption(url: url) else {
                ErrorController.addInternalError(errorLocation: "MTScraper.getHxEPSandPEData", errorInfo: "download failed for \(url)")
                return nil
            }
                        
            do {
                tableText = try await MacrotrendsScraper.extractTable(title:"PE Ratio Historical Data", html: validPageText) // \(title)
            } catch {
                ErrorController.addInternalError(errorLocation: "MTScraper.getHxEPSandPEData", errorInfo: "failed to extract table for \(url)")
                return nil
            }

            do {
                tableHeaderTexts = try await MacrotrendsScraper.extractHeaderTitles(html: tableText)
            } catch {
                ErrorController.addInternalError(errorLocation: "MTScraper.getHxEPSandPEData", errorInfo: "failed to extract header titles for \(url)")
                return nil
            }
            
            if tableHeaderTexts.count > 0 && tableHeaderTexts.contains("Date") {
                do {
                    datedValues = try MacrotrendsScraper.extractTableData(html: validPageText, titles: tableHeaderTexts, untilDate: date)
                    return datedValues
                } catch {
                    ErrorController.addInternalError(errorLocation: "MTScraper.getHxEPSandPEData", errorInfo: "failed to extract header titles for \(url)")
                    return nil
                }
            }
        
            ErrorController.addInternalError(errorLocation: "MTScraper.getHxEPSandPEData", errorInfo: "failed to extract header titles for \(url)")
            return nil

    }

    
    //MARK: - Internal functions
    
    /// multiplies non-ratios/ per-share vlues by 1_000_000
    class func extractDatedValuesFromTable(htmlText: String, rowTitles: [String]) async -> [Labelled_DatedValues]? {
        
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = NSLocale.current
            formatter.timeZone = NSTimeZone.local
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter
        }()
        
        var extractedString: String?
        do {
            extractedString = try extracTable2(htmlText: htmlText)
//                throw InternalError(location: "WebScraper2.extractDatedValuesFromMTTable", errorInfo: "table text not extracted", errorType: .htmlTableTextNotExtracted)
        } catch {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "table text not extracted")
            return nil
        }
        
        guard let tableText = extractedString else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "table text not extracted")
            return nil
        }
        
        var results = [Labelled_DatedValues]()
        for title in rowTitles {
            var labelledDV = Labelled_DatedValues(label: title, datedValues: [DatedValue]())
            if  let rowText = extractRow(tableText: tableText, rowTitle: title) {
                let pairs = rowText.split(separator: ",")
                for pair in pairs {
                    var datedValue: DatedValue
                    let date_Value = pair.split(separator: ":")
                    guard let date$ = date_Value.first?.filter("-0123456789.".contains) else {
                        continue
                    }
                    guard let date = dateFormatter.date(from: String(date$)) else {
                        continue
                    }
                    guard let value$ = date_Value.last else {
                        continue
                    }
                    guard let value = Double(value$.filter("-0123456789.".contains)) else {
                        continue
                    }
                    
                    var factor = 1_000_000.0
                    if title.contains("Per Share") {
                        factor = 1.0
                    } else if title.starts(with: "RO") {
                        factor = 1/100
                    }

                    
                    datedValue = DatedValue(date: date, value: value * factor)
                    labelledDV.datedValues.append(datedValue)
                }
            }
            results.append(labelledDV)
        }
        
        return results        
    }
    
    /// has Date yyyy + 6 columns; average annual price is in the first column
    class func numbersFromColumn(html$: String?, tableHeader: String, targetColumnsFromLeft: [Int]?=[0]) -> [DatedValue]? {
        
        let tableTerminal = "</tbody>" //"</tr></tbody>"
//        let localColumnTerminal = "</td>"
//        let rowStart = "<tr>"
        let rowTerminal = "</tr>"
//        let labelStart = ">"
        
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return formatter
        }()

        
        let pageText = String(html$ ?? "")
        
        guard let titleIndex = pageText.range(of: tableHeader) else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "did not find \(String(describing: tableHeader))")
           return nil
        }
        
        guard let tableStartIndex = pageText.range(of: "<tbody>", range: titleIndex.upperBound..<pageText.endIndex) else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "did not find '<body>'")
           return nil
        }

        guard let tableEndIndex = pageText.range(of: tableTerminal, range: tableStartIndex.upperBound..<pageText.endIndex) else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "did not find \(String(describing: tableTerminal))")
           return nil
        }
        
        let tableText = String(pageText[tableStartIndex.upperBound..<tableEndIndex.lowerBound])
        
        let rows = tableText.split(separator: rowTerminal)
        
        let targetValues = targetColumnsFromLeft ?? [1,2,3,4,5,6]
        
        var datedValues = [DatedValue]()
        for row in rows {
//            print()
//            print("row for \(tableHeader)...")
            var columnTexts = row.split(separator: "</td>")
//            print("...columnTExts \(columnTexts)")
            for i in 0..<columnTexts.count {
                guard let dataStartPosition = columnTexts[i].range(of: "center") else { //">"
                    continue
                }
//                let cut = String(columnTexts[i][dataStartPosition.lowerBound..<columnTexts[i].endIndex])
                columnTexts[i] = columnTexts[i][dataStartPosition.upperBound..<columnTexts[i].endIndex]
            }
//            print()
//            print("... corrected columnTExts \(columnTexts)")
            guard let valueDate = dateFormatter.date(from: String(columnTexts[0]).numbersOnly()) else {
                continue
            }
//            print("...valueDate \(valueDate)")
            for i in targetValues {
//                print("...value$ \(columnTexts[i])")
                if let value = String(columnTexts[i]).textToNumber() {
//                    print("...value \(value)")
                    datedValues.append(DatedValue(date: valueDate, value: value))
                }
            }
        }
        
        return datedValues
        
    }

    /// default for MacroTrends table
    /// should have caller be Download Redirefction delegate as NotificationCenter observer
    class func getqColumnTableData(url: URL, companyName: String, tableHeader: String , dateColumn: Int, valueColumn: Int, until date: Date?=nil) async throws -> [DatedValue]? {
        
            var htmlText:String?
            var datedValues: [DatedValue]?
            let downloader = Downloader(task: .healthData)
        
           do {
               htmlText = try await downloader.downloadDataWithRedirection(url: url)
            } catch let error as InternalErrorType {
                throw error
            }
        
            guard let validPageText = htmlText else {
                throw InternalErrorType.generalDownloadError // possible result of MT redirection
            }
                
            do {
                datedValues = try extractColumnsValuesFromTable(html$: validPageText, tableHeader: tableHeader, dateColumn: dateColumn, valueColumn: valueColumn, until: date)
                return datedValues
            } catch let error as InternalErrorType {
               throw error
            }

    }
    
    /// returns a date (assuming format yyyy-MM-dd) from default column 0 and a value from another column (%, T,B,M,K)
    /// columns count begins with 0...,check the website table in question
    /// send webpage html and the Title/Header identifying the start of the table
    /// default html tags are for MacroTrends table, with tableStart <tbody><tr>'  tableTerminal "</tr></tbody>", columnTerminal "</td>", rowTerminal and start "</tr>"
    /// check html and send other values for these if the table text differs
    class func extractColumnsValuesFromTable(html$: String?, tableHeader: String, tableTerminal: String? = nil, columnTerminal: String? = nil, dateColumn: Int?=0, valueColumn: Int, until: Date?=nil) throws -> [DatedValue]? {
        
        let tableHeader = tableHeader
        let tableStart = "<tbody><tr>"
        let tableTerminal =  tableTerminal ?? "</tr></tbody>"
        let localColumnTerminal = columnTerminal ?? "</td>"
        let rowTerminal = "</tr>"
        
        let websiteDateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.calendar.timeZone = TimeZone(identifier: "UTC")!
            return formatter
        }()

        guard let validHtml = html$ else {
            throw InternalError(location: #function, errorInfo: "empty web page text for \(tableHeader)", errorType: .emptyWebpageText)
        }
        
        let pageText = String(validHtml)
        
        guard let titleIndex = pageText.range(of: tableHeader) else {
            throw InternalError(location: #function, errorInfo: "did not find \(String(describing: tableHeader)) in \(pageText)", errorType: .htmlTableHeaderEndNotFound)
        }

        guard let tableEndIndex = pageText.range(of: tableTerminal,options: [NSString.CompareOptions.literal], range: titleIndex.upperBound..<pageText.endIndex, locale: nil) else {
            throw InternalError(location: #function, errorInfo: "did not find \(String(describing: tableTerminal)) in \(pageText)", errorType: .htmlTableEndNotFound)
        }
                
        guard let tableStartIndex = pageText.range(of: tableStart, range: titleIndex.upperBound..<pageText.endIndex) else {
            throw InternalError(location: #function, errorInfo: "did not find \(String(describing: tableStart)) in \(pageText)", errorType: .htmlTableSequenceStartNotFound)
        }
        
        let tableText = String(pageText[tableStartIndex.upperBound..<tableEndIndex.lowerBound])
        
        var valueArray = [DatedValue]()
        
        let rows$ = tableText.components(separatedBy: rowTerminal)
        for row in rows$ {
            let columns$ = row.components(separatedBy: localColumnTerminal)
            var value: Double?
            var date: Date?
            guard columns$.count > valueColumn else { continue }
            
            let date$ = columns$[0]
            let value$ = columns$[valueColumn]
            
            for column$ in [date$, value$] {
                let data = Data(column$.utf8)
                if let content$ = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil).string {
                    
                    if let dateValue = websiteDateFormatter.date(from: content$) {
                        date = dateValue
                    } else if let validValue = Double(content$.filter("-0123456789.".contains)) {
                        value = validValue
                        switch value$.last! {
                        case "%":
                            value! /= 100
                        case "T":
                            value! *= 1000000000000
                        case "B":
                            value! *= 1000000000
                        case "M":
                            value! *= 1000000
                        case "K":
                            value! *= 1000
                        default:
                            value = validValue
                        }
                    }
                }
            }
            
            if date != nil && value != nil {
                valueArray.append(DatedValue(date: date!, value: value!))
                
                if let stopDate = until {
                    if date! < stopDate { break }
                }
            }

        }
        
        return valueArray

    }

    /// for MT "Financials' only pages with titled rows and dated values
    class func extracTable2(htmlText: String) throws -> String? {
        
        let mtTableDataStart = "var originalData = ["
        let mtTableDataEnd = "}];"
        
        let pageText = htmlText
        
        guard pageText.count > 0 else {
            throw InternalErrorType.emptyWebpageText
        }
        
        guard let tableStartIndex = pageText.range(of: mtTableDataStart) else {
            throw InternalErrorType.htmlTableSequenceStartNotFound
        }
        
        guard let tableEndIndex = pageText.range(of: mtTableDataEnd,options: [NSString.CompareOptions.literal], range: tableStartIndex.upperBound..<pageText.endIndex, locale: nil) else {
            throw InternalErrorType.htmlTableEndNotFound
        }
        
        return String(pageText[tableStartIndex.upperBound...tableEndIndex.upperBound]) // lowerBound
    }

    class func extractRow(tableText: String, rowTitle: String) -> String? {

        let mtRowTitle = ">"+rowTitle+"<"
        let mtRowDataStart = "/div>\","
        let mtRowDataEnd = "},"
        let mtTableEndIndex = "}]"
        
        guard tableText.count > 0 else {
            return nil
        }

        guard let rowStartIndex = tableText.range(of: mtRowTitle) else {
            return nil
        }
        
        var rowDataEndIndex = tableText.range(of: mtRowDataEnd,options: [NSString.CompareOptions.literal], range: rowStartIndex.upperBound..<tableText.endIndex, locale: nil)
        
        if rowDataEndIndex == nil {
            rowDataEndIndex = tableText.range(of: mtTableEndIndex,options: [NSString.CompareOptions.literal], range: rowStartIndex.upperBound..<tableText.endIndex, locale: nil)
        }
        
        guard rowDataEndIndex != nil else {
            return nil
        }

        guard let rowDataStartIndex = tableText.range(of: mtRowDataStart,options: [NSString.CompareOptions.literal], range: rowStartIndex.upperBound..<rowDataEndIndex!.lowerBound, locale: nil) else {
            return nil
        }
        
        return String(tableText[rowDataStartIndex.upperBound..<rowDataEndIndex!.lowerBound])
    }
    
    /// for MT pages such as 'PE-Ratio' with dated rows and table header
    class func extractTable(title: String, html: String, tableStartSequence: String?=nil, tableEndSequence: String?=nil) async throws -> String {
        
        let tableTitle = title.replacingOccurrences(of: "-", with: " ")
        
        let startSequence = tableStartSequence ?? tableTitle
        
        let tableStartIndex = html.range(of: startSequence)
        
        if tableStartIndex == nil {
            throw InternalError(location: #function, errorInfo: "did not find \(String(describing: tableTitle)) in \(html)", errorType: .htmlTableTitleNotFound)
        }
        
        guard let tableEndIndex = html.range(of: tableEndSequence ?? "</table>",options: [NSString.CompareOptions.literal], range: tableStartIndex!.upperBound..<html.endIndex, locale: nil) else {
            throw InternalError(location: #function, errorInfo: "did not find \(String(describing: tableEndSequence)) in \(html)", errorType: .htmlTableEndNotFound)
        }
        
        let tableText = String(html[tableStartIndex!.upperBound..<tableEndIndex.lowerBound])

        return tableText
    }

    /// for MT pages such as 'PE-Ratio' with dated rows and table header, to assist 'extractTable' and 'extractTableData' func
    class func extractHeaderTitles(html: String) async throws -> [String] {
        
        let headerStartSequence = "</thead>"
        let headerEndSequence = "<tbody><tr>"
        let rowEndSequence = "</th>"
        
        guard let headerStartIndex = html.range(of: headerStartSequence) else {
            throw InternalErrorType.htmTablelHeaderStartNotFound
        }
        
        guard let headerEndIndex = html.range(of: headerEndSequence,options: [NSString.CompareOptions.literal], range: headerStartIndex.upperBound..<html.endIndex, locale: nil) else {
            throw InternalError(location: #function, errorInfo: "did not find \(String(describing: headerEndSequence)) in \(html)", errorType: .htmlTableHeaderEndNotFound)

        }
        
        var headerText = String(html[headerStartIndex.upperBound..<headerEndIndex.lowerBound])
        var rowStartIndex = headerText.range(of: "<th ", options: [NSString.CompareOptions.literal])
        var columnTitles = [String]()
        
        repeat {
            
            if let rsi = rowStartIndex {
                if let rowEndIndex = headerText.range(of: rowEndSequence,options: [NSString.CompareOptions.literal], range: rsi.lowerBound..<headerText.endIndex) {
                    
                    let rowText = String(headerText[rsi.upperBound..<rowEndIndex.lowerBound])
                    
                    if let valueStartIndex = rowText.range(of: "\">", options: .backwards) {
                        
                        let value$ = String(rowText[valueStartIndex.upperBound..<rowText.endIndex])
                        if value$ != "" {
                            columnTitles.append(value$)
                        }
                    }
                    headerText = String(headerText[rowEndIndex.lowerBound..<headerText.endIndex])
                    
                    rowStartIndex = headerText.range(of: "<th ", options: [NSString.CompareOptions.literal])
                    }
                else { break } // no rowEndIndex
            }
            else { break } // no rowStartIndex
        } while rowStartIndex != nil
        
        return columnTitles
    }

    /// for MT pages such as 'PE-Ratio' with dated rows and table header, to assist 'extractTable' and 'extractTableData' func
    class func extractTableData(html: String, titles: [String], untilDate: Date?=nil) throws -> [Dated_EPS_PER_Values] {
        
        let bodyStartSequence = "<tbody><tr>"
        let bodyEndSequence = "</tr></tbody>"
        let rowEndSequence = "</td>"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "y-M-d"
        
        var datedValues = [Dated_EPS_PER_Values]()
        
        guard let bodyStartIndex = html.range(of: bodyStartSequence) else {
            throw InternalError(location: #function, errorInfo: "did not find \(String(describing: bodyStartSequence)) in \(html)", errorType: .htmlTableBodyStartIndexNotFound)
        }
        
        guard let bodyEndIndex = html.range(of: bodyEndSequence,options: [NSString.CompareOptions.literal], range: bodyStartIndex.upperBound..<html.endIndex, locale: nil) else {
            throw InternalError(location: #function, errorInfo: "did not find \(String(describing: bodyEndSequence)) in \(html)", errorType: .htmlTableBodyEndIndexNotFound)
        }
        
        var tableText = String(html[bodyStartIndex.upperBound..<bodyEndIndex.lowerBound])
        var rowStartIndex = tableText.range(of: "<td ", options: [NSString.CompareOptions.literal])

        var columnCount = 0
        let columnsExpected = titles.count
        
        var date: Date?
        var epsValue: Double?
        var peValue: Double?

        outer: repeat {
            
            if let rsi = rowStartIndex {
                if let rowEndIndex = tableText.range(of: rowEndSequence,options: [NSString.CompareOptions.literal], range: rsi.lowerBound..<tableText.endIndex) {
                    
                    let rowText = String(tableText[rsi.upperBound..<rowEndIndex.lowerBound])
                    
                    if let valueStartIndex = rowText.range(of: "\">", options: .backwards) {
                        
                        let value$ = String(rowText[valueStartIndex.upperBound..<rowText.endIndex])

                        if (columnCount)%columnsExpected == 0 {
                            if let validDate = dateFormatter.date(from: String(value$)) {// date
                                date = validDate
                            }
                        }
                        else {
                            let value = Double(value$.filter("-0123456789.".contains)) ?? Double()

                            if (columnCount-2)%columnsExpected == 0 { // EPS value
                                epsValue = value
                            }
                            else if (columnCount+1)%columnsExpected == 0 { // PER value
                                peValue = value
                                if let validDate = date {
                                    let newDV = Dated_EPS_PER_Values(date: validDate,epsTTM: (epsValue ?? Double()),peRatio: (peValue ?? Double()))
                                    datedValues.append(newDV)
                                    if let minDate = untilDate {
                                        if minDate > validDate { return datedValues }
                                    }
                                    date = nil
                                    peValue = nil
                                    epsValue = nil

                                }
                            }
                        }
                    }
                    
                    tableText = String(tableText[rowEndIndex.lowerBound..<tableText.endIndex])
                    
                    rowStartIndex = tableText.range(of: "<td ", options: [NSString.CompareOptions.literal])

                }
                else { break } // no rowEndIndex
            }
            else { break } // no rowStartIndex
            columnCount += 1

            
        } while rowStartIndex != nil

        return datedValues
    }

    // MARK: - NSManagedObject functions
    
    /*
    class func saveR1Data(shareID: NSManagedObjectID, labelledDatedValues: [Labelled_DatedValues]) async throws {
        
        let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc.automaticallyMergesChangesFromParent = true
        
        do {
            if let bgShare = backgroundMoc.object(with: shareID) as? Share {
                try await bgShare.mergeInDownloadedData(labelledDatedValues: labelledDatedValues)
            }
        } catch {
            ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "couldn't save background MOC")
        }

        /*
        let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc.automaticallyMergesChangesFromParent = true
        
        
        
        try await backgroundMoc.perform {

            do {
                if let bgShare = backgroundMoc.object(with: shareID) as? Share {
                    
                    let incomeStatement = bgShare.income_statement ?? Income_statement(context: backgroundMoc)
                    incomeStatement.share = bgShare
                    
                    let ratios = bgShare.ratios ?? Ratios(context: backgroundMoc)
                    ratios.share = bgShare
                    
                    let cashFLowStatement = bgShare.cash_flow ?? Cash_flow(context: backgroundMoc)
                    cashFLowStatement.share = bgShare
                    
                    let balanceSheet = bgShare.balance_sheet ?? Balance_sheet(context: backgroundMoc)
                    balanceSheet.share = bgShare
                    
                    let analysis = bgShare.analysis ?? Analysis(context: backgroundMoc)
                    analysis.share = bgShare
                    
                    let keyStats = bgShare.key_stats ?? Key_stats(context: backgroundMoc)
                    keyStats.share = bgShare
                                        
                    let r1v = bgShare.rule1Valuation ?? Rule1Valuation(context: backgroundMoc)
                    r1v.share = bgShare
                    
                    // save new value with date in a share trend
                    let (_, moat) = r1v.moatScore()
                    
                    if moat != nil {
                        let dv = DatedValue(date: r1v.creationDate!, value: moat!)
//                        bgShare.saveTrendsData(datedValuesToAdd: [dv], trendName: .moatScore)
                        r1v.addMoatTrend(date: Date(), moat: moat!)
                    }
                    
                    let (price,_) = r1v.stickerPrice()
                    if price != nil {
                        let dv = DatedValue(date: r1v.creationDate!, value: price!)
//                        bgShare.saveTrendsData(datedValuesToAdd: [dv], trendName: .stickerPrice)
                        r1v.addStickerPriceTrend(date: Date(), price: price!)
                    }

                    // calculate FCF from OCF and netPPEChange
                    let ocf = labelledDatedValues.filter { ldv in
                        if ldv.label.lowercased().contains("operating activities") { return true }
                        else { return false }
                    }.first?.datedValues
                    
                    let netPPE = labelledDatedValues.filter { ldv in
                        if ldv.label.lowercased() == ("net change in property, plant, and equipment") { return true }
                        else { return false }
                    }.first?.datedValues
                    
                    if let  fcfDV = cashFLowStatement.calculateFCF(ocf: ocf, netPPEChange: netPPE) {
                        let millions: [DatedValue] = fcfDV.compactMap{ DatedValue(date: $0.date, value: $0.value * 1_000_000) }
                        cashFLowStatement.freeCashFlow = millions.convertToData()
                    }
                        
                    for result in labelledDatedValues {
                        switch result.label.lowercased() {
                        case "revenue":
                            let millions: [DatedValue] = result.datedValues.compactMap{ DatedValue(date: $0.date, value: $0.value * 1_000_000) }
                            incomeStatement.revenue = millions.convertToData()
                        case "eps - earnings per share":
                            incomeStatement.eps_annual = result.datedValues.convertToData()
                        case "net income":
                            let millions: [DatedValue] = result.datedValues.compactMap{ DatedValue(date: $0.date, value: $0.value * 1_000_000) }
                           incomeStatement.netIncome = millions.convertToData()
                        case "roi - return on investment":
                            let percent: [DatedValue] = result.datedValues.compactMap{ DatedValue(date: $0.date, value: $0.value / 100) }
                            ratios.roi = percent.convertToData()
                        case "book value per share":
                            ratios.bvps = result.datedValues.convertToData()
                        case "cash flow from operating activities":
                            let millions: [DatedValue] = result.datedValues.compactMap{ DatedValue(date: $0.date, value: $0.value * 1_000_000) }
                            cashFLowStatement.opCashFlow = millions.convertToData()
                        case "long term debt":
                            let millions: [DatedValue] = result.datedValues.compactMap{ DatedValue(date: $0.date, value: $0.value * 1_000_000) }
                            balanceSheet.debt_longTerm = millions.convertToData()
                        case "pe ratio historical data":
                            ratios.pe_ratios = result.datedValues.convertToData()
                        case "sales growth (year/est)":
                            analysis.future_revenueGrowthRate = result.datedValues.convertToData()
//                        case "operating cash flow":
//                            let millions: [DatedValue] = result.datedValues.compactMap{ DatedValue(date: $0.date, value: $0.value * 1_000_000) }
//                            cashFLowStatement.opCashFlow = millions.convertToData()
                        case "purchases":
                            if let r0 = result.datedValues.first { // first or last?
                                keyStats.insiderPurchases = [r0].convertToData()
                            }
                        case "sales":
                            if let r0 = result.datedValues.first { // first or last?
                                keyStats.insiderSales = [r0].convertToData()
                            }
                        case "total insider shares held":
                            if let r0 = result.datedValues.first { // first or last?
                                keyStats.insiderShares =  [r0].convertToData()
                            }
                        case "forward p/e":
                            if let r0 = result.datedValues.first { // first or last?
                                analysis.forwardPE = [r0].convertToData()
                            }
                        case "rdexpense":
                            incomeStatement.rdExpense = result.datedValues.convertToData()
                        default:
                            ErrorController.addInternalError(errorLocation: "WebPageScraper2.saveR1Date", systemError: nil, errorInfo: "unspecified result label \(result.label)")
                        }
                    }
                    
                    r1v.creationDate = Date()
                    try backgroundMoc.save()
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateValuationData"), object: nil, userInfo: nil)
                    //DEBUG ONLY
                }
                //DEBUG ONLY

                else {
                    print("Unable to get background share from objectID for R1 valuation")
                }
                //DEBUG ONLY

            } catch {
                ErrorController.addInternalError(errorLocation: "WebPageScraper2.saveR1Data", systemError: error, errorInfo: "Error saving R1 data download")
                throw error
            }
       }
         */
    }
    */
}
