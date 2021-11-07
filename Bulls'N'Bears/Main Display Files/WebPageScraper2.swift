//
//  WebPageScraper2.swift
//  Bulls'N'Bears
//
//  Created by aDav on 04/11/2021.
//

import Foundation

class WebPageScraper2 {
    
    //MARK: - specific task functions
    
    /// returns historical pe ratios and eps TTM with dates from macro trends website
    /// in form of [DatedValues] = (date, epsTTM, peRatio )
    /// ; optional parameter 'date' returns values back to this date and the first set before.
    /// ; throws downlad and analysis errors, which need to be caught by cailler
    class func getHxEPSandPEData(url: URL, companyName: String, until date: Date?=nil) async throws -> [Dated_EPS_PER_Values]? {
        
            var htmlText = String()
            var tableText = String()
            var tableHeaderTexts = [String]()
            var datedValues = [Dated_EPS_PER_Values]()
            let title = companyName.capitalized(with: .current)
        
            do {
                htmlText = try await Downloader.downloadData(url: url)
            } catch let error as DownloadAndAnalysisError {
                throw error
//                if error == .mimeType {
//                    print("response mime type is not html; can't decode")
//                    throw DownloadAndAnalysisError.mimeType
//                } else if error == .urlError {
//                    print("a url error occurred")
//                    throw DownloadAndAnalysisError.urlError
//                }
            }
                
            do {
                tableText = try await extractTable(title:"\(title) PE Ratio Historical Data", html: htmlText)
            } catch let error as DownloadAndAnalysisError {
                throw error
//                if error == .htmlTableHeaderEndNotFound {
//                    print("html analysis error: table end not found")
//                } else if error == .htmlTableTitleNotFound {
//                    print("html analysis error: title not found")
//                }
            }

            do {
                tableHeaderTexts = try await extractHeaderTitles(html: tableText)
            } catch let error as DownloadAndAnalysisError {
                throw error
//                if error == .htmlTableRowStartIndexNotFound {
//                    print("html analysis error: header start not found")
//                } else if error == .htmlTableHeaderEndNotFound {
//                    print("html analysis error: header end not found")
//                } else if error == .htmlTableRowEndNotFound {
//                    print("html analysis error: row end not found")
//                }
            }
            
            if tableHeaderTexts.count > 0 && tableHeaderTexts.contains("Date") {
                do {
                    datedValues = try extractTableData(html: htmlText, titles: tableHeaderTexts, untilDate: date)
                    return datedValues
                } catch let error as DownloadAndAnalysisError {
                   throw error
                }
            } else {
                print("did not find any table header titles, or missing date Column- over & out")
                throw DownloadAndAnalysisError.htmTablelHeaderStartNotFound
            }

    }
    
    class func getCurrentPrice(url: URL) async throws -> Double? {
        
        var htmlText = String()

        do {
            htmlText = try await Downloader.downloadData(url: url)
            let values = try scrapeRowForDoubles(website: .yahoo, html$: htmlText, rowTitle: "<span class=\"Trsdu(0.3s) Trsdu(0.3s) " , rowTerminal: "</span>", numberTerminal: "</span>")
            return values.first
        } catch let error as DownloadAndAnalysisError {
            throw error
        }

    }
    
    class func downloadAndAnalyseProfile(url: URL) async throws -> ProfileData? {
        
        var htmlText = String()

        do {
            htmlText = try await Downloader.downloadData(url: url)
        } catch let error as DownloadAndAnalysisError {
            throw error
        }

        
        let rowTitles = ["\"sector\":", "\"industry\":", "\"fullTimeEmployees\""] // titles differ from the ones displayed on webpage!
        
        var sector = String()
        var industry = String()
        var employees = Double()
        
        for title in rowTitles {
            
            let pageText = htmlText
            
            
            if title.starts(with: "\"sector") {
                let strings = try scrapeRowForText(html$: pageText, rowTitle: title , rowTerminal: ",", textTerminal: "\"")

                if let valid = strings.first {
                        sector = valid
                }
            } else if title.starts(with: "\"industry") {
                let strings = try scrapeRowForText(html$: pageText, rowTitle: title , rowTerminal: ",", textTerminal: "\"")

                
                if let valid = strings.first {
                        industry = valid
                }
            } else if title.starts(with: "\"fullTimeEmployees") {
                let values = try scrapeYahooRowForDoubles(html$: pageText, rowTitle: title , rowTerminal: "\"", numberTerminal: ",")
                
                if let valid = values.first {
                        employees = valid
                }
            }
        }
        
        return ProfileData(sector: sector, industry: industry, employees: employees)
                
    }
    
    /// returns (priceDate, errors) in time-DESCENDING order
    class func downloadAndAanalyseTreasuryYields(url: URL) async throws -> [PriceDate]? {
        
        var htmlText = String()

        do {
            htmlText = try await Downloader.downloadData(url: url)
        } catch let error as DownloadAndAnalysisError {
            throw error
        }
        
        var priceDates = [PriceDate]()
        
        let tableEnd = "</td></tr></table>\r\n<div class=\"updated\""
        let columnStart = "</td><td class=\"text_view_data\">"
        let rowStart = "<td scope=\"row\" class=\"text_view_data\">"
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = NSLocale.current
            formatter.timeZone = NSTimeZone.local
            formatter.dateFormat = "MM/dd/yy"
            return formatter
        }()

        guard let tableStartIndex = htmlText.range(of: rowStart) else {
            throw DownloadAndAnalysisError.htmlTableRowStartIndexNotFound
        }
        
        htmlText = String(htmlText.suffix(from: tableStartIndex.lowerBound))
        
        guard let tableEndIndex = htmlText.range(of: tableEnd) else {
            throw DownloadAndAnalysisError.htmlTableEndNotFound
        }
        
        htmlText = String(htmlText.prefix(through: tableEndIndex.upperBound))
        
        var rows = [String]()
        var rowStartIndex = htmlText.range(of: rowStart, options: .backwards)
        guard rowStartIndex != nil else {
            throw DownloadAndAnalysisError.htmlTableRowStartIndexNotFound
        }
        
        repeat {
            let row$ = String(htmlText[rowStartIndex!.upperBound...])
            rows.append(row$)
            htmlText.removeSubrange(rowStartIndex!.lowerBound...)
            rowStartIndex = htmlText.range(of: rowStart, options: .backwards)
        } while rowStartIndex != nil
        
        for i in 0..<rows.count {
            var row = rows[i]

            for _ in 0..<2 {
                if let columStartIndex = row.range(of: columnStart, options: .backwards) {
                    row.removeSubrange(columStartIndex.lowerBound...)
                }
            }
            
            var value: Double?
            var date: Date?
            if let columStartIndex = row.range(of: columnStart, options: .backwards) {
                let value$ = row[columStartIndex.upperBound...]
                value = Double(value$.filter("-0123456789.".contains))
            }
            if let endOfDateIndex = row.range(of: "</td><td ") {
                let date$ = String(String(row[...endOfDateIndex.lowerBound]).dropLast())
                date = dateFormatter.date(from: date$)
            }
            
            if value != nil && date != nil {
                priceDates.append((date:date!, price: value!))
            }
        }
        
        return priceDates
        
    }


    
    
    //MARK: - general MacroTrend functions
    
    class func extractTable(title: String, html: String) async throws -> String {
        
        guard let tableStartIndex = html.range(of: title) else {
            throw DownloadAndAnalysisError.htmlTableTitleNotFound
        }
        
        guard let tableEndIndex = html.range(of: "</table>",options: [NSString.CompareOptions.literal], range: tableStartIndex.upperBound..<html.endIndex, locale: nil) else {
            throw DownloadAndAnalysisError.htmlTableEndNotFound
        }
        
        let tableText = String(html[tableStartIndex.upperBound..<tableEndIndex.lowerBound])

        return tableText
    }

    class func extractHeaderTitles(html: String) async throws -> [String] {
        
        let headerStartSequence = "</thead>"
        let headerEndSequence = "<tbody><tr>"
        let rowEndSequence = "</th>"
        
        guard let headerStartIndex = html.range(of: headerStartSequence) else {
            throw DownloadAndAnalysisError.htmTablelHeaderStartNotFound
        }
        
        guard let headerEndIndex = html.range(of: headerEndSequence,options: [NSString.CompareOptions.literal], range: headerStartIndex.upperBound..<html.endIndex, locale: nil) else {
            throw DownloadAndAnalysisError.htmlTableHeaderEndNotFound
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

    class func extractTableData(html: String, titles: [String], untilDate: Date?=nil) throws -> [Dated_EPS_PER_Values] {
        
        let bodyStartSequence = "<tbody><tr>"
        let bodyEndSequence = "</tr></tbody>"
        let rowEndSequence = "</td>"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "y-M-d"
        
        var datedValues = [Dated_EPS_PER_Values]()
        
        guard let bodyStartIndex = html.range(of: bodyStartSequence) else {
            throw DownloadAndAnalysisError.htmlTableBodyStartIndexNotFound
        }
        
        guard let bodyEndIndex = html.range(of: bodyEndSequence,options: [NSString.CompareOptions.literal], range: bodyStartIndex.upperBound..<html.endIndex, locale: nil) else {
            throw DownloadAndAnalysisError.htmlTableBodyEndIndexNotFound
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
    
    /// macrotrend data are time-DESCENDING from left to right,
    /// so the value arrays - scraped right-to-left  from eadh row - are returned in time_ASCENDING order
    class func macrotrendsRowExtraction(table$: String, rowTitle: String, exponent: Double?=nil, numberTerminal:String?=nil) throws -> [Double] {
        
        var valueArray = [Double]()
        let numberTerminal = "</div></div>"
        let numberStarter = ">"
        var tableText = table$
        
        var numberEndIndex = tableText.range(of: numberTerminal)

        while numberEndIndex != nil && tableText.count > 0 {
            
            if let numberStartIndex = tableText.range(of: numberStarter, options: .backwards, range: tableText.startIndex..<numberEndIndex!.lowerBound, locale: nil)  {
                
                let value$ = tableText[numberStartIndex.upperBound..<numberEndIndex!.lowerBound]

                if value$ == "-" { valueArray.append( 0.0) } // MT.ent hads '-' indicating nil/ 0
                else {
                    let value = numberFromText(value$: String(value$), rowTitle: rowTitle, exponent: exponent)
                    valueArray.append(value)
                }
            }
            else {
                throw DownloadAndAnalysisError.contentStartSequenceNotFound
            }
            
            tableText.removeSubrange(...numberEndIndex!.upperBound)
            numberEndIndex = tableText.range(of: numberTerminal)
        }
        
        return valueArray  // in time_DESCENDING order
    }

    //MARK: - general Yahoo functions
    
    /// webpageExponent = the exponent used by the webpage to listing financial figures, e.g. 'thousands' on yahoo = 3.0
    class func scrapeRowForDoubles(website: Website, html$: String?, sectionHeader: String?=nil, rowTitle: String, rowTerminal: String? = nil, numberStarter: String?=nil , numberTerminal: String? = nil, webpageExponent: Double?=nil) throws -> [Double] {
        
        var pageText = html$
        let sectionTitle: String? = (sectionHeader != nil) ? (">" + sectionHeader!) : nil
        let rowDataStartDelimiter: String? = (website == .macrotrends) ? "class=\"fas fa-chart-bar\"></i></div></div></div><div role=" : nil
        let rowStart = website == .macrotrends ? ">" + rowTitle + "</a></div></div>" : ">" + rowTitle // + "</span>"
        let rowTerminal = website == .macrotrends ? "</div></div></div>" : (rowTerminal ?? "</span></td></tr>")
        let tableTerminal = "</div></div></div></div>"

        guard pageText != nil else {
            throw DownloadAndAnalysisError.emptyWebpageText
        }
        
// 1 Remove leading and trailing parts of the html code
// A Find section header
        if sectionTitle != nil {
            guard let sectionIndex = pageText?.range(of: sectionTitle!) else {
                throw DownloadAndAnalysisError.htmlSectionTitleNotFound
            }
            pageText = String(pageText!.suffix(from: sectionIndex.upperBound))
        }
                        
// B Find beginning of row
        var rowStartIndex = pageText?.range(of: rowStart)
        guard rowStartIndex != nil else {
            throw DownloadAndAnalysisError.htmlRowStartIndexNotFound
        }
        
        if let validStarter = rowDataStartDelimiter {
            if let index = pageText?.range(of: validStarter, options: [NSString.CompareOptions.literal], range: rowStartIndex!.upperBound..<pageText!.endIndex, locale: nil) {
                rowStartIndex = index
            }
        }
        
// C Find end of row - or if last row end of table - and reduce pageText to this row
        if let rowEndIndex = pageText?.range(of: rowTerminal,options: [NSString.CompareOptions.literal], range: rowStartIndex!.upperBound..<pageText!.endIndex, locale: nil) {
            pageText = String(pageText![rowStartIndex!.upperBound..<rowEndIndex.upperBound])
        } else if let tableEndIndex = pageText?.range(of: tableTerminal,options: [NSString.CompareOptions.literal], range: rowStartIndex!.upperBound..<pageText!.endIndex, locale: nil) {
            pageText = String(pageText![rowStartIndex!.upperBound..<tableEndIndex.upperBound])
        }
        else {
            throw DownloadAndAnalysisError.htmlRowEndIndexNotFound
        }
        
        if website == .macrotrends {
            let values = try macrotrendsRowExtraction(table$: pageText ?? "", rowTitle: rowTitle, exponent: webpageExponent)
            return values // MT.com rows are time_DESCENDING from left to right, so the valueArray is in time-ASCENDING order deu to backwards row scraping.
        }
        else {
                let values = try yahooRowNumbersExtraction(table$: pageText ?? "", rowTitle: rowTitle,numberTerminal: numberTerminal, exponent: webpageExponent)
                return values
        }
    }
    
    class func scrapeYahooRowForDoubles(html$: String?, rowTitle: String, rowTerminal: String? = nil, numberTerminal: String? = nil) throws -> [Double] {
        
        var pageText = html$
        let rowStart = rowTitle
        let rowTerminal = rowTerminal ?? "\""

        guard pageText != nil else {
            throw DownloadAndAnalysisError.emptyWebpageText
        }
        
                        
// B Find beginning of row
        let rowStartIndex = pageText?.range(of: rowStart)
        guard rowStartIndex != nil else {
            throw DownloadAndAnalysisError.htmlRowStartIndexNotFound
        }
                
// C Find end of row - or if last row end of table - and reduce pageText to this row
        if let rowEndIndex = pageText?.range(of: rowTerminal,options: [NSString.CompareOptions.literal], range: rowStartIndex!.upperBound..<pageText!.endIndex, locale: nil) {
            pageText = String(pageText![rowStartIndex!.upperBound..<rowEndIndex.upperBound])
        }
        else {
            throw DownloadAndAnalysisError.htmlRowEndIndexNotFound
        }

        let values = try yahooRowNumbersExtraction(table$: pageText ?? "", rowTitle: rowTitle, numberTerminal: numberTerminal)
        return values
    }

    class func yahooRowNumbersExtraction(table$: String, rowTitle: String, numberTerminal: String?=nil, exponent: Double?=nil) throws -> [Double] {
        
        var valueArray = [Double]()
        let numberTerminal = numberTerminal ?? "</span>"
        let numberStarter = ">"
        var tableText = table$
        
        var labelEndIndex = tableText.range(of: numberTerminal, options: .backwards, range: nil, locale: nil)
        if let index = labelEndIndex {
            tableText.removeSubrange(index.lowerBound...)
        }

        repeat {
            guard let labelStartIndex = tableText.range(of: numberStarter, options: .backwards, range: tableText.startIndex..<labelEndIndex!.lowerBound, locale: nil) else {
                throw DownloadAndAnalysisError.contentStartSequenceNotFound
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
    
    class func scrapeRowForText(html$: String?, sectionHeader: String?=nil, sectionTerminal: String?=nil, rowTitle: String, rowTerminal: String? = nil, textTerminal: String? = nil, webpageExponent: Double?=nil) throws -> [String] {
        
        var pageText = html$
        let sectionTitle: String? = (sectionHeader != nil) ? (">" + sectionHeader!) : nil
//        let rowDataStartDelimiter: String? = (website == .macrotrends) ? "class=\"fas fa-chart-bar\"></i></div></div></div><div role=" : nil
        let rowStart = rowTitle
        let rowTerminal = (rowTerminal ?? ",")
        let paraTerminal = sectionTerminal ?? "</p>"

        guard pageText != nil else {
            throw DownloadAndAnalysisError.emptyWebpageText
        }
        
// 1 Remove leading and trailing parts of the html code
// A Find section header
        if sectionTitle != nil {
            guard let sectionIndex = pageText?.range(of: sectionTitle!) else {
                throw DownloadAndAnalysisError.htmlSectionTitleNotFound
            }
            pageText = String(pageText!.suffix(from: sectionIndex.upperBound))
        }
                        
// B Find beginning of row
        let rowStartIndex = pageText?.range(of: rowStart)
        guard rowStartIndex != nil else {
            throw DownloadAndAnalysisError.htmlRowStartIndexNotFound
        }
        
// C Find end of row - or if last row end of table - and reduce pageText to this row
        if let rowEndIndex = pageText?.range(of: rowTerminal,options: [NSString.CompareOptions.literal], range: rowStartIndex!.upperBound..<pageText!.endIndex, locale: nil) {
            pageText = String(pageText![rowStartIndex!.upperBound..<rowEndIndex.lowerBound])
        } else if let tableEndIndex = pageText?.range(of: paraTerminal,options: [NSString.CompareOptions.literal], range: rowStartIndex!.upperBound..<pageText!.endIndex, locale: nil) {
            pageText = String(pageText![rowStartIndex!.upperBound..<tableEndIndex.lowerBound])
        }
        else {
            throw DownloadAndAnalysisError.htmlRowEndIndexNotFound
        }
        
        let textArray = try yahooRowStringExtraction(table$: pageText ?? "", rowTitle: rowTitle, textTerminal: textTerminal)
        return textArray
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
                throw DownloadAndAnalysisError.contentStartSequenceNotFound
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


    // MARK: - Yahoo & MT functions
    

    
    //MARK: - general analysis functions
    
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



}
