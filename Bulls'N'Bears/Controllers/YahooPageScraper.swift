//
//  YahooPageScraper.swift
//  Bulls'N'Bears
//
//  Created by aDav on 05/01/2023.
//

import Foundation
import CoreData
import UIKit


struct YahooDownloadJob {
    var pageName = String()
    var tableTitles = [String?]()
    var rowTitles = [[String]]()
    var saveTitles = [[String]]()
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
        

        
        var components = (pageName == "summary") ? URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)") :  URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)/\(pageName)")
        components?.queryItems = [URLQueryItem(name: "p", value: symbol)]
        self.url = components?.url
        
    }
}

var yahooWebDictionary: [YahooDictionaryEntry]?

class YahooPageScraper {
    
    //MARK: - Download descriptors and delimiters
    class func yahooDownloadJobs(symbol: String, shortName: String, option: DownloadOptions) -> [YahooDownloadJob]? {
        
        let dictionary = yahooWebDictionary ?? dictionaryBuilder()
        return dictionary.downloadJobs(for: option, symbol: symbol, shortName: shortName)
        
    }
    

    class func dictionaryBuilder() -> [YahooDictionaryEntry] {
        
        var dictionary = [YahooDictionaryEntry]()
        
        dictionary = dictionary.addElement(pageName: "financials", sectionNames: ["Income statement"], rowNames: [["Total revenue","Basic EPS","Net income", "Interest expense","Income before tax","Income tax expense"]], saveNames: [["Revenue","EPS - Earnings Per Share", "Net Income","Interest expense","Income before tax","Income tax expense"]])
        
        dictionary = dictionary.addElement(pageName: "balance-sheet", sectionNames: ["Balance sheet"], rowNames: [["Current debt","Long-term debt", "Total liabilities"]], saveNames: [["Current debt","Long-term Debt","Total liabilities"]])
        
        dictionary = dictionary.addElement(pageName: "cash-flow", sectionNames: ["Cash flow"], rowNames: [["Free cash flow","Operating cash flow","Capital expenditure"]], saveNames: [["Free cash flow", "Operating cash flow","Capital expenditure"]])
        
        dictionary = dictionary.addElement(pageName: "insider-transactions", sectionNames: ["Insider purchases - Last 6 months"], rowNames: [["Total insider shares held", "Purchases", "Sales"]], saveNames: [["Total insider shares held", "Purchases", "Sales"]])
        
        dictionary = dictionary.addElement(pageName: "analysis", sectionNames: ["Revenue estimate", "Growth estimates"], rowNames: [["Avg. Estimate", "Sales growth (year/est)"], ["Next year", "Next 5 years (per annum)"]], saveNames: [["Avg. Estimate", "Sales growth (year/est)"], ["Next year", "Next 5 years (per annum)"]])
        
        dictionary = dictionary.addElement(pageName: "key-statistics", sectionNames: ["Valuation measures", nil], rowNames: [["Forward P/E","Market cap (intra-day)"],["Beta (5Y monthly)", "Shares outstanding", "Payout ratio","Trailing annual dividend yield"]], saveNames: [["Forward P/E","Market cap (intra-day)"],["Beta (5Y monthly)","Shares outstanding", "Payout ratio","Trailing annual dividend yield"]])
        
        dictionary = dictionary.addElement(pageName: "profile", sectionNames: [nil], rowNames: [["<span>Sector(s)</span>", "<span>Industry</span>", "span>Full-time employees</span>", "<span>Description</span>"]], saveNames: [["Sector", "Industry", "Employees", "Description"]])
        
        dictionary = dictionary.addElement(pageName: "summary", sectionNames: [nil], rowNames: [["Market cap","Beta (5Y monthly)", "PE ratio (TTM)","Earnings date"]], saveNames: [["Market cap","Beta (5Y monthly)", "PE ratio (TTM)","Earnings date"]])
        
        return dictionary
        
    }
    
    class func countOfRowsToDownload(option: DownloadOptions) -> Int {
        
        let dictionary = yahooWebDictionary ?? dictionaryBuilder()
        return dictionary.rowTitles(for: option).count
    }
    
    // MARK: - central download function
    
    /// missing arrays for BVPS, ROI, OPCF/s and PE Hx
    class func dataDownloadAnalyseSave(symbol: String, shortName: String, shareID: NSManagedObjectID, option: DownloadOptions, progressDelegate: ProgressViewDelegate?=nil,downloadRedirectDelegate: DownloadRedirectionDelegate?) async {
        
        guard let downloadJobs = yahooDownloadJobs(symbol: symbol, shortName: shortName, option: option) else {
            return
        }
        
        var checkCurrency: String?
        var checkExchange: String?
        
        var nextEarningsDate: Date?
        var currencyAndExchangrLDT: [Labelled_DatedTexts]?
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
            
            if type == .summary {
                var i = 0
                for title in job.rowTitles.first ?? [] {
                    if let value = singleNumberExtraction(htmlText: htmlText, parameterTitle: title + "</span></td>", numberStart: ">", numberEnd: "</td>") {
                        let dv = DatedValue(date: Date(), value: value)
                        results.append(Labelled_DatedValues(label: job.saveTitles.first![i], datedValues: [dv]))
                    } else {
                        let earningsDates$ = yahooRowStringExtraction(table$: htmlText, rowTitle: title + "</span></td>", textTerminal: "</span></td>").first!
                       let rangeDates = earningsDates$.split(separator: " - ")
                        
                        let dateFormatter: DateFormatter = {
                            let formatter = DateFormatter()
                            formatter.locale = NSLocale.current
                            formatter.timeZone = NSTimeZone.local
                            formatter.dateFormat = "dd MMM yyy"
                            return formatter
                        }()

                        if let firstDate = rangeDates.first {
                            nextEarningsDate = dateFormatter.date(from: String(firstDate))
                        }
                    }
                    i += 1
                }
            }
            else if var extractionResults = YahooPageScraper.extractPageData(html: htmlText, pageType: type, job: job, shareID: shareID) {
                
                // extract Currency and Exchange from any Yahoo page
                if checkCurrency == nil || checkExchange == nil {
                    if let currencyPosition = htmlText.range(of: "Currency in ") {
                        if let currencyEndPosition = htmlText.range(of: "</span>", range: currencyPosition.upperBound..<htmlText.endIndex) {
                            let shareCurrency = String(htmlText[currencyPosition.upperBound..<currencyEndPosition.lowerBound])
                            checkCurrency = shareCurrency
                            currencyAndExchangrLDT = [Labelled_DatedTexts(label: "Currency", datedTexts: [DatedText(date: Date(), text: shareCurrency.replacingOccurrences(of: " ", with: ""))])]
                        }
                        
                        if let exchangeStartPosition = htmlText.range(of: "<span>", options: .backwards ,range: htmlText.startIndex..<currencyPosition.lowerBound) {
                            
                            let exchangeRowText = String(htmlText[exchangeStartPosition.upperBound..<currencyPosition.lowerBound])
                            let exchangeRowTexts = exchangeRowText.split(separator: "-")
                            if let exchange$ = exchangeRowTexts.first {
                                checkExchange = String(exchange$)
                                let exchangeLDV = Labelled_DatedTexts(label: "Exchange", datedTexts: [DatedText(date: Date(), text: String(exchange$).replacingOccurrences(of: " ", with: ""))])
                                if currencyAndExchangrLDT == nil {
                                    currencyAndExchangrLDT = [exchangeLDV]
                                } else {
                                    currencyAndExchangrLDT?.append(exchangeLDV)
                                }
                            }
                        }
                    }
                }
                
                if job.pageName.contains("statistics") {
                    
                    // if Yahoo doesn't have div Yield try YCharts
                    let divYield = extractionResults.filter({ ldv in
                        if ldv.label.contains("dividend yield") { return true }
                        else { return false }
                    }).first
                    
                    if divYield == nil || divYield?.datedValues.count ?? 0 < 1 {
//                        print("no div Yield from Yahoo, trying from YCharts...")
                        await YChartsScraper.dataDownloadAnalyseSave(symbol: symbol, downloadOption: .divYield, shareID: shareID, progressDelegate: progressDelegate)
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
        
        let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc.automaticallyMergesChangesFromParent = true
        
//        do {
        if let bgShare = backgroundMoc.object(with: shareID) as? Share {
            if let valid = nextEarningsDate {
                let research = bgShare.research ?? StockResearch(context: backgroundMoc)
                research.share = bgShare
                if valid > research.nextReportDate ?? Date() {
                    research.nextReportDate = valid
                }
            }
            if let valid = currencyAndExchangrLDT {
                await bgShare.mergeInDownloadedTexts(ldTexts: valid)
            }
            await bgShare.mergeInDownloadedData(labelledDatedValues: results)
        }
//        }
//        catch {
//            ErrorController.addInternalError(errorLocation: #function, systemError: error ,errorInfo: "failed to save downloadde data for \(symbol)")
//        }
        
    }

    
    class func dcfDownloadAnalyseAndSave(shareSymbol: String?, shortName: String?=nil, shareID: NSManagedObjectID, progressDelegate: ProgressViewDelegate?=nil) async throws {
        
        guard let symbol = shareSymbol else {
            progressDelegate?.downloadError(error: "Failed DCF valuation download: missing share symbol")
            throw InternalErrorType.shareSymbolMissing
        }
        
        await dataDownloadAnalyseSave(symbol: symbol, shortName: shortName!, shareID: shareID, option: .dcfOnly, progressDelegate: progressDelegate, downloadRedirectDelegate: nil)
        
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
        
        await dataDownloadAnalyseSave(symbol: symbol, shortName: shortName, shareID: shareID, option: .yahooKeyStatistics, progressDelegate: delegate, downloadRedirectDelegate: nil)
        
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
                    removeFile(csvFileURL)
                    return nil
                }
                else {
                    let minDate = Date().addingTimeInterval(-years*year)
                    if let datedValues = try await analyseValidatedYahooCSVFile(localURL: csvFileURL, minDate: minDate) {
                        
                        var datedDividends = [DatedValue]()
                        for dv in datedValues {
                            datedDividends.append(DatedValue(date: dv.date, value: dv.values[0]))
                        }
                        removeFile(csvFileURL)
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

    class func dailyPricesDownloadCSV(symbol: String?) async -> [PricePoint]? {
        
        guard symbol != nil else {
            return nil
        }
        
        let nowSinceRefDate = yahooPricesStartDate.timeIntervalSince(yahooRefDate) // 10 years back!
        let yearAgoSinceRefDate = yahooPricesEndDate.timeIntervalSince(yahooRefDate)

        let start$ = numberFormatter.string(from: nowSinceRefDate as NSNumber) ?? ""
        let end$ = numberFormatter.string(from: yearAgoSinceRefDate as NSNumber) ?? ""
        
        var urlComponents = URLComponents(string: "https://query1.finance.yahoo.com/v7/finance/download/\(symbol!)")
        urlComponents?.queryItems = [URLQueryItem(name: "period1", value: start$),URLQueryItem(name: "period2", value: end$),URLQueryItem(name: "interval", value: "1d"), URLQueryItem(name: "events", value: "history"), URLQueryItem(name: "includeAdjustedClose", value: "true") ]
        
        
        if let sourceURL = urlComponents?.url {

            // first try to download historical prices from Yahoo finance as CSV file
            let expectedHeaderTitles = ["Date","Open","High","Low","Close","Adj Close","Volume"]

            do {
                if let csvURL = try await Downloader.downloadCSVFile2(url: sourceURL, symbol: symbol!, type: "_PPoints") {
                    if CSVImporter.matchesExpectedFormat(url: csvURL, expectedHeaderTitles: expectedHeaderTitles) {
                        // successful CSV file downloaded
                        let oneYearAgo = Date().addingTimeInterval(-year)
                        if let pricePoints = CSVImporter.extractPricePointsFromFile(url: csvURL, symbol: symbol!, minDate: oneYearAgo) {
                            removeFile(csvURL)
                            return pricePoints
                        }
                    } else {
                        // csv file not correct, download data from webpage instead
                        removeFile(csvURL)
                        ErrorController.addInternalError(errorLocation: #function, errorInfo: "Error when trying to download Yahoo CSV Price - incorrect csv file format for \(symbol!)")
                    }
                } else {
                    // csv file download failed, download data from webpage instead
                    ErrorController.addInternalError(errorLocation: #function, errorInfo: "download failed for Yahoo CSV Price file for \(symbol!) - url \(sourceURL)")
                }
            } catch {
                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "Error when trying to download Yahoo CSV Price csv file for \(symbol!)")
            }
        }
        
        return nil
    }
    
    /// downloads, analyses and merges new with existing price points, then saves; min date is optional for manual limitation; re-calculates MACD's
    class func dailyPricesDownloadAnalyseSave(symbol: String, shareID: NSManagedObjectID, minDate:Date?=nil, existingPricePoints: [PricePoint]?) async {

// 2 data download usually for the last 3 momnths or so
        var urlComponents = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)/history")
        urlComponents?.queryItems = [URLQueryItem(name: "p", value: symbol)]
        
        
        guard let sourceURL = urlComponents?.url else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "daily prices url error \(String(describing: urlComponents))")
            return
        }
        
        guard let html = await Downloader.downloadDataNoThrow(url: sourceURL) else  {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "daily prices download for \(symbol) failed \(String(describing: urlComponents)) as page text is nil")
            return
        }
            
        var minDate = minDate ?? existingPricePoints?.last?.tradingDate
//        if Date().timeIntervalSince(minDate ?? Date()) < 365*24*3600 {
//            minDate = Date().addingTimeInterval(-365*24*3600)
//        }
        
        
        var newPricePoints: [PricePoint]?
        
        // if for whatever reason the price history is less than one year, download from one year ago.
        // This requires CSV download, the data page only goes back 6 months for a 'bot' download
        let targetEarliestDate: TimeInterval = ["AAPL","TSLA", "LOGI"].contains(symbol) ? 3*365*24*3600 : 365*24*3600
        let earliestPriceDate = existingPricePoints?.first?.tradingDate
        if Date().timeIntervalSince(earliestPriceDate ?? Date()) < (targetEarliestDate-5*24*3600) {
            minDate = Date().addingTimeInterval(-targetEarliestDate)
            print("price Hx is less than one year - try to reload from \(minDate!) for \(symbol)")
            newPricePoints = await dailyPricesDownloadCSV(symbol: symbol)
        }
        else {
            newPricePoints = YahooPageScraper.priceTableAnalyse(html$: html, limitDate: minDate, specificDate: nil, symbol: symbol)
        }
            
        guard newPricePoints?.count ?? 0 > 0 else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "daily prices download for \(symbol) failed - no price points retrieved from page")
            return
        }
        
        var merged = existingPricePoints ?? [PricePoint]()
       
        if existingPricePoints != nil {
            
            merged = (existingPricePoints!.mergeIn(pricePoints: newPricePoints))
            //TEMP
//            merged = existingPricePoints!.fillGaps(pricePoints: pricePoints)
        }
        
        let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc.automaticallyMergesChangesFromParent = true
        
        do {
            if let bgShare = backgroundMoc.object(with: shareID) as? Share {
                
                bgShare.setDailyPrices(pricePoints: merged, saveInMOC: false)
                bgShare.reCalculateMACDs(newPricePoints: merged, shortPeriod: 8, longPeriod: 17)
                
                try backgroundMoc.save()
            }
        }
        catch {
            ErrorController.addInternalError(errorLocation: #function, systemError: error ,errorInfo: "failed to save downloaded daily prices for \(symbol)")
        }
    }

    
    /*
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
    */
    /// providing a limit date stops the analysis after encountering that date. Providing a specific date looks for pricepoint data closest to that date only. Don't send both limit AND specific dates; unlike browser page the earliest date is much less than one year ago (six months only)
    class func priceTableAnalyse(html$: String, limitDate: Date?=nil, specificDate:Date?=nil, symbol:String?=nil) -> [PricePoint]? {
        
        let tableEnd$ = "</tbody><tfoot>"
        let tableStart$ = "<thead>"
        
        let rowStart$ = " Ta(start)" // empty space is imporTANT
        let columnEnd = "</span></td>"
        let valueStart = "<span>"
        
        // 1 search for table start and end
        // 2 split table content into rows with rowStart
        // 3 split row$ into columns with columEnd
        // 4 go back from columnEnd finding valueStart
        
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
        
        let rows = pageText.split(separator: rowStart$)
        var rowCount = 0
    rowLoop: for row in rows {
            if rowCount == 0 {
                rowCount += 1
                continue rowLoop
            }
            var pricePoint:PricePoint?
            let columns = row.split(separator: columnEnd)
            var columnCount = 0
//            print()
//            print("PP Download row text \(rowCount) : \(row)")
            var pricevalues = [Double]()
    columnLoop: for column in columns {
//            print("PP column text \(columnCount) : \(column)")
                if let valueStartPosition = column.range(of: valueStart, options: .backwards) {
                    let value$ = String(column[valueStartPosition.upperBound..<column.endIndex])
//                    print("PP column \(columnCount) value$  : \(value$)")
                    if columnCount == 0 {
                        let date$ = value$.replacingOccurrences(of: "Sept", with: "Sep")
                        if let priceDate = dateFormatter.date(from: date$) {
                            pricePoint = PricePoint()
                            pricePoint!.tradingDate = priceDate
                        }
                        else {
                            rowCount += 1
                            continue rowLoop
                        }
                    }
                    else {
                        let value = value$.textToNumber() ?? 0.0
                        pricevalues.append(value)
                    }
                }
                columnCount += 1
            }
        
            
            if var valid = pricePoint {
                if pricevalues.count > 5 {
                    valid.open = pricevalues[0]
                    valid.high = pricevalues[1]
                    valid.low = pricevalues[2]
                    valid.close = pricevalues[3]
                    valid.volume = pricevalues[5]
                    
                    pricePoints.append(valid)
                    
                    if let limit = limitDate {
                      if valid.tradingDate < limit { break rowLoop }
                    }
                }
            }
            rowCount += 1
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
    class func extractPageData(html: String?, pageType: YahooPageType, job: YahooDownloadJob, shareID: NSManagedObjectID) -> [Labelled_DatedValues]? {
        
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
        let saveTitles = job.saveTitles
        
        var tableCount = 0
    outer: for header in job.tableTitles {
            
        let delimiters = YahooPageDelimiters(pageType: pageType, tableHeader: header, rowTitles: job.rowTitles[tableCount], saveTitles: saveTitles[tableCount])
            
            if pageType == .profile {

                Task.init(priority: .background) {
                    await profileData_extractAnalyseSave(pageText: pageText, job: job, shareID: shareID)
                }
                continue outer
            }
            
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
                        ErrorController.addInternalError(errorLocation: #function, errorInfo: "didn't find row start for \(rStart)")
//                        print("table text START ________________________________")
//                        print(tableText)
//                        print("table text END________________________________")
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
                        ErrorController.addInternalError(errorLocation: #function, errorInfo: "didn't find row end for \(rStart)")
                        continue
                    }
                                         
                    let columnTexts = rowText.split(separator: delimiters.columnStart).dropFirst() // gibberish after rowTitle
                    
                    if columnTexts.count < 4 && topRowDates?.count ?? 0 > 3 { // assume no TTM column
                        // no TTM column, so drop any default generated
                        topRowDates = Array(topRowDates!.dropFirst()) // get rid of TTM date
                    }
                    
                    for ct in columnTexts {
                        let dataStartPosition = ct.range(of: delimiters.dataStart) ?? ct.range(of: ">")
                        
                        guard dataStartPosition != nil else {
                            ErrorController.addInternalError(errorLocation: #function, errorInfo: "didn't find data start for \(rStart) in \(ct)")
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
                            ErrorController.addInternalError(errorLocation: #function, errorInfo: "didn't find data end for \(rStart) in \(ct)")
                            continue
                        }
                    }

//                if rStart.contains("PE ratio") {
//                    print()
//                    print(rStart)
//                    print(rowValues)
//                    print()
//                }
                    
                    labelledValues.append(LabelledValues(label: delimiters.saveRowTitles[rowCount], values: rowValues))
                    
                    
                    //Merge with top row dates and modify certain values
                    if rStart.starts(with: "Next year") {
                        // use only the first value
                        let now = Date()
                        let year = DatesManager.yearOnly(date: now)
                        let endOfNextYear = DatesManager.dateFromAString(dateString: "31.12.\(year+1)")!
                        
                        let singleLdv = Labelled_DatedValues(label: delimiters.saveRowTitles[rowCount], datedValues: [DatedValue(date: endOfNextYear, value: rowValues.first ?? 0)])
                        labelledDatedValues.append(singleLdv)
                    }
                    else if rStart.starts(with: "Next 5 years") {
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
                else if rStart.lowercased().starts(with: "avg. estimate") || rStart.lowercased().starts(with: "sales growth"){
                        // use only next years' value, which is the last in the row
                        if let nextYearValue = rowValues.last {
                            let year = DatesManager.yearOnly(date: Date())
                            let endOfNextYear = DatesManager.dateFromAString(dateString: "31.12.\(year+1)")!
                            
                            labelledDatedValues.append(Labelled_DatedValues(label: delimiters.saveRowTitles[rowCount], datedValues: [DatedValue(date: endOfNextYear, value: nextYearValue)]))
                        }
                    }
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
    
    class func profileData_extractAnalyseSave(pageText: String, job: YahooDownloadJob, shareID: NSManagedObjectID) async {
        

//        let delimiters = YahooPageDelimiters(pageType: .profile, tableHeader: nil, rowTitles: job.rowTitles.flatMap{ $0 })
        
        //1 find section with Sector(s). INdustry and Employees
        
        let rowTitles = job.rowTitles.flatMap{ $0 }
        guard let sectionStartPosition = pageText.range(of: rowTitles[0]) else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "didn't find \(job.rowTitles[0]) on profile page")
            return
        }
        
        guard let sectionEndPosition = pageText.range(of: "</span></p>", range: sectionStartPosition.upperBound..<pageText.endIndex) else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "didn't find '</span></p>' for end of section on profile page")
            return
        }
        
        let sectionText = pageText[sectionStartPosition.lowerBound..<sectionEndPosition.upperBound] // leave<span>Sector(s)</span> included
        
//        print(sectionText)
//        let texts = sectionText.split(separator: "<br/>")
//        print(texts)
        var textResults = [Labelled_DatedTexts]()
        var valueResults = [Labelled_DatedValues]() // shoul dbe one only for Full-time employees
        var count = 0
        let saveTitles = job.saveTitles.flatMap{ $0 }
        
        for title in rowTitles.dropLast(1) {
//            print(title)
            guard let titleStart = sectionText.range(of: title) else {
                ErrorController.addInternalError(errorLocation: #function, errorInfo: "didn't find \(title) in \(sectionText)")
                if !title.contains("employees") {
                    let result = DatedText(date: Date(), text: "NA")
                    textResults.append(Labelled_DatedTexts(label: saveTitles[count], datedTexts: [result]))
                } else {
                    let result = DatedValue(date: Date(), value: 0.0)
                    valueResults.append(Labelled_DatedValues(label: saveTitles[count], datedValues: [result]))

                }
                continue
            }
            
            guard let contentEnd = sectionText.range(of: "</span><", range: titleStart.upperBound..<sectionText.endIndex) else {
                ErrorController.addInternalError(errorLocation: #function, errorInfo: "didn't find end of content '</span>' following \(title) in \(sectionText)")
                if !title.contains("employees") {
                    let result = DatedText(date: Date(), text: "NA")
                    textResults.append(Labelled_DatedTexts(label: saveTitles[count], datedTexts: [result]))
                } else {
                    let result = DatedValue(date: Date(), value: 0.0)
                    valueResults.append(Labelled_DatedValues(label: saveTitles[count], datedValues: [result]))

                }
                continue
            }
            
            guard let contentStart = sectionText.range(of: ">", options: .backwards, range: titleStart.upperBound..<contentEnd.lowerBound) else {
                ErrorController.addInternalError(errorLocation: #function, errorInfo: "didn't find start of content '>' following \(title) in \(sectionText)")
                if !title.contains("employees") {
                    let result = DatedText(date: Date(), text: "NA")
                    textResults.append(Labelled_DatedTexts(label: saveTitles[count], datedTexts: [result]))
                } else {
                    let result = DatedValue(date: Date(), value: 0.0)
                    valueResults.append(Labelled_DatedValues(label: saveTitles[count], datedValues: [result]))

                }
                continue
            }
            
            let content$ = String(sectionText[contentStart.upperBound..<contentEnd.lowerBound])
//            print(content$)
            if title.contains("employees") {
                let value = content$.textToNumber() ?? 0.0
                let result = DatedValue(date: Date(), value: value)
                valueResults.append(Labelled_DatedValues(label: "Employees", datedValues: [result]))
            } else {
                let result = DatedText(date: Date(), text: content$)
                textResults.append(Labelled_DatedTexts(label: saveTitles[count], datedTexts: [result]))
            }
            
            count += 1
        }
        
        //2 find section with Description
        if let sPosition = pageText.range(of: "<span>Description</span></h2>") {
            if let ePosition = pageText.range(of: "</p></section>", range: sPosition.upperBound..<pageText.endIndex) {
                
                let rowText = String(pageText[sPosition.upperBound..<ePosition.lowerBound])
                if let textStartPosition = rowText.range(of: ">") {
                    let description = String(rowText[textStartPosition.upperBound..<rowText.endIndex])
                    let result = DatedText(date: Date(), text: description)
                    textResults.append(Labelled_DatedTexts(label: "Description", datedTexts: [result]))
                 }
                else {
                    ErrorController.addInternalError(errorLocation: #function, errorInfo: "didn't find '>' as start of description content in rowText \(rowText)")
                }

            }
            else {
                ErrorController.addInternalError(errorLocation: #function, errorInfo: "didn't find '</p></section>' as end of description content on profile page")
            }
        }
        else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "didn't find '<span>Description</span></h2>' as start of description content on profile page")
        }

        let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc.automaticallyMergesChangesFromParent = true
        
//        do {
            if let bgShare = backgroundMoc.object(with: shareID) as? Share {
                await bgShare.mergeInDownloadedData(labelledDatedValues: valueResults)
                await bgShare.mergeInDownloadedTexts(ldTexts: textResults)
            }
//        } catch {
//            ErrorController.addInternalError(errorLocation: #function, systemError: error ,errorInfo: "failed to save profile downloads data for \(job.url!)")
//        }
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
        } else if pageName.contains("profile") {
            type = .profile
        } else  {
            type = .summary
        }

        return type
    }
    
    class func singleNumberExtraction(htmlText: String?, parameterTitle: String, numberStart: String, numberEnd: String) -> Double? {
        
        guard let pagetext = htmlText else { return nil }
        
        guard let titlePosition = pagetext.range(of: parameterTitle) else { return nil }
                
        guard let numberEndPosition = pagetext.range(of: numberEnd, range: titlePosition.upperBound..<pagetext.endIndex) else { return nil }
        
        guard let numberStartPosition = pagetext.range(of: numberStart, options: .backwards , range: titlePosition.upperBound..<numberEndPosition.lowerBound) else { return nil }
        
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

//        do {
            // 1 Remove leading and trailing parts of the html code
            // A Find section header
            if sectionTitle != nil {
                guard let sectionIndex = pageText.range(of: sectionTitle!) else {
                    ErrorController.addInternalError(errorLocation: #function, errorInfo: "did not find \(String(describing: sectionTitle)) in \(String(describing: pageText))")
                    return [String]()
                }
                pageText = String(pageText.suffix(from: sectionIndex.upperBound))
            }
            
            // B Find beginning of row
            
            guard let rowStartIndex = pageText.range(of: rowStart) else {
                ErrorController.addInternalError(errorLocation: #function, errorInfo: "did not find \(String(describing: rowStart)) in \(String(describing: pageText))")
                return [String]()
            }
        
// C Find end of row - or if last row end of table - and reduce pageText to this row
            if let rowEndIndex = pageText.range(of: "</span><br/><span>", range: rowStartIndex.upperBound..<pageText.endIndex) {
                pageText = String(pageText[rowStartIndex.upperBound..<rowEndIndex.lowerBound])
            } else if let tableEndIndex = pageText.range(of: tableTerminal, range: rowStartIndex.upperBound..<pageText.endIndex) {
                pageText = String(pageText[rowStartIndex.upperBound..<tableEndIndex.lowerBound])
            }
            else {
                ErrorController.addInternalError(errorLocation: #function, errorInfo: "did not find \(String(describing: rowTerminal)) in \(String(describing: pageText))")
                return [String]()
            }
            
            let data = Data(pageText.utf8)
            if let content$ = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil).string {
                return [content$]
            }
            
//        } catch {
//            ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "analysis error")
//            return [String]()
//        }

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

    class func yahooRowStringExtraction(table$: String, rowTitle: String, textTerminal: String?=nil) -> [String] {
        
        var textArray = [String]()
        let textTerminal = textTerminal ?? "\""
        let textStarter = "<span>"
        var tableText = table$
        
        var labelEndIndex = tableText.range(of: textTerminal, options: .backwards, range: nil, locale: nil)
        if let index = labelEndIndex {
            tableText.removeSubrange(index.lowerBound...)
        }

        repeat {
            guard let labelStartIndex = tableText.range(of: textStarter, options: .backwards, range: tableText.startIndex..<labelEndIndex!.lowerBound, locale: nil) else {
                ErrorController.addInternalError(errorLocation: #function, errorInfo: "did not find \(String(describing: textStarter))")
                return [String]()
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
    
    class func removeFile(_ atURL: URL?) {
        
        guard atURL != nil else {
            return
        }
        
        do {
            try FileManager.default.removeItem(at: atURL!)
        } catch let error {
            DispatchQueue.main.async {
                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "YahooPageScraper - error trying to remove existing file \(atURL!) in the Document folder to be able to move new file of same name from Inbox folder ")
            }
        }
    }


}


struct YahooDictionaryEntry {
    
    var pageName:String
    var sectionName: String?
    var rowName: String
    var parameterTitle: String
    
    init(pageName: String, sectionName: String?, rowName: String, parameterTitle: String?) {
        self.pageName = pageName
        self.sectionName = sectionName
        self.rowName = rowName
        self.parameterTitle = parameterTitle ?? rowName
    }
    
}

enum YahooPageType {
    case financials
    case balance_sheet
    case cash_flow
    case insider_transactions
    case analysis
    case key_statistics
    case summary
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
        case .summary:
            rowEnd = "</td></tr>"
            dataStart = ">"
            dataEnd = ""
        case .profile:
            // Description text block doesn't have dataEnd , ends with rowEnd
            rowEnd = "</p>"
            dataStart = ">"
            dataEnd = "</span></span>"
        }
    }
}

