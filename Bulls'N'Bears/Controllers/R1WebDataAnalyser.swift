//
//  R1WebDataAnalyser.swift
//  Bulls'N'Bears
//
//  Created by aDav on 30/01/2021.
//

import UIKit
import WebKit

class R1WebDataAnalyser: NSObject, WKUIDelegate, WKNavigationDelegate  {
        
    var share: Share!
//    var valuation: Rule1Valuation!
    var controller: CombinedValuationController!
    var webpages = ["financial-statements", "financial-ratios", "balance-sheet", "pe-ratio","analysis", "cash-flow","insider-transactions"]
    weak var progressDelegate: ProgressViewDelegate?
    var downloadErrors = [String]()
    var downloadTasks = 0
    var downloadTasksComplete = 0
    
    var downloader: WebDataDownloader!
    
    init(stock: Share, controller: CombinedValuationController, progressDelegate: ProgressViewDelegate) {
        
        super.init()
            
        self.progressDelegate = progressDelegate
        guard stock.name_short != nil else {
            
            progressDelegate.downloadError(error: "Unable to load WB valuation data, can't find a short name in dictionary.")

            return
        }

        self.share = stock
        self.controller = controller
        
        let placeholder = SharePlaceHolder(share: share)
        
        downloader = WebDataDownloader(stock: placeholder, delegate: self)
        let macroTrendPageNames = ["financial-statements", "financial-ratios", "balance-sheet", "pe-ratio"]
        let yahooPageNames = ["analysis", "cash-flow","insider-transactions"]
        downloader.macroTrendsDownload(pageTitles: macroTrendPageNames)
        downloader.yahooDownload(pageTitles: yahooPageNames)
        downloadTasks = macroTrendPageNames.count + yahooPageNames.count
        
    }
    
    func deallocate() {
        NotificationCenter.default.removeObserver(self)
        downloader.webView = nil
        downloader = nil
    }
    
}

extension R1WebDataAnalyser: DataDownloaderDelegate {
    
    func downloadComplete(html$: String?, pageTitle: String?) {
                
        downloadTasksComplete += 1
        
        guard html$ != nil else {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "download complete, html string is empty")
            return
        }
        
        guard let section = pageTitle else {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "download complete - notification did not contain section info!!")
            return
        }
        
        var result:(array: [Double]?, errors: [String])
        if section == webpages[0] {
            result = WebpageScraper.scrapeRowForDoubles(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Revenue")
            downloadErrors.append(contentsOf: result.errors)
            share.rule1Valuation?.revenue = result.array
            
            result = WebpageScraper.scrapeRowForDoubles(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "EPS - Earnings Per Share")
            downloadErrors.append(contentsOf: result.errors)
            share.rule1Valuation?.eps = result.array
            
            result = WebpageScraper.scrapeRowForDoubles(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Net Income")
            downloadErrors.append(contentsOf: result.errors)
            if let income = result.array?.first {
                share.rule1Valuation?.netIncome = income * pow(10, 3)
            }
            
            DispatchQueue.main.async {
                self.progressDelegate?.progressUpdate(allTasks: self.downloadTasks, completedTasks: self.downloadTasksComplete)
            }
        }
        else if section == webpages[1] {
            
            result = WebpageScraper.scrapeRowForDoubles(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "ROI - Return On Investment")
            downloadErrors.append(contentsOf: result.errors)
            var roicPct = [Double]()
            for number in result.array ?? [] {
                roicPct.append(number/100)
            }
            share.rule1Valuation?.roic = roicPct
            
            result = WebpageScraper.scrapeRowForDoubles(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Book Value Per Share")
            downloadErrors.append(contentsOf: result.errors)
            share.rule1Valuation?.bvps = result.array

            result = WebpageScraper.scrapeRowForDoubles(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Operating Cash Flow Per Share")
            downloadErrors.append(contentsOf: result.errors)
            share.rule1Valuation?.opcs = result.array

            DispatchQueue.main.async {
                self.progressDelegate?.progressUpdate(allTasks: self.downloadTasks, completedTasks: self.downloadTasksComplete)
            }
        }
        else if section == webpages[2] {
            
            result = WebpageScraper.scrapeRowForDoubles(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Long Term Debt")
            downloadErrors.append(contentsOf: result.errors)
            let cleanedResult = result.array?.filter({ (element) -> Bool in
                return element != Double()
            })
            if let debt = cleanedResult?.first {
                share.rule1Valuation?.debt = debt * 1000
            }

            DispatchQueue.main.async {
                self.progressDelegate?.progressUpdate(allTasks: self.downloadTasks,completedTasks: self.downloadTasksComplete)
            }

        }
        else if section == webpages[3] {
            
            result = WebpageScraper.scrapeColumn(html$: html$, tableHeader: "PE Ratio Historical Data</th>")
            downloadErrors.append(contentsOf: result.errors)
            if let pastPER = result.array?.sorted() {
                let withoutExtremes = pastPER.excludeQuintiles()
                share.rule1Valuation?.hxPE = [withoutExtremes.min()!, withoutExtremes.max()!]
            }
            
            DispatchQueue.main.async {
                self.progressDelegate?.progressUpdate(allTasks: self.webpages.count,completedTasks: self.downloadTasksComplete)
            }
        }
        else if section == webpages[4] {
           
            result = WebpageScraper.scrapeRowForDoubles(website: .yahoo, html$: html$, sectionHeader: "Revenue estimate</span>", rowTitle: "Sales growth (year/est)")
            downloadErrors.append(contentsOf: result.errors)
            if let validResult = result.array?.reversed() {
                var growth = [validResult.last!]
                let a = validResult.dropLast()
                growth.append(a.last!)
                
                share.rule1Valuation?.growthEstimates = [growth.min()!, growth.max()!]
            }
            
            DispatchQueue.main.async {
                self.progressDelegate?.progressUpdate(allTasks: self.downloadTasks,completedTasks: self.downloadTasksComplete)
            }
        } else if section == webpages[5] {

            result = WebpageScraper.scrapeRowForDoubles(website: .yahoo, html$: html$, sectionHeader: "Cash flow</span>", rowTitle: "Operating cash flow")
            downloadErrors.append(contentsOf: result.errors)
            share.rule1Valuation?.opCashFlow = result.array?.first ?? Double()

            DispatchQueue.main.async {
                self.progressDelegate?.progressUpdate(allTasks: self.downloadTasks,completedTasks: self.downloadTasksComplete)
            }
        } else if section == webpages[6] {
            let rowTitles = ["Purchases","Sales","Total insider shares held"]
            
            for rtitle in rowTitles {
                result = WebpageScraper.scrapeRowForDoubles(website: .yahoo, html$: html$, sectionHeader: "Insider purchases - Last 6 months</span>", rowTitle: rtitle, rowTerminal: "</td></tr>", numberTerminal: "</td>")
                downloadErrors.append(contentsOf: result.errors)
                if rtitle.contains("Purchases") {
                    share.rule1Valuation?.insiderStockBuys = result.array?.last ?? Double()
                }
                if rtitle.contains("Sales") {
                    share.rule1Valuation?.insiderStockSells = result.array?.last ?? Double()
                }
                else {
                    share.rule1Valuation?.insiderStocks = result.array?.last ?? Double()
                }
            }

            DispatchQueue.main.async {
                self.progressDelegate?.progressUpdate(allTasks: self.downloadTasks ,completedTasks: self.downloadTasksComplete)
            }
        }
        
        if downloadTasksComplete == downloadTasks {
            
            self.deallocate()
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateValuationData"), object: self.downloadErrors , userInfo: nil)
            }
        }

    }
    
    
}
