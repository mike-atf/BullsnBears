//
//  Rule1ValuationController.swift
//  Bulls'N'Bears
//
//  Created by aDav on 09/01/2021.
//

import UIKit
import CoreData

protocol R1ValuationHelper {
    func buildRowTitles() -> [[String]]
    func getR1Value(indexPath: IndexPath) -> Any?
    func configureCell(indexPath: IndexPath, cell: ValuationTableViewCell)
    func userEnteredText(sender: UITextField, indexPath: IndexPath)
    func r1SectionTitles() -> [String]
    func r1SectionSubTitles() -> [String]
}


class Rule1ValuationController: R1ValuationHelper {
    
    var rowTitles: [[String]]?
    var valuationListViewController: ValuationListViewController!
    var valuation: Rule1Valuation?

    var revenueGrowthRates = [Double]()
    var averagePredictedGrowth = Double()
    var fcfGrowthRates = [Double]()
    var bvpsGrowthRate = [Double]()
    var epsGrowthRate = [Double]()

    let r1ValuationSectionTitles = ["General",
                                    "Moat parameters: Values 5-10 years back",
                                    "", "", "", "",
                                    "PE Ratios", "Growth predictions",
                                    "Adj. growth prediction (Optional)",
                                    "Debt (Optional)",
                                    "Insider Trading (Optional)",
                                    "CEO Rating (Optional)"
                                    ]
//    let l = [0,1,6,7,8,9,10,13]
    let r1ValuationSectionSubtitles = ["Creation date","1.Book Value per Share", "2.Earnings per Share", "3.Sales/ Revenue", "4.Free Cash Flow", "5.Return on Invested Capital", "min and max last 5-10 years", "Analysts min and max predictions","Adjust predicted growth rates", "", "", "Between 0 - 10"]
    
       
    init(listView: ValuationListViewController) {
        self.valuationListViewController = listView
        self.valuation = listView.r1Valuation
    }
    
    static func returnR1Valuations(company: String? = nil) -> [Rule1Valuation]? {
        
        var valuations: [Rule1Valuation]?
        
        let fetchRequest = NSFetchRequest<Rule1Valuation>(entityName: "Rule1Valuation")
        if let validName = company {
            let predicate = NSPredicate(format: "company BEGINSWITH %@", argumentArray: [validName])
            fetchRequest.predicate = predicate
        }
        
        do {
            valuations = try managedObjectContext.fetch(fetchRequest)
            } catch let error {
                ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: error, errorInfo: "error fetching Rule1Valuation")
        }

        return valuations
    }

    
    func buildRowTitles() -> [[String]] {
        
        let yearOnlyFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = NSLocale.current
            formatter.timeZone = NSTimeZone.local
            formatter.dateFormat = "YYYY"
            return formatter
        }()
        
        let generalSectionTitles = ["Date"]
        var bvpsTitles = ["BVPS"]
        var epsTitles = ["EPS"]
        var revenueTitles = ["Revenue"]
        var fcfTitles = ["FCF"]
        var roicTitles = ["ROIC"]
        
        let hxPERTitles = ["past PER min" , "past PER max"]
        var growthPredTitles = ["Pred. sales growth"]
        var adjGrowthPredTitles = ["Adj. sales growth"]
        let debtRowTitles = ["Long term debt", "Debt / FCF"]
        let insideTradingRowTitles = ["Total insider shares", "Inside share buys", "Inside Share sells"]
        let ceoRatingRowTitle = ["CEO rating"]

        var count = 0
        for i in stride(from: 9, to: 0, by: -1) {
            let date = (valuation?.creationDate ?? Date()).addingTimeInterval(Double(i * -1) * 366 * 24 * 3600)
            let year$ = yearOnlyFormatter.string(from: date)
            
            var newTitle = bvpsTitles.first! + " " + year$
            bvpsTitles.insert(newTitle, at: 1)
            
            newTitle = epsTitles.first! + " " + year$
            epsTitles.insert(newTitle, at: 1)

            newTitle = revenueTitles.first! + " " + year$
            revenueTitles.insert(newTitle, at: 1)

            newTitle = fcfTitles.first! + " " + year$
            fcfTitles.insert(newTitle, at: 1)
            
            newTitle = roicTitles.first! + " " + year$
            roicTitles.insert(newTitle, at: 1)
            
            count += 1
        }
        
        for i in 0..<2 {
            let date = (valuation?.creationDate ?? Date()).addingTimeInterval(Double(i) * 366 * 24 * 3600)
            let year$ = yearOnlyFormatter.string(from: date)
            
            var newTitle = growthPredTitles.first! + " " + year$
            growthPredTitles.append(newTitle)
            newTitle = adjGrowthPredTitles.first! + " " + year$
            adjGrowthPredTitles.append(newTitle)
        }

        bvpsTitles.removeFirst()
        epsTitles.removeFirst()
        revenueTitles.removeFirst()
        roicTitles.removeFirst()
        fcfTitles.removeFirst()
        growthPredTitles.removeFirst()
        adjGrowthPredTitles.removeFirst()
        
        let rowTitles = [generalSectionTitles ,bvpsTitles, epsTitles, revenueTitles, fcfTitles, roicTitles, hxPERTitles, growthPredTitles, adjGrowthPredTitles, debtRowTitles, insideTradingRowTitles,ceoRatingRowTitle]

        return rowTitles

    }
    
    func getR1Value(indexPath: IndexPath) -> Any? {
        
        guard let valuation = valuation else { return nil }
                
        switch indexPath.section {
        case 0:
            // 'General
            return valuation.creationDate
        case 1:
            // 'Moat parameters - BVPS
            return valuation.bvps?[indexPath.row]

        case 2:
            // 'Moat parameters - EPS
            return valuation.eps?[indexPath.row]
        case 3:
            // 'Moat parameters - Revenue
            return valuation.revenue?[indexPath.row]
        case 4:
            // 'Moat parameters - FCF
            return valuation.oFCF?[indexPath.row]
        case 5:
            // 'Moat parameters - ROIC
            return valuation.roic?[indexPath.row]
        case 6:
            // 'Historical min /max PER
            return valuation.hxPE?[indexPath.row]
        case 7:
            // 'Growth predictions
            return valuation.growthEstimates?[indexPath.row]
        case 8:
            // 'Adjusted Growth predictions
            return valuation.adjGrowthEstimates?[indexPath.row]
       case 9:
            // 'Debt
            return valuation.debt
        case 10:
            // 'Insider Stocks'
            return valuation.insiderStocks
        case 11:
            // 'Insider Stocks'
            return valuation.insiderStockBuys
        case 12:
            // 'Insider Stocks'
            return valuation.insiderStockSells
        case 13:
            return valuation.ceoRating
        default:
            ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
        }
        
        return "error"


    }
    
    internal func cellValueFormat(indexPath: IndexPath) -> ValuationCellValueFormat {
        
        switch indexPath.section {
        case 0:
            // 'General
            return .date
        case 1:
            return .currency
        case 2:
            return .currency
        case 3:
            return .currency
        case 4:
            return .currency
        case 5:
            return .percent
        case 6:
            return .numberWithDecimals
        case 7:
            return .percent
        case 8:
            return .percent
       case 9:
            if indexPath.row == 0 { return .currency}
            else { return .percent}
        case 10:
            return .numberWithDecimals
        default:
            ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
        }
        
        return .numberWithDecimals
    }
    
    func configureCell(indexPath: IndexPath, cell: ValuationTableViewCell) {
        
        let value = getR1Value(indexPath: indexPath)
        let value$ = getCellValueText(value: value, indexPath: indexPath)
        let rowTitle = (rowTitles ?? buildRowTitles())[indexPath.section][indexPath.row]
        let format = cellValueFormat(indexPath: indexPath)
        let detail$ = getDetail$(indexPath: indexPath) ?? ""
        
        cell.configure(title: rowTitle, value$: value$, detail: detail$, indexPath: indexPath, dcfDelegate: nil, r1Delegate: self, valueFormat: format)

    }
    
    internal func getCellValueText(value: Any?, indexPath: IndexPath) -> String? {
        
        var value$: String?
        
        if let validValue = value {
            if let date = validValue as? Date {
                value$ = dateFormatter.string(from: date)
            }
            else if let number = validValue as? Double {
                if [7,5,8].contains(indexPath.section) {
                    value$ = percentFormatter.string(from: number as NSNumber)
               }
                else if [6,9,11].contains(indexPath.section) {
                    value$ = numberFormatterWithFraction.string(from: number as NSNumber)
                }
                else if [10].contains(indexPath.section) {
                    value$ = numberFormatterNoFraction.string(from: number as NSNumber)
                }
                else {
                    value$ = currencyFormatterGapNoPence.string(from: number as NSNumber)
                }
            }
            else if let text = validValue as? String {
                value$ = text
            }
        }
        
        return value$

    }
    
    internal func getDetail$(indexPath: IndexPath) -> String? {
        
        switch indexPath.section {
        case 0:
            // 'General
            return nil
        case 1:
            // 'Moat parameters - BVPS
            if indexPath.row == 9 { return nil }
            else if indexPath.row < ( bvpsGrowthRate.count ) - 1 {
                return percentFormatter.string(from: bvpsGrowthRate[indexPath.row] as NSNumber)
            }
            return nil
        case 2:
            // 'Moat parameters - EPS
            if indexPath.row == 9 { return nil }
            else if indexPath.row < ( bvpsGrowthRate.count ) - 1 {
                return percentFormatter.string(from: epsGrowthRate[indexPath.row] as NSNumber)
            }
            return nil
        case 3:
            // 'Moat parameters - Revenue
            if indexPath.row == 9 { return nil }
            else if indexPath.row < ( bvpsGrowthRate.count ) - 1 {
                return percentFormatter.string(from: revenueGrowthRates[indexPath.row] as NSNumber)
            }
            return nil
        case 4:
            // 'Moat parameters - FCF
            if indexPath.row == 9 { return nil }
                else if indexPath.row < ( bvpsGrowthRate.count ) - 1 {
                    return percentFormatter.string(from: fcfGrowthRates[indexPath.row] as NSNumber)
            }
            return nil
        case 5:
            // 'Moat parameters - ROIC
            return nil
        case 6:
            // 'Historical min /max PER
            return nil
        case 7:
            // 'Growth predictions
            return nil
        case 8:
            // 'Adjusted Growth predictions
            return nil
       case 9:
            // 'Debt
            if let fcf = valuation?.oFCF?.first {
                if fcf > 0 {
                    let proportion = (valuation?.debt ?? 0.0) / fcf
                    return percentFormatter.string(from: proportion as NSNumber)
                }
            }
            return nil
        case 10:
            // 'Insider Stocks'
            if valuation?.insiderStocks ?? 0.0 == 0.0 { return nil }
            if indexPath.row == 0 {
                return nil
            } else if indexPath.row == 1 {
                if let insiderStocks = valuation?.insiderStocks {
                    let proportion = (valuation?.insiderStockBuys ?? 0.0) / insiderStocks
                    return percentFormatter.string(from: proportion as NSNumber)
                }
            }
            else if indexPath.row == 3 {
                if let insiderStocks = valuation?.insiderStocks {
                    let proportion = (valuation?.insiderStockSells ?? 0.0) / insiderStocks
                    return percentFormatter.string(from: proportion as NSNumber)
                }
            }
            else { return nil }
        case 11:
            // 'CEO'
            return "0-10"
        default:
            ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
        }
        
        return nil

    }
    
    func userEnteredText(sender: UITextField, indexPath: IndexPath) {
        
        guard let validtext = sender.text else {
            return
        }
        
        guard let value = Double(validtext.filter("0123456789.".contains)) else {
            ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "error converting entered text to number: \(sender.text ?? "no text")")
            return
        }

        guard let valuation = valuation else { return }
                
        switch indexPath.section {
        case 0:
            // 'General
            return
        case 1:
            // 'Moat parameters - BVPS
            valuation.bvps?[indexPath.row] = value

        case 2:
            // 'Moat parameters - EPS
            valuation.eps?[indexPath.row] = value
        case 3:
            // 'Moat parameters - Revenue
            valuation.revenue?[indexPath.row] = value
        case 4:
            // 'Moat parameters - FCF
            valuation.oFCF?[indexPath.row] = value
        case 5:
            // 'Moat parameters - ROIC
            valuation.roic?[indexPath.row] = value
        case 6:
            // 'Historical min /max PER
            valuation.hxPE?[indexPath.row] = value
        case 7:
            // 'Growth predictions
            valuation.growthEstimates?[indexPath.row] = value
        case 8:
            // 'Adjusted Growth predictions
            valuation.adjGrowthEstimates?[indexPath.row] = value
       case 9:
            // 'Debt
            valuation.debt = value
        case 10:
            // 'Insider Stocks'
            valuation.insiderStocks = value
        case 11:
            // 'Insider Stocks'
            valuation.insiderStockBuys = value
        case 12:
            // 'Insider Stocks'
            valuation.insiderStockSells = value
        case 13:
            valuation.ceoRating = value
        default:
            ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
        }
        
        return
    }
    
    func r1SectionTitles() -> [String] {
        return r1ValuationSectionTitles
    }
    
    func r1SectionSubTitles() -> [String] {
        return r1ValuationSectionSubtitles
    }
    
    internal func recalculateAvgGrowthRate() {
        
        var growthRateSum = revenueGrowthRates.compactMap{ $0 }.reduce(0, +)
        growthRateSum += valuation?.growthEstimates?.compactMap{ $0 }.reduce(0, +) ?? 0.0
        
        averagePredictedGrowth = growthRateSum / Double(revenueGrowthRates.compactMap{ $0 }.count + (valuation?.growthEstimates?.compactMap{ $0 }.count ?? 0) )
    }
    
    internal func recalculateBVPSGrowth() {
        
        bvpsGrowthRate.removeAll()
        
        for i in 1..<(valuation?.bvps?.count ?? 0) {
            if valuation!.bvps![i] > 0 {
                let rate = (valuation!.bvps![i-1] - valuation!.bvps![i]) / valuation!.bvps![i]
                bvpsGrowthRate.append(rate)
            }
            else {
                bvpsGrowthRate.append(Double())
            }
        }
        bvpsGrowthRate.append(Double()) // add fifth unused element to allow return in 'getDetailValue'
        
    }
    
    internal func recalculateEPSGrowth() {
        
        epsGrowthRate.removeAll()
        
        for i in 1..<(valuation?.eps?.count ?? 0) {
            if valuation!.eps![i] > 0 {
                let rate = (valuation!.eps![i-1] - valuation!.eps![i]) / valuation!.eps![i]
                epsGrowthRate.append(rate)
            }
            else {
                epsGrowthRate.append(Double())
            }
        }
        epsGrowthRate.append(Double()) // add 10th unused element to allow return in 'getDetailValue'
        
    }
 
    internal func recalculateFCFGrowth() {
        
        fcfGrowthRates.removeAll()
        
        for i in 1..<(valuation?.oFCF?.count ?? 0) {
            if valuation!.oFCF![i] > 0 {
                let rate = (valuation!.oFCF![i-1] - valuation!.oFCF![i]) / valuation!.oFCF![i]
                fcfGrowthRates.append(rate)
            }
            else {
                fcfGrowthRates.append(Double())
            }
        }
        fcfGrowthRates.append(Double()) // add fifth unused element to allow return in 'getDetailValue'
        
    }


}
