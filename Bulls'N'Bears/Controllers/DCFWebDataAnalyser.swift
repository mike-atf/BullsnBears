//
//  DCFWebDataAnalyser.swift
//  Bulls'N'Bears
//
//  Created by aDav on 20/01/2021.
//

import UIKit

class DCFWebDataAnalyser {
    
    var stock: Stock
    var html$: String?
    var valuation: DCFValuation!
    var yahooPages = ["key-statistics", "financials", "balance-sheet", "cash-flow", "analysis"]
    var controller: CombinedValuationController!
    weak var progressDelegate: ProgressViewDelegate?
    var completedDownLoadTasks = 0
    var downloadTasks = 0
    var yahooSession: URLSessionDataTask?
    var downloadErrors = [String]()
    
    init(stock: Stock, valuation: DCFValuation, controller: CombinedValuationController, pDelegate: ProgressViewDelegate) {
        self.stock = stock
        self.valuation = valuation
        self.controller = controller
        self.progressDelegate = pDelegate
        
        NotificationCenter.default.addObserver(self, selector: #selector(downloadCompleted(notification:)), name: Notification.Name(rawValue: "WebDataDownloadComplete"), object: nil)
        
        startDCFDataSearch(section: yahooPages.first!)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func startDCFDataSearch(section: String) {
        
        var components: URLComponents?
                
        downloadTasks = yahooPages.count
        components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(stock.symbol)/\(section)")
        components?.queryItems = [URLQueryItem(name: "p", value: stock.symbol)]
        download(url: components?.url, for: section)
    }
    
    @objc
    func downloadCompleted(notification: Notification) {
                        
        completedDownLoadTasks += 1
        
        guard let validWebCode = html$ else {
            downloadErrors.append("download complete, html string is empty")
            return
        }
        
        guard let section = notification.object as? String else {
            downloadErrors.append("download complete - notification did not contain section info!!")
            return
        }
                
        var result:(array: [Double]?, errors: [String])
        if section == yahooPages.first! {
// Key stats
            
            result = WebpageScraper.scrapeRow(website: .yahoo, html$: validWebCode, rowTitle: "Market cap (intra-day)" , rowTerminal: "</tr>", numberTerminal: "</td>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.marketCap = result.array?.first ?? Double()
            
            result = WebpageScraper.scrapeRow(website: .yahoo, html$: validWebCode, rowTitle: "Beta (5Y monthly)" , rowTerminal: "</tr>", numberTerminal: "</td>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.beta = result.array?.first ?? Double()
            
            result = WebpageScraper.scrapeRow(website: .yahoo, html$: validWebCode, rowTitle: "Shares outstanding" , rowTerminal: "</tr>", numberTerminal: "</td>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.sharesOutstanding = result.array?.first ?? Double()

            startDCFDataSearch(section: yahooPages[1])
        }
        else if section == yahooPages[1] {
// Income
            result = WebpageScraper.scrapeRow(website: .yahoo, html$: validWebCode, rowTitle: "Total revenue", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.tRevenueActual = result.array // Array(result.array?.dropFirst() ?? []) // remove TTM column

            result = WebpageScraper.scrapeRow(website: .yahoo,html$: validWebCode, rowTitle: "Net income", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.netIncome = result.array // Array(result.array?.dropFirst() ?? [])

            result = WebpageScraper.scrapeRow(website: .yahoo,html$: validWebCode, rowTitle: "Interest expense", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.expenseInterest = result.array?.first ?? Double()
            
            result = WebpageScraper.scrapeRow(website: .yahoo,html$: validWebCode, rowTitle: "Income before tax", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.incomePreTax = result.array?.first ?? Double()

            result = WebpageScraper.scrapeRow(website: .yahoo,html$: validWebCode, rowTitle: "Income tax expense", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.expenseIncomeTax = result.array?.first ?? Double()

            startDCFDataSearch(section: yahooPages[2])
        }
        else if section == yahooPages[2] {
// Balance sheet
            
            result = WebpageScraper.scrapeRow(website: .yahoo,html$: validWebCode, rowTitle: "Current debt", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.debtST = result.array?.first ?? Double()

            result = WebpageScraper.scrapeRow(website: .yahoo,html$: validWebCode, rowTitle: "Long-term debt", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            if result.errors.count > 0 {
                downloadTasks += 1
                var components = URLComponents(string: "https://finance.yahoo.com/quote/\(stock.symbol)/\(section)")
                components?.queryItems = [URLQueryItem(name: "p", value: stock.symbol)]
                download(url: components?.url, for: "Yahoo LT Debt")
            }
            else {
                valuation.debtLT = result.array?.first ?? Double()
            }
            startDCFDataSearch(section: yahooPages[3])
        }
        else if section == yahooPages[3] {
// Cash flow
            
            result = WebpageScraper.scrapeRow(website: .yahoo,html$: validWebCode, rowTitle: "Operating cash flow", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.tFCFo = result.array // Array(result.array?.dropFirst() ?? [])
            
            result = WebpageScraper.scrapeRow(website: .yahoo,html$: validWebCode, rowTitle: "Capital expenditure", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.capExpend = result.array // Array(result.array?.dropFirst() ?? [])

            startDCFDataSearch(section: yahooPages[4])
        }
        else if section == yahooPages[4] {
// Analysis
            
            result = WebpageScraper.scrapeRow(website: .yahoo,html$: validWebCode, sectionHeader: "Revenue estimate</span>" ,rowTitle: "Avg. Estimate", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            let a1 = result.array?.dropFirst()
            let a2 = a1?.dropFirst()
            valuation.tRevenuePred = Array(a2 ?? [])

            result = WebpageScraper.scrapeRow(website: .yahoo,html$: validWebCode, sectionHeader: "Revenue estimate</span>" , rowTitle: "Sales growth (year/est)", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            let b1 = result.array?.dropFirst()
            let b2 = b1?.dropFirst()
            valuation.revGrowthPred = Array(b2 ?? [])
        }
        else if section == "Yahoo LT Debt" {
            
            // extra if 'Long-term debt not included in Financial > balance sheet
            // use 'Total debt' instead
            result = WebpageScraper.scrapeRow(website: .yahoo,html$: validWebCode, rowTitle: "Total Debt", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.debtLT = result.array?.first ?? Double()
            
            downloadErrors = downloadErrors.filter({ (error) -> Bool in
                if error.contains("Long-term debt") { return false }
                else { return true }
            })
        }
        
        DispatchQueue.main.async {
            self.progressDelegate?.progressUpdate(allTasks: self.downloadTasks, completedTasks: self.completedDownLoadTasks)
        }
        
        if completedDownLoadTasks == downloadTasks {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateValuationData"), object: self.downloadErrors, userInfo: nil)
            }
        }
        
    }
    
    // Download
    func download(url: URL?, for section: String) {
        
        guard let validURL = url else {
            downloadErrors.append("Download failed - empty url")
            return
        }
        
        yahooSession = URLSession.shared.dataTask(with: validURL) { (data, urlResponse, error) in
            
            guard error == nil else {
                self.downloadErrors.append("Download error \(error!.localizedDescription)")
                return
            }
            
            guard urlResponse != nil else {
                self.downloadErrors.append("Download failed - \(urlResponse!)")
                return
            }
            
            guard let validData = data else {
                self.downloadErrors.append("Download failed - data error")
                return
            }

            self.html$ = String(decoding: validData, as: UTF8.self)
            
           NotificationCenter.default.post(name: Notification.Name(rawValue: "WebDataDownloadComplete"), object: section , userInfo: nil)
        }
        yahooSession?.resume()
    }
}
