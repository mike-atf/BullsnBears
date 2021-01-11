//
//  ValuationsController.swift
//  TrendMyStocks
//
//  Created by aDav on 03/01/2021.
//

import UIKit
import CoreData

protocol DCFValuationHelper {
    func buildRowTitles() -> [[String]]
    func getDCFValue(indexPath: IndexPath) -> Any?
    func configureCell(indexPath: IndexPath, cell: ValuationTableViewCell)
    func userEnteredText(sender: UITextField, indexPath: IndexPath)
    func dcfSectionTitles() -> [String]
    func dcfSectionSubTitles() -> [String]
}

class ValuationsController : DCFValuationHelper {
    
    var rowTitles: [[String]]?
    var valuationListViewController: ValuationListViewController!
    var valuation: DCFValuation?
    var revenueGrowthRates = [Double]()
    var netIncomeGrowthRates = [Double]()
    var fcfGrowthRates = [Double]()
    var averagePredictedRevGrowth: Double?

    let dcfValuationSectionTitles = ["General","Key Statistics", "Income Statement", "", "", "Balance Sheet", "Cash Flow", "", "Revenue & Growth prediction","","Adjusted future growth"]
    let dcfValuationSectionSubtitles = ["General","Yahoo Summary > Key Statistics", "Details > Financials > Income Statement", "", "", "Details > Financials > Balance Sheet", "Details > Financials > Cash Flow", "","Details > Analysis > Revenue estimate", "", ""]
    
       
    init(listView: ValuationListViewController) {
        self.valuationListViewController = listView
        self.valuation = listView.dcfValuation
        recalculateRevenueGrowth()
        recalculateIncomeGrowth()
        recalculateFCFGrowth()
    }

    
    static func returnDCFValuations(company: String? = nil) -> [DCFValuation]? {
        
        var valuations: [DCFValuation]?
        
        let fetchRequest = NSFetchRequest<DCFValuation>(entityName: "DCFValuation")
        if let validName = company {
            let predicate = NSPredicate(format: "company BEGINSWITH %@", argumentArray: [validName])
            fetchRequest.predicate = predicate
        }
        
        do {
            valuations = try managedObjectContext.fetch(fetchRequest)
            } catch let error {
                ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: error, errorInfo: "error fetching dcfValuations")
        }

        return valuations
    }
    
    static func createDCFValuation(company: String) -> DCFValuation? {
        let newValuation:DCFValuation? = {
            NSEntityDescription.insertNewObject(forEntityName: "DCFValuation", into: managedObjectContext) as? DCFValuation
        }()
        newValuation?.company = company
        do {
            try  managedObjectContext.save()
        } catch {
            let error = error
            ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: error, errorInfo: "error creating and saving dcfValuations")
        }

        return newValuation
    }
    
    static func createR1Valuation(company: String) -> Rule1Valuation? {
        let newValuation:Rule1Valuation? = {
            NSEntityDescription.insertNewObject(forEntityName: "Rule1Valuation", into: managedObjectContext) as? Rule1Valuation
        }()
        newValuation?.company = company
        do {
            try  managedObjectContext.save()
        } catch {
            let error = error
            ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: error, errorInfo: "error creating and saving Rule1Valuation")
        }

        return newValuation
    }

    
    public func dcfSectionTitles() -> [String] {
        return dcfValuationSectionTitles
    }
    
    public func dcfSectionSubTitles() -> [String] {
        return dcfValuationSectionSubtitles
    }
    
    internal func cellValueFormat(indexPath: IndexPath) -> ValuationCellValueFormat {
        
        switch indexPath.section {
        case 0:
            // 'General
            switch indexPath.row {
            case 0:
                return .date
            case 1:
                return .percent
            case 2:
                return .percent
            case 3:
                return .percent
            default:
                ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
            }
        case 1:
            // 'Key Statistics
            switch indexPath.row {
            case 0:
                return .currency
            case 1:
                return .numberWithDecimals
            case 2:
                return .numberNoDecimals
            default:
                ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")

            }
        case 2:
            // 'Income Statement S1 - Revenue
            return .currency
        case 3:
            // 'Income Statement S2 - net income
            return .currency
        case 4:
            // 'Income Statement S3 -
            switch indexPath.row {
            case 0:
                return .currency
            case 1:
                return .currency
            case 2:
                return .currency
            default:
                ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
            }
        case 5:
            // 'balance sheet'
            switch indexPath.row {
            case 0:
                return .currency
            case 1:
                return .currency
            default:
                ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
            }
        case 6:
            // 'Cash Flow S1
            return .currency
        case 7:
            // 'Cash Flow S2
            return .currency
        case 8:
            // 'Prediction S1
            return .currency
       case 9:
            // 'Prediction S2
            return .percent
        case 10:
            // adjsuted predcited growth rate
            return .percent
        default:
            ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
        }
        
        return .numberWithDecimals
    }
    
    public func configureCell(indexPath: IndexPath, cell: ValuationTableViewCell) {
        
        let value = getDCFValue(indexPath: indexPath)
        let value$ = getCellValueText(value: value, indexPath: indexPath)
        let rowTitle = (rowTitles ?? buildRowTitles())[indexPath.section][indexPath.row]
        let format = cellValueFormat(indexPath: indexPath)
        let detail$ = getDetail$(indexPath: indexPath) ?? ""
        
        cell.configure(title: rowTitle, value$: value$, detail: detail$, indexPath: indexPath, dcfDelegate: self, r1Delegate: nil, valueFormat: format)
    }
    
    func userEnteredText(sender: UITextField, indexPath: IndexPath) {
        
        guard let validtext = sender.text else {
            return
        }
        
        guard let value = Double(validtext.filter("0123456789.".contains)) else {
            ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "error converting entered text to number: \(sender.text ?? "no text")")
            return
        }
        
        guard let validValuation = valuation else {
            ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "error assigning entered text: Controller doesn't have valuation")
            return
        }
        
        var jumpToCellPath: IndexPath?

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
            jumpToCellPath = IndexPath(row: indexPath.row, section: indexPath.section)
            jumpToCellPath!.row += 1

            switch indexPath.row {
            case 0:
                validValuation.marketCap = value
            case 1:
                validValuation.beta = value
            case 2:
                validValuation.sharesOutstanding = value
                jumpToCellPath = IndexPath(row: 0, section: indexPath.section+1)
            default:
                ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
            }
        case 2:
            // 'Income Statement S1 - Revenue
            jumpToCellPath = IndexPath(row: indexPath.row, section: indexPath.section)
            jumpToCellPath!.row += 1
            validValuation.tRevenueActual![indexPath.row] = value
            recalculateRevenueGrowth()
            jumpToCellPath = IndexPath(row: 0, section: indexPath.section+1)
        case 3:
            // 'Income Statement S2 - net income
            jumpToCellPath = IndexPath(row: indexPath.row, section: indexPath.section)
            jumpToCellPath!.row += 1
            validValuation.netIncome![indexPath.row] = value
            recalculateIncomeGrowth()
            jumpToCellPath = IndexPath(row: 0, section: indexPath.section+1)
        case 4:
            // 'Income Statement S3 -
            jumpToCellPath = IndexPath(row: indexPath.row, section: indexPath.section)
            jumpToCellPath!.row += 1
            switch indexPath.row {
            case 0:
                validValuation.expenseInterest = value
            case 1:
                validValuation.incomePreTax = value
            case 2:
                validValuation.expenseIncomeTax = value
                jumpToCellPath = IndexPath(row: 0, section: indexPath.section+1)
            default:
                ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
            }
        case 5:
            // 'balance sheet'
            jumpToCellPath = IndexPath(row: indexPath.row, section: indexPath.section)
            jumpToCellPath!.row += 1
           switch indexPath.row {
            case 0:
                validValuation.debtST = value
            case 1:
                validValuation.debtLT = value
                jumpToCellPath = IndexPath(row: 0, section: indexPath.section+1)
            default:
                ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
            }
        case 6:
            // 'Cash Flow S1
            jumpToCellPath = IndexPath(row: indexPath.row, section: indexPath.section)
            jumpToCellPath!.row += 1
            validValuation.tFCFo![indexPath.row] = value
            recalculateFCFGrowth()
            jumpToCellPath = IndexPath(row: 0, section: indexPath.section+1)
        case 7:
            // 'Cash Flow S2
            jumpToCellPath = IndexPath(row: indexPath.row, section: indexPath.section)
            jumpToCellPath!.row += 1
            validValuation.capExpend![indexPath.row] = value
            jumpToCellPath = IndexPath(row: 0, section: indexPath.section+1)
        case 8:
            // 'Prediction S1
            jumpToCellPath = IndexPath(row: indexPath.row, section: indexPath.section)
            jumpToCellPath!.row += 1
            validValuation.tRevenuePred![indexPath.row] = value
            jumpToCellPath = IndexPath(row: 0, section: indexPath.section+1)
       case 9:
            // 'Prediction S2
            jumpToCellPath = IndexPath(row: indexPath.row, section: indexPath.section)
            jumpToCellPath!.row += 1
            validValuation.revGrowthPred![indexPath.row] = value / 100.0
            recalculateAvgGrowthRate()
            jumpToCellPath = IndexPath(row: 0, section: indexPath.section+1)
        case 10:
            // adjsuted predicted growth rate
            validValuation.revGrowthPredAdj![indexPath.row] = value / 100.0
        default:
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
        }
        
        if let updatePaths = determineRowsToUpdateAfterUserEntry(indexPath: indexPath) {
            valuationListViewController.helperUpdatedRows(paths: updatePaths)
        }
//        if let jumpPath = jumpToCellPath {
//            valuationListViewController.helperAskedToEnterNextTextField(targetPath: jumpPath)
//        }

    }
    
    internal func determineRowsToUpdateAfterUserEntry(indexPath: IndexPath) -> [IndexPath]? {
        
        
        guard let validValuation = valuation else {
            ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "error assiging entered text: Controller doesn't have valuation")
            return nil
        }
        
        var paths: [IndexPath]?

        switch indexPath.section {
        case 0:
            return nil
        case 1:
            return nil
        case 2:
            if indexPath.row > 0 && indexPath.row < (validValuation.tRevenueActual!.count) {
                paths = [IndexPath(row: indexPath.row-1, section: indexPath.section)]
            }
            paths?.append(IndexPath(row: 0, section: 10))
            paths?.append(IndexPath(row: 1, section: 10))
        case 3:
            if indexPath.row > 0 && indexPath.row < (validValuation.netIncome!.count) {
                paths = [IndexPath(row: indexPath.row-1, section: indexPath.section)]
            }
        case 4:
            if indexPath.row == 2 {
                paths = [indexPath]
            }
        case 5:
            paths = [indexPath]
        case 6:
            if indexPath.row > 0 && indexPath.row < (validValuation.tFCFo!.count) {
                paths = [IndexPath]()
                let newpath = IndexPath(row: indexPath.row-1, section: indexPath.section)
                paths?.append(newpath)
            }
        case 9:
            paths = [IndexPath(row: 0, section: 10)]
            paths?.append(IndexPath(row: 1, section: 10))

        default:
            ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unexpected default encountered in determineRowsToUpdateAfterUserEntry")
        }
        
        return paths
    }
    
    internal func recalculateRevenueGrowth() {
        
        revenueGrowthRates.removeAll()
        
        for i in 1..<(valuation?.tRevenueActual?.count ?? 0) {
            if valuation!.tRevenueActual![i] > 0 {
                let rate = (valuation!.tRevenueActual![i-1] - valuation!.tRevenueActual![i]) / valuation!.tRevenueActual![i]
                revenueGrowthRates.append(rate)
            }
            else {
                revenueGrowthRates.append(Double()) // add fifth unused element to allow return in 'getDetailValue'
            }
        }
        revenueGrowthRates.append(Double())
        
        recalculateAvgGrowthRate()
    }
    
    internal func recalculateAvgGrowthRate() {
        
        var growthRateSum = revenueGrowthRates.compactMap{ $0 }.reduce(0, +)
        growthRateSum += valuation?.revGrowthPred?.compactMap{ $0 }.reduce(0, +) ?? 0.0
        
        averagePredictedRevGrowth = growthRateSum / Double(revenueGrowthRates.compactMap{ $0 }.count + (valuation?.revGrowthPred?.compactMap{ $0 }.count ?? 0) )
    }
    
    internal func recalculateIncomeGrowth() {
        
        netIncomeGrowthRates.removeAll()
        
        for i in 1..<(valuation?.tRevenueActual?.count ?? 0) {
            if valuation!.tRevenueActual![i] > 0 {
                let rate = (valuation!.netIncome![i-1] - valuation!.netIncome![i]) / valuation!.tRevenueActual![i]
                netIncomeGrowthRates.append(rate)
            }
            else {
                netIncomeGrowthRates.append(Double())
            }
        }
        netIncomeGrowthRates.append(Double()) // add fifth unused element to allow return in 'getDetailValue'
        
    }
    
    internal func recalculateFCFGrowth() {
        
        fcfGrowthRates.removeAll()
        
        for i in 1..<(valuation?.tFCFo?.count ?? 0) {
            if valuation!.tFCFo![i] > 0 {
                let rate = (valuation!.tFCFo![i-1] - valuation!.tFCFo![i]) / valuation!.tFCFo![i]
                fcfGrowthRates.append(rate)
            }
            else {
                fcfGrowthRates.append(Double())
            }
        }
        fcfGrowthRates.append(Double()) // add fifth unused element to allow return in 'getDetailValue'
        
    }


    
    internal func getCellValueText(value: Any?, indexPath: IndexPath) -> String? {
        
        var value$: String?

        if let validValue = value {
            if let date = validValue as? Date {
                value$ = dateFormatter.string(from: date)
            }
            else if let number = validValue as? Double {
                if [0,9,10].contains(indexPath.section) {
                    value$ = percentFormatter2Digits.string(from: number as NSNumber)
               }
                else {
                    if indexPath == IndexPath(item: 1, section: 1) || indexPath == IndexPath(item: 2, section: 1) {
                        // beta
                        value$ = numberFormatterWithFraction.string(from: number as NSNumber)
                    } else {
                        value$ = currencyFormatterGapNoPence.string(from: number as NSNumber)
                    }
                }
            }
            else if let text = validValue as? String {
                value$ = text
            }
        }
        
        return value$

    }
    
    internal func getDCFValue(indexPath: IndexPath) -> Any? {
        
        guard let valuation = valuation else { return nil }
        
        switch indexPath.section {
        case 0:
            // 'General
            switch indexPath.row {
            case 0:
                return valuation.creationDate
            case 1:
                return UserDefaults.standard.value(forKey: "10YUSTreasuryBondRate") as! Double
            case 2:
                return UserDefaults.standard.value(forKey: "PerpetualGrowthRate") as! Double
            case 3:
                return UserDefaults.standard.value(forKey: "LongTermMarketReturn") as! Double
            default:
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "undefined indexpath \(indexPath) in DCFValuation.returnValuationListItem")
            }
        case 1:
            // 'Key Statistics
            switch indexPath.row {
            case 0:
                return valuation.marketCap
            case 1:
                return valuation.beta
            case 2:
                return valuation.sharesOutstanding
            default:
                ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
            }
        case 2:
            // 'Income Statement S1 - Revenue
            return valuation.tRevenueActual![indexPath.row]
        case 3:
            // 'Income Statement S2 - net income
            return valuation.netIncome![indexPath.row]
        case 4:
            // 'Income Statement S3 -
            switch indexPath.row {
            case 0:
                return valuation.expenseInterest
            case 1:
                return valuation.incomePreTax
            case 2:
                return valuation.expenseIncomeTax
            default:
                ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
            }
        case 5:
            // 'balance sheet'
            switch indexPath.row {
            case 0:
                return valuation.debtST
            case 1:
                return valuation.debtLT
            default:
                ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
            }
        case 6:
            // 'Cash Flow S1
            return valuation.tFCFo![indexPath.row]
        case 7:
            // 'Cash Flow S2
            return valuation.capExpend![indexPath.row]
        case 8:
            // 'Prediction S1
            return valuation.tRevenuePred![indexPath.row]
       case 9:
            // 'Prediction S2
            return valuation.revGrowthPred![indexPath.row]
        case 10:
            // adjsuted predcited growth rate
            return averagePredictedRevGrowth
        default:
            ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
        }
        
        return "error"

    }
    
    internal func getDetail$(indexPath: IndexPath) -> String? {
        
        switch indexPath.section {
        case 0:
            // 'General
            return nil
        case 1:
            // 'Key Statistics
            return nil
        case 2:
            // 'Income Statement S1 - Revenue
            if indexPath.row < (valuation?.tRevenueActual?.count ?? 0) - 1 {
                return percentFormatter2Digits.string(from: revenueGrowthRates[indexPath.row] as NSNumber)
            }
            else { return "" }
        case 3:
            // 'Income Statement S2 - net income
            if indexPath.row < (valuation?.netIncome?.count ?? 0) - 1 {
                return percentFormatter2Digits.string(from: netIncomeGrowthRates[indexPath.row] as NSNumber)
            }
            else { return "" }
        case 4:
            // 'Income Statement S3 -
            switch indexPath.row {
            case 0:
                return nil
            case 1:
                return nil
            case 2:
                if (valuation?.incomePreTax ?? 0.0) > 0 {
                    let result = ((valuation?.expenseIncomeTax ?? 0.0) / valuation!.incomePreTax)
                    return percentFormatter2Digits.string(from: result as NSNumber)
                }
                else { return nil }
            default:
                ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
            }
        case 5:
            // 'balance sheet'
            switch indexPath.row {
            case 0:
                if (valuation?.marketCap ?? 0.0) > 0 {
                    let result = (valuation?.debtST ?? 0) / ((valuation?.debtST ?? 0) + valuation!.marketCap)
                    return percentFormatter2Digits.string(from: result as NSNumber)
                } else { return nil }
            case 1:
                if (valuation?.marketCap ?? 0.0) > 0 {
                    let result =  (valuation?.debtLT ?? 0) / ((valuation?.debtLT ?? 0) + valuation!.marketCap)
                    return percentFormatter2Digits.string(from: result as NSNumber)
                } else { return nil }
            default:
                ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
                return ""
            }
        case 6:
            // 'Cash Flow S1
            if indexPath.row < (valuation?.tFCFo?.count ?? 0) - 1 {
                return percentFormatter2Digits.string(from: fcfGrowthRates[indexPath.row] as NSNumber)
            }
            else { return "" }
        case 7:
            // 'Cash Flow S2
            return nil
        case 8:
            // 'Prediction S1
            return nil
       case 9:
            // 'Prediction S2
            return nil
        case 10:
            // adjsuted predcited growth rate
            if let value = averagePredictedRevGrowth {
                return percentFormatter2Digits.string(from: value as NSNumber)
            }
        default:
            ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
        }
        
        return nil

    }
    
    public func buildRowTitles() -> [[String]] {
        
        let yearOnlyFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = NSLocale.current
            formatter.timeZone = NSTimeZone.local
            formatter.dateFormat = "YYYY"
            return formatter
        }()
        
        var totalRevenueTitles = ["Total revenue"]
        
        var netIncomeTitles = ["Net income"]

        
        var oFCFTitles = ["op. Cash flow"]
       
        var capExpendTitles = ["Capital expend."]
        
        var revPredTitles = ["Revenue estimate"]
        var growthPredTitles = ["Sales growth"]
        var adjGrowthPredTitles = ["Adj. sales growth"]

        var count = 0
        for i in stride(from: 4, to: 0, by: -1) {
            let date = (valuation?.creationDate ?? Date()).addingTimeInterval(Double(i * -1) * 366 * 24 * 3600)
            let year$ = yearOnlyFormatter.string(from: date)
            
            var newTitle = totalRevenueTitles.first! + " " + year$
            totalRevenueTitles.insert(newTitle, at: 1)
            
            newTitle = netIncomeTitles.first! + " " + year$
            netIncomeTitles.insert(newTitle, at: 1)

            newTitle = oFCFTitles.first! + " " + year$
            oFCFTitles.insert(newTitle, at: 1)

            newTitle = capExpendTitles.first! + " " + year$
            capExpendTitles.insert(newTitle, at: 1)
            
            count += 1
        }
        
        for i in 0..<2 {
            let date = (valuation?.creationDate ?? Date()).addingTimeInterval(Double(i) * 366 * 24 * 3600)
            let year$ = yearOnlyFormatter.string(from: date)
            
            var newTitle = revPredTitles.first! + " " + year$
            revPredTitles.append(newTitle)
            newTitle = growthPredTitles.first! + " " + year$
            growthPredTitles.append(newTitle)
        }
        
        for i in 0..<2 {
            let date = (valuation?.creationDate ?? Date()).addingTimeInterval(Double(i+2) * 366 * 24 * 3600)
            let year$ = yearOnlyFormatter.string(from: date)
            
            let newTitle = adjGrowthPredTitles.first! + " " + year$
            adjGrowthPredTitles.append(newTitle)
        }

        
        totalRevenueTitles.removeFirst()
        netIncomeTitles.removeFirst()
        oFCFTitles.removeFirst()
        capExpendTitles.removeFirst()
        revPredTitles.removeFirst()
        growthPredTitles.removeFirst()
        adjGrowthPredTitles.removeFirst()
        
        let generalSectionTitles = ["Date", "US 10y Treasure Bond rate", "Perpetual growth rate", "Exp. LT Market return"]
        let keyStatsTitles = ["Market cap", "beta", "Shares outstdg. (in thousands)"]
        let singleIncomeSectionTitles = ["Interest expense","Pre-Tax income","Income tax expend."]
        let balanceSheetSectionTitles = ["Current debt","Long term debt"]
        
        var incomeSection1Titles = [String]()
        var incomeSection2Titles = [String]()
        var incomeSection3Titles = [String]()
        var cashFlowSection1Titles = [String]()
        var cashFlowSection2Titles = [String]()
        var predictionSection1Titles = [String]()
        var predictionSection2Titles = [String]()

        incomeSection1Titles.append(contentsOf: totalRevenueTitles)
        incomeSection2Titles.append(contentsOf: netIncomeTitles)
        incomeSection3Titles.append(contentsOf: singleIncomeSectionTitles)
        
        cashFlowSection1Titles.append(contentsOf: oFCFTitles)
        cashFlowSection2Titles.append(contentsOf: capExpendTitles)
        
        predictionSection1Titles.append(contentsOf: revPredTitles)
        predictionSection2Titles.append(contentsOf: growthPredTitles)
        
        rowTitles = [generalSectionTitles ,keyStatsTitles, incomeSection1Titles, incomeSection2Titles, incomeSection3Titles, balanceSheetSectionTitles, cashFlowSection1Titles, cashFlowSection2Titles, predictionSection1Titles,predictionSection2Titles, adjGrowthPredTitles]
        
        return rowTitles!

    }

}
