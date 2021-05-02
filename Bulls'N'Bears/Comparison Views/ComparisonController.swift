//
//  ComparisonController.swift
//  Bulls'N'Bears
//
//  Created by aDav on 28/04/2021.
//

import Foundation

class ComparisonController {
    
    var shares: [Share]?
    var controlledView: ComparisonVC
    
    
    init(shares: [Share]?, viewController: ComparisonVC) {
        
        self.shares = shares
        self.controlledView = viewController
    }
    
    func rowTitles() -> [[String]]{
        
        let titleStructure = [["Shares","Why to buy"],
                                ["Personal rating score", "Fundamentals score", "Compet. strength" ,"GB Valuation" ,"DCF Valuation", "Intrinsic value"],
                                ["PE ratio", "Lynch ratio", "Book value / share price"],
                                ["Ret. earnings", "Revenue", "Net income", "Op. Cash flow", "Profit margin", "EPS"],
                                ["ROI", "ROE", "ROA"],
                                ["LT Debt / net income", "LT Debt / adj equity", "cap. exp.", "SGA / revenue", "R&D / profit"]]
        
        return titleStructure
        
    }
    
    func sectionTitle() -> [String] {
        
        return ["", "Scores & valuations", "Ratios", "Fundamentals" ,"Returns", "Debt, outgoings & costs"]
    }
    
    func titleForSection(section: Int) -> String {
        
        guard section < sectionTitle().count else {
            return ""
        }
        
        return sectionTitle()[section]
    }
    
    func titleForRow(for path: IndexPath) -> String {
        
        let titles = rowTitles()
        return titles[path.section][path.row]
    }
    
    func rowTexts(forPath: IndexPath) -> [String] {
        
        var texts = [String]()
        
        switch forPath.section {
        case 0:
            if forPath.row == 0 {
                texts = shares?.compactMap{ $0.symbol } ?? [String]()
            }
            else if forPath.row == 1 {
                for share in shares ?? [] {
                    texts.append(share.research?.theBuyStory ?? "")
                }
            }
        case 1:
            if forPath.row == 0 {
                for share in  shares ?? [] {
                    var text = "-"
                    if share.userEvaluationScore > 0 {
                        text = percentFormatter0Digits.string(from: share.userEvaluationScore as NSNumber) ?? "-"
                    }
                    texts.append(text)
                }
            }
            else if forPath.row == 1 {
                for share in  shares ?? [] {
                    var text = "-"
                    if share.valueScore > 0 {
                        text = percentFormatter0Digits.string(from: share.valueScore as NSNumber) ?? "-"
                    }
                    texts.append(text)
                }
            }
            else if forPath.row == 2 {
                for share in  shares ?? [] {
                    var text = "-"
                    if let moat = share.rule1Valuation?.moatScore() {
                        text = percentFormatter0Digits.string(from: moat as NSNumber) ?? "-"
                    }
                    texts.append(text)
                }
            }
            else if forPath.row == 3 {
                for share in  shares ?? [] {
                    var text = "-"
                    if share.rule1Valuation != nil {
                        let (price,_) = share.rule1Valuation!.stickerPrice()
                        if let validPrice = price {
                            text = currencyFormatterNoGapNoPence.string(from: validPrice as NSNumber) ?? "-"
                        }
                    }
                    texts.append(text)
                }
            }
            else if forPath.row == 4 {
                for share in  shares ?? [] {
                    var text = "-"
                    if share.dcfValuation != nil {
                        let (price,_) = share.dcfValuation!.returnIValue()
                        if let validPrice = price {
                            text = currencyFormatterNoGapNoPence.string(from: validPrice as NSNumber) ?? "-"
                        }
                    }
                    texts.append(text)
                }
            }
            else if forPath.row == 5 {
                for share in  shares ?? [] {
                    var text = "-"
                    if share.wbValuation != nil {
                        let (price,_) = share.wbValuation!.ivalue()
                        if let validPrice = price {
                            text = currencyFormatterNoGapNoPence.string(from: validPrice as NSNumber) ?? "-"
                        }
                    }
                    texts.append(text)
                }
            }
        case 2:
            if forPath.row == 0 {
                for share in  shares ?? [] {
                    var text = "-"
                    if share.peRatio != 0 {
                        text = numberFormatterWith1Digit.string(from: share.peRatio as NSNumber) ?? "-"
                    }
                    texts.append(text)
                }
            }
            else if forPath.row == 1 {
                for share in  shares ?? [] {
                    var text = "-"
                    if share.wbValuation != nil {
                        if let ratio = share.wbValuation!.lynchRatio() {
                            text = numberFormatterWith1Digit.string(from: ratio as NSNumber) ?? "-"
                        }
                    }
                    texts.append(text)
                }
            }
            else if forPath.row == 2 {
                for share in  shares ?? [] {
                    var text = "-"
                    if share.wbValuation != nil {
                        if let values = share.wbValuation!.bookValuePerPrice() {
                            var t1$:String?
                            var t2$:String?
                            if let value1 = values[0] {
                                t1$ = percentFormatter0Digits.string(from: value1 as NSNumber) ?? ""
                            }
                            if let value2 = values[1] {
                                t2$ = currencyFormatterNoGapWithPence.string(from: value2 as NSNumber) ?? ""
                            }

                            
                            if t1$ != nil && t2$ != nil {
                                text = t1$! + " (" + t2$! + ")"
                            }
                            else {
                                text = (t1$ ?? t2$) ?? "-"
                            }
                        }
                    }
                    texts.append(text)
                }
            }
        case 3:
            if forPath.row == 0 {
                for share in  shares ?? [] {
                    var text = "-"
                    if let retE = share.wbValuation?.equityRepurchased {
                        if let lastRetEarnings = retE.last {
                            if lastRetEarnings < 0 {
                                text = "last neg."
                            }
                            else {
                                
                            }
                        }
                    }
                    texts.append(text)
                }
            }


        default:
            texts = [String]()
        }
        
        return texts
    }
    
    /*
     tableStructure:
     == section 0
     0 titles / symbols
     1 research.buy story
     == section 1
     0 user rating score
     1 fundamentals score
     2 moat score
     3 GB valuation
     4 DCF Valuation
     5 intrinsic WB value
     == section 2
     0 PE ratios
     1 Lynch score
     2 Book value/share price
     == section 3
     0 ret. earnings
     1 sales
     2 net income
     3 OCF
     4 profit margin
     5 EPS
     == section 4
     0 ROI
     1 ROE
     2 ROA
     == section 5
     0 debt / net income
     1 debt / adj equity
     2 capEx
     3 SGA / revenue
     4 RD / profit growth
     
     */
    

    
}
