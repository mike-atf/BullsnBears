//
//  MWScraper.swift
//  Bulls'N'Bears
//
//  Created by aDav on 01/03/2023.
//

import UIKit
import CoreData

let mwDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM/dd/yy"
    formatter.timeStyle = .long
    return formatter
}()

class MWScraper {
    
    class func dataDownloadAnalyseSave(symbol: String, exchange: String, currency: String ,shareID: NSManagedObjectID, option: DownloadOptions, progressDelegate: ProgressViewDelegate?=nil) async {
        
        guard let jobs = mwDownloadJobs(symbol: symbol, option: option) else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "marketwatch download \(option) for \(symbol) failed due to download jobs not created")
            return
        }
        
        var results = [Labelled_DatedValues]()
        
        for job in jobs {
            
            print("______________")
            print(job.url!)
            
            guard let htmlText = await Downloader.downloadDataWithRedirectionOption(url: job.url) else {
                ErrorController.addInternalError(errorLocation: #function, errorInfo: "marketwatch download \(option) for \(symbol) at \(String(describing: job.url)) failed due to empty web page /error")
                return
            }
            
            guard checkCompatibility(htmlText: htmlText, exchange: exchange, currency: currency) else {
                print(htmlText)
                return
            }
            
            print("++++++++++++++")
//            print(htmlText)
//            print("==============")
            
            if let lDVs = analyseMWPage(htmlText: htmlText, sections: job.tableTitles, parameterNames: job.rowTitles, saveNames: job.saveTitles) {
                results.append(contentsOf: lDVs)
            }
            
            
            progressDelegate?.taskCompleted()
        }
        
        let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc.automaticallyMergesChangesFromParent = true
        
        if let bgShare = backgroundMoc.object(with: shareID) as? Share {
            await bgShare.mergeInDownloadedData(labelledDatedValues: results)
        }

        
    }
    
    class func mwDownloadJobs(symbol: String, option: DownloadOptions) -> [MWDownloadJob]? {
        
        var pageNames = [String]()
        var sectionNames = [[String?]]()
        var rowNames = [[[String]]]()
        var saveNames = [[[String]]]()
        guard let symbolPreDot = symbol.components(separatedBy: ".").first else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "marketwatch download job requested for \(symbol) with \(option) can't extract pre-.part")
            return nil
        }
        
        switch option {
            
        case .allPossible:
            pageNames = ["company-profile"] // "" for 'overview', "financials"
            sectionNames = [["Profitability", "Liquidity"]]
            rowNames = [[["Return on Equity", "Return on Assets", "Return on Invested Capital"],["Current Ratio", "Quick Ratio"]]]
            saveNames = [[["roe - return on equity", "roa - return on assets", "roi - return on investment"],["Current Ratio", "Quick Ratio"]]]
            
        default:
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "unknown marketwatch download job requested \(option)")
            return nil
        }
        
        var jobs = [MWDownloadJob]()
        var count = 0
        for name in pageNames {
            if let newJob = MWDownloadJob(symbol: symbolPreDot, pageName: name, tableTitles: sectionNames[count], rowTitles: rowNames[count], saveTitles: saveNames[count]) {
                jobs.append(newJob)
                print(newJob)
            }
            count += 1
        }
        
        return jobs
    }
    
    class func mwPricesDownloadAnalyseSave(symbol: String, shortName: String, shareID: NSManagedObjectID, option: DownloadOptions, progressDelegate: ProgressViewDelegate?=nil) {
        
        var components = URLComponents(string: "https://www.marketwatch.com/investing/stock/\(symbol)/downloaddatapartial")
        
        let start$ = mwDateFormatter.string(from: DatesManager.beginningOfDay(of: Date().addingTimeInterval(-365*24*3600)))
        let end$ = mwDateFormatter.string(from: DatesManager.endOfDay(of: Date()))
        components?.queryItems = [URLQueryItem(name: "startdate", value: start$), URLQueryItem(name: "enddate", value: end$), URLQueryItem(name: "daterange", value: "d365")]
        
        guard let url = components?.url else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "url generation error for marketwatch prices download for \(symbol)")
            return
        }
    }
    
    class func analyseMWPage(htmlText: String, sections: [String?], parameterNames: [[String]], saveNames: [[String]]?) -> [Labelled_DatedValues]? {
        
        var results: [Labelled_DatedValues]?
        var pageText = htmlText
        var realNames = saveNames ?? parameterNames
        
        var sectionCount = 0
        var parameterCount = 0
    sectionLoop: for section in sections {
            
            var startPosition: Range<String.Index>?
            var endPosition: Range<String.Index>?
            if section != nil {
                startPosition = htmlText.range(of: section!)
                if startPosition != nil {
                    startPosition = htmlText.range(of: "<tbody>", range: startPosition!.upperBound..<htmlText.endIndex)
                    endPosition = htmlText.range(of: "</tbody>", range: startPosition!.upperBound..<htmlText.endIndex)
                    if endPosition != nil {
                        pageText = String(htmlText[startPosition!.upperBound..<endPosition!.lowerBound])
                    }
                }
            }
            parameterCount = 0
    parameterLoop: for parameter in parameterNames[sectionCount] {
                
                startPosition = pageText.range(of: parameter)
                guard startPosition != nil else {
                    ErrorController.addInternalError(errorLocation: #function, errorInfo: "mw download unable to find startSequence for \(parameter)")
                    continue parameterLoop
                }
        
                endPosition = pageText.range(of: "</td>", range: startPosition!.upperBound..<pageText.endIndex)
                guard endPosition != nil else {
                    ErrorController.addInternalError(errorLocation: #function, errorInfo: "mw download unable to find endSequence for \(parameter)")
                    print(pageText)
                    continue parameterLoop
                }
        
                guard let numberStart = pageText.range(of: ">",options:. backwards ,range: startPosition!.upperBound..<endPosition!.lowerBound) else {
                    ErrorController.addInternalError(errorLocation: #function, errorInfo: "mw download unable to find endSequence for \(parameter)")
                    continue parameterLoop
                }
        
                let rowContent = String(pageText[numberStart.upperBound..<endPosition!.lowerBound])
                if let number = rowContent.textToNumber() {
                    
                    let newLDV = Labelled_DatedValues(label: realNames[sectionCount][parameterCount], datedValues: [DatedValue(date: Date(), value: number)])
                    if results == nil { results = [Labelled_DatedValues]() }
                    results?.append(newLDV)
                }
                parameterCount += 1
            }
            
            sectionCount += 1
        }
        
        return results
    }
    
    class func checkCompatibility(htmlText: String, exchange: String, currency: String) -> Bool {
        
        guard let headStartPosition = htmlText.range(of: "parsely-tags") else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "mwPage compatibility check exchange \(exchange), currency \(currency) failed, cant find 'parsely-tags'")
            return false
        }
        
        guard let headEndPosition = htmlText.range(of: "exchangeTimezone", range: headStartPosition.upperBound..<htmlText.endIndex) else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "mwPage compatibility check exchange \(exchange), currency \(currency) failed, cant find 'MarketWatch</title>'")
            return false
        }
        
        var count = 0
        let cleanedExchange = exchange.replacingOccurrences(of: " ", with: "").capitalized
        let cleanedCurrency = currency.replacingOccurrences(of: " ", with: "")
        for checkText in [cleanedExchange, cleanedCurrency] {
            
            let search = ["exchange", "priceCurrency"][count]
            
            guard let exPos = htmlText.range(of: search, range: headStartPosition.upperBound..<headEndPosition.lowerBound) else {
                ErrorController.addInternalError(errorLocation: #function, errorInfo: "mwPage compatibility check '\(search)' not found on page")
                return false
            }
            
            guard let lineEnd = htmlText.range(of: "/>",range:exPos.upperBound..<headEndPosition.lowerBound) else {
                ErrorController.addInternalError(errorLocation: #function, errorInfo: "mwPage compatibility check '/>' line end of exchange not found on page")
                return false
            }
            
            let lineContent = String(htmlText[exPos.upperBound..<lineEnd.lowerBound])
//            let cleaned = lineContent.filter { char in
//                if ("-0123456789.&#;:=\"".contains(char)) { return false }
//                else { return true }
//            }
            
            guard lineContent.contains(checkText) else {
                ErrorController.addInternalError(errorLocation: #function, errorInfo: "mwPage compatibility check  |\(checkText)| not found on page - page data may relate to other exchange")
                return false
            }
            
//            guard htmlText.range(of: "priceCurrency", range: headStartPosition.upperBound..<headEndPosition.lowerBound) != nil else {
//                ErrorController.addInternalError(errorLocation: #function, errorInfo: "mwPage compatibility check \(search) \(currency) not found on page - page data may have other currency")
//                print(htmlText[headStartPosition.upperBound..<headEndPosition.lowerBound])
//                return false
//            }
            
            count += 1
        }

        return true
    }
    
}

struct MWDownloadJob {
    var pageName = String()
    var tableTitles = [String?]()
    var rowTitles = [[String]]()
    var saveTitles = [[String]]()
    var url: URL?
    
    init?(symbol: String, pageName: String, tableTitles: [String?], rowTitles: [[String]], saveTitles: [[String]]?=nil) {
        
        guard tableTitles.count == rowTitles.count else {
            ErrorController.addInternalError(errorLocation: "YahooDownloadJobs struct", errorInfo: "mismatch between tables to download \(tableTitles) and rowTitle groups \(rowTitles)")
            return nil
        }
        
        self.pageName = pageName
        
        var sectionCount = 0
        for title in tableTitles {
            if title != nil {
                self.tableTitles.append(">\(title!)</span>")
            } else {
                self.tableTitles.append(title)
            }
            
            var new = [String]()
            for parameter in rowTitles[sectionCount] {
                new.append(">\(parameter)</td>")
            }
            self.rowTitles.append(new)

            sectionCount += 1
        }
        
        self.saveTitles = saveTitles ?? rowTitles
        
        var components = URLComponents(string: "https://www.marketwatch.com/investing/stock/\(symbol)/\(pageName)")
//        components?.queryItems = [URLQueryItem(name: "p", value: symbol)]
        self.url = components?.url
        
    }
}

