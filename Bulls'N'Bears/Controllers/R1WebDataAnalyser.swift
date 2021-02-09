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
    var sectionsComplete = [Bool]()
    var progressDelegate: ProgressViewDelegate?
    var request: URLRequest!
    var yahooSession: URLSessionDataTask?
    var downloadErrors = [String]()
    
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
    
        for _ in webpages {
            sectionsComplete.append(false)
        }
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
//        sectionsComplete.append(false)
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
            
            result = WebpageScraper.scrapeRow(html$: html$, sectionHeader: nil, rowTitle: "Revenue")
            downloadErrors.append(contentsOf: result.errors)
            valuation.revenue = result.array
            
            result = WebpageScraper.scrapeRow(html$: html$, sectionHeader: nil, rowTitle: "EPS - Earnings Per Share")
            downloadErrors.append(contentsOf: result.errors)
            valuation.eps = result.array
            
            result = WebpageScraper.scrapeRow(html$: html$, sectionHeader: nil, rowTitle: "Net Income")
            downloadErrors.append(contentsOf: result.errors)
            if let income = result.array?.first {
                valuation.netIncome = income * pow(10, 3)
            }
            
            sectionsComplete[0] = true
            DispatchQueue.main.async {
                self.progressDelegate?.progressUpdate(allTasks: self.webpages.count, completedTasks: 1)
            }
            loadView(section: webpages[1])
        }
        else if section == webpages[1] {
            
            result = WebpageScraper.scrapeRow(html$: html$, sectionHeader: nil, rowTitle: "ROI - Return On Investment")
            downloadErrors.append(contentsOf: result.errors)
            var roicPct = [Double]()
            for number in result.array ?? [] {
                roicPct.append(number/100)
            }
            valuation.roic = roicPct
            
            result = WebpageScraper.scrapeRow(html$: html$, sectionHeader: nil, rowTitle: "Book Value Per Share")
            downloadErrors.append(contentsOf: result.errors)
            valuation.bvps = result.array

            result = WebpageScraper.scrapeRow(html$: html$, sectionHeader: nil, rowTitle: "Operating Cash Flow Per Share")
            downloadErrors.append(contentsOf: result.errors)
            valuation.opcs = result.array

            sectionsComplete[1] = true
            DispatchQueue.main.async {
                self.progressDelegate?.progressUpdate(allTasks: self.webpages.count, completedTasks: 2)
            }
            loadView(section: webpages[2])
        }
        else if section == webpages[2] {
            
            result = WebpageScraper.scrapeRow(html$: html$, sectionHeader: nil, rowTitle: "Long Term Debt")
            downloadErrors.append(contentsOf: result.errors)
            if let debt = result.array?.first {
                valuation.debt = debt * 1000
            }

            sectionsComplete[2] = true
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
            
            sectionsComplete[3] = true
            let components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(stock.symbol)/\(webpages[4])")
            webView.section = webpages[4]
            DispatchQueue.main.async {
                self.progressDelegate?.progressUpdate(allTasks: self.webpages.count,completedTasks: 4)
            }
            downloadYahoo(url: components?.url, for: webpages[4])
        }
        else if section == webpages[4] {
           
            result = WebpageScraper.scrapeRow(html$: html$, sectionHeader: "Revenue estimate</span>", rowTitle: ">Sales growth (year/est)</span>", rowTerminal: "</span></td></tr>", numberTerminal: "</span>")
            downloadErrors.append(contentsOf: result.errors)
            let a1 = result.array?.dropFirst()
            let a2 = a1?.dropFirst()
            
            if let growth = a2 {
                valuation.growthEstimates = [growth.min()!, growth.max()!]
            }

            sectionsComplete[4] = true
            DispatchQueue.main.async {
                self.progressDelegate?.progressUpdate(allTasks: self.webpages.count,completedTasks: 5)
            }
            let components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(stock.symbol)/\(webpages[5])")
            webView.section = webpages[5]
            downloadYahoo(url: components?.url, for: webpages[5])
        } else if section == webpages[5] {

            result = WebpageScraper.scrapeRow(html$: html$, sectionHeader: "Cash flow</span>", rowTitle: ">Operating cash flow</span>", rowTerminal: "</span></td></tr>", numberTerminal: "</span>")
            downloadErrors.append(contentsOf: result.errors)
            valuation.opCashFlow = result.array?.first ?? Double()

            sectionsComplete[5] = true
            DispatchQueue.main.async {
                self.progressDelegate?.progressUpdate(allTasks: self.webpages.count,completedTasks: 6)
            }
            let components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(stock.symbol)/\(webpages[6])")
            webView.section = webpages[5]
            downloadYahoo(url: components?.url, for: webpages[6])
        } else if section == webpages[6] {
            let rowTitles = ["Purchases</span>","Sales</span>","Total insider shares held</span>"]
            
            for rtitle in rowTitles {
                result = WebpageScraper.scrapeRow(html$: html$, sectionHeader: "Insider purchases - Last 6 months</span>", rowTitle: rtitle, rowTerminal: "</td></tr>", numberTerminal: "</td>")
                downloadErrors.append(contentsOf: result.errors)
                if rtitle.contains("Purchases") {
                    valuation.insiderStockBuys = result.array?.first ?? Double()
                }
                if rtitle.contains("Sales") {
                    valuation.insiderStockSells = result.array?.first ?? Double()
                }
                else {
                    valuation.insiderStocks = result.array?.first ?? Double()
                }
            }

            sectionsComplete[6] = true
            DispatchQueue.main.async {
                self.progressDelegate?.progressUpdate(allTasks: self.webpages.count,completedTasks: 7)
                self.progressDelegate = nil
            }
        }
        
        if !sectionsComplete.contains(false) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateValuationData"), object: self.downloadErrors , userInfo: nil)
            }
        }

    }
    
    /*
    func extractRowNumbers(keyPhrase: String, expectedNumbers: Int) -> [Double]? {
        
        let rowTitleSearch$ = ">" + keyPhrase + "</a></div></div>"
        let rowTerminal = "</div></div></div><div role=\"row\""
        let numberTerminal = "</div></div><div role=\"gridcell\""
        let tableTerminal = "</div></div></div></div></div>"
        let numberStart = ">"
        var sectionHTML$ = html$
        
        // 1 Remove leading and trailing parts of the html code
        guard sectionHTML$ != nil else {
            downloadErrors.append("Downloaded empty webpage")
            return nil
        }
        
        guard let titleIndex = sectionHTML$!.range(of: rowTitleSearch$) else {
            downloadErrors.append("Did not find section \(keyPhrase) on MT website")
            return nil
        }

        var rowEndIndex: Range<String.Index>?
        rowEndIndex = sectionHTML$!.range(of: rowTerminal,options: [NSString.CompareOptions.literal], range: titleIndex.upperBound..<sectionHTML$!.endIndex, locale: nil) ?? sectionHTML$!.range(of: tableTerminal,options: [NSString.CompareOptions.literal], range: titleIndex.upperBound..<sectionHTML$!.endIndex, locale: nil)
        
        guard rowEndIndex != nil else {
            downloadErrors.append("Did not find end of a row in section \(keyPhrase) on MT website")
            return nil
        }
        sectionHTML$ = String(sectionHTML$![titleIndex.upperBound..<rowEndIndex!.lowerBound])
        
        // Go through rows backwards to find numbers
        var valueArray = [Double]()
        for _ in 0..<expectedNumbers {
            guard let labelStartIndex = sectionHTML$!.range(of: numberStart, options: .backwards, range: nil, locale: nil) else {
                downloadErrors.append("Did not find number start in \(keyPhrase) on MT website")
                continue
            }
            let value$ = sectionHTML$![labelStartIndex.upperBound...]
            valueArray.append(Double(value$.filter("-0123456789.".contains)) ?? Double())
            
            guard let labelEndIndex = sectionHTML$!.range(of: numberTerminal, options: .backwards, range: nil, locale: nil) else {
//                downloadErrors.append("Did not find number end in \(keyPhrase) on MT website")
                continue
            }
            sectionHTML$!.removeSubrange(labelEndIndex.lowerBound...)
        }
        return valueArray.reversed()
    }
    
    func extractColumnNumbers(keyPhrase: String) -> [Double]? {
        
        let tableHeader = keyPhrase
        let tableTerminal =  "</td>\n\t\t\t\t </tr></tbody>"
        let columnTerminal = "</td>"
        let labelStart = ">"
        
        var sectionHTML$ = String(html$ ?? "")
        
        guard let titleIndex = sectionHTML$.range(of: tableHeader) else {
            downloadErrors.append("Did not find section \(keyPhrase) on MT website")
            return nil
        }

        let tableEndIndex = sectionHTML$.range(of: tableTerminal,options: [NSString.CompareOptions.literal], range: titleIndex.upperBound..<sectionHTML$.endIndex, locale: nil)
        
        guard tableEndIndex != nil else {
            downloadErrors.append("Did not find table end in section \(keyPhrase) on MT website")
            return nil
        }
        sectionHTML$ = String(sectionHTML$[titleIndex.upperBound..<tableEndIndex!.lowerBound])
        
        var rowEndIndex = sectionHTML$.range(of: columnTerminal, options: .backwards, range: nil, locale: nil)
        var valueArray = [Double]()
        var count = 0 // row has four values, we only want the last of those four
        repeat {
            let labelStartIndex = sectionHTML$.range(of: labelStart, options: .backwards, range: nil, locale: nil)
            let value$ = sectionHTML$[labelStartIndex!.upperBound...]
            
            if count%4 == 0 {
                valueArray.append(Double(value$.filter("-0123456789.".contains)) ?? Double())
            }

            rowEndIndex = sectionHTML$.range(of: columnTerminal, options: .backwards, range: nil, locale: nil)
            if rowEndIndex != nil {
                sectionHTML$.removeSubrange(rowEndIndex!.lowerBound...)
                count += 1
            }
//            else {
//                downloadErrors.append("Did not find row end in section \(keyPhrase) on MT website")
//            }
        }  while rowEndIndex != nil
        
        return valueArray
    }
    
    func extractAnalysis(sectionTitle: String, rowTitle: String, numbers: Int) -> [Double]? {

        let rowTerminal = sectionTitle.contains("Revenue") ? "</span></td></tr>" : "</span></div></div>"
        let labelTerminal = "</span>"
        let labelStart = ">"
            
        var webpage$ = String(html$ ?? "")
        
        guard let revenueSection = webpage$.range(of: sectionTitle) else {
            downloadErrors.append("Did not find section \(sectionTitle)")
            return nil
        }
        webpage$ = String(webpage$.suffix(from: revenueSection.upperBound))
                        
        guard let titleIndex = webpage$.range(of: rowTitle) else {
            downloadErrors.append("Did not find title \(rowTitle) in section \(sectionTitle) on webpage")
            return nil
        }

        guard let rowEndIndex = webpage$.range(of: rowTerminal,options: [NSString.CompareOptions.literal], range: titleIndex.upperBound..<webpage$.endIndex, locale: nil) else {
            downloadErrors.append("Did not find row end for title \(rowTitle) in section \(sectionTitle) on webpage")
            return nil
        }
        webpage$ = String(webpage$[titleIndex.upperBound..<rowEndIndex.lowerBound])

        var valueArray = [Double]()
        for _ in 0..<numbers {
            guard let labelStartIndex = webpage$.range(of: labelStart, options: .backwards, range: nil, locale: nil) else {
                downloadErrors.append("Did not find number start in \(sectionTitle) on webpage")
                continue
            }
            let value$ = webpage$[labelStartIndex.upperBound...]

            var value = Double()
            if let v = Double(value$.filter("-0123456789.".contains)) {
                if value$.last == "%" {
                    value = v / 100.0
                }
                else {
                    value = v
                }
            }
            valueArray.append(value)
            
            guard let labelEndIndex = webpage$.range(of: labelTerminal, options: .backwards, range: nil, locale: nil) else {
//                downloadErrors.append("Did not find number end in \(sectionTitle) on MT website")
                continue
            }
            webpage$.removeSubrange(labelEndIndex.lowerBound...)

        }
        return valueArray
    }
    
    func extractYahooData(sectionTitle: String, rowTitles: [String], numbers: Int) -> [String: [Double?]]? {

        let rowTerminal = sectionTitle.contains("Insider purchases") ? "</td></tr>" : "</div></div>"
        let labelTerminal = "</td>"
        let labelStart = ">"
            
        var webpage$ = String(html$ ?? "")
        
        guard let revenueSection = webpage$.range(of: sectionTitle) else {
            downloadErrors.append("Did not find section \(sectionTitle) on YahooFin")
            return nil
        }
        webpage$ = String(webpage$.suffix(from: revenueSection.upperBound))
        var valueDict = [String : [Double?]]()
        
        for rowTitle in rowTitles {
            
            var section$ = webpage$
            
            guard let titleIndex = webpage$.range(of: rowTitle) else {
                downloadErrors.append("Did not find row \(rowTitle) in section \(sectionTitle) on YahooFin")
                return nil
            }

            guard let rowEndIndex = section$.range(of: rowTerminal,options: [NSString.CompareOptions.literal], range: titleIndex.upperBound..<section$.endIndex, locale: nil) else {
                downloadErrors.append("Did not find row end of \(rowTitle) in section \(sectionTitle) on YahooFin")
                return nil
            }
            section$ = String(section$[titleIndex.upperBound..<rowEndIndex.lowerBound])

            var valueArray = [Double]()
            for _ in 0..<numbers {
                guard let labelStartIndex = section$.range(of: labelStart, options: .backwards, range: nil, locale: nil) else {
                    downloadErrors.append("Did not find number start in \(sectionTitle) on MT website")
                    continue
                }
                let value$ = section$[labelStartIndex.upperBound...]

                var value = Double()
                if let v = Double(value$.filter("-0123456789.".contains)) {
                    if value$.last == "%" {
                        value = v / 100.0
                    }
                    else if case value$.first = Character("(") {
                        value = v * -1
                    } else if value$.uppercased().last == "T" {
                        value = v * pow(10.0, 12) // should be 12 but values are entered as '000
                    } else if value$.uppercased().last == "B" {
                        value = v * pow(10.0, 9) // should be 9 but values are entered as '000
                    }
                    else if value$.uppercased().last == "M" {
                        value = v * pow(10.0, 6) // should be 6 but values are entered as '000
                    }
                    else if value$.uppercased().last == "K" {
                        value = v * pow(10.0, 3) // should be 6 but values are entered as '000
                    } else {
                        value = v
                    }
                }
                valueArray.append(value)
                
                guard let labelEndIndex = section$.range(of: labelTerminal, options: .backwards, range: nil, locale: nil) else {
//                    downloadErrors.append("Did not find number end in \(sectionTitle) on MT website")
                    continue
                }
                section$.removeSubrange(labelEndIndex.lowerBound...)

            }
            valueDict[rowTitle] = valueArray.reversed()
        }
                        
        return valueDict
    }
    */
    
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
