//
//  CombinedValuationController.swift
//  Bulls'N'Bears
//
//  Created by aDav on 12/01/2021.
//

import UIKit
import CoreData

protocol ValuationHelper {
    func rowTitles() -> [[String]]
    func getValue(indexPath: IndexPath) -> Any?
    func cellInfo(indexPath: IndexPath) -> ValuationListCellInfo
    func userEnteredText(sender: UITextField, indexPath: IndexPath)
    func sectionTitles() -> [String]
    func sectionSubTitles() -> [String]
    func saveValuation() -> [String]?
}


class CombinedValuationController: ValuationHelper {
    
    weak var valuationListViewController: ValuationListViewController!
    var valuation: Any?
    var webAnalyser: Any?
    var stock: Stock!
    var method: ValuationMethods!
    var rowtitles: [[String]]!

    init(stock: Stock, valuationMethod: ValuationMethods, listView: ValuationListViewController) {
        
        self.valuationListViewController = listView
        self.method = valuationMethod
        self.stock = stock
        
        if valuationMethod == .rule1 {
            if let valuation = CombinedValuationController.returnR1Valuations(company: stock.symbol)?.first {
                self.valuation = valuation
            }
            else {
                self.valuation = CombinedValuationController.createR1Valuation(company: stock.symbol)
                if let existingDCFValuation = CombinedValuationController.returnDCFValuations(company: stock.symbol)?.first {
                    (valuation as? Rule1Valuation)?.getDataFromDCFValuation(dcfValuation: existingDCFValuation)
                }
            }
        }
        else if valuationMethod == .dcf {
            
            
            if let valuation = CombinedValuationController.returnDCFValuations(company: stock.symbol)?.first {
                self.valuation = valuation
            }
            else {
                self.valuation = CombinedValuationController.createDCFValuation(company: stock.symbol)
                if let existingR1Valuation = CombinedValuationController.returnR1Valuations(company: stock.symbol)?.first {
                    (valuation as? DCFValuation)?.getDataFromR1Valuation(r1Valuation: existingR1Valuation)
                }
            }
        }
    }
    
    //MARK: - Class functions
    
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
    
    //MARK: - Delegate functions
    func sectionTitles() -> [String] {
        
        var titles = [String]()
        
        if method == .dcf {
            titles = ["DCF Valuation - \(stock.symbol)","Key Statistics", "Income Statement", "", "", "Balance Sheet", "Cash Flow", "", "Revenue & Growth prediction","","Adjusted future growth"]
        } else
        if method == .rule1 {
            titles = ["Rule 1 Valuation - \(stock.symbol)",
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
            subtitles = ["General","Yahoo Summary > Key Statistics", "Details > Financials > Income Statement", "", "", "Details > Financials > Balance Sheet", "Details > Financials > Cash Flow", "values entered will be converted to negative","Details > Analysis > Revenue estimate", "", ""]
        } else
        if method == .rule1 {
            subtitles = ["Creation date","1. Book Value per Share", "2. Earnings per Share", "3. Sales/ Revenue", "4. OP. Free Cash Flow Per Share", "5. Return on Invested Capital", "min and max last 5-10 years", "Analysts min and max predictions","Adjust predicted growth rates", "", "last 6 months", "Between 0 - 10"]
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

    func cellInfo(indexPath: IndexPath) -> ValuationListCellInfo {
        
        let value = getValue(indexPath: indexPath)
        let value$ = valueText(value: value, indexPath: indexPath)
        let title = (rowtitles ?? rowTitles())[indexPath.section][indexPath.row]
        let format = valueFormat(indexPath: indexPath)
        
        return ValuationListCellInfo(value$: value$, title: title, format: format, detailInfo: getDetail$(indexPath: indexPath))
    }
    
    func rowTitles() -> [[String]] {
        
         rowtitles = (method == .dcf) ? dcfRowTitles() : rule1RowTitles()
        return rowtitles
    }
    
    func saveValuation() -> [String]? {
        
        if let valuation = self.valuation as? DCFValuation  {
            // check alignment of profit = net income and fcf
            var alerts:[String]?
            
            valuation.save()
            
            for income in valuation.netIncome ?? [] {
                if income < 0 {
                    alerts = [String]()
                    alerts?.append("Non-profitable at some point in the last 3 years.")
                }
            }
            
            if let fcf_netIncome_correlation = stock.getCorrelation(xArray: (valuation.netIncome?.compactMap{ $0 } ?? []), yArray: (valuation.tFCFo?.compactMap{ $0 } ?? []))?.coEfficient {
                let correlation$ = numberFormatterDecimals.string(from: fcf_netIncome_correlation as NSNumber) ?? ""
            
                if abs(fcf_netIncome_correlation) < 0.75 {
                    if alerts == nil {
                        alerts = [String]()
                    }
                    alerts?.append("Free cash flow and net income are not well aligned (correlation: \(correlation$))")
                }
            }
            return alerts
        }
        else if let valuation = self.valuation as? Rule1Valuation  {
            valuation.save()
            
            var alerts:[String]?


            if let moatCount = r1MoatParameterCount() {
                if moatCount < 25 {
                    if alerts == nil {
                        alerts = [String]()
                    }
                    alerts?.append("There are \(moatCount)/ 50 possible moat values.\nThe moat score and sticker price may not be very reliable")
                }
            }
            
            if (valuation.debtProportion() ?? 0) > 0.3 {
                alerts?.append("High long-term debt!")
            }
            
            if (valuation.insiderSalesProportion() ?? 0) > 0.1 {
                alerts?.append("More than 10% of insider stocks sold in last 6 months!")
            }
            return alerts
        }
        return nil
    }
    
    //MARK: - Internal functions
    
    public func startDataDownload() {
        
        if method == .rule1 {
            webAnalyser = R1WebDataAnalyser(stock: self.stock, valuation: self.valuation as! Rule1Valuation, controller: self, progressDelegate: self.valuationListViewController)

        }
        else {
            webAnalyser = DCFWebDataAnalyser(stock: stock, valuation: valuation as! DCFValuation, controller: self, pDelegate: self.valuationListViewController)
        }
        
    }
    
    public func stopDownload() {
        NotificationCenter.default.removeObserver(webAnalyser as Any)
        
        if let analyser = webAnalyser as? R1WebDataAnalyser {
            analyser.webView.stopLoading()
            analyser.yahooSession?.cancel()
            analyser.progressDelegate = nil
            analyser.request = nil
            analyser.yahooSession = nil
            analyser.webView = nil
        }
        else if let analyser = webAnalyser as? DCFWebDataAnalyser {
            analyser.yahooSession?.cancel()
            analyser.yahooSession = nil
            analyser.progressDelegate = nil
        }
        
        webAnalyser = nil
    }
    
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
            valuation.tRevenueActual?.add(value: value, index: indexPath.row)
        case 3:
            // 'Income Statement S2 - net income
            valuation.netIncome?.add(value: value, index: indexPath.row)
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
            valuation.tFCFo?.add(value: value, index: indexPath.row)
        case 7:
            // 'Cash Flow S2
            if value > 0 { valuation.capExpend![indexPath.row]  = value * -1 }
            else {
                valuation.capExpend?.add(value: value, index: indexPath.row)
            }
        case 8:
            // 'Prediction S1
            valuation.tRevenuePred?.add(value: value, index: indexPath.row)
       case 9:
            // 'Prediction S2
        valuation.revGrowthPred?.add(value: value / 100.0, index: indexPath.row)
        case 10:
            // adjsuted predicted growth rate
            valuation.revGrowthPredAdj?.add(value: value / 100.0, index: indexPath.row)
        default:
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
        }
        
        if let updatePaths = rowsToUpdateAfterUserEntry(indexPath) {
            valuationListViewController.helperUpdatedRows(paths: updatePaths)
        }

        valuation.save()
        
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
            valuation.bvps?.add(value: value, index: indexPath.row)
        case 2:
            // 'Moat parameters - EPS
            valuation.eps?.add(value: value, index: indexPath.row)
        case 3:
            // 'Moat parameters - Revenue
            valuation.revenue?.add(value: value, index: indexPath.row)
        case 4:
            // 'Moat parameters - FCF
            valuation.opcs?.add(value: value, index: indexPath.row)
        case 5:
            // 'Moat parameters - ROIC
            valuation.roic?.add(value: value / 100, index: indexPath.row)
        case 6:
            // 'Historical min /max PER
            valuation.hxPE?.add(value: value, index: indexPath.row)
        case 7:
            // 'Growth predictions
            valuation.growthEstimates?.add(value: value / 100, index: indexPath.row)
        case 8:
            // 'Adjusted Growth predictions
            valuation.adjGrowthEstimates?.add(value: value / 100, index: indexPath.row)
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
        
        valuation.save()
        
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
            case 4:
                if indexPath.row == 1{
                    paths.append(IndexPath(row: 2, section: 4))
                }
            case 5:
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
            case 1:
                if indexPath.row > 0 && indexPath.row < (valuation.bvps!.count) {
                    paths.append(IndexPath(row: 0, section: 7))
                    paths.append(IndexPath(row: 1, section: 7))
                }
            case 7:
                // Analyst predcited growht rates
                paths.append(IndexPath(row: 0, section: 8))
                paths.append(IndexPath(row: 1, section: 8))
            case 9:
                // 'Debt
                if indexPath.row == 0 {
                    paths.append(IndexPath(row: indexPath.row+1, section: indexPath.section))
                }
            default:
                return paths
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
        
        var section3$ = ""
        if indexPath.row < (valuation.tRevenueActual?.count ?? 0) - 1 {
            if let growth = calculateGrowthDCF(valuation.tRevenueActual, element:indexPath.row) {
                section3$ = percentFormatter0Digits.string(from: growth as NSNumber) ?? ""
            }
        }
        if indexPath.section == 2 {
            if valuation.tRevenueActual?.count ?? 0 > indexPath.row {
                if (valuation.tRevenueActual?[indexPath.row] ?? 0.0) < 0 {
                    color = UIColor(named: "Red")!
                    section3$ = "! " + (section3$)
                }
            }
            else { valuation.tRevenueActual?.append(Double()) }
        }
        var section4$ = ""
        if valuation.netIncome?.count ?? 0 > indexPath.row {
                if let growth = calculateGrowthDCF(valuation.netIncome, element:indexPath.row) {
                    section4$ = percentFormatter0Digits.string(from: growth as NSNumber) ?? ""
                }
        }
        if indexPath.section == 2 {
            if valuation.netIncome?.count ?? 0 > indexPath.row {
                if (valuation.netIncome?[indexPath.row] ?? 0.0) < 0 {
                    color = UIColor(named: "Red")!
                    section4$ = "! " + (section4$)
                }
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
        var section7$ = ""
        if indexPath.row < (valuation.tFCFo?.count ?? 0) - 1 {
            if let growth = calculateGrowthDCF(valuation.tFCFo, element:indexPath.row) {
                section7$ = percentFormatter0Digits.string(from: growth as NSNumber) ?? ""
            }
        }

        var section8$ = ""
        if indexPath.row < (valuation.capExpend?.count ?? 0) - 1 {
            if let growth = calculateGrowthDCF(valuation.capExpend, element:indexPath.row) {
                section8$ = percentFormatter0Digits.string(from: growth as NSNumber) ?? ""
            }
        }

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
            if indexPath.row == 9 { return (nil, nil) }
            else if let growth = calculateGrowthR1(valueArray: valuation.bvps, element: indexPath.row) {
                let color = growth < 0.1 ? UIColor(named: "Red") : UIColor(named: "Green")
                return (percentFormatter0Digits.string(from: growth as NSNumber), color)
            }
            return (nil, nil)
        case 2:
            // 'Moat parameters - EPS
            if indexPath.row == 9 { return (nil, nil) }
            else if let growth = calculateGrowthR1(valueArray: valuation.eps, element: indexPath.row) {
                let color = growth < 0.1 ? UIColor(named: "Red") : UIColor(named: "Green")
                return (percentFormatter0Digits.string(from: growth as NSNumber), color)
            }
            return (nil, nil)

        case 3:
            // 'Moat parameters - Revenue
            if indexPath.row == 9 { return (nil, nil) }
            else if let growth = calculateGrowthR1(valueArray: valuation.revenue, element: indexPath.row) {
                let color = growth < 0.1 ? UIColor(named: "Red") : UIColor(named: "Green")
                return (percentFormatter0Digits.string(from: growth as NSNumber), color)
            }
            return (nil, nil)

        case 4:
            // 'Moat parameters - FCF
            if indexPath.row == 9 { return (nil, nil) }
            else if let growth = calculateGrowthR1(valueArray: valuation.opcs, element: indexPath.row) {
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
            if let growth = averageGrowthPrediction() {
                return ((percentFormatter0Digits.string(from: growth as NSNumber) ?? "%"), nil)
            }

       case 9:
            // 'Debt / percent of FCF shown in TextField
            if indexPath.row == 0 { return (nil, nil) }
            else if valuation.insiderStocks != Double() {
                if valuation.netIncome > 0 {
                    let proportion = (valuation.debt) / valuation.netIncome
                    let color = proportion > 3.0 ? UIColor(named: "Red") : UIColor(named: "Green")
                    return (percentFormatter0Digits.string(from: proportion as NSNumber), color)
                }
                else {
                    return ("neg inc.", UIColor(named: "Red")!)
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
        let keyStatsTitles = ["Market cap", "beta", "Shares outstdg.(tds)"]
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
        let debtRowTitles = ["Long term debt", "Debt / income"]
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
                return numberFormatterWith1Digit.string(from: number as NSNumber)
            }
            else if currencyGapWithPence.contains(indexPath.section) {
                return currencyFormatterGapWithPence.string(from: number as NSNumber)
            }
            else if currencyGapNoPence.contains(indexPath.section) {
                return currencyFormatterGapNoPence.string(from: number as NSNumber)
            }
            else if [9].contains(indexPath.section) {
                // Rule 1 'Debt section'
                if indexPath.row == 0 {
                    return numberFormatterWith1Digit.string(from: number as NSNumber)
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
                                                       [.currency, .currency,.currency,.currency],
                                                       [.currency,.currency, .currency, .currency],
                                                       [.currency, .currency, .currency],
                                                       [.currency, .currency],
                                                       [.currency,.currency,.currency,.currency],
                                                       [.currency,.currency,.currency,.currency],
                                                       [.currency,.currency],
                                                       [.percent,.percent],
                                                       [.percent,.percent]]
                                                       
        let r1Formats:[[ValuationCellValueFormat]] = [[.date],
                                                      [.currency,.currency, .currency, .currency, .currency, .currency,.currency, .currency, .currency, .currency],
                                                      [.currency,.currency, .currency, .currency, .currency, .currency,.currency, .currency, .currency, .currency],
                                                      [.currency,.currency, .currency, .currency, .currency, .currency,.currency, .currency, .currency, .currency],
                                                      [.currency,.currency, .currency, .currency, .currency, .currency,.currency, .currency, .currency, .currency],
                                                      [.percent, .percent, .percent, .percent, .percent, .percent, .percent, .percent, .percent, .percent],
                                                      [.numberWithDecimals,.numberWithDecimals],
                                                      [.percent, .percent],
                                                      [.percent, .percent],
                                                      [.currency, .percent],
                                                      [.numberNoDecimals,.numberNoDecimals, .numberNoDecimals],
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
        let section5 = valuation.opcs ?? []
        let section6 = valuation.roic ?? []
        let section7 = valuation.hxPE ?? []
        
        var averageGrowth = [Double?]()
        if let growth = averageGrowthPrediction() {
            averageGrowth = [growth, growth]
        }
        let section8 = valuation.growthEstimates ?? averageGrowth
        
        let prediction = averageGrowthPrediction()
        let section9 = [valuation.adjGrowthEstimates?.first ?? prediction, valuation.adjGrowthEstimates?.last ?? prediction]
        let section10 = [valuation.debt, valuation.debtProportion()]
        let section11 = [valuation.insiderStocks, valuation.insiderStockBuys, valuation.insiderStockSells]
        let section12 = [valuation.ceoRating]

        return [section1, section2, section3, section4, section5, section6, section7, section8, section9, section10, section11, section12]

    }
    
    internal func averageGrowthPrediction() -> Double? {
        
        if let valuation = self.valuation as? DCFValuation {
            
            guard valuation.tRevenueActual?.count ?? 0 > 1 && valuation.revGrowthPred?.count ?? 0 > 0 else {
                return nil
            }
            
            var revenueGrowthRates = [Double]()
            revenueGrowthRates.append(contentsOf: valuation.revGrowthPred ?? [])
            for i in 1..<(valuation.revGrowthPred?.count ?? 1) {
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

            if valuation.growthEstimates?.count ?? 0 > 0 {
                return valuation.growthEstimates?.mean()
            }
            
            var growthRates = [Double]()
            if valuation.bvps?.count ?? 0 > 0 {
                for i in 1..<valuation.bvps!.count {
                    let rate = (valuation.bvps![i-1] - valuation.bvps![i]) / valuation.bvps![i]
                    growthRates.append(rate)
                }
            }
            
            return growthRates.mean()
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
        
        let result = (numbers[element] - numbers[element+1]) / abs(numbers[element+1])

        
        return (!result.isNaN && result.isFinite) ? result : nil
                
    }
 
    internal func calculateGrowthR1(valueArray: [Double]?, element: Int) -> Double? {
        
        guard element > 0 && element < (valueArray?.count ?? 0) else {
            return nil
        }
        
        guard valueArray![element] > 0 else {
            return nil
        }
        
        guard let endValue = valueArray?.first else {
            return nil
        }
        
        guard endValue > 0 else {
            return nil
        }
        
        return compoundGrowthRate(endValue: endValue, startValue: valueArray![element], years: Double(element))
    }

    internal func compoundGrowthRate(endValue: Double, startValue: Double, years: Double) -> Double {
        
        return (pow((endValue / startValue) , (1/years)) - 1)
    }
    
    func r1MoatParameterCount() -> Int? {
        
        
        guard  let v = valuation as? Rule1Valuation else {
            return nil
        }
        
        let arrays = [v.bvps, v.eps, v.revenue, v.opcs, v.roic]
        var countNonZero = 0
        for array in arrays {
            countNonZero += array?.compactMap{ $0 }.filter({ (value) -> Bool in
                if value != 0 { return true }
                else { return false }
            }).count ?? 0
        }
        
        return countNonZero
    }

}
