//
//  R1WebDataAnalyser.swift
//  Bulls'N'Bears
//
//  Created by aDav on 30/01/2021.
//

import UIKit
import WebKit

class R1WebDataAnalyser: NSObject, WKUIDelegate, WKNavigationDelegate  {
        
    var webView: R1WebView!
    var view = UIView()
    var stock: Stock!
    var hyphenatedShortName: String?
    var html$: String?
    var valuation: Rule1Valuation!
    var controller: CombinedValuationController!
    var webpages = ["financial-statements", "financial-ratios", "balance-sheet", "pe-ratio","analysis", "cash-flow","insider-transactions"]
    weak var progressDelegate: ProgressViewDelegate?
    var request: URLRequest!
    var yahooSession: URLSessionDataTask?
    var downloadErrors = [String]()
    var downloadTasks = 0
    var downloadTasksComplete = 0
    
    var macroTrendCookies: [HTTPCookie]? = {
        
        guard let fileURL = Bundle.main.url(forResource: "MTCookies", withExtension: nil) else {
            return nil
        }
     
        if let data = FileManager.default.contents(atPath: fileURL.path) {
            do {
                if let dataArray = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [Data] {
                    var mtCookies = [HTTPCookie]()
                    for data in dataArray {
                        if let newCookie = HTTPCookie.loadCookie(using: data) {
                            mtCookies.append(newCookie)
                        }
                    }
                    return (mtCookies.count > 0) ? mtCookies : nil
                }
            } catch let error {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "can't convert stored MT cookies back to usable format.")
            }
        }
        return nil
    }()
    
    init(stock: Stock, valuation: Rule1Valuation, controller: CombinedValuationController, progressDelegate: ProgressViewDelegate) {
        
        super.init()
            
        guard let shortName = stock.name_short else {
            alertController.showDialog(title: "Unable to load Rule 1 valuation data for \(stock.symbol)", alertMessage: "can't find a stock short name in dictionary.")
            return
        }
        
        self.progressDelegate = progressDelegate
        self.stock = stock
        self.valuation = valuation
        self.controller = controller
        
        let webConfiguration = WKWebViewConfiguration()
        let viewFrame =  controller.valuationListViewController.view.frame
        webView = R1WebView(frame: viewFrame, configuration: webConfiguration)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        
        let shortNameComponents = shortName.split(separator: " ")
        hyphenatedShortName = String(shortNameComponents.first!)
        for index in 1..<shortNameComponents.count {
            hyphenatedShortName! += "-" + String(shortNameComponents[index])
        }

        guard hyphenatedShortName != nil else {
            alertController.showDialog(title: "Unable to load Rule 1 valuation data for \(stock.symbol)", alertMessage: "can't construct a stock term for the macrotrends website.")
            return
        }

        NotificationCenter.default.addObserver(self, selector: #selector(downloadCompleted(_:)), name: Notification.Name(rawValue: "WebDataDownloadComplete"), object: nil)
    
        downloadTasks = webpages.count
        loadView(section: webpages.first!)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func loadView(url: URL? = nil, section: String) {
        
        if let validURL = url {
            request = URLRequest(url: validURL)
        }
        else {
            var components: URLComponents?
                        
            components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(stock.symbol)/\(hyphenatedShortName!.lowercased())/" + section)
            
            if let validURL = components?.url {
                request = URLRequest(url: validURL)
                
    //            if let cookies = macroTrendCookies {
    //                let headers = HTTPCookie.requestHeaderFields(with: cookies)
    //                for (name, value) in headers {
    //                    request.addValue(value, forHTTPHeaderField: name)
    //                }
    //            }
                
    //            if let appSupportDirectoryPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first {
    //
    //                if let data = FileManager.default.contents(atPath: appSupportDirectoryPath + "/" + "MTCookies") {
    //
    //                    do {
    //                        if let dataArray = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [Data] {
    //                            var mtCookies = [HTTPCookie]()
    //                            for data in dataArray {
    //                                if let newCookie = HTTPCookie.loadCookie(using: data) {
    //                                    mtCookies.append(newCookie)
    //                                }
    //                            }
    //                            let headers = HTTPCookie.requestHeaderFields(with: mtCookies)
    //                            for (name, value) in headers {
    //                                request.addValue(value, forHTTPHeaderField: name)
    //                            }
    //                        }
    //                    } catch let error {
    //                        ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "can't convert stored MT cookies back to usable format.")
    //                    }
    //                }
    //            }

            }
        }
        webView.section = section
        webView.load(request)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
//        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { (cookies) in
//            let appSupportDirectoryPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first
//            var dataArray = [Data]()
//            for cookie in cookies {
//                if let cookieData = cookie.archive() {
//                    dataArray.append(cookieData)
//                }
//            }
//
//            do {
//                let fileData = try NSKeyedArchiver.archivedData(withRootObject: dataArray, requiringSecureCoding: false)
//                try fileData.write(to: URL(fileURLWithPath: appSupportDirectoryPath! + "/" + "MTCookies"))
//            } catch let error {
//                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error converting website cookies into storage object for re-use")
//            }
//        }

        webView.evaluateJavaScript("document.documentElement.outerHTML.toString()", completionHandler: { (html: Any?, error: Error?) in
            if error == nil {
                self.html$ = html as? String
                let section = (webView as! R1WebView).section
                NotificationCenter.default.post(name: Notification.Name(rawValue: "WebDataDownloadComplete"), object: section , userInfo: nil)

            }
            else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error cpaturing html string from website: \(String(describing: webView.url))")
            }
        })
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        guard let response = navigationResponse.response as? HTTPURLResponse,
            let url = navigationResponse.response.url else {
            decisionHandler(.cancel)
            return
          }

          if let headerFields = response.allHeaderFields as? [String: String] {
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
            cookies.forEach { cookie in
              webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
            }
            
//            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { (cookies) in
//                let appSupportDirectoryPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first
//                var dataArray = [Data]()
//                for cookie in cookies {
//                    if let cookieData = cookie.archive() {
//                        dataArray.append(cookieData)
//                    }
//                }
//
//                do {
//                    let fileData = try NSKeyedArchiver.archivedData(withRootObject: dataArray, requiringSecureCoding: false)
//                    try fileData.write(to: URL(fileURLWithPath: appSupportDirectoryPath! + "/" + "MTCookies"))
//                } catch let error {
//                    ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error converting website cookies into storage object for re-use")
//                }
//            }
            
          }
          
          decisionHandler(.allow)
    }
    
    @objc
    func downloadCompleted(_ notification: Notification) {
        
        downloadTasksComplete += 1
        
        guard html$ != nil else {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "download complete, html string is empty")
            return
        }
        
        guard let section = notification.object as? String else {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "download complete - notification did not contain section info!!")
            return
        }
        
        var result:(array: [Double]?, errors: [String])
        if section == webpages[0] {
            result = WebpageScraper.scrapeRow(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Revenue")
            downloadErrors.append(contentsOf: result.errors)
            valuation.revenue = result.array
            
            result = WebpageScraper.scrapeRow(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "EPS - Earnings Per Share")
            downloadErrors.append(contentsOf: result.errors)
            valuation.eps = result.array
            
            result = WebpageScraper.scrapeRow(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Net Income")
            downloadErrors.append(contentsOf: result.errors)
            if let income = result.array?.first {
                valuation.netIncome = income * pow(10, 3)
            }
            
            DispatchQueue.main.async {
                self.progressDelegate?.progressUpdate(allTasks: self.webpages.count, completedTasks: 1)
            }
            loadView(section: webpages[1])
        }
        else if section == webpages[1] {
            
            result = WebpageScraper.scrapeRow(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "ROI - Return On Investment")
            downloadErrors.append(contentsOf: result.errors)
            var roicPct = [Double]()
            for number in result.array ?? [] {
                roicPct.append(number/100)
            }
            valuation.roic = roicPct
            
            result = WebpageScraper.scrapeRow(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Book Value Per Share")
            downloadErrors.append(contentsOf: result.errors)
            valuation.bvps = result.array

            result = WebpageScraper.scrapeRow(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Operating Cash Flow Per Share")
            downloadErrors.append(contentsOf: result.errors)
            valuation.opcs = result.array

            DispatchQueue.main.async {
                self.progressDelegate?.progressUpdate(allTasks: self.webpages.count, completedTasks: 2)
            }
            loadView(section: webpages[2])
        }
        else if section == webpages[2] {
            
            result = WebpageScraper.scrapeRow(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Long Term Debt")
            downloadErrors.append(contentsOf: result.errors)
            let cleanedResult = result.array?.filter({ (element) -> Bool in
                return element != Double()
            })
            if let debt = cleanedResult?.first {
                valuation.debt = debt * 1000
            }

            DispatchQueue.main.async {
                self.progressDelegate?.progressUpdate(allTasks: self.webpages.count,completedTasks: 3)
            }
            loadView(section: webpages[3])
        }
        else if section == webpages[3] {
            
            result = WebpageScraper.scrapeColumn(html$: html$, tableHeader: "PE Ratio Historical Data</th>")
            downloadErrors.append(contentsOf: result.errors)
            if let pastPER = result.array?.sorted() {
                let withoutExtremes = pastPER.excludeQuintiles()
                valuation.hxPE = [withoutExtremes.min()!, withoutExtremes.max()!]
            }
            
            let components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(stock.symbol)/\(webpages[4])")
            webView.section = webpages[4]
            DispatchQueue.main.async {
                self.progressDelegate?.progressUpdate(allTasks: self.webpages.count,completedTasks: 4)
            }
            downloadYahoo(url: components?.url, for: webpages[4])
        }
        else if section == webpages[4] {
           
            result = WebpageScraper.scrapeRow(website: .yahoo, html$: html$, sectionHeader: "Revenue estimate</span>", rowTitle: "Sales growth (year/est)")
            downloadErrors.append(contentsOf: result.errors)
            if let validResult = result.array?.reversed() {
                var growth = [validResult.last!]
                let a = validResult.dropLast()
                growth.append(a.last!)
                
                valuation.growthEstimates = [growth.min()!, growth.max()!]
            }
            
            DispatchQueue.main.async {
                self.progressDelegate?.progressUpdate(allTasks: self.webpages.count,completedTasks: 5)
            }
            let components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(stock.symbol)/\(webpages[5])")
            webView.section = webpages[5]
            downloadYahoo(url: components?.url, for: webpages[5])
        } else if section == webpages[5] {

            result = WebpageScraper.scrapeRow(website: .yahoo, html$: html$, sectionHeader: "Cash flow</span>", rowTitle: "Operating cash flow")
            downloadErrors.append(contentsOf: result.errors)
            valuation.opCashFlow = result.array?.first ?? Double()

            DispatchQueue.main.async {
                self.progressDelegate?.progressUpdate(allTasks: self.webpages.count,completedTasks: 6)
            }
            let components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(stock.symbol)/\(webpages[6])")
            webView.section = webpages[5]
            downloadYahoo(url: components?.url, for: webpages[6])
        } else if section == webpages[6] {
            let rowTitles = ["Purchases","Sales","Total insider shares held"]
            
            for rtitle in rowTitles {
                result = WebpageScraper.scrapeRow(website: .yahoo, html$: html$, sectionHeader: "Insider purchases - Last 6 months</span>", rowTitle: rtitle, rowTerminal: "</td></tr>", numberTerminal: "</td>")
                downloadErrors.append(contentsOf: result.errors)
                if rtitle.contains("Purchases") {
                    valuation.insiderStockBuys = result.array?.last ?? Double()
                }
                if rtitle.contains("Sales") {
                    valuation.insiderStockSells = result.array?.last ?? Double()
                }
                else {
                    valuation.insiderStocks = result.array?.last ?? Double()
                }
            }

            DispatchQueue.main.async {
                self.progressDelegate?.progressUpdate(allTasks: self.downloadTasks ,completedTasks: self.downloadTasksComplete)
            }
        }
        
        if downloadTasksComplete == downloadTasks {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateValuationData"), object: self.downloadErrors , userInfo: nil)
            }
        }

    }
    
    func downloadYahoo(url: URL?, for section: String) {
        
        guard let validURL = url else {
            downloadErrors.append("DCF valuation data download failed. No website address")
            return
        }
        
        yahooSession = URLSession.shared.dataTask(with: validURL) { (data, urlResponse, error) in
            
            guard error == nil else {
                self.downloadErrors.append("Download error \(error!.localizedDescription) occurred")
                return
            }
            
            guard urlResponse != nil else {
                self.downloadErrors.append("Download error \(urlResponse!) occurred")
                return
            }
            
            guard let validData = data else {
                self.downloadErrors.append("Download error occurred: invalid website data")
                return
            }

            self.html$ = String(decoding: validData, as: UTF8.self)
            
           NotificationCenter.default.post(name: Notification.Name(rawValue: "WebDataDownloadComplete"), object: section , userInfo: nil)
        }
        yahooSession?.resume()
    }
}
