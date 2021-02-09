//
//  WebpageScraper.swift
//  Bulls'N'Bears
//
//  Created by aDav on 08/02/2021.
//

import Foundation

class WebpageScraper {
    
    /// webpageExponent = the exponent used by the webpage to listing financial figures, e.g. 'thousands' on yahoo = 3.0
    class func scrapeRow(html$: String?, sectionHeader: String?=nil, rowTitle: String, sectionTerminal: String? = nil, rowTerminal: String? = nil, numberTerminal: String? = nil, numberStarter: String? = nil, webpageExponent: Double?=nil) -> ([Double]?, [String]) {
        
        var pageText = html$
        let sectionTitle: String? = (sectionHeader != nil) ? (">" + sectionHeader!) : nil
//        let sectionTerminal = sectionTerminal ?? "</div></div></div></div></div>"
        let rowTerminal = rowTerminal ?? "</div></div></div><div role=\"row\""
        let numberTerminal = numberTerminal ?? "</div></div><div role=\"gridcell\""
        let numberStarter = numberStarter ?? ">"
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
                errors.append("Did not find section \(sectionTitle!) on webpage")
                return (nil, errors)
            }
            pageText = String(pageText!.suffix(from: sectionIndex.upperBound))
        }
                        
// B Find beginning of row
        guard let rowStartIndex = pageText?.range(of: rowTitle) else {
            errors.append("Did not find row titled \(rowTitle) on webpage")
            return (nil, errors)
        }
// C Find end of row - or if last row end of table - and reduce pageText to this row
        if let rowEndIndex = pageText?.range(of: rowTerminal,options: [NSString.CompareOptions.literal], range: rowStartIndex.upperBound..<pageText!.endIndex, locale: nil) {
            pageText = String(pageText![rowStartIndex.upperBound..<rowEndIndex.lowerBound])
        } else if let tableEndIndex = pageText?.range(of: tableTerminal,options: [NSString.CompareOptions.literal], range: rowStartIndex.upperBound..<pageText!.endIndex, locale: nil) {
            pageText = String(pageText![rowStartIndex.upperBound..<tableEndIndex.lowerBound])
        }
        else {
            errors.append("Did not find row end for title \(rowTitle) on webpage")
            return (nil, errors)
        }

        var valueArray = [Double]()
        var labelEndIndex: Range<String.Index>?
        
        repeat {
            guard let labelStartIndex = pageText!.range(of: numberStarter, options: .backwards, range: nil, locale: nil) else {
                errors.append("Did not find number start in \(rowTitle) on webpage")
                continue
            }
            let value$ = pageText![labelStartIndex.upperBound...]

            if value$.filter("-0123456789.".contains) != "" {
                var value = Double()
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
                        value = v * (pow(10.0, webpageExponent ?? 0.0))
                    }
                    
                    if value$.last == ")" {
                        value = v * -1
                    }
                }
                valueArray.append(value)
            }
            else if value$.contains("N/A") {
                valueArray.append(Double())
            }
            
            labelEndIndex = pageText!.range(of: numberTerminal, options: .backwards, range: nil, locale: nil)
            if let index = labelEndIndex {
                pageText!.removeSubrange(index.lowerBound...)
            }
            
        } while labelEndIndex != nil && (pageText?.count ?? 0) > 1

        return (valueArray.reversed() ,errors)
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
