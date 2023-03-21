//
//  WebKitLoader.swift
//  Bulls'N'Bears
//
//  Created by aDav on 03/03/2023.
//
import UIKit
import WebKit

protocol WebKitDownloadDelegate {
    func downloadComplete(htmlText: String, for job: FraBoDownloadJob)
}

class WebKitLoader: UIViewController {
    
    var webView: WKWebView!
//    var requestor: Downloader!
    var downloadDelegate: WebKitDownloadDelegate!
    var job: FraBoDownloadJob!
    
    override func loadView() {
        
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()
        let acceptanceCookie = HTTPCookie(properties: [.path: "/", .name: "cookie-settings-v3", .version: "1", .value: "%7B%22isFunctionalCookieCategoryAccepted%22%3Atrue%2C%22isAdvertisingCookieCategoryAccepted%22%3Atrue%2C%22isTrackingCookieCategoryAccepted%22%3Atrue%2C%22isCookiePolicyAccepted%22%3Atrue%2C%22isCookiePolicyDeclined%22%3Afalse%7D", .domain: "www.boerse-frankfurt.de", .sameSitePolicy: "lax", .secure: "FALSE", .expires: "2024-03-03 14:40:56 +0000"] )

        config.websiteDataStore.httpCookieStore.setCookie(acceptanceCookie!)
        
        webView = WKWebView(frame: .zero, configuration: config)
        self.view = webView
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
//
//        let userContentController = WKUserContentController()
//        userContentController.add(self, name: "Test")
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            print(Float(webView.estimatedProgress))
            // use ProgressBar view here
        }
    }
    
    public func loadURL(job: FraBoDownloadJob, delegate: WebKitDownloadDelegate) async {
                
        guard job.url != nil else {
            // deallocate
            return
        }
        
        self.job = job
        self.downloadDelegate = delegate
        let request = URLRequest(url: job.url!)
        print("loading \(job.url!)....")
        webView.load(request)
    }

    

}

extension WebKitLoader: WKNavigationDelegate, WKUIDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        
        if let host = navigationAction.request.url?.host {
            if host.starts(with: "www.boerse-frankfurt.de") {
                return .allow
            }
        }
        print("donwload disallowed for \(String(describing: navigationAction.request.url?.host))")
        return .cancel
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        print("finished loading...")
        
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { allCookies in
            print("found \(allCookies.count) cookies set")
            
        }

                        
        webView.evaluateJavaScript("document.documentElement.outerHTML.toString()") { (result, error) in
            
            if let error = error {
                print("!!!!!!!")
                print(error)
                print()
            }
            if let result = result as? String {
                print("============")
                self.downloadDelegate.downloadComplete(htmlText: result, for: self.job)
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
