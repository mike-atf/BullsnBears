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
    var sectionsComplete = [Bool]()
    var progressDelegate: ProgressViewDelegate?
    var completedDownLoadTasks = 0
    var yahooSession: URLSessionDataTask?
    var downloadErrors = [String]()
    
    init(stock: Stock, valuation: DCFValuation, controller: CombinedValuationController, pDelegate: ProgressViewDelegate) {
        self.stock = stock
        self.valuation = valuation
        self.controller = controller
        self.progressDelegate = pDelegate
        
        startDCFDataSearch()
        
        NotificationCenter.default.addObserver(self, selector: #selector(downloadCompleted(notification:)), name: Notification.Name(rawValue: "WebDataDownloadComplete"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func startDCFDataSearch() {
        
        var components: URLComponents?
                
        for section in yahooPages {
            sectionsComplete.append(false)
            components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(stock.symbol)/\(section)")
            components?.queryItems = [URLQueryItem(name: "p", value: stock.symbol)]
            download(url: components?.url, for: section)
        }
    }
    
    @objc
    func downloadCompleted(notification: Notification) {
                        
        guard let validWebCode = html$ else {
//            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "download complete, html string is empty")
            downloadErrors.append("download complete, html string is empty")
            return
        }
        
        guard let section = notification.object as? String else {
//            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "download complete - notification did not contain section info!!")
            downloadErrors.append("download complete - notification did not contain section info!!")
            return
        }
        
        completedDownLoadTasks += 1
        
        if section == yahooPages.first! {
            let stats = keyStats(validWebCode)
            valuation.beta = stats[1]
            valuation.marketCap = stats[0]
            valuation.sharesOutstanding = stats[2]
            sectionsComplete[0] = true
        }
        else if section == yahooPages[1] {
            let stats = incomeStats(validWebCode)
            valuation.tRevenueActual = stats[">Total revenue</span>"]
            valuation.netIncome = stats[">Net income</span>"]
            valuation.expenseInterest = stats[">Interest expense</span>"]?.first ?? Double()
            valuation.incomePreTax = stats[">Income before tax</span>"]?.first ?? Double()
            valuation.expenseIncomeTax = stats[">Income tax expense</span>"]?.first ?? Double()
            sectionsComplete[1] = true
        }
        else if section == yahooPages[2] {
            let stats = balanceSheet(validWebCode)
            valuation.debtST = stats[">Current debt</span>"]?.first ?? Double()
            valuation.debtLT = stats[">Long-term debt</span>"]?.first ?? Double()
            sectionsComplete[2] = true
        }
        else if section == yahooPages[3] {
            let stats = cashFlow(validWebCode)
            valuation.tFCFo = stats[">Operating cash flow</span>"]
            valuation.capExpend = stats[">Capital expenditure</span>"]
            sectionsComplete[3] = true
        }
        else if section == yahooPages[4] {
            let stats = analysis(validWebCode)
            valuation.tRevenuePred = stats[">Avg. Estimate</span>"] ?? [Double]()
            valuation.revGrowthPred = stats[">Sales growth (year/est)</span>"]
            sectionsComplete[4] = true
        }
        
        DispatchQueue.main.async {
            self.progressDelegate?.progressUpdate(allTasks: self.yahooPages.count, completedTasks: self.completedDownLoadTasks)
        }
        
        if !sectionsComplete.contains(false) {
            DispatchQueue.main.async {
                self.completedDownLoadTasks = 0
                self.progressDelegate = nil
                NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateValuationData"), object: self.downloadErrors, userInfo: nil)
            }
        }
        
    }
    
    func keyStats(_ validWebCode: String) -> [Double] {
        
        var keyStatValues = [Double]()
        var count = -1 // !!
        for search$ in [">Market cap (intra-day)</span>", ">Beta (5Y monthly)</span>", ">Shares outstanding</span>"] {
            keyStatValues.append(Double())
            count += 1
            
            var webpage$ = String(validWebCode)
                            
            guard let index1 = webpage$.range(of: search$) else {
                downloadErrors.append("can't find \(search$) on webpage")
                continue
            }

            guard let index3 = webpage$.range(of: "</tr>",options: [NSString.CompareOptions.literal], range: index1.upperBound..<webpage$.endIndex, locale: nil) else {
                downloadErrors.append("can't find row in \(search$) on webpage")
                continue
            }
            
            webpage$ = String(webpage$[index1.upperBound..<index3.lowerBound])
            guard let index4 = webpage$.range(of: "</td>", options: .backwards, range: nil, locale: nil) else {
                downloadErrors.append("can't find rown end in \(search$) on webpage")
                continue
            }
            webpage$.removeSubrange(index4.lowerBound...)

            guard let index5 = webpage$.range(of: ">", options: .backwards, range: nil, locale: nil) else {
                downloadErrors.append("can't find nu ber start in \(search$) on webpage")
                continue
            }
            
            webpage$ = String(webpage$[index5.upperBound...])
                            
            let value$ = webpage$
            
            let numbers = value$.filter("-0123456789.".contains)
            
            var value = Double()
            if let v = Double(numbers) {
                if value$.last == "T" {
                    value = v * pow(10.0, 9) // should be 12 but values are entered as '000
                } else if value$.last == "B" {
                    value = v * pow(10.0, 6) // should be 9 but values are entered as '000
                }
                else if value$.last == "M" {
                    value = v * pow(10.0, 3) // should be 6 but values are entered as '000
                }
                else if !search$.contains("Beta") {
                    value = v * pow(10.0, 3)
                }
                else {
                    value = v
                }
            }
            keyStatValues[count] = value
            
        }
        return keyStatValues
    }
    
    func incomeStats(_ validWebCode: String) -> [String:[Double]] {
        
        let rowTerminal = "</span></div></div>"
        let labelTerminal = "</span></div>"
        let labelStart = ">"
        
        var incomeValues = [String:[Double]]()
        var count = -1 // !!
        
        for search$ in [">Total revenue</span>", ">Net income</span>", ">Interest expense</span>", ">Income before tax</span>",">Income tax expense</span>"] {
            count += 1
            incomeValues[search$] = [Double]()

            var webpage$ = String(validWebCode)
                            
            guard let titleIndex = webpage$.range(of: search$) else {
                downloadErrors.append("can't find \(search$) on webpage")
                continue
            }

            guard let rowEndIndex = webpage$.range(of: rowTerminal,options: [NSString.CompareOptions.literal], range: titleIndex.upperBound..<webpage$.endIndex, locale: nil) else {
                downloadErrors.append("can't find end of row in \(search$) on webpage")
                continue
            }
            webpage$ = String(webpage$[titleIndex.upperBound..<rowEndIndex.lowerBound])
            
            if count < 2 {
                var valueArray = [Double]()
                for i in 0..<4 {
                    valueArray.append(Double())

                    guard let labelStartIndex = webpage$.range(of: labelStart, options: .backwards, range: nil, locale: nil) else {
                        downloadErrors.append("can't find start of number in \(search$) on webpage")
                        continue
                    }
                    let value$ = webpage$[labelStartIndex.upperBound...]
                    valueArray[i] = Double(value$.filter("-0123456789.".contains)) ?? Double()
                    
                    guard let labelEndIndex = webpage$.range(of: labelTerminal, options: .backwards, range: nil, locale: nil) else {
                        downloadErrors.append("can't find end of number in \(search$) on webpage")
                        continue
                    }
                    webpage$.removeSubrange(labelEndIndex.lowerBound...)

                }
                incomeValues[search$] = valueArray.reversed()
            }
            else {
                for _ in 0..<4 {

                    guard let labelStartIndex = webpage$.range(of: labelStart, options: .backwards, range: nil, locale: nil) else {
                        downloadErrors.append("can't find start of number in \(search$) on webpage")
                        continue
                    }
                    let value$ = webpage$[labelStartIndex.upperBound...]
                    incomeValues[search$] = [Double(value$.filter("-0123456789.".contains)) ?? Double()]
                    
                    guard let labelEndIndex = webpage$.range(of: labelTerminal, options: .backwards, range: nil, locale: nil) else {
                        downloadErrors.append("can't find end of number in \(search$) on webpage")
                        continue
                    }
                    webpage$.removeSubrange(labelEndIndex.lowerBound...)
                }
            }
        }
        
        return incomeValues
    }
    
    func balanceSheet(_ validWebCode: String) -> [String:[Double]] {
        
        let rowTerminal = "</span></div></div>"
        let labelTerminal = "</span></div>"
        let labelStart = ">"
        
        var debtValues = [String:[Double]]()
        
        for search$ in [">Current debt</span>", ">Long-term debt</span>"] {
            
            var webpage$ = String(validWebCode)
            debtValues[search$] = [0.0] // use default 0, assuming that if no current or long-term is listed this means 0 debt
                            
            guard let titleIndex = webpage$.range(of: search$) else {
                downloadErrors.append("can't find \(search$) on webpage")
                continue
            }

            guard let rowEndIndex = webpage$.range(of: rowTerminal,options: [NSString.CompareOptions.literal], range: titleIndex.upperBound..<webpage$.endIndex, locale: nil) else {
                downloadErrors.append("can't find row end for \(search$) on webpage")
                continue
            }
            webpage$ = String(webpage$[titleIndex.upperBound..<rowEndIndex.lowerBound])
            
            for _ in 0..<4 {

                guard let labelStartIndex = webpage$.range(of: labelStart, options: .backwards, range: nil, locale: nil) else {
                    downloadErrors.append("can't find number start in \(search$) on webpage")
                    continue
                }
                let value$ = webpage$[labelStartIndex.upperBound...]
                debtValues[search$] = [Double(value$.filter("-0123456789.".contains)) ?? 0.0] // use 0.0 here as "-" is used for 'no debt'
                
                guard let labelEndIndex = webpage$.range(of: labelTerminal, options: .backwards, range: nil, locale: nil) else {
                    downloadErrors.append("can't find number end in \(search$) on webpage")
                    continue
                }
                webpage$.removeSubrange(labelEndIndex.lowerBound...)
            }
        }
        
        return debtValues
    }
    
    func cashFlow(_ validWebCode: String) -> [String:[Double]] {
        
        let rowTerminal = "</span></div></div>"
        let labelTerminal = "</span></div>"
        let labelStart = ">"
        
        var cashFlowValues = [String:[Double]]()
        
        for search$ in [">Operating cash flow</span>", ">Capital expenditure</span>"] {
            
            var webpage$ = String(validWebCode)
                            
            guard let titleIndex = webpage$.range(of: search$) else {
                downloadErrors.append("can't find \(search$) on webpage")
                continue
            }

            guard let rowEndIndex = webpage$.range(of: rowTerminal,options: [NSString.CompareOptions.literal], range: titleIndex.upperBound..<webpage$.endIndex, locale: nil) else {
                downloadErrors.append("can't find row end in \(search$) on webpage")
                continue
            }
            webpage$ = String(webpage$[titleIndex.upperBound..<rowEndIndex.lowerBound])

            var valueArray = [Double]()
            for i in 0..<4 {
                valueArray.append(Double())

                guard let labelStartIndex = webpage$.range(of: labelStart, options: .backwards, range: nil, locale: nil) else {
                    downloadErrors.append("can't find start of number in \(search$) on webpage")
                    continue
                }
                let value$ = webpage$[labelStartIndex.upperBound...]
                valueArray[i] = Double(value$.filter("-0123456789.".contains)) ?? Double()
                
                guard let labelEndIndex = webpage$.range(of: labelTerminal, options: .backwards, range: nil, locale: nil) else {
                    downloadErrors.append("can't find end of number in \(search$) on webpage")
                    continue
                }
                webpage$.removeSubrange(labelEndIndex.lowerBound...)

            }
            cashFlowValues[search$] = valueArray.reversed()
        }
        
        return cashFlowValues
    }
    
    func analysis(_ validWebCode: String) -> [String:[Double]] {
        
        let rowTerminal = "</span></td></tr>"
        let labelTerminal = "</span>"
        let labelStart = ">"
        
        var predictionValues = [String:[Double]]()
        
        for search$ in [">Avg. Estimate</span>", ">Sales growth (year/est)</span>"] {
            
            var webpage$ = String(validWebCode)
            
            guard let revenueSection = webpage$.range(of: ">Revenue estimate</span>") else {
                downloadErrors.append("can't find 'Revenue estimate' on webpage")
                continue
            }
            webpage$ = String(webpage$.suffix(from: revenueSection.upperBound))
                            
            guard let titleIndex = webpage$.range(of: search$) else {
                downloadErrors.append("can't find \(search$) on webpage")
                continue
            }

            guard let rowEndIndex = webpage$.range(of: rowTerminal,options: [NSString.CompareOptions.literal], range: titleIndex.upperBound..<webpage$.endIndex, locale: nil) else {
                downloadErrors.append("can't find row end in \(search$) on webpage")
                continue
            }
            webpage$ = String(webpage$[titleIndex.upperBound..<rowEndIndex.lowerBound])

            var valueArray = [Double]()
            for _ in 0..<2 {
                guard let labelStartIndex = webpage$.range(of: labelStart, options: .backwards, range: nil, locale: nil) else {
                    downloadErrors.append("can't find number start in \(search$) on webpage")
                    continue
                }
                let value$ = webpage$[labelStartIndex.upperBound...]

                var value = Double()
                if let v = Double(value$.filter("-0123456789.".contains)) {
                    if value$.last == "T" {
                        value = v * pow(10.0, 9) // should be 12 but values are entered as '000
                    } else if value$.last == "B" {
                        value = v * pow(10.0, 6) // should be 9 but values are entered as '000
                    }
                    else if value$.last == "M" {
                        value = v * pow(10.0, 3) // should be 6 but values are entered as '000
                    }
                    else if value$.last == "%" {
                        value = v / 100.0
                    }
                    else if !search$.contains("Beta") {
                        value = v * pow(10.0, 3)
                    }
                    else {
                        value = v
                    }
                }
                valueArray.append(value)
                
                guard let labelEndIndex = webpage$.range(of: labelTerminal, options: .backwards, range: nil, locale: nil) else {
                    downloadErrors.append("can't find number end in \(search$) on webpage")
                    continue
                }
                webpage$.removeSubrange(labelEndIndex.lowerBound...)

            }
            predictionValues[search$] = valueArray.reversed()
            valueArray.removeAll()
        }
        
        return predictionValues
    }
    
    // Download
    func download(url: URL?, for section: String) {
        
        guard let validURL = url else {
//            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "DCF valuation data download failed due to optional only url request")
            downloadErrors.append("Download failed - empty url")
            return
        }
        
        yahooSession = URLSession.shared.dataTask(with: validURL) { (data, urlResponse, error) in
            
            guard error == nil else {
//                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "a download error occurred")
                self.downloadErrors.append("Download error \(error!.localizedDescription)")
                return
            }
            
            guard urlResponse != nil else {
//                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "a download url response problme occurred: \(urlResponse!)")
                self.downloadErrors.append("Download failed - \(urlResponse!)")
                return
            }
            
            guard let validData = data else {
//                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "a DCF valuation download data problem occurred")
                self.downloadErrors.append("Download failed - data error")
                return
            }

            self.html$ = String(decoding: validData, as: UTF8.self)
            
           NotificationCenter.default.post(name: Notification.Name(rawValue: "WebDataDownloadComplete"), object: section , userInfo: nil)
        }
        yahooSession?.resume()
    }
}
