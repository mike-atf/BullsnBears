//
//  CombinedValuationController.swift
//  Bulls'N'Bears
//
//  Created by aDav on 12/01/2021.
//

import UIKit
import CoreData

protocol ValuationDelegate {
    func rowTitles() -> [[String]]
//    func getValue(indexPath: IndexPath) -> Any?
//    func getDatedValues(indexPath: IndexPath) -> DatedValue?
    func cellInfoNew(indexPath: IndexPath) -> Rule1DCFCellData
    func userEnteredText(sender: UITextField, indexPath: IndexPath)
    func sectionTitles() -> [String]
    func sectionSubTitles() -> [String]
    func checkValuation() -> [String]?
}


class CombinedValuationController: NSObject ,ValuationDelegate {
    
    weak var valuationListViewController: ValuationListViewController!
    var valuation: Any?
    var valuationID: NSManagedObjectID? // for coordinating background updates from donwloads
    var webAnalyser: Any?
    var share: Share!
    var method: ValuationMethods!
    var rowtitles: [[String]]!
    var downloadTask: Task<Any?, Error>?

    init(share: Share, valuationMethod: ValuationMethods, listView: ValuationListViewController) {
        
        self.valuationListViewController = listView
        self.method = valuationMethod
        self.share = share

        if valuationMethod == .rule1 {
            
            if let valuation = share.rule1Valuation {
                self.valuation = valuation
            }
            else if let valuation = CombinedValuationController.returnR1Valuations(company: share.symbol!) {
                // any orphan valuation belonging to this company left after deleting share
                share.rule1Valuation = valuation
                self.valuation = valuation
            }
            else {
                self.valuation = CombinedValuationController.createR1Valuation(company: share.symbol!)
                share.rule1Valuation = self.valuation as? Rule1Valuation
            }
            
        }
        else if valuationMethod == .dcf {
            
            if let valuation = share.dcfValuation {
                self.valuation = valuation
            }
            else if let valuation = CombinedValuationController.returnDCFValuations(company: share.symbol!) {
                // any orphan valuation belonging to this company left after deleting share
                self.valuation = valuation
                share.dcfValuation = valuation
            }
            else {
                self.valuation = CombinedValuationController.createDCFValuation(company: share.symbol!)
                share.dcfValuation = self.valuation as? DCFValuation
            }
        }
        
        if let vv = valuation as? Rule1Valuation {
            valuationID = vv.objectID
        } else if let vv = valuation as? DCFValuation {
            valuationID = vv.objectID
        }
    }
    
    //MARK: - Class functions
    
    static func createR1Valuation(company: String) -> Rule1Valuation? {
        
        if let existingValuation = returnR1Valuations(company: company) {
            existingValuation.delete()
        }
        
        let newValuation:Rule1Valuation? = {
            NSEntityDescription.insertNewObject(forEntityName: "Rule1Valuation", into: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext) as? Rule1Valuation
        }()
        
        newValuation?.company = company
        
        do {
            try  (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.save()
        } catch {
            let error = error
            ErrorController.addInternalError(errorLocation: #file + "."  + #function, systemError: error, errorInfo: "error creating and saving Rule1Valuation")
        }

        return newValuation
    }
    
    static func returnR1Valuations(company: String?) -> Rule1Valuation? {
        
        var valuations: [Rule1Valuation]?
        
        let fetchRequest = NSFetchRequest<Rule1Valuation>(entityName: "Rule1Valuation")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: false)] // newest first
        if let validName = company {
            let predicate = NSPredicate(format: "company == %@", argumentArray: [validName])
            fetchRequest.predicate = predicate
        }
        
        do {
            valuations = try (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.fetch(fetchRequest)
//            valuations = try fetchRequest.execute()
            } catch let error {
                ErrorController.addInternalError(errorLocation: #file + "."  + #function, systemError: error, errorInfo: "error fetching Rule1Valuation")
        }
        
        if valuations?.count ?? 0 > 1 {
            for i in 1..<valuations!.count {
                valuations![i].delete()
            }
        }

        return valuations?.first
    }
    
    static func returnDCFValuations(company: String?) -> DCFValuation? {
        
        var valuations: [DCFValuation]?
        
        let fetchRequest = NSFetchRequest<DCFValuation>(entityName: "DCFValuation")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: false)] // newest first
        fetchRequest.returnsObjectsAsFaults = false
        if let validName = company {
            let predicate = NSPredicate(format: "company == %@", argumentArray: [validName])
            fetchRequest.predicate = predicate
        }
        
        do {
            valuations = try (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.fetch(fetchRequest)
//            valuations = try fetchRequest.execute()
            } catch let error {
                ErrorController.addInternalError(errorLocation: #file + "."  + #function, systemError: error, errorInfo: "error fetching dcfValuations")
        }

        if valuations?.count ?? 0 > 1 {
            for i in 1..<valuations!.count {
                valuations![i].delete()
            }
        }

        return valuations?.first
    }
    
    static func createDCFValuation(company: String) -> DCFValuation? {
        
        if let existingValuation = returnDCFValuations(company: company) {
            existingValuation.delete()
        }

        let newValuation:DCFValuation? = {
            NSEntityDescription.insertNewObject(forEntityName: "DCFValuation", into: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext) as? DCFValuation
        }()
        newValuation?.company = company
        do {
            try  (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.save()
        } catch {
            let error = error
            ErrorController.addInternalError(errorLocation: #file + "."  + #function, systemError: error, errorInfo: "error creating and saving dcfValuations")
        }

        return newValuation
    }
    
    //MARK: - Delegate functions
    func sectionTitles() -> [String] {
        
        var titles = [String]()
                
        if method == .dcf {
            titles = ["\(share.symbol!) DCF Valuation","Key Statistics", "Income Statement", "", "", "Balance Sheet", "Cash Flow", "", "Revenue & Growth prediction","","Adjusted future growth"]
        } else
        if method == .rule1 {
            titles = ["\(share.symbol!) R1 Valuation", "Predictions",
            "Moat parameters",
            "", "", "", "",
            "PE Ratios", "Growth predictions",
            "Adj. growth prediction",
            "Debt",
            "Insider Trading",
            "CEO Rating"
            ]
        }
        
        return titles
    }
    
    func sectionSubTitles() -> [String] {
        
        var subtitles = [String]()
        
        if method == .dcf {
            subtitles = ["Download, or enter data","Yahoo Summary > Key Statistics", "Details > Financials > Income Statement", "", "", "Details > Financials > Balance Sheet", "Details > Financials > Cash Flow", "values entered will be converted to negative","Details > Analysis > Revenue estimate", "", ""]
        } else
        if method == .rule1 {
            subtitles = ["Download, or enter data", "Adjust" ,"1. Book Value per Share", "2. Earnings per Share", "3. Revenue", "4. Free Cash Flow Per Share", "5. Return on Invested Capital", "min and max last 5-10 years", "Analysts min and max predictions","Adjust the predicted growth rates", "", "last 6 months", "Optional, between 0 - 10"]
        }
        
        return subtitles
    }
    
//    func getValue(indexPath: IndexPath) -> Any? {
//
//        var valuesArray = [[Any?]]()
//
//        if method == .dcf {
//            valuesArray = getDCFValues()
//        }
//        else if method == .rule1 {
//            valuesArray = getR1Values()
//        }
//        if indexPath.section < valuesArray.count {
//            if indexPath.row < (valuesArray[indexPath.section].count) {
//                return valuesArray[indexPath.section][indexPath.row]
//            }
//        }
//        else {
//            ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "undefined indexpath \(indexPath) in Valuation.getDCFValue")
//        }
//
//        return nil
//    }
    
    /*
    func getDatedValues(indexPath: IndexPath) -> DatedValue? {
        
        var datedValues = [[DatedValue?]?]()
        
        if method == .rule1 {
            datedValues = getR1ValuesNew()
        }
        else if method == .dcf {
            // dcf
        }
        
        if indexPath.section < datedValues.count {
            if indexPath.row < (datedValues[indexPath.section]?.count ?? 0) {
                return datedValues[indexPath.section]?[indexPath.row]
            }
        }
        else {
            ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "undefined indexpath \(indexPath) in Valuation.getDatedValues")
        }
        
        return nil
    }

    
    func getValueString(indexPath: IndexPath) -> String {
        
        var valuesArray = [[String]]()
        
        if method == .dcf {
            valuesArray = getDCFValueStrings()
        }
        else if method == .rule1 {
            valuesArray = getR1ValueStrings()
        }
        
        if indexPath.section < valuesArray.count {
            if indexPath.row < (valuesArray[indexPath.section].count) {
                return valuesArray[indexPath.section][indexPath.row]
            }
        }
        else {
            ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "undefined indexpath \(indexPath) in Valuation.getDCFValue")
        }
        
        return String()
    }
    */
    /*
    /// should return 3 string for title, value$ and trailing (%) string
    func cellTexts(indexPath: IndexPath) -> [String] {
                
        if method == .dcf {
            return dcfCellTexts(indexPath: indexPath)
        }
        else {
            return rule1CellTexts(indexPath: indexPath)
        }
    }
     */

    
    func userEnteredText(sender: UITextField, indexPath: IndexPath) {
        
        guard let validtext = sender.text else {
            return
        }
        
        guard validtext != "" else {
            return
        }
        
        guard let value = Double(validtext.filter("-0123456789.".contains)) else {
            ErrorController.addInternalError(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "error converting entered text to number: \(sender.text ?? "no text")")
            return
        }
        
        if (self.valuation as? DCFValuation) != nil {
            convertUserEntryDCF(value, indexPath: indexPath)
        }
        else if (self.valuation as? Rule1Valuation) != nil {
            convertUserEntryR1(value, indexPath: indexPath)
        }
    }

    /*
    func cellInfo(indexPath: IndexPath) -> ValuationListCellInfo {
        
        let value$ = getValueString(indexPath: indexPath)
        let title = (rowtitles ?? rowTitles())[indexPath.section][indexPath.row]
        let format = valueFormat(indexPath: indexPath)
        
        return ValuationListCellInfo(value$: value$, title: title, format: format, detailInfo: getDetail$(indexPath: indexPath))
    }
    */
    
    func cellInfoNew(indexPath indexpath: IndexPath) -> Rule1DCFCellData {
        
        if method == .dcf {
            return dcfCellTexts(indexPath: indexpath)
        }
        else {
            return rule1CellTexts(indexPath: indexpath)
        }
    }
    
    func rowTitles() -> [[String]] {
        
         rowtitles = (method == .dcf) ? dcfRowTitles() : rule1RowTitles()
        return rowtitles
    }
    
    func checkValuation() -> [String]? {
        
        guard let validID = valuationID else {
            ErrorController.addInternalError(errorLocation: "CombinedValuationController.checkValuation", systemError: nil, errorInfo: "controller has no valid NSManagedObjectID to fetch valuation")
            return nil
        }

        if let valuation = self.valuation as? DCFValuation  {
            // check alignment of profit = net income and fcf
            var alerts:[String]?
            
            self.valuation = ((UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.object(with: validID) as? DCFValuation)!
                
                       
            for income in valuation.netIncome ?? [] {
                if income < 0 {
                    alerts = [String]()
                    alerts?.append("Non-profitable at some point in the last 3 years.")
                }
            }
            let coefficient = Calculator.correlation(xArray: (valuation.netIncome?.compactMap{ $0 } ?? []), yArray: (valuation.tFCFo?.compactMap{ $0 } ?? []))?.coEfficient
            if let fcf_netIncome_correlation = coefficient {
                let correlation$ = numberFormatter2Decimals.string(from: fcf_netIncome_correlation as NSNumber) ?? ""
            
                if abs(fcf_netIncome_correlation) < 0.75 {
                    if alerts == nil {
                        alerts = [String]()
                    }
                    alerts?.append("Free cash flow and net income are not well aligned (correlation: \(correlation$))")
                }
            }
            valuation.alerts = alerts
            return alerts
        }
        else if let valuation = self.valuation as? Rule1Valuation  {

            var alerts:[String]?

            self.valuation = ((UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.object(with: validID) as? Rule1Valuation)!

            if let moatCount = valuation.r1MoatParameterCount() {
                if moatCount < 30 {
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
            valuation.alerts = alerts
            return alerts
        }
        return nil
    }
    
    class func checkDCFR1Valuation(valuationID: NSManagedObjectID?) -> [String]? {
        
        guard let validID = valuationID else {
            return ["no valid valuation ID sent for check"]
        }
        
        var alerts: [String]?
        
//        guard
        let valuation = ((UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.object(with: validID))
//        else
//        {
//            return ["no valuation for checking can be fetched from MOC"]
//        }
    
        if let dcfValuation = valuation as? DCFValuation {
            
            for income in dcfValuation.netIncome ?? [] {
                if income < 0 {
                    alerts = [String]()
                    alerts?.append("Non-profitable at some point in the last 3 years.")
                }
            }
            let coefficient = Calculator.correlation(xArray: (dcfValuation.netIncome?.compactMap{ $0 } ?? []), yArray: (dcfValuation.tFCFo?.compactMap{ $0 } ?? []))?.coEfficient
            if let fcf_netIncome_correlation = coefficient {
                let correlation$ = numberFormatter2Decimals.string(from: fcf_netIncome_correlation as NSNumber) ?? ""
                
                if abs(fcf_netIncome_correlation) < 0.75 {
                    if alerts == nil {
                        alerts = [String]()
                    }
                    alerts?.append("Free cash flow and net income are not well aligned (correlation: \(correlation$))")
                }
            }
            dcfValuation.alerts = alerts
        }
        else if let r1Valuation = valuation as? Rule1Valuation {
            
            let arrays = [r1Valuation.bvps, r1Valuation.eps, r1Valuation.revenue, r1Valuation.opcs, r1Valuation.roic]
            var moatCount = 0
            for array in arrays {
                moatCount += array?.compactMap{ $0 }.filter({ (value) -> Bool in
                    if value != 0 { return true }
                    else { return false }
                }).count ?? 0
            }

            if moatCount < 25 {
                if alerts == nil {
                    alerts = [String]()
                }
                alerts?.append("There are \(moatCount) of 50 possible moat values.\nThe moat score and sticker price may not be very reliable")
            }
            
            if (r1Valuation.debtProportion() ?? 0) > 0.3 {
                alerts?.append("High long-term debt!")
            }
            
            if (r1Valuation.insiderSalesProportion() ?? 0) > 0.1 {
                alerts?.append("More than 10% of insider stocks sold in last 6 months!")
            }
            r1Valuation.alerts = alerts
        } else {
            alerts = ["DCF or R1 Valuation check: objectID fetched from MOC does not match DCF- or R1 Valuation"]
        }

        
        return alerts
        
    }
    
    /*
    func updateData() {
        
        guard let validID = valuationID else {
            ErrorController.addInternalError(errorLocation: "CombinedValuationController.checkValuation", systemError: nil, errorInfo: "controller has no valid NSManagedObjectID to fetch valuation")
            return
        }

        if (self.valuation as? DCFValuation) != nil  {
            
            self.valuation = ((UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.object(with: validID) as? DCFValuation)!
            
        } else if (self.valuation as? Rule1Valuation) != nil {
            
            self.valuation = ((UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.object(with: validID) as? Rule1Valuation)!
        }
    }
    */
    
    //MARK: - Internal functions
    
    public func startDataDownload(progressDelegate: ProgressViewDelegate?=nil) {
        
        // accessing share properties must happen on main thread!
        guard let symbol =  share.symbol, let shortName = share.name_short else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "Combined Val controller download request for \(share) with incomplete information" )
            return
        }

        let shareID = share.objectID
        
        if method == .rule1 {

            downloadTask = Task.init(priority: .background) {
                do {
                    let _ = await Rule1Valuation.downloadAnalyseAndSave(shareSymbol: symbol, shortName: shortName, shareID: shareID, progressDelegate: self.valuationListViewController, downloadRedirectDelegate: self)
                    try Task.checkCancellation()
                } catch  {
                    ErrorController.addInternalError(errorLocation: "CombinedValuationController.startDataDownload", systemError: error, errorInfo: "Error downloading R1 valuation: \(error)")
                }
                return nil
            }
        }
        else {

            downloadTask = Task.init(priority: .background) {

                do {
                    await YahooPageScraper.dataDownloadAnalyseSave(symbol: symbol, shortName: shortName, shareID: shareID, option: .dcfOnly, progressDelegate: valuationListViewController, downloadRedirectDelegate: self)
//                    try await YahooPageScraper.dcfDownloadAnalyseAndSave(shareSymbol: symbol, shareID: shareID, progressDelegate: self.valuationListViewController)
                    try Task.checkCancellation()
                } catch let error {
                    ErrorController.addInternalError(errorLocation: "CombinedValuationController.startDataDownload", systemError: error, errorInfo: "Error downloading DCF valuation: \(error)")
                }
                return nil
            }
        }
        
    }
    

    public func stopDownload() {
        
        NotificationCenter.default.removeObserver(webAnalyser as Any)
        
        downloadTask?.cancel()
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
                ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "undefined indexpath \(indexPath) in DCFValuation.getValuationListItem")
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
                ErrorController.addInternalError(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
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
                ErrorController.addInternalError(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
            }
        case 5:
            // 'balance sheet'
           switch indexPath.row {
            case 0:
                valuation.debtST = value
            case 1:
                valuation.debtLT = value
            default:
                ErrorController.addInternalError(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
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
//            valuation.tRevenuePred?.add(value: value, index: indexPath.row)
            if indexPath.row == 0 { // next year
                let date = DatesManager.endOfYear(of: Date().addingTimeInterval(365*24*3600))
                let datedValue = DatedValue(date: date, value: value/100)
                var existing = share.analysis?.future_revenue.datedValues(dateOrder: .descending)
                if existing != nil {
                    existing![0] = datedValue
                } else {
                    existing = [datedValue]
                }
                share.analysis?.future_revenue = existing!.convertToData()
            }
            else { // current year
                let date = DatesManager.endOfYear(of: Date())
                let datedValue = DatedValue(date: date, value: value/100)
                var existing = share.analysis?.future_revenue.datedValues(dateOrder: .descending)
                if existing != nil {
                    existing![1] = datedValue
                } else {
                    existing = [datedValue]
                }
                share.analysis?.future_revenue = existing!.convertToData()
            }
            share.save()

       case 9:
            // 'Prediction S2
//        valuation.revGrowthPred?.add(value: value / 100.0, index: indexPath.row)
            if indexPath.row == 0 { // next year
                let date = DatesManager.endOfYear(of: Date().addingTimeInterval(365*24*3600))
                let datedValue = DatedValue(date: date, value: value/100)
                var existing = share.analysis?.adjFutureGrowthRate.datedValues(dateOrder: .descending)
                if existing != nil {
                    existing![0] = datedValue
                } else {
                    existing = [datedValue]
                }
                share.analysis?.adjFutureGrowthRate = existing!.convertToData()
            }
            else { // current year
                let date = DatesManager.endOfYear(of: Date())
                let datedValue = DatedValue(date: date, value: value/100)
                var existing = share.analysis?.adjFutureGrowthRate.datedValues(dateOrder: .descending)
                if existing != nil {
                    existing![1] = datedValue
                } else {
                    existing = [datedValue]
                }
                share.analysis?.adjFutureGrowthRate = existing!.convertToData()
            }
            share.save()

        case 10:
            // adjsuted predicted growth rate
            valuation.revGrowthPredAdj?.add(value: value / 100.0, index: indexPath.row)
        default:
            ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
        }
        
        if let updatePaths = rowsToUpdateAfterUserEntry(indexPath) {
            valuationListViewController.helperUpdatedRows(paths: updatePaths)
        }
        
        do {
            try valuation.managedObjectContext?.save()
        } catch let error {
            ErrorController.addInternalError(errorLocation: "CombinedValController.convertUserEntryDCF", systemError: error , errorInfo: "Unable to to save user entry to valuation's moc")
        }
        
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
            // 'Predictions
            if indexPath.row == 0 {
                valuation.adjGrowthEstimates = [value/100, value/100]
                
                let date1 = DatesManager.endOfYear(of: Date().addingTimeInterval(365*24*3600))
                let date2 = DatesManager.endOfYear(of: Date())
                
                let datedValue1 = DatedValue(date: date1, value: value/100)
                let datedValue2 = DatedValue(date: date2, value: value/100)
                share.analysis?.adjFutureGrowthRate = [datedValue1, datedValue2].convertToData()

            } else {
//                valuation.adjFuturePE = value
                let date1 = DatesManager.endOfYear(of: Date().addingTimeInterval(365*24*3600))
                let date2 = DatesManager.endOfYear(of: Date())
                
                let datedValue1 = DatedValue(date: date1, value: value)
                let datedValue2 = DatedValue(date: date2, value: value)
                share.analysis?.adjForwardPE = [datedValue1, datedValue2].convertToData()
            }
        case 2:
            // 'Moat parameters - BVPS
            valuation.bvps?.add(value: value, index: indexPath.row)
        case 3:
            // 'Moat parameters - EPS
            valuation.eps?.add(value: value, index: indexPath.row)
        case 4:
            // 'Moat parameters - Revenue
            valuation.revenue?.add(value: value, index: indexPath.row)
        case 5:
            // 'Moat parameters - FCF
            valuation.opcs?.add(value: value, index: indexPath.row)
        case 6:
            // 'Moat parameters - ROIC
            valuation.roic?.add(value: value / 100, index: indexPath.row)
        case 7:
            // 'Historical min /max PER
            valuation.hxPE?.add(value: value, index: indexPath.row)
        case 8:
            // 'Growth predictions
            valuation.growthEstimates?.add(value: value / 100, index: indexPath.row)
        case 9:
            // 'Adjusted Growth predictions
//            valuation.adjGrowthEstimates?.add(value: value / 100, index: indexPath.row)
            if indexPath.row == 0 { // next year
                let date = DatesManager.endOfYear(of: Date().addingTimeInterval(365*24*3600))
                let datedValue = DatedValue(date: date, value: value/100)
                var existing = share.analysis?.adjFutureGrowthRate.datedValues(dateOrder: .descending)
                if existing != nil {
                    existing![0] = datedValue
                } else {
                    existing = [datedValue]
                }
                share.analysis?.adjFutureGrowthRate = existing!.convertToData()
            }
            else { // current year
                let date = DatesManager.endOfYear(of: Date())
                let datedValue = DatedValue(date: date, value: value/100)
                var existing = share.analysis?.adjFutureGrowthRate.datedValues(dateOrder: .descending)
                if existing != nil {
                    existing![1] = datedValue
                } else {
                    existing = [datedValue]
                }
                share.analysis?.adjFutureGrowthRate = existing!.convertToData()
            }
            share.save()

       case 10:
            // 'Debt
            if indexPath.row == 0 {
                valuation.debt = value
            }
        case 11:
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
        case 12:
            valuation.ceoRating = value
        default:
            ErrorController.addInternalError(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
        }
        
        valuation.save()
        share.save()
        
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
    
    /*
    internal func getDetail$(indexPath: IndexPath) -> (String?, UIColor?) {
        
        return (method == .dcf) ? getDCFDetail$(indexPath) : getR1Detail$(indexPath)
    }
    */
    
    /*
    internal func getDCFDetail$(_ indexPath: IndexPath) -> (String?, UIColor?) {
    
        guard let valuation = self.valuation as? DCFValuation else { return (nil,nil) }
        
        let section1$: String? = nil
        let section2$: String? = nil
        var color = UIColor.label
        
        var section3$ = ""
        if indexPath.row < (valuation.tRevenueActual?.count ?? 0) - 1 {
            if let growth = calculateGrowthDCF(valuation.tRevenueActual?.reversed(), element:indexPath.row) {
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
            if let growth = calculateGrowthDCF(valuation.netIncome?.reversed(), element:indexPath.row) {
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
        var section5$: String?
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
            stDebtPorportion$ = percentFormatter2Digits.string(from: stDebtProportion! as NSNumber)
        }
        var ltDebtProportion: Double?
        var ltDebtPorportion$: String?
        if (valuation.marketCap) > 0 {
            ltDebtProportion =  (valuation.debtLT) / ((valuation.debtLT) + valuation.marketCap)
            ltDebtPorportion$ = percentFormatter2Digits.string(from: ltDebtProportion! as NSNumber)
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
            if let growth = calculateGrowthDCF(valuation.tFCFo?.reversed(), element:indexPath.row) {
                section7$ = percentFormatter0Digits.string(from: growth as NSNumber) ?? ""
            }
        }

        var section8$ = ""
        if indexPath.row < (valuation.capExpend?.count ?? 0) - 1 {
            if let growth = calculateGrowthDCF(valuation.capExpend?.reversed(), element:indexPath.row) {
                section8$ = percentFormatter0Digits.string(from: growth as NSNumber) ?? ""
            }
        }

        let section9$: String? = nil
        let section10$: String? = averageGrowthPrediction() != nil ? percentFormatter0Digits.string(from: averageGrowthPrediction()! as NSNumber) : nil
        let section11$: String? = nil
        
        let detailsArray = [section1$, section2$, section3$, section4$, section5$, section6$, section7$, section8$, section9$, section10$,section11$]
        
        return (detailsArray[indexPath.section], color)
        
    }
    */
    
    /*
    internal func getR1Detail$(_ indexPath: IndexPath) -> (String?,UIColor?) {
        
        guard let valuation = self.valuation as? Rule1Valuation else { return (nil, nil) }

        switch indexPath.section {
        case 0:
            // 'General
            return (nil, nil)
        case 1:
            // 'Predictions
            if indexPath.row == 0 {
                var salesGrowthPrediction: Double?
                if valuation.adjGrowthEstimates?.mean() ?? 0 != 0.0 {
                    salesGrowthPrediction = valuation.adjGrowthEstimates?.mean()
                } else if valuation.growthEstimates?.mean() ?? 0 != 0 {
                    salesGrowthPrediction = valuation.growthEstimates?.mean()
                }
                
                guard let prediction = salesGrowthPrediction else {
                    return ("-", UIColor.label)
                }
                let prediction$ = percentFormatter2Digits.string(from: prediction as NSNumber) ?? "-"
                return (prediction$, UIColor.label)
            }
            else if indexPath.row == 1 {
                guard let min = valuation.hxPE?.min(), let max = valuation.hxPE?.max() else {
                    return ("-", UIColor.label)
                }
                let color = UIColor.label
                
                let peRange$ = numberFormatterNoFraction.string(from: min as NSNumber)! + "-"+numberFormatterNoFraction.string(from: max as NSNumber)!
                return (peRange$, color)
            } else {
                return (nil, nil)
            }

        case 2:
            // 'Moat parameters - BVPS
            if indexPath.row == 9 { return (nil, nil) }
            else if let growth = calculateGrowthR1(valueArray: valuation.bvps, element: indexPath.row) {
                let color = growth < 0.1 ? UIColor(named: "Red") : UIColor(named: "Green")
                return (percentFormatter0Digits.string(from: growth as NSNumber), color)
            }
            return (nil, nil)
        case 3:
            // 'Moat parameters - EPS
            if indexPath.row == 9 { return (nil, nil) }
            else if let growth = calculateGrowthR1(valueArray: valuation.eps, element: indexPath.row) {
                let color = growth < 0.1 ? UIColor(named: "Red") : UIColor(named: "Green")
                return (percentFormatter0Digits.string(from: growth as NSNumber), color)
            }
            return (nil, nil)

        case 4:
            // 'Moat parameters - Revenue
            if indexPath.row == 9 { return (nil, nil) }
            else if let growth = calculateGrowthR1(valueArray: valuation.revenue, element: indexPath.row) {
                let color = growth < 0.1 ? UIColor(named: "Red") : UIColor(named: "Green")
                return (percentFormatter0Digits.string(from: growth as NSNumber), color)
            }
            return (nil, nil)

        case 5:
            // 'Moat parameters - FCF
            if indexPath.row == 9 { return (nil, nil) }
            else if let growth = calculateGrowthR1(valueArray: valuation.opcs, element: indexPath.row) {
                let color = growth < 0.1 ? UIColor(named: "Red") : UIColor(named: "Green")
                return (percentFormatter0Digits.string(from: growth as NSNumber), color)
            }
            return (nil, nil)

        case 6:
            // 'Moat parameters - ROIC
            if indexPath.row == 9 { return (nil, nil) }
            else if (valuation.roic?.count ?? 0) > indexPath.row {
                let color = valuation.roic![indexPath.row] < 0.1 ? UIColor(named: "Red") : UIColor(named: "Green")
                return (percentFormatter0Digits.string(from: valuation.roic![indexPath.row] as NSNumber), color)
            }
            else { return (nil, nil) }
        case 7:
            // 'Historical min /max PER
            return (nil, nil)

        case 8:
            // 'Growth predictions
            return (nil, nil)

        case 9:
            // 'Adjusted Growth predictions
            if let growth = averageGrowthPrediction() {
                return ((percentFormatter0Digits.string(from: growth as NSNumber) ?? "%"), nil)
            }

       case 10:
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
        case 11:
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
        case 12:
            // 'CEO'
            return ("0-10", nil)
        default:
            ErrorController.addInternalError(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
        }
        
        return (nil, nil)
    }
     */
    
    internal func dcfRowTitles() -> [[String]] {
        
        guard let dcfValuation = valuation as? DCFValuation else {
            return [[]]
        }
        
        let yearOnlyFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = NSLocale.current
            formatter.timeZone = NSTimeZone.local
            formatter.dateFormat = "yyyy"
            return formatter
        }()
        
        var section0Titles = ["Total revenue"]
        var section1Titles = ["Net income"]
        var section2Titles = ["op. Cash flow"]
        var section3Titles = ["Capital expend."]
        var section4Titles = ["Revenue est."]
        var section5Titles = ["Revenue growth"]
        var section6Titles = ["Adj. sales growth"]
        
        let generalSectionTitles = ["Date", "US 10y Treasure Bond rate", "Perpetual growth rate", "Exp. LT Market return"]
        let keyStatsTitles = ["Market cap", "beta", "Shares outstdg."]
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
            formatter.dateFormat = "yyyy"
            return formatter
        }()
        
        let generalSectionTitles = ["Latest Date"]
        let predictionTitles = ["Pred. growth", "Pred. PE ratio"]
        var bvpsTitles = ["BVPS"]
        var epsTitles = ["EPS"]
        var revenueTitles = ["Revenue"]
        var fcfTitles = ["FCF"]
        var roicTitles = ["ROIC"]
        
        let hxPERTitles = ["past PER min" , "past PER max"]
        let growthPredTitles = ["Pred. sales growth min", "Pred. sales growth max"]
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
        
        rowtitles = [generalSectionTitles , predictionTitles ,bvpsTitles,epsTitles, revenueTitles, fcfTitles, roicTitles, hxPERTitles, growthPredTitles, adjGrowthPredTitles, debtRowTitles, insideTradingRowTitles, ceoRatingRowTitle]

        return rowtitles


    }
    
    /*
    internal func valueText(value: Any?, indexPath: IndexPath) -> String? {
        
        guard  let validValue = value else {
            return nil
        }
        
        let percentWith2Digits = (method == .dcf) ? [0,9,10] : [7,5,8,10,11]
        let numberWithDigits = (method == .dcf) ? [1] : [6,9]
        let numberNoDigits = (method == .dcf) ? [] : [10]
        let currencyGapWithPence = (method == .dcf) ? [] : [1,2,3,4]
        let currencyGapNoPence = (method == .dcf) ? [2,3,4,5,6,7] : []
        
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
            else if [10].contains(indexPath.section) {
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
     */
    
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
                                                      [.percent, .numberNoDecimals],
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
        
    /*
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
    
    internal func getDCFValueStrings() -> [[String]] {
        
        
        guard let valuation = (self.valuation as? DCFValuation) else { return [[String()]] }
        
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = NSLocale.current
            formatter.timeZone = NSTimeZone.local
            formatter.dateStyle = .short
            return formatter
        }()

        let creationDate = dateFormatter.string(from: valuation.creationDate!)
        let tBondRate = UserDefaults.standard.value(forKey: "10YUSTreasuryBondRate") as! Double
        let pGrowthRate = UserDefaults.standard.value(forKey: "PerpetualGrowthRate") as! Double
        let ltReturn =  UserDefaults.standard.value(forKey: "LongTermMarketReturn") as! Double
        
        let section1 = [creationDate,
                              tBondRate.shortString(decimals: 1, formatter: percentFormatter2Digits),
                        pGrowthRate.shortString(decimals: 1, formatter: percentFormatter2Digits),
                        ltReturn.shortString(decimals: 1,formatter: percentFormatter2Digits)]
        let section2 = [valuation.marketCap.shortString(decimals: 2), valuation.beta.shortString(decimals: 1, formatter: numberFormatter2Decimals), valuation.sharesOutstanding.shortString(decimals: 2, formatter: numberFormatterWith1Digit)]
        let section3 = valuation.tRevenueActual?.reversed().shortStrings(decimals: 2)  ?? [String]()
        let section4 = valuation.netIncome?.reversed().shortStrings(decimals: 2)  ?? [String]()
        let section5 = [valuation.expenseInterest.shortString(decimals: 1), valuation.incomePreTax.shortString(decimals: 1), valuation.expenseIncomeTax.shortString(decimals: 1)]
        let section6 = [valuation.debtST.shortString(decimals: 1), valuation.debtLT.shortString(decimals: 1)]
        let section7 = valuation.tFCFo?.reversed().shortStrings(decimals: 2)  ?? [String]()
        let section8 = valuation.capExpend?.reversed().shortStrings(decimals: 2)  ?? [String]()
        let section9 = valuation.tRevenuePred?.shortStrings(decimals: 2)  ?? [String]()
        let section10 = valuation.revGrowthPred?.shortStrings(decimals: 1, formatter: percentFormatter2Digits)  ?? [String]()
        let prediction = averageGrowthPrediction()?.shortString(decimals: 1, formatter: percentFormatter2Digits)  ?? String()
        let section11 = [prediction, prediction]
        
        return [section1, section2, section3, section4, section5, section6, section7, section8, section9, section10, section11]
        
    }
     */
    
//    internal func getR1Values() -> [[Any?]]  {
//
//        guard let valuation = (self.valuation as? Rule1Valuation) else { return [[nil]] }
//
//        let section1:[Any] = [valuation.creationDate ?? Date()]
//        let section2 = valuation.bvps ?? []
//        let section3 = valuation.eps ?? []
//        let section4 = valuation.revenue ?? []
//        let section5 = valuation.opcs ?? []
//        let section6 = valuation.roic ?? []
//        let section7 = valuation.hxPE ?? []
//
//        var averageGrowth = [Double?]()
//        if let growth = averageGrowthPrediction() {
//            averageGrowth = [growth, growth]
//        }
//        let section8 = valuation.growthEstimates ?? averageGrowth
//
//        let prediction = averageGrowthPrediction()
//        let section9 = [valuation.adjGrowthEstimates?.first ?? prediction, valuation.adjGrowthEstimates?.last ?? prediction]
//        let section10 = [valuation.debt, valuation.debtProportion()]
//        let section11 = [valuation.insiderStocks, valuation.insiderStockBuys, valuation.insiderStockSells]
//        let section12 = [valuation.ceoRating]
//
//        return [section1, section2, section3, section4, section5, section6, section7, section8, section9, section10, section11, section12]
//
//    }
    
    internal func dcfCellTexts(indexPath: IndexPath) -> Rule1DCFCellData {
        
        let yearOnlyDateFormatter: DateFormatter = {
            let formatter = DateFormatter()
//            formatter.locale = NSLocale.current
//            formatter.timeZone = NSTimeZone.local
            formatter.dateFormat = "yyyy"
            return formatter
        }()
        
        var parameterTitle = String()
        var parameterDV: [DatedValue]?
        var value$ = "-"
        var detail$ = ""
        var detailTextColor = UIColor.label

        
        let valueFormatter = currencyFormatterNoGapWithPence
        
        if indexPath.section == 0 {
            // Date, 10y T-Bonds return, perp growth rate, LT market return rate
            if indexPath.row == 0 {
                let valuation = (self.valuation as? DCFValuation) ?? DCFValuation(context: share.managedObjectContext!)
                valuation.share = share
                parameterTitle = "Latest date"
                value$ = dateFormatter.string(from: valuation.creationDate ?? Date())
            }
            else if indexPath.row == 1 {
                let tBondRate = UserDefaults.standard.value(forKey: "10YUSTreasuryBondRate") as! Double
                parameterTitle = "10y T-Bond return"
                value$ = tBondRate.shortString(decimals: 0, formatter: percentFormatter2Digits)
            }
            else if indexPath.row == 2 {
                let pGrowthRate = UserDefaults.standard.value(forKey: "PerpetualGrowthRate") as! Double
                parameterTitle = "Lt Market return"
                value$ = pGrowthRate.shortString(decimals: 0, formatter: percentFormatter2Digits)
            }
            else if indexPath.row == 3 {
                let ltReturn =  UserDefaults.standard.value(forKey: "LongTermMarketReturn") as! Double
                parameterTitle = "LT Growth rate"
                value$ = ltReturn.shortString(decimals: 0, formatter: percentFormatter2Digits)
            }
            return Rule1DCFCellData(value$: value$, title: parameterTitle, detail$: detail$)

        }
        else if indexPath.section == 1 {
            // Market cap, beta, shares outstanding
            if indexPath.row == 0 {
                value$ = share.key_stats?.marketCap.datedValues(dateOrder: .descending)?.first?.value.shortString(decimals: 0, formatter: currencyFormatterNoGapWithPence) ?? "-"
                parameterTitle = "Market cap."
            } else if indexPath.row == 1 {
                value$ = share.key_stats?.beta.datedValues(dateOrder: .descending)?.first?.value.shortString(decimals: 0, formatter: numberFormatter2Decimals) ?? "-"
                parameterTitle = "Beta"
            }
            else {
                value$ = share.key_stats?.sharesOutstanding.datedValues(dateOrder: .descending)?.first?.value.shortString(decimals: 0, formatter: numberFormatter2Decimals) ?? "-"
                parameterTitle = "Shares outsdg."
            }
            return Rule1DCFCellData(value$: value$, title: parameterTitle, detail$: detail$)
        }
        else if indexPath.section == 2 {
            parameterTitle = "Revenue "
            parameterDV = share.income_statement?.revenue.datedValues(dateOrder: .descending, oneForEachYear: true).dropZeros()
        }
        else if indexPath.section == 3 {
            parameterTitle = "Net income "
            parameterDV = share.income_statement?.netIncome.datedValues(dateOrder: .descending, oneForEachYear: true).dropZeros()
        }
        else if indexPath.section == 4 {
            // Int expense, pretax income, income tax
            if indexPath.row == 0 {
                parameterTitle = "Interest expense "
                value$ = share.income_statement?.interestExpense.datedValues(dateOrder: .descending)?.first?.value.shortString(decimals: 0, formatter: currencyFormatterNoGapWithPence) ?? "-"
            } else if indexPath.row == 1 {
                parameterTitle = "Income pre-tax "
                value$ = share.income_statement?.preTaxIncome.datedValues(dateOrder: .descending)?.first?.value.shortString(decimals: 0, formatter: currencyFormatterNoGapWithPence) ?? "-"
            } else if indexPath.row == 2 {
                parameterTitle = "Income tax "
                let tax = share.income_statement?.incomeTax.datedValues(dateOrder: .descending)?.first?.value
                value$ = tax?.shortString(decimals: 0, formatter: currencyFormatterNoGapWithPence) ?? "-"
                if let revenue = share.income_statement?.revenue.datedValues(dateOrder: .descending)?.first?.value {
                    if revenue != 0 && tax != nil {
                        let proportion = tax!/revenue
                        detail$ = proportion.shortString(decimals: 0, formatter: percentFormatter0Digits)
                    }
                }
            }
            
            return Rule1DCFCellData(value$: value$, title: parameterTitle, detail$: detail$)
        }
        else if indexPath.section == 5 {
            // Current and LT debt
            if indexPath.row == 0 {
                parameterTitle = "Current debt "
                let value = share.balance_sheet?.debt_shortTerm.datedValues(dateOrder: .descending)?.first?.value
                value$ = value?.shortString(decimals: 0, formatter: currencyFormatterNoGapWithPence) ?? "-"
                if value != nil {
                    if let netIncome = share.income_statement?.netIncome.datedValues(dateOrder: .descending)?.first?.value {
                        if netIncome != 0 {
                            let proportion = value!/netIncome
                            detail$ = proportion.shortString(decimals: 1, formatter: percentFormatter0Digits)
                            let greenRange = 0...3.0
                            detailTextColor = greenRange.contains(proportion) ? UIColor.systemGreen : UIColor.systemRed
                        }
                    }
                }
            }
            else {
                parameterTitle = "Long-term debt "
                let value = share.balance_sheet?.debt_longTerm.datedValues(dateOrder: .descending)?.first?.value
                value$ = value?.shortString(decimals: 0, formatter: currencyFormatterNoGapWithPence) ?? "-"
                if value != nil {
                    if let netIncome = share.income_statement?.netIncome.datedValues(dateOrder: .descending)?.first?.value {
                        if netIncome != 0 {
                            let proportion = value!/netIncome
                            detail$ = proportion.shortString(decimals: 1, formatter: percentFormatter0Digits)
                            let greenRange = 0...3.0
                            detailTextColor = greenRange.contains(proportion) ? UIColor.systemGreen : UIColor.systemRed
                        }
                    }
                }
            }
            
            return Rule1DCFCellData(value$: value$, title: parameterTitle, detail$: detail$, detailColor: detailTextColor)
        }
        else if indexPath.section == 6 {
            parameterTitle = "FCF "
            parameterDV = share.cash_flow?.freeCashFlow.datedValues(dateOrder: .descending, oneForEachYear: true).dropZeros()
        }
        else if indexPath.section == 7 {
            parameterTitle = "CapEx "
            parameterDV = share.cash_flow?.capEx.datedValues(dateOrder: .descending, oneForEachYear: true).dropZeros()
        }
        else if indexPath.section == 8 {
            parameterTitle = "Revenue est "
            let future1Revenue = share.analysis?.future_revenue.datedValues(dateOrder: .descending)?.first
            let currentRevenue = share.income_statement?.revenue.datedValues(dateOrder: .descending)?.first?.value
            if indexPath.row == 0 {
                parameterTitle += yearOnlyDateFormatter.string(from: future1Revenue?.date ?? Date())
                value$ = future1Revenue?.value.shortString(decimals: 0, formatter: currencyFormatterNoGapWithPence) ?? "-"
                if future1Revenue?.value != nil && currentRevenue != nil {
                    if currentRevenue! != 0 {
                        let growth = (future1Revenue!.value - currentRevenue!) / currentRevenue!
                        detail$ = growth.shortString(decimals: 1, formatter: percentFormatter2Digits)
                        let greenRange = 0.05...
                        detailTextColor = greenRange.contains(growth) ? UIColor.systemGreen : UIColor.systemRed
                    }
                }
            }
            else {
                let future2Revenue = share.analysis?.future_revenue.datedValues(dateOrder: .descending)?.last
                value$ = future2Revenue?.value.shortString(decimals: 0, formatter: currencyFormatterNoGapWithPence) ?? "-"
                parameterTitle += yearOnlyDateFormatter.string(from: future2Revenue?.date ?? Date())
                if currentRevenue != nil && future2Revenue?.value != nil {
                    if future1Revenue!.value != 0 {
                        let growth = (future2Revenue!.value - currentRevenue!) / currentRevenue!
                        detail$ = growth.shortString(decimals: 1, formatter: percentFormatter2Digits)
                        let greenRange = 0.05...
                        detailTextColor = greenRange.contains(growth) ? UIColor.systemGreen : UIColor.systemRed
                    }
                }
            }
            
            return Rule1DCFCellData(value$: value$, title: parameterTitle, detail$: detail$, detailColor: detailTextColor)

        }
        else if indexPath.section == 9 {
            
            parameterTitle = "Revenue growth "
            let future1Growth = share.analysis?.future_revenueGrowthRate.datedValues(dateOrder: .descending)?.first
            if indexPath.row == 0 {
                parameterTitle += yearOnlyDateFormatter.string(from: future1Growth?.date ?? Date())
                value$ = future1Growth?.value.shortString(decimals: 0, formatter: percentFormatter2Digits) ?? "-"
            }
            else {
                let future2Growth = share.analysis?.future_revenueGrowthRate.datedValues(dateOrder: .descending)?.last
                value$ = future2Growth?.value.shortString(decimals: 0, formatter: percentFormatter2Digits) ?? "-"
                parameterTitle += yearOnlyDateFormatter.string(from: future2Growth?.date ?? Date())
            }
            
            return Rule1DCFCellData(value$: value$, title: parameterTitle, detail$: detail$, detailColor: detailTextColor)
        }
        else if indexPath.section == 10 {
            
            parameterTitle = "Adj. growth "
            let future1Growth = share.analysis?.adjFutureGrowthRate.datedValues(dateOrder: .descending)?.first
            if indexPath.row == 0 {
                parameterTitle += yearOnlyDateFormatter.string(from: future1Growth?.date ?? Date())
                value$ = future1Growth?.value.shortString(decimals: 0, formatter: currencyFormatterNoGapWithPence) ?? "-"
            }
            else {
                let future2Growth = share.analysis?.adjFutureGrowthRate.datedValues(dateOrder: .descending)?.last
                value$ = future2Growth?.value.shortString(decimals: 0, formatter: currencyFormatterNoGapWithPence) ?? "-"
                parameterTitle += yearOnlyDateFormatter.string(from: future2Growth?.date ?? Date())
            }
            
            return Rule1DCFCellData(value$: value$, title: parameterTitle, detail$: detail$, detailColor: detailTextColor)
        }

        // formatting multiple year value sections

        if let dvs = parameterDV {// waste; need to retrieve from data for every element!
            if dvs.count > indexPath.row {
                value$ = dvs[indexPath.row].value.shortString(decimals: 2, formatter: valueFormatter)
                parameterTitle += yearOnlyDateFormatter.string(from: dvs[indexPath.row].date)
            }
            
            let returns = Calculator.ratesOfGrowth(datedValues: dvs) ?? [Double]()
            
            if returns.count > indexPath.row {
                detail$ = returns[indexPath.row].shortString(decimals: 0, formatter: percentFormatter0Digits)
                let greenRange = 0.1...
                detailTextColor = greenRange.contains(returns[indexPath.row]) ? UIColor.systemGreen : UIColor.systemRed
            }

//            if dvs.count > indexPath.row+1 {
//                let growth = (dvs[indexPath.row].value - dvs[indexPath.row+1].value) / dvs[indexPath.row+1].value
//                detail$ = growth.shortString(decimals: 0, formatter: percentFormatter0Digits)
//                let greenRange = 0.1...
//                detailTextColor = greenRange.contains(growth) ? UIColor.systemGreen : UIColor.systemRed
//            }
            return Rule1DCFCellData(value$: value$, title: parameterTitle, detail$: detail$, detailColor: detailTextColor)
        }
        
        return Rule1DCFCellData(value$: value$, title: parameterTitle, detail$: detail$)
    }
    
    /*
    internal func getR1ValuesNew() -> [[DatedValue?]?]  {
        
        let section1 = [nil] as [DatedValue?]
        let section2 = share.ratios?.bvps.convertToDatedValues(dateOrder: .descending)
        let section3 = share.income_statement?.eps_annual.convertToDatedValues(dateOrder: .descending)
        let section4 = share.income_statement?.revenue.convertToDatedValues(dateOrder: .descending)
        let section5 = share.ratios?.ocfPerShare.convertToDatedValues(dateOrder: .descending)
        let section6 = share.ratios?.roi.convertToDatedValues(dateOrder: .descending)
        let section7 = share.ratios?.pe_ratios.convertToDatedValues(dateOrder: .descending)

        var averageGrowth = [DatedValue]()
        if let growth = averageGrowthPrediction() {
            let nextYear = DatesManager.beginningOfYear(of: Date().addingTimeInterval(365*24*3600))
            let yearAfterNext = DatesManager.beginningOfYear(of: Date().addingTimeInterval(2*365*24*3600))
            averageGrowth = [DatedValue(date: yearAfterNext, value: growth), DatedValue(date: nextYear, value: growth)]
        }
        let section8 = share.analysis?.future_growthRate.convertToDatedValues(dateOrder: .descending) ?? averageGrowth
        
        let adjustedGrowthPredictions = share.analysis?.adjFutureGrowthRate.convertToDatedValues(dateOrder: .descending)
        let section9 = [adjustedGrowthPredictions?.first ?? averageGrowth[0], adjustedGrowthPredictions?.last ?? averageGrowth[1]]
        let section10 = [share.balance_sheet?.debt_total.convertToDatedValues(dateOrder: .descending)?.first, share.balance_sheet?.totalDebtProportion()]
        let section11 = [share.key_stats?.insiderShares.convertToDatedValues(dateOrder: .descending)?.first, share.key_stats?.insiderPurchases.convertToDatedValues(dateOrder: .descending)?.first, share.key_stats?.insiderSales.convertToDatedValues(dateOrder: .descending)?.first]
        let section12 = [nil] as [DatedValue?]


        return [section1, section2, section3, section4, section5, section6, section7, section8, section9, section10, section11, section12]

    }
    internal func getR1ValueStrings() -> [[String]]  {
        
        guard let valuation = (self.valuation as? Rule1Valuation) else { return [[String()]] }
        
        let creationDate = dateFormatter.string(from: valuation.creationDate!)
        let section1 = [creationDate]
        
        let (cleanedBVPS, _) = ValuationDataCleaner.cleanValuationData(dataArrays: [valuation.bvps ?? [], valuation.eps ?? []], method: .rule1)
        guard let first = cleanedBVPS.first else {
            return [[String()]]
        }
        guard let futureGrowth = valuation.futureGrowthEstimate(cleanedBVPS: first) else {
            return [[String()]]
        }
        var predictedGrowth = 0.0
        if valuation.adjGrowthEstimates?.mean() ?? 0 != 0.0 {
            predictedGrowth = valuation.adjGrowthEstimates!.mean()!
        } else if valuation.growthEstimates?.mean() ?? 0 != 0.0 {
            predictedGrowth = valuation.growthEstimates!.mean()!
        }
        
        var futurePER$ = ""
        if let futurePER = valuation.futurePER(futureGrowth: futureGrowth) {
            futurePER$ = futurePER.shortString(decimals: 1, formatter: numberFormatterNoFraction)
        } else {
            futurePER$ = "\(valuation.hxPE?.min() ?? 0) - \(valuation.hxPE?.max() ?? 0)"
        }
        let section1New1 = [predictedGrowth.shortString(decimals: 1, formatter: percentFormatter2Digits), futurePER$]
        
        let section2 = valuation.bvps?.shortStrings(decimals: 2) ?? [String]()
        let section3 = valuation.eps?.shortStrings(decimals: 2) ?? [String]()
        let section4 = valuation.revenue?.shortStrings(decimals: 2)  ?? [String]()
        let section5 = valuation.opcs?.shortStrings(decimals: 2) ?? [String]()
        let section6 = valuation.roic?.shortStrings(decimals: 1, formatter: percentFormatter2Digits) ?? [String]()
        let section7 = valuation.hxPE?.sorted().shortStrings(decimals: 1, formatter: numberFormatterWith1Digit) ?? [String]()
        
        var averageGrowth = [Double?]()
        if let growth = averageGrowthPrediction() {
            averageGrowth = [growth, growth]
        }
        let section8 = (valuation.growthEstimates ?? averageGrowth).shortStrings(decimals: 1, formatter: percentFormatter2Digits)
        
        let prediction = averageGrowthPrediction()
        let section9Values = [valuation.adjGrowthEstimates?.first ?? prediction, valuation.adjGrowthEstimates?.last ?? prediction]
        let section10Values = [valuation.debt, valuation.debtProportion()]
        let section11Values = [valuation.insiderStocks, valuation.insiderStockBuys, valuation.insiderStockSells]
        let section12Value = [valuation.ceoRating]
        
        let section9 = section9Values.shortStrings(decimals: 2, formatter: percentFormatter2Digits)
        let section10 = [section10Values[0]?.shortString(decimals: 0, formatter: currencyFormatterNoGapNoPence) ?? "-", section10Values[1]?.shortString(decimals: 2, formatter: percentFormatter2Digits) ?? "-"]
        let section11 = section11Values.shortStrings(decimals: 2, formatter: numberFormatterNoFraction)
        let section12 = section12Value.shortStrings(decimals: 0, formatter: numberFormatterNoFraction)


        return [section1, section1New1, section2, section3, section4, section5, section6, section7, section8, section9, section10, section11, section12]

    }
     */
    
    internal func rule1CellTexts(indexPath: IndexPath) -> Rule1DCFCellData  {
        
        let yearOnlyDateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return formatter
        }()
        
        var parameterTitle = String()
        var value$ = "-"
        var parameterDV: [DatedValue]?
        var valueFormatter = currencyFormatterNoGapWithPence
        var detailTextColor = UIColor.label
        var detail$ = ""
        
        
        if indexPath.section == 0 {
            // Rule1 Date
            let valuation = (self.valuation as? Rule1Valuation) ?? Rule1Valuation(context: share.managedObjectContext!)
            valuation.share = share
            
            return Rule1DCFCellData(value$: dateFormatter.string(from: valuation.creationDate ?? Date()), title: "Latest date", detail$: detail$)
        }
        else if indexPath.section == 1 {
            // Predictions - Growth and PW
            if indexPath.row == 0 {
                let predictedGrowth = share.analysis?.meanFutureGrowthRate(adjusted: true, salesGrowthRate: true) ?? share.analysis?.meanFutureGrowthRate(adjusted: false, salesGrowthRate: true)
                
                return Rule1DCFCellData(value$: predictedGrowth.shortString(decimals: 1, formatter: percentFormatter2Digits), title: "Pred. growth", detail$: detail$)
            }
            else {
                var value$ = String()
                if let predictedPE = share.analysis?.meanFuturePE() {
                    value$ = predictedPE.shortString(decimals: 1, formatter: numberFormatterNoFraction)
                }
                
                let minPE = share.ratios?.minPastPE_ValueOnly() ?? 0
                let maxPE = share.ratios?.maxPastPE_ValueOnly() ?? 0
                
                detail$ = minPE.shortString(decimals: 0, formatter: numberFormatterNoFraction) + "-" + maxPE.shortString(decimals: 0, formatter: numberFormatterNoFraction)

                return Rule1DCFCellData(value$: value$, title: "Pred. PE ratio", detail$: detail$)
            }
        }
        else if indexPath.section == 2 {
            
            parameterTitle = "BVPS "
            parameterDV = share.ratios?.bvps.datedValues(dateOrder: .descending, oneForEachYear: true).dropZeros()
            
        }
        else if indexPath.section == 3 {
            // EPS
            parameterTitle = "EPS "
            parameterDV = share.income_statement?.eps_annual.datedValues(dateOrder: .descending, oneForEachYear: true).dropZeros()
        }
        else if indexPath.section == 4 {
            parameterTitle = "Revenue "
            parameterDV = share.income_statement?.revenue.datedValues(dateOrder: .descending, oneForEachYear: true).dropZeros()
        }
        else if indexPath.section == 5 {
            parameterTitle = "FCF per Share "
            parameterDV = share.ratios?.fcfPerShare.datedValues(dateOrder: .descending, oneForEachYear: true).dropZeros()
        }
        else if indexPath.section == 6 {
            parameterTitle = "ROI "
            parameterDV = share.ratios?.roi.datedValues(dateOrder: .descending, oneForEachYear: true).dropZeros()
            valueFormatter = percentFormatter2Digits
        }
        else if indexPath.section == 7 {
            // min and max PE
            var peDV: Double?
            var title = String()
            if indexPath.row == 0 {
                peDV = share.ratios?.minPastPE_ValueOnly()
                title = "Past PE min"
            } else {
                peDV = share.ratios?.maxPastPE_ValueOnly()
                title = "Past PE max"
            }
            
            value$ = peDV?.shortString(decimals: 1, formatter: numberFormatterWith1Digit) ?? "-"

            return Rule1DCFCellData(value$: value$, title: title, detail$: detail$)
        }
        else if indexPath.section == 8 {
            // analyst predicted min and max growth
            var predictedGrowthRate: Double?
            if indexPath.row == 0 {
                predictedGrowthRate = share.analysis?.minFutureGrowthRate(adjusted: false, salesGrowthRate: true)
            } else {
                predictedGrowthRate = share.analysis?.maxFutureGrowthRate(adjusted: false, salesGrowthRate: true)

            }
            value$ = predictedGrowthRate?.shortString(decimals: 1, formatter: percentFormatter0Digits) ?? "-"
            return Rule1DCFCellData(value$: value$, title: "Pred. rev. growth", detail$: detail$)
        }
        else if indexPath.section == 9 {
            // adjsuted predicted min and max growth
            var predictedGrowthRate: Double?
            if indexPath.row == 0 {
                predictedGrowthRate = share.analysis?.minFutureGrowthRate(adjusted: true, salesGrowthRate: false)
            } else {
                predictedGrowthRate = share.analysis?.maxFutureGrowthRate(adjusted: true, salesGrowthRate: false)

            }
            value$ = predictedGrowthRate?.shortString(decimals: 1, formatter: percentFormatter0Digits) ?? "-"
            return Rule1DCFCellData(value$: value$, title: "Adj pred growth", detail$: detail$)
        }
        else if indexPath.section == 10 {
            // long-term debt and debt/income ratio
            var title$ = String()
            if indexPath.row == 0 {
                let ltDebt = share.balance_sheet?.debt_longTerm.datedValues(dateOrder: .descending, oneForEachYear: true)?.first?.value
                value$ = ltDebt?.shortString(decimals: 0, formatter: valueFormatter) ?? "-"
                title$ = "Long term debt"
            } else {
                title$ = "Debt/ Income"
                if let totalDebt = share.balance_sheet?.debt_total.datedValues(dateOrder: .descending, oneForEachYear: true)?.first?.value {
                    if let netIncome = share.income_statement?.netIncome.datedValues(dateOrder: .descending)?.first?.value {
                        if netIncome != 0 {
                            let ratio = totalDebt/netIncome
                            let greenRange = 0...0.3
                            detailTextColor = greenRange.contains(ratio) ? UIColor.systemGreen : UIColor.systemRed
                            value$ = ratio.shortString(decimals: 1, formatter: percentFormatter0Digits)
                        }
                    }
                }
            }
            
            return Rule1DCFCellData(value$: value$, title: title$, detail$: detail$, detailColor: detailTextColor)
        }
        else if indexPath.section == 11 {
            // insider share total, buys, sales
            var title$ = String()
            var value$ = "-"
            
            if indexPath.row == 0 {
                title$ = "Insider shares"
                let value = share.key_stats?.insiderShares.datedValues(dateOrder: .descending)?.first?.value
                value$ = value?.shortString(decimals: 0, formatter: numberFormatter2Decimals) ?? "-"
            }
            else if indexPath.row == 1 {
                title$ = "Insider share buys"
                if let value = share.key_stats?.insiderPurchases.datedValues(dateOrder: .descending)?.first?.value {
                    value$ = value.shortString(decimals: 0, formatter: numberFormatter2Decimals)
                    if let ts = share.key_stats?.insiderShares.datedValues(dateOrder: .descending)?.first?.value {
                        if ts != 0 {
                            let proportion = value / ts
                            detail$ = proportion.shortString(decimals: 1, formatter: percentFormatter0Digits)
                        }
                    }
                }
            }
            else {
                title$ = "Insider share sales"
                if let value = share.key_stats?.insiderSales.datedValues(dateOrder: .descending)?.first?.value {
                    value$ = value.shortString(decimals: 0, formatter: numberFormatter2Decimals)
                    if let ts = share.key_stats?.insiderShares.datedValues(dateOrder: .descending)?.first?.value {
                        if ts != 0 {
                            let proportion = value / ts
                            detail$ = proportion.shortString(decimals: 1, formatter: percentFormatter0Digits)
                        }
                    }
                }
            }
            
            return Rule1DCFCellData(value$: value$, title: title$, detail$: detail$)
        }
        
        
        // formatting multiple year value sections
        if let dvs = parameterDV {// waste; need to retrieve from data for every element!
            if dvs.count > indexPath.row {
                let value = dvs[indexPath.row].value
                value$ = value.shortString(decimals: 2, formatter: valueFormatter)
                parameterTitle += yearOnlyDateFormatter.string(from: dvs[indexPath.row].date)
                
                // for ROI detail = value in%
                if parameterTitle.contains("ROI") {
                    let value = dvs[indexPath.row].value
                    detail$ = value.shortString(decimals: 0, formatter: percentFormatter0Digits)
                    let greenRange = 0.1...
                    detailTextColor = greenRange.contains(value) ? UIColor.systemGreen : UIColor.systemRed
                    
                    return Rule1DCFCellData(value$: value$, title: parameterTitle, detail$: detail$, detailColor: detailTextColor)
                }
            }
            
            let returns = Calculator.ratesOfGrowth(datedValues: dvs) ?? [Double]()
            
            if returns.count > indexPath.row {
                detail$ = returns[indexPath.row].shortString(decimals: 0, formatter: percentFormatter0Digits)
                let greenRange = 0.1...
                detailTextColor = greenRange.contains(returns[indexPath.row]) ? UIColor.systemGreen : UIColor.systemRed
            }
            
//            if dvs.count > indexPath.row+1 {
//                let growth = (dvs[indexPath.row].value - dvs[indexPath.row+1].value) / dvs[indexPath.row+1].value
//                detail$ = growth.shortString(decimals: 0, formatter: percentFormatter0Digits)
//                let greenRange = 0.1...
//                detailTextColor = greenRange.contains(growth) ? UIColor.systemGreen : UIColor.systemRed
//            }
            
        }
        
        return Rule1DCFCellData(value$: value$, title: parameterTitle, detail$: detail$, detailColor: detailTextColor)

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
            
            if valuation.growthEstimates?.count ?? 0 == 1 {
                // if there's only one element (min, max) then duplicate the one element
                valuation.growthEstimates?.append(valuation.growthEstimates!.first!)
            }

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
    
    // returns either mean non-adusted future growth, or ema or mean of past bvps growth rates
    internal func rule1PredictedGrowth() -> Double? {
        
        if let g = share.analysis?.meanFutureGrowthRate(adjusted: false, salesGrowthRate: true) {
            return g
        } else {
            
            var growthRates = [Double]()
            if let bvps = share.ratios?.bvps.valuesOnly(dateOrdered: .descending) { // for ema
                if bvps.count > 1 {
                    for i in 1..<bvps.count {
                        let rate = (bvps[i-1] - bvps[i]) / bvps[i]
                        growthRates.append(rate)
                    }
                }
            }
            
            return growthRates.ema(periods: growthRates.count - 3) ?? growthRates.mean()

        }
    }
    
    /// returns detail value for the SAME row based on any existing later elements
    /// expects array in TIME DESCENDING order
    internal func calculateGrowthDCF(_ array: [Double]?, element: Int) -> Double? {
        guard let numbers = array else {
            return nil
        }
        
        guard numbers.count > (element + 1) else {
            return nil
        }
        
        let result = (numbers[element] - numbers[element+1]) / abs(numbers[element+1])

        
        return (!result.isNaN && result.isFinite) ? result : nil
                
    }
 
    /// 'element' is the order number in the DESCENDING valueArray to calculate compound growth in relation to first element in valueArray
    /// the element number is interpreted as 'years' backwards since date of first element
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
    
//    func r1MoatParameterCount() -> Int? {
//
//
//        guard  let v = valuation as? Rule1Valuation else {
//            return nil
//        }
//
//        let arrays = [v.bvps, v.eps, v.revenue, v.opcs, v.roic]
//        var countNonZero = 0
//        for array in arrays {
//            countNonZero += array?.compactMap{ $0 }.filter({ (value) -> Bool in
//                if value != 0 { return true }
//                else { return false }
//            }).count ?? 0
//        }
//
//        return countNonZero
//    }

}

extension CombinedValuationController: DownloadRedirectionDelegate {
    
    func awaitingRedirection(notification: Notification) {
        
        NotificationCenter.default.removeObserver(self)
        
        if let request = notification.object as? URLRequest {
            if let url = request.url {
                
                guard url.absoluteString.starts(with: "https://www.macrotrends.net") else {
                    ErrorController.addInternalError(errorLocation: "awaitingRedirection", systemError: nil, errorInfo: "redirection request to non-macrotrends page reived \(request.url?.path ?? "")")
                    return
                }
                       
                var components = url.pathComponents.dropLast()
                if let component = components.last {
                    let mtShortName = String(component)
                    components = components.dropLast()
                    if let symbolComponent = components.last {
                        let symbol = String(symbolComponent)
                        
                        DispatchQueue.main.async {
                            if self.share.symbol == symbol {
                                self.share.name_short = mtShortName
                                do {
                                    try self.share.managedObjectContext?.save()
                                } catch let error {
                                    ErrorController.addInternalError(errorLocation: "StocksController2.awaitingRedirection", systemError: error, errorInfo: "couldn't save \(symbol) in it's MOC after downlaod re-direction")
                                }
                                
                                if let info = notification.userInfo as? [String:Any] {
                                    if let task = info["task"] as? DownloadTask {
                                        switch task {
                                        case .epsPER:
                                            print("CombinedValuationController: redirect for \(symbol) epsPER task recevied")
                                        case .test:
                                            print("CombinedValuationController: redirect for \(symbol) test task recevied")
                                        case .wbValuation:
                                            print("CombinedValuationController: redirect for \(symbol) wbValuation task recevied")
                                        case .r1Valuation:
                                            print("CombinedValuationController: redirect for \(symbol) r1Valuation task recevied")
                                            self.startDataDownload()
                                        case .qEPS:
                                            print("WBValuationController: redirect for \(symbol) qEPS task received")
                                        case .healthData:
                                            print("FinHealthController: redirect for \(symbol) healthData task received")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? {
           
        let object = request
        let notification = Notification(name: Notification.Name(rawValue: "Redirection"), object: object, userInfo: nil)
        NotificationCenter.default.post(notification)

        return nil
    }
}
