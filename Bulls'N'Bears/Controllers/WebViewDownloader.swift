//
//  WebViewDownloader.swift
//  Bulls'N'Bears
//
//  Created by aDav on 10/03/2023.
//

import UIKit
import WebKit
import CoreData

protocol WebViewDownloadDelegate: UIViewController {
    func downloadAnalyseSaveComplete(remove view: WebViewDownloader)
}

/// for downloading from websites that require interaction/ don't download all data with URLSession
/// needs instantiation and a ViewController to add view to (temporarily)
/// must be called on MainThread
class WebViewDownloader: WKWebView, WKNavigationDelegate, WKUIDelegate {
    
    var shareID: NSManagedObjectID?
    var hostingDelegate: WebViewDownloadDelegate?
    var currency: String?

    static func newWebViewDownloader(delegate: WebViewDownloadDelegate) -> WebViewDownloader {
        
        print("creating WK downloader")
        
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        config.suppressesIncrementalRendering = true
        
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss +0000"
            return formatter
        }()
        
        let expiry$ = dateFormatter.string(from: Date().addingTimeInterval(30*24*3600))
        
        let acceptanceCookie = HTTPCookie(properties: [.path: "/", .name: "cookie-settings-v3", .version: "1", .value: "%7B%22isFunctionalCookieCategoryAccepted%22%3Atrue%2C%22isAdvertisingCookieCategoryAccepted%22%3Atrue%2C%22isTrackingCookieCategoryAccepted%22%3Atrue%2C%22isCookiePolicyAccepted%22%3Atrue%2C%22isCookiePolicyDeclined%22%3Afalse%7D", .domain: "www.boerse-frankfurt.de", .sameSitePolicy: "lax", .secure: "FALSE", .expires: "2024-03-03 14:40:56 +0000"] ) // "2024-03-03 14:40:56 +0000"
        config.websiteDataStore.httpCookieStore.setCookie(acceptanceCookie!)
        
        let frameSize = delegate.view.bounds.size
        return WebViewDownloader(frame: CGRect(origin: .zero, size: frameSize), configuration: config)
    }
    
    func downloadPage(domain: String, companyName: String, pageName: String, currency: String?,shareID: NSManagedObjectID?, in delegate: WebViewDownloadDelegate) {
        
        guard shareID != nil else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "WebView download requested for \(companyName) without valid shareID")
            return
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

        //https://www.boerse-frankfurt.de/equity/
        guard let url = WebViewDownloader.getURL(domain: domain,companyName: webname, pageName: pageName) else {
            return }
        
        self.currency = currency
        self.shareID = shareID!
        self.hostingDelegate = delegate
        hostingDelegate?.view.addSubview(self)
//        hostingDelegate?.navigationController?.view.insertSubview(self, belowSubview: hostingDelegate!.navigationController!.view)
        
        self.navigationDelegate = self
        self.uiDelegate = self
        
        let request = URLRequest(url: url)
        self.load(request)
        
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        
        if let host = navigationAction.request.url?.host {
            if host.starts(with: "www.boerse-frankfurt.de") {
                return .allow
            }
        }
        return .cancel
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        //outerHTML
        webView.evaluateJavaScript("document.documentElement.innerHTML.toString()") { [self] (result, error) in
            
            if let error = error {
                self.downloadFailed(error: error, description: nil)
            }
            if let result = result as? String {
                print("============ FraBo Webview navigation finished, text=\n\(result)")
                self.downloadComplete(html: result)
            } else {
                self.downloadFailed(error: nil, description: "downloaded non-html result \(String(describing: result))")
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "estimatedProgress" {
            print(Float(self.estimatedProgress))
            // use ProgressBar view here
        }
    }
    
    func downloadComplete(html: String?) {
        
        if let htmlText = html {
            print("received html string")
            print()
            analyseAndSave(htmlText: htmlText)
        } else {
            print("received EMPTY html string")
            print()
            hostingDelegate?.downloadAnalyseSaveComplete(remove: self)

        }
                 
    }
    
    func downloadFailed(error: Error?, description: String?) {
        print()
        print("download error received")
        if error != nil {
            print(error!)
        }
        if description != nil {
            print(description!)
        }
        hostingDelegate?.downloadAnalyseSaveComplete(remove: self)
    }
    
    func analyseAndSave(htmlText: String) {
        
        var results = [Labelled_DatedValues]()
        
        guard let startPosition = htmlText.range(of: "> Historical key data") else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "download from FraBo key data page - cant find '> Historical key data' section start' in \(htmlText)")
            return
        }
        
        guard let endPosition = htmlText.range(of: "</tr></tbody></table>", range: startPosition.upperBound..<htmlText.endIndex) else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "download from FraBo key data page - cant find '</tr></tbody></table>' as end sequence in \(htmlText)")
            return
        }

        let sections = ["Historical key data"]
        let parameters = [["Sales in mio.","Gross profit in mio.","Income tax payments in mio.","Net income / loss in mio.","Earnings per share (basic)", "Book value per share", "Cashflow per share", "P/E", "Return on equity", "Total return on Assets", "ROI"]]
        let saveNames = [["Revenue","Gross profit","income tax expense","Net income","eps - earnings per share", "Book value per share", "free cash flow per share", "pe ratio historical data", "roe - return on equity", "roa - return on assets", "roi - return on investment"]]
        
        if let lDVs = analyseFraBoKeyDataPage(htmlText: String(htmlText[startPosition.upperBound..<endPosition.lowerBound]), sections: sections, parameterNames: parameters, saveNames: saveNames, currency: self.currency ?? "no currency") {
            results.append(contentsOf: lDVs)
        }
        
        
        let finalResults = results
        
        let moc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        moc.automaticallyMergesChangesFromParent = true
        
        Task {
            if let share = moc.object(with: shareID!) as? Share {
                await share.mergeInDownloadedData(labelledDatedValues: finalResults)
                
                DispatchQueue.main.async {
                    self.hostingDelegate?.downloadAnalyseSaveComplete(remove: self)
                }
            }
        }
        
    }
    
    func analyseFraBoKeyDataPage(htmlText: String, sections: [String?], parameterNames: [[String]], saveNames: [[String]]?, currency: String) -> [Labelled_DatedValues]? {
                
        var results: [Labelled_DatedValues]?
        var resultDates: [Date]?
        let realNames = saveNames ?? parameterNames
        
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return formatter
        }()
        
        var sectionCount = 0
        var parameterCount = 0
        
        let yearTerminal = "</th>"
        let yearRowTerminal = "</tr></thead>"
        

        // 2 extract years
        if let yearRowEndPosition = htmlText.range(of: yearRowTerminal) {
            let yearRow = htmlText[htmlText.startIndex..<yearRowEndPosition.lowerBound]
            
            let yearSections = yearRow.split(separator: yearTerminal)
            for yearSection in yearSections {
                if let yearStartPosittion = yearSection.range(of: ">", options: .backwards) {
                    let year$ = yearSection[yearStartPosittion.upperBound..<yearSection.endIndex]
                    if let yearDate = dateFormatter.date(from: String(year$)) {
                        if resultDates == nil { resultDates = [yearDate] }
                        else { resultDates!.append(yearDate)}
                    }
                } else {
                    ErrorController.addInternalError(errorLocation: #function, errorInfo: "download from FraBo key data page - cant find start sequence '>' in \(yearSection) for beginning of year $")
                }            }
            
        } else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "download from FraBo key data page - can;t find end sequence \(yearRowTerminal) for row of year dates")
        }
        
        if self.currency != nil {
            // 3 ensure trading currency matches share currency
            if let currencyRowStartPosition = htmlText.range(of: ">Financial reporting currency</td>") {
                if let currencyEndPosition = htmlText.range(of: "</td>", range: currencyRowStartPosition.upperBound..<htmlText.endIndex) {
                    if let currencyStart = htmlText.range(of: ">", options: .backwards, range: currencyRowStartPosition.upperBound..<currencyEndPosition.lowerBound) {
                        let currency$ = htmlText[currencyStart.upperBound..<currencyEndPosition.lowerBound]
                        if currency$ != currency {
                            ErrorController.addInternalError(errorLocation: #function, errorInfo: "download from FraBo key data page - trading currency on page is '\(currency$)' which does NOT match the shares trading currency '\(currency)'. Abandoned data download")
                            return nil
                        }
                    }
                }
            } else {
                ErrorController.addInternalError(errorLocation: #function, errorInfo: "download from FraBo key data page - can;t find start sequence '>Financial reporting currency</td>' for row with trading currency ")
            }
        }
      
        // 4 get figures
    sectionLoop: for _ in sections {
            
//            var endPosition: Range<String.Index>?
//            if section != nil {
//                if let bodyStartPosition = htmlText.range(of: "<tbody>") {
//                    endPosition = htmlText.range(of: "</tbody></table>", range: bodyStartPosition.upperBound..<htmlText.endIndex)
//                    if endPosition != nil {
//                        pageText = String(htmlText[startPosition.upperBound..<endPosition!.lowerBound])
//                    }
//                }
//                else {
//                    ErrorController.addInternalError(errorLocation: #function, errorInfo: "frabo key data download unable to find position of '</tbody></table>' on page \(htmlText)")
//                    sectionCount += 1
//                    continue sectionLoop
//                }
//            }
        
            parameterCount = 0
        
    parameterLoop: for parameter in parameterNames[sectionCount] {
        
        var labelledDVs = Labelled_DatedValues(label: realNames[sectionCount][parameterCount], datedValues: [DatedValue]())
        
        if let parameterStartPosition = htmlText.range(of: (parameter + "</td>")) {
            
            if let rowEndPosition = htmlText.range(of: "!----></tr>", range: parameterStartPosition.upperBound..<htmlText.endIndex) {
                
                let row$ = htmlText[parameterStartPosition.upperBound..<rowEndPosition.lowerBound]
                
                let columnTexts = row$.split(separator: "</td><")
                var columnCount = 0
                for text in columnTexts {
                    if let pmStartPosition = text.range(of: ">", options: .backwards) {
                        var value$ = String(text[pmStartPosition.upperBound..<text.endIndex])
                        if ["ROI", "Total return on Assets", "Return on equity"].contains(parameter) {
                            value$ += "%"
                        } else if parameter.contains("in mio") {
                            value$ += "M"
                        }
                        let value = value$.textToNumber() ?? 0.0
                        let valueDate = (resultDates?.count ?? 0 > columnCount) ? resultDates![columnCount] : Date()
                        let dv = DatedValue(date: valueDate, value: value)
                        labelledDVs.datedValues.append(dv)
                    }
                    else {
                        ErrorController.addInternalError(errorLocation: #function, errorInfo: "mw download unable to find column value start position '>' for \(parameter) in \(text), row$ = \(row$)")
                    }
                    columnCount += 1
                }
                
            } else {
                ErrorController.addInternalError(errorLocation: #function, errorInfo: "mw download unable to find row endSequence '!----></tr>' for \(parameter)")
                parameterCount += 1
                continue parameterLoop
            }
        }
        else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "mw download unable to find row start position for '\(parameter)' in\n \(htmlText)")
        }

        if results == nil {
            results = [Labelled_DatedValues]()
        }
        results!.append(labelledDVs)
        parameterCount += 1

        }
        sectionCount += 1
    }
        
//        print("results ===============")
//        for result in results ?? [] {
//            print(result)
//        }
        
        return results
    }
    
    class func getURL(domain: String ,companyName: String, pageName: String) -> URL? {
        
        return URL(string: "\(domain)/\(companyName)/\(pageName)")! //https://www.boerse-frankfurt.de/equity
    }

}
