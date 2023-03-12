//
//  FraBoScraper.swift
//  Bulls'N'Bears
//
//  Created by aDav on 02/03/2023.
//

import UIKit
import CoreData
import WebKit



//https://www.boerse-frankfurt.de/equity/aixtron-se/key-data

protocol FraBoDownloadDelegate : AnyObject, WKNavigationDelegate, WKUIDelegate {
    var hostViewController: StocksListTVC { get set }
    var hiddenDownloadView: WKWebView? { get set }
    var instantiatedScraper: FraBoScraper? { get set }
}

let fraboDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy"
    return formatter
}()

class FraBoScraper: NSObject {
    
    var symbol: String!
    var companyName: String!
    var exchange: String!
    var currency: String!
    var shareID: NSManagedObjectID!
    var option: DownloadOptions!
    var progressDelegate: ProgressViewDelegate?
    var webView: WKWebView!
    var downloadDelegate: FraBoDownloadDelegate?
    var downloadJobs: [FraBoDownloadJob]?
    
    /*
    override init() {

        super.init()
        
//        let config = WKWebViewConfiguration()
//        config.websiteDataStore = WKWebsiteDataStore.nonPersistent()
//        config.suppressesIncrementalRendering = true
//
//        let acceptanceCookie = HTTPCookie(properties: [.path: "/", .name: "cookie-settings-v3", .version: "1", .value: "%7B%22isFunctionalCookieCategoryAccepted%22%3Atrue%2C%22isAdvertisingCookieCategoryAccepted%22%3Atrue%2C%22isTrackingCookieCategoryAccepted%22%3Atrue%2C%22isCookiePolicyAccepted%22%3Atrue%2C%22isCookiePolicyDeclined%22%3Afalse%7D", .domain: "www.boerse-frankfurt.de", .sameSitePolicy: "lax", .secure: "FALSE", .expires: "2024-03-03 14:40:56 +0000"] )
//
//        config.websiteDataStore.httpCookieStore.setCookie(acceptanceCookie!)
//        webView = WKWebView(frame: .zero, configuration: config)
//        webView.backgroundColor = UIColor.systemBlue
    }
    */
    
    /*
    class func dataDownloadAnalyseSave(symbol: String, companyName: String ,exchange: String, currency: String ,shareID: NSManagedObjectID, option: DownloadOptions, progressDelegate: ProgressViewDelegate?=nil) async {
        
        guard let jobs = fraBoDownloadJobs(symbol: symbol, companyName: companyName ,option: option) else {
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
            print(htmlText)
            print("==============")
            
            if let lDVs = analyseFraBoPage(htmlText: htmlText, sections: job.tableTitles, parameterNames: job.rowTitles, saveNames: job.saveTitles) {
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
    */
    
    class func fraBoDownloadJobs(symbol: String, companyName: String ,option: DownloadOptions) -> [FraBoDownloadJob]? {
        
        var pageNames = [String]()
        var sectionNames = [[String?]]()
        var rowNames = [[[String]]]()
        var saveNames = [[[String]]]()
        
        switch option {
            
        case .allPossible:
            pageNames = ["key-data"]
            sectionNames = [["Historical key data"]]
            rowNames = [[["Sales in mio.","Gross profit in mio.","Income tax payments in mio.","Net income / loss in mio.","Earnings per share (basic)", "Book value per share", "Cashflow per share", "P/E", "Return on equity", "Total return on Assets", "ROI"]]]
            saveNames = [[["Revenue","Gross profit","income tax expense","Net income","eps - earnings per share", "Book value per share", "free cash flow per share", "pe ratio historical data", "roe - return on equity", "roa - return on assets", "roi - return on investment"]]]
            
        default:
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "unknown marketwatch download job requested \(option)")
            return nil
        }
        
        var jobs = [FraBoDownloadJob]()
        var count = 0
        for name in pageNames {
            if let newJob = FraBoDownloadJob(symbol: symbol, companyName: companyName, pageName: name, tableTitles: sectionNames[count], rowTitles: rowNames[count], saveTitles: saveNames[count]) {
                jobs.append(newJob)
                print(newJob)
            }
            count += 1
        }
        
        return jobs
    }
    
    class func fromURLToJob(url: URL, scraper: FraBoScraper) -> FraBoDownloadJob? {
        
        guard let lastPathComponent = url.pathComponents.last else {
            return nil
        }
        
        let companyWebName = url.pathComponents[url.pathComponents.count-2]
        
        if lastPathComponent == "key-data" {
            
            guard let existingJobsForPage = scraper.downloadJobs?.filter({ job in
                if (job.url?.lastPathComponent ?? "") == lastPathComponent { return true }
                else { return false }
            }) else { return nil }
            
            let companyJob = existingJobsForPage.filter({ job in
                if (job.url?.pathComponents[url.pathComponents.count-2] ?? "noWebName") == companyWebName { return true }
                else { return false }
            }).first
            
            return companyJob
        }
        
        return nil
    }
    
    class func fraboPricesDownloadAnalyseSave(symbol: String, shortName: String, shareID: NSManagedObjectID, option: DownloadOptions, progressDelegate: ProgressViewDelegate?=nil) {
        
        var components = URLComponents(string: "https://www.marketwatch.com/investing/stock/\(symbol)/downloaddatapartial")
        
        let start$ = mwDateFormatter.string(from: DatesManager.beginningOfDay(of: Date().addingTimeInterval(-365*24*3600)))
        let end$ = mwDateFormatter.string(from: DatesManager.endOfDay(of: Date()))
        components?.queryItems = [URLQueryItem(name: "startdate", value: start$), URLQueryItem(name: "enddate", value: end$), URLQueryItem(name: "daterange", value: "d365")]
        
        guard let url = components?.url else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "url generation error for marketwatch prices download for \(symbol)")
            return
        }
    }
    
    class func analyseFraBoPage(htmlText: String, sections: [String?], parameterNames: [[String]], saveNames: [[String]]?) -> [Labelled_DatedValues]? {
        
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
        
        print(htmlText)
        
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
    
    func downloadWithWebView(symbol: String, companyName: String ,exchange: String, currency: String ,shareID: NSManagedObjectID, option: DownloadOptions, progressDelegate: ProgressViewDelegate?=nil, downloadDelegate: FraBoDownloadDelegate) {
        
        guard let jobs = FraBoScraper.fraBoDownloadJobs(symbol: symbol, companyName: companyName, option: option) else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "marketwatch download \(String(describing: self.option)) for \(String(describing: self.symbol)) failed due to download jobs not created")
            return
        }
        self.downloadJobs = jobs
        self.symbol = symbol
        self.companyName = companyName
        self.exchange = exchange
        self.currency = currency
        self.shareID = shareID
        self.option = option
        self.progressDelegate = progressDelegate
        self.downloadDelegate = downloadDelegate
        self.downloadDelegate?.instantiatedScraper = self
        
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        config.suppressesIncrementalRendering = true
        
        // TODO: - dapat the expires date to always be in the future
        let acceptanceCookie = HTTPCookie(properties: [.path: "/", .name: "cookie-settings-v3", .version: "1", .value: "%7B%22isFunctionalCookieCategoryAccepted%22%3Atrue%2C%22isAdvertisingCookieCategoryAccepted%22%3Atrue%2C%22isTrackingCookieCategoryAccepted%22%3Atrue%2C%22isCookiePolicyAccepted%22%3Atrue%2C%22isCookiePolicyDeclined%22%3Afalse%7D", .domain: "www.boerse-frankfurt.de", .sameSitePolicy: "lax", .secure: "FALSE", .expires: "2024-03-03 14:40:56 +0000"] )

        config.websiteDataStore.httpCookieStore.setCookie(acceptanceCookie!)
        self.downloadDelegate?.hiddenDownloadView = WKWebView(frame: CGRect(origin: .zero, size: self.downloadDelegate?.hostViewController.view.frame.size ?? CGSize(width: 1920, height: 1280)), configuration: config)
        
        // TODO: invisible but blocks TVC touches! Push behind TVC if possible
        self.downloadDelegate?.hiddenDownloadView?.alpha = 0.0
        
//        self.downloadDelegate?.hiddenDownloadView?.navigationDelegate = downloadDelegate.hostViewController
//        self.downloadDelegate?.hiddenDownloadView?.uiDelegate = downloadDelegate.hostViewController
//        self.downloadDelegate?.hiddenDownloadView?.addObserver(downloadDelegate.hostViewController, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)

        for job in jobs {

            if let url = job.url {
                let request = URLRequest(url: url)
                self.downloadDelegate?.hiddenDownloadView?.load(request)
                print("loading....")
            }

                //resumes after download to delegate's WKNavigationDelegate functions
        }
    }

    
    class func analyseAndSave(htmlText: String, job: FraBoDownloadJob, shareID: NSManagedObjectID?) {
        
        var results = [Labelled_DatedValues]()
        
//        guard FraBoScraper.checkCompatibility(htmlText: htmlText, exchange: self.exchange, currency: self.currency) else {
//            print(htmlText)
//            return
//        }
        
        guard shareID != nil else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "FraBo Controller has received class func request  \(job) to analyse and save html, without receiving a shareID to save results to")
            return
        }
        
        print("++++++++++++++")
        print(htmlText)
        print("==============")
        
        if let lDVs = FraBoScraper.analyseFraBoPage(htmlText: htmlText, sections: job.tableTitles, parameterNames: job.rowTitles, saveNames: job.saveTitles) {
            results.append(contentsOf: lDVs)
        }
        
        
//        self.progressDelegate?.taskCompleted()
        let finalResults = results
        
        Task {
            let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
            backgroundMoc.automaticallyMergesChangesFromParent = true
            
            if let bgShare = backgroundMoc.object(with: shareID!) as? Share {
                await bgShare.mergeInDownloadedData(labelledDatedValues: finalResults)
            }
        }
        
    }

    
}

struct FraBoDownloadJob {
    
    var pageName = String()
    var tableTitles = [String?]()
    var rowTitles = [[String]]()
    var saveTitles = [[String]]()
    var url: URL?
    
    init?(symbol: String, companyName: String ,pageName: String, tableTitles: [String?], rowTitles: [[String]], saveTitles: [[String]]?=nil) {
        
        guard tableTitles.count == rowTitles.count else {
            ErrorController.addInternalError(errorLocation: "FrBoJobs struct", errorInfo: "mismatch between tables to download \(tableTitles) and rowTitle groups \(rowTitles)")
            return nil
        }
        
        let nameParts = companyName.split(separator: " ")
        var webname = String()
        var count = 0
        for namePart in nameParts {
            webname += namePart.lowercased()
            if count > 0 {
                break
            }
            webname += "-"
            count += 1
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
        
        let components = URLComponents(string: "https://www.boerse-frankfurt.de/equity/\(webname)/key-data")
        self.url = components?.url
        
    }
}
