//
//  MacrotrendsScraper.swift
//  Bulls'N'Bears
//
//  Created by aDav on 13/01/2023.
//

import UIKit
import CoreData

//financialsScore [adj/futureGrowthRate,revenue, retEarnings, EPS_annual, grossProfit, netIncome, divYield, pe ratios, capEx, ROE, opCashFLow, LTdebt, SGA, R&D]

enum DownloadOptions {
    case allPossible
    case rule1Only
    case dcfOnly
    case wbvOnly
    case yahooKeyStatistics
    case yahooProfile
    case lynchParameters
    case moatScore
    case wbvIntrinsicValue
    case allValuationDataOnly
    case researchDataOnly
    case mainIndicatorsOnly // lynch [netIncome, PE ratio TTM from yahoo, current divYield from Yahoo], moat [bvps, eps_annual, revenue, opCFs, roi]
    case screeningInfos
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
            pageNames = ["financial-statements"]
        case .moatScore:
            pageNames = ["financial-statements", "financial-ratios"]
        case .wbvIntrinsicValue:
            pageNames = ["financial-statements", "pe-ratio"]
        case .allValuationDataOnly:
            pageNames = ["financial-statements", "balance-sheet", "cash-flow-statement" ,"financial-ratios", "pe-ratio"]
        case .mainIndicatorsOnly:
            pageNames = mtPageNames(options: .moatScore)
        case .screeningInfos:
            pageNames = mtPageNames(options: .mainIndicatorsOnly)
        default:
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "MacrotrendsScraper has been asked to download unknown job \(options)")
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
            rowTitles = [["Net Income"]] // 'pre-ratio' irrelavant here but rowTitle.count must match pageTitle.count
        case .moatScore:
            rowTitles = [["Revenue","EPS - Earnings Per Share"], ["Book Value Per Share","ROI - Return On Investment","Operating Cash Flow Per Share"]]
        case .wbvIntrinsicValue:
            rowTitles = [["Net Income", "EPS - Earnings Per Share"],["pe-ratio"]]
        case .allValuationDataOnly:
            rowTitles = [["Revenue","Gross Profit","Research And Development Expenses","SG&A Expenses","Net Income", "Operating Income", "EPS - Earnings Per Share"],
             ["Long Term Debt", "Retained Earnings (Accumulated Deficit)", "Share Holder Equity"],
             ["Cash Flow From Operating Activities"],
             ["ROE - Return On Equity", "ROA - Return On Assets", "ROI - Return On Investment","Book Value Per Share","Operating Cash Flow Per Share", "Free Cash Flow Per Share"], ["pe-ratio"]]
        case .mainIndicatorsOnly:
            rowTitles = mtAnnualDataRowTitles(options: .moatScore)
            rowTitles[0].append(contentsOf: mtAnnualDataRowTitles(options: .lynchParameters)[0])
        case .screeningInfos:
            rowTitles = mtAnnualDataRowTitles(options: .mainIndicatorsOnly)
        default:
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "MacrotrendsScraper has been asked to download unknown job \(options)")

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

}
