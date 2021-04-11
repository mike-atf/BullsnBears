//
//  DCFWebDataAnalyser.swift
//  Bulls'N'Bears
//
//  Created by aDav on 20/01/2021.
//

import UIKit

class DCFWebDataAnalyser {
    
    var stock: Share
    var valuation: DCFValuation!
    var yahooPages = ["key-statistics", "financials", "balance-sheet", "cash-flow", "analysis"]
    var controller: CombinedValuationController!
    weak var progressDelegate: ProgressViewDelegate?
    var completedDownLoadTasks = 0
    var downloadTasks = 0
    var downloadErrors = [String]()
    var downloader: WebDataDownloader!
    var altDebtDownload = false
    
    init(stock: Share, controller: CombinedValuationController, pDelegate: ProgressViewDelegate) {
        self.stock = stock
        self.valuation = stock.dcfValuation
        self.controller = controller
        self.progressDelegate = pDelegate
        
        downloader = WebDataDownloader(stock: stock, delegate: self)
        downloader.yahooDownload(pageTitles: yahooPages)
        downloadTasks = yahooPages.count
    }
    
    func deallocate() {
        NotificationCenter.default.removeObserver(self)
        downloader.webView = nil
        downloader = nil
    }

}

extension DCFWebDataAnalyser: DataDownloaderDelegate {
    
    func downloadComplete(html$: String?, pageTitle: String?) {
        
        completedDownLoadTasks += 1
        
        guard let validWebCode = html$ else {
            downloadErrors.append("download complete, html string is empty")
            return
        }
        
        guard let section = pageTitle else {
            downloadErrors.append("download complete - notification did not contain section info!!")
            return
        }
                
        var result:(array: [Double]?, errors: [String])
        if section == yahooPages.first! {
// Key stats
            
            result = WebpageScraper.scrapeRowForDoubles(website: .yahoo, html$: validWebCode, rowTitle: "Market cap (intra-day)" , rowTerminal: "</tr>", numberTerminal: "</td>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.marketCap = result.array?.first ?? Double()
            
            result = WebpageScraper.scrapeRowForDoubles(website: .yahoo, html$: validWebCode, rowTitle: "Beta (5Y monthly)" , rowTerminal: "</tr>", numberTerminal: "</td>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.beta = result.array?.first ?? Double()
            
            result = WebpageScraper.scrapeRowForDoubles(website: .yahoo, html$: validWebCode, rowTitle: "Shares outstanding" , rowTerminal: "</tr>", numberTerminal: "</td>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.sharesOutstanding = result.array?.first ?? Double()
        }
        else if section == yahooPages[1] {
// Income
            result = WebpageScraper.scrapeRowForDoubles(website: .yahoo, html$: validWebCode, rowTitle: "Total revenue", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.tRevenueActual = result.array // Array(result.array?.dropFirst() ?? []) // remove TTM column

            result = WebpageScraper.scrapeRowForDoubles(website: .yahoo,html$: validWebCode, rowTitle: "Net income", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.netIncome = result.array // Array(result.array?.dropFirst() ?? [])

            result = WebpageScraper.scrapeRowForDoubles(website: .yahoo,html$: validWebCode, rowTitle: "Interest expense", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.expenseInterest = result.array?.first ?? Double()
            
            result = WebpageScraper.scrapeRowForDoubles(website: .yahoo,html$: validWebCode, rowTitle: "Income before tax", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.incomePreTax = result.array?.first ?? Double()

            result = WebpageScraper.scrapeRowForDoubles(website: .yahoo,html$: validWebCode, rowTitle: "Income tax expense", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.expenseIncomeTax = result.array?.first ?? Double()

        }
        else if section == yahooPages[2] {
// Balance sheet
            if !altDebtDownload {
                result = WebpageScraper.scrapeRowForDoubles(website: .yahoo,html$: validWebCode, rowTitle: "Current debt", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
                downloadErrors.append(contentsOf: result.errors)
                valuation.debtST = result.array?.first ?? Double()

                result = WebpageScraper.scrapeRowForDoubles(website: .yahoo,html$: validWebCode, rowTitle: "Long-term debt", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
                downloadErrors.append(contentsOf: result.errors)
                if result.errors.count > 0 {
                    downloadTasks += 1
                    
                    downloader.yahooDownloadTasks.append(section)
                    altDebtDownload = true
                }
                else {
                    valuation.debtLT = result.array?.first ?? Double()
                }
            }
            else {
                result = WebpageScraper.scrapeRowForDoubles(website: .yahoo,html$: validWebCode, rowTitle: "Total Debt", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
                downloadErrors.append(contentsOf: result.errors)
                valuation.debtLT = result.array?.first ?? Double()
                
                downloadErrors = downloadErrors.filter({ (error) -> Bool in
                    if error.contains("Long-term debt") { return false }
                    else { return true }
                })
                altDebtDownload = false
            }
        }
        else if section == yahooPages[3] {
// Cash flow
            
            result = WebpageScraper.scrapeRowForDoubles(website: .yahoo,html$: validWebCode, rowTitle: "Operating cash flow", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.tFCFo = result.array // Array(result.array?.dropFirst() ?? [])
            
            result = WebpageScraper.scrapeRowForDoubles(website: .yahoo,html$: validWebCode, rowTitle: "Capital expenditure", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.capExpend = result.array // Array(result.array?.dropFirst() ?? [])
        }
        else if section == yahooPages[4] {
// Analysis
            
            result = WebpageScraper.scrapeRowForDoubles(website: .yahoo,html$: validWebCode, sectionHeader: "Revenue estimate</span>" ,rowTitle: "Avg. Estimate", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            let a1 = result.array?.dropLast()
            let a2 = a1?.dropLast()
            valuation.tRevenuePred = Array(a2 ?? []).reversed()

            result = WebpageScraper.scrapeRowForDoubles(website: .yahoo,html$: validWebCode, sectionHeader: "Revenue estimate</span>" , rowTitle: "Sales growth (year/est)", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            let b1 = result.array?.dropLast()
            let b2 = b1?.dropLast()
            valuation.revGrowthPred = Array(b2 ?? []).reversed()
        }
        else if section == "Yahoo LT Debt" {
            
            // extra if 'Long-term debt not included in Financial > balance sheet
            // use 'Total debt' instead
            result = WebpageScraper.scrapeRowForDoubles(website: .yahoo,html$: validWebCode, rowTitle: "Total Debt", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
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
//            self.downloader = nil
            self.deallocate()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateValuationData"), object: self.downloadErrors, userInfo: nil)
            }
        }

    }
    
}
