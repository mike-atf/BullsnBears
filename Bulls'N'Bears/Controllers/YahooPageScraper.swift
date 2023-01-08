//
//  YahooPageScraper.swift
//  Bulls'N'Bears
//
//  Created by aDav on 05/01/2023.
//

import Foundation

enum YahooPageType {
    case financials
    case balance_sheet
    case cash_flow
    case insider_transactions
    case analysis
    case key_statistics
}

struct YahooPageDelimiters {
    
    var tableStart:String?
    var tableEnd = String()
    var rowStart = [String]()
    /// rowEnd may not be found in last row, so check for tableEnd if not found
    var rowEnd = String()
    var columnStart = String()
    var dataStart = String()
    var dataEnd = String()
    
    init(pageType: YahooPageType, tableHeader: String?, rowTitles: [String]) {
        
        if tableHeader != nil {
            tableStart = "<span>" + tableHeader! + "</span>"
        }
        for title in rowTitles {
            rowStart.append(title + "</span>") //"<span>" +
        }

        switch pageType {
        case .financials:
            rowEnd = "fin-row"
            columnStart = "fin-col"
            dataStart = "<span>"
            dataEnd = "</span>"
            tableEnd = "</div></div><div></div></div></div></div></div>"
        case .balance_sheet:
            rowEnd = "fin-row"
            columnStart = "fin-col"
            dataStart = "<span>"
            dataEnd = "</span>"
            tableEnd = "</div></div><div></div></div></div></div></div>"
        case .cash_flow:
            rowEnd = "fin-row"
            columnStart = "fin-col"
            dataStart = "<span>"
            dataEnd = "</span>"
            tableEnd = "</div></div><div></div></div></div></div></div>"
        case .analysis:
            rowEnd = "</tr>"
            columnStart = "Ta(end)"
            dataStart = ">"
            dataEnd = "</td>"
            tableEnd = "</tbody></table>"
        case .key_statistics:
            rowEnd = "</tr>"
            columnStart = "Pstart"
            dataStart = ">"
            dataEnd = "</td>"
            tableEnd = "</tbody></table>"
        case .insider_transactions:
            rowEnd = "</tr>"
            columnStart = "Py(10px)"
            dataStart = ">"
            dataEnd = "</td>"
            tableEnd = "</tbody></table>"
        }
    }
    
}

class YahooPageScraper {
    
    
    /// missing arrays for BVPS, ROI, OPCF/s and PE Hx
    class func r1DataFromYahoo(symbol: String, progressDelegate: ProgressViewDelegate?=nil, avoidMTTitles: Bool?=nil ,downloadRedirectDelegate: DownloadRedirectionDelegate?) async throws -> [LabelledValues]? {
        
        var results = [LabelledValues]()
        
        let pageNames = (avoidMTTitles ?? false) ? ["balance-sheet","insider-transactions", "analysis", "key-statistics"] : ["financials","balance-sheet","cash-flow", "insider-transactions", "analysis", "key-statistics"]

        let tableTitles = (avoidMTTitles ?? false) ? ["Balance sheet", "Insider purchases - Last 6 months", "Revenue estimate", "Valuation measures"] : ["Income statement", "Balance sheet", "Cash flow", "Insider purchases - Last 6 months", "Revenue estimate", "Valuation measures"]

        let rowTitles = (avoidMTTitles ?? false) ? [["Common stock"],["Total insider shares held", "Purchases", "Sales"], ["Sales growth (year/est)"],["Forward P/E"]] : [["Total revenue","Basic EPS","Net income"], ["Total non-current liabilities", "Common stock"],["Net cash provided by operating activities"],["Total insider shares held", "Purchases", "Sales"], ["Sales growth (year/est)"],["Forward P/E"]]
        
        let saveTitles = (avoidMTTitles ?? false) ? [["Common stock"],["Total insider shares held", "Purchases", "Sales"],["Sales growth (year/est)"],["Forward P/E"]] : [["Revenue","EPS - Earnings Per Share", "Net Income"], ["Long Term Debt", "Common stock"],["Operating cash flow"],["Total insider shares held", "Purchases", "Sales"],["Sales growth (year/est)"],["Forward P/E"]]
        

        var count = 0
        for pageName in pageNames {
            
//            var type: YahooPageType!
//            if pageName.contains("balance") {
//                type = .balance_sheet
//            } else if pageName.contains("insider") {
//                type = .insider_transactions
//            } else if pageName.contains("financials") {
//                type = .financials
//            } else if pageName.contains("analysis") {
//                type = .analysis
//            } else if pageName.contains("cash") {
//                type = .cash_flow
//            } else if pageName.contains("statistics") {
//                type = .key_statistics
//            }
            
            var components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)/\(pageName)")
            components?.queryItems = [URLQueryItem(name: "p", value: symbol)]
            
            guard let url = components?.url else {
                progressDelegate?.downloadError(error: InternalErrorType.urlInvalid.localizedDescription)
                continue
            }

            var type = getYahooPageType(url: url)

            var htmlText = String()

            do {
                htmlText = try await Downloader.downloadData(url: url)
            } catch let error as InternalErrorType {
                progressDelegate?.downloadError(error: error.localizedDescription)
                continue
            }


            if var labelledResults = extractYahooPageData(html: htmlText, pageType: type, tableHeader: tableTitles[count], rowTitles: rowTitles[count],replacementRowTitles: saveTitles[count] ){
                
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

    
    /// using yahoo as source
    class func downloadHxDividendsFile(symbol: String, companyName: String, years: TimeInterval) async throws -> [DatedValue]? {
        
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
            throw InternalError(location: #function, errorInfo: "invalid url for downloading yahoo Hx dividend .csv file")
        }
        
        let expectedHeaderColumnTitles = ["Date", "Dividends"]

        guard let csvFileURL = try await Downloader.downloadCSVFile2(url: url, symbol: symbol, type: "_Div") else {
            throw InternalError(location: #function, errorInfo: "Failed Dividend CSV File download from Yahoo for \(symbol)")
        }

        var iterator = csvFileURL.lines.makeAsyncIterator()
        
        if let headerRow = try await iterator.next() {
            let titles: [String] = headerRow.components(separatedBy: ",")
            if !(titles == expectedHeaderColumnTitles) {
                throw InternalError(location: #function, errorInfo: "Dividend CSV File downloadwd from Yahoo for \(symbol) does not have expected header row titles \(headerRow)")
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

        return nil
    }
    
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
    
    /// returns ALL column values; filerting needs to happen if not all columns are wanted; if no tableHeader provided searches the enire web page for the rowTitles
    class func extractYahooPageData(html: String?, pageType: YahooPageType, tableHeader: String?, rowTitles:[String], replacementRowTitles:[String]?=nil) -> [LabelledValues]? {
        
        guard let pageText = html else {
            return nil
        }
                
        let delimiters = YahooPageDelimiters(pageType: pageType, tableHeader: tableHeader, rowTitles: rowTitles)
                
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
        
        var labelledValues = [LabelledValues]()
        var i = 0
        for rStart in delimiters.rowStart {
            
            var rowValues = [Double]()
            guard let rowStartPosition = tableText.range(of: rStart) else {
                labelledValues.append(LabelledValues(label:  replacementRowTitles?[i] ?? rowTitles[i], values: rowValues))
                continue
            }
            
            var rowText = String()
            
            if let rowEndPosition = tableText.range(of: delimiters.rowEnd ,range: rowStartPosition.upperBound..<tableText.endIndex) {
                rowText = String(tableText[rowStartPosition.upperBound..<rowEndPosition.lowerBound])

            } else if let rowEndPosition = tableText.range(of: delimiters.tableEnd ,range: rowStartPosition.upperBound..<tableText.endIndex) {
                rowText = String(tableText[rowStartPosition.upperBound..<rowEndPosition.lowerBound])
            } else {
                labelledValues.append(LabelledValues(label: replacementRowTitles?[i] ?? rowTitles[i], values: rowValues))
                continue
            }
            
            let columnTexts = rowText.split(separator: delimiters.columnStart).dropFirst()
            for ct in columnTexts {
                let dataStartPosition = ct.range(of: delimiters.dataStart) ?? ct.range(of: ">")
                
                guard dataStartPosition != nil else {
                    rowValues.append(0.0)
                    continue
                }
                
                var modifier = 1.0
                
                if let dataEndPosition = ct.range(of: delimiters.dataEnd, range: dataStartPosition!.upperBound..<ct.endIndex)  {
                    var content$ = ct[dataStartPosition!.upperBound..<dataEndPosition.lowerBound].filter("-0123456789.TBMk".contains)
                    if content$ != "" {
                        if content$.capitalized.last! == "M" {
                            modifier = 1_000_000.0
                            content$.removeLast()
                        }
                        else if content$.capitalized.last! == "K" {
                            modifier = 1_000.0
                            content$.removeLast()
                        }
                        else if content$.capitalized.last! == "B" {
                            modifier = 1_000_000_000.0
                            content$.removeLast()
                        }
                        else if content$.capitalized.last! == "T" {
                            modifier = 1_000_000_000_000.0
                            content$.removeLast()
                        }
                        rowValues.append((Double(content$) ?? 0.0) * modifier)
                    }
                } else if let dataEndPosition = ct.range(of: "</div>", range: dataStartPosition!.upperBound..<ct.endIndex)  {
                    var content$ = ct[dataStartPosition!.upperBound..<dataEndPosition.lowerBound].filter("-0123456789.Mk".contains)
                    if content$ != "" {
                        if content$.capitalized.last! == "M" {
                            modifier = 1_000_000.0
                            content$.removeLast()
                        } else if content$.capitalized.last! == "K" {
                            modifier = 1_000.0
                            content$.removeLast()
                        }
                        else if content$.capitalized.last! == "B" {
                            modifier = 1_000_000_000.0
                            content$.removeLast()
                        }
                        else if content$.capitalized.last! == "T" {
                            modifier = 1_000_000_000_000.0
                            content$.removeLast()
                        }
                        rowValues.append((Double(content$) ?? 0.0) * modifier)
                    }
                }
                else {
                    rowValues.append(0.0)
                    continue
                }
            }
            
            labelledValues.append(LabelledValues(label: replacementRowTitles?[i] ?? rowTitles[i], values: rowValues))
            
            i += 1
            
        }
        
        return labelledValues
    }
    
    class func getYahooPageType(url: URL) -> YahooPageType {
        
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
        } else {
            type = .key_statistics
        }

        return type
    }
        
    /// expect one table row of html text; called from WebScraper 2
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
            let value = String(value$).numberFromText(rowTitle: rowTitle,exponent: exponent)

//            let value = WebPageScraper2.numberFromText(value$: String(value$), rowTitle: rowTitle, exponent: exponent)
            valueArray.append(value)
            
            
            labelEndIndex = tableText.range(of: numberTerminal, options: .backwards, range: tableText.startIndex..<labelEndIndex!.lowerBound, locale: nil)
            if let index = labelEndIndex {
                tableText.removeSubrange(index.lowerBound...)
            }

        } while labelEndIndex != nil && (tableText.count > 1)

        return valueArray
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
    

    /*
    class func downloadAndAnalyseHxDividendsPage(symbol: String, years: TimeInterval, delegate: CSVFileDownloadDelegate) async throws {
        
        let nowSinceRefDate = Date().timeIntervalSince(yahooRefDate)
        let tenYearsAgoSinceRefDate = Date().addingTimeInterval(-years*year).timeIntervalSince(yahooRefDate)

        let start$ = numberFormatter.string(from: nowSinceRefDate as NSNumber) ?? ""
        let end$ = numberFormatter.string(from: tenYearsAgoSinceRefDate as NSNumber) ?? ""
        
        var urlComponents = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)/history")

        urlComponents?.queryItems = [
            URLQueryItem(name: "period1", value: end$),
            URLQueryItem(name: "period2", value: start$),
            URLQueryItem(name: "interval", value: "capitalGain|div|split"),
            URLQueryItem(name: "filter", value: "div"),
            URLQueryItem(name: "frequency", value: "1d"),
            URLQueryItem(name: "includeAdjustedClose", value: "true") ]
        
        
        var dividendWDates: [DatedValue]?
        
        guard let url = urlComponents?.url else {
            throw InternalError(location: #function, errorInfo: "invalid url for downloading yahoo Hx dividend data")
        }
        
        do {
            let html = try await Downloader.downloadData(url: url)
            
            if let tableContent = try getCompleteYahooWebTableContent(html: html, tableTitle: nil) {
                
                let dateFormatter: DateFormatter = {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "dd MMM yyyy"
                    formatter.calendar.timeZone = TimeZone(identifier: "UTC")!
                    return formatter
                }()
                
                var divDates = [DatedValue]()
                for row in tableContent {
                    if let dV = extractDatedValueFromStrings(rowElements: row, formatter: dateFormatter) {
                        divDates.append(dV)
                    }
                }
                dividendWDates = divDates
            }
            
        } catch {
            throw InternalError(location: #function, systemError: error)
        }

        delegate.dataDownloadCompleted(results: dividendWDates)

    }
    */
}
