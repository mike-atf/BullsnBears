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

    var revenueGrowthRates = [Double()]
    var averagePredictedGrowth = Double()
    var fcfGrowthRates = [Double()]
    var bvpsGrowthRate = [Double()]
    var epsGrowthRate = [Double()]

    let r1ValuationSectionTitles = ["General",
                                    "Moat parameters: Values 5-10 years back",
                                    "", "", "", "",
                                    "PE Ratios", "Growth predictions",
                                    "Adj. growth prediction (Optional)",
                                    "Debt (Optional)",
                                    "Insider Trading (Optional)",
                                    "CEO Rating (Optional)"
                                    ]
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
        let growthPredTitles = ["Pred. sales growth min", "Pred. sales growth min"]
        let adjGrowthPredTitles = ["Adj. sales growth min", "Adj. sales growth max"]
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
        
        bvpsTitles.removeFirst()
        epsTitles.removeFirst()
        revenueTitles.removeFirst()
        roicTitles.removeFirst()
        fcfTitles.removeFirst()
        
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
            if valuation.bvps?.count ?? 0 > indexPath.row {
                return valuation.bvps?[indexPath.row]
            }
        case 2:
            // 'Moat parameters - EPS
            if valuation.eps?.count ?? 0 > indexPath.row {
                return valuation.eps?[indexPath.row]
            }
        case 3:
            // 'Moat parameters - Revenue
            if valuation.revenue?.count ?? 0 > indexPath.row {
                return valuation.revenue?[indexPath.row]
            }
        case 4:
            // 'Moat parameters - FCF
            if valuation.oFCF?.count ?? 0 > indexPath.row {
                return valuation.oFCF?[indexPath.row]
            }
        case 5:
            // 'Moat parameters - ROIC
            if valuation.roic?.count ?? 0 > indexPath.row {
                return valuation.roic?[indexPath.row]
            }
        case 6:
            // 'Historical min /max PER
            if valuation.hxPE?.count ?? 0 > indexPath.row {
                return valuation.hxPE?[indexPath.row]
            }
        case 7:
            // 'Growth predictions
            if valuation.growthEstimates?.count ?? 0 > indexPath.row {
                return valuation.growthEstimates?[indexPath.row]
            }
            else {
                return averagePredictedGrowth
            }
        case 8:
            // 'Adjusted Growth predictions
            if valuation.adjGrowthEstimates?.count ?? 0 > indexPath.row  {
                return valuation.adjGrowthEstimates?[indexPath.row]
            }
            else {
                return averagePredictedGrowth
            }
       case 9:
            // 'Debt
            if indexPath.row == 0 {
                return valuation.debt
            }
            else {
                if let validFCF = valuation.oFCF?.first {
                    if validFCF > 0 {
                        return valuation.debt / validFCF
                    }
                }
            }
            return nil
        case 10:
            // 'Insider Stocks'
            if indexPath.row == 0 {
                return valuation.insiderStocks
            }
            else if indexPath.row == 1 {
                return valuation.insiderStockBuys
            }
            else if indexPath.row == 2 {
                return valuation.insiderStockSells
            }
        case 11:
            // 'CEO rating'
            return valuation.ceoRating
        default:
            ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
        }
        
        return nil


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
        let (detail$, color) = getDetail$(indexPath: indexPath)
        
        cell.configure(title: rowTitle, value$: value$, detail: detail$ ?? "", indexPath: indexPath, dcfDelegate: nil, r1Delegate: self, valueFormat: format, detailColor: color)

    }
    
    internal func getCellValueText(value: Any?, indexPath: IndexPath) -> String? {
        
        var value$: String?
        
        if let validValue = value {
            if let date = validValue as? Date {
                value$ = dateFormatter.string(from: date)
            }
            else if let number = validValue as? Double {
                if [7,5,8].contains(indexPath.section) {
                    value$ = percentFormatter2Digits.string(from: number as NSNumber)
               }
                else if [6,9,11].contains(indexPath.section) {
                    value$ = numberFormatterWithFraction.string(from: number as NSNumber)
                }
                else if [10].contains(indexPath.section) {
                    value$ = numberFormatterNoFraction.string(from: number as NSNumber)
                }
                else if [9].contains(indexPath.section) {
                    if indexPath.row == 0 {
                        value$ = numberFormatterWithFraction.string(from: number as NSNumber)
                    }
                    else {
                        value$ = percentFormatter2Digits.string(from: number as NSNumber)
                    }
                }
                else {
                    value$ = currencyFormatterGapWithPence.string(from: number as NSNumber)
                }
            }
            else if let text = validValue as? String {
                value$ = text
            }
        }
        
        return value$

    }
    
    internal func compoundGrowthRate(endValue: Double, startValue: Double, years: Double) -> Double {
        
        return (pow((endValue / startValue) , (1/years)) - 1)
    }
    
    internal func getDetail$(indexPath: IndexPath) -> (String?, UIColor?) {
        
        switch indexPath.section {
        case 0:
            // 'General
            return (nil, nil)
        case 1:
            // 'Moat parameters - BVPS
            if indexPath.row == 9 || indexPath.row == 0 { return (nil, nil) }
            else if indexPath.row < ( bvpsGrowthRate.count ) {
                let color = bvpsGrowthRate[indexPath.row] < 0.1 ? UIColor(named: "Red") : UIColor(named: "Green")
                return (percentFormatter0Digits.string(from: bvpsGrowthRate[indexPath.row] as NSNumber), color)
            }
            return (nil, nil)
        case 2:
            // 'Moat parameters - EPS
            if indexPath.row == 9 || indexPath.row == 0 { return (nil, nil) }
            else if indexPath.row < ( epsGrowthRate.count ) {
                let color = epsGrowthRate[indexPath.row] < 0.1 ? UIColor(named: "Red") : UIColor(named: "Green")
                return (percentFormatter0Digits.string(from: epsGrowthRate[indexPath.row] as NSNumber), color)
            }
            return (nil, nil)

        case 3:
            // 'Moat parameters - Revenue
            if indexPath.row == 9 || indexPath.row == 0 { return (nil, nil) }
            else if indexPath.row < ( revenueGrowthRates.count ) {
                let color = revenueGrowthRates[indexPath.row] < 0.1 ? UIColor(named: "Red") : UIColor(named: "Green")
                return (percentFormatter0Digits.string(from: revenueGrowthRates[indexPath.row] as NSNumber), color)
            }
            return (nil, nil)

        case 4:
            // 'Moat parameters - FCF
            if indexPath.row == 9 || indexPath.row == 0 { return (nil, nil) }
                else if indexPath.row < ( fcfGrowthRates.count ) {
                    let color = fcfGrowthRates[indexPath.row] < 0.1 ? UIColor(named: "Red") : UIColor(named: "Green")
                    return (percentFormatter0Digits.string(from: fcfGrowthRates[indexPath.row] as NSNumber), color)
            }
            return (nil, nil)

        case 5:
            // 'Moat parameters - ROIC
            if indexPath.row == 9 { return (nil, nil) }
            else if (valuation?.roic?.count ?? 0) > indexPath.row {
                let color = valuation!.roic![indexPath.row] < 0.1 ? UIColor(named: "Red") : UIColor(named: "Green")
                return (percentFormatter0Digits.string(from: valuation!.roic![indexPath.row] as NSNumber), color)
            }
            else { return (nil, nil) }
        case 6:
            // 'Historical min /max PER
            return (nil, nil)

        case 7:
            // 'Growth predictions
            return (nil, nil)

        case 8:
            // 'Adjusted Growth predictions
            return (nil, nil)

       case 9:
            // 'Debt
            if indexPath.row == 0 { return (nil, nil) }
            else if let fcf = valuation?.oFCF?.first {
                if fcf > 0 {
                    let proportion = (valuation?.debt ?? 0.0) / fcf
                    return (percentFormatter2Digits.string(from: proportion as NSNumber), nil)
                }
            }
            else {
                return (nil, nil)
            }
        case 10:
            // 'Insider Stocks'
            if valuation?.insiderStocks ?? 0.0 == 0.0 { return (nil, nil) }
            if indexPath.row == 0 {
                return (nil, nil)

            } else if indexPath.row == 1 {
                if let insiderStocks = valuation?.insiderStocks {
                    let proportion = (valuation?.insiderStockBuys ?? 0.0) / insiderStocks
                    return (percentFormatter2Digits.string(from: proportion as NSNumber), nil)
                }
            }
            else if indexPath.row == 2 {
                if let insiderStocks = valuation?.insiderStocks {
                    let proportion = (valuation?.insiderStockSells ?? 0.0) / insiderStocks
                    return (percentFormatter2Digits.string(from: proportion as NSNumber), nil)
                }
            }
            else { return (nil, nil) }
        case 11:
            // 'CEO'
            return ("0-10", nil)
        default:
            ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
        }
        
        return (nil, nil)
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
            valuation.bvps?.insert(value, at: indexPath.row)
            bvpsGrowthRate = recalculateGrowth(valueArray: valuation.bvps, index: indexPath.row, growthArray: bvpsGrowthRate) ?? bvpsGrowthRate
            recalculateAvgGrowthRate()
        case 2:
            // 'Moat parameters - EPS
            valuation.eps?.insert(value, at: indexPath.row)
            epsGrowthRate = recalculateGrowth(valueArray: valuation.eps, index: indexPath.row,growthArray: epsGrowthRate) ?? epsGrowthRate
        case 3:
            // 'Moat parameters - Revenue
            valuation.revenue?.insert(value, at: indexPath.row)
            revenueGrowthRates = recalculateGrowth(valueArray: valuation.revenue, index: indexPath.row, growthArray: revenueGrowthRates) ?? revenueGrowthRates
        case 4:
            // 'Moat parameters - FCF
            valuation.oFCF?.insert(value, at: indexPath.row)
            fcfGrowthRates = recalculateGrowth(valueArray: valuation.oFCF, index: indexPath.row, growthArray: fcfGrowthRates) ?? fcfGrowthRates
        case 5:
            // 'Moat parameters - ROIC
            valuation.roic?.insert(value / 100, at: indexPath.row)
        case 6:
            // 'Historical min /max PER
            valuation.hxPE?.insert(value, at: indexPath.row)
        case 7:
            // 'Growth predictions
            valuation.growthEstimates?.insert(value / 100, at: indexPath.row)
            recalculateAvgGrowthRate()
        case 8:
            // 'Adjusted Growth predictions
            valuation.adjGrowthEstimates?.insert(value / 100, at: indexPath.row)
       case 9:
            // 'Debt
            if indexPath.row == 0 {
                valuation.debt = value
            }
        case 10:
            // 'Insider Stocks'
            if indexPath.row == 0 {
                valuation.insiderStocks = value
            }
            else if indexPath.row == 1 {
                valuation.insiderStockBuys = value
            }
            else if indexPath.row == 2 {
                valuation.insiderStockSells = value
            }
        case 11:
            valuation.ceoRating = value
        default:
            ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
        }
        
        if let updatePaths = determineRowsToUpdateAfterUserEntry(indexPath: indexPath) {
            valuationListViewController.helperUpdatedRows(paths: updatePaths)
        }

        return
    }
    
    internal func determineRowsToUpdateAfterUserEntry(indexPath: IndexPath) -> [IndexPath]? {
        
        
        guard let validValuation = valuation else {
            ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "error assigning entered text: Controller doesn't have valuation")
            return nil
        }
        
        var paths: [IndexPath]?

        switch indexPath.section {
        case 0:
            return nil
        case 1:
            if indexPath.row > 0 && indexPath.row < (validValuation.bvps!.count) {
                paths = [indexPath]
                paths?.append(IndexPath(row: 0, section: 8))
                paths?.append(IndexPath(row: 1, section: 8))
            }
        case 2:
            if indexPath.row > 0 && indexPath.row < (validValuation.eps!.count) {
                paths = [indexPath]
//                paths?.append(IndexPath(row: 0, section: 8))
//                paths?.append(IndexPath(row: 1, section: 8))
            }
        case 3:
            if indexPath.row > 0 && indexPath.row < (validValuation.revenue!.count) {
                paths = [indexPath]
//                paths?.append(IndexPath(row: 0, section: 8))
//                paths?.append(IndexPath(row: 1, section: 8))
            }
        case 4:
            if indexPath.row > 0 && indexPath.row < (validValuation.oFCF!.count) {
                paths = [indexPath]
//                paths?.append(IndexPath(row: 0, section: 8))
//                paths?.append(IndexPath(row: 1, section: 8))
            }
        case 5:
            paths = [indexPath]
//            paths?.append(IndexPath(row: 0, section: 8))
//            paths?.append(IndexPath(row: 1, section: 8))
        case 6:
            return nil
        case 7:
            // Analyst predcited growht rates
            paths = [IndexPath(row: 0, section: 8),IndexPath(row: 1, section: 8) ]
        case 9:
            // 'Debt
            if indexPath.row == 0 {
                paths = [IndexPath(row: indexPath.row+1, section: indexPath.section)]
            }
        case 10:
            // 'Insider trading
            if indexPath.row > 0 {
                paths = [indexPath]
            }
        default:
            ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unexpected default encountered in determineRowsToUpdateAfterUserEntry")
        }
        
        return paths
    }

    
    func r1SectionTitles() -> [String] {
        return r1ValuationSectionTitles
    }
    
    func r1SectionSubTitles() -> [String] {
        return r1ValuationSectionSubtitles
    }
    
    internal func recalculateAvgGrowthRate() {
        
        var growthRateSum = bvpsGrowthRate.compactMap{ $0 }.reduce(0, +)
        growthRateSum += valuation?.growthEstimates?.compactMap{ $0 }.reduce(0, +) ?? 0.0
        
        averagePredictedGrowth = growthRateSum / (Double(bvpsGrowthRate.compactMap{ $0 }.count + (valuation?.growthEstimates?.compactMap{ $0 }.count ?? 0) ))
    }
    
    internal func recalculateGrowth(valueArray: [Double]?, index: Int, growthArray: [Double]?) -> [Double]? {
        
        var newGrowthArray = [Double]()
        newGrowthArray.append(contentsOf: growthArray ?? [Double]())

        guard index > 0 && index < (valueArray?.count ?? 0) else {
            return nil
        }
        
        guard let endValue = valueArray?.first else {
            return nil
        }
        
        guard endValue != 0 else {
            return nil
        }
        
        let rate = compoundGrowthRate(endValue: endValue, startValue: valueArray![index], years: Double(index))
        newGrowthArray.append(rate)
        
        return newGrowthArray
    }

}
