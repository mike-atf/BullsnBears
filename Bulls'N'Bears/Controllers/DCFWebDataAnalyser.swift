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
//    var sectionsComplete = [Bool]()
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
        
        startDCFDataSearch(section: yahooPages.first!)
        
        NotificationCenter.default.addObserver(self, selector: #selector(downloadCompleted(notification:)), name: Notification.Name(rawValue: "WebDataDownloadComplete"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func startDCFDataSearch(section: String) {
        
        var components: URLComponents?
                
//        sectionsComplete.append(false)
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
            
            result = WebpageScraper.scrapeRow(html$: validWebCode, rowTitle: ">Market cap (intra-day)</span>" , rowTerminal: "</tr>", numberTerminal: "</td>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.marketCap = result.array?.first ?? Double()
            
            result = WebpageScraper.scrapeRow(html$: validWebCode, rowTitle: ">Beta (5Y monthly)</span>" , rowTerminal: "</tr>", numberTerminal: "</td>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.beta = result.array?.first ?? Double()
            
            result = WebpageScraper.scrapeRow(html$: validWebCode, rowTitle: ">Shares outstanding</span>" , rowTerminal: "</tr>", numberTerminal: "</td>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.sharesOutstanding = result.array?.first ?? Double()

//            sectionsComplete[0] = true
            startDCFDataSearch(section: yahooPages[1])
        }
        else if section == yahooPages[1] {
// Income
            result = WebpageScraper.scrapeRow(html$: validWebCode, rowTitle: ">Total revenue</span>", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.tRevenueActual = result.array // Array(result.array?.dropFirst() ?? []) // remove TTM column

            result = WebpageScraper.scrapeRow(html$: validWebCode, rowTitle: ">Net income</span>", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.netIncome = result.array // Array(result.array?.dropFirst() ?? [])

            result = WebpageScraper.scrapeRow(html$: validWebCode, rowTitle: ">Interest expense</span>", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.expenseInterest = result.array?.first ?? Double()
            
            result = WebpageScraper.scrapeRow(html$: validWebCode, rowTitle: ">Income before tax</span>", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.incomePreTax = result.array?.first ?? Double()

            result = WebpageScraper.scrapeRow(html$: validWebCode, rowTitle: ">Income tax expense</span>", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.expenseIncomeTax = result.array?.first ?? Double()

//            sectionsComplete[1] = true
            startDCFDataSearch(section: yahooPages[2])
        }
        else if section == yahooPages[2] {
// Balance sheet
            
            result = WebpageScraper.scrapeRow(html$: validWebCode, rowTitle: ">Current debt</span>", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.debtST = result.array?.first ?? Double()

            result = WebpageScraper.scrapeRow(html$: validWebCode, rowTitle: ">Long-term debt</span>", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            if result.errors.count > 0 {
                downloadTasks += 1
                var components = URLComponents(string: "https://finance.yahoo.com/quote/\(stock.symbol)/\(section)")
                components?.queryItems = [URLQueryItem(name: "p", value: stock.symbol)]
                download(url: components?.url, for: "Yahoo LT Debt")
            }
            else {
                valuation.debtLT = result.array?.first ?? Double()
//                sectionsComplete[2] = true            }
            }
            startDCFDataSearch(section: yahooPages[3])
        }
        else if section == yahooPages[3] {
// Cash flow
            
            result = WebpageScraper.scrapeRow(html$: validWebCode, rowTitle: ">Operating cash flow</span>", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.tFCFo = result.array // Array(result.array?.dropFirst() ?? [])
            
            result = WebpageScraper.scrapeRow(html$: validWebCode, rowTitle: ">Capital expenditure</span>", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.capExpend = result.array // Array(result.array?.dropFirst() ?? [])

//            sectionsComplete[3] = true
            startDCFDataSearch(section: yahooPages[4])
        }
        else if section == yahooPages[4] {
// Analysis
            
            result = WebpageScraper.scrapeRow(html$: validWebCode, sectionHeader: "Revenue estimate</span>" ,rowTitle: ">Avg. Estimate</span>", rowTerminal: "</span></td></tr>", numberTerminal: "</span>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            let a1 = result.array?.dropFirst()
            let a2 = a1?.dropFirst()
            valuation.tRevenuePred = Array(a2 ?? [])

            result = WebpageScraper.scrapeRow(html$: validWebCode, sectionHeader: "Revenue estimate</span>" , rowTitle: ">Sales growth (year/est)</span>", rowTerminal: "</span></td></tr>", numberTerminal: "</span>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            let b1 = result.array?.dropFirst()
            let b2 = b1?.dropFirst()
            valuation.revGrowthPred = Array(b2 ?? [])

//            sectionsComplete[4] = true
        }
        else if section == "Yahoo LT Debt" {
            
            // extra if 'Long-term debt not included in Financial > balance sheet
            // use 'Total debt' instead
            result = WebpageScraper.scrapeRow(html$: validWebCode, rowTitle: ">Total Debt</span>", rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0)
            downloadErrors.append(contentsOf: result.errors)
            valuation.debtLT = result.array?.first ?? Double()
//            sectionsComplete[2] = true
            
            
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
    
    /*
    func scrubWebData() -> String? {
        // webdata will contain an empty Double() as placeholder if no valid number can be found
        
        var error: String?
        var predictionArrays = [valuation.tRevenuePred!, valuation.revGrowthPred!, valuation.revGrowthPredAdj!]
        
        for i in 0..<predictionArrays.count {
            predictionArrays[i] = predictionArrays[i].filter({ (element) -> Bool in
                if element != Double() { return true }
                else { return false }
            })
        }
        
        var firstValidValues = [Int?]()
        var valueArrays = [valuation.tRevenueActual!, valuation.tFCFo!, valuation.netIncome!, valuation.capExpend!]
        
        // if one array contains leading empty Double() elements remove these and all corresponding elements in other array
        var count = 0
        var validElements = [Int]()
        var allElements = [Int]()
        for array in  valueArrays { // bvps is created as [Double]() in insert
            count = 0

            allElements.append(array.count)

            validElements.append(array.filter({ (element) -> Bool in
                if element != Double() { return true }
                else { return false }
            }).count)
            
            for value in array {
                if value != Double() {
                    firstValidValues.append(count)
                    break
                }
                count += 1
            }
        }
        
        let minimumValidElements = validElements.min() ?? 0
        let maximumValidElements = allElements.max() ?? 0
        
        if minimumValidElements != maximumValidElements {
            // assuming leading! elements for most recent years are missing in some arrays
            // may give wrong results if elements from earlier years are missing
            error = "limited data set due to gaps"

            for i in 0..<valueArrays.count {
                let elementCount = valueArrays[i].count
                valueArrays[i].removeSubrange(0..<(elementCount - minimumValidElements))
            }
            // dont' return yet - check below wehther more invalid elements need to be removed
        }
        
        // if one array contains empty Double() elements only return empty arrays
        guard !firstValidValues.contains(nil) else {
            return "essential valuation data missing"
        }
        
        // no usable non-empty element in at least one array
        guard let firstUsableValueIndex = firstValidValues.compactMap({ $0 }).max() else {
            valuation.tRevenueActual = [Double]()
            valuation.tFCFo = [Double]()
            valuation.netIncome = [Double]()
            valuation.capExpend = [Double]()
            return "essential valuation data missing"
        }
                
        if firstUsableValueIndex == 0 { return error } // the first element of all arrays is valid, as expected
        else if ((maximumValidElements - minimumValidElements) - 1) < firstUsableValueIndex {
            // initial elements of some arrays are invalid and need to be removed
            // some leading elements may already have been removed above if arrays have different elements counts
            // all arrays have the same element count here but this may here be equal or less than the firstUsableValueIndex
            // i.e. invalid elements may have already been removed
            print(valueArrays)
            error = "limited data set due to gaps"
        }
        else {
            let removeToIndex = firstUsableValueIndex - ((maximumValidElements - minimumValidElements) - 1)
            for i in 0..<valueArrays.count {
                valueArrays[i].removeSubrange(0...removeToIndex)
                print(valueArrays[i])
            }
            error = "limited data set due to gaps"
        }
        
        valuation.tRevenueActual = valueArrays[0]
        valuation.tFCFo = valueArrays[1]
        valuation.netIncome = valueArrays[2]
        valuation.capExpend = valueArrays[3]
        
        return error

    }
    */
    
    /*
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
//                        downloadErrors.append("can't find end of number in \(search$) on webpage")
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
//                        downloadErrors.append("can't find end of number in \(search$) on webpage")
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
//                    downloadErrors.append("can't find number end in \(search$) on webpage")
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
//                    downloadErrors.append("can't find end of number in \(search$) on webpage")
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
//                    downloadErrors.append("can't find number end in \(search$) on webpage")
                    continue
                }
                webpage$.removeSubrange(labelEndIndex.lowerBound...)

            }
            predictionValues[search$] = valueArray.reversed()
            valueArray.removeAll()
        }
        
        return predictionValues
    }
    */
    
    // Download
    func download(url: URL?, for section: String) {
        
        guard let validURL = url else {
            downloadErrors.append("Download failed - empty url")
            return
        }
        
        print("DCF downloading \(section)...")
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
