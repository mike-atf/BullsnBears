//
//  CombinedValuationController.swift
//  Bulls'N'Bears
//
//  Created by aDav on 12/01/2021.
//

import UIKit

protocol ValuationHelper {
    func rowTitles() -> [[String]]
    func getValue(indexPath: IndexPath) -> Any?
    func configureCell(indexPath: IndexPath, cell: ValuationTableViewCell)
    func userEnteredText(sender: UITextField, indexPath: IndexPath)
    func sectionTitles() -> [String]
    func sectionSubTitles() -> [String]
    func saveValuation()
}


class CombinedValuationController: ValuationHelper {
    
    var valuationListViewController: ValuationListViewController!
    var valuation: Any?
    var stockName: String!
    var method: ValuationMethods!
    var rowtitles: [[String]]!
//    var valuesArray = [[Any?]]()

    init(stockName: String, valuationMethod: ValuationMethods, listView: ValuationListViewController) {
        
        self.valuationListViewController = listView
        self.method = valuationMethod
        
        if valuationMethod == .rule1 {
            if let valuation = Rule1ValuationController.returnR1Valuations(company: stockName)?.first {
                self.valuation = valuation
            }
            else {
                self.valuation = Rule1ValuationController.createR1Valuation(company: stockName)
                if let existingDCFValuation = ValuationsController.returnDCFValuations(company: stockName)?.first {
                    (valuation as? Rule1Valuation)?.getDataFromDCFValuation(dcfValuation: existingDCFValuation)
                }
            }
            
//            valuesArray = getR1Values()
        }
        else if valuationMethod == .dcf {
            
            if let valuation = ValuationsController.returnDCFValuations(company: stockName)?.first {
                self.valuation = valuation
            }
            else {
                self.valuation = ValuationsController.createDCFValuation(company: stockName)
                if let existingR1Valuation = Rule1ValuationController.returnR1Valuations(company: stockName)?.first {
                    (valuation as? DCFValuation)?.getDataFromR1Valuation(r1Valuation: existingR1Valuation)
                }
            }
            
//            valuesArray = getDCFValues()
        }
//        recalculateRevenueGrowth()
//        recalculateIncomeGrowth()
//        recalculateFCFGrowth()
    }
    
    //MARK: - Delegate functions
    func sectionTitles() -> [String] {
        
        var titles = [String]()
        
        if method == .dcf {
            titles = ["General","Key Statistics", "Income Statement", "", "", "Balance Sheet", "Cash Flow", "", "Revenue & Growth prediction","","Adjusted future growth"]
        } else
        if method == .rule1 {
            titles = ["General",
            "Moat parameters: Values 5-10 years back",
            "", "", "", "",
            "PE Ratios", "Growth predictions",
            "Adj. growth prediction (Optional)",
            "Debt (Optional)",
            "Insider Trading (Optional)",
            "CEO Rating (Optional)"
            ]
        }
        
        return titles
    }
    
    func sectionSubTitles() -> [String] {
        
        var subtitles = [String]()
        
        if method == .dcf {
            subtitles = ["General","Yahoo Summary > Key Statistics", "Details > Financials > Income Statement", "", "", "Details > Financials > Balance Sheet", "Details > Financials > Cash Flow", "enter negative values (-)","Details > Analysis > Revenue estimate", "", ""]
        } else
        if method == .rule1 {
            subtitles = ["Creation date","1. Book Value per Share", "2. Earnings per Share", "3. Sales/ Revenue", "4. Free Cash Flow", "5. Return on Invested Capital", "min and max last 5-10 years", "Analysts min and max predictions","Adjust predicted growth rates", "", "", "Between 0 - 10"]
        }
        
        return subtitles
    }
    
    func getValue(indexPath: IndexPath) -> Any? {
        
        var valuesArray = [[Any?]]()
        
        if method == .dcf {
            valuesArray = getDCFValues()
        }
        else if method == .rule1 {
            valuesArray = getR1Values()
        }
        if indexPath.section < valuesArray.count {
            if indexPath.row < (valuesArray[indexPath.section].count) {
                return valuesArray[indexPath.section][indexPath.row]
            }
        }
        else {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "undefined indexpath \(indexPath) in Valuation.getDCFValue")
        }
        
        return nil
    }
    
    func userEnteredText(sender: UITextField, indexPath: IndexPath) {
        
        guard let validtext = sender.text else {
            return
        }
        
        guard validtext != "" else {
            return
        }
        
        guard let value = Double(validtext.filter("-0123456789.".contains)) else {
            ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "error converting entered text to number: \(sender.text ?? "no text")")
            return
        }
        
        if (self.valuation as? DCFValuation) != nil {
            convertUserEntryDCF(value, indexPath: indexPath)
        }
        else if (self.valuation as? Rule1Valuation) != nil {
            convertUserEntryR1(value, indexPath: indexPath)
        }
    }

    func configureCell(indexPath: IndexPath, cell: ValuationTableViewCell) {
        
        let value = getValue(indexPath: indexPath)
        let value$ = valueText(value: value, indexPath: indexPath)
        let title = (rowtitles ?? rowTitles())[indexPath.section][indexPath.row]
        let format = valueFormat(indexPath: indexPath)
        let (detail$, textColor) = getDetail$(indexPath: indexPath)
        
        cell.configure(title: title, value$: value$, detail: detail$ ?? "", indexPath: indexPath, method: method, delegate: self, valueFormat: format, detailColor: textColor)
    }
    
    func rowTitles() -> [[String]] {
        
         rowtitles = (method == .dcf) ? dcfRowTitles() : rule1RowTitles()
        return rowtitles
    }
    
    func saveValuation() {
        if let valuation = self.valuation as? DCFValuation  { valuation.save() }
        else if let valuation = self.valuation as? Rule1Valuation  { valuation.save() }
    }
    
    //MARK: - Internal functions
    
    internal func convertUserEntryDCF(_ value: Double, indexPath: IndexPath) {
        
        guard let valuation = self.valuation as? DCFValuation else {
            return
        }
        
        
        switch indexPath.section {
        case 0:
            // 'General
            switch indexPath.row {
            case 0:
                // date - do nothing
                return
            case 1:
                UserDefaults.standard.set(value / 100.0, forKey: "10YUSTreasuryBondRate")
            case 2:
                UserDefaults.standard.set(value / 100.0, forKey: "PerpetualGrowthRate")
            case 3:
                UserDefaults.standard.set(value / 100.0, forKey: "LongTermMarketReturn")
            default:
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "undefined indexpath \(indexPath) in DCFValuation.getValuationListItem")
            }
        case 1:
            // 'Key Statistics

            switch indexPath.row {
            case 0:
                valuation.marketCap = value
            case 1:
                valuation.beta = value
            case 2:
                valuation.sharesOutstanding = value
            default:
                ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
            }
        case 2:
            // 'Income Statement S1 - Revenue
            valuation.tRevenueActual![indexPath.row] = value
        case 3:
            // 'Income Statement S2 - net income
            valuation.netIncome![indexPath.row] = value
        case 4:
            // 'Income Statement S3 -
            switch indexPath.row {
            case 0:
                valuation.expenseInterest = value
            case 1:
                valuation.incomePreTax = value
            case 2:
                valuation.expenseIncomeTax = value
            default:
                ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
            }
        case 5:
            // 'balance sheet'
           switch indexPath.row {
            case 0:
                valuation.debtST = value
            case 1:
                valuation.debtLT = value
            default:
                ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
            }
        case 6:
            // 'Cash Flow S1
            valuation.tFCFo![indexPath.row] = value
        case 7:
            // 'Cash Flow S2
            if value > 0 { valuation.capExpend![indexPath.row]  = value * -1 }
            else {
                valuation.capExpend![indexPath.row] = value
            }
        case 8:
            // 'Prediction S1
            valuation.tRevenuePred![indexPath.row] = value
       case 9:
            // 'Prediction S2
            valuation.revGrowthPred![indexPath.row] = value / 100.0
        case 10:
            // adjsuted predicted growth rate
            valuation.revGrowthPredAdj![indexPath.row] = value / 100.0
        default:
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
        }
        
        if let updatePaths = rowsToUpdateAfterUserEntry(indexPath) {
            valuationListViewController.helperUpdatedRows(paths: updatePaths)
        }
        
        
//        print("user entered \(value), array now \(valuesArray)")

        var jumpToCellPath = IndexPath(row: indexPath.row+1, section: indexPath.section)
        if jumpToCellPath.row > rowtitles[indexPath.section].count-1 {
            jumpToCellPath = IndexPath(row: 0, section: indexPath.section + 1)
        }
         if jumpToCellPath.section < rowtitles.count {
            valuationListViewController.helperAskedToEnterNextTextField(targetPath: jumpToCellPath)
        }
    }
    
    internal func convertUserEntryR1(_ value: Double, indexPath: IndexPath) {
        
        guard let valuation = self.valuation as? Rule1Valuation else {
            return
        }
        
        switch indexPath.section {
        case 0:
            // 'General
            return
        case 1:
            // 'Moat parameters - BVPS
            valuation.bvps?.insert(value, at: indexPath.row)
        case 2:
            // 'Moat parameters - EPS
            valuation.eps?.insert(value, at: indexPath.row)
        case 3:
            // 'Moat parameters - Revenue
            valuation.revenue?.insert(value, at: indexPath.row)
        case 4:
            // 'Moat parameters - FCF
            valuation.oFCF?.insert(value, at: indexPath.row)
        case 5:
            // 'Moat parameters - ROIC
            valuation.roic?.insert(value / 100, at: indexPath.row)
        case 6:
            // 'Historical min /max PER
            valuation.hxPE?.insert(value, at: indexPath.row)
        case 7:
            // 'Growth predictions
            valuation.growthEstimates?.insert(value / 100, at: indexPath.row)
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
        
        if let updatePaths = rowsToUpdateAfterUserEntry(indexPath) {
            valuationListViewController.helperUpdatedRows(paths: updatePaths)
        }
        
        var jumpToCellPath = IndexPath(row: indexPath.row+1, section: indexPath.section)
        if jumpToCellPath.row > rowtitles[indexPath.section].count {
            jumpToCellPath = IndexPath(row: 0, section: indexPath.section + 1)
        }
         if jumpToCellPath.section < rowtitles.count {
            valuationListViewController.helperAskedToEnterNextTextField(targetPath: jumpToCellPath)
        }
    }

    internal func rowsToUpdateAfterUserEntry(_ indexPath: IndexPath) -> [IndexPath]? {
        
        if let valuation = self.valuation as? DCFValuation {

            var paths = [IndexPath(row: indexPath.row, section: indexPath.section)]

            switch indexPath.section {
//            case 0:
//                return nil
//            case 1:
//                return nil
            case 2:
                if indexPath.row > 0 && indexPath.row < (valuation.tRevenueActual!.count) {
                    paths.append(IndexPath(row: indexPath.row-1, section: indexPath.section))
                }
                paths.append(IndexPath(row: 0, section: 10))
                paths.append(IndexPath(row: 1, section: 10))
            case 3:
                if indexPath.row > 0 && indexPath.row < (valuation.netIncome!.count) {
                    paths.append(IndexPath(row: indexPath.row-1, section: indexPath.section))
                }
//            case 4:
//                paths.append(IndexPath(row: 1, section: indexPath.section))
            case 5:
//                paths = [indexPath]
                paths.append(IndexPath(row: 1, section: indexPath.section))
            case 6:
                if indexPath.row > 0 && indexPath.row < (valuation.tFCFo!.count) {
                    paths.append(IndexPath(row: indexPath.row-1, section: indexPath.section))
                }
            case 7:
                if indexPath.row > 0 && indexPath.row < (valuation.capExpend!.count) {
                    paths.append(IndexPath(row: indexPath.row-1, section: indexPath.section))
                }
            case 9:
                paths = [IndexPath(row: 0, section: 10)]
                paths.append(IndexPath(row: 1, section: 10))

            default:
                return nil
            }
            
            return paths
        }
        else if let valuation = self.valuation as? Rule1Valuation {
            
            var paths = [IndexPath(row: indexPath.row, section: indexPath.section)]

            switch indexPath.section {
//            case 0:
//                return nil
            case 1:
                if indexPath.row > 0 && indexPath.row < (valuation.bvps!.count) {
                    paths.append(IndexPath(row: 0, section: 8))
                    paths.append(IndexPath(row: 1, section: 8))
                }
//            case 2:
//                if indexPath.row > 0 && indexPath.row < (valuation.eps!.count) {
//                    paths = [indexPath]
//                }
//            case 3:
//                if indexPath.row > 0 && indexPath.row < (valuation.revenue!.count) {
//                    paths = [indexPath]
//                }
//            case 4:
//                if indexPath.row > 0 && indexPath.row < (valuation.oFCF!.count) {
//                    paths = [indexPath]
//                }
//            case 5:
//                paths = [indexPath]
//            case 6:
//                return nil
            case 7:
                // Analyst predcited growht rates
                paths.append(IndexPath(row: 0, section: 8))
                paths.append(IndexPath(row: 1, section: 8))
            case 9:
                // 'Debt
                if indexPath.row == 0 {
                    paths.append(IndexPath(row: indexPath.row+1, section: indexPath.section))
                }
//            case 10:
//                // 'Insider trading
//                if indexPath.row > 0 {
//                    paths = [indexPath]
//                }
            default:
                return nil
            }
            
            return paths

        }
        
        return nil
    }
    
    internal func getDetail$(indexPath: IndexPath) -> (String?, UIColor?) {
        
        return (method == .dcf) ? getDCFDetail$(indexPath) : getR1Detail$(indexPath)
    }
    
    internal func getDCFDetail$(_ indexPath: IndexPath) -> (String?, UIColor?) {
    
        guard let valuation = self.valuation as? DCFValuation else { return (nil,nil) }
        
        let section1$: String? = nil
        let section2$: String? = nil
        var color = UIColor.label
        
        var section3$: String? = (indexPath.row < (valuation.tRevenueActual?.count ?? 0) - 1) ? percentFormatter0Digits.string(from: calculateGrowthDCF(valuation.tRevenueActual, element:indexPath.row)! as NSNumber) : ""
        if indexPath.section == 2 {
            if (valuation.tRevenueActual?[indexPath.row] ?? 0.0) < 0 {
                color = UIColor(named: "Red")!
                section3$ = "! " + (section3$ ?? "")
            }
        }
        var section4$: String? = (indexPath.row < (valuation.netIncome?.count ?? 0) - 1) ? percentFormatter0Digits.string(from: calculateGrowthDCF(valuation.netIncome, element:indexPath.row)! as NSNumber) : ""
        if indexPath.section == 3 {
            if (valuation.netIncome?[indexPath.row] ?? 0.0) < 0 {
                color = UIColor(named: "Red")!
                section4$ = "! " + (section4$ ?? "")
            }
        }

// section4
        var taxProportion: Double?
        var taxProportion$: String?
        if (valuation.incomePreTax) > 0 {
            taxProportion = ((valuation.expenseIncomeTax) / valuation.incomePreTax)
            taxProportion$ = percentFormatter0Digits.string(from: taxProportion! as NSNumber)
        }
        var section5$: String? // = [nil, nil, taxProportion$]
        if indexPath.row < 2 {
            section5$ = nil
        } else if indexPath.row == 2 {
            section5$ = taxProportion$
        }

// section5
        var stDebtProportion: Double?
        var stDebtPorportion$: String?
        if (valuation.marketCap) > 0 {
            stDebtProportion = (valuation.debtST) / ((valuation.debtST) + valuation.marketCap)
            stDebtPorportion$ = percentFormatter0Digits.string(from: stDebtProportion! as NSNumber)
        }
        var ltDebtProportion: Double?
        var ltDebtPorportion$: String?
        if (valuation.marketCap) > 0 {
            ltDebtProportion =  (valuation.debtLT) / ((valuation.debtLT) + valuation.marketCap)
            ltDebtPorportion$ = percentFormatter0Digits.string(from: ltDebtProportion! as NSNumber)
        }
        var section6$: String?
        if indexPath.row == 0 {
            section6$ = stDebtPorportion$
        } else if indexPath.row == 1 {
            section6$ = ltDebtPorportion$
        }
        
//section 6
        let section7$: String? = (indexPath.row < (valuation.tFCFo?.count ?? 0) - 1) ? percentFormatter0Digits.string(from: calculateGrowthDCF(valuation.tFCFo, element:indexPath.row)! as NSNumber) : ""

        let section8$: String? = (indexPath.row < (valuation.capExpend?.count ?? 0) - 1) ? percentFormatter0Digits.string(from: calculateGrowthDCF(valuation.capExpend, element:indexPath.row)! as NSNumber) : ""

        let section9$: String? = nil
        let section10$: String? = averageGrowthPrediction() != nil ? percentFormatter0Digits.string(from: averageGrowthPrediction()! as NSNumber) : nil
        let section11$: String? = nil
        
        let detailsArray = [section1$, section2$, section3$, section4$, section5$, section6$, section7$, section8$, section9$, section10$,section11$]
        
        return (detailsArray[indexPath.section], color)
        
    }
        
    internal func getR1Detail$(_ indexPath: IndexPath) -> (String?,UIColor?) {
        
        guard let valuation = self.valuation as? Rule1Valuation else { return (nil, nil) }

        switch indexPath.section {
        case 0:
            // 'General
            return (nil, nil)
        case 1:
            // 'Moat parameters - BVPS
            if indexPath.row == 9 || indexPath.row == 0 { return (nil, nil) }
            else if let growth = calculateGrowthR1(valueArray: valuation.bvps, element: indexPath.row) {
                let color = growth < 0.1 ? UIColor(named: "Red") : UIColor(named: "Green")
                return (percentFormatter0Digits.string(from: growth as NSNumber), color)
            }
            return (nil, nil)
        case 2:
            // 'Moat parameters - EPS
            if indexPath.row == 9 || indexPath.row == 0 { return (nil, nil) }
            else if let growth = calculateGrowthR1(valueArray: valuation.eps, element: indexPath.row) {
                let color = growth < 0.1 ? UIColor(named: "Red") : UIColor(named: "Green")
                return (percentFormatter0Digits.string(from: growth as NSNumber), color)
            }
            return (nil, nil)

        case 3:
            // 'Moat parameters - Revenue
            if indexPath.row == 9 || indexPath.row == 0 { return (nil, nil) }
            else if let growth = calculateGrowthR1(valueArray: valuation.revenue, element: indexPath.row) {
                let color = growth < 0.1 ? UIColor(named: "Red") : UIColor(named: "Green")
                return (percentFormatter0Digits.string(from: growth as NSNumber), color)
            }
            return (nil, nil)

        case 4:
            // 'Moat parameters - FCF
            if indexPath.row == 9 || indexPath.row == 0 { return (nil, nil) }
            else if let growth = calculateGrowthR1(valueArray: valuation.oFCF, element: indexPath.row) {
                let color = growth < 0.1 ? UIColor(named: "Red") : UIColor(named: "Green")
                return (percentFormatter0Digits.string(from: growth as NSNumber), color)
            }
            return (nil, nil)

        case 5:
            // 'Moat parameters - ROIC
            if indexPath.row == 9 { return (nil, nil) }
            else if (valuation.roic?.count ?? 0) > indexPath.row {
                let color = valuation.roic![indexPath.row] < 0.1 ? UIColor(named: "Red") : UIColor(named: "Green")
                return (percentFormatter0Digits.string(from: valuation.roic![indexPath.row] as NSNumber), color)
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
            else if let fcf = valuation.oFCF?.first {
                if fcf > 0 {
                    let proportion = (valuation.debt) / fcf
                    return (percentFormatter2Digits.string(from: proportion as NSNumber), nil)
                }
            }
            else {
                return (nil, nil)
            }
        case 10:
            // 'Insider Stocks'
            if valuation.insiderStocks == 0.0 { return (nil, nil) }
            if indexPath.row == 0 {
                return (nil, nil)

            } else if indexPath.row == 1 {
                if valuation.insiderStocks > 0 {
                    let proportion = (valuation.insiderStockBuys) / valuation.insiderStocks
                    return (percentFormatter2Digits.string(from: proportion as NSNumber), nil)
                }
            }
            else if indexPath.row == 2 {
                if valuation.insiderStocks > 0 {
                    let proportion = (valuation.insiderStockSells) / valuation.insiderStocks
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
        
    internal func dcfRowTitles() -> [[String]] {
        
        guard let dcfValuation = valuation as? DCFValuation else {
            return [[]]
        }
        
        let yearOnlyFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = NSLocale.current
            formatter.timeZone = NSTimeZone.local
            formatter.dateFormat = "YYYY"
            return formatter
        }()
        
        var section0Titles = ["Total revenue"]
        var section1Titles = ["Net income"]
        var section2Titles = ["op. Cash flow"]
        var section3Titles = ["Capital expend."]
        var section4Titles = ["Revenue estimate"]
        var section5Titles = ["Sales growth"]
        var section6Titles = ["Adj. sales growth"]
        
        let generalSectionTitles = ["Date", "US 10y Treasure Bond rate", "Perpetual growth rate", "Exp. LT Market return"]
        let keyStatsTitles = ["Market cap", "beta", "Shares outstdg. (in thousands)"]
        let singleIncomeSectionTitles = ["Interest expense","Pre-Tax income","Income tax expend."]
        let balanceSheetSectionTitles = ["Current debt","Long term debt"]

        var count = 0
        for i in stride(from: 4, to: 0, by: -1) {
            let date = (dcfValuation.creationDate ?? Date()).addingTimeInterval(Double(i * -1) * 366 * 24 * 3600)
            let year$ = yearOnlyFormatter.string(from: date)
            
            var newTitle = section0Titles.first! + " " + year$
            section0Titles.insert(newTitle, at: 1)
            
            newTitle = section1Titles.first! + " " + year$
            section1Titles.insert(newTitle, at: 1)

            newTitle = section2Titles.first! + " " + year$
            section2Titles.insert(newTitle, at: 1)

            newTitle = section3Titles.first! + " " + year$
            section3Titles.insert(newTitle, at: 1)
            
            count += 1
        }
        
        for i in 0..<2 {
            let date = (dcfValuation.creationDate ?? Date()).addingTimeInterval(Double(i) * 366 * 24 * 3600)
            let year$ = yearOnlyFormatter.string(from: date)
            
            var newTitle = section4Titles.first! + " " + year$
            section4Titles.append(newTitle)
            newTitle = section5Titles.first! + " " + year$
            section5Titles.append(newTitle)
        }
        
        for i in 0..<2 {
            let date = (dcfValuation.creationDate ?? Date()).addingTimeInterval(Double(i+2) * 366 * 24 * 3600)
            let year$ = yearOnlyFormatter.string(from: date)
            
            let newTitle = section6Titles.first! + " " + year$
            section6Titles.append(newTitle)
        }

        
        section0Titles.removeFirst()
        section1Titles.removeFirst()
        section2Titles.removeFirst()
        section3Titles.removeFirst()
        section4Titles.removeFirst()
        section5Titles.removeFirst()
        section6Titles.removeFirst()
        
        var incomeSection1Titles = [String]()
        var incomeSection2Titles = [String]()
        var incomeSection3Titles = [String]()
        var cashFlowSection1Titles = [String]()
        var cashFlowSection2Titles = [String]()
        var predictionSection1Titles = [String]()
        var predictionSection2Titles = [String]()

        incomeSection1Titles.append(contentsOf: section0Titles)
        incomeSection2Titles.append(contentsOf: section1Titles)
        incomeSection3Titles.append(contentsOf: singleIncomeSectionTitles)
        
        cashFlowSection1Titles.append(contentsOf: section2Titles)
        cashFlowSection2Titles.append(contentsOf: section3Titles)
        
        predictionSection1Titles.append(contentsOf: section4Titles)
        predictionSection2Titles.append(contentsOf: section5Titles)
        
        rowtitles = [generalSectionTitles ,keyStatsTitles, incomeSection1Titles, incomeSection2Titles, incomeSection3Titles, balanceSheetSectionTitles, cashFlowSection1Titles, cashFlowSection2Titles, predictionSection1Titles,predictionSection2Titles, section6Titles]
        
        return rowtitles

    }
    
    internal func rule1RowTitles() -> [[String]] {
        
        guard let rule1Valuation = valuation as? Rule1Valuation else {
            return [[]]
        }

        
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
            let date = (rule1Valuation.creationDate ?? Date()).addingTimeInterval(Double(i * -1) * 366 * 24 * 3600)
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
        
        rowtitles = [generalSectionTitles ,bvpsTitles, epsTitles, revenueTitles, fcfTitles, roicTitles, hxPERTitles, growthPredTitles, adjGrowthPredTitles, debtRowTitles, insideTradingRowTitles, ceoRatingRowTitle]

        return rowtitles


    }
    
    internal func valueText(value: Any?, indexPath: IndexPath) -> String? {
        
        guard  let validValue = value else {
            return nil
        }
        
        let percentWith2Digits = (method == .dcf) ? [0,9,10] : [7,5,8]
        let numberWithDigits = (method == .dcf) ? [1] : [6,11]
        let numberNoDigits = (method == .dcf) ? [] : [10]
        let currencyGapWithPence = (method == .dcf) ? [] : [1,2,3,4]
        let currencyGapNoPence = (method == .dcf) ? [2,3,4,5,6,7,8] : []
        
        // r1 Section 9 have two different formats
        
        if let date = validValue as? Date {
            return dateFormatter.string(from: date)
        }
        
        else if let number = validValue as? Double {
            if percentWith2Digits.contains(indexPath.section) {
                    return percentFormatter2Digits.string(from: number as NSNumber)
            }
            else if numberNoDigits.contains(indexPath.section) {
                return numberFormatterNoFraction.string(from: number as NSNumber)
            }
            else if numberWithDigits.contains(indexPath.section) {
                return numberFormatterWithFraction.string(from: number as NSNumber)
            }
            else if currencyGapWithPence.contains(indexPath.row) {
                return currencyFormatterGapWithPence.string(from: number as NSNumber)
            }
            else if currencyGapNoPence.contains(indexPath.section) {
                return currencyFormatterGapNoPence.string(from: number as NSNumber)
            }
            else if [9].contains(indexPath.section) {
                // Rule 1 'Debt section'
                if indexPath.row == 0 {
                    return numberFormatterWithFraction.string(from: number as NSNumber)
                }
                else {
                    return percentFormatter2Digits.string(from: number as NSNumber)
                }
            }
        }
        else if let t$ = validValue as? String {
            return t$
        }
        return nil

    }

    internal func valueFormat(indexPath: IndexPath) -> ValuationCellValueFormat {
        
        let dcfFormats:[[ValuationCellValueFormat]] = [[.date, .percent, .percent, .percent],
                                                       [.currency, .numberWithDecimals, .numberNoDecimals],
                                                       [.currency,.currency,.currency,.currency],
                                                       [.currency,.currency, .currency, .currency],
                                                       [.currency, .currency, .currency],
                                                       [.currency, .currency],
                                                       [.currency,.currency,.currency,.currency],
                                                       [.currency,.currency,.currency,.currency],
                                                       [.currency,.currency],
                                                       [.percent,.percent],
                                                       [.percent,.percent]]
                                                       
        let r1Formats:[[ValuationCellValueFormat]] = [[.date],
                                                      [.currency],
                                                      [.currency],
                                                      [.currency],
                                                      [.currency],
                                                      [.percent],
                                                      [.numberWithDecimals],
                                                      [.percent],
                                                      [.percent],
                                                      [.currency, .percent],
                                                      [.numberWithDecimals]]
        
        let formats = method == .dcf ? dcfFormats : r1Formats
        if indexPath.section < formats.count {
            if indexPath.row < formats[indexPath.section].count {
                return formats[indexPath.section][indexPath.row]
            }
        }
        
        return .numberWithDecimals
    }
        
    internal func getDCFValues() -> [[Any?]] {
        
        guard let valuation = (self.valuation as? DCFValuation) else { return [[nil]] }
        
        let section1:[Any] = [valuation.creationDate ?? Date(),
                     UserDefaults.standard.value(forKey: "10YUSTreasuryBondRate") as! Double,
                     UserDefaults.standard.value(forKey: "PerpetualGrowthRate") as! Double,
                     UserDefaults.standard.value(forKey: "LongTermMarketReturn") as! Double]
        let section2 = [valuation.marketCap, valuation.beta, valuation.sharesOutstanding]
        let section3 = valuation.tRevenueActual ?? []
        let section4 = valuation.netIncome ?? []
        let section5 = [valuation.expenseInterest, valuation.incomePreTax, valuation.expenseIncomeTax]
        let section6 = [valuation.debtST, valuation.debtLT]
        let section7 = valuation.tFCFo ?? []
        let section8 = valuation.capExpend ?? []
        let section9 = valuation.tRevenuePred ?? []
        let section10 = valuation.revGrowthPred ?? []
        let prediction = averageGrowthPrediction()
        let section11 = [prediction, prediction]
        
        return [section1, section2, section3, section4, section5, section6, section7, section8, section9, section10, section11]
        
    }
    
    internal func getR1Values() -> [[Any?]]  {
        
        guard let valuation = (self.valuation as? Rule1Valuation) else { return [[nil]] }
        
        let section1:[Any] = [valuation.creationDate ?? Date()]
        let section2 = valuation.bvps ?? []
        let section3 = valuation.eps ?? []
        let section4 = valuation.revenue ?? []
        let section5 = valuation.oFCF ?? []
        let section6 = valuation.roic ?? []
        let section7 = valuation.hxPE ?? []
        
        var averageGrowth = [Double?]()
        if let growth = averageGrowthPrediction() {
            averageGrowth = [growth, growth]
        }
        let section8 = valuation.growthEstimates ?? averageGrowth
        
        let section9 = [valuation.debt, debtProportion()]
        let section10 = [valuation.insiderStocks, valuation.insiderStockBuys, valuation.insiderStockSells]
        let section11 = [valuation.ceoRating]

        return [section1, section2, section3, section4, section5, section6, section7, section8, section9, section10, section11]

    }
    
    internal func debtProportion() -> Double? {
        
        if let validFCF = (valuation as? Rule1Valuation)?.oFCF?.first {
            if validFCF > 0 {
                if let validDebt = (valuation as? Rule1Valuation)?.debt {
                    return validDebt / validFCF
                }
            }
        }
            
        return nil
    }
    
    internal func averageGrowthPrediction() -> Double? {
        
        if let valuation = self.valuation as? DCFValuation {
            
            guard valuation.tRevenueActual?.count ?? 0 > 0 || valuation.revGrowthPredAdj?.count ?? 0 > 0 else {
                return nil
            }
            
            var revenueGrowthRates = [Double]()
            revenueGrowthRates.append(contentsOf: valuation.revGrowthPred ?? [])
            for i in 1..<(valuation.revGrowthPred?.count ?? 0) {
                if valuation.revGrowthPred![i] > 0 {
                    let growth = (valuation.tRevenueActual![i-1] - valuation.tRevenueActual![i]) / valuation.tRevenueActual![i]
                    revenueGrowthRates.append(growth)
                }
            }
            
            if revenueGrowthRates.count > 0 {
                return (revenueGrowthRates.compactMap{ $0 }.reduce(0, +) ) / Double(revenueGrowthRates.count)
            }
            else { return nil }
        }
        else if let valuation = self.valuation as? Rule1Valuation  {

            guard valuation.bvps?.count ?? 0 > 0 || valuation.growthEstimates?.count ?? 0 > 0 else {
                return nil
            }
            
            var growthRateSum: Double?
            
            if let sum = valuation.bvps?.compactMap({ $0 }).reduce(0, +) {
                growthRateSum = sum + (valuation.growthEstimates?.compactMap{ $0 }.reduce(0, +) ?? 0.0)
                
                return growthRateSum! / (Double((valuation.bvps?.compactMap{ $0 }.count ?? 0) + (valuation.growthEstimates?.compactMap{ $0 }.count ?? 0)))
            }
        }
        return nil
    }
    
    internal func calculateGrowthDCF(_ array: [Double]?, element: Int) -> Double? {
        
        // returns detail value for the SAME row based on any existing later elements
        
        guard let numbers = array else {
            return nil
        }
        
        guard numbers.count > (element + 1) else {
            return nil
        }
        
        return (numbers[element] - numbers[element+1]) / abs(numbers[element+1])
                
    }
 
    internal func calculateGrowthR1(valueArray: [Double]?, element: Int) -> Double? {
        
        guard element > 0 && element < (valueArray?.count ?? 0) else {
            return nil
        }
        
        guard let endValue = valueArray?.first else {
            return nil
        }
        
        guard endValue != 0 else {
            return nil
        }
        
        return compoundGrowthRate(endValue: endValue, startValue: valueArray![element], years: Double(element))
    }

    internal func compoundGrowthRate(endValue: Double, startValue: Double, years: Double) -> Double {
        
        return (pow((endValue / startValue) , (1/years)) - 1)
    }

}
