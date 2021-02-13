//
//  WebpageScraper.swift
//  Bulls'N'Bears
//
//  Created by aDav on 08/02/2021.
//

import Foundation

class WebpageScraper {
    
    /// webpageExponent = the exponent used by the webpage to listing financial figures, e.g. 'thousands' on yahoo = 3.0
    class func scrapeRow(website: Website, html$: String?, sectionHeader: String?=nil, rowTitle: String, sectionTerminal: String? = nil, rowTerminal: String? = nil, numberTerminal: String? = nil, numberStarter: String? = nil, webpageExponent: Double?=nil) -> ([Double]?, [String]) {
        
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
            return (valueArray, errors)
        }
        else {
            let (valueArray, errors) = yahooRowExtraction(table$: pageText ?? "", rowTitle: rowTitle, numberTerminal: numberTerminal, exponent: webpageExponent)
            return (valueArray, errors)
        }
//        repeat {
//            guard let labelStartIndex = pageText!.range(of: numberStarter, options: .backwards, range: nil, locale: nil) else {
//                let error = "Did not find number start in \(rowTitle) on webpage"
//                if !errors.contains(error) {
//                    errors.append(error)
//                }
//                continue
//            }
//            let value$ = pageText![labelStartIndex.upperBound...]
//
//            let value = numberFromText(value$: String(value$), rowTitle: rowTitle, exponent: webpageExponent)
//            valueArray.append(value)
//
//
//            labelEndIndex = pageText!.range(of: numberTerminal, options: .backwards, range: nil, locale: nil)
//            if let index = labelEndIndex {
//                pageText!.removeSubrange(index.lowerBound...)
//            }
//
//        } while labelEndIndex != nil && (pageText?.count ?? 0) > 1

//        return (valueArray.reversed() ,errors)
    }
    
    class func macrotrendsRowExtraction(table$: String, rowTitle: String, exponent: Double?=nil) -> ([Double], [String]) {
        
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
        
        return (valueArray, errors)
    }
    
    class func yahooRowExtraction(table$: String, rowTitle: String, numberTerminal: String?=nil, exponent: Double?=nil) -> ([Double], [String]) {
        
        var valueArray = [Double]()
        var errors = [String]()
        let numberTerminal = numberTerminal ?? "</span>"
        let numberStarter = ">"
        var tableText = table$
        
//        print()
//        print("\(rowTitle) row text:")
//        print("\(tableText)")
//
        var labelEndIndex = tableText.range(of: numberTerminal, options: .backwards, range: nil, locale: nil)
        if let index = labelEndIndex {
            tableText.removeSubrange(index.lowerBound...)
        }

        repeat {
            guard let labelStartIndex = tableText.range(of: numberStarter, options: .backwards, range: tableText.startIndex..<labelEndIndex!.lowerBound, locale: nil) else {
                let error = "Did not find number start in \(rowTitle) on webpage"
                if !errors.contains(error) {
                    errors.append(error)
                }
                continue
            }
            
            let value$ = tableText[labelStartIndex.upperBound...]
//            print("value$ extracted = \(value$)")
            let value = numberFromText(value$: String(value$), rowTitle: rowTitle, exponent: exponent)
            valueArray.append(value)
            
            
            labelEndIndex = tableText.range(of: numberTerminal, options: .backwards, range: tableText.startIndex..<labelEndIndex!.lowerBound, locale: nil)
            if let index = labelEndIndex {
                tableText.removeSubrange(index.lowerBound...)
            }
//            print("remaining row text = \(tableText)")

        } while labelEndIndex != nil && (tableText.count > 1)

//        print("extracted values \(valueArray)")
//        print("===================================++++++++++")

        return (valueArray, errors)
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
    
    class func scrapeColumn(html$: String?, tableHeader: String, tableTerminal: String? = nil, columnTerminal: String? = nil) -> ([Double]?, [String]) {
        
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
            
            if count%4 == 0 {
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
    
}
