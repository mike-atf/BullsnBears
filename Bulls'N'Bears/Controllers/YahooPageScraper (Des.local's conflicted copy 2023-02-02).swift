//
//  YahooPageScraper.swift
//  Bulls'N'Bears
//
//  Created by aDav on 05/01/2023.
//

import Foundation
import CoreData
import UIKit

enum YahooPageType {
    case financials
    case balance_sheet
    case cash_flow
    case insider_transactions
    case analysis
    case key_statistics
    case quote
    case profile
}

struct YahooPageDelimiters {
    
    var tableStart:String?
    var tableEnd = String()
    var rowStarts = [String]()
    /// rowEnd may not be found in last row, so check for tableEnd if not found
    var rowEnd = String()
    var columnStart = String()
    var dataStart = String()
    var dataEnd = String()
    var topRowTitle: String?
    var topRowEnd: String?
    var topRowDataEnd: String?
    var saveRowTitles = [String]()
    
    init(pageType: YahooPageType, tableHeader: String?, rowTitles: [String], saveTitles:[String]?=nil) {
        
        if tableHeader != nil {
            tableStart = "<span>" + tableHeader! + "</span>"
        }
        for title in rowTitles {
            if title == "Next year" {
                rowStarts.append(title + "</span></td>" ) // without this will find top row column 'Next year (yyyy)'
            }
            else if title == "Free cash flow" {
                rowStarts.append("title=\"Free cash flow\"><span class=\"Va(m)\">" + title + "</span>")
            }
            else {
                rowStarts.append(title + "</span>")
            }
        }
        
        self.saveRowTitles = saveTitles ?? rowTitles

        switch pageType {
        case .financials:
            rowEnd = "fin-row"
            columnStart = "fin-col"
            dataStart = "<span>"
            dataEnd = "</span>"
            tableEnd = "</div></div><div></div></div></div></div></div>"
            topRowTitle = "<span>Breakdown</span>"
            topRowEnd = "fin-row"
            topRowDataEnd = dataEnd
        case .balance_sheet:
            rowEnd = "fin-row"
            columnStart = "fin-col"
            dataStart = "<span>"
            dataEnd = "</span>"
            tableEnd = "</div></div><div></div></div></div></div></div>"
            topRowTitle = "<span>Breakdown</span>"
            topRowEnd = "fin-row"
            topRowDataEnd = dataEnd
        case .cash_flow:
            rowEnd = "fin-row"
            columnStart = "fin-col"
            dataStart = "<span>"
            dataEnd = "</span>"
            tableEnd = "</div></div><div></div></div></div></div></div>"
            topRowTitle = "<span>Breakdown</span>"
            topRowEnd = "fin-row"
            topRowDataEnd = dataEnd
        case .analysis:
            rowEnd = "</tr>"
            columnStart = "Ta(end)"
            dataStart = ">"
            dataEnd = "</td>"
            tableEnd = "</tbody></table>"
            topRowTitle = tableStart
            topRowEnd = "</thead><tbody>"
            topRowDataEnd = "</th>"
        case .key_statistics:
            // no top row
            rowEnd = "</tr>"
            columnStart = "Pstart"
            dataStart = ">"
            dataEnd = "</td>"
            tableEnd = "</tbody></table>"
        case .insider_transactions:
            tableStart! += "</h3><span"
            rowEnd = "</tr>"
            columnStart = "Py(10px)"
            dataStart = ">"
            dataEnd = "</td>"
            tableEnd = "</tbody></table>"
        case .quote:
            rowEnd = "}"
            dataStart = ":"
            dataEnd = "\""
        case .profile:
            // Description text block doesn't have dataEnd , ends with rowEnd
            rowEnd = "</p>"
            dataStart = ">"
            dataEnd = "</span></span>"
        }
    }
}

struct YahooDownloadJobs {
    var pageName = String()
    var tableTitles = [String?]()
    var rowTitles = [[String]]()
    var saveTitles = [[String]]()
    var delimiters: YahooPageDelimiters!
    var url: URL?
    
    init?(symbol: String, shortName: String, pageName: String, tableTitles: [String?], rowTitles: [[String]], saveTitles: [[String]]?=nil) {
        
        guard tableTitles.count == rowTitles.count else {
            ErrorController.addInternalError(errorLocation: "YahooDownloadJobs struct", errorInfo: "mismatch between tables to download \(tableTitles) and rowTitle groups \(rowTitles)")
            return nil
        }
        
        self.pageName = pageName
        self.tableTitles = tableTitles
        self.rowTitles = rowTitles
        self.saveTitles = saveTitles ?? rowTitles

        
        var components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)/\(pageName)")
        components?.queryItems = [URLQueryItem(name: "p", value: symbol)]
        self.url = components?.url

    }
}


class YahooPageScraper {
    
    //MARK: - Download descriptors and delimiters
    class func yahooDownloadJobs(symbol: String, shortName: String, option: DownloadOptions) -> [YahooDownloadJobs]? {
        
        let pages = yahooPageNames(option: option)
        let tableTitles = yahooTableTitles(option: option)
        let rowTitles = yahooRowTitles(option: option)
        let saveTitles = yahooSaveTitles(option: option)
        
        guard pages.count == tableTitles.count && rowTitles.count == tableTitles.count && rowTitles.count == saveTitles.count else  {
            ErrorController.addInternalError(errorLocation: "yahooDownloadJobs function", errorInfo: "mismatch between tables to download \(tableTitles) and rowTitle groups \(rowTitles)")
            return nil
        }
        
        var allJobs = [YahooDownloadJobs]()
        for i in 0..<pages.count {
            if let job = YahooDownloadJobs(symbol: symbol, shortName: shortName, pageName: pages[i], tableTitles: tableTitles[i], rowTitles: rowTitles[i], saveTitles: saveTitles[i]) {
                allJobs.append(job)
            }
        }
        
        return allJobs
    }
    
    class func yahooPageNames(option: DownloadOptions) -> [String] {
        
        var pageNames = [String]()
        
        switch option {
        case .allPossible:
            pageNames = ["financials","balance-sheet","cash-flow", "insider-transactions", "analysis", "key-statistics", "profile"]
        case .dcfOnly:
            pageNames = ["financials","balance-sheet","cash-flow", "analysis", "key-statistics"]
        case .rule1Only:
            pageNames = ["financials","balance-sheet", "insider-transactions", "analysis", "key-statistics"]
        case .wbvOnly:
            pageNames = ["financials","balance-sheet","cash-flow", "insider-transactions", "analysis", "key-statistics"]
        case .yahooKeyStatistics:
            pageNames = ["key-statistics"]
        case .yahooProfile:
            pageNames = ["profile"]
        }

        return pageNames
    }
    
    class func yahooTableTitles(option: DownloadOptions) -> [[String?]] {
        
        var tableTitles = [[String?]]()
        
        // page - [table] - [[rows]]
        // [pages] - [[table]] - [[[rows]]]
        
        switch option {
        case .allPossible:
            tableTitles = [["Income statement"],
                           ["Balance sheet"],
                           ["Cash flow"],
                           ["Insider purchases - Last 6 months"],
                           ["Revenue estimate", "Growth estimates"],
                           ["Valuation measures", nil],
                            [nil]]
        case .dcfOnly:
            tableTitles = [["Income statement"],
                           ["Balance sheet"],
                           ["Cash flow"],
                           ["Revenue estimate", "Growth estimates"],
                           ["Valuation measures", nil]]
         case .rule1Only:
            tableTitles = [["Income statement"],
                           ["Balance sheet"],
                           ["Insider purchases - Last 6 months"],
                           ["Revenue estimate", "Growth estimates"],
                           ["Valuation measures"]]
        case .wbvOnly:
            tableTitles = [["Income statement"],
                           ["Balance sheet"],
                           ["Cash flow"],
                           ["Insider purchases - Last 6 months"],
                           ["Revenue estimate", "Growth estimates"],
                           ["Valuation measures", nil]]
        case .yahooKeyStatistics:
            tableTitles = [[nil]]
        case .yahooProfile:
            tableTitles = [[nil]]
        }
        
        return tableTitles
    }
    
    class func yahooRowTitles(option: DownloadOptions) -> [[[String]]] {
        
        var rowTitles = [[[String]]]()
        
        switch option {
        case .allPossible:
            rowTitles = [
                [["Total revenue","Basic EPS","Net income", "Interest expense","Income before tax","Income tax expense"]],
                [["Current debt","Long-term debt", "Total liabilities"]],
                [["Free cash flow","Operating cash flow","Capital expenditure"]],
                [["Total insider shares held", "Purchases", "Sales"]],
                [["Avg. Estimate", "Sales growth (year/est)"], ["Next year", "Next 5 years (per annum)"]],
                [["Forward P/E","Market cap (intra-day)", "Beta (5Y monthly)"],["Shares outstanding", "Payout ratio"," Trailing annual dividend yield"]],
                [["<span>Sector(s)", "<span>Industry", "span>Full-time employees", "<span>Description"]]]
        case .dcfOnly:
            rowTitles = [
                [["Total revenue", "Net income", "Interest expense","Income before tax","Income tax expense"]],
                [["Current debt","Long-term debt"]],
                [["Free cash flow","Capital expenditure"]],
                [["Avg. Estimate", "Sales growth (year/est)"], ["Next year", "Next 5 years (per annum)"]],
                [["Market cap (intra-day)", "Beta (5Y monthly)"],["Shares outstanding", "Payout ratio"," Trailing annual dividend yield"]]
                ]
         case .rule1Only:
            rowTitles = [
                [["Total revenue","Basic EPS","Net income"]],
                [["Current debt","Long-term debt"]],
                [["Total insider shares held", "Purchases", "Sales"]],
                [["Avg. Estimate", "Sales growth (year/est)"], ["Next year", "Next 5 years (per annum)"]],
                [["Forward P/E"]]
                ]
        case .wbvOnly:
            rowTitles = [
                [["Total revenue","Basic EPS","Net income", "Interest expense","Income before tax","Income tax expense"]],
                [["Current debt","Long-term debt", "Total liabilities"]],
                [["Free cash flow","Operating cash flow","Capital expenditure"]],
                [["Total insider shares held", "Purchases", "Sales"]],
                [["Avg. Estimate", "Sales growth (year/est)"], ["Next year", "Next 5 years (per annum)"]],
                [["Forward P/E","Market cap (intra-day)", "Beta (5Y monthly)"],["Shares outstanding", "Payout ratio"," Trailing annual dividend yield"]]]
        case .yahooKeyStatistics:
            rowTitles = [[["Beta (5Y monthly)", "Trailing P/E", "Diluted EPS", "Trailing annual dividend yield"]]] // titles differ from the ones displayed on webpage!
        case .yahooProfile:
            rowTitles = [[["<span>Sector(s)", "<span>Industry<", "span>Full-time employees", "<span>Description"]]]
        }
        
        return rowTitles
    }
    
    class func yahooSaveTitles(option: DownloadOptions) -> [[[String]]] {
        
        var saveTitles = [[[String]]]()
        
        switch option {
        case .allPossible:
            saveTitles = [
                [["Revenue","EPS - Earnings Per Share", "Net Income","Interest expense","Income before tax","Income tax expense"]],
                [["Current debt","Long-term Debt","Total liabilities"]],
                [["Free cash flow", "Operating cash flow","Capital expenditure"]],
                [["Total insider shares held", "Purchases", "Sales"]],
                [["Avg. Estimate", "Sales growth (year/est)"], ["Next year", "Next 5 years (per annum)"]],
                [["Forward P/E","Market cap (intra-day)", "Beta (5Y monthly)"],["Shares outstanding", "Payout ratio"," Trailing annual dividend yield"]],
                [["Sector", "Industry", "Employees", "Description"]]]
            
        case .dcfOnly:
            saveTitles = [
                [["Revenue","Net Income","Interest expense","Income before tax","Income tax expense"]],
                [["Current debt","Long-term Debt"]],
                [["Free cash flow", "Capital expenditure"]],
                [["Avg. Estimate", "Sales growth (year/est)"], ["Next year", "Next 5 years (per annum)"]],
                [["Market cap (intra-day)", "Beta (5Y monthly)"],["Shares outstanding", "Payout ratio","Trailing annual dividend yield"]]]
        case .rule1Only:
            print()
        case .wbvOnly:
            saveTitles = [
                [["Revenue","EPS - Earnings Per Share", "Net Income","Interest expense","Income before tax","Income tax expense"]],
                [["Current debt","Long-term Debt","Total liabilities"]],
                [["Free cash flow", "Operating cash flow","Capital expenditure"]],
                [["Total insider shares held", "Purchases", "Sales"]],
                [["Avg. Estimate", "Sales growth (year/est)"],["Next year", "Next 5 years (per annum)"]],
                [["Forward P/E","Market cap (intra-day)", "Beta (5Y monthly)"]],
                [["Shares outstanding", "Payout ratio","Trailing annual dividend yield"]]]
        case .yahooKeyStatistics:
            saveTitles = [[["Beta (5Y monthly)", "Trailing P/E", "EPS - Earnings Per Share", "Trailing annual dividend yield"]]] // titles differ from the ones
        case .yahooProfile:
            saveTitles = [[["Sector", "Industry", "Employees", "Description"]]]
        }
        
        return saveTitles
    }

    class func yahooAllDataRowTitles() -> [[String]] {

        return [
            ["Total revenue","Basic EPS","Net income", "Interest expense","Income before tax","Income tax expense"],
            ["Current debt","Long-term debt", "Total liabilities"],
            ["Free cash flow","Operating cash flow","Capital expenditure"],
            ["Total insider shares held", "Purchases", "Sales"],
            ["Avg. Estimate", "Sales growth (year/est)"],
            ["Next year", "Next 5 years (per annum)"],
            ["Forward P/E","Market cap (intra-day)", "Beta (5Y monthly)"],
            ["Shares outstanding", "Payout ratio"," Trailing annual dividend yield"]]

    }
    
    // MARK: - central download function
    
    /// missing arrays for BVPS, ROI, OPCF/s and PE Hx
    class func dataDownloadAnalyseSave(symbol: String, shortName: String, shareID: NSManagedObjectID, option: DownloadOptions, progressDelegate: ProgressViewDelegate?=nil,downloadRedirectDelegate: DownloadRedirectionDelegate?) async {
        
//        guard shortName != nil else {
//            ErrorController.addInternalError(errorLocation: #function, errorInfo: "Yahoo dowload \(symbol) \(option) requested with missing shortName")
//            return
//        }
        
        guard let downloadJobs = yahooDownloadJobs(symbol: symbol, shortName: shortName, option: option) else {
            return
        }
        
        var results = [Labelled_DatedValues]()
        var count = 0
        for job in downloadJobs {
            
            guard let url = job.url else {
                ErrorController.addInternalError(errorLocation: #function, errorInfo: "invalid URL from job \(job)")
                continue
            }
            
            guard let htmlText = await Downloader.downloadDataNoThrow(url: url) else {
                ErrorController.addInternalError(errorLocation: #function, errorInfo: "failed to download page text for \(job.pageName) for \(symbol)")
                continue
            }
            
            let type = getPageType(url: url)

            if var extractionResults = YahooPageScraper.extractPageData(html: htmlText, pageType: type, tableHeaders: job.tableTitles, rowTitles: job.rowTitles, replacementRowTitles: job.saveTitles) {
                
                // extract Currency from Yahoo>Analysis page
                if job.pageName == "analysis" {
                    if let currencyPosition = htmlText.range(of: "Currency in ") {
                        if let currencyEndPosition = htmlText.range(of: "</span>", range: currencyPosition.upperBound..<htmlText.endIndex) {
                            let shareCurrency = String(htmlText[currencyPosition.upperBound..<currencyEndPosition.lowerBound])
                            var userInfo = [String: String]()
                            userInfo["symbol"] = symbol
                            
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "CurrencyFound"), object: shareCurrency, userInfo: userInfo)
                        }
                    }
                }

                
                for i in 0..<extractionResults.count {
                    if extractionResults[i].label == "Sales" || extractionResults[i].label.contains("Purchases") || extractionResults[i].label.contains("Total insider shares") {
                        extractionResults[i].datedValues = [extractionResults[i].datedValues[0]]
                    }
                }
                results.append(contentsOf: extractionResults)
            }

            progressDelegate?.taskCompleted()
            count += 1
        }
        
        /*
        let pageNames = ["financials","balance-sheet","cash-flow", "insider-transactions", "analysis", "analysis", "key-statistics","key-statistics" ] // analysis and key-statistics twice!

        let tableTitles: [String?] = ["Income statement", "Balance sheet", "Cash flow", "Insider purchases - Last 6 months", "Revenue estimate", "Growth estimates", "Valuation measures", nil]

        let rowTitles = yahooAllDataRowTitles()
        
        let saveTitles = [
            ["Revenue","EPS - Earnings Per Share", "Net Income","Interest expense","Income before tax","Income tax expense"],
            ["Current debt","Long Term Debt","Total liabilities"],
            ["Free cash flow", "Operating cash flow","Capital expenditure"],
            ["Total insider shares held", "Purchases", "Sales"],
            ["Avg. Estimate", "Sales growth (year/est)"],
            ["Next year", "Next 5 years (per annum)"],
            ["Forward P/E","Market cap (intra-day)", "Beta (5Y monthly)"],
            ["Shares outstanding", "Payout ratio"," Trailing annual dividend yield"]]
                
        //
        var count = 0
        for pageName in pageNames {
                        
            var components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)/\(pageName)")
            components?.queryItems = [URLQueryItem(name: "p", value: symbol)]
            
            guard let url = components?.url else {
                progressDelegate?.downloadError(error: InternalErrorType.urlInvalid.localizedDescription)
                continue
            }

            let type = getPageType(url: url)

            guard let htmlText = await Downloader.downloadDataNoThrow(url: url) else {
                ErrorController.addInternalError(errorLocation: #function, errorInfo: "failed to download page text for \(pageName) for \(symbol)")
                continue
            }

            // extract Currency from Yahoo>Analysis page
            if pageName == "analysis" {
                if let currencyPosition = htmlText.range(of: "Currency in ") {
                    if let currencyEndPosition = htmlText.range(of: "</span>", range: currencyPosition.upperBound..<htmlText.endIndex) {
                        let shareCurrency = String(htmlText[currencyPosition.upperBound..<currencyEndPosition.lowerBound])
                        var userInfo = [String: String]()
                        userInfo["symbol"] = symbol
                        
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "CurrencyFound"), object: shareCurrency, userInfo: userInfo)
                    }
                }
            }

            if var extractionResults = YahooPageScraper.extractPageData(html: htmlText, pageType: type, tableHeaders: tableTitles[count], rowTitles: rowTitles[count],replacementRowTitles: saveTitles[count]) {
                
                
                for i in 0..<extractionResults.count {
                    if extractionResults[i].label == "Sales" || extractionResults[i].label.contains("Purchases") || extractionResults[i].label.contains("Total insider shares") {
                        extractionResults[i].datedValues = [extractionResults[i].datedValues[0]]
                    }
                }
                results.append(contentsOf: extractionResults)
            }
            
            progressDelegate?.taskCompleted()
            count += 1
            
        }
        */
        
        print("all Yahoo data ++++++++++++++")
        for value in results {
            print(value.label)
            for dv in value.datedValues {
                print(dv)
            }
        }
        
        let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc.automaticallyMergesChangesFromParent = true
        
        do {
            if let bgShare = backgroundMoc.object(with: shareID) as? Share {
                try await bgShare.mergeInDownloadedData(labelledDatedValues: results)
            }
        } catch {
            ErrorController.addInternalError(errorLocation: #function, systemError: error ,errorInfo: "failed to save downloadde data for \(symbol)")
        }
        
    }

    /*
    /// missing arrays for BVPS, ROI, OPCF/s and PE Hx
    class func rule1DownloadAndAnalyse(symbol: String, shareID: NSManagedObjectID, progressDelegate: ProgressViewDelegate?=nil, avoidMTTitles: Bool?=nil ,downloadRedirectDelegate: DownloadRedirectionDelegate?) async -> [Labelled_DatedValues]? {
        
//        let results = await allAnnualData_DownloadAnalyseSave(symbol: symbol, shareID: shareID, option: .rule1Only, downloadRedirectDelegate: downloadRedirectDelegate)
//        return results
        
        /*
        var results = [Labelled_DatedValues]()
        
        let pageNames = (avoidMTTitles ?? false) ? ["insider-transactions", "analysis", "key-statistics","cash-flow"] : ["financials","balance-sheet","cash-flow", "insider-transactions", "analysis", "key-statistics"]

        let tableTitles = (avoidMTTitles ?? false) ? ["Balance sheet", "Insider purchases - Last 6 months", "Revenue estimate", "Valuation measures", "Cash flow"] : ["Income statement", "Balance sheet", "Cash flow", "Insider purchases - Last 6 months", "Revenue estimate", "Valuation measures"]

        let rowTitles = (avoidMTTitles ?? false) ? [["Total insider shares held", "Purchases", "Sales"], ["Sales growth (year/est)"],["Forward P/E"], ["Free cash flow"]] : [["Total revenue","Basic EPS","Net income"], ["Total non-current liabilities", "Common stock"],["Net cash provided by operating activities", "Free cash flow"],["Total insider shares held", "Purchases", "Sales"], ["Sales growth (year/est)"],["Forward P/E"]]
        
        let saveTitles = (avoidMTTitles ?? false) ? [["Total insider shares held", "Purchases", "Sales"],["Sales growth (year/est)"],["Forward P/E"],["Free cash flow"]] : [["Revenue","EPS - Earnings Per Share", "Net Income"], ["Long Term Debt", "Common stock"],["Operating cash flow","Free cash flow"],["Total insider shares held", "Purchases", "Sales"],["Sales growth (year/est)"],["Forward P/E"]]
        

        var count = 0
        for pageName in pageNames {
                        
            var components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)/\(pageName)")
            components?.queryItems = [URLQueryItem(name: "p", value: symbol)]
            
            guard let url = components?.url else {
                progressDelegate?.downloadError(error: InternalErrorType.urlInvalid.localizedDescription)
                continue
            }

            let type = getPageType(url: url)

//            var htmlText = String()
//
//            do {
            guard let htmlText = await Downloader.downloadDataNoThrow(url: url) else {
                ErrorController.addInternalError(errorLocation: #function, errorInfo: "failed page text download for \(symbol) \(pageName)")
                continue
            }
//            } catch let error as InternalErrorType {
//                progressDelegate?.downloadError(error: error.localizedDescription)
//                continue
//            }

            // extract Currency from Yahoo>Analysis page
            if pageName == "analysis" {
                if let currencyPosition = htmlText.range(of: "Currency in ") {
                    if let currencyEndPosition = htmlText.range(of: "</span>", range: currencyPosition.upperBound..<htmlText.endIndex) {
                        let shareCurrency = String(htmlText[currencyPosition.upperBound..<currencyEndPosition.lowerBound])
                        var userInfo = [String: String]()
                        userInfo["symbol"] = symbol
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "CurrencyFound"), object: shareCurrency, userInfo: userInfo)
                    }
                }
            }

            if var extractionResults = YahooPageScraper.extractPageData(html: htmlText, pageType: type, tableHeaders: tableTitles[count], rowTitles: rowTitles[count],replacementRowTitles: saveTitles[count]) {
                
                
                for i in 0..<extractionResults.count {
                    if extractionResults[i].label == "Sales" || extractionResults[i].label.contains("Purchases") || extractionResults[i].label.contains("Total insider shares") {
                        extractionResults[i].datedValues = [extractionResults[i].datedValues[0]]
                    }
                }
                results.append(contentsOf: extractionResults)
            }
            
            progressDelegate?.taskCompleted()
            count += 1
            
        }
        
        return results
        */
    }
     */
    
    class func dcfDownloadAnalyseAndSave(shareSymbol: String?, shortName: String?=nil, shareID: NSManagedObjectID, progressDelegate: ProgressViewDelegate?=nil) async throws {
        
        guard let symbol = shareSymbol else {
            progressDelegate?.downloadError(error: "Failed DCF valuation download: missing share symbol")
            throw InternalErrorType.shareSymbolMissing
        }
         
 // 1 Download and analyse web page data
//        var results = [LabelledValues]()
        var datedResults = [Labelled_DatedValues]()
        let allTasks = shortName != nil ? 8 : 7
        var progressTasks = 0
        
        let rowNames = [["Market cap (intra-day)", "Beta (5Y monthly)", "Shares outstanding", "Payout ratio"],["Total revenue", "Net income", "Interest expense","Income before tax","Income tax expense"],["Current debt","Long-term debt", "Total liabilities"],["Operating cash flow","Capital expenditure", "Free cash flow"],["Avg. Estimate", "Sales growth (year/est)"], ["Next year","Next 5 years (per annum)"]]
        
        
        var i = 0
        // analysis twice! as table segments are different and overlap of toprow titles with 'Next' row titles
        for title in ["key-statistics", "financials", "balance-sheet", "cash-flow", "analysis","analysis"] {
            var components: URLComponents?
            
            components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)/\(title)")
            components?.queryItems = [URLQueryItem(name: "p", value: shareSymbol)]
            
            guard let url = components?.url else {
                progressDelegate?.downloadError(error: "Failed DCF valuation download for \(symbol): invalid url")
                throw InternalErrorType.urlInvalid
            }
            
            var htmlText = String()
            do {
                htmlText = try await Downloader.downloadData(url: url)
            } catch {
                progressDelegate?.downloadError(error: "Failed DCF valuation download for \(symbol): \(error.localizedDescription)")
            }
            
            progressTasks += 1
            progressDelegate?.progressUpdate(allTasks: allTasks, completedTasks: progressTasks)
            
            let tableHeaders = (title == "analysis") ? ["Revenue estimate","Growth estimates"] : nil
            let tableHeader = (i > 3) ? tableHeaders![i-4] : nil
            
            var extractionResults = YahooPageScraper.extractPageData(html: htmlText, pageType: YahooPageScraper.getPageType(url: url), tableHeaders: [tableHeader], rowTitles: [rowNames[i]])

            if extractionResults != nil {
                if title == "analysis" {

                    for j in 0..<(extractionResults?.count ?? 0) {
                        // need last two results only for 'current year' and 'next year'
                        if !(extractionResults![j].label.starts(with: "Next")) {
                            if extractionResults![j].datedValues.count > 2 {
                                extractionResults![j].datedValues = [extractionResults![j].datedValues[2], extractionResults![j].datedValues[3]]
                            }
                        }
                    }
                }
                
               datedResults.append(contentsOf: extractionResults!.sortAllElementDatedValues(dateOrder: .ascending))
            }
            
//            lvs = extractionResults?.convertToLabelledValues(dateOrder: .ascending)
             //
            
            
//            if var labelledResults = lvs {
//
//                for j in 0..<labelledResults.count {
//
//                    if title == "analysis" {
//                        // need last two results only for 'current year' and 'next year'
//                        if labelledResults[j].values.count > 3 {
//                            labelledResults[j].values = [labelledResults[j].values[2], labelledResults[j].values[3]]
//                        } else if labelledResults[j].values.count == 1 {
//                            labelledResults[j].values = [labelledResults[j].values[0]]
//                        }
//                    }
//                }
//
//                results.append(contentsOf: labelledResults)
//            }
//
            i += 1
        }
        
        // also need 'netBorrowings' from MT for DCF
        let pageTitle = "cash-flow-statement"
        let rowTitle = "Debt Issuance/Retirement Net - Total"
        if let shortname = shortName {
            
            if let netBorrowingsDV = try await MacrotrendsScraper.selectMTDataDownloadAnalyse(symbol: symbol, shortName: shortname, pageNames: [pageTitle], rowTitles: [[rowTitle]], progressDelegate: progressDelegate ,downloadRedirectDelegate: nil) {
                
                datedResults.append(contentsOf: netBorrowingsDV)
            }
            
        }
        
        print()
        for result in datedResults {
            print(result)
        }
//
//        print()
//        for result in oldResults {
//           print(result)
//        }
        
        
            
        // 2 Save data to background DCFValuation
        let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc.automaticallyMergesChangesFromParent = true
        
        if let share = backgroundMoc.object(with: shareID) as? Share {
            try await share.mergeInDownloadedData(labelledDatedValues: datedResults)
        }
        
        /*
        await backgroundMoc.perform {
            do {
                if let share = backgroundMoc.object(with: shareID) as? Share {
                    
                    //NEW
                    let keyStats = share.key_stats ?? Key_stats(context: backgroundMoc)
                    keyStats.share = share
                    
                    let incomeStatement = share.income_statement ?? Income_statement(context: backgroundMoc)
                    incomeStatement.share = share
                    
                    let balanceSheet = share.balance_sheet ?? Balance_sheet(context: backgroundMoc)
                    balanceSheet.share = share
                    
                    let cashFlowStatement = share.cash_flow ?? Cash_flow(context: backgroundMoc)
                    cashFlowStatement.share = share

                    let analysis = share.analysis ?? Analysis(context: backgroundMoc)
                    analysis.share = share
                    
                    let dcfv = share.dcfValuation ?? DCFValuation(context: backgroundMoc)
                    dcfv.share = share
                    dcfv.creationDate = Date()

                    for result in datedResults {
                        if result.datedValues.count > 0 {
                            switch result.label {
                            case _ where result.label.starts(with: "Market cap (intra-day)"):
                                keyStats.marketCap = result.datedValues.convertToData()
                            case _ where result.label.starts(with: "Beta (5Y monthly)"):
                                keyStats.beta = result.datedValues.convertToData()
                            case _ where result.label.starts(with: "Shares outstanding"):
                                keyStats.sharesOutstanding = [result.datedValues.last!].convertToData()
                            case _ where result.label.starts(with: "Total revenue"):
                                // don't replace any existing macrotrends data as Yahoo only has last four years
                                if !(incomeStatement.revenue.convertToDatedValues(dateOrder: .ascending)?.count ?? 0 > result.datedValues.count) {
                                    incomeStatement.revenue = result.datedValues.convertToData()
                                }
                            case _ where result.label.starts(with: "Net income"):
                                // don't replace any existing macrotrends data as Yahoo only has last four years
                                if !(incomeStatement.netIncome.convertToDatedValues(dateOrder: .ascending)?.count ?? 0 > result.datedValues.count) {
                                    incomeStatement.netIncome = result.datedValues.convertToData()
                                }
                            case _ where result.label.starts(with: "Interest expense"):
                                incomeStatement.interestExpense = result.datedValues.convertToData()
                            case _ where result.label.starts(with: "Income before tax"):
                                // don't replace any existing macrotrends data as Yahoo only has last four years
                                if !(incomeStatement.preTaxIncome.convertToDatedValues(dateOrder: .ascending)?.count ?? 0 > result.datedValues.count) {
                                    incomeStatement.preTaxIncome = result.datedValues.convertToData()
                                }
                            case _ where result.label.starts(with: "Income tax expense"):
                                incomeStatement.incomeTax = [result.datedValues.last!].convertToData()
                            case _ where result.label.starts(with: "Current debt"):
                                balanceSheet.debt_shortTerm = [result.datedValues.last!].convertToData()
                            case _ where result.label.starts(with: "Long-term debt"):
                                balanceSheet.debt_longTerm = [result.datedValues.last!].convertToData()
                            case _ where result.label.starts(with: "Total liabilities"):
                                balanceSheet.debt_total = [result.datedValues.last!].convertToData()
                            case _ where result.label.starts(with: "Operating cash flow"):
                                
                                // don't replace any existing macrotrends data as Yahoo only has last four years
                                if !(cashFlowStatement.opCashFlow.convertToDatedValues(dateOrder: .ascending)?.count ?? 0 > result.datedValues.count) {
                                    cashFlowStatement.opCashFlow = result.datedValues.convertToData()
                                }
                            case _ where result.label.starts(with: "Capital expenditure"):
                                cashFlowStatement.capEx = result.datedValues.convertToData()
                            case _ where result.label.starts(with: "Avg. Estimate"):
                                analysis.future_revenue = result.datedValues.convertToData()
                            case _ where result.label.starts(with: "Sales growth (year/est)"):
                                analysis.future_revenueGrowthRate = result.datedValues.convertToData()
                            case _ where result.label.starts(with: "Next year"):
                                analysis.future_growthNextYear = result.datedValues.convertToData()
                            case _ where result.label.starts(with: "Next 5 years"):
                                analysis.future_growthNext5pa = result.datedValues.convertToData()
                              case _ where result.label.starts(with: "Debt Issuance"):
                                    analysis.share?.cash_flow?.netBorrowings = result.datedValues.convertToData()
                            case _ where result.label.starts(with: "Payout ratio"):
                                  analysis.share?.key_stats?.dividendPayoutRatio = result.datedValues.convertToData()
                           default:
                                ErrorController.addInternalError(errorLocation: "WebPageScraper2.dcfDataDownload", systemError: nil, errorInfo: "unspecified result label \(result.label) for share \(symbol)")
                            }
                        }
                    }
                    
                    if let dcfv = share.dcfValuation {
                        let (dcfValue, _) = dcfv.returnIValueNew()
                        if dcfValue != nil {
                            let trendValue = DatedValue(date: dcfv.creationDate!, value: dcfValue!)
//                            dcfv.share?.saveTrendsData(datedValuesToAdd: [trendValue], trendName: .dCFValue)
                            dcfv.addIntrinsiceValueTrendAndSave(date: Date(), price: dcfValue!)
                        }
                    }
                    
                   try backgroundMoc.save()
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateValuationData"), object: nil, userInfo: nil)
                }
            }
            catch {
                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "error trying to save DCF data after download")
            }
        }
        */
    }

    /// downloads beta, trailing PE, EPS, Foward annual div. yiels
    class func keyratioDownloadAndSave(shareSymbol: String?, shortName: String?, shareID: NSManagedObjectID, delegate: ProgressViewDelegate?=nil) async throws {
        
        guard let symbol = shareSymbol else {
            throw InternalErrorType.shareSymbolMissing
        }
        
        guard var shortName = shortName else {
            throw InternalErrorType.shareShortNameMissing
        }
        
        if shortName.contains(" ") {
            shortName = shortName.replacingOccurrences(of: " ", with: "-")
        }
        
        guard var components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)/key-statistics") else {
            throw InternalErrorType.urlInvalid
        }
        components.queryItems = [URLQueryItem(name: "p", value: symbol), URLQueryItem(name: ".tsrc", value: "fin-srch")]

        guard let url = components.url else {
            throw InternalErrorType.urlError
        }
        
        let htmlText = try await Downloader.downloadData(url: url)
                    
        let rowTitles = ["Beta (5Y monthly)", "Trailing P/E", "Diluted EPS", "Trailing annual dividend yield"] // titles differ from the ones displayed on webpage!
        
        var results = [Labelled_DatedValues]()
        
        if let extractionResults = YahooPageScraper.extractPageData(html: htmlText, pageType: .key_statistics, tableHeaders: [nil], rowTitles: [rowTitles]) {
            results.append(contentsOf: extractionResults)
        }
        
        let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc.automaticallyMergesChangesFromParent = true
        
        do {
            if let bgShare = backgroundMoc.object(with: shareID) as? Share {
                try await bgShare.mergeInDownloadedData(labelledDatedValues: results)
            }
        } catch {
            ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "couldn't save background MOC")
        }

    }
    
    /// using yahoo as source
    class func dividendsHxFileDownload(symbol: String, companyName: String, years: TimeInterval) async -> [DatedValue]? {
        
        let nowSinceRefDate = Date().timeIntervalSince(yahooRefDate)
        let tenYearsAgoSinceRefDate = Date().addingTimeInterval(-years*year).timeIntervalSince(yahooRefDate)

        let start$ = numberFormatter.string(from: nowSinceRefDate as NSNumber) ?? ""
        let end$ = numberFormatter.string(from: tenYearsAgoSinceRefDate as NSNumber) ?? ""
        var urlComponents = URLComponents(string: "https://query1.finance.yahoo.com/v7/finance/download/\(symbol)")

        urlComponents?.queryItems = [
            URLQueryItem(name: "period1", value: end$),
            URLQueryItem(name: "period2", value: start$),
            URLQueryItem(name: "interval", value: "1d"),
            URLQueryItem(name: "events", value: "div"),
            URLQueryItem(name: "includeAdjustedClose", value: "true") ]

        guard let url = urlComponents?.url else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "invalid url for downloading yahoo Hx dividend .csv file")
           return nil
        }
        
        let expectedHeaderColumnTitles = ["Date", "Dividends"]

        do {
            guard let csvFileURL = try await Downloader.downloadCSVFile2(url: url, symbol: symbol, type: "_Div") else {
                ErrorController.addInternalError(errorLocation: #function, errorInfo: "Failed Dividend CSV File download from Yahoo for \(symbol)")
                return nil
            }
            
            
            var iterator = csvFileURL.lines.makeAsyncIterator()
            
            if let headerRow = try await iterator.next() {
                let titles: [String] = headerRow.components(separatedBy: ",")
                if !(titles == expectedHeaderColumnTitles) {
                    ErrorController.addInternalError(errorLocation: #function, errorInfo: "Dividend CSV File downloadwd from Yahoo for \(symbol) does not have expected header row titles \(headerRow)")
                    return nil
                }
                else {
                    let minDate = Date().addingTimeInterval(-years*year)
                    if let datedValues = try await analyseValidatedYahooCSVFile(localURL: csvFileURL, minDate: minDate) {
                        
                        var datedDividends = [DatedValue]()
                        for dv in datedValues {
                            datedDividends.append(DatedValue(date: dv.date, value: dv.values[0]))
                        }
                        return datedDividends
                    }
                }
            }
        } catch {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "Failure to analyse CSV File download from Yahoo for \(symbol)")
           return nil
        }


        return nil
    }
    
    class func dailyPricesDownloadAndAnalyse(shareSymbol: String, minDate:Date?=nil) async throws -> [PricePoint]? {

// 2 data download usually for the last 3 momnths or so
        var urlComponents = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(shareSymbol)/history")
        urlComponents?.queryItems = [URLQueryItem(name: "p", value: shareSymbol)]
        
        
        guard let sourceURL = urlComponents?.url else {
            throw InternalError(location: "WebScraper2.downloadAndAnalyseDailyTradingPrices", errorInfo: "\(String(describing: urlComponents))", errorType: .urlInvalid)
        }
        
        let dataText = try await Downloader.downloadData(url: sourceURL)

        let downloadedPricePoints = YahooPageScraper.priceTableAnalyse(html$: dataText, limitDate: minDate)

        return downloadedPricePoints
    }
    
    class func profileDownloadAndAnalyse(share: Share) async -> ProfileData? {
        
        var components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(share.symbol!)/profile")
        components?.queryItems = [URLQueryItem(name: "p", value: (share.symbol!))]

        guard let url = components?.url else { return nil }
        
        guard let htmlText = await Downloader.downloadDataNoThrow(url: url) else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "profile download failed for \(share)")
            return nil
        }

        
        let rowTitles = ["<span>Sector(s)</span>:", "<span>Industry</span>:", "span>Full-time employees</span>:", "<span>Description</span></h2>"] // titles differ from the ones displayed on webpage!
        
        var sector = String()
        var industry = String()
        var employees = Double()
        var description = String()

        for title in rowTitles {
                        
            if title.contains("Sector") {
                let strings = scrapeRowForText(html$: htmlText, rowTitle: title , rowTerminal: ",", textTerminal: "\"")

                if let valid = strings.first {
                        sector = valid
                }
            } else if title.contains("Industry") {
                let strings = scrapeRowForText(html$: htmlText, rowTitle: title , rowTerminal: ",", textTerminal: "\"")

                
                if let valid = strings.first {
                        industry = valid
                }
            } else if title.contains("Employees") {
                if let value = extractOneDouble(html$: htmlText, rowTitle: title , rowTerminal: "</p></div></div>", numberTerminal: "</span></span>") {
                
                    employees = value
                }
            } else if title.contains("Description") {
                description = getTextBlock(html$: htmlText, rowTitle: title , rowTerminal: "", textTerminal: "</p></section>")
            }
        }
        
        return ProfileData(sector: sector, industry: industry, employees: employees, description: description)
    }

    /// providing a limit date stops the analysis after encountering that date. Providing a specific date looks for pricepoint data closest to that date only. Don't send both limit AND specific dates
    class func priceTableAnalyse(html$: String, limitDate: Date?=nil, specificDate:Date?=nil) -> [PricePoint]? {
        
        let tableEnd$ = "</tbody><tfoot>"
        let tableStart$ = "<thead>"
        
        let rowStart$ = "Ta(start)"
        let rowEnd = "</span></td>"
        
        
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM yyyy"
            formatter.calendar.timeZone = TimeZone(identifier: "UTC")!
            return formatter
        }()

        var pageText = html$
        
        // eliminate above table start
        if let tableStartIndex = pageText.range(of: tableStart$) {
            pageText.removeSubrange(...tableStartIndex.upperBound)
        } else {
            return nil
        }

        // eliminate below table end
        if let tableEndIndex = pageText.range(of: tableEnd$) {
            pageText.removeSubrange(tableEndIndex.upperBound...)
        } else {
            return nil
        }

        // table should have 7 columns: Date, Open, High, Low, Close, Ajd. close , Volume
        
        var pricePoints = [PricePoint]()
        
        var rowStartIndex = pageText.range(of: rowStart$, options: .backwards)
        var count = 0
        while rowStartIndex != nil {
            
            var tradingDate: Date?
            
            var values = [Double]()
            
            var rowText = pageText[rowStartIndex!.upperBound...]
            
            count = 0
            var columnEndIndex = rowText.range(of: rowEnd, options: .backwards)
            while columnEndIndex != nil {
                rowText.removeSubrange(columnEndIndex!.lowerBound...)
                if let dataIndex = rowText.range(of: ">", options: .backwards) {
                    // loading webpage outside OS browser loads September as 'Sept' which has no match in dateFormatter.
                    // needs replacing with 'Sep'
                    let data = rowText[dataIndex.upperBound...]
                    let data$ = data.replacingOccurrences(of: "Sept", with: "Sep")
//                    if data$.contains("Sept") {
//                        if let septIndex = data$.range(of: "Sept") {
//                            data$.replaceSubrange(septIndex, with: "Sep")
//                        }
//                    }

                    if count == 6 {
                        if let date = dateFormatter.date(from: String(data$)) {
                            tradingDate = date
                        }
                    }
                    else if let value = Double(data$.filter("-0123456789.".contains)) {
                            values.append(value)
                    }
                }
                else {
                    values.append(Double())
                }
                columnEndIndex = rowText.range(of: rowEnd, options: .backwards)
                count += 1
            }
            
            if values.count == 6 && tradingDate != nil {
                
                if specificDate == nil {
                    let newPricePoint = PricePoint(open: values[5], close: values[2], low: values[3], high: values[4], volume: values[0], date: tradingDate!)
                    pricePoints.append(newPricePoint)
                } else {
                    if tradingDate! < specificDate! {
                        let specificPricePoint = PricePoint(open: values[5], close: values[2], low: values[3], high: values[4], volume: values[0], date: tradingDate!)
                        return [specificPricePoint]
                    }
                }
                
                if let limit = limitDate {
                    if (tradingDate ?? Date()) < limit {
                        return pricePoints
                    }
                }
            }
            
            pageText.removeSubrange(rowStartIndex!.lowerBound...)
            rowStartIndex = pageText.range(of: rowStart$, options: .backwards)
        }

        return pricePoints
    }
    
    class func companyNameSearchOnPage(html: String) throws -> [String: String]? {
        
        var pageText = html
//        let sectionStart = "<span>Exchange"
        let tableStart$ = "</thead>"
        let rowStart$ = "/quote/"
        let tableEnd$ = "</table>"
        let title$ = "title=\""
        let symbol$ = "data-symbol=\""
        let termEnd$ = "\""

        guard let tableStartIndex = pageText.range(of: tableStart$) else {
            throw InternalError(location: #function, errorInfo: "did not find \(tableStart$)) on Yahoo company name search page", errorType: .htmlTableSequenceStartNotFound)
        }
        pageText.removeSubrange(...tableStartIndex.upperBound)
        
        guard let firstRowStartIndex = pageText.range(of: rowStart$) else {
            throw InternalError(location: #function, errorInfo: "did not find \(rowStart$)) on Yahoo company name search page", errorType: .htmlRowStartIndexNotFound)
        }
        pageText.removeSubrange(...firstRowStartIndex.upperBound)
        
        guard let tableEndIndex = pageText.range(of: tableEnd$) else {
            throw InternalError(location: #function, errorInfo: "did not find \(tableEnd$) on Yahoo company name search page", errorType: .htmlTableEndNotFound)
        }
        pageText.removeSubrange(tableEndIndex.upperBound...)
        

        let rows$ = pageText.components(separatedBy: rowStart$)
        
        var sharesFound = [String: String]()
        for row$ in rows$ {
            
            let data = Data(row$.utf8)
            if let content$ = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil).string {
                
                var title: String?
                var symbol: String?
                
                if let titleStartIndex = content$.range(of: title$) {
                    if let titleEndIndex = content$.range(of: termEnd$, range: titleStartIndex.upperBound..<content$.endIndex) {
                        title = String(content$[titleStartIndex.upperBound..<titleEndIndex.lowerBound])
                    }
                }
                
                if let symbolStartIndex = content$.range(of: symbol$) {
                    if let symbolEndIndex = content$.range(of: termEnd$, range: symbolStartIndex.upperBound..<content$.endIndex) {
                        symbol = String(content$[symbolStartIndex.upperBound..<symbolEndIndex.lowerBound])
                    }
                }
                
                if symbol != nil && title != nil {
                    sharesFound[symbol!] = title!
                }
                
            }
        }
        
        return sharesFound
        
    }

    //MARK: - internal functions
    
    /// returns numbers in order left to right, as on web page (date DESCENDING); use for extraction of numbers from tables with rows; not suitable if there are no columnStart and -end sequences
    /// returns ALL column values; filerting needs to happen if not all columns are wanted; if no tableHeader provided searches the enire web page for the rowTitles
    /// ALL numbers are converted to correct figures, so  from 'thousands' in financials' to correct numbers
    class func extractPageData(html: String?, pageType: YahooPageType, tableHeaders: [String?], rowTitles: [[String]], replacementRowTitles:[[String]]?=nil) -> [Labelled_DatedValues]? {
        
        guard let pageText = html else {
            return nil
        }
        
        let yahooDateFormat: DateFormatter = {
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone(identifier: "UTC")!
            formatter.dateFormat = "dd/MM/yyyy"
            return formatter
        }()
        
        var labelledDatedValues = [Labelled_DatedValues]()
        let saveTitles = replacementRowTitles ?? rowTitles
        
        var tableCount = 0
        outer: for header in tableHeaders {
            
            let delimiters = YahooPageDelimiters(pageType: pageType, tableHeader: header, rowTitles: rowTitles[tableCount], saveTitles: saveTitles[tableCount])
            
// some functions don't look for table headers, just row titles
            var tableText = pageText
            if let headerText = delimiters.tableStart {
                if let headerPosition = pageText.range(of: headerText) {
                    if let tableEndPosition = pageText.range(of: delimiters.tableEnd, range: headerPosition.upperBound..<pageText.endIndex) {
                        tableText = String(pageText[headerPosition.upperBound...tableEndPosition.upperBound])
                    } else {
                        tableText = String(pageText[headerPosition.upperBound..<pageText.endIndex])
                    }
                }
            }
            
// analyse the toprow for dates or other data if needed (delimiters set to topRow)
            var topRowDates: [Date]?
            if let topRowTitle = delimiters.topRowTitle {
                
                if let titlePosition = tableText.range(of: topRowTitle) {
                    if let topRowEndPosition = tableText.range(of: delimiters.topRowEnd!, range: titlePosition.upperBound..<tableText.endIndex) {
                        let topRowText = String(tableText[titlePosition.upperBound..<topRowEndPosition.lowerBound])
                        let topRowColumnTexts = topRowText.split(separator: delimiters.dataStart)
                        for text in topRowColumnTexts {
                            if let dEnd = text.range(of: delimiters.dataEnd) {
                                let columnText = text[text.startIndex..<dEnd.lowerBound]
                                if columnText == "ttm" { // not all financials tables have 'TTM" in first column
                                    topRowDates = [DatesManager.endOfDay(of: Date().addingTimeInterval(-24*3600))]
                                }
                                else if let date = yahooDateFormat.date(from: String(columnText)) {
                                    if topRowDates == nil {
                                        topRowDates = [Date]()
                                    }
                                    topRowDates?.append(date)
                                }
                            }
                        }
                    }
                }
            }
            
// set defaults header dates for some pages
            if pageType == .financials || pageType == .balance_sheet || pageType == .cash_flow {
                if topRowDates == nil {
                    // 0 = TTM, but this is not always present!
                    topRowDates = [DatesManager.endOfDay(of: Date().addingTimeInterval((-24*3600)))]
                    // following columns are last 4 years
                    let now = Date()
                    let year = DatesManager.yearOnly(date: now)
                    
                    for rowCount in 0..<4 {
                        let endOfYear = DatesManager.dateFromAString(dateString: "31.12.\(year-rowCount)")!
                        topRowDates?.append(endOfYear)
                    }
                }
            }
            else if pageType == .analysis {
                let now = Date()
                let year = DatesManager.yearOnly(date: now)
                
                topRowDates = [DatesManager.endOfQuarter(of: now)] // current Quarter
                topRowDates?.append(DatesManager.endOfQuarter(of: now.addingTimeInterval(122*24*3600))) // next Quarter
                let endOfThisYear = DatesManager.dateFromAString(dateString: "31.12.\(year+1)")!
                let endOfNextYear = DatesManager.dateFromAString(dateString: "31.12.\(year+2)")!
                topRowDates?.append(endOfThisYear) // current Year
                topRowDates?.append(endOfNextYear)
            }
            
            // get values from the rows below to topRow
            var labelledValues = [LabelledValues]()
            
            var rowCount = 0
            inner: for rStart in delimiters.rowStarts {
                                    
                    // some specific rStart modifications take place in delimiters init
                    
                    var rowValues = [Double]()
                    guard let rowStartPosition = tableText.range(of: rStart) else {
                        labelledValues.append(LabelledValues(label:  delimiters.saveRowTitles[rowCount], values: rowValues))
                        continue
                    }
                    
                    var rowText = String()
                    
                    if let rowEndPosition = tableText.range(of: delimiters.rowEnd ,range: rowStartPosition.upperBound..<tableText.endIndex) {
                        rowText = String(tableText[rowStartPosition.upperBound..<rowEndPosition.lowerBound])
                        
                    } else if let rowEndPosition = tableText.range(of: delimiters.tableEnd ,range: rowStartPosition.upperBound..<tableText.endIndex) {
                        rowText = String(tableText[rowStartPosition.upperBound..<rowEndPosition.lowerBound])
                    } else {
                        labelledValues.append(LabelledValues(label: delimiters.saveRowTitles[rowCount], values: rowValues))
                        continue
                    }
                    
                    if rStart.contains("Sector") || rStart.contains("Industry") || rStart.contains("Employees") {
                        // need to extract text rather than numbers
                        print(rStart)
                        print(rowText)
                        
                        let texts = rowText.split(separator: "<br/>")
                        for text in texts {
                            //TODO: - Lablled_DatedValues not compatible with text - need separate function
                        }
                        
                        continue outer
                    }
                    
                    let columnTexts = rowText.split(separator: delimiters.columnStart).dropFirst() // gibberish after rowTitle
                    
                    if columnTexts.count < 4 && topRowDates?.count ?? 0 > 3 { // assume no TTM column
                        // no TTM column, so drop any default generated
                        topRowDates = Array(topRowDates!.dropFirst()) // get rid of TTM date
                    }
                    
                    for ct in columnTexts {
                        let dataStartPosition = ct.range(of: delimiters.dataStart) ?? ct.range(of: ">")
                        
                        guard dataStartPosition != nil else {
                            rowValues.append(0.0)
                            continue
                        }
                        
                        if let dataEndPosition = ct.range(of: delimiters.dataEnd, range: dataStartPosition!.upperBound..<ct.endIndex)  {
                            let content$ = String(ct[dataStartPosition!.upperBound..<dataEndPosition.lowerBound])
                            if content$ != "" {
                                let rowValue = content$.numberFromText(text: content$)
                                if [.financials, .balance_sheet, .cash_flow].contains(pageType) {
                                    if rStart.contains("EPS") {
                                        rowValues.append(rowValue)
                                    } else {
                                        rowValues.append(rowValue * 1_000)
                                    }
                                } else {
                                    rowValues.append(rowValue)
                                }
                            }
                        } else if let dataEndPosition = ct.range(of: "</div>", range: dataStartPosition!.upperBound..<ct.endIndex)  {
                            let content$ = String(ct[dataStartPosition!.upperBound..<dataEndPosition.lowerBound])
                            if content$ != "" {
                                let rowValue = content$.numberFromText(text: content$)
                                if [.financials, .balance_sheet, .cash_flow].contains(pageType) {
                                    if rStart.contains("EPS") {
                                        rowValues.append(rowValue)
                                    } else {
                                        rowValues.append(rowValue * 1_000)
                                    }
                                    
                                } else {
                                    rowValues.append(rowValue)
                                }
                            }
                        }
                        else {
                            rowValues.append(0.0)
                            continue
                        }
                    }
                    
                    labelledValues.append(LabelledValues(label: delimiters.saveRowTitles[rowCount], values: rowValues))
                    
                    
                    //Merge with top row dates and modify certain values
                    if rStart.starts(with: "Next year") {
                        // use only the first value
                        let now = Date()
                        let year = DatesManager.yearOnly(date: now)
                        let endOfNextYear = DatesManager.dateFromAString(dateString: "31.12.\(year+1)")!
                        
                        let singleLdv = Labelled_DatedValues(label: delimiters.saveRowTitles[rowCount], datedValues: [DatedValue(date: endOfNextYear, value: rowValues.first ?? 0)])
                        labelledDatedValues.append(singleLdv)
                    } else if rStart.starts(with: "Next 5 years") {
                        let now = Date()
                        let year = DatesManager.yearOnly(date: now)
                        var futureYears = [Date]()
                        var datedvalues = [DatedValue]()
                        for y in 2..<5 {
                            let endOfYear = DatesManager.dateFromAString(dateString: "31.12.\(year+y)")!
                            futureYears.append(endOfYear)
                            let dv = DatedValue(date: endOfYear, value: rowValues.first ?? 0)
                            datedvalues.append(dv)
                        }
                        labelledDatedValues.append(Labelled_DatedValues(label:delimiters.saveRowTitles[rowCount], datedValues: datedvalues))
                    }
    //                else if pageType == .profile {
    //                    // Sectot, INdustry, Employees, DEscription
    //                    var datedvalues = [DatedValue]()
    //                    for columnCount in 0..<rowValues.count {
    //                        let datedValues = DatedValue(date: Date(), value: rowValues[columnCount])
    //                        datedvalues.append(datedValues)
    //                    }
    //                    labelledDatedValues.append(Labelled_DatedValues(label:delimiters.saveRowTitles[rowCount], datedValues: datedvalues))                }
                    else if topRowDates?.count ?? 0 >= rowValues.count {
                        var dvs = [DatedValue]()
                        for columnCount in 0..<rowValues.count {
                            let datedValues = DatedValue(date: topRowDates![columnCount], value: rowValues[columnCount])
                            dvs.append(datedValues)
                        }
                        let ldvs = Labelled_DatedValues(label: delimiters.saveRowTitles[rowCount], datedValues: dvs)
                        labelledDatedValues.append(ldvs)
                    }
                    else {
                        // no or not enough dates from top row for key-statistics which are of now/ ttm or predictions
                        var dvs = [DatedValue]()
                        for value in rowValues {
                            dvs.append(DatedValue(date: Date(), value: value))
                        }
                        labelledDatedValues.append(Labelled_DatedValues(label: delimiters.saveRowTitles[rowCount], datedValues: dvs))
                        
                    }
                    
                    rowCount += 1
                }
            
            tableCount += 1
        }
        
        return labelledDatedValues
     }
    
    class func getPageType(url: URL) -> YahooPageType {
        
        let pageName = url.pathComponents.last ?? ""
        
        var type: YahooPageType!
        if pageName.contains("balance") {
            type = .balance_sheet
        } else if pageName.contains("insider") {
            type = .insider_transactions
        } else if pageName.contains("financials") {
            type = .financials
        } else if pageName.contains("analysis") {
            type = .analysis
        } else if pageName.contains("cash") {
            type = .cash_flow
        } else if pageName.contains("statistics") {
            type = .key_statistics
        } else if pageName.contains("profile"){
            type = .profile
        }

        return type
    }
    
    class func singleNumberExtraction(htmlText: String?, figureTitle: String, numberStart: String, numberEnd: String) -> Double? {
        
        guard let pagetext = htmlText else { return nil }
        
        guard let titlePosition = pagetext.range(of: figureTitle) else { return nil }
        
        guard let numberStartPosition = pagetext.range(of: numberStart,range: titlePosition.upperBound..<pagetext.endIndex) else { return nil }
        
        guard let numberEndPosition = pagetext.range(of: numberEnd, range: numberStartPosition.upperBound..<pagetext.endIndex) else { return nil }
        
        let numberText = String(pagetext[numberStartPosition.upperBound..<numberEndPosition.lowerBound])
        
        return numberText.textToNumber()
        
    }
    
    /// it should have been established that the header row contains the expected title BEFORE sending this file; otherwise use 'analyseYahooCSVFile'
    class func analyseValidatedYahooCSVFile(localURL: URL, minDate:Date?=nil) async throws -> [DatedValues]? {
        
        var columnContents = [DatedValues]()
        
        for try await line in localURL.lines {
            let rowContents = line.components(separatedBy: ",")
            var date: Date?
            var values = [Double]()
            
            for content in rowContents {
                if let d = yahooCSVFileDateFormatter.date(from: content) {
                    date = d
                } else if let value = Double(content) {
                    values.append(value)
                }
            }
            
            if let valid = date {
                if let earliestDate = minDate {
                    if valid < earliestDate { break }
                }
                columnContents.append((DatedValues(date: valid, values: values)))
            }
            
        }
        
        return columnContents
    }

    class func scrapeRowForText(html$: String?, sectionHeader: String?=nil, sectionTerminal: String?=nil, rowTitle: String, rowTerminal: String? = nil, textTerminal: String? = nil, webpageExponent: Double?=nil) -> [String] {
        
        guard var pageText = html$ else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "empty web page")
            return [String]()
        }
        
        let sectionTitle: String? = (sectionHeader != nil) ? (">" + sectionHeader!) : nil
        let rowStart = rowTitle
        let rowTerminal = (rowTerminal ?? ",")
        let tableTerminal = sectionTerminal ?? ".</p></section>"

        do {
            // 1 Remove leading and trailing parts of the html code
            // A Find section header
            if sectionTitle != nil {
                guard let sectionIndex = pageText.range(of: sectionTitle!) else {
                    throw InternalError(location: #function, errorInfo: "did not find \(String(describing: sectionTitle)) in \(String(describing: pageText))", errorType: .htmlSectionTitleNotFound)
                }
                pageText = String(pageText.suffix(from: sectionIndex.upperBound))
            }
            
            // B Find beginning of row
            
            guard let rowStartIndex = pageText.range(of: rowStart) else {
                throw InternalError(location: #function, errorInfo: "did not find \(String(describing: rowStart)) in \(String(describing: pageText))", errorType: .htmlRowStartIndexNotFound)
            }
        
// C Find end of row - or if last row end of table - and reduce pageText to this row
            if let rowEndIndex = pageText.range(of: "</span><br/><span>", range: rowStartIndex.upperBound..<pageText.endIndex) {
                pageText = String(pageText[rowStartIndex.upperBound..<rowEndIndex.lowerBound])
            } else if let tableEndIndex = pageText.range(of: tableTerminal, range: rowStartIndex.upperBound..<pageText.endIndex) {
                pageText = String(pageText[rowStartIndex.upperBound..<tableEndIndex.lowerBound])
            }
            else {
                throw InternalError(location: #function, errorInfo: "did not find \(String(describing: rowTerminal)) in \(String(describing: pageText))", errorType: .htmlRowEndIndexNotFound)
            }
            
            let data = Data(pageText.utf8)
            if let content$ = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil).string {
                return [content$]
            }
//
//            let textArray = try yahooRowStringExtraction(table$: pageText, rowTitle: rowTitle, textTerminal: textTerminal)
//            return textArray
            
        } catch {
            ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "analysis error")
            return [String]()
        }

        return [String]()
    }

    class func getTextBlock(html$: String?, sectionHeader: String?=nil, sectionTerminal: String?=nil, rowTitle: String, rowTerminal: String? = nil, textTerminal: String? = nil, webpageExponent: Double?=nil) -> String {
        
        do {
            guard var pageText = html$ else {
                throw InternalError(location: #function, errorInfo: "empty web page", errorType: .emptyWebpageText)
            }
            
            let sectionTitle: String? = (sectionHeader != nil) ? (">" + sectionHeader!) : nil
            let rowStart = rowTitle
            let rowTerminal = (rowTerminal ?? ",")
            let tableTerminal = sectionTerminal ?? "</p>"
            var extractionTextBlock = String()
            
            // 1 Remove leading and trailing parts of the html code
            // A Find section header
            if sectionTitle != nil {
                guard let sectionIndex = pageText.range(of: sectionTitle!) else {
                    throw InternalError(location: #function, errorInfo: "did not find \(String(describing: sectionTitle)) in \(String(describing: pageText))", errorType: .htmlSectionTitleNotFound)
                }
                pageText = String(pageText.suffix(from: sectionIndex.upperBound))
            }
            
            // B Find beginning of row
            guard let rowStartIndex = pageText.range(of: rowStart)else {
                throw InternalError(location: #function, errorInfo: "did not find \(String(describing: rowStart)) in \(String(describing: pageText))", errorType: .htmlRowStartIndexNotFound)
            }
            
            // C Find end of row - or if last row end of table - and reduce pageText to this row
            if let rowEndIndex = pageText.range(of: rowTerminal,options: [NSString.CompareOptions.literal], range: rowStartIndex.upperBound..<pageText.endIndex, locale: nil) {
                extractionTextBlock = String(pageText[rowStartIndex.upperBound..<rowEndIndex.lowerBound])
            } else if let tableEndIndex = pageText.range(of: tableTerminal,options: [NSString.CompareOptions.literal], range: rowStartIndex.upperBound..<pageText.endIndex, locale: nil) {
                extractionTextBlock = String(pageText[rowStartIndex.upperBound..<tableEndIndex.lowerBound])
            }
            else {
                throw InternalError(location: #function, errorInfo: "did not find \(String(describing: rowTerminal)) in \(String(describing: pageText))", errorType: .htmlRowEndIndexNotFound)
            }
            
            return extractionTextBlock
        } catch {
            ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "error analysing")
            return ""
        }
    }
    
    class func extractOneDouble(html$: String?, rowTitle: String, rowTerminal: String? = nil, numberTerminal: String? = nil) -> Double? {
        
        var pageText = html$
        let rowStart = rowTitle
        let rowTerminal = rowTerminal ?? "\""

        guard pageText != nil else {
            return nil
        }
        
                        
// B Find beginning of row
        let rowStartIndex = pageText?.range(of: rowStart)
        guard rowStartIndex != nil else {
            return nil
        }
                
// C Find end of row - or if last row end of table - and reduce pageText to this row
        if let rowEndIndex = pageText?.range(of: rowTerminal,options: [NSString.CompareOptions.literal], range: rowStartIndex!.upperBound..<pageText!.endIndex, locale: nil) {
            pageText = String(pageText![rowStartIndex!.upperBound..<rowEndIndex.lowerBound])
        }
        else {
            return nil
        }

        let numbersOnly = pageText?.filter("-0123456789.".contains)
        let values = Double(numbersOnly ?? "")
        return values
    }

    class func yahooRowStringExtraction(table$: String, rowTitle: String, textTerminal: String?=nil) throws -> [String] {
        
        var textArray = [String]()
        let textTerminal = textTerminal ?? "\""
        let textStarter = "\""
        var tableText = table$
        
        var labelEndIndex = tableText.range(of: textTerminal, options: .backwards, range: nil, locale: nil)
        if let index = labelEndIndex {
            tableText.removeSubrange(index.lowerBound...)
        }

        repeat {
            guard let labelStartIndex = tableText.range(of: textStarter, options: .backwards, range: tableText.startIndex..<labelEndIndex!.lowerBound, locale: nil) else {
                throw InternalError(location: #function, errorInfo: "did not find \(String(describing: textStarter)) in \(tableText)", errorType: .contentStartSequenceNotFound)
            }
            
            let value$ = String(tableText[labelStartIndex.upperBound...])
            textArray.append(value$)
            
            labelEndIndex = tableText.range(of: textTerminal, options: .backwards, range: tableText.startIndex..<labelEndIndex!.lowerBound, locale: nil)
            if let index = labelEndIndex {
                tableText.removeSubrange(index.lowerBound...)
            }

        } while labelEndIndex != nil && (tableText.count > 1)

        return textArray
    }
    
    class func analyseCSVFile(localURL: URL, expectedHeaderTitles: [String]?, minDate:Date?=nil,dateFormatter: DateFormatter?=nil) async throws -> [DatedValues]? {
        
            let dateFormatter = dateFormatter ?? yahooCSVFileDateFormatter
            
            var iterator = localURL.lines.makeAsyncIterator()

            guard let headerRow = try await iterator.next() else {
                throw InternalError(location: #function, errorInfo: "Yahoo CSV file missing header row")
            }
    
            if let expectedTitles = expectedHeaderTitles {
                guard expectedTitles == headerRow.components(separatedBy: ",") else {
                    throw InternalError(location: #function, errorInfo: "Yahoo CSV file header titles \(expectedTitles) don't match expected titles")
                }
            }
    
            var columnContents = [DatedValues]()
        
            while let nextLine = try await iterator.next() {
                let rowContents = nextLine.components(separatedBy: ",")
                var date: Date?
                var values = [Double]()
                
                for content in rowContents {
                    if let d = dateFormatter.date(from: content) {
                        date = d
                    } else if let value = Double(content) {
                        values.append(value)
                    }
                }
                
                if let valid = date {
                    if let earliestDate = minDate {
                        if valid < earliestDate { break }
                    }
                    columnContents.append((DatedValues(date: valid, values: values)))
                }
                
            }
            
            return columnContents
    }

}
