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
    var yahooPages = ["key-statistics", "financials", "balance-sheet"]
    var controller: CombinedValuationController!
    
    init(stock: Stock, valuation: DCFValuation, controller: CombinedValuationController) {
        self.stock = stock
        self.valuation = valuation
        self.controller = controller
        
        startDCFDataSearch()
        
        NotificationCenter.default.addObserver(self, selector: #selector(downloadCompleted(notification:)), name: Notification.Name(rawValue: "WebDataDownloadComplete"), object: nil)
    }
    
    private func startDCFDataSearch() {
        
        var components: URLComponents?
        
        for section in yahooPages {
            
            components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(stock.name)/\(section)")
            components?.queryItems = [URLQueryItem(name: "p", value: stock.name)]
            download(url: components?.url, for: section)
        }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateValuationData"), object: nil , userInfo: nil)
        }
    }
    
    
    @objc
    func downloadCompleted(notification: Notification) {
                        
        guard let validWebCode = html$ else {
            print("download complete, html string is empty")
            return
        }
        
        guard let section = notification.object as? String else {
            print("download complete - notification did not contain section info!!")
            return
        }
        
        if section == yahooPages.first! {
            let stats = keyStats(validWebCode)
            valuation.beta = stats[1]
            valuation.marketCap = stats[0]
            valuation.sharesOutstanding = stats[2]
        }
        else if section == yahooPages[1] {
            let stats = incomeStats(validWebCode)
            valuation.tRevenueActual = stats[">Total revenue</span>"]
            valuation.netIncome = stats[">Net income</span>"]
            valuation.expenseInterest = stats[">Interest expense</span>"]?.first ?? Double()
            valuation.incomePreTax = stats[">Income before tax</span>"]?.first ?? Double()
            valuation.expenseIncomeTax = stats[">Income tax expense</span>"]?.first ?? Double()
        }
        else if section == yahooPages[2] {
            
        }
        
        valuation.save()
    }
    
    func keyStats(_ validWebCode: String) -> [Double] {
        
        var keyStatValues = [Double]()
        var count = -1 // !!
        for search$ in [">Market cap (intra-day)</span>", ">Beta (5Y monthly)</span>", ">Shares outstanding</span>"] {
            keyStatValues.append(Double())
            count += 1
            
            var webpage$ = String(validWebCode)
                            
            guard let index1 = webpage$.range(of: search$) else {
                continue
            }

            guard let index3 = webpage$.range(of: "</tr>",options: [NSString.CompareOptions.literal], range: index1.upperBound..<webpage$.endIndex, locale: nil) else {
                continue
            }
            
            webpage$ = String(webpage$[index1.upperBound..<index3.lowerBound])
            guard let index4 = webpage$.range(of: "</td>", options: .backwards, range: nil, locale: nil) else {
                continue
            }
            webpage$.removeSubrange(index4.lowerBound...)

            guard let index5 = webpage$.range(of: ">", options: .backwards, range: nil, locale: nil) else {
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
            
// temp - remove
//            do {
//                let plainText = try NSAttributedString(data: search$.data(using: .utf8) ?? Data(), options: [NSAttributedString.DocumentReadingOptionKey.documentType : NSAttributedString.DocumentType.html], documentAttributes: nil)
//                print("\(plainText.string) = \(currencyFormatterGapWithOptionalPence.string(from: value as NSNumber) ?? "-")")
//
//            } catch let error {
//                print(error)
//            }
// temp - remove
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
                continue
            }

            guard let rowEndIndex = webpage$.range(of: rowTerminal,options: [NSString.CompareOptions.literal], range: titleIndex.upperBound..<webpage$.endIndex, locale: nil) else {
                continue
            }
            webpage$ = String(webpage$[titleIndex.upperBound..<rowEndIndex.lowerBound])
            
            if count < 2 {
                var valueArray = [Double]()
                for i in 0..<4 {
                    valueArray.append(Double())

                    guard let labelStartIndex = webpage$.range(of: labelStart, options: .backwards, range: nil, locale: nil) else {
                        continue
                    }
                    let value$ = webpage$[labelStartIndex.upperBound...]
                    valueArray[i] = Double(value$.filter("-0123456789.".contains)) ?? Double()
                    
                    guard let labelEndIndex = webpage$.range(of: labelTerminal, options: .backwards, range: nil, locale: nil) else {
                        continue
                    }
                    webpage$.removeSubrange(labelEndIndex.lowerBound...)

                }
                incomeValues[search$] = valueArray.reversed()
            }
            else {
                for _ in 0..<4 {

                    guard let labelStartIndex = webpage$.range(of: labelStart, options: .backwards, range: nil, locale: nil) else {
                        continue
                    }
                    let value$ = webpage$[labelStartIndex.upperBound...]
                    incomeValues[search$] = [Double(value$.filter("-0123456789.".contains)) ?? Double()]
                    
                    guard let labelEndIndex = webpage$.range(of: labelTerminal, options: .backwards, range: nil, locale: nil) else {
                        continue
                    }
                    webpage$.removeSubrange(labelEndIndex.lowerBound...)
                }
            }
        }
        
        for value in incomeValues {
            print("\(value.key) = \(value.value)")
        }
        return incomeValues
    }
    
    func balanceSheet(_ validWebCode: String) -> [Double] {
        
        let rowTerminal = "</span></div></div>"
        let labelTerminal = "</span></div>"
        let labelStart = ">"
        
        var debtValues = [Double]()
        var count = -1 // !!
        
        for search$ in [">Current debt</span>", ">Long-term debt</span>"] {
            
        }
        
        return debtValues

    }
    
    
    // Download
    func download(url: URL?, for section: String) {
        
        guard let validURL = url else {
            print("download failed to to optional only url request")
            return
        }
        
        print("trying to download \(validURL)")
        
        let dataTask = URLSession.shared.dataTask(with: validURL) { (data, urlResponse, error) in
            
            guard error == nil else {
                print("a download error occurred: \(error!)")
                return
            }
            
            guard urlResponse != nil else {
                print("a download url response problme occurred: \(urlResponse!)")
                return
            }
            
            guard let validData = data else {
                print("a download data problem occurred")
                return
            }

            self.html$ = String(decoding: validData, as: UTF8.self)
            
           NotificationCenter.default.post(name: Notification.Name(rawValue: "WebDataDownloadComplete"), object: section , userInfo: nil)

            
        }
        dataTask.resume()
                
        
    }
}
