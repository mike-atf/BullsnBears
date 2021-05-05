//
//  WebpageScraper.swift
//  Bulls'N'Bears
//
//  Created by aDav on 08/02/2021.
//

import Foundation

class WebpageScraper {
    
    /// webpageExponent = the exponent used by the webpage to listing financial figures, e.g. 'thousands' on yahoo = 3.0
    class func scrapeRowForDoubles(website: Website, html$: String?, sectionHeader: String?=nil, rowTitle: String, rowTerminal: String? = nil, numberTerminal: String? = nil, webpageExponent: Double?=nil) -> ([Double]?, [String]) {
        
        var pageText = html$
        let sectionTitle: String? = (sectionHeader != nil) ? (">" + sectionHeader!) : nil
        let rowDataStartDelimiter: String? = (website == .macrotrends) ? "class=\"fas fa-chart-bar\"></i></div></div></div><div role=" : nil
        let rowStart = website == .macrotrends ? ">" + rowTitle + "</a></div></div>" : ">" + rowTitle + "</span>"
        let rowTerminal = website == .macrotrends ? "</div></div></div>" : (rowTerminal ?? "</span></td></tr>")
        let tableTerminal = "</div></div></div></div>"

        var errors = [String]()
        
        guard pageText != nil else {
            errors.append("Empty webpage for \(rowTitle), \(rowTitle)")
            return (nil, errors)
        }
        
// 1 Remove leading and trailing parts of the html code
// A Find section header
        if sectionTitle != nil {
            guard let sectionIndex = pageText?.range(of: sectionTitle!) else {
                let error = "Did not find section \(sectionTitle!) on webpage"
                if !errors.contains(error) {
                    errors.append(error)
                }
                return (nil, errors)
            }
            pageText = String(pageText!.suffix(from: sectionIndex.upperBound))
        }
                        
// B Find beginning of row
        var rowStartIndex = pageText?.range(of: rowStart)
        guard rowStartIndex != nil else {
            let error = "Did not find row titled \(rowTitle) on webpage"
            if !errors.contains(error) {
                errors.append(error)
            }
            return (nil, errors)
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
            let error = "Did not find row end for title \(rowTitle) on webpage"
            if !errors.contains(error) {
                errors.append(error)
            }
            return (nil, errors)
        }
        
        if website == .macrotrends {
            let (valueArray, errors) = macrotrendsRowExtraction(table$: pageText ?? "", rowTitle: rowTitle, exponent: webpageExponent)
            return (valueArray, errors) // MT.com rows are time_DESCENDING from left to right, so the valueArray is in time-ASCENDING order deu to backwards row scraping.
        }
        else {
            let (valueArray, errors) = yahooRowNumbersExtraction(table$: pageText ?? "", rowTitle: rowTitle, numberTerminal: numberTerminal, exponent: webpageExponent)
            return (valueArray, errors)
        }
    }
    
    class func scrapeYahooRowForDoubles(html$: String?, rowTitle: String, rowTerminal: String? = nil, numberTerminal: String? = nil) -> ([Double]?, [String]) {
        
        var pageText = html$
        let rowStart = rowTitle
        let rowTerminal = rowTerminal ?? "\""

        var errors = [String]()
        
        guard pageText != nil else {
            errors.append("Empty webpage for \(rowTitle), \(rowTitle)")
            return (nil, errors)
        }
        
                        
// B Find beginning of row
        let rowStartIndex = pageText?.range(of: rowStart)
        guard rowStartIndex != nil else {
            let error = "Did not find row titled \(rowTitle) on webpage"
            if !errors.contains(error) {
                errors.append(error)
            }
            return (nil, errors)
        }
                
// C Find end of row - or if last row end of table - and reduce pageText to this row
        if let rowEndIndex = pageText?.range(of: rowTerminal,options: [NSString.CompareOptions.literal], range: rowStartIndex!.upperBound..<pageText!.endIndex, locale: nil) {
            pageText = String(pageText![rowStartIndex!.upperBound..<rowEndIndex.upperBound])
        }
        else {
            let error = "Did not find row end for title \(rowTitle) on webpage"
            if !errors.contains(error) {
                errors.append(error)
            }
            return (nil, errors)
        }
        
//        print()
//        print("website text:")
//        print(html$ ?? "none")
        

        return yahooNumbersExtraction(table$: pageText ?? "", rowTitle: rowTitle, numberTerminal: numberTerminal)
//        return (valueArray, errors)
    }

    
    class func scrapeRowForText(website: Website, html$: String?, sectionHeader: String?=nil, sectionTerminal: String?=nil, rowTitle: String, rowTerminal: String? = nil, textTerminal: String? = nil, webpageExponent: Double?=nil) -> ([String]?, [String]) {
        
        var pageText = html$
        let sectionTitle: String? = (sectionHeader != nil) ? (">" + sectionHeader!) : nil
        let rowDataStartDelimiter: String? = (website == .macrotrends) ? "class=\"fas fa-chart-bar\"></i></div></div></div><div role=" : nil
        let rowStart = website == .macrotrends ? ">" + rowTitle + "</a></div></div>" : rowTitle
        let rowTerminal = website == .macrotrends ? "</div></div></div>" : (rowTerminal ?? ",")
        let paraTerminal = sectionTerminal ?? "</p>"

        var errors = [String]()
        
        guard pageText != nil else {
            errors.append("Empty webpage for \(rowTitle), \(rowTitle)")
            return (nil, errors)
        }
        
// 1 Remove leading and trailing parts of the html code
// A Find section header
        if sectionTitle != nil {
            guard let sectionIndex = pageText?.range(of: sectionTitle!) else {
                let error = "Did not find section \(sectionTitle!) on webpage"
                if !errors.contains(error) {
                    errors.append(error)
                }
                return (nil, errors)
            }
            pageText = String(pageText!.suffix(from: sectionIndex.upperBound))
        }
                        
// B Find beginning of row
        var rowStartIndex = pageText?.range(of: rowStart)
        guard rowStartIndex != nil else {
            let error = "Did not find row titled \(rowTitle) on webpage"
            if !errors.contains(error) {
                errors.append(error)
            }
            return (nil, errors)
        }
        
        if let validStarter = rowDataStartDelimiter {
            if let index = pageText?.range(of: validStarter, options: [NSString.CompareOptions.literal], range: rowStartIndex!.upperBound..<pageText!.endIndex, locale: nil) {
                rowStartIndex = index
            }
        }
        
// C Find end of row - or if last row end of table - and reduce pageText to this row
        if let rowEndIndex = pageText?.range(of: rowTerminal,options: [NSString.CompareOptions.literal], range: rowStartIndex!.upperBound..<pageText!.endIndex, locale: nil) {
            pageText = String(pageText![rowStartIndex!.upperBound..<rowEndIndex.lowerBound])
        } else if let tableEndIndex = pageText?.range(of: paraTerminal,options: [NSString.CompareOptions.literal], range: rowStartIndex!.upperBound..<pageText!.endIndex, locale: nil) {
            pageText = String(pageText![rowStartIndex!.upperBound..<tableEndIndex.lowerBound])
        }
        else {
            let error = "Did not find row end for title \(rowTitle) on webpage"
            if !errors.contains(error) {
                errors.append(error)
            }
            return (nil, errors)
        }
        
//        print()
//        print("website text:")
//        print(html$ ?? "none")
        
        if website == .macrotrends {
//            let (textArray, errors) = macrotrendsRowExtraction(table$: pageText ?? "", rowTitle: rowTitle, exponent: webpageExponent)
//            return (textArray, errors)
            return (nil, ["macrotrends text extraction not implemented"])
        }
        else {
            let (textArray, errors) = yahooRowStringExtraction(table$: pageText ?? "", rowTitle: rowTitle, textTerminal: textTerminal)
            return (textArray, errors)
        }
    }

    
    class func scrapeTextRow(website: Website, html$: String?, rowTitle: String, rowTerminal: String, numberTerminal: String? = nil) -> ([Double]?, [String]) {
        
        var pageText = html$
        let textLineStart = rowTitle
        var errors = [String]()
        
        guard pageText != nil else {
            errors.append("Empty webpage for \(rowTitle), \(rowTitle)")
            return (nil, errors)
        }
        
// 1 Remove leading and trailing parts of the html code
// A Find section header
                        
// B Find beginning of row
        let rowStartIndex = pageText?.range(of: textLineStart)
        guard rowStartIndex != nil else {
            let error = "Did not find row titled \(rowTitle) on webpage"
            if !errors.contains(error) {
                errors.append(error)
            }
            return (nil, errors)
        }
        
        
// C Find end of row - or if last row end of table - and reduce pageText to this row
        if let rowEndIndex = pageText?.range(of: rowTerminal,options: [NSString.CompareOptions.literal], range: rowStartIndex!.upperBound..<pageText!.endIndex, locale: nil) {
            pageText = String(pageText![rowStartIndex!.upperBound..<rowEndIndex.upperBound])
        }
        else {
            let error = "Did not find row end for title \(rowTitle) on webpage"
            if !errors.contains(error) {
                errors.append(error)
            }
            return (nil, errors)
        }
        
//        print()
//        print("website text:")
//        print(html$ ?? "none")
        
        return macrotrendsRowExtraction(table$: pageText ?? "", rowTitle: rowTitle, exponent: nil)
    }

    /// macrotrend data are time-DESCENDING from left to right,
    /// so the value arrays - scraped right-to-left  from eadh row - are returned in time_ASCENDING order
    class func macrotrendsRowExtraction(table$: String, rowTitle: String, exponent: Double?=nil, numberTerminal:String?=nil) -> ([Double], [String]) {
        
        var valueArray = [Double]()
        var errors = [String]()
        let numberTerminal = "</div></div>"
        let numberStarter = ">"
        var tableText = table$
        
        var numberEndIndex = tableText.range(of: numberTerminal)

        while numberEndIndex != nil && tableText.count > 0 {
            
            if let numberStartIndex = tableText.range(of: numberStarter, options: .backwards, range: tableText.startIndex..<numberEndIndex!.lowerBound, locale: nil)  {
                
                let value$ = tableText[numberStartIndex.upperBound..<numberEndIndex!.lowerBound]

                let value = numberFromText(value$: String(value$), rowTitle: rowTitle, exponent: exponent)
                valueArray.append(value)
            }
            else {
                let error = "Did not find start of number on MT webpage"
                if !errors.contains(error) {
                    errors.append(error)
                }
            }
            
            tableText.removeSubrange(...numberEndIndex!.upperBound)
            numberEndIndex = tableText.range(of: numberTerminal)
        }
        
        return (valueArray, errors)  // in time_DESCENDING order
    }
    
    class func yahooRowNumbersExtraction(table$: String, rowTitle: String, numberTerminal: String?=nil, exponent: Double?=nil) -> ([Double], [String]) {
        
        var valueArray = [Double]()
        var errors = [String]()
        let numberTerminal = numberTerminal ?? "</span>"
        let numberStarter = ">"
        var tableText = table$
        
        var labelEndIndex = tableText.range(of: numberTerminal, options: .backwards, range: nil, locale: nil)
        if let index = labelEndIndex {
            tableText.removeSubrange(index.lowerBound...)
        }

//        print("row text:")
//        print(tableText)
        repeat {
            guard let labelStartIndex = tableText.range(of: numberStarter, options: .backwards, range: tableText.startIndex..<labelEndIndex!.lowerBound, locale: nil) else {
                let error = "Did not find number start in \(rowTitle) on webpage"
                if !errors.contains(error) {
                    errors.append(error)
                }
                continue
            }
            
            let value$ = tableText[labelStartIndex.upperBound...]
//            print("value$ extracted: \(value$)")
            let value = numberFromText(value$: String(value$), rowTitle: rowTitle, exponent: exponent)
            valueArray.append(value)
            
            
            labelEndIndex = tableText.range(of: numberTerminal, options: .backwards, range: tableText.startIndex..<labelEndIndex!.lowerBound, locale: nil)
            if let index = labelEndIndex {
                tableText.removeSubrange(index.lowerBound...)
            }

        } while labelEndIndex != nil && (tableText.count > 1)

//        print("values extracted: \(valueArray)")
//        print("======================================="
//        )
        return (valueArray, errors)
    }
    
    class func yahooNumbersExtraction(table$: String, rowTitle: String, numberTerminal: String?=nil, exponent: Double?=nil) -> ([Double], [String]) {
        
        var valueArray = [Double]()
        var errors = [String]()
        let numberTerminal = numberTerminal ?? ","
        let numberStarter = ":"
        var tableText = table$
        
        var labelEndIndex = tableText.range(of: numberTerminal, options: .backwards, range: nil, locale: nil)
        if let index = labelEndIndex {
            tableText.removeSubrange(index.lowerBound...)
        }

//        print("row text:")
//        print(tableText)
        repeat {
            guard let labelStartIndex = tableText.range(of: numberStarter, options: .backwards, range: tableText.startIndex..<labelEndIndex!.lowerBound, locale: nil) else {
                let error = "Did not find number start in \(rowTitle) on webpage"
                if !errors.contains(error) {
                    errors.append(error)
                }
                continue
            }
            
            let value$ = tableText[labelStartIndex.upperBound...]
//            print("value$ extracted: \(value$)")
            let value = numberFromText(value$: String(value$), rowTitle: rowTitle, exponent: exponent)
            valueArray.append(value)
            
            
            labelEndIndex = tableText.range(of: numberTerminal, options: .backwards, range: tableText.startIndex..<labelEndIndex!.lowerBound, locale: nil)
            if let index = labelEndIndex {
                tableText.removeSubrange(index.lowerBound...)
            }

        } while labelEndIndex != nil && (tableText.count > 1)

//        print("values extracted: \(valueArray)")
//        print("======================================="
//        )
        return (valueArray, errors)
    }

    
    class func yahooRowStringExtraction(table$: String, rowTitle: String, textTerminal: String?=nil) -> ([String], [String]) {
        
        var textArray = [String]()
        var errors = [String]()
        let textTerminal = textTerminal ?? "\""
        let textStarter = "\""
        var tableText = table$
        
        var labelEndIndex = tableText.range(of: textTerminal, options: .backwards, range: nil, locale: nil)
        if let index = labelEndIndex {
            tableText.removeSubrange(index.lowerBound...)
        }

//        print("row text:")
//        print(tableText)
        repeat {
            guard let labelStartIndex = tableText.range(of: textStarter, options: .backwards, range: tableText.startIndex..<labelEndIndex!.lowerBound, locale: nil) else {
                let error = "Did not find text start in \(rowTitle) on webpage"
                if !errors.contains(error) {
                    errors.append(error)
                }
                continue
            }
            
            let value$ = String(tableText[labelStartIndex.upperBound...])
//            print("value$ extracted: \(value$)")
            textArray.append(value$)
            
            labelEndIndex = tableText.range(of: textTerminal, options: .backwards, range: tableText.startIndex..<labelEndIndex!.lowerBound, locale: nil)
            if let index = labelEndIndex {
                tableText.removeSubrange(index.lowerBound...)
            }

        } while labelEndIndex != nil && (tableText.count > 1)

//        print("values extracted: \(valueArray)")
//        print("======================================="
//        )
        return (textArray, errors)
    }

    
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
    
    class func scrapeColumn(html$: String?, tableHeader: String, tableTerminal: String? = nil, columnTerminal: String? = nil, noOfColumns:Int?=4, targetColumnFromRight: Int?=0) -> ([Double]?, [String]) {
        
        let tableHeader = tableHeader
        let tableTerminal =  tableTerminal ?? "</td>\n\t\t\t\t </tr></tbody>"
        let columnTerminal = columnTerminal ?? "</td>"
        let labelStart = ">"
        
        var errors = [String]()

        var pageText = String(html$ ?? "")
        
        guard let titleIndex = pageText.range(of: tableHeader) else {
            errors.append("Did not find section \(tableHeader) on MT website")
            return (nil, errors)
        }

        let tableEndIndex = pageText.range(of: tableTerminal,options: [NSString.CompareOptions.literal], range: titleIndex.upperBound..<pageText.endIndex, locale: nil)
        
        guard tableEndIndex != nil else {
            errors.append("Did not find table end in section \(tableHeader) on MT website")
            return (nil, errors)
        }
        pageText = String(pageText[titleIndex.upperBound..<tableEndIndex!.lowerBound])
        
        var rowEndIndex = pageText.range(of: columnTerminal, options: .backwards, range: nil, locale: nil)
        var valueArray = [Double]()
        var count = 0 // row has four values, we only want the last of those four
        
        repeat {
            let labelStartIndex = pageText.range(of: labelStart, options: .backwards, range: nil, locale: nil)
            let value$ = pageText[labelStartIndex!.upperBound...]
            
            if count%(noOfColumns ?? 4) == (targetColumnFromRight ?? 0) {
                valueArray.append(Double(value$.filter("-0123456789.".contains)) ?? Double())
            }

            rowEndIndex = pageText.range(of: columnTerminal, options: .backwards, range: nil, locale: nil)
            if rowEndIndex != nil {
                pageText.removeSubrange(rowEndIndex!.lowerBound...)
                count += 1
            }
        }  while rowEndIndex != nil
        
        return (valueArray, errors)

    }
    
    class func scrapePERDatesTable(html$: String?, tableHeader: String, tableTerminal: String? = nil, columnTerminal: String? = nil) -> ([DatedValue]?, [String]) {
        
        let tableHeader = tableHeader
        let tableTerminal =  tableTerminal ?? "</td>\n\t\t\t\t </tr></tbody>"
        let columnTerminal = columnTerminal ?? "</td>"
        let labelStart = ">"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "y-M-d"
        
        var errors = [String]()

        var pageText = String(html$ ?? "")
        
        guard let titleIndex = pageText.range(of: tableHeader) else {
            errors.append("Did not find section \(tableHeader) on MT website")
            return (nil, errors)
        }

        let tableEndIndex = pageText.range(of: tableTerminal,options: [NSString.CompareOptions.literal], range: titleIndex.upperBound..<pageText.endIndex, locale: nil)
        
        guard tableEndIndex != nil else {
            errors.append("Did not find table end in section \(tableHeader) on MT website")
            return (nil, errors)
        }
        pageText = String(pageText[titleIndex.upperBound..<tableEndIndex!.lowerBound])
        
        var rowEndIndex = pageText.range(of: columnTerminal, options: .backwards, range: nil, locale: nil)
        var valueArray = [DatedValue]()
        var count = 0 // row has four values, we only want the last of those four
        var dateElements = [Date?]()
        var perElements = [Double]()
        
        repeat {
            let labelStartIndex = pageText.range(of: labelStart, options: .backwards, range: nil, locale: nil)
            let value$ = pageText[labelStartIndex!.upperBound...]
            
            if count%4 == 0 { // PER value
                perElements.append(Double(value$.filter("-0123456789.".contains)) ?? Double())
            }
            else if count%3 == 0 { // date
                dateElements.append(dateFormatter.date(from: String(value$)))
            }

            rowEndIndex = pageText.range(of: columnTerminal, options: .backwards, range: nil, locale: nil)
            if rowEndIndex != nil {
                pageText.removeSubrange(rowEndIndex!.lowerBound...)
                count += 1
            }
            
        }  while rowEndIndex != nil
        
        count = 0
        for per in perElements {
            if dateElements.count > count {
                if let date = dateElements[count] {
                    valueArray.append(DatedValue(date: date, value: per))
                }
            }
            count += 1
        }
        
        return (valueArray.reversed(), errors)

    }
    
    /// returns (priceDate, errors) in time-DESCENDING order
    class func scrapeTreasuryYields(html$: String?) -> ([PriceDate]?, [String]) {
        
        var errors = [String]()
        
        guard var pageText = html$ else {
            errors = ["Empty html$ received trying to find TreasuryBond Yields"]
            return (nil, errors)
        }
        
        var priceDates = [PriceDate]()
        
//        let tableStart = "<tbody><tr>"
        let tableEnd = "</td></tr></table>\r\n<div class=\"updated\"" //"</td></tr></tbody></table>"
        let columnStart = "</td><td class=\"text_view_data\">" //"</td><td class=\"text_view_data\">"
        let rowStart = "<td scope=\"row\" class=\"text_view_data\">"  //"<td scope=\"row "
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = NSLocale.current
            formatter.timeZone = NSTimeZone.local
            formatter.dateFormat = "MM/dd/yy"
            return formatter
        }()

        guard let tableStartIndex = pageText.range(of: rowStart) else {
            let error = "Did not find table end on TreasuryBond Yields webpage"
            if !errors.contains(error) {
                errors.append(error)
            }
            return (nil,errors)
        }
        
        pageText = String(pageText.suffix(from: tableStartIndex.lowerBound))
        
        guard let tableEndIndex = pageText.range(of: tableEnd) else {
            let error = "Did not find table end on TreasuryBond Yields webpage"
            if !errors.contains(error) {
                errors.append(error)
            }
            return (nil,errors)
        }
        
        pageText = String(pageText.prefix(through: tableEndIndex.upperBound))
        
        var rows = [String]()
        var rowStartIndex = pageText.range(of: rowStart, options: .backwards)
        guard rowStartIndex != nil else {
            let error = "Did not start of last table row on TreasuryBond Yields webpage"
            if !errors.contains(error) {
                errors.append(error)
            }
            return (nil,errors)
        }
        
        repeat {
            let row$ = String(pageText[rowStartIndex!.upperBound...])
            rows.append(row$)
            pageText.removeSubrange(rowStartIndex!.lowerBound...)
            rowStartIndex = pageText.range(of: rowStart, options: .backwards)
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
        
        return (priceDates,errors)
        
    }

}
