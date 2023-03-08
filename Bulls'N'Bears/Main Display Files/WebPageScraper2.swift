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

//struct WebPageInfoDelimiters {
//
//    var htmlText: String!
//    var pageTitle: String?
//    var sectionTitle: String?
//    var rowTitle: String?
//    var pageStartSequence: String?
//    var tableTitle: String?
//    var tableStartSequence: String?
//    var tableEndSequence: String?
//    var rowStartSequence: String?
//    var rowEndSequence: String?
//    var numberStartSequence: String?
//    var numberEndSequence: String?
//    var numberExponent: Double?=nil
//    var textStartSequence: String?
//    var textEndSequence: String?
//    var pageType: Website!
//
//    let numberEndSequence_Yahoo_default1 = "</span>"
//    let numberStartSequence_Yahoo_default = ">"
//    let numberEndSequence_Yahoo_default2 = "</span></div>"
//    let tableStartSequence_yahoo_default = "<thead "
//    let tableEndSequence_default = "</div></div></div></div>"
//    let tableEndSequence_yahoo_default1 = "</p>"
//    let tableEndSequence_yahoo_default2 = "</tbody><tfoot "
//    let rowEndSequence_default = "</div></div></div>"
//    let rowEndSequence_default2 =  "</span></div></div>"
//    let rowEndSequence_yahoo_default1 = "</span></td>"
//    let rowEndSequence_yahoo_default2 = "</span></td></tr>"
//    let rowStartSequence_MT_default = "class=\"fas fa-chart-bar\"></i></div></div></div><div role="
//    let rowStartSequence_yahoo_default = "Ta(start)"
//
//    let rowEndSequence_Yahoo_default = "\""
//    let textStartSequence_yahoo_default = "\""
//    let textEndSequence_yahoo_default = "\""
//
//    init(html$: String, pageType: Website,pageTitle:String?=nil, pageStarter:String?=nil, sectionTitle: String?=nil, tableTitle:String?=nil, tableStarter:String?=nil, tableEnd:String?=nil, rowTitle:String?=nil, rowStart:String?=nil, rowEnd:String?=nil, numberStart:String?=nil, numberEnd:String?=nil, exponent: Double?=nil, textStart: String?=nil, textEnd:String?=nil) {
//
//        self.htmlText = html$
//        self.pageType = pageType
//        self.pageTitle = pageTitle
//        self.pageStartSequence = pageStarter
//        self.sectionTitle = (sectionTitle != nil) ? (">" + sectionTitle!) : nil
//        self.tableTitle = tableTitle
//        self.tableStartSequence = tableStarter
//        self.tableEndSequence = tableEnd ?? tableEndSequence_default
//        self.rowTitle = rowTitle
//        if rowStart != nil {
//            self.rowStartSequence = (pageType == .macrotrends) ? (">" + rowStart! + "<") : rowStart!
//        } else {
//            self.rowStartSequence = (pageType == .macrotrends) ? rowStartSequence_MT_default : nil
//        }
//        self.rowEndSequence = rowEnd ?? rowEndSequence_default
//        self.numberStartSequence = numberStart
//        self.numberEndSequence = numberEnd
//        self.numberExponent = exponent
//        self.textStartSequence = textStart
//        self.textEndSequence = textEnd
//
//    }
//
//}

class WebPageScraper2: NSObject {
    
    var progressDelegate: ProgressViewDelegate?
    
    /// use this to create an instance if you don't wish to use the class functions
    init(progressDelegate: ProgressViewDelegate?) {
        self.progressDelegate = progressDelegate
    }

    /// called  by StocksController.updateStocks for non-US stocks when trying to download from MacroTrends
    class func nonUSDataDownload(symbol: String?, shortName: String?, shareID: NSManagedObjectID ,progressDelegate: ProgressViewDelegate?=nil) async {
        
        guard let valid = symbol else {
            ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "missing stock symbol")
            progressDelegate?.cancelRequested()
            return
        }
        
        guard let validSN = shortName else {
            ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "missing stock short name")
            progressDelegate?.cancelRequested()
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
        progressDelegate?.allTasks = 5
        
        Task.init {
            do {
                // download from ariva and move on after async let...
                var r1LabelledValues = [Labelled_DatedValues]()

                async let arivaHTML = Downloader.downloadDataNoThrow(url: arivaURL!)
                
                progressDelegate?.taskCompleted()
                                
//                await YahooPageScraper.dataDownloadAnalyseSave(symbol: valid, shortName: validSN, shareID: shareID, option: .rule1Only, downloadRedirectDelegate: nil)
                
//                progressDelegate?.taskCompleted()

                // find full url for company on tagesschau search page
                if let html = await Downloader.downloadDataWithRedirectionOption(url: tsURL) {
                    var tagesschauShareURLs = try TagesschauScraper.shareAddressLineTagesschau(htmlText: html)
                    if tagesschauShareURLs?.count ?? 0 > 1 {
                        tagesschauShareURLs = tagesschauShareURLs?.filter({ address in
                            if address.contains("aktie") { return true }
                            else { return false }
                        })
                    }

                    if let firstAddress = tagesschauShareURLs?.first {
                        if let url = URL(string: firstAddress) {

                            // 2 download tagesschau data webpage from full url
                            if let htmlText = await Downloader.downloadDataNoThrow(url: url) {
                                await TagesschauScraper.dataDownloadAnalyseSave(htmlText: htmlText, symbol: symbol, shareID: shareID, progressDelegate: progressDelegate)
                            }
//                            if let infoPage = await Downloader.downloadDataNoThrow(url: url) {
//                                if infoPage != "" {
//                                    if let ldvs = await TagesschauScraper.rule1DownloadAndAnalyse(htmlText: infoPage, symbol: symbol, shareID: shareID, progressDelegate: progressDelegate) {
//                                        r1LabelledValues.append(contentsOf: ldvs.sortAllElementDatedValues(dateOrder: .ascending))
//                                    }
//                                }
//                            }
                        }
                    }
                }
                progressDelegate?.taskCompleted()

                // ...continue analysing arivaHTML here
                if let arivaLDVs = await ArivaScraper.pageAnalysis(html: arivaHTML ?? "", headers: ["Bewertung"], parameters: [["KGV (Kurs/Gewinn)","Return on Investment in %"]]) {
                    
                    r1LabelledValues.append(contentsOf: arivaLDVs.sortAllElementDatedValues(dateOrder: .ascending))
                }
                progressDelegate?.taskCompleted()
                
                for i in 0..<r1LabelledValues.count {
                    if let latest = r1LabelledValues[i].datedValues.first {
                        if latest.value == 0.0 {
                            r1LabelledValues[i].datedValues = Array(r1LabelledValues[i].datedValues.dropFirst())
                        }
                    }
                }

                progressDelegate?.downloadComplete()
                
                let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
                backgroundMoc.automaticallyMergesChangesFromParent = true
                
                if let bgShare = backgroundMoc.object(with: shareID) as? Share {
                    await bgShare.mergeInDownloadedData(labelledDatedValues: r1LabelledValues)
                }
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: "DownloadEnded"), object: nil, userInfo: nil)

            } catch {
                progressDelegate?.downloadError(error: error.localizedDescription)
//                NotificationCenter.default.post(name: Notification.Name(rawValue: "DownloadEnded"), object: nil, userInfo: nil)
                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "error downloading 'Tageschau' Aktien info page")
            }
        }
    }

    /*
    class func arivaPageAnalysis(html: String, headers: [String], parameters: [[String]]) -> [Labelled_DatedValues]? {
        
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
    */
    
    /// calls Downloader function with completion handler to return csv file
    /// returns extracted [DateValue] array through Notification with name ""TBOND csv file downloaded""
    class func downloadAndAnalyseTreasuryYields(url: URL) async {
        
       let treasuryCSVHeaderTitles = ["Date","\"1 Mo\"", "\"2 Mo\"","\"3 Mo\"","\"4 Mo\"","\"6 Mo\"","\"1 Yr\"","\"2 Yr\"","\"3 Yr\"","\"5 Yr\"","\"7 Yr\"","\"10 Yr\"","\"20 Yr\"","\"30 Yr\""]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"

        do {
            if let fileURL = try await Downloader.downloadCSVFile2(url: url, symbol: "TBonds", type: "_TB") {

                if let datedValues = try await YahooPageScraper.analyseCSVFile(localURL: fileURL, expectedHeaderTitles: treasuryCSVHeaderTitles, dateFormatter: dateFormatter) {
                    
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

}
