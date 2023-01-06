//
//  WebPageScraper2.swift
//  Bulls'N'Bears
//
//  Created by aDav on 04/11/2021.
//

import UIKit
import CoreData

@objc protocol DownloadRedirectionDelegate: URLSessionTaskDelegate {
    
    func awaitingRedirection(notification: Notification)
}

struct WebPageInfoDelimiters {
    
    var htmlText: String!
    var pageTitle: String?
    var sectionTitle: String?
    var rowTitle: String?
    var pageStartSequence: String?
    var tableTitle: String?
    var tableStartSequence: String?
    var tableEndSequence: String?
    var rowStartSequence: String?
    var rowEndSequence: String?
    var numberStartSequence: String?
    var numberEndSequence: String?
    var numberExponent: Double?=nil
    var textStartSequence: String?
    var textEndSequence: String?
    var pageType: Website!
    
    let numberEndSequence_Yahoo_default1 = "</span>"
    let numberStartSequence_Yahoo_default = ">"
    let numberEndSequence_Yahoo_default2 = "</span></div>"
    let tableStartSequence_yahoo_default = "<thead "
    let tableEndSequence_default = "</div></div></div></div>"
    let tableEndSequence_yahoo_default1 = "</p>"
    let tableEndSequence_yahoo_default2 = "</tbody><tfoot "
    let rowEndSequence_default = "</div></div></div>"
    let rowEndSequence_default2 =  "</span></div></div>"
    let rowEndSequence_yahoo_default1 = "</span></td>"
    let rowEndSequence_yahoo_default2 = "</span></td></tr>"
    let rowStartSequence_MT_default = "class=\"fas fa-chart-bar\"></i></div></div></div><div role="
    let rowStartSequence_yahoo_default = "Ta(start)"

    let rowEndSequence_Yahoo_default = "\""
    let textStartSequence_yahoo_default = "\""
    let textEndSequence_yahoo_default = "\""
    
    init(html$: String, pageType: Website,pageTitle:String?=nil, pageStarter:String?=nil, sectionTitle: String?=nil, tableTitle:String?=nil, tableStarter:String?=nil, tableEnd:String?=nil, rowTitle:String?=nil, rowStart:String?=nil, rowEnd:String?=nil, numberStart:String?=nil, numberEnd:String?=nil, exponent: Double?=nil, textStart: String?=nil, textEnd:String?=nil) {
        
        self.htmlText = html$
        self.pageType = pageType
        self.pageTitle = pageTitle
        self.pageStartSequence = pageStarter
        self.sectionTitle = (sectionTitle != nil) ? (">" + sectionTitle!) : nil
        self.tableTitle = tableTitle
        self.tableStartSequence = tableStarter
        self.tableEndSequence = tableEnd ?? tableEndSequence_default
        self.rowTitle = rowTitle
        if rowStart != nil {
            self.rowStartSequence = (pageType == .macrotrends) ? (">" + rowStart! + "<") : rowStart!
        } else {
            self.rowStartSequence = (pageType == .macrotrends) ? rowStartSequence_MT_default : nil
        }
        self.rowEndSequence = rowEnd ?? rowEndSequence_default
        self.numberStartSequence = numberStart
        self.numberEndSequence = numberEnd
        self.numberExponent = exponent
        self.textStartSequence = textStart
        self.textEndSequence = textEnd
        
    }
    
}

class WebPageScraper2: NSObject {
    
    var progressDelegate: ProgressViewDelegate?
    
    /// use this to create an instance if you don't wish to use the class functions
    init(progressDelegate: ProgressViewDelegate?) {
        self.progressDelegate = progressDelegate
    }
    //MARK: - specific task functions
    
    /// returns historical pe ratios and eps TTM with dates from macro trends website
    /// in form of [DatedValues] = (date, epsTTM, peRatio )
    /// ; optional parameter 'date' returns values back to this date and the first set before.
    /// ; throws downlad and analysis errors, which need to be caught by cailler
    class func getHxEPSandPEData(url: URL, companyName: String, until date: Date?=nil, downloadRedirectDelegate: DownloadRedirectionDelegate) async throws -> [Dated_EPS_PER_Values]? {
        
            var htmlText:String?
            var tableText = String()
            var tableHeaderTexts = [String]()
            var datedValues = [Dated_EPS_PER_Values]()
            let downloader = Downloader(task: .epsPER)
        
            do {
                // to catch any redirections
                NotificationCenter.default.addObserver(downloadRedirectDelegate, selector: #selector(DownloadRedirectionDelegate.awaitingRedirection(notification:)), name: Notification.Name(rawValue: "Redirection"), object: nil)
                
                htmlText = try await downloader.downloadDataWithRedirection(url: url)
            } catch let error as InternalErrorType {
                throw error
            }
        
            guard let validPageText = htmlText else {
                throw InternalErrorType.generalDownloadError // possible result of MT redirection
            }
                
            do {
                tableText = try await extractTable(title:"PE Ratio Historical Data", html: validPageText) // \(title)
            } catch let error as InternalErrorType {
                throw error
            }

            do {
                tableHeaderTexts = try await extractHeaderTitles(html: tableText)
            } catch let error as InternalErrorType {
                throw error
            }
            
            if tableHeaderTexts.count > 0 && tableHeaderTexts.contains("Date") {
                do {
                    datedValues = try extractTableData(html: validPageText, titles: tableHeaderTexts, untilDate: date)
                    return datedValues
                } catch let error as InternalErrorType {
                   throw error
                }
            } else {
                throw InternalErrorType.htmTablelHeaderStartNotFound
            }

    }
    
    /// returns quarterly eps  with dates from macro trends website
    /// in form of [DatedValues] = (date, eps )
    /// ; optional parameter 'date' returns values back to this date and the first set before.
    /// ; throws downlad and analysis errors, which need to be caught by cailler
    class func getqEPSDataFromMacrotrends(url: URL, companyName: String, until date: Date?=nil, downloadRedirectDelegate: DownloadRedirectionDelegate) async throws -> [DatedValue]? {
        
            var htmlText:String?
            var datedValues = [DatedValue]()
            let downloader = Downloader(task: .qEPS)
        
            do {
                // to catch any redirections
                NotificationCenter.default.addObserver(downloadRedirectDelegate, selector: #selector(DownloadRedirectionDelegate.awaitingRedirection(notification:)), name: Notification.Name(rawValue: "Redirection"), object: nil)
                
                htmlText = try await downloader.downloadDataWithRedirection(url: url)
            } catch let error as InternalErrorType {
                throw error
            }
        
            guard let validPageText = htmlText else {
                throw InternalErrorType.generalDownloadError // possible result of MT redirection
            }
                
            do {
                let formatter = DateFormatter()
                formatter.dateFormat = "y-M-d"
                let extractionCodes = WebpageExtractionCodes(tableTitle: "Quarterly EPS", option: .macroTrends, rowStartSequence: "\">", dateFormatter: formatter)
                datedValues = try extractQEPSTableData(html: validPageText, extractionCodes: extractionCodes,untilDate: date)
                return datedValues
            } catch let error as InternalErrorType {
               throw error
            }

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

    
    /// returns historical pe ratios and eps TTM with dates from macro trends website
    /// in form of [DatedValues] = (date, epsTTM, peRatio )
    /// ; optional parameter 'date' returns values back to this date and the first set before.
    /// ; throws downlad and analysis errors, which need to be caught by cailler
    /*
    class func getHxEPSandPEDataNasdaq(url: URL, companyName: String, until date: Date?=nil, downloadRedirectDelegate: DownloadRedirectionDelegate) async throws -> [Dated_EPS_PER_Values]? {
        
            var htmlText:String?
            var tableText = String()
            var tableHeaderTexts = [String]()
            var datedValues = [Dated_EPS_PER_Values]()
//            let title = companyName.capitalized(with: .current)
            let downloader = Downloader(task: .epsPER)
        
            do {
                // to catch any redirections
                NotificationCenter.default.addObserver(downloadRedirectDelegate, selector: #selector(DownloadRedirectionDelegate.awaitingRedirection(notification:)), name: Notification.Name(rawValue: "Redirection"), object: nil)
                
                htmlText = try await downloader.downloadDataWithRedirection(url: url)
            } catch let error as InternalErrorType {
                throw error
            }
        
            guard let validPageText = htmlText else {
                throw InternalErrorType.generalDownloadError // possible result of MT redirection
//                return nil
            }
                
            do {
                tableText = try await extractTable(title:"Quarterly Earnings Surprise Amount", html: validPageText) // \(title)
            } catch let error as InternalErrorType {
                throw error
            }

            do {
                tableHeaderTexts = try await extractHeaderTitles(html: tableText)
            } catch let error as InternalErrorType {
                throw error
            }
            
            if tableHeaderTexts.count > 0 && tableHeaderTexts.contains("Date") {
                do {
                    datedValues = try extractTableData(html: validPageText, titles: tableHeaderTexts, untilDate: date)
                    return datedValues
                } catch let error as InternalErrorType {
                   throw error
                }
            } else {
                throw InternalErrorType.htmTablelHeaderStartNotFound
            }

    }
    */
    
    class func getCurrentPrice(url: URL) async throws -> Double? {
        
        var htmlText = String()

        do {
            htmlText = try await Downloader.downloadData(url: url)
            if let values = scrapeRowForDoubles(website: .yahoo, html$: htmlText, rowTitle: "currentPrice" , rowTerminal: "}",  numberStarter: ":", numberTerminal: "\"") {

                return values.first
            } else {
                return nil
            }
        } catch let error as InternalErrorType {
            ErrorController.addInternalError(errorLocation: "WebScraper2.getCurretnPrice", systemError: error, errorInfo: "error downloading current price data from \(url)")
            throw error
        }

    }
    
    /*
    /// using yahoo as info source
    class func downloadAndAnalyseProfile(url: URL) async throws -> ProfileData? {
        
        var htmlText = String()

        do {
            htmlText = try await Downloader.downloadData(url: url)
        } catch let error as InternalErrorType {
            throw InternalError.init(location: "WebScraper2.downloadAndAnalyseProfile", systemError: error, errorInfo: "error downloading and analysing profile data from \(url)")
        }

        
        let rowTitles = ["\"sector\":", "\"industry\":", "\"fullTimeEmployees\"", "longBusinessSummary\":\""] // titles differ from the ones displayed on webpage!
        
        var sector = String()
        var industry = String()
        var employees = Double()
        var description = String()

        for title in rowTitles {
                        
            if title.starts(with: "\"sector") {
                let strings = try scrapeRowForText(html$: htmlText, rowTitle: title , rowTerminal: ",", textTerminal: "\"")

                if let valid = strings.first {
                        sector = valid
                }
            } else if title.starts(with: "\"industry") {
                let strings = try scrapeRowForText(html$: htmlText, rowTitle: title , rowTerminal: ",", textTerminal: "\"")

                
                if let valid = strings.first {
                        industry = valid
                }
            } else if title.contains("Employees") {
                if let value = extractOneDouble(html$: htmlText, rowTitle: title , rowTerminal: "\"", numberTerminal: ",") {
                
                    employees = value
                }
            } else if title.contains("Summary") {
                description = try getTextBlock(html$: htmlText, rowTitle: title , rowTerminal: "\"", textTerminal: "\",")
            }
        }
        
        return ProfileData(sector: sector, industry: industry, employees: employees, description: description)
    }
    */
//    class func downloadAndAnalyseHxDividendsPage(symbol: String, years: TimeInterval, delegate: CSVFileDownloadDelegate) async throws {
//
//        let nowSinceRefDate = Date().timeIntervalSince(yahooRefDate)
//        let tenYearsAgoSinceRefDate = Date().addingTimeInterval(-years*year).timeIntervalSince(yahooRefDate)
//
//        let start$ = numberFormatter.string(from: nowSinceRefDate as NSNumber) ?? ""
//        let end$ = numberFormatter.string(from: tenYearsAgoSinceRefDate as NSNumber) ?? ""
//
//        var urlComponents = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)/history")
//
//        urlComponents?.queryItems = [
//            URLQueryItem(name: "period1", value: end$),
//            URLQueryItem(name: "period2", value: start$),
//            URLQueryItem(name: "interval", value: "capitalGain|div|split"),
//            URLQueryItem(name: "filter", value: "div"),
//            URLQueryItem(name: "frequency", value: "1d"),
//            URLQueryItem(name: "includeAdjustedClose", value: "true") ]
//
//
//        var dividendWDates: [DatedValue]?
//
//        guard let url = urlComponents?.url else {
//            throw InternalError(location: #function, errorInfo: "invalid url for downloading yahoo Hx dividend data")
//        }
//
//        do {
//            let html = try await Downloader.downloadData(url: url)
//
//            if let tableContent = try getCompleteYahooWebTableContent(html: html, tableTitle: nil) {
//
//                let dateFormatter: DateFormatter = {
//                    let formatter = DateFormatter()
//                    formatter.dateFormat = "dd MMM yyyy"
//                    formatter.calendar.timeZone = TimeZone(identifier: "UTC")!
//                    return formatter
//                }()
//
//                var divDates = [DatedValue]()
//                for row in tableContent {
//                    if let dV = extractDatedValueFromStrings(rowElements: row, formatter: dateFormatter) {
//                        divDates.append(dV)
//                    }
//                }
//                dividendWDates = divDates
//            }
//
//        } catch {
//            throw InternalError(location: #function, systemError: error)
//        }
//
//        delegate.dataDownloadCompleted(results: dividendWDates)
//
//    }
    
    /// using yahoo as source
//    class func downloadHxDividendsFile(symbol: String, companyName: String, years: TimeInterval) async throws -> [DatedValue]? {
//        
//        let nowSinceRefDate = Date().timeIntervalSince(yahooRefDate)
//        let tenYearsAgoSinceRefDate = Date().addingTimeInterval(-years*year).timeIntervalSince(yahooRefDate)
//
//        let start$ = numberFormatter.string(from: nowSinceRefDate as NSNumber) ?? ""
//        let end$ = numberFormatter.string(from: tenYearsAgoSinceRefDate as NSNumber) ?? ""
//        var urlComponents = URLComponents(string: "https://query1.finance.yahoo.com/v7/finance/download/\(symbol)")
//
//        urlComponents?.queryItems = [
//            URLQueryItem(name: "period1", value: end$),
//            URLQueryItem(name: "period2", value: start$),
//            URLQueryItem(name: "interval", value: "1d"),
//            URLQueryItem(name: "events", value: "div"),
//            URLQueryItem(name: "includeAdjustedClose", value: "true") ]
//
//        guard let url = urlComponents?.url else {
//            throw InternalError(location: #function, errorInfo: "invalid url for downloading yahoo Hx dividend .csv file")
//        }
//        
//        let expectedHeaderColumnTitles = ["Date", "Dividends"]
//
//        guard let csvFileURL = try await Downloader.downloadCSVFile2(url: url, symbol: symbol, type: "_Div") else {
//            throw InternalError(location: #function, errorInfo: "Failed Dividend CSV File download from Yahoo for \(symbol)")
//        }
//
//        var iterator = csvFileURL.lines.makeAsyncIterator()
//        
//        if let headerRow = try await iterator.next() {
//            let titles: [String] = headerRow.components(separatedBy: ",")
//            if !(titles == expectedHeaderColumnTitles) {
//                throw InternalError(location: #function, errorInfo: "Dividend CSV File downloadwd from Yahoo for \(symbol) does not have expected header row titles \(headerRow)")
//            }
//            else {
//                let minDate = Date().addingTimeInterval(-years*year)
//                if let datedValues = try await analyseValidatedYahooCSVFile(localURL: csvFileURL, minDate: minDate) {
//                    
//                    var datedDividends = [DatedValue]()
//                    for dv in datedValues {
//                        datedDividends.append(DatedValue(date: dv.date, value: dv.values[0]))
//                    }
//                    return datedDividends
//                }
//            }
//        }
//
//        return nil
//    }

    /// it shuold have been established that the header row contains the expected title BEFORE sending this file
    class func analyseYahooCSVFile(localURL: URL, expectedHeaderTitles: [String]?, minDate:Date?=nil,dateFormatter: DateFormatter?=nil) async throws -> [DatedValues]? {
        
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


    /// takes [String] looking for a date string as per formatter, and a Double value; order doesn't matter.
    class func extractDatedValueFromStrings(rowElements: [String], formatter: DateFormatter) -> DatedValue? {
        
        guard rowElements.count == 2 else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "error trying to extract datedValue from [String]. No of elements sent is \(rowElements.count), not 2 as necessary")
            return nil
        }
                
        var date: Date?
        var value: Double?
        
        for element in rowElements {
            
            let cleaned = String(element.replacingOccurrences(of: "Sept", with: "Sep"))
            if let valid = formatter.date(from: cleaned) {
                date = valid
            } else if let valid = Double(cleaned) {
                value = valid
            }
        }
        
        if date != nil && value != nil {
            return DatedValue(date: date!, value: value!)
        } else {
            return nil
        }
        
    }
    
    //MARK: - Rule 1 Data
    
    class func r1DataDownloadAndSave(shareSymbol: String?, shortName: String?, valuationID: NSManagedObjectID, progressDelegate: ProgressViewDelegate?=nil, downloadRedirectDelegate: DownloadRedirectionDelegate) async throws {
        
        guard let symbol = shareSymbol else {
            progressDelegate?.downloadError(error: InternalErrorType.shareSymbolMissing.localizedDescription)
            throw InternalErrorType.shareSymbolMissing
        }
        
        guard let shortName = shortName else {
            progressDelegate?.downloadError(error: InternalErrorType.shareShortNameMissing.localizedDescription)
            throw InternalErrorType.shareShortNameMissing
        }
        
        
        var results = [LabelledValues]()
        
        if symbol.contains(".") {
            // non-US Stocks
            do {
                
                try await nonMTRule1DataDownload(symbol: symbol, shortName: shortName, valuationID: valuationID)

            } catch {
                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "error trying to download Rule1 data from Yahoo")
            }
        }
        else {
            // US-Stocks
            let pageNamesMT = ["financial-statements", "financial-ratios", "balance-sheet"]
            let perOnMT = ["pe-ratio"]
            let pageNamesYahoo = ["analysis", "cash-flow","insider-transactions"]
            let mtRowTitles = [["Revenue","EPS - Earnings Per Share","Net Income"],["ROI - Return On Investment","Book Value Per Share","Operating Cash Flow Per Share"],["Long Term Debt"]]
            
            
            progressDelegate?.allTasks = mtRowTitles.compactMap{ $0 }.count + pageNamesYahoo.count + perOnMT.count
            
            
            // 1 Download and analyse web page data first MT then Yahoo
            // MacroTrends downloads for Rule1 Data
            
            do {
                if let mtR1Data = try await r1DataFromMT(symbol: symbol, shortName: shortName, pageNames: pageNamesMT, rowTitles: mtRowTitles, progressDelegate: progressDelegate ,downloadRedirectDelegate: downloadRedirectDelegate) {
                    results.append(contentsOf: mtR1Data)
                }
            } catch {
                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "error trying to download Rule1 data from MacroTrends")
            }
            
            // 2 Yahoo downloads for Rule1 Data
            
            do {
                if let yahooR1Data = try await r1DataFromYahoo(symbol: symbol, progressDelegate: progressDelegate, avoidMTTitles: true,  downloadRedirectDelegate: downloadRedirectDelegate) {
                    results.append(contentsOf: yahooR1Data)
                    
                }
            } catch {
                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "error trying to download Rule1 data from Yahoo")
            }
            
            // TODO: - harmonise data preferring MT arrays over Yahoo arrays
        }

// 3 Save R1 data to background R1Valuation
        let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc.automaticallyMergesChangesFromParent = true
        
        do {
            try await saveR1Data(valuationID: valuationID, labelledValues: results)
        } catch {
            progressDelegate?.downloadError(error: error.localizedDescription)
            throw error
        }
    }
    
   /// fetches [["Revenue","EPS - Earnings Per Share","Net Income"],["ROI - Return On Investment","Book Value Per Share","Operating Cash Flow Per Share"],["Long Term Debt"]]. Does NOT fetch: OCF (single), Debt (single),  growthEstimates, hx PE,  insider stocks, -buys and - sells; these come from Yahoo
    class func r1DataFromMT(symbol: String, shortName: String, pageNames: [String], rowTitles: [[String]], progressDelegate: ProgressViewDelegate?=nil, downloadRedirectDelegate: DownloadRedirectionDelegate) async  throws -> [LabelledValues]? {
        
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

        var results = [LabelledValues]()
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
                NotificationCenter.default.addObserver(downloadRedirectDelegate, selector: #selector(DownloadRedirectionDelegate.awaitingRedirection(notification:)), name: Notification.Name(rawValue: "Redirection"), object: nil)
                
                htmlText = try await downloader.downloadDataWithRedirection(url: url)
                
            } catch let error as InternalErrorType {
                progressDelegate?.downloadError(error: error.localizedDescription)
                continue
            }
            
            guard let pageText = htmlText else {
                progressDelegate?.downloadError(error: InternalErrorType.emptyWebpageText.localizedDescription)
                continue
            }
            
            let labelledDatedValues = try await extractDatedValuesFromMTTable(htmlText: pageText, rowTitles: rowTitles[sectionCount])
            
            // remove dates
            var dateSet = Set<Date>()
            var labelledValues = [LabelledValues]()
            for value in labelledDatedValues {
                var newLV = LabelledValues(label: value.label, values: [Double]())
                let values = value.datedValues.compactMap{ $0.value }
                let dates = value.datedValues.compactMap{ $0.date }
                newLV.values = values
                labelledValues.append(newLV)
                dateSet.formUnion(dates)
            }
            results.append(contentsOf: labelledValues)
                        
            progressDelegate?.taskCompleted()
            
            sectionCount += 1
        }
        
// MT download for PE Ratio in different format than 'Financials'
        for pageName in ["pe-ratio"] {
            var components: URLComponents?
            components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(symbol)/\(hyphenatedShortName)/" + pageName)
            
            guard let url = components?.url else {
                progressDelegate?.downloadError(error: InternalErrorType.urlInvalid.localizedDescription)
                continue
            }
            
            // the following values are NOT ANNUAL but quarterly, sort of!
            let values = try await getHxEPSandPEData(url: url, companyName: hyphenatedShortName.capitalized, until: nil, downloadRedirectDelegate: downloadRedirectDelegate)
            var newLabelledValues = LabelledValues(label: "PE Ratio Historical Data", values: [Double]())

            if let per = values?.compactMap({ $0.peRatio }) {
                newLabelledValues.values = per
            }
            
            results.append(newLabelledValues)
            progressDelegate?.taskCompleted()
        }

        return results
    }

    
    /// missing arrays for BVPS, ROI, OPCF/s and PE Hx
    class func r1DataFromYahoo(symbol: String, progressDelegate: ProgressViewDelegate?=nil, avoidMTTitles: Bool?=nil ,downloadRedirectDelegate: DownloadRedirectionDelegate?) async throws -> [LabelledValues]? {
        
        var results = [LabelledValues]()
        
        let pageNames = (avoidMTTitles ?? false) ? ["balance-sheet","insider-transactions", "analysis", "key-statistics"] : ["financials","balance-sheet","cash-flow", "insider-transactions", "analysis", "key-statistics"]

        let tableTitles = (avoidMTTitles ?? false) ? ["Balance sheet", "Insider purchases - Last 6 months", "Revenue estimate", "Valuation measures"] : ["Income statement", "Balance sheet", "Cash flow", "Insider purchases - Last 6 months", "Revenue estimate", "Valuation measures"]

        let rowTitles = (avoidMTTitles ?? false) ? [["Common stock"],["Total insider shares held", "Purchases", "Sales"], ["Sales growth (year/est)"],["Forward P/E"]] : [["Total revenue","Basic EPS","Net income"], ["Total non-current liabilities", "Common stock"],["Net cash provided by operating activities"],["Total insider shares held", "Purchases", "Sales"], ["Sales growth (year/est)"],["Forward P/E"]]
        
        let saveTitles = (avoidMTTitles ?? false) ? [["Common stock"],["Total insider shares held", "Purchases", "Sales"],["Sales growth (year/est)"],["Forward P/E"]] : [["Revenue","EPS - Earnings Per Share", "Net Income"], ["Long Term Debt", "Common stock"],["Operating cash flow"],["Total insider shares held", "Purchases", "Sales"],["Sales growth (year/est)"],["Forward P/E"]]
        

        var count = 0
        for pageName in pageNames {
            
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
            }
            
            var components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)/\(pageName)")
            components?.queryItems = [URLQueryItem(name: "p", value: symbol)]
            
            guard let url = components?.url else {
                progressDelegate?.downloadError(error: InternalErrorType.urlInvalid.localizedDescription)
                continue
            }

            var htmlText = String()

            do {
                htmlText = try await Downloader.downloadData(url: url)
            } catch let error as InternalErrorType {
                progressDelegate?.downloadError(error: error.localizedDescription)
                continue
            }


            if var labelledResults = YahooPageScraper.extractYahooPageData(html: htmlText, pageType: type, tableHeader: tableTitles[count], rowTitles: rowTitles[count],replacementRowTitles: saveTitles[count] ){
                
                for i in 0..<labelledResults.count {
                    // eliminate duplicate TTM figure if same as previous full year figure
                    if labelledResults[i].values.count > 1 {
                        if labelledResults[i].values[0] == labelledResults[i].values[1] {
                            labelledResults[i].values = Array(labelledResults[i].values.dropFirst())
                            //                        labelledResults[i].values = newValues
                        }
                    }
                    
                    if labelledResults[i].label == "Sales" || labelledResults[i].label.contains("Purchases") {
                        labelledResults[i].values = [labelledResults[i].values.first ?? 0.0]
                    } else if labelledResults[i].label.contains("Sales growth") {
                        labelledResults[i].values = [labelledResults[i].values.compactMap{ $0 / 100 }.last ?? 0.0] // growth percent values
                    }
                }

//                print("Yahoo results for \(rowTitles[count])")
//                print("alt titles are \(saveTitles[count])")
//                for result in results {
//                    print(result)
//                }
//                print()

                results.append(contentsOf: labelledResults)
            }
            // DEBUG ONLY
            else {
                print("Download Yahoo results for \(rowTitles[count]) NO RESULTS")
            }
            //DEBUG ONLY
            
            progressDelegate?.taskCompleted()
            count += 1
            
        }
        
        return results
        
    }
    
    class func r1DataFromTagesschau(htmlText: String, symbol: String?, valuationID: NSManagedObjectID, progressController: ProgressViewDelegate?=nil) throws -> [LabelledValues] {
        
//        let sectionHeaders = ["Kennzahlen","Gewinn und Verlustrechnung", ">Cash flow</h2",">Bilanz</h2>", "Wertpapierdaten"]
//        // vermeide äöü in html search string
//        let rowTitles = [["Eigenkapitalrendite"],["Umsatz","Operatives Ergebnis","Buchwert je Aktie","Wertminderung","Ergebnis vor Steuer:" ,"hnliche Aufwendungen","Personalaufwand","Materialaufwand","Sonstige betriebliche Aufwendungen"],["nderung der Finanzmittel"],["Eigene Aktien","Summe Anlageverm","Langfristige Finanzverbindlichkeiten"],["Ausstehende Aktien","Gewinn je Aktie", "Aktuell ausstehende Aktien"]]
        let sectionHeaders = ["Kennzahlen","Gewinn und Verlustrechnung", ">Bilanz</h2>", "Wertpapierdaten"]
        // vermeide äöü in html search string
        let rowTitles = [["Eigenkapitalrendite"],["Umsatz","Operatives Ergebnis","Buchwert je Aktie","Wertminderung","Ergebnis vor Steuer:" ,"hnliche Aufwendungen","Personalaufwand","Materialaufwand","Sonstige betriebliche Aufwendungen"],["Eigene Aktien","Summe Anlageverm","Langfristige Finanzverbindlichkeiten"],["Ausstehende Aktien","Gewinn je Aktie", "Aktuell ausstehende Aktien"]]

        var allLabelledValues = [LabelledValues]()
        var sumAnlVerm: [Double]?
        var wertMind: [Double]?
        var sga: [Double]?
        var sharesOutStanding: [Double]?

        do {
            // isin and currency data have to be sent via notification as there is no access to the share object in this function
            var sendDictionary = [String: String]()

            if let isin = try extractStringFromTagesschau(html: htmlText, searchTerm: "ISIN:") {
                sendDictionary["isin"] = isin
            }
            if let currency = try extractStringFromTagesschau(html: htmlText, searchTerm: "hrung:") {//Währung
                sendDictionary["currency"] = currency
            }
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: "ISIN and CURRENCY INFO"), object: symbol, userInfo: sendDictionary)
            
            var count = 0
            for header in sectionHeaders {
                for rowTitle in rowTitles[count] {
                    
                    let results = extractDataFromTagesschau(html: htmlText, sectionHeader: header, rowTitle: rowTitle)
                    var newestDate = DatesManager.endOfYear(of: Date().addingTimeInterval(-year))
                    var labelledValues: LabelledValues?
                    
                    if let lV = results as? LabelledValues {
                        labelledValues = lV
                    } else if let labelledDatedValues = results as? Labelled_DatedValues {
                        labelledValues = LabelledValues(label: labelledDatedValues.label, values: labelledDatedValues.datedValues.compactMap{ $0.value })
                        let dates = labelledDatedValues.datedValues.compactMap{ $0.date }.sorted()
                        newestDate = dates.last!
                    } else {
                        ErrorController.addInternalError(errorLocation: #function, errorInfo: "no values downloaded for \(rowTitle) from Tagesschau website")
                        continue
                    }
                                        
                    let relabelledValues = translateGermanLabelledValuesForR1(labelledValues: labelledValues)
                    
                    if relabelledValues?.label.contains("SGA") ?? false {
                        if sga == nil {
                            if let valid = relabelledValues?.values {
                                sga = valid
                            }
                        } else if let valid = relabelledValues?.values {
                            for i in 0..<sga!.count {
                                sga![i] += valid[i]
                            }
                        }
                    }
                    else if relabelledValues?.label ?? "" == "Summe Anlageverm" {
                        sumAnlVerm = relabelledValues?.values
                    }
                    else if relabelledValues?.label ?? "" == "Wertminderung" {
                        wertMind = relabelledValues?.values
                    }
                    else if relabelledValues?.label ?? "" == "Shares outstanding" {
                        sharesOutStanding = relabelledValues?.values
                    }
                    else if relabelledValues?.label ?? "" == "Current shares outstanding" {
                        if sharesOutStanding == nil {
                            sharesOutStanding = relabelledValues?.values
                        } else if let cso = relabelledValues?.values.first {
                            sharesOutStanding![0] = cso
                        }
                    }
                    else {
                        if let valid = relabelledValues {
                            allLabelledValues.append(valid)
                        }
                    }
                }
                count += 1
            }
        } catch {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "extractData from Tagesschau failed for some row titles")

        }
        
        if let valid = sga {
            allLabelledValues.append(LabelledValues(label: "sgaExpense", values: valid))
            print("'SGA expense' downloaded and calculated for sgaExpenses value for WBValuation \(allLabelledValues.last!) - currently unused")
        }
        
        if let valid1 = wertMind {
            if let valid2 = sumAnlVerm {
                var yoyChange = [Double]()
                let recent = valid2[0]
                for i in 1..<valid2.count {
                    yoyChange.append(recent - valid2[i] + valid1[i])
                }
                allLabelledValues.append(LabelledValues(label: "capExpend", values: yoyChange))
//                print("'capEx' downloaded and calculated for capEx for WBValuation \(allLabelledValues.last!) - currently unused")
            }
        }
        
        if let ocf = allLabelledValues.filter({ lValues in
            if lValues.label == "Operating cash flow" { return true }
            else { return false }
        }).first {
            
            if let vsa = sharesOutStanding {
                var cfps = [Double]()
                
                var count = 0
                for cf in ocf.values {
                    if vsa.count > count {
                        cfps.append(cf / vsa[count])
                    }
                    count += 1
                }
                allLabelledValues.append(LabelledValues(label: "Operating Cash Flow Per Share", values: cfps))
            }
        }
                
        let aLV = allLabelledValues
//        Task.init(priority: .background, operation: {
//            try await saveR1Data(valuationID: valuationID, labelledValues: aLV)
//            progressController?.downloadComplete()
//            NotificationCenter.default.post(name: Notification.Name(rawValue: "DownloadEnded"), object: nil, userInfo: nil)
//        })
        
        return allLabelledValues
        
    }
    
    /*
    class func calculateROIC(epit: [Double]?, eigenKap: [Double]?, fremdKap: [Double]?) -> [Double]? {
        guard let vEpit = epit else { return  nil }
        guard let vEigenK = eigenKap else { return nil }
        guard let vFremdK = fremdKap else { return nil }
        
        guard vEpit.count == vEigenK.count else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "error calculating ROIC from Tagesschau. No of years of Erg v Steuern does not match no of years of Summe EigenKap")
            return nil
        }
        
        guard vEigenK.count == vFremdK.count else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "error calculating ROIC from Tagesschau. No of years of Summe FremdKapital does not match no of years of Summe EigenKap")
            return nil
        }
        
        var roic = [Double]()
        
        for i in 0..<vEpit.count {
            // saved in 'saveR1Data' by dividing by 100, so multiply here
            let r = 100 * vEpit[i] / (vEigenK[i] + vFremdK[i])
            roic.append(r)
        }
        
        return roic
    }
    */
    
    class func translateGermanLabelledValuesForR1(labelledValues: LabelledValues?) -> LabelledValues? {
        
        guard let label = labelledValues?.label else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "values for downloaded from Tagesschau website with identifying label")
            return nil
        }
        
        var newLabel: String?
        var modifiedValues = labelledValues!.values
        
        switch label {
        case "Eigenkapitalrendite":
            print("Eigenkapitalrendite downloaded for single ROI value for WBValuation - currently unused")
        case "Umsatz":
            newLabel = "Revenue"
        case "Gewinn je Aktie":
            newLabel = "EPS - Earnings Per Share"
            modifiedValues = labelledValues!.values.compactMap{ $0 / 1_000 }
        case "Operatives Ergebnis":
            print("Operatives Ergebnis downloaded for operatingIncome value for WBValuation - currently unused")
        case "Buchwert je Aktie":
            newLabel = "Book Value Per Share"
            modifiedValues = labelledValues!.values.compactMap{ $0 / 1_000 }
        case "Wertminderung":
            newLabel = "Wertminderung" // user together with 'Summe Anlagevermögen' YoY for capEx calculation
        case "Ergebnis vor Steuer:":
            print("Ergebnis vor Steuer: downloaded for grossProfit value for WBValuation - currently unused")
        case "hnliche Aufwendungen":
            // complete title 'Zinsen und ähnliche Aufwendungen'
            print("'Zinsen und ähnliche Aufwendungen' downloaded for interestExpense value for WBValuation - currently unused")
        case "Personalaufwand":
            newLabel = "SGA1" // calculate total SGA for WBvaluation
        case "Materialaufwand":
            newLabel = "SGA2"  // calculate total SGA for WBvaluation
        case "Sonstige betriebliche Aufwendungen":
            newLabel = "SGA3" // calculate total SGA for WBvaluation
//        case "nderung der Finanzmittel":
//            // full title is 'Veränderung der Finanzmittel'
//            newLabel = "Operating cash flow"
//            modifiedValues = labelledValues!.values.compactMap{ $0 * 1_000_000 }
        case "Eigene Aktien":
            // convert from negative, then use YoY change for ret. earnings/ eqRepurchased for WBV'
            print("'Eigene Aktien' downloaded for eqRepurchased value for WBValuation - currently unused")
        case "Summe Anlageverm":
            // Summe Anlagevermögen (YoY change) + Wertminderung = cepEx
            newLabel = "Summe Anlageverm"
        case "Langfristige Finanzverbindlichkeiten":
            newLabel = "Long Term Debt"
            modifiedValues = labelledValues!.values.compactMap{ $0 / 1_000 }
        case "Ausstehende Aktien":
            newLabel = "Shares outstanding"
            modifiedValues = labelledValues!.values.compactMap{ $0 * 1_000_000 }
        case "Aktuell ausstehende Aktien":
            newLabel = "Current shares outstanding"
            modifiedValues = labelledValues!.values.compactMap{ $0 * 1_000_000 }
        default:
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "unexpected label downloaded from Tagesschau website for \(label)")
        }
        
        if let valid = newLabel {
            return LabelledValues(label: valid, values: modifiedValues)
        } else {
            return nil
        }
    }
    
    class func extractDataFromTagesschau(html: String, sectionHeader: String, rowTitle: String) -> Any? {
                
        let sectionEnd = "</tbody>"
        let rowStartSeq = "<tr>"
        let rowEndSeq = "</tr>"
        
        let columnStartSeq = "<td>"
        let columnEndSeq = "</td>"
        
        let tableStartSeq = " <table class"
        let tableEndSeq = "</table>"
        
        let topRowStartSeq = "<thead>"
        let topRowEndSeq = " </thead>"
        let topRowValueStartSeq = "<th>"
        
        let valueEndSeq = "</span>"

        var values = [Double]()
        var dates: [Date?]?
        
        var labelledValues: LabelledValues?
        var labelledDatedValues: Labelled_DatedValues?
        
        guard let sectionStart = html.range(of: sectionHeader) else {
            return nil
        }
        
        guard let sectionEnd = html.range(of: sectionEnd, range: sectionStart.upperBound..<html.endIndex) else {
            return nil
        }
        
        let dateRowStart = html.range(of: topRowStartSeq, range: sectionStart.upperBound..<sectionEnd.lowerBound)
        var dateRowEnd: Range<String.Index>?
        
        // extract years data from tabel top row
        if dateRowStart != nil {
            dateRowEnd = html.range(of: topRowEndSeq, range: dateRowStart!.upperBound..<html.endIndex)
            
            if dateRowEnd != nil {
                let topRow$ = String(html[dateRowStart!.upperBound..<dateRowEnd!.lowerBound])
                let values$ = topRow$.components(separatedBy: topRowValueStartSeq)

                dates = [Date?]()
                let calendar = Calendar.current
                let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]
                var dateComponents = calendar.dateComponents(components, from: Date())
                dateComponents.second = 59
                dateComponents.minute = 59
                dateComponents.hour = 23
                dateComponents.day = 31
                dateComponents.month = 12

                for value$ in values$ {
                    
                    let data = Data(value$.utf8)
                    if let content$ = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil).string {
                        let value = content$.filter("0123456789.".contains)
                        
                        if let yearValue = Int(value) {
                            if yearValue > 2000 && yearValue < 2030 {
                                dateComponents.year = yearValue
                                dates?.append(calendar.date(from: dateComponents))
                            }
                            else {
                                ErrorController.addInternalError(errorLocation: #function, errorInfo: "year date extraction error from Tagesschau data: \(value)")
                            }
                        }
                    }
                }

            }
        }
        // extract years data from tabel top row

        guard let rowStart = html.range(of: rowTitle, range: (dateRowStart ?? sectionStart).upperBound..<html.endIndex) else {
            return nil
        }
        
        guard let rowEnd = html.range(of: rowEndSeq, range: rowStart.upperBound..<html.endIndex) else {
            return nil
        }

        // extract number values
        let rowText = String(html[rowStart.upperBound..<rowEnd.lowerBound])
        let values$ = rowText.components(separatedBy: columnEndSeq)
//        let oneMillion = 1000000.0
        for value$ in values$ {
            
            let data = Data(value$.utf8)
            if let content$ = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil).string {
                var value$ = content$.filter("-0123456789,%".contains)
                value$ = value$.replacingOccurrences(of: ",", with: ".")
                if value$.last == "%" {
                    let value = Double(value$.dropLast()) ?? 0.0
                    values.append(value/100.0)
                }
                else if value$ == "-" {
                    values.append(0.0)
                }
                else if let value = Double(value$) {
                    values.append(value*1000)
                }
           }
        }

        let data = Data(rowTitle.utf8)
        let label = (try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil).string) ?? "Missing row label"
        
        
        if let validDates = dates?.compactMap({ $0 }) {
            
            if validDates.count == values.count {
                var datedValues = [DatedValue]()
                for i in 0..<validDates.count {
                    datedValues.append(DatedValue(date: validDates[i], value: values[i]))
                }
                labelledDatedValues = Labelled_DatedValues(label: label, datedValues: datedValues)
            } else {
                ErrorController.addInternalError(errorLocation: #function, errorInfo: "mismatch between extracted years count and values count, from Tagesschau website \(validDates) \(values)")
            }
        } else {
            // no year numbers found, use values in array
            labelledValues = LabelledValues(label: label, values: values)
        }

        
        return labelledDatedValues ?? labelledValues
    }
    
    class func extractStringFromTagesschau(html: String, searchTerm: String) throws -> String? {
        
        let rowStart = "<tr>"
        let valueEnd = "</span>"
        
        guard let termStart = html.range(of: searchTerm) else {
            throw InternalErrorType.htmlRowStartIndexNotFound
        }
        
        guard let termEnd = html.range(of: valueEnd, range: termStart.upperBound..<html.endIndex) else {
            throw InternalErrorType.contentEndSequenceNotFound
        }
        
        let target$ = String(html[termStart.upperBound..<termEnd.lowerBound])
        return target$.replacingOccurrences(of: " ", with: "")

    }


    
    //MARK: - DCF data
    
    class func dcfDataDownloadAndSave(shareSymbol: String?, valuationID: NSManagedObjectID, progressDelegate: ProgressViewDelegate?=nil) async throws {
        
        guard let symbol = shareSymbol else {
            progressDelegate?.downloadError(error: "Failed DCF valuation download: missing share symbol")
            throw InternalErrorType.shareSymbolMissing
        }
         
 // 1 Download and analyse web page data
        var results = [LabelledValues]()
        let allTasks = 6
        var progressTasks = 0
        
        for title in ["key-statistics", "financials", "balance-sheet", "cash-flow", "analysis"] {
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
            
            let labelledResults = try dcfDataExtraction(htmlText: htmlText, section: title)
            results.append(contentsOf: labelledResults)
        }
        
// 2 Save data to background DCFValuation
        let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc.automaticallyMergesChangesFromParent = true
        
        await backgroundMoc.perform {
            do {
                if let dcfv = backgroundMoc.object(with: valuationID) as? DCFValuation {

                    do {
                        for result in results {
                            switch result.label {
                            case _ where result.label.starts(with: "Market cap (intra-day)"):
                                dcfv.marketCap = result.values.first ?? Double()
                            case _ where result.label.starts(with: "Beta (5Y monthly)"):
                                dcfv.beta = result.values.first ?? Double()
                            case _ where result.label.starts(with: "Shares outstanding"):
                                dcfv.sharesOutstanding = result.values.first ?? Double()
                            case _ where result.label.starts(with: "Total revenue"):
                                dcfv.tRevenueActual = result.values
                            case _ where result.label.starts(with: "Net income"):
                                dcfv.netIncome = result.values
                            case _ where result.label.starts(with: "Interest expense"):
                                dcfv.expenseInterest = result.values.first ?? Double()
                            case _ where result.label.starts(with: "Income before tax"):
                                dcfv.incomePreTax = result.values.first ?? Double()
                            case _ where result.label.starts(with: "Income tax expense"):
                                dcfv.expenseIncomeTax = result.values.first ?? Double()
                            case _ where result.label.starts(with: "Current debt"):
                                dcfv.debtST = result.values.first ?? Double()
                            case _ where result.label.starts(with: "Long-term debt"):
                                dcfv.debtLT = result.values.first ?? Double()
                            case _ where result.label.starts(with: "Total Debt"):
                                dcfv.totalDebt = result.values.first ?? Double()
                            case _ where result.label.starts(with: "Operating cash flow"):
                                dcfv.tFCFo = result.values
                            case _ where result.label.starts(with: "Capital expenditure"):
                                dcfv.capExpend = result.values
                            case _ where result.label.starts(with: "Avg. Estimate"):
                                dcfv.tRevenuePred = result.values
                            case _ where result.label.starts(with: "Sales growth (year/est)"):
                                dcfv.revGrowthPred = result.values
                            default:
                                ErrorController.addInternalError(errorLocation: "WebPageScraper2.dcfDataDownload", systemError: nil, errorInfo: "unspecified result label \(result.label) for share \(symbol)")
                            }
                        }
                        
                        dcfv.creationDate = Date()
                        try backgroundMoc.save()
                        
                        let (dcfValue, _) = dcfv.returnIValue()
                        if dcfValue != nil {
                            let trendValue = DatedValue(date: dcfv.creationDate!, value: dcfValue!)
                            dcfv.share?.saveTrendsData(datedValuesToAdd: [trendValue], trendName: .dCFValue)
                        }

                        progressDelegate?.downloadComplete()
                        
                    } catch let error {
                        ErrorController.addInternalError(errorLocation: "WebPageScraper2.dcfDataDownload", systemError: error, errorInfo: "Error saving DCF data download results for \(symbol)")
                    }
                   
                }
            }
        }
        
    }
    
    /// called  by StocksController.updateStocks for non-US stocks when trying to download from MacroTrends
    class func nonMTRule1DataDownload(symbol: String?, shortName: String?, valuationID: NSManagedObjectID ,progressController: ProgressViewDelegate?=nil) async throws {
        
        guard let valid = symbol else {
            ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "missing stock symbol")
            progressController?.cancelRequested()
            return
        }
        
        guard let validSN = shortName else {
            ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "missing stock short name")
            progressController?.cancelRequested()
            return
        }


        let webString = valid.replacingOccurrences(of: " ", with: "+")
        let webStringComps = webString.split(separator: ".")
        var tagesschauURL: URL?
        if let symbolNoDots = webStringComps.first {
            tagesschauURL = URL(string: "https://www.tagesschau.de/wirtschaft/boersenkurse/suche/?suchbegriff=\(symbolNoDots)")
        }
        
        let snComponents = validSN.split(separator: " ")
        var arivaComponents = String(snComponents.first!)
        if snComponents.count > 1 {
            if snComponents[1] == "SE" {
                arivaComponents += " " + String(snComponents[1])
            }
        }
        let arivaString = arivaComponents.replacingOccurrences(of: " ", with: "_") + "-aktie"
        let arivaURL = URL(string: "https://www.ariva.de/\(arivaString)/bilanz-guv")
        let tsURL = tagesschauURL
        
        // TODO: - download from 3 sites, but an error thrown at each will stop execution so the others don't download
        Task.init {
            do {
                // download from ariva and move on after async let...
                var r1LabelledValues = [LabelledValues]()
                
                async let arivaHTML = try? Downloader.downloadData(url: arivaURL!)
                // also download limited R1 data from Yahoo
                async let yahooLVS = try? r1DataFromYahoo(symbol: symbol!, downloadRedirectDelegate: nil)
                
                // find full url for company on tagesschau search page
                if let html = try await Downloader().downloadDataWithRedirection(url: tsURL) {
                    var tagesschauShareURLs = try shareAddressLineTagesschau(htmlText: html)
                    if tagesschauShareURLs?.count ?? 0 > 1 {
                        tagesschauShareURLs = tagesschauShareURLs?.filter({ address in
                            if address.contains("aktie") { return true }
                            else { return false }
                        })
                    }
                    
                    if let firstAddress = tagesschauShareURLs?.first {
                        if let url = URL(string: firstAddress) {
                            
                            // 2 download tagesschau data webpage from full url
                            if let infoPage = try? await Downloader.downloadData(url: url) {
                                if infoPage != "" {
                                    if let tsLVS = try? r1DataFromTagesschau(htmlText: infoPage, symbol: symbol, valuationID: valuationID, progressController: progressController) {
                                        r1LabelledValues.append(contentsOf: tsLVS)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // ...continue analysing arivaHTML here
                if let arivaLDVs = await arivaPageAnalysis(html: arivaHTML ?? "", headers: ["Bewertung"], parameters: [["KGV (Kurs/Gewinn)","Return on Investment in %"]]) {
                    for ldv in arivaLDVs {
                        let newLV = LabelledValues(label: ldv.label, values: ldv.datedValues.compactMap{ $0.value} )
                        r1LabelledValues.append(newLV)
                    }
                }
                
                if var lvs = await yahooLVS {
                    
                    // merge TS and Yahoo Revenue figures
                    if var tsRevenue = r1LabelledValues.filter({ lvalues in
                        if lvalues.label == "Revenue" { return true }
                        else { return false }
                    }).first {
                        print(tsRevenue)
                        if let yahooRevenue = lvs.filter({ lvalues in
                            if lvalues.label == "Revenue" { return true }
                            else { return false }
                        }).first {
                            print(yahooRevenue)
                            tsRevenue.values.insert(yahooRevenue.values[0], at: 0)
                            r1LabelledValues = r1LabelledValues.filter({ lValue in
                                if lValue.label == "Revenue" { return false }
                                else { return true }
                            })
                            print(tsRevenue)
                            r1LabelledValues.append(tsRevenue)
                            lvs = lvs.filter({ lValue in
                                if lValue.label == "Revenue" { return false }
                                else { return true }
                            })
                        }
                    }
                    
                    // if available use TS long-term debt data
                    if let tsLTDebt = r1LabelledValues.filter({ lvalues in
                        if lvalues.label == "Long Term Debt" { return true }
                        else { return false }
                    }).first {
                        
                        if tsLTDebt.values.count > 3 {
                            
                            lvs = lvs.filter({ lValue in
                                if lValue.label == "Long Term Debt" { return false }
                                else { return true }
                            })
                            
                        }
                        else {
                            r1LabelledValues = r1LabelledValues.filter({ lValue in
                                if lValue.label == "Long Term Debt" { return false }
                                else { return true }
                            })
                            
                        }
                    }

                    // if tagesschau EPS has more than TTM and last 3 years use these, otherwise use Yahoo
                    if r1LabelledValues.filter({ lValues in
                        if lValues.label == "EPS - Earnings Per Share" { return true }
                        else { return false }
                    }).first?.values.count ?? 0 > 4 {
                        r1LabelledValues.append(contentsOf: lvs.filter({ lValues in
                            if lValues.label == "EPS - Earnings Per Share" { return false }
                            else { return true }
                        }))
                    }
                    else {
                        r1LabelledValues.append(contentsOf: lvs)
                    }
                }
//
//                print()
//                print("Rule 1 data frm tagesschau, ariva and yahoo:")
//                for lv in r1LabelledValues {
//                    print(lv)
//                }
//
                for i in 0..<r1LabelledValues.count {
                    if let latest = r1LabelledValues[i].values.first {
                        if latest == 0.0 {
                            r1LabelledValues[i].values = Array(r1LabelledValues[i].values.dropFirst())
                        }
                    }
                }
                                
                try await saveR1Data(valuationID: valuationID, labelledValues: r1LabelledValues)

                NotificationCenter.default.post(name: Notification.Name(rawValue: "DownloadEnded"), object: nil, userInfo: nil)

            } catch {
                progressController?.downloadError(error: error.localizedDescription)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "DownloadEnded"), object: nil, userInfo: nil)
                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "error downloading 'Tageschau' Aktien info page")
            }
        }
    }
    
    class func arivaPageAnalysis(html: String, headers: [String], parameters: [[String]]) -> [Labelled_DatedValues]? {
        
        let rowEndSequence = "</tr> <tr>"
        let columnEndSequence = "</td>"
        let columnStartSequence = "<td class="
        let tableEndSequence = "</tbody> </table>"
        let tableStartSequence = "<tbody>"
        
        var pageText = html
        var dates: [Date?]?
        var ldv: [Labelled_DatedValues]?
        
        var i = 0
        for header in headers {
            
            guard let headerPosition = pageText.range(of: header) else {
                i += 1
                continue
            }
            
            guard let tableEndPosition = pageText.range(of: tableEndSequence, range: headerPosition.upperBound..<pageText.endIndex) else {
                i += 1
                continue
            }
            
            var tableText = pageText[headerPosition.upperBound..<tableEndPosition.lowerBound]
            
            // 1 get years from first row
            guard let tableStart = tableText.range(of: tableStartSequence) else {
                i += 1
                continue
            }
            
            guard let yearsRowStart = tableText.range(of: columnStartSequence, range: tableStart.upperBound..<tableText.endIndex) else {
                i += 1
                continue
            }
            
            let calendar = Calendar.current
            let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]
            var dateComponents = calendar.dateComponents(components, from: Date())
            dateComponents.second = 59
            dateComponents.minute = 59
            dateComponents.hour = 23
            dateComponents.day = 31
            dateComponents.month = 12

            dates = [Date?]()
            guard let yearsRowEnd = tableText.range(of: rowEndSequence, range: yearsRowStart.upperBound..<tableText.endIndex) else {
                i += 1
                continue
            }
            var yearsRow$ = tableText[yearsRowStart.lowerBound..<yearsRowEnd.lowerBound]
            var yearColumnEnd = yearsRow$.range(of: columnEndSequence)
            while yearColumnEnd != nil {
                guard let columStart = yearsRow$.range(of: columnStartSequence) else {
                    break
                }
                let column$ = yearsRow$[columStart.upperBound..<yearColumnEnd!.lowerBound]
                let content$ = column$.filter("-0123456789/".contains)
                if let year$ = content$.split(separator: "/").first {
                    if let yearValue = Int(year$) {
                        if yearValue > 2000 && yearValue < 2030 {
                            dateComponents.year = yearValue
                            dates?.append(calendar.date(from: dateComponents))
                        }
                        else {
                            ErrorController.addInternalError(errorLocation: #function, errorInfo: "year date extraction error from ariva web data: \(yearValue)")
                        }
                    }
                }
                yearsRow$ = yearsRow$[yearColumnEnd!.upperBound...]
                yearColumnEnd = yearsRow$.range(of: columnEndSequence)
            }
            
            // 2 get related parameters
            ldv = [Labelled_DatedValues]()
            for parameter in parameters[i] {

                var parameterValues = [Double?]()
                if var parameterStart = tableText.range(of: parameter) {
                    guard let rowStart = tableText.range(of: columnEndSequence, range: parameterStart.upperBound..<tableText.endIndex) else {
                        i += 1
                        continue
                    }
                    
                    if let rowEnd = tableText.range(of: rowEndSequence, range: rowStart.upperBound..<tableText.endIndex) {
                        var row$ = tableText[rowStart.upperBound..<rowEnd.lowerBound]
                        var columnEnd = row$.range(of: columnEndSequence)
                        while columnEnd != nil {
                            guard let columStart = row$.range(of: columnStartSequence) else {
                                break
                            }
                            let content$ = row$[columStart.upperBound..<columnEnd!.lowerBound]
                            let validValue = Double(content$.filter("-0123456789,".contains).replacingOccurrences(of: ",", with: "."))
                            parameterValues.append(validValue)
                            row$ = row$[columnEnd!.upperBound...]
                            columnEnd = row$.range(of: columnEndSequence)
                        }
                    }
                }
                
                if let vDates = dates {
                    if parameterValues.count == vDates.count {
                        
                        var dvs = [DatedValue]()
                        var j = 0
                        for date in vDates {
                            if let value = parameterValues[j], date != nil {
                                dvs.append(DatedValue(date: date!, value: value))
                            }
                            j += 1
                        }
                        dvs = dvs.sorted(by: { dv0, dv1 in
                            if dv0.date > dv1.date { return true }
                            else { return false }
                        })
                        var translatedParameter = String()
                        if parameter.contains("KGV") {
                            translatedParameter = "PE Ratio Historical Data"
                        } else if parameter.contains("Return on Investment") {
                            translatedParameter = "ROI - Return On Investment"
                        }
                        ldv?.append(Labelled_DatedValues(label: translatedParameter, datedValues: dvs))
                    }
                }
            }
                    
            i += 1
        }
        
        return ldv
    }
    
    class func saveR1Data(valuationID: NSManagedObjectID, labelledValues: [LabelledValues]) async throws {
        
        let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc.automaticallyMergesChangesFromParent = true
        
        //TODO: - share some values with wbv, dcf and research

        try await backgroundMoc.perform {

            do {
                if let r1v = backgroundMoc.object(with: valuationID) as? Rule1Valuation {
                    
                    for result in labelledValues {
                        switch result.label.lowercased() {
                        case "revenue":
                            r1v.revenue = result.values
                        case "eps - earnings per share":
                            r1v.eps = result.values
                        case "net income":
                            if let value = result.values.first {
                                r1v.netIncome = value * pow(10, 3)
                            }
                        case "roi - return on investment":
                            r1v.roic = result.values.compactMap{ $0/100.0 }
                        case "book value per share":
                            r1v.bvps = result.values
                        case "operating cash flow per share":
                            r1v.opcs = result.values
                        case "long term debt":
                            let cleanedResult = result.values.filter({ (element) -> Bool in
                                return element != Double()
                            })
                            if let debt = cleanedResult.first {
                                r1v.debt = debt * 1000
                            }
                        case "pe ratio historical data":
                            r1v.hxPE = result.values
                        case "sales growth (year/est)":
                            r1v.growthEstimates = result.values
                        case "operating cash flow":
                            r1v.opCashFlow = result.values.first ?? Double()
                        case "purchases":
                            r1v.insiderStockBuys = result.values.last ?? Double()
                        case "sales":
                            r1v.insiderStockSells = result.values.last ?? Double()
                        case "total insider shares held":
                            r1v.insiderStocks = result.values.last ?? Double()
                        case "forward p/e":
                            r1v.adjFuturePE = result.values.last ?? Double()
                        default:
                            ErrorController.addInternalError(errorLocation: "WebPageScraper2.saveR1Date", systemError: nil, errorInfo: "unspecified result label \(result.label)")
                        }
                    }
                    
                    r1v.creationDate = Date()
                    try backgroundMoc.save()
                
                    // save new value with date in a share trend
                    if let vShare = r1v.share {
                        if let moat = r1v.moatScore() {
                            let dv = DatedValue(date: r1v.creationDate!, value: moat)
                            vShare.saveTrendsData(datedValuesToAdd: [dv], trendName: .moatScore)
                        }
                        let (price,_) = r1v.stickerPrice()
                        if price != nil {
                            let dv = DatedValue(date: r1v.creationDate!, value: price!)
                            vShare.saveTrendsData(datedValuesToAdd: [dv], trendName: .stickerPrice)
                        }
                    }

                }
            } catch {
                ErrorController.addInternalError(errorLocation: "WebPageScraper2.saveR1Data", systemError: error, errorInfo: "Error saving R1 data download")
                throw error
            }
       }
    }
    
    class func shareAddressLineTagesschau(htmlText: String) throws -> [String]? {
        
        let sectionStartSequence = "desktopSearchResult"
        let sectionEndSequence = "Die Daten werden von der Infront Financial Technology GmbH bereitgestellt"
        let addressStartSequence = "document.location="
        let addressEndSequence = "';"
        
        var addresses = Set<String>()
        
        guard let sectionStart = htmlText.range(of: sectionStartSequence) else {
            throw InternalErrorType.contentStartSequenceNotFound
        }
        
        guard let sectionEnd = htmlText.range(of: sectionEndSequence) else {
            throw InternalErrorType.contentStartSequenceNotFound
        }
        
        let croppedHtml = String(htmlText[sectionStart.upperBound..<sectionEnd.lowerBound])
        
        guard let startPosition = croppedHtml.range(of: addressStartSequence) else {
            throw InternalErrorType.contentStartSequenceNotFound
        }
        
        guard let endPosition = croppedHtml.range(of: addressEndSequence, range: startPosition.upperBound..<croppedHtml.endIndex) else {
            throw InternalErrorType.contentEndSequenceNotFound
        }

        let address$ = String(croppedHtml[startPosition.upperBound..<endPosition.lowerBound])
        let address = address$.replacingOccurrences(of: "\'", with: "")
        addresses.insert(address)
        
        var nextEndPosition: Range<String.Index>?
        var nextStartPosition = croppedHtml.range(of: addressStartSequence,range: endPosition.upperBound..<croppedHtml.endIndex)
        if nextStartPosition != nil {
            nextEndPosition = croppedHtml.range(of: addressEndSequence,range: nextStartPosition!.upperBound..<croppedHtml.endIndex)
        }
        
        while nextEndPosition != nil {
            let address$ = String(croppedHtml[nextStartPosition!.upperBound..<nextEndPosition!.lowerBound])
            let address = address$.replacingOccurrences(of: "\'", with: "")
            addresses.insert(address)
            
            nextStartPosition = croppedHtml.range(of: addressStartSequence,range: nextEndPosition!.upperBound..<croppedHtml.endIndex)
            if nextStartPosition != nil {
                nextEndPosition = croppedHtml.range(of: addressEndSequence, range: nextStartPosition!.upperBound..<croppedHtml.endIndex)
            } else {
                nextEndPosition = nil
            }
        }
        
        print("TS Addressen found: \(addresses)")
        
        return Array(addresses)
        
    }
        
    
    /// calls Downloader function with completion handler to return csv file
    /// returns extracted [DateValue] array through Notification with name ""TBOND csv file downloaded""
    class func downloadAndAnalyseTreasuryYields(url: URL) async {
        
       let treasuryCSVHeaderTitles = ["Date","\"1 Mo\"", "\"2 Mo\"","\"3 Mo\"","\"4 Mo\"","\"6 Mo\"","\"1 Yr\"","\"2 Yr\"","\"3 Yr\"","\"5 Yr\"","\"7 Yr\"","\"10 Yr\"","\"20 Yr\"","\"30 Yr\""]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"

        do {
            if let fileURL = try await Downloader.downloadCSVFile2(url: url, symbol: "TBonds", type: "_TB") {

                if let datedValues = try await analyseYahooCSVFile(localURL: fileURL, expectedHeaderTitles: treasuryCSVHeaderTitles, dateFormatter: dateFormatter) {
                    
                    var tenYDatedRates = [DatedValue]()
                    for value in datedValues {
                        let dValue = DatedValue(date: value.date, value: value.values[11])
                        tenYDatedRates.append(dValue)
                    }

                    NotificationCenter.default.post(name: Notification.Name(rawValue: "TBOND csv file downloaded"), object: tenYDatedRates, userInfo: nil)
                }
            }
        } catch {
            ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "Error downloading TBond rates")
        }
    }

    //MARK: - WBV functions
    /// uses MacroTrends webpage
    class func downloadAnalyseSaveWBValuationDataFromMT(shareSymbol: String?, shortName: String?, valuationID: NSManagedObjectID, progressDelegate: ProgressViewDelegate?=nil, downloadRedirectDelegate: DownloadRedirectionDelegate) async throws {
        
        guard let symbol = shareSymbol else {
            throw InternalErrorType.shareSymbolMissing
        }
        
        guard var sn = shortName else {
            throw InternalErrorType.shareShortNameMissing
        }
        
        if sn.contains(" ") {
            sn = sn.replacingOccurrences(of: " ", with: "-")
        }
        var downloadErrors: [InternalErrorType]?
        
        let webPageNames = ["financial-statements", "balance-sheet", "cash-flow-statement" ,"financial-ratios"]
        
        let rowNames = [["Revenue","Gross Profit","Research And Development Expenses","SG&A Expenses","Net Income", "Operating Income", "EPS - Earnings Per Share"],["Long Term Debt","Property, Plant, And Equipment","Retained Earnings (Accumulated Deficit)", "Share Holder Equity"],["Cash Flow From Operating Activities"],["ROE - Return On Equity", "ROA - Return On Assets", "Book Value Per Share"]]
        
        var results = [LabelledValues]()
        var resultDates = [Date]()
        var sectionCount = 0
        let downloader: Downloader? = Downloader(task: .wbValuation)
        for section in webPageNames {
            
            if let components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(symbol)/\(sn)/\(section)")  {
                if let url = components.url  {
                    
                    NotificationCenter.default.addObserver(downloadRedirectDelegate, selector: #selector(DownloadRedirectionDelegate.awaitingRedirection(notification:)), name: Notification.Name(rawValue: "Redirection"), object: nil)

                    let htmlText = try await downloader?.downloadDataWithRedirection(url: url)
                    
                    if let validPageText = htmlText {
                        
                        let labelledDatedValues = try await WebPageScraper2.extractDatedValuesFromMTTable(htmlText: validPageText, rowTitles: rowNames[sectionCount])
                        
                        let labelledValues = labelledDatedValues.compactMap{ LabelledValues(label: $0.label, values: $0.datedValues.compactMap{ $0.value }) }
                        
                        var dates = [Date]()
                        for ldv in labelledDatedValues {
                            let extractedDates = ldv.datedValues.compactMap { $0.date }
                            dates.append(contentsOf: extractedDates)
                        }
                        resultDates.append(contentsOf: dates)
                        results.append(contentsOf: labelledValues)
                        
                        sectionCount += 1
                    }
                    else {
                        if downloadErrors == nil { downloadErrors = [InternalErrorType.generalDownloadError] }
                        else { downloadErrors?.append(InternalErrorType.generalDownloadError)}
                    }
                }
            }
        }
        
        // capEx = net PPE for capEx from Yahoo
        var components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)/balance-sheet")
        components?.queryItems = [URLQueryItem(name: "p", value: symbol)]
        
        if let url = components?.url  {
            
            let netPPE = "Net property, plant and equipment"
            let htmlText = try await Downloader.downloadData(url: url)
            
            if let lvs = YahooPageScraper.extractYahooPageData(html: htmlText, pageType: .balance_sheet, tableHeader: "Balance sheet", rowTitles: [netPPE]) {
            
//            if let lvs = yahooFinancialsExtraction(html: htmlText, tableHeader: "Balance sheet", rowTitles: [netPPE]) {
                results.append(contentsOf: lvs)
            }
            else {
                ErrorController.addInternalError(errorLocation: #function, errorInfo: "Failed to get net PPE from Yahoo Financials > balance sheet for \(symbol)")
            }

            
        }
        
        
// Historical PE and EPS with dates
        var perAndEPSvalues: [Dated_EPS_PER_Values]?
        if let components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(symbol)/\(sn)/pe-ratio") {
            if let url = components.url {
                perAndEPSvalues = try await getHxEPSandPEData(url: url, companyName: sn, until: nil, downloadRedirectDelegate: downloadRedirectDelegate)
            }
        }
            
// Historical stock prices
        var hxPriceValues: [Double]?
        
        if let components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(symbol)/\(sn)/stock-price-history") {
            if let url = components.url {
                
                var htmlText = String()
                do {
                    htmlText = try await Downloader.downloadData(url: url)
                    
                    hxPriceValues = try macrotrendsScrapeColumn(html$: htmlText, tableHeader: "Historical Annual Stock Price Data</th>", tableTerminal: "</tbody>", columnTerminal: "</td>" ,noOfColumns: 7, targetColumnFromRight: 6)
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

        try await backgroundMoc.perform {

            do {

                if let wbv = backgroundMoc.object(with: valuationID) as? WBValuation {
                                                                
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
                        }
                        
                    wbv.latestDataDate = resultDates.max()
                    
                        if let validEPSPER = perAndEPSvalues {
                            let perDates: [DatedValue] = validEPSPER.compactMap{ DatedValue(date: $0.date, value: $0.peRatio) }
                            wbv.savePERWithDateArray(datesValuesArray: perDates, saveInContext: false)
                            let epsDates: [DatedValue] = validEPSPER.compactMap{ DatedValue(date: $0.date, value: $0.epsTTM) }
                            wbv.saveEPSTTMWithDateArray(datesValuesArray: epsDates, saveToMOC: false)
                        }
                        
                        wbv.avAnStockPrice = hxPriceValues?.reversed()
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
                try backgroundMoc.save()
            } catch let error {
                ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: error, errorInfo: "couldn't save background MOC")
            }
            
            
            if (downloadErrors ?? []).contains(InternalErrorType.generalDownloadError) {
                throw InternalErrorType.generalDownloadError
            }
        }
        
    }
    
    class func downloadAnalyseSaveWBValuationDataFromYahoo(shareSymbol: String?, valuationID: NSManagedObjectID, progressDelegate: ProgressViewDelegate?=nil, downloadRedirectDelegate: DownloadRedirectionDelegate) async throws {
        
        guard let symbol = shareSymbol else {
            throw InternalErrorType.shareSymbolMissing
        }
        
        var downloadErrors: [InternalErrorType]?
        
        let webPageNames = ["financials", "balance-sheet", "cash-flow" ,"analysis"]
        let tableTitles = ["Income statement", "Balance sheet", "Cash flow", "Revenue estimate"]
        
        let rowNames = [["Total revenue","Gross profit","Research development","Selling general and administrative","Net income", "Operating income or loss", "Basic EPS"],["Total non-current liabilities","Gross property, plant and equipment", "Net property, plant and equipment","Retained earnings", "Total stockholders&#x27; equity"],[ "Net cash provided by operating activities"],["Sales growth (year/est)"]]
        
        var results = [LabelledValues]()
        var sectionCount = 0

        for section in webPageNames {
            
            var pageType: YahooPageType!
            if section.contains("financials") {
                pageType = .financials
            } else if section.contains("balance") {
                pageType = .balance_sheet
            } else if section.contains("cash") {
                pageType = .cash_flow
            } else if section.contains("analysis") {
                pageType = .analysis
            }
            
            var components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)/\(section)")
            components?.queryItems = [URLQueryItem(name: "p", value: symbol)]
            
            if let url = components?.url  {
                
                NotificationCenter.default.addObserver(downloadRedirectDelegate, selector: #selector(DownloadRedirectionDelegate.awaitingRedirection(notification:)), name: Notification.Name(rawValue: "Redirection"), object: nil)
                
                let htmlText = try await Downloader.downloadData(url: url)
                
                if var lvs = YahooPageScraper.extractYahooPageData(html: htmlText, pageType: pageType, tableHeader: tableTitles[sectionCount], rowTitles: rowNames[sectionCount]) {
                    for i in 0..<lvs.count {
                        if lvs[i].label.contains("Sales growth") {
                            // convert from percent to double, extracting last row only
                            lvs[i].values = [lvs[i].values.compactMap{ $0 / 100 }.last!]
                        }
                    }
                    results.append(contentsOf: lvs)
                }
            }
            else {
                throw InternalError(location: #function, errorInfo: "invalid url for Yahoo WBV data download for  \(symbol)")
            }
                                    
            sectionCount += 1
        }
        
//        print()
//        for result in results {
//            print(result)
//        }
// Historical PE and EPS with dates
        var perAndEPSvalues: [Dated_EPS_PER_Values]?
//        if let components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(symbol)/\(sn)/pe-ratio") {
//            if let url = components.url {
//                perAndEPSvalues = try await getHxEPSandPEData(url: url, companyName: sn, until: nil, downloadRedirectDelegate: downloadRedirectDelegate)
//            }
//        }
            
// Historical stock prices
        var hxPriceValues: [Double]?

        let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc.automaticallyMergesChangesFromParent = true

        try await backgroundMoc.perform {

            do {

                if let wbv = backgroundMoc.object(with: valuationID) as? WBValuation {
                                                                
                    for result in results {
                        if result.label.lowercased().contains("revenue") {
                            wbv.revenue = result.values
                        }
                        else if result.label.lowercased().contains( "profit") {
                            wbv.grossProfit = result.values
                        }
                        else if result.label.lowercased().contains("research and development") {
                            wbv.rAndDexpense = result.values
                        }
                        else if result.label.lowercased().contains("selling") {
                            wbv.sgaExpense = result.values
                        }
                        else if result.label.lowercased().contains("net income") {
                            wbv.netEarnings = result.values
                        }
                        else if result.label.lowercased().contains("operating income") {
                            wbv.operatingIncome = result.values
                        }
                        else if result.label.lowercased().contains("eps") {
                            wbv.eps = result.values
                        }
                        else if result.label.lowercased().contains("debt") {
                            wbv.debtLT = result.values
                        }
                        else if result.label.lowercased() == "gross property, plant and equipment" {
                            wbv.ppe = result.values
                        }
                        else if result.label.lowercased() == "net property, plant and equipment" {
                            var capEx = [Double]()
                            for i in 0..<result.values.count-1 {
                                // assumes time DESCENDING values, as is the case on Yahoo financials pages
                                capEx.append(result.values[i] - result.values[i+1])
                            }
                            wbv.capExpend = capEx
                        }
                        else if result.label.lowercased().contains("retained") {
                            wbv.equityRepurchased = result.values
                        }
                        else if result.label.lowercased().contains("total stockholders") {
                            wbv.shareholdersEquity = result.values
                        }
                        else if result.label.lowercased().contains("operating") {
                            wbv.opCashFlow = result.values
                        }
                        //TODO: - find non-MT sources for Returns and BVPS
//                            case "ROE - Return On Equity":
//                                wbv.roe = result.values
//                            case "ROA - Return On Assets":
//                                wbv.roa = result.values
//                            case "Book Value Per Share":
//                                wbv.bvps = result.values
                        else {
                            ErrorController.addInternalError(errorLocation: "WebScraper2.downloadAndAnalyseWBVData", systemError: nil, errorInfo: "undefined download result with title \(result.label)")
                        }
                    }
                        
//                    wbv.latestDataDate = resultDates.max()
                    
                        if let validEPSPER = perAndEPSvalues {
                            let perDates: [DatedValue] = validEPSPER.compactMap{ DatedValue(date: $0.date, value: $0.peRatio) }
                            wbv.savePERWithDateArray(datesValuesArray: perDates, saveInContext: false)
                            let epsDates: [DatedValue] = validEPSPER.compactMap{ DatedValue(date: $0.date, value: $0.epsTTM) }
                            wbv.saveEPSTTMWithDateArray(datesValuesArray: epsDates, saveToMOC: false)
                        }
                        
                        wbv.avAnStockPrice = hxPriceValues?.reversed()
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
                try backgroundMoc.save()
            } catch let error {
                ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: error, errorInfo: "couldn't save background MOC")
            }
            
            
            if (downloadErrors ?? []).contains(InternalErrorType.generalDownloadError) {
                throw InternalErrorType.generalDownloadError
            }
        }
        
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
                    
        let rowTitles = ["Beta (5Y monthly)", "Trailing P/E", "Diluted EPS", "Forward annual dividend yield"] // titles differ from the ones displayed on webpage!
        
        var results = [LabelledValues]()
        
        for title in rowTitles {
            var labelledValues = LabelledValues(label: title, values: [Double]())
            if let values = WebPageScraper2.scrapeRowForDoubles(website: .yahoo, html$: htmlText, rowTitle: ">" + title+"</span>" , rowTerminal: "</tr>", numberTerminal: "</td>") {
                labelledValues.values = values
            }
            results.append(labelledValues)
        }
        
        let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc.automaticallyMergesChangesFromParent = true
        
        await backgroundMoc.perform {
            
            do {
                if let bgShare = backgroundMoc.object(with: shareID) as? Share {
                    
                    for result in results {
                                    
                        if result.label.starts(with: "Beta") {
                            bgShare.beta = result.values.first ?? Double()
                        } else if result.label.starts(with: "Trailing") {
                            bgShare.peRatio = result.values.first ?? Double()
                        } else if result.label.starts(with: "Diluted") {
                            bgShare.eps = result.values.first ?? Double()
                        } else if result.label == "Forward annual dividend yield" {
                            bgShare.divYieldCurrent = result.values.first ?? Double()
                        } else {
                            ErrorController.addInternalError(errorLocation: "WebScraper2.keyratioDownload", systemError: nil, errorInfo: "undefined download result with title \(result.label)")
                        }
                    }
                    
                }
                
                try backgroundMoc.save()
                
            } catch let error {
                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "couldn't save background MOC")
            }
        }
    }
    
    class func downloadAndAnalyseDailyTradingPrices(shareSymbol: String, minDate:Date?=nil) async throws -> [PricePoint]? {

// 2 data download usually for the last 3 momnths or so
        var urlComponents = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(shareSymbol)/history")
        urlComponents?.queryItems = [URLQueryItem(name: "p", value: shareSymbol)]
        
        
        guard let sourceURL = urlComponents?.url else {
            throw InternalError(location: "WebScraper2.downloadAndAnalyseDailyTradingPrices", errorInfo: "\(String(describing: urlComponents))", errorType: .urlInvalid)
        }
        
        let dataText = try await Downloader.downloadData(url: sourceURL)

        let downloadedPricePoints = YahooPageScraper.analyseYahooPriceTable(html$: dataText, limitDate: minDate)

        return downloadedPricePoints
    }
        
    //MARK: - general MacroTrend functions
    
    class func extractDatedValuesFromMTTable(htmlText: String, rowTitles: [String]) async throws -> [Labelled_DatedValues] {
        
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = NSLocale.current
            formatter.timeZone = NSTimeZone.local
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter
        }()

        guard let tableText = try extractMTTable2(htmlText: htmlText) else {
            throw InternalError(location: "WebScraper2.extractDatedValuesFromMTTable", errorInfo: "table text not extracted", errorType: .htmlTableTextNotExtracted)
        }
        
        var results = [Labelled_DatedValues]()
        for title in rowTitles {
            var labelledDV = Labelled_DatedValues(label: title, datedValues: [DatedValue]())
            if  let rowText = extractMTTableRowText(tableText: tableText, rowTitle: title) {
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
                    
                    datedValue = DatedValue(date: date, value: value)
                    labelledDV.datedValues.append(datedValue)
                }
            }
            results.append(labelledDV)
        }
        
        return results
        
    }
    
    class func extractMTTableRowText(tableText: String, rowTitle: String) -> String? {

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
    
    /// for MT "Financials' only pages with titled rows and dated values
    class func extractMTTable2(htmlText: String) throws -> String? {
        
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
    
    /// for MT pages such as 'PE-Ratio' with dated rows and table header, to assist 'extractTable' and 'extractTableData' func
    class func extractQEPSTableData(html: String, extractionCodes: WebpageExtractionCodes ,untilDate: Date?=nil) throws -> [DatedValue] {
        
        let bodyStartSequence = extractionCodes.bodyStartSequence
        let bodyEndSequence = extractionCodes.bodyEndSequence
        let rowEndSequence = extractionCodes.rowEndSequence
        
        var datedValues = [DatedValue]()
        
        let startSequence = extractionCodes.tableTitle ?? extractionCodes.tableStartSequence
        
        guard let tableStartIndex = html.range(of: startSequence) else {
            throw InternalError(location: #function, errorInfo: "did not find \(String(describing: startSequence)) in \(html)", errorType: .htmlTableTitleNotFound)
        }
        
        var tableText = String(html[tableStartIndex.upperBound..<html.endIndex])

        guard let bodyStartIndex = tableText.range(of: bodyStartSequence) else {
            throw InternalError(location: #function, errorInfo: "did not find \(String(describing: bodyStartSequence)) in \(tableText)", errorType: .htmlTableBodyStartIndexNotFound)
        }
        
        guard let bodyEndIndex = tableText.range(of: bodyEndSequence,options: [NSString.CompareOptions.literal], range: bodyStartIndex.upperBound..<tableText.endIndex, locale: nil) else {
            throw InternalError(location: #function, errorInfo: "did not find \(String(describing: bodyEndSequence)) in \(tableText)", errorType: .htmlTableBodyEndIndexNotFound)
        }
        
        
        tableText = String(tableText[bodyStartIndex.upperBound..<bodyEndIndex.lowerBound])
        var rowStartIndex = tableText.range(of: extractionCodes.rowStartSequence, options: [NSString.CompareOptions.literal])

        var columnCount = 0
        let columnsExpected = 2
        
        var date: Date?
        var epsValue: Double?

        outer: repeat {
            
            if let rsi = rowStartIndex {
                if let rowEndIndex = tableText.range(of: rowEndSequence, range: rsi.lowerBound..<tableText.endIndex) {
                    
                    var rowText = String(tableText[rsi.upperBound..<rowEndIndex.lowerBound])
                   
                    var valueStartIndex = rowText.range(of: extractionCodes.dataCellStartSequence)
                    inner: repeat {
//                        print("current rowText = \(rowText)")
                        if let vsi = valueStartIndex {
//                            print("found valueStart \(extractionCodes.dataCellStartSequence)")
                            if let valueEndIndex = rowText.range(of: extractionCodes.dataCellEndSequence, range: vsi.lowerBound..<rowText.endIndex) {

                                var value$ = String(rowText[vsi.upperBound..<valueEndIndex.lowerBound])
                                if let formatIndex = value$.range(of: "text-right") {
                                    value$ = String(value$[formatIndex.upperBound..<value$.endIndex])
                                }
//                                print(value$)

                                if columnCount%columnsExpected == 0 {
                                    let date$ = String(value$.dropFirst())
                                    date = extractionCodes.dateFormatter.date(from: date$)
//                                    print(date)
                                }
                                else if (columnCount+1)%columnsExpected == 0 { // EPS value
                                    epsValue = Double(value$.filter("-0123456789.".contains))
//                                    print(epsValue)
                                    if let validDate = date, let validValue = epsValue {
                                        let newDV = DatedValue(date: validDate, value: validValue)
                                        datedValues.append(newDV)
                                        if let minDate = untilDate {
                                            if minDate > validDate { return datedValues }
                                        }
                                    }
                                }
                                rowText = String(rowText[valueEndIndex.upperBound..<rowText.endIndex])
                            }
                            else {
                                ErrorController.addInternalError(errorLocation: #function, errorInfo: "missing valueEndIndex \(extractionCodes.dataCellEndSequence) for \(rowText)")
                                rowText = ""
                            }
                        }
                        valueStartIndex = rowText.range(of: extractionCodes.dataCellStartSequence)
                        columnCount += 1
                    } while valueStartIndex != nil
                        
                    tableText = String(tableText[rowEndIndex.lowerBound..<tableText.endIndex])
                    
                    rowStartIndex = tableText.range(of:extractionCodes.rowStartSequence)

                    }
                else {
                    rowStartIndex = nil
                } // no rowEndIndex
            }
            else {
                rowStartIndex = nil
            } // no rowStartIndex
//            columnCount += 1

            
        } while rowStartIndex != nil
        

        return datedValues
    }

    
    /// macrotrend data are time-DESCENDING from left to right,
    /// so the value arrays - scraped right-to-left  from eadh row - are returned in time_ASCENDING order
    class func macrotrendsRowExtraction(table$: String, rowTitle: String, exponent: Double?=nil, numberTerminal:String?=nil) -> [Double]? {
        
        var valueArray = [Double]()
        let lnumberTerminal = numberTerminal ??  "</div></div>"
        let numberStarter = ">"
        var tableText = table$
        
        var numberEndIndex = tableText.range(of: lnumberTerminal)

        while numberEndIndex != nil && tableText.count > 0 {
            
            if let numberStartIndex = tableText.range(of: numberStarter, options: .backwards, range: tableText.startIndex..<numberEndIndex!.lowerBound, locale: nil)  {
                
                let value$ = tableText[numberStartIndex.upperBound..<numberEndIndex!.lowerBound]

                if value$ == "-" { valueArray.append( 0.0) } // MT.ent hads '-' indicating nil/ 0
                else {
                    let value = String(value$).numberFromText(rowTitle: rowTitle,exponent: exponent)
//                    let value = numberFromText(value$: String(value$), rowTitle: rowTitle, exponent: exponent)
                    valueArray.append(value)
                }
            }
            else {
                return nil
            }
            
            tableText.removeSubrange(...numberEndIndex!.upperBound)
            numberEndIndex = tableText.range(of: lnumberTerminal)
        }
        
        return valueArray  // in time_DESCENDING order
    }
    
    class func macrotrendsScrapeColumn(html$: String?, tableHeader: String, tableTerminal: String? = nil, columnTerminal: String? = nil, noOfColumns:Int?=4, targetColumnFromRight: Int?=0) throws -> [Double]? {
        
        let tableHeader = tableHeader
        let tableTerminal =  tableTerminal ?? "</td>\n\t\t\t\t </tr></tbody>"
        let localColumnTerminal = columnTerminal ?? "</td>"
        let labelStart = ">"
        
        var pageText = String(html$ ?? "")
        
        guard let titleIndex = pageText.range(of: tableHeader) else {
            throw InternalError(location: #function, errorInfo: "did not find \(String(describing: tableHeader)) in \(pageText)", errorType: .htmlTableHeaderEndNotFound)
        }

        let tableEndIndex = pageText.range(of: tableTerminal,options: [NSString.CompareOptions.literal], range: titleIndex.upperBound..<pageText.endIndex, locale: nil)
        
        guard tableEndIndex != nil else {
            throw InternalError(location: #function, errorInfo: "did not find \(String(describing: tableTerminal)) in \(pageText)", errorType: .htmlTableEndNotFound)
        }
        
        pageText = String(pageText[titleIndex.upperBound..<tableEndIndex!.lowerBound])
        
        var rowEndIndex = pageText.range(of: localColumnTerminal, options: .backwards, range: nil, locale: nil)
        var valueArray = [Double]()
        var count = 0 // row has four values, we only want the last of those four
        
        repeat {
            let labelStartIndex = pageText.range(of: labelStart, options: .backwards, range: nil, locale: nil)
            let value$ = pageText[labelStartIndex!.upperBound...]
            
            if count%(noOfColumns ?? 4) == (targetColumnFromRight ?? 0) {
                valueArray.append(Double(value$.filter("-0123456789.".contains)) ?? Double())
            }

            rowEndIndex = pageText.range(of: localColumnTerminal, options: .backwards, range: nil, locale: nil)
            if rowEndIndex != nil {
                pageText.removeSubrange(rowEndIndex!.lowerBound...)
                count += 1
            }
        }  while rowEndIndex != nil
        
        return valueArray

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

    
    class func rule1DataExtraction(htmlText: String, section: String) -> [LabelledValues]? {
        
        guard htmlText != "" else {
            return nil
        }
        

        var results = [LabelledValues]()
// the first four sections are from MT pages
        if section == "financial-statements" {
            
            for title in ["Revenue","EPS - Earnings Per Share","Net Income"] {
                var labelledResults1 = LabelledValues(label: title, values: [Double]())
                
                if let values = WebPageScraper2.scrapeRowForDoubles(website: .macrotrends, html$: htmlText, sectionHeader: nil, rowTitle: ">" + title) {
                    labelledResults1.values = values
                    results.append(labelledResults1)
                }
            }
        }
        else if section == "financial-ratios" {
            
            for title in ["ROI - Return On Investment","Book Value Per Share","Operating Cash Flow Per Share"] {
                var labelledResults1 = LabelledValues(label: title, values: [Double]())
                if title.starts(with: "ROI") {
                    if let values = WebPageScraper2.scrapeRowForDoubles(website: .macrotrends, html$: htmlText, sectionHeader: nil, rowTitle: title) {
                        labelledResults1.values = values.compactMap{ $0 / 100 }
                    }
                }
                else {
                    if let values  = WebPageScraper2.scrapeRowForDoubles(website: .macrotrends, html$: htmlText, sectionHeader: nil, rowTitle: title) {
                        labelledResults1.values = values
                    }
                }
                results.append(labelledResults1)
            }
        }
        else if section == "balance-sheet" {
            var labelledResults1 = LabelledValues(label: "Long Term Debt", values: [Double]())
            if let values = WebPageScraper2.scrapeRowForDoubles(website: .macrotrends, html$: htmlText, sectionHeader: nil, rowTitle: "Long Term Debt") {
                let cleanedValues = values.filter({ (element) -> Bool in
                    return element != Double()
                })
                if let debt = cleanedValues.first {
                    labelledResults1.values = [Double(debt * 1000)]
                }
            }
            results.append(labelledResults1)
        }
        else if section == "pe-ratio" {
            var labelledResults1 = LabelledValues(label: "PE Ratio Historical Data", values: [Double]())
            if let values = WebPageScraper2.scrapeRowForDoubles(website: .macrotrends, html$: htmlText, sectionHeader: nil, rowTitle: "PE Ratio Historical Data</th>") {
                let pastPER = values.sorted()
                let withoutExtremes = pastPER.excludeQuintiles()
                labelledResults1.values = [withoutExtremes.min()!, withoutExtremes.max()!]
            }
            results.append(labelledResults1)
        }
        
// the following from Yahoo pages
        else if section == "analysis" {
            var labelledResults1 = LabelledValues(label: "Sales growth (year/est)", values: [Double]())

            if let values = WebPageScraper2.scrapeRowForDoubles(website: .yahoo, html$: htmlText, sectionHeader: "Revenue estimate</span>", rowTitle: "Sales growth (year/est)</span>") {
                let reverseValues = values.reversed()
                if let valid = reverseValues.last {
                    var growth = [valid]
                    let droppedLast = reverseValues.dropLast()
                    growth.append(droppedLast.last!)
                    labelledResults1.values = [growth.min()!, growth.max()!]
                }
            }
            results.append(labelledResults1)
        }
        else if section == "cash-flow" {

            var labelledResults1 = LabelledValues(label: "Operating cash flow", values: [Double]())

            if let values = WebPageScraper2.scrapeRowForDoubles(website: .yahoo, html$: htmlText, sectionHeader: "Cash flow</span>", rowTitle: "Operating cash flow</span>", rowTerminal: "</span></div></div><div") {
                labelledResults1.values = [values.last ?? Double()]
            }
            results.append(labelledResults1)
        }
        else if section == "insider-transactions" {
            
            for title in ["Purchases","Sales","Total insider shares held"] {
                
                var labelledResults1 = LabelledValues(label: title, values: [Double]())
                if let values = WebPageScraper2.scrapeRowForDoubles(website: .yahoo, html$: htmlText, sectionHeader: "Insider purchases - Last 6 months</span>", rowTitle: title+"</span>", rowTerminal: "</td></tr>", numberTerminal: "</td>") {
                    labelledResults1.values = [values.last ?? Double()]
                }
                results.append(labelledResults1)
            }
        }
        else if section == "key-statistics" {
            
            let title = "Forward P/E"
            var labelledValue = LabelledValues(label: title, values: [Double]())
            if let values = WebPageScraper2.scrapeRowForDoubles(website: .yahoo, html$: htmlText, rowTitle: ">" + title , rowTerminal: "</tr>", numberTerminal: "</td>", webpageExponent: nil) {
            
                labelledValue.values = [values.first ?? Double()]
            }
            results.append(labelledValue)

        }
        else if section == "financials" {
            
        }
        
        return results
    }
    
    /*
    class func checkAvailableOnMT(searchString: String) async throws -> Bool {
        
        let test = "AAPL"
//        var urlComponents = URLComponents(string: "https://www.macrotrends.net/stocks/research/\(searchString)")
        var urlComponents = URLComponents(string: "https://www.macrotrends.net/stocks/research")
//        urlComponents?.queryItems = [URLQueryItem(name: "p", value: searchString)]
        
        if let sourceURL = urlComponents?.url {
            Task.init(priority: .background) {
                do {
                    let webPage = try await Downloader.downloadData(url: sourceURL)
                    print("downloaded")
                } catch let error {
                    ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "failed web data download")
                }
            }

        }

        return false

    }
     */
    
    //MARK: - general Yahoo functions
    
    /// extracts entire table with header row elements and all row elements as strings; replaces any 'strong' = bold element with simple elements; returns only as many elements per row as there are column header titles; designed for Yahoo Dividend table
    class func getCompleteYahooWebTableContent(html: String?, tableTitle:String?=nil) throws -> [[String]]? {
        
        let tableStart = "<table"
        let tableEnd = "</table"
        
        let headerStart = "<thead"
        let headerEnd = "</thead"
        
        let bodyStart = "<tbody"
        let bodyEnd = "</tbody"
        
        let rowStart = "<tr"
//        let rowEnd = "</tr"
        
        let elementStart = "<span>"
        let elementEnd = "</span>"
        
        let altElementStart = "<strong>" // BOLD characters
        let altElementEnd = "</strong>"

        guard var pageText = html else {
            throw InternalError.init(location: #function, errorInfo: "empty yahoo web page expecting a table")
        }
        
        guard pageText != "" else {
            throw InternalError.init(location: #function, errorInfo: "empty yahoo web page expecting a table")
        }
        
        if let title = tableTitle {
            if let titleRange = pageText.range(of: title) {
                pageText = String(pageText[titleRange.upperBound..<pageText.endIndex])
            }
        }
        
        guard let tableStartRange = pageText.range(of: tableStart) else {
            throw InternalError.init(location: #function, errorInfo: "yahoo web page expecting a table, but table start sequence not found")
        }
        
        guard let tableEndRange = pageText.range(of: tableEnd, range: tableStartRange.upperBound..<pageText.endIndex) else {
            throw InternalError.init(location: #function, errorInfo: "yahoo web page expecting a table, but table end sequence not found")

        }
        
        guard let headerStartRange = pageText.range(of: headerStart, range: tableStartRange.upperBound..<pageText.endIndex) else {
            throw InternalError.init(location: #function, errorInfo: "yahoo web page expecting a table; no header start sequence found")
        }
        
        guard let headerEndRange = pageText.range(of: headerEnd, range: headerStartRange.upperBound..<pageText.endIndex) else {
            throw InternalError.init(location: #function, errorInfo: "yahoo web page expecting a table; no header end sequence found")
        }
        
        // define column header titlea
        var headerStrings = [String]()
        
        let headerRow = String(pageText[headerStartRange.upperBound..<headerEndRange.lowerBound])
        let headerElements = headerRow.components(separatedBy: elementStart)
        
        for element in headerElements {
            let row$ = String(element).replacingOccurrences(of: ">", with: "")
            let data = Data(row$.utf8)
            if let content$ = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil).string {
                if content$ != "" {
                    headerStrings.append(content$)
                }
            }
        }
        
        guard let bodyStartRange = pageText.range(of: bodyStart, range: headerEndRange.upperBound..<pageText.endIndex) else {
            throw InternalError.init(location: #function, errorInfo: "yahoo web page expecting a table; no body start sequence found")
        }
        
        guard let bodyEndRange = pageText.range(of: bodyEnd, range: bodyStartRange.upperBound..<pageText.endIndex) else {
            throw InternalError.init(location: #function, errorInfo: "yahoo web page expecting a table; no body end sequence found")
        }
        
        pageText = String(pageText[bodyStartRange.upperBound..<bodyEndRange.lowerBound])
        pageText = pageText.replacingOccurrences(of: altElementStart, with: elementStart)
        pageText = pageText.replacingOccurrences(of: altElementEnd, with: elementEnd)
        
        let bodyRows = pageText.components(separatedBy: rowStart)
        var tableContents = [[String]]()
        
        for var row in bodyRows {
            
            var rowContents = [String]()
            while row.count > 0 {

                var eStartRg = row.range(of: elementStart)
                
                if eStartRg == nil {
                    eStartRg = row.range(of: altElementStart)
                    guard eStartRg != nil else {
                        break
                    }
                }
                
                var eEndR = row.range(of: elementEnd,range: eStartRg!.upperBound..<row.endIndex)
                
                if eEndR == nil {
                    eEndR = row.range(of: altElementEnd,range: eStartRg!.upperBound..<row.endIndex)
                    guard eEndR != nil else {
                        break
                    }
                }
                
                let element = String(row[eStartRg!.upperBound..<eEndR!.lowerBound])
                if element != "" {
                    rowContents.append(element)
                }
                // only add as many elements as there are column/ header titles
                if rowContents.count == headerStrings.count {
                    break
                }
                
                row = String(row[eEndR!.upperBound..<row.endIndex])
            }
            if rowContents != [] {
                tableContents.append(rowContents)
            }
        }
        
        tableContents.insert(headerStrings, at: 0)
        return tableContents
    }
    
    class func dcfDataExtraction(htmlText: String, section: String) throws -> [LabelledValues] {
    
        guard htmlText != "" else {
            throw InternalError(location: #function, errorInfo: "empty web page found for \(section)", errorType: .emptyWebpageText)
        }
        
        let yahooPages = ["key-statistics", "financials", "balance-sheet", "cash-flow", "analysis"]
        var results = [LabelledValues]()

        if section == yahooPages.first! {
// Key stats,
            
            for rowTitle in ["Market cap (intra-day)</span>", "Beta (5Y monthly)</span>", "Shares outstanding</span>"] {
                var labelledValue = LabelledValues(label: rowTitle, values: [Double]())
                if let values = WebPageScraper2.scrapeRowForDoubles(website: .yahoo, html$: htmlText, rowTitle: ">" + rowTitle , rowTerminal: "</tr>", numberTerminal: "</td>", webpageExponent: 3.0) {
                
                    labelledValue.values = [values.first ?? Double()]
                }
                results.append(labelledValue)
            }
        }
        else if section == yahooPages[1] {
// Income
            for rowTitle in ["Total revenue</span>", "Net income</span>", "Interest expense</span>","Income before tax</span>","Income tax expense</span>"] {
                var labelledValue = LabelledValues(label: rowTitle, values: [Double]())
                
                if let values = WebPageScraper2.scrapeRowForDoubles(website: .yahoo, html$: htmlText, rowTitle: rowTitle, rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0) {

                    if rowTitle == "Interest expense</span>" {
                        labelledValue.values = [values.first ?? Double()]
                    } else if rowTitle == "Income before tax</span>"{
                        labelledValue.values = [values.first ?? Double()]
                    } else if rowTitle == "Income tax expense</span>" {
                        labelledValue.values = [values.first ?? Double()]
                    }
                    else {
                        labelledValue.values = values
                    }
                    }
                results.append(labelledValue)
            }
        }
        else if section == yahooPages[2] {
            let rowTitles = ["Current debt</span>","Long-term debt</span>", "Total Debt</span>"]
// Balance sheet
            
            for title in rowTitles {
                var labelledValue = LabelledValues(label: title, values: [Double]())
                if let values = WebPageScraper2.scrapeRowForDoubles(website: .yahoo,html$: htmlText, rowTitle: title, rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0) {
                    if (values.first ?? Double()) != Double() {
                        labelledValue.values = [values.first!]
                        results.append(labelledValue)
                        if title == "Long-term debt</span>" { break }
                    }
                }
            }
        }
        else if section == yahooPages[3] {
// Cash flow
            
            let rowTitles = ["Operating cash flow</span>","Capital expenditure</span>"]
            
            for title in rowTitles {
                var labelledValue = LabelledValues(label: title, values: [Double]())
                if let values = WebPageScraper2.scrapeRowForDoubles(website: .yahoo,html$: htmlText, rowTitle: title, rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0) {
                    labelledValue.values = values
                }
                results.append(labelledValue)
            }
            
        }
        else if section == yahooPages[4] {
// Analysis
            
            let rowTitles = ["Avg. Estimate</span>", "Sales growth (year/est)</span>"]
            
            for title in rowTitles {
                var labelledValue = LabelledValues(label: title, values: [Double]())
                if let values = WebPageScraper2.scrapeRowForDoubles(website: .yahoo,html$: htmlText, sectionHeader: "Revenue estimate</span>" ,rowTitle: title, rowTerminal: "</td></tr>", numberTerminal: "</td>" , webpageExponent: 3.0) {

                    let a1 = values.dropLast()
                    let a2 = a1.dropLast()
                    labelledValue.values = a2.reversed()
                }
                results.append(labelledValue)
            }
        }
        
        return results
    }
    
    /// webpageExponent = the exponent used by the webpage to listing financial figures, e.g. 'thousands' on yahoo = 3.0
    class func scrapeRowForDoubles(website: Website, html$: String?, sectionHeader: String?=nil, rowTitle: String, rowTerminal: String? = nil, numberStarter: String?=nil , numberTerminal: String? = nil, webpageExponent: Double?=nil) -> [Double]? {
        
        var pageText = html$
        let sectionTitle: String? = (sectionHeader != nil) ? (">" + sectionHeader!) : nil
        let rowDataStartDelimiter: String? = (website == .macrotrends) ? "class=\"fas fa-chart-bar\"></i></div></div></div><div role=" : nil
        let rowStart = website == .macrotrends ? ">" + rowTitle + "<" : rowTitle
        var rowTerminal2: String = rowTerminal ?? "</div></div></div>" // after ?? is fot MT only
        let tableTerminal = "</div></div></div></div>"

        guard pageText != nil else {
            return nil
        }
        

        if website == .yahoo {
            rowTerminal2 =  rowTerminal ?? "</span></td></tr>"
        }
// 1 Remove leading and trailing parts of the html code
// A Find section header
        if sectionTitle != nil {
            guard let sectionIndex = pageText?.range(of: sectionTitle!) else {
                return nil
            }
            pageText = String(pageText!.suffix(from: sectionIndex.upperBound))
        }
                        
// B Find beginning of row
        var rowStartIndex = pageText?.range(of: rowStart)
        guard rowStartIndex != nil else {
            return nil
        }
        
        if let validStarter = rowDataStartDelimiter {
            if let index = pageText?.range(of: validStarter, options: [NSString.CompareOptions.literal], range: rowStartIndex!.upperBound..<pageText!.endIndex, locale: nil) {
                rowStartIndex = index
            }
        }
        
// C Find end of row - or if last row end of table - and reduce pageText to this row
        if let rowEndIndex = pageText?.range(of: rowTerminal2,options: [NSString.CompareOptions.literal], range: rowStartIndex!.upperBound..<pageText!.endIndex, locale: nil) {
                pageText = String(pageText![rowStartIndex!.upperBound..<rowEndIndex.upperBound])
        } else if let tableEndIndex = pageText?.range(of: "}]",options: [NSString.CompareOptions.literal], range: rowStartIndex!.upperBound..<pageText!.endIndex, locale: nil) {
                pageText = String(pageText![rowStartIndex!.upperBound..<tableEndIndex.upperBound])
        } else if let tableEndIndex = pageText?.range(of: tableTerminal,options: [NSString.CompareOptions.literal], range: rowStartIndex!.upperBound..<pageText!.endIndex, locale: nil) {
                pageText = String(pageText![rowStartIndex!.upperBound..<tableEndIndex.upperBound])
        }
        else {
            return nil
        }
        
        if website == .macrotrends {
            
            
            let values = macrotrendsRowExtraction(table$: pageText ?? "", rowTitle: rowTitle, exponent: webpageExponent)
            return values // MT.com rows are time_DESCENDING from left to right, so the valueArray is in time-ASCENDING order deu to backwards row scraping.
        }
        else {
            let values = YahooPageScraper.yahooRowNumbersExtraction(table$: pageText ?? "", rowTitle: rowTitle, numberStarter: numberStarter, numberTerminal: numberTerminal, exponent: webpageExponent)
                return values
        }
    }
    
    /*
    class func scrapeYahooRowForDoubles(html$: String?, rowTitle: String, rowTerminal: String? = nil, numberTerminal: String? = nil) -> [Double]? {
        
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

        let values = YahooPageScraper.yahooRowNumbersExtraction(table$: pageText ?? "", rowTitle: rowTitle, numberTerminal: numberTerminal)
        return values
    }
    */
    /*
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
        return Double(numbersOnly ?? "")
    }
     */

    /*
    /// expect one table row of html text
    class func yahooRowNumbersExtraction(table$: String, rowTitle: String, numberStarter: String?=nil, numberTerminal: String?=nil, exponent: Double?=nil) -> [Double]? {
        
        var valueArray = [Double]()
        let numberTerminal = numberTerminal ?? "</span>"
        let numberStarter = numberStarter ?? ">"
        var tableText = table$
        
        var labelEndIndex = tableText.range(of: numberTerminal, options: .backwards, range: nil, locale: nil)
        if let index = labelEndIndex {
            tableText.removeSubrange(index.lowerBound...)
        }
        
        guard labelEndIndex != nil else { return nil }

        repeat {
            guard let labelStartIndex = tableText.range(of: numberStarter, options: .backwards, range: tableText.startIndex..<labelEndIndex!.lowerBound, locale: nil) else {
                return nil
            }
            
            let value$ = tableText[labelStartIndex.upperBound...]
            let value = numberFromText(value$: String(value$), rowTitle: rowTitle, exponent: exponent)
            valueArray.append(value)
            
            
            labelEndIndex = tableText.range(of: numberTerminal, options: .backwards, range: tableText.startIndex..<labelEndIndex!.lowerBound, locale: nil)
            if let index = labelEndIndex {
                tableText.removeSubrange(index.lowerBound...)
            }

        } while labelEndIndex != nil && (tableText.count > 1)

        return valueArray
    }
    */
    /*
    class func scrapeRowForText(html$: String?, sectionHeader: String?=nil, sectionTerminal: String?=nil, rowTitle: String, rowTerminal: String? = nil, textTerminal: String? = nil, webpageExponent: Double?=nil) throws -> [String] {
        
        guard var pageText = html$ else {
            throw InternalError(location: #function, errorInfo: "empty web page", errorType: .emptyWebpageText)
        }
        
        let sectionTitle: String? = (sectionHeader != nil) ? (">" + sectionHeader!) : nil
        let rowStart = rowTitle
        let rowTerminal = (rowTerminal ?? ",")
        let tableTerminal = sectionTerminal ?? "</p>"

        
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
        if let rowEndIndex = pageText.range(of: rowTerminal, range: rowStartIndex.upperBound..<pageText.endIndex) {
            pageText = String(pageText[rowStartIndex.upperBound..<rowEndIndex.lowerBound])
        } else if let tableEndIndex = pageText.range(of: tableTerminal, range: rowStartIndex.upperBound..<pageText.endIndex) {
            pageText = String(pageText[rowStartIndex.upperBound..<tableEndIndex.lowerBound])
        }
        else {
            throw InternalError(location: #function, errorInfo: "did not find \(String(describing: rowTerminal)) in \(String(describing: pageText))", errorType: .htmlRowEndIndexNotFound)
        }
        
        let textArray = try yahooRowStringExtraction(table$: pageText, rowTitle: rowTitle, textTerminal: textTerminal)
        return textArray
    }
    */
    /*
    class func getTextBlock(html$: String?, sectionHeader: String?=nil, sectionTerminal: String?=nil, rowTitle: String, rowTerminal: String? = nil, textTerminal: String? = nil, webpageExponent: Double?=nil) throws -> String {
        
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
    }
     */
    /*
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
    */
    /*
    /// providing a limit date stops the analysis after encountering that date. Providing a specific date looks for pricepoint data closest to that date only. Don't send both limit AND specific dates
    class func analyseYahooPriceTable(html$: String, limitDate: Date?=nil, specificDate:Date?=nil) -> [PricePoint]? {
        
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
    */
    
    /*
    // returns double values without multiplication by 1000 from Yahoo pages; treat 0.0 as nil
    class func yahooFinancialsExtraction(html: String, tableHeader: String, rowTitles: [String], altRowTitles:[String]?=nil) -> [LabelledValues]? {
        
        let header = "<span>" + tableHeader + "</span>"
        var rowStarts = [String]()
        var rowEnd = "fin-row" // last row in table does not have this, ends with tableEnd
        var columnStart = "fin-col"
        var dataStart = "<span>"
        var dataEnd = "</span>"
        let tableEnd = "</div></div><div></div></div></div></div></div>"
        let altTableEnd = "</tr></tbody></table>"
        
        guard let headerPosition = html.range(of: header) else {
            return nil
        }
        
        var tableText = String()
        
        // two different page formats for Yahoo pages
        if let tableEndPosition = html.range(of: tableEnd, range: headerPosition.upperBound..<html.endIndex) {
            tableText = String(html[headerPosition.upperBound...tableEndPosition.upperBound])
            for title in rowTitles {
                rowStarts.append(">" + title + "</span>") // </span></div>
            }
        } else if let altTableEndPosition = html.range(of: altTableEnd, range: headerPosition.upperBound..<html.endIndex) {
            tableText = String(html[headerPosition.upperBound...altTableEndPosition.upperBound])
            columnStart = "Py(10px)" //"Py(10px)\\"
            dataStart = ">"
            dataEnd = "</td>"
            for _ in rowTitles {
                rowStarts.append("Ta(start)")
            }
            rowEnd = "Ta(end)"
        }
        
        guard tableText != "" else {
            return nil
        }
        
        let testRowStartPosition = tableText.range(of: rowStarts[0])
        if testRowStartPosition == nil {
            // third variant of Yahoo page!
            rowStarts = [String]()
            for _ in rowTitles {
                rowStarts.append("fi-row")
            }
        }
        
        var labelledValues = [LabelledValues]()
        var count = 0
        for rStart in rowStarts {
            
            var rowValues = [Double]()
            guard let rowStartPosition = tableText.range(of: rStart) else {
                labelledValues.append(LabelledValues(label: rowTitles[count], values: rowValues))
                continue
            }
            
            var rowText = String()
            
            if let rowEndPosition = tableText.range(of: rowEnd ,range: rowStartPosition.upperBound..<tableText.endIndex) {
                rowText = String(tableText[rowStartPosition.upperBound..<rowEndPosition.lowerBound])

            } else if let rowEndPosition = tableText.range(of: tableEnd ,range: rowStartPosition.upperBound..<tableText.endIndex) {
                rowText = String(tableText[rowStartPosition.upperBound..<rowEndPosition.lowerBound])
            } else {
                labelledValues.append(LabelledValues(label: rowTitles[count], values: rowValues))
                continue
            }
            
            let columnTexts = rowText.split(separator: columnStart).dropFirst()
            for ct in columnTexts {
                let dataStartPosition = ct.range(of: dataStart) ?? ct.range(of: ">")
                
                guard dataStartPosition != nil else {
                    rowValues.append(0.0)
                    continue
                }
                
                if let dataEndPosition = ct.range(of: dataEnd, range: dataStartPosition!.upperBound..<ct.endIndex)  {
                    let content$ = ct[dataStartPosition!.upperBound..<dataEndPosition.lowerBound].filter("-0123456789.".contains)
                    rowValues.append((Double(content$) ?? 0.0))
                } else if let dataEndPosition = ct.range(of: "</div>", range: dataStartPosition!.upperBound..<ct.endIndex)  {
                    let content$ = ct[dataStartPosition!.upperBound..<dataEndPosition.lowerBound].filter("-0123456789.".contains)
                    rowValues.append((Double(content$) ?? 0.0))
                }
                else {
                    rowValues.append(0.0)
                    continue
                }
            }
            
            let title = (altRowTitles ?? rowTitles)[count]
            labelledValues.append(LabelledValues(label: title, values: rowValues))
            
            
            count += 1
        }
        
        return labelledValues
        
    }
    */
    /*
    class func companyNameSearchOnPage(html: String) throws -> [String: String]? {
        
        var pageText = html
        let sectionStart = "<span>Exchange"
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
     */
    // MARK: - YCharts functions
    
    
    /// returns quarterly eps  with dates from YCharts website
    /// in form of [DatedValues] = (date, eps )
    /// ; optional parameter 'date' returns values back to this date and the first set before.
    /// ; throws downlad and analysis errors, which need to be caught by cailler
    class func getqEPSDataFromYCharts(url: URL, companyName: String, until date: Date?=nil, downloadRedirectDelegate: DownloadRedirectionDelegate) async throws -> [DatedValue]? {
        
            var htmlText:String?
            var datedValues = [DatedValue]()
            let downloader = Downloader(task: .qEPS)
        
            do {
                // to catch any redirections
                NotificationCenter.default.addObserver(downloadRedirectDelegate, selector: #selector(DownloadRedirectionDelegate.awaitingRedirection(notification:)), name: Notification.Name(rawValue: "Redirection"), object: nil)
                
                htmlText = try await downloader.downloadDataWithRedirection(url: url)
//                print("marketwatch html for \(companyName) is:\n\(htmlText)")
            } catch {
                throw error
            }
        
            guard let validPageText = htmlText else {
                throw InternalError(location: #function, errorInfo: "html text = nil for url \(url)", errorType: .generalDownloadError)
            }
                
            do {

                let codes = WebpageExtractionCodes(tableTitle: "Historical EPS Diluted (Quarterly) Data", option: .yCharts, dataCellStartSequence: "<td") // "\">"
                datedValues = try extractQEPSTableData(html: validPageText, extractionCodes: codes, untilDate: date)
                return datedValues
            } catch let error {
                throw InternalError(location: #function, systemError: error as NSError, errorInfo: "failed hist q EPS extraction \(url)", errorType: .generalDownloadError)
            }

    }

    
    /*
    class func numberFromText(value$: String, rowTitle: String, exponent: Double?=nil) -> Double {
        
        var value = Double()
        
        if value$.filter("-0123456789.".contains) != "" {
            if let v = Double(value$.filter("-0123456789.".contains)) {
              
                if value$.last == "%" {
                    value = v / 100.0
                }
                else if value$.uppercased().last == "T" {
                    value = v * pow(10.0, 12) // should be 12 but values are entered as '000
                } else if value$.uppercased().last == "B" {
                    value = v * pow(10.0, 9) // should be 9 but values are entered as '000
                }
                else if value$.uppercased().last == "M" {
                    value = v * pow(10.0, 6) // should be 6 but values are entered as '000
                }
                else if value$.uppercased().last == "K" {
                    value = v * pow(10.0, 3) // should be 6 but values are entered as '000
                }
                else if rowTitle.contains("Beta") {
                    value = v
                }
                else {
                    value = v * (pow(10.0, exponent ?? 0.0))
                }
                
                if value$.last == ")" {
                    value = v * -1
                }
            }
        }
        
        return value
    }
    */

}
