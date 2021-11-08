//
//  WebDataDownloader.swift
//  Bulls'N'Bears
//
//  Created by aDav on 17/02/2021.
//

import UIKit
import WebKit

protocol DataDownloaderDelegate {
    func downloadComplete(html$: String?, pageTitle: String?)
}

class WebDataDownloader: NSObject, WKUIDelegate, WKNavigationDelegate {
    
    var delegate: DataDownloaderDelegate?
    var mtDownloadTasks = [String]()
    var yahooDownloadTasks = [String]()
    var macroTrendCookies: [HTTPCookie]?
    var request: URLRequest?
    var yahooSession: URLSessionTask?
    var mt_html$: String?
    var yahoo_html$: String?
    var webView: HiddenWebView?
    var stock: Share!
    var hyphenatedShortName: String?
    var errors = [String]()
    
    init(stock: Share, delegate: DataDownloaderDelegate) {
        super.init()
        
        self.stock = stock
        self.delegate = delegate
    }
    
    public func yahooDownload(pageTitles:[String]) {
        
        var components: URLComponents?
                
        guard pageTitles.count > 0 else {
            return
        }
        
        yahooDownloadTasks = pageTitles
        components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(stock.symbol)/\(pageTitles.first!)")
        components?.queryItems = [URLQueryItem(name: "p", value: stock.symbol)]
        
        yahooDownloadPage(url: components?.url, for: yahooDownloadTasks.first!)
    }
    
    public func macroTrendsDownload(pageTitles: [String]) {
        
        guard pageTitles.count > 0 else {
            return
        }
        
        guard var shortName = stock.name_short?.lowercased() else {
            alertController.showDialog(title: "Unable to load Rule 1 valuation data for \(stock.symbol)", alertMessage: "can't find a stock short name in dictionary.")
            return
        }
        
        if shortName.contains(" ") {
            shortName = shortName.replacingOccurrences(of: " ", with: "-")
        }

                     
//        let shortNameComponents = shortName.split(separator: " ")
//        hyphenatedShortName = String(shortNameComponents.first ?? "").lowercased()
//        guard hyphenatedShortName != nil && hyphenatedShortName != "" else {
//            alertController.showDialog(title: "Unable to load Rule 1 valuation data for \(stock.symbol)", alertMessage: "can't construct a stock term for the macrotrends website.")
//            return
//        }
//        
//        for index in 1..<shortNameComponents.count {
//            if !shortNameComponents[index].contains("(") {
//                hyphenatedShortName! += "-" + String(shortNameComponents[index])
//            }
//        }

        
        let webConfiguration = WKWebViewConfiguration()
        let viewFrame =  CGRect(origin: CGPoint.zero, size: CGSize(width: 2880, height: 1800))
        webView = HiddenWebView(frame: viewFrame, configuration: webConfiguration)
        webView?.uiDelegate = self
        webView?.navigationDelegate = self

        self.mtDownloadTasks = pageTitles

        macroTrendCookies = {
            
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

        loadWebView(url: nil, stockSymbol: stock.symbol, stockShortname: hyphenatedShortName!.lowercased(), section: mtDownloadTasks.first! )
    }
    
    // MARK: - WebView functions
    
    private func loadWebView(url: URL? = nil, stockSymbol: String, stockShortname: String, section: String) {
        
        if let validURL = url {
            request = URLRequest(url: validURL)
        }
        else {
            
            var components: URLComponents?
                        
            components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(stockSymbol)/\(stockShortname)/" + section)
            
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
        
        webView?.section = section
        
        if let validRequest = request {
            webView?.load(validRequest)
        }
        else {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "Invzlid download request (url \(String(describing: url)) for symbol: \(stock.symbol) with shortName \(stockShortname)")
//            mtDownloadTasks = [String]()
            self.mtDownloadCompleted(section: nil)
        }
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
                self.mt_html$ = html as? String
                let section = (webView as! HiddenWebView).section
                self.mtDownloadCompleted(section: section)

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
            
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { (cookies) in
                let appSupportDirectoryPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first
                var dataArray = [Data]()
                for cookie in cookies {
                    if let cookieData = cookie.archive() {
                        dataArray.append(cookieData)
                    }
                }

                do {
                    let fileData = try NSKeyedArchiver.archivedData(withRootObject: dataArray, requiringSecureCoding: false)
                    try fileData.write(to: URL(fileURLWithPath: appSupportDirectoryPath! + "/" + "MTCookies"))
                } catch let error {
                    ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error converting website cookies into storage object for re-use")
                }
            }
            
          }
          
          decisionHandler(.allow)
    }
    
    // MARK: - direct download functions
    
    func yahooDownloadPage(url: URL?, for section: String) {
        
        var components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(stock.symbol)/\(section)")
        components?.queryItems = [URLQueryItem(name: "p", value: stock.symbol)]

        
        guard let validURL = components?.url else {
            errors.append("Download failed - empty url")
            return
        }
        
        //backgrodun thread. Don't access NSManagedObjects properties, hence using SharePlaceholder
        yahooSession = URLSession.shared.dataTask(with: validURL) { (data, urlResponse, error) in
            
            guard error == nil else {
                self.errors.append("Download error \(error!.localizedDescription)")
                return
            }
            
            guard urlResponse != nil else {
                self.errors.append("Download failed - \(urlResponse!)")
                return
            }
            
            guard let validData = data else {
                self.errors.append("Download failed - data error")
                return
            }

            self.yahoo_html$ = String(decoding: validData, as: UTF8.self)
            self.yahooDownloadCompleted(section: section)
            
        }
        yahooSession?.resume()
    }


    // MARK: - completed download functions
    
    func mtDownloadCompleted(section: String?) {
        // is called from a background thread!
        
        guard let validSection = section else {
            DispatchQueue.main.async {
                self.delegate?.downloadComplete(html$: "", pageTitle: "")
            }
            return
        }
        
        var remove = Int()
        for i in 0..<mtDownloadTasks.count {
            if mtDownloadTasks[i] == validSection {
                remove = i
            }
        }
        if mtDownloadTasks.count > remove {
            mtDownloadTasks.remove(at: remove)
        }

        DispatchQueue.main.async {
            self.delegate?.downloadComplete(html$: self.mt_html$, pageTitle: validSection)
        }

        if let nextTask = mtDownloadTasks.first {
            loadWebView(stockSymbol: stock.symbol, stockShortname: hyphenatedShortName!.lowercased(), section: nextTask)
        }

    }
    
    func yahooDownloadCompleted(section: String) {
        // is called from a background thread!

        var remove = Int()
        for i in 0..<yahooDownloadTasks.count {
            if yahooDownloadTasks[i] == section {
                remove = i
            }
        }
        if yahooDownloadTasks.count > remove {
            yahooDownloadTasks.remove(at: remove)
        }

        DispatchQueue.main.async {
            self.delegate?.downloadComplete(html$: self.yahoo_html$, pageTitle: section)
        }
        
        if let nextTask = yahooDownloadTasks.first {
            yahooDownloadPage(url: nil, for: nextTask)
        }

    }
}
