//
//  FinanzenScraper.swift
//  Bulls'N'Bears
//
//  Created by aDav on 14/03/2023.
//

import Foundation
import CoreData
import UIKit

class FinanzenScraper {
    
    class func countOfDownloadTasks() -> Int {
        return 3
    }
    
    class func downloadAnalyseAndSavePredictions(shareSymbol: String?, companyName: String, shareID: NSManagedObjectID, progressDelegate: ProgressViewDelegate?=nil ) async {
        
        let longNameFirst = String(companyName.split(separator: " ").first ?? "noFirstName")
        
        let components = URLComponents(string: "https://www.finanzen.net/schaetzungen/\(longNameFirst)")
        
        guard let url = components?.url else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "failed to generate valid url for 'Finanzen' predictions download for \(companyName)")
            return
        }
        
        guard let htmlText = await Downloader.downloadDataNoThrow(url: url) else {
            return
        }
        
        progressDelegate?.taskCompleted()
        
        let sectionHeaders = ">Sch&auml;tzungen* zu"
        let rowTitles = [">Umsatzerlöse in Mio.</td>", "KGV"]
        let saveTitles = ["avg. estimate", "forward p/e"]
        
        guard let results = analyseFinanzenPage(htmlText: htmlText, section: sectionHeaders, rowTitles: rowTitles, saveTitles: saveTitles) else {
            return
        }
        progressDelegate?.taskCompleted()
            
        let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc.automaticallyMergesChangesFromParent = true
        
        if let bgShare = backgroundMoc.object(with: shareID) as? Share {
            await bgShare.mergeInDownloadedData(labelledDatedValues: results)
        }
        
        progressDelegate?.taskCompleted()
    }
    
    class func analyseFinanzenPage(htmlText: String, section: String, rowTitles: [String], saveTitles: [String]) -> [Labelled_DatedValues]? {
        
        let tableEndSequence = "</tbody></table>"
        
        let rowEndSequence = "</td></tr>"
        let columnEndSequence = "</td>"
        let valueStartSequence = ">"
        
        let tableHeaderRowEndSequence = "</tr></thead>"
        let tableHeaderColumnEndSequence = "e</th>"
        
        guard let sectionText = sectionText(htmlText: htmlText, sectionTitle: section, sectionEndSequence: tableEndSequence) else {
            return nil
        }
        
        // find years in header row
        guard let headerRowEnd = sectionText.range(of: tableHeaderRowEndSequence) else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "failed to locate header row end sequence \(tableHeaderRowEndSequence) for section \(section) on 'Finanzen' predictions page \(htmlText)")
            return nil
        }
        
        let headerRowTexts = String(sectionText[...headerRowEnd.lowerBound])
        
        let valueDates = headerRowColumnValues(headerRowText: headerRowTexts, columnSeparator: tableHeaderColumnEndSequence)
        
        var results = [Labelled_DatedValues]()
        
        var rowCount = 0
        for title in rowTitles {
            
            guard let rowStart = sectionText.range(of: title) else {
                ErrorController.addInternalError(errorLocation: #function, errorInfo: "failed to locate row start of \(title) for section \(section) on 'Finanzen' predictions page \(htmlText)")
                continue
            }
            guard let rowEnd = sectionText.range(of: rowEndSequence, range: rowStart.upperBound..<sectionText.endIndex) else {
                ErrorController.addInternalError(errorLocation: #function, errorInfo: "failed to locate row end of \(title) for section \(section) on 'Finanzen' predictions page \(htmlText)")
                continue
            }
            
            let rowText = String(sectionText[rowStart.upperBound..<rowEnd.lowerBound])
            let columnValues = bodyRowColumnValues(title: title, rowText: rowText, columnSeparator: columnEndSequence)
            
            var datedValues = [DatedValue]()
            var count = 0
            
            for value in columnValues {
                if let vv = value {
                    if valueDates.count > count {
                        if let vd = valueDates[count] {
                            datedValues.append(DatedValue(date: vd, value: vv))
                        }
                    }
                }
                count += 1
            }
            
            results.append(Labelled_DatedValues(label: saveTitles[rowCount], datedValues: datedValues.sortByDate(dateOrder: .ascending)))
            rowCount += 1
        }
        
        let endOfThisYear = DatesManager.endOfYear(of: Date())
        var correctedResults = [Labelled_DatedValues]()
        
        // 1 remove forward PE for this year
        if var forwardPE = results.filter({ ldv in
            if ldv.label.contains("forward") { return true }
            else { return false }
        }).first {
            
            forwardPE.datedValues = forwardPE.datedValues.filter({ dv in
                if dv.date > endOfThisYear { return true }
                else { return false }
            })
            correctedResults.append(forwardPE)
        }
        
        // 1 calc revenue growth, and remove future revenue for this year
        if var revenueEstimates = results.filter({ ldv in
            if ldv.label.contains("estimate") { return true }
            else { return false }
        }).first {
            if revenueEstimates.datedValues.count > 1 {
                var yoyRevenueGrowth = revenueEstimates
                for i in 0..<revenueEstimates.datedValues.count-1 {
                    let difference = revenueEstimates.datedValues[i+1].value - revenueEstimates.datedValues[i].value
                    let proportion = difference / revenueEstimates.datedValues[i].value
                    yoyRevenueGrowth.datedValues[i+1].value = proportion
                }
                // 2 remove this year's element of yoy growth
                yoyRevenueGrowth.datedValues = yoyRevenueGrowth.datedValues.filter({ dv in
                    if dv.date > endOfThisYear { return true }
                    else { return false }
                })
                yoyRevenueGrowth.label = "sales growth (year/est)"
                correctedResults.append(yoyRevenueGrowth)
                
                // 3 remove this years' revenue estimate
                revenueEstimates.datedValues = revenueEstimates.datedValues.filter({ dv in
                    if dv.date > endOfThisYear { return true }
                    else { return false }
                })
                correctedResults.append(revenueEstimates)
            }
        }
//
//        print()
//        print("Finanzen page results")
//        for result in correctedResults {
//            print(result)
//        }
        
        return correctedResults
        
    }
    
    class func sectionText(htmlText: String, sectionTitle: String, sectionEndSequence: String) -> String? {
        
        
        guard let sectionStart = htmlText.range(of: sectionTitle) else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "failed to locate section \(sectionTitle) on 'Finanzen' predictions page \(htmlText)")
            return nil
        }
        
        guard let sectionEnd = htmlText.range(of: sectionEndSequence, range: sectionStart.upperBound..<htmlText.endIndex) else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "failed to locate section end \(sectionEndSequence) on 'Finanzen' predictions page \(htmlText)")
            return nil
        }
        
        return String(htmlText[sectionStart.upperBound..<sectionEnd.lowerBound])

    }
    
    class func headerRowColumnValues(headerRowText: String, columnSeparator: String) -> [Date?] {
        
        let headerRowColumnTexts = headerRowText.split(separator: columnSeparator)
        
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return formatter
        }()

        var dates = [Date?]()
        
        for text in headerRowColumnTexts {
            if let valueStart = text.range(of: ">", options: .backwards) {
                let value$ = String(text[valueStart.upperBound...])
                if let date = dateFormatter.date(from: value$) {
                    dates.append(DatesManager.endOfYear(of: date))
                } else {
                    dates.append(nil)
                }
            }
        }

        return dates
    }
    
    class func bodyRowColumnValues(title: String, rowText: String, columnSeparator: String) -> [Double?] {
        
        let rowColumnTexts = rowText.split(separator: columnSeparator)
        
        var values = [Double?]()
                
        for text in rowColumnTexts {
            if let valueStart = text.range(of: ">", options: .backwards) {
                var value$ = String(text[valueStart.upperBound...])
                if title.lowercased().contains("in mio") {
                    value$ += "M"
                }
                value$ = value$.replacingOccurrences(of: ",", with: ".")
                values.append(value$.textToNumber())
            }
        }

        return values
    }

    
}
