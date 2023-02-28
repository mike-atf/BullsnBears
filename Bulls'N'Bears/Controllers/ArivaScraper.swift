//
//  ArivaScraper.swift
//  Bulls'N'Bears
//
//  Created by aDav on 22/02/2023.
//

import Foundation

class ArivaScraper {
    
    class func pageAnalysis(html: String, headers: [String], parameters: [[String]]) -> [Labelled_DatedValues]? {
        
        let rowEndSequence = "</tr> <tr>"
        let columnEndSequence = "</td>"
        let columnStartSequence = "<td class="
        let tableEndSequence = "</tbody> </table>"
        let tableStartSequence = "<tbody>"
        
        let pageText = html
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
            
            let tableText = pageText[headerPosition.upperBound..<tableEndPosition.lowerBound]
            
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
                if let parameterStart = tableText.range(of: parameter) {
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
                            let eValue$ = content$.filter("-0123456789,%".contains).replacingOccurrences(of: ",", with: ".")
                            var validValue = eValue$.textToNumber()
                            if parameter.contains("%") && validValue != nil{
                                validValue! /= 100
                            }
                            parameterValues.append(validValue)
                            row$ = row$[columnEnd!.upperBound...]
                            columnEnd = row$.range(of: columnEndSequence)
                        }
                    }
                }
                
                if let vDates = dates { // ascending order by default
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
    
}
