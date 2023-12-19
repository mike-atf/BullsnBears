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
    func cellInfoNew(indexPath: IndexPath) -> Rule1DCFCellData
    func userEnteredText(sender: UITextField, indexPath: IndexPath)
    func sectionTitles() -> [String]
    func sectionSubTitles() -> [String]

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
        
//        newValuation?.company = company
        
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
//        newValuation?.company = company
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
            subtitles = ["Download, or enter data", "" ,"1. Book Value per Share", "2. Earnings per Share", "3. Revenue", "4. Free Cash Flow Per Share", "5. Return on Invested Capital", "min and max last 5-10 years", "Analysts min and max predictions","Adjust the predicted growth rates", "", "last 6 months", "Optional, between 0 - 10"]
        }
        
        return subtitles
    }
    
    
    func userEnteredText(sender: UITextField, indexPath: IndexPath) {
        
        guard let validtext = sender.text else {
            return
        }
        
        guard validtext != "" else {
            return
        }
        
        guard let value = validtext.textToNumber() else {
            ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "error converting entered text to number: \(sender.text ?? "no text")")
            return
        }
        
        if (self.valuation as? DCFValuation) != nil {
            convertUserEntryDCF(value, indexPath: indexPath)
        }
        else if (self.valuation as? Rule1Valuation) != nil {
            convertUserEntryR1(value, indexPath: indexPath)
        }
        
        sender.text = "\(value)"
    }
   
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
   
    
    //MARK: - Internal functions
    
    public func startDataDownload(progressDelegate: ProgressViewDelegate?=nil) {
        
        // accessing share properties must happen on main thread!
        let symbol =  share.symbol
        let shortName = share.name_short
        let shareID = share.objectID
        
        let tasks = (method == .rule1) ? (MacrotrendsScraper.countOfRowsToDownload(option: .rule1Only) + YahooPageScraper.countOfRowsToDownload(option: .rule1Only)) : (MacrotrendsScraper.countOfRowsToDownload(option: .dcfOnly) + YahooPageScraper.countOfRowsToDownload(option: .dcfOnly))
        
        progressDelegate?.allTasks = tasks
        
        if method == .rule1 {
            share.rule1Valuation?.creationDate = Date()
            downloadTask = Task.init(priority: .background) {
                
                await MacrotrendsScraper.dataDownloadAnalyseSave(shareSymbol: symbol, shortName: shortName, shareID: shareID, downloadOption: .rule1Only, progressDelegate: progressDelegate, downloadRedirectDelegate: nil)
                
                await YahooPageScraper.dataDownloadAnalyseSave(symbol: symbol ?? "missing", shortName: shortName ?? "missing", shareID: shareID, option: .rule1Only,  progressDelegate: progressDelegate ,downloadRedirectDelegate: nil)

                progressDelegate?.downloadComplete()
                return nil
            }
        }
        else {
            share.dcfValuation?.creationDate = Date()
            downloadTask = Task.init(priority: .background) {
                
                await MacrotrendsScraper.dataDownloadAnalyseSave(shareSymbol: symbol, shortName: shortName, shareID: shareID, downloadOption: .dcfOnly, progressDelegate: progressDelegate, downloadRedirectDelegate: nil)
                
                await YahooPageScraper.dataDownloadAnalyseSave(symbol: symbol ?? "missing", shortName: shortName ?? "missing", shareID: shareID, option: .dcfOnly,  progressDelegate: progressDelegate ,downloadRedirectDelegate: nil)

                progressDelegate?.downloadComplete()
                return nil
            }
        }
        
    }
    

    public func stopDownload() {
        
        NotificationCenter.default.removeObserver(webAnalyser as Any)
        
        downloadTask?.cancel()
    }

     
    internal func convertUserEntryDCF(_ value: Double, indexPath: IndexPath) {
        
        switch indexPath.section {
        case 0:
            // 'General
            switch indexPath.row {
            case 0:
                // date - do nothing
                return
            case 1:
                UserDefaults.standard.set(value, forKey: "10YUSTreasuryBondRate")
            case 2:
                UserDefaults.standard.set(value, forKey: "LongTermMarketReturn")
            case 3:
                UserDefaults.standard.set(value, forKey: "PerpetualGrowthRate")
            default:
                ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "undefined indexpath \(indexPath) in DCFValuation.getValuationListItem")
            }
        case 1:
            // 'Key Statistics

            switch indexPath.row {
            case 0:
                share.key_stats?.marketCap = [DatedValue(date: Date(), value: value)].convertToData()
            case 1:
                share.key_stats?.beta = [DatedValue(date: Date(), value: value)].convertToData()
            case 2:
                share.key_stats?.sharesOutstanding = [DatedValue(date: Date(), value: value)].convertToData()
            default:
                ErrorController.addInternalError(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
            }
        case 2:
            //TODO: - the following cases are wrong. Per indexPath a date related to the year most be identified
            // 'Income Statement S1 - Revenue
            let dvs = share.income_statement?.revenue.datedValues(dateOrder: .descending)
            let latestYear = dvs?.first?.date ?? Date()
            let yearForRow = latestYear.addingTimeInterval(-(Double(indexPath.row)*365*24*3600))
            let newDV = [DatedValue(date: yearForRow, value: value)]
            if dvs != nil {
                share.income_statement?.revenue = dvs?.mergeIn(newDV: newDV)?.convertToData()
            } else {
                share.income_statement?.revenue = newDV.convertToData()
            }
//            valuation.tRevenueActual?.add(value: value, index: indexPath.row)
        case 3:
            // 'Income Statement S2 - net income
            let dvs = share.income_statement?.netIncome.datedValues(dateOrder: .descending)
            let latestYear = dvs?.first?.date ?? Date()
            let yearForRow = latestYear.addingTimeInterval(-(Double(indexPath.row)*365*24*3600))
            let newDV = [DatedValue(date: yearForRow, value: value)]
            if dvs != nil {
                share.income_statement?.netIncome = dvs?.mergeIn(newDV: newDV)?.convertToData()
            } else {
                share.income_statement?.netIncome = newDV.convertToData()
            }
//            valuation.netIncome?.add(value: value, index: indexPath.row)
        case 4:
            // 'Income Statement S3 -
            switch indexPath.row {
            case 0:
                let dvs = share.income_statement?.interestExpense.datedValues(dateOrder: .descending)
                let latestYear = dvs?.first?.date ?? Date()
                let yearForRow = latestYear.addingTimeInterval(-(Double(indexPath.row)*365*24*3600))
                let newDV = [DatedValue(date: yearForRow, value: value)]
                if dvs != nil {
                    share.income_statement?.interestExpense = dvs?.mergeIn(newDV: newDV)?.convertToData()
                } else {
                    share.income_statement?.interestExpense = newDV.convertToData()
                }
//                valuation.expenseInterest = value
            case 1:
                let dvs = share.income_statement?.preTaxIncome.datedValues(dateOrder: .descending)
                let latestYear = dvs?.first?.date ?? Date()
                let yearForRow = latestYear.addingTimeInterval(-(Double(indexPath.row)*365*24*3600))
                let newDV = [DatedValue(date: yearForRow, value: value)]
                if dvs != nil {
                    share.income_statement?.preTaxIncome = dvs?.mergeIn(newDV: newDV)?.convertToData()
                } else {
                    share.income_statement?.preTaxIncome = newDV.convertToData()
                }
//                valuation.incomePreTax = value
            case 2:
                let dvs = share.income_statement?.incomeTax.datedValues(dateOrder: .descending)
                let latestYear = dvs?.first?.date ?? Date()
                let yearForRow = latestYear.addingTimeInterval(-(Double(indexPath.row)*365*24*3600))
                let newDV = [DatedValue(date: yearForRow, value: value)]
                if dvs != nil {
                    share.income_statement?.incomeTax = dvs?.mergeIn(newDV: newDV)?.convertToData()
                } else {
                    share.income_statement?.incomeTax = newDV.convertToData()
                }
//                valuation.expenseIncomeTax = value
            default:
                ErrorController.addInternalError(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
            }
        case 5:
            // 'balance sheet'
           switch indexPath.row {
            case 0:
               let dvs = share.balance_sheet?.debt_shortTerm.datedValues(dateOrder: .descending)
               let latestYear = dvs?.first?.date ?? Date()
               let yearForRow = latestYear.addingTimeInterval(-(Double(indexPath.row)*365*24*3600))
               let newDV = [DatedValue(date: yearForRow, value: value)]
               if dvs != nil {
                   share.balance_sheet?.debt_shortTerm = dvs?.mergeIn(newDV: newDV)?.convertToData()
               } else {
                   share.balance_sheet?.debt_shortTerm = newDV.convertToData()
               }
//                valuation.debtST = value
            case 1:
               let dvs = share.balance_sheet?.debt_longTerm.datedValues(dateOrder: .descending)
               let latestYear = dvs?.first?.date ?? Date()
               let yearForRow = latestYear.addingTimeInterval(-(Double(indexPath.row)*365*24*3600))
               let newDV = [DatedValue(date: yearForRow, value: value)]
               if dvs != nil {
                   share.balance_sheet?.debt_longTerm = dvs?.mergeIn(newDV: newDV)?.convertToData()
               } else {
                   share.balance_sheet?.debt_longTerm = newDV.convertToData()
               }
//               valuation.debtLT = value
            default:
                ErrorController.addInternalError(errorLocation: #file + "."  + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
            }
        case 6:
            // 'Cash Flow S1
            let dvs = share.cash_flow?.opCashFlow.datedValues(dateOrder: .descending)
            let latestYear = dvs?.first?.date ?? Date()
            let yearForRow = latestYear.addingTimeInterval(-(Double(indexPath.row)*365*24*3600))
            let newDV = [DatedValue(date: yearForRow, value: value)]
            if dvs != nil {
                share.cash_flow?.opCashFlow = dvs?.mergeIn(newDV: newDV)?.convertToData()
            } else {
                share.cash_flow?.opCashFlow = newDV.convertToData()
            }
//            valuation.tFCFo?.add(value: value, index: indexPath.row)
        case 7:
            // 'Cash Flow S2
            let dvs = share.cash_flow?.capEx.datedValues(dateOrder: .descending)
            let latestYear = dvs?.first?.date ?? Date()
            let yearForRow = latestYear.addingTimeInterval(-(Double(indexPath.row)*365*24*3600))
            let newDV = [DatedValue(date: yearForRow, value: abs(value) * -1)]
            if dvs != nil {
                share.cash_flow?.capEx = dvs?.mergeIn(newDV: newDV)?.convertToData()
            } else {
                share.cash_flow?.capEx = newDV.convertToData()
            }

//            if value > 0 { valuation.capExpend![indexPath.row]  = value * -1 }
//            else {
//                valuation.capExpend?.add(value: value, index: indexPath.row)
//            }
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

        case 10:
            // adjsuted predicted growth rate
            let dvs = share.analysis?.adjFutureGrowthRate.datedValues(dateOrder: .descending)
            let latestYear = dvs?.first?.date ?? Date()
            let yearForRow = latestYear.addingTimeInterval(-(Double(indexPath.row)*365*24*3600))
            let newDV = [DatedValue(date: yearForRow, value: abs(value) * -1)]
            if dvs != nil {
                share.analysis?.adjFutureGrowthRate = dvs?.mergeIn(newDV: newDV)?.convertToData()
            } else {
                share.analysis?.adjFutureGrowthRate = newDV.convertToData()
            }
//            valuation.revGrowthPredAdj?.add(value: value / 100.0, index: indexPath.row)
        default:
            ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "unrecogniased indexPath \(indexPath)")
        }
        
//        if let updatePaths = rowsToUpdateAfterUserEntry(indexPath) {
//            valuationListViewController.helperUpdatedRows(paths: updatePaths)
//        }
        
        do {
            try share.managedObjectContext?.save()
        } catch let error {
            ErrorController.addInternalError(errorLocation: "CombinedValController.convertUserEntryDCF", systemError: error , errorInfo: "Unable to to save user entry to valuation's moc")
        }
        
//        var jumpToCellPath = IndexPath(row: indexPath.row+1, section: indexPath.section)
//        if jumpToCellPath.row > rowtitles[indexPath.section].count-1 {
//            jumpToCellPath = IndexPath(row: 0, section: indexPath.section + 1)
//        }
//         if jumpToCellPath.section < rowtitles.count {
//            valuationListViewController.goToNextTextField(targetPath: jumpToCellPath)
//        }
    }
    
    internal func convertUserEntryR1(_ value: Double, indexPath: IndexPath) {
        
        switch indexPath.section {
        case 0:
            // 'General
            return
        case 1:
            // 'Predictions
            if indexPath.row == 0 {
                
                let date1 = DatesManager.endOfYear(of: Date().addingTimeInterval(365*24*3600))
                let date2 = DatesManager.endOfYear(of: Date())
                
                let datedValue1 = DatedValue(date: date1, value: value/100)
                let datedValue2 = DatedValue(date: date2, value: value/100)
                share.analysis?.adjFutureGrowthRate = [datedValue1, datedValue2].convertToData()

            } else {
                let date1 = DatesManager.endOfYear(of: Date().addingTimeInterval(365*24*3600))
                let date2 = DatesManager.endOfYear(of: Date())
                
                let datedValue1 = DatedValue(date: date1, value: value)
                let datedValue2 = DatedValue(date: date2, value: value)
                share.analysis?.adjForwardPE = [datedValue1, datedValue2].convertToData()
            }
        case 2:
            // 'Moat parameters - BVPS
            var bvps = share.ratios?.bvps.datedValues(dateOrder: .descending)
            let latestYear = bvps?.first?.date ?? DatesManager.endOfYear(of: Date().addingTimeInterval(-365*24*3600))
            let yearForRow = latestYear.addingTimeInterval(-(Double(indexPath.row)*365*24*3600))
            let newDV = DatedValue(date: yearForRow, value: value)
            if bvps != nil {
                bvps = bvps?.replacedAllValuesInYear(newDV: newDV)
                share.ratios?.bvps = bvps?.convertToData()
            } else {
                share.ratios?.bvps = [newDV].convertToData()
            }
            
        case 3:
            // 'Moat parameters - EPS
            var epsa = share.income_statement?.eps_annual.datedValues(dateOrder: .descending)
            let latestYear = epsa?.first?.date ?? DatesManager.endOfYear(of: Date().addingTimeInterval(-365*24*3600))
            let yearForRow = latestYear.addingTimeInterval(-(Double(indexPath.row)*365*24*3600))
            let newDV = DatedValue(date: yearForRow, value: value)
            if epsa != nil {
                epsa =  epsa?.replacedAllValuesInYear(newDV: newDV)
                share.income_statement?.eps_annual = epsa?.convertToData()
            } else {
                share.income_statement?.eps_annual = [newDV].convertToData()
            }
        case 4:
            // 'Moat parameters - Revenue
            var revenue = share.income_statement?.revenue.datedValues(dateOrder: .descending)
            let latestYear = revenue?.first?.date ?? DatesManager.endOfYear(of: Date().addingTimeInterval(-365*24*3600))
            let yearForRow = latestYear.addingTimeInterval(-(Double(indexPath.row)*365*24*3600))
            let newDV = DatedValue(date: yearForRow, value: value)
            if revenue != nil {
                revenue = revenue?.replacedAllValuesInYear(newDV: newDV)
                share.income_statement?.revenue = revenue?.convertToData()
            } else {
                share.income_statement?.revenue = [newDV].convertToData()
            }
        case 5:
            // 'Moat parameters - FCF
            var opcs = share.ratios?.ocfPerShare.datedValues(dateOrder: .descending)
            let latestYear = opcs?.first?.date ?? DatesManager.endOfYear(of: Date().addingTimeInterval(-365*24*3600))
            let yearForRow = latestYear.addingTimeInterval(-(Double(indexPath.row)*365*24*3600))
            let newDV = DatedValue(date: yearForRow, value: value)
            if opcs != nil {
                opcs = opcs?.replacedAllValuesInYear(newDV: newDV)
                share.ratios?.ocfPerShare = opcs?.convertToData()
            } else {
                share.ratios?.ocfPerShare = [newDV].convertToData()
            }
        case 6:
            // 'Moat parameters - ROIC
            var roi = share.ratios?.roi.datedValues(dateOrder: .descending)
            let latestYear = roi?.first?.date ?? DatesManager.endOfYear(of: Date().addingTimeInterval(-365*24*3600))
            let yearForRow = latestYear.addingTimeInterval(-(Double(indexPath.row)*365*24*3600))
            let newDV = DatedValue(date: yearForRow, value: value)
            if roi != nil {
                roi = roi?.replacedAllValuesInYear(newDV: newDV)
                share.ratios?.roi = roi?.convertToData()
            } else {
                share.ratios?.roi = [newDV].convertToData()
            }
        case 7:
            // 'Historical min /max PER
            if indexPath.row == 0 {
                // min
                share.pe_min = value
                if share.pe_max != 0 {
                    let mean = (share.pe_min + share.pe_max)/2
                    let nextYear = DatesManager.endOfYear(of: Date().addingTimeInterval(365*24*3500))
                    let forwardPE = DatedValue(date: nextYear, value: mean)
                    share.analysis?.forwardPE = [forwardPE].convertToData()
                }
            } else {
                // max
                share.pe_max = value
                if share.pe_min != 0 {
                    let mean = (share.pe_min + share.pe_max)/2
                    let nextYear = DatesManager.endOfYear(of: Date().addingTimeInterval(365*24*3500))
                    let forwardPE = DatedValue(date: nextYear, value: mean)
                    share.analysis?.forwardPE = [forwardPE].convertToData()
                }
            }
        case 8:
            // 'Growth predictions
            var growth = share.analysis?.future_growthNextYear.datedValues(dateOrder: .descending)
            let latestYear = growth?.first?.date ?? Date().addingTimeInterval(2*365*24*3600)
            let yearForRow = latestYear.addingTimeInterval(-(Double(indexPath.row)*365*24*3600))
            let newDV = DatedValue(date: yearForRow, value: value)
            if growth != nil {
                growth?.append(newDV)
                share.analysis?.future_growthNextYear = growth?.convertToData()
            } else {
                share.analysis?.future_growthNextYear = [newDV].convertToData()
            }
        case 9:
            // 'Adjusted Growth predictions
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

       case 10:
            // 'Debt
            if indexPath.row == 0 {
                var debt = share.balance_sheet?.debt_total.datedValues(dateOrder: .descending)
                let datedValue = DatedValue(date: Date(), value: value)
                if debt != nil {
                    debt = debt?.replacedAllValuesInYear(newDV: datedValue)
                    share.balance_sheet?.debt_total = debt?.convertToData()
                } else {
                    share.balance_sheet?.debt_total = [datedValue].convertToData()
                }
            }
        case 11:
            // 'Insider Stocks'
            if indexPath.row == 0 {
                var iss = share.key_stats?.insiderShares.datedValues(dateOrder: .descending)
                let datedValue = DatedValue(date: Date(), value: value)
                if iss != nil {
                    iss = iss?.replacedAllValuesInYear(newDV: datedValue)
                    share.key_stats?.insiderShares = iss?.convertToData()
                } else {
                    share.key_stats?.insiderShares = [datedValue].convertToData()
                }
            }
            else if indexPath.row == 1 {
                var isp = share.key_stats?.insiderPurchases.datedValues(dateOrder: .descending)
                let datedValue = DatedValue(date: Date(), value: value)
                if isp != nil {
                    isp = isp?.replacedAllValuesInYear(newDV: datedValue)
                    share.key_stats?.insiderPurchases = isp?.convertToData()
                } else {
                    share.key_stats?.insiderPurchases = [datedValue].convertToData()
                }
            }
            else if indexPath.row == 2 {
                var issa = share.key_stats?.insiderSales.datedValues(dateOrder: .descending)
                let datedValue = DatedValue(date: Date(), value: value)
                if issa != nil {
                    issa = issa?.replacedAllValuesInYear(newDV: datedValue)
                    share.key_stats?.insiderPurchases = issa?.convertToData()
                } else {
                    share.key_stats?.insiderPurchases = [datedValue].convertToData()
                }
            }
        case 12:
            share.rule1Valuation?.ceoRating = value
        default:
            ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "unrecognised indexPath \(indexPath)")
        }
        
        do {
            try share.managedObjectContext?.save()
        } catch {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "Error trying to save new user entry in DCF valuation controller")
        }
        
    }

    internal func rowsToUpdateAfterUserEntry(_ indexPath: IndexPath) -> [IndexPath]? {
        
        if self.valuation is DCFValuation {

            var paths = [IndexPath(row: indexPath.row, section: indexPath.section)]

            switch indexPath.section {
            case 2:
                if indexPath.row > 0 && indexPath.row < (share.income_statement?.revenue.valuesOnly(dateOrdered: .ascending, withoutZeroes: true)?.count ?? 0) {
                    paths.append(IndexPath(row: indexPath.row-1, section: indexPath.section))
                }
                paths.append(IndexPath(row: 0, section: 10))
                paths.append(IndexPath(row: 1, section: 10))
            case 3:
                if indexPath.row > 0 && indexPath.row < (share.income_statement?.netIncome.valuesOnly(dateOrdered: .ascending, withoutZeroes: true)?.count ?? 0) {
                    paths.append(IndexPath(row: indexPath.row-1, section: indexPath.section))
                }
            case 4:
                if indexPath.row == 1{
                    paths.append(IndexPath(row: 2, section: 4))
                }
            case 5:
                paths.append(IndexPath(row: 1, section: indexPath.section))
            case 6:
                if indexPath.row > 0 && indexPath.row < (share.cash_flow?.freeCashFlow.valuesOnly(dateOrdered: .ascending, withoutZeroes: true)?.count ?? 0) {
                    paths.append(IndexPath(row: indexPath.row-1, section: indexPath.section))
                }
            case 7:
                if indexPath.row > 0 && indexPath.row < (share.cash_flow?.capEx.valuesOnly(dateOrdered: .ascending, withoutZeroes: true)?.count ?? 0) {
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
        else if self.valuation is Rule1Valuation {
            
            var paths = [IndexPath(row: indexPath.row, section: indexPath.section)]

            switch indexPath.section {
            case 1:
                if indexPath.row > 0 && indexPath.row < (share.ratios?.bvps.valuesOnly(dateOrdered: .ascending, withoutZeroes: true)?.count ?? 0) {
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
        
    
    internal func dcfCellTexts(indexPath: IndexPath) -> Rule1DCFCellData {
        
        let yearOnlyDateFormatter: DateFormatter = {
            let formatter = DateFormatter()
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
                let pGrowthRate = UserDefaults.standard.value(forKey: "LongTermMarketReturn") as! Double
                parameterTitle = "Exp. Market return"
                value$ = pGrowthRate.shortString(decimals: 0, formatter: percentFormatter2Digits)
            }
            else if indexPath.row == 3 {
                let ltReturn =  UserDefaults.standard.value(forKey: "PerpetualGrowthRate") as! Double
                parameterTitle = "LT Growth rate"
                value$ = ltReturn.shortString(decimals: 0, formatter: percentFormatter2Digits)
            }
            return Rule1DCFCellData(value$: value$, title: parameterTitle, detail$: detail$)

        }
        else if indexPath.section == 1 {
            // Market cap, beta, shares outstanding
            if indexPath.row == 0 {
                value$ = share.key_stats?.marketCap.datedValues(dateOrder: .descending, includeThisYear: true)?.first?.value.shortString(decimals: 0, formatter: currencyFormatterNoGapWithPence) ?? "-"
                parameterTitle = "Market cap."
            } else if indexPath.row == 1 {
                value$ = share.key_stats?.beta.datedValues(dateOrder: .descending, includeThisYear: true)?.first?.value.shortString(decimals: 0, formatter: numberFormatter2Decimals) ?? "-"
                parameterTitle = "Beta"
            }
            else {
                value$ = share.key_stats?.sharesOutstanding.datedValues(dateOrder: .descending, includeThisYear: true)?.first?.value.shortString(decimals: 0, formatter: numberFormatter2Decimals) ?? "-"
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
            let futureRevenueDV = share.analysis?.future_revenue.datedValues(dateOrder: .ascending, includeThisYear: true)
            let future1Revenue = futureRevenueDV?.first //first is for next year
            let currentRevenue = share.income_statement?.revenue.datedValues(dateOrder: .descending, includeThisYear: true)?.first?.value
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
            else if futureRevenueDV?.count ?? 0 > 1 {
                let future2Revenue = futureRevenueDV!.last
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
            let future1Growth = share.analysis?.future_revenueGrowthRate.datedValues(dateOrder: .descending, includeThisYear: true)?.first
            if indexPath.row == 0 {
                parameterTitle += yearOnlyDateFormatter.string(from: future1Growth?.date ?? Date())
                value$ = future1Growth?.value.shortString(decimals: 0, formatter: percentFormatter2Digits) ?? "-"
            }
            else {
                let future2Growth = share.analysis?.future_revenueGrowthRate.datedValues(dateOrder: .descending, includeThisYear: true)?.last
                value$ = future2Growth?.value.shortString(decimals: 0, formatter: percentFormatter2Digits) ?? "-"
                parameterTitle += yearOnlyDateFormatter.string(from: future2Growth?.date ?? Date())
            }
            
            return Rule1DCFCellData(value$: value$, title: parameterTitle, detail$: detail$, detailColor: detailTextColor)
        }
        else if indexPath.section == 10 {
            
            parameterTitle = "Adj. growth "
            let future1Growth = share.analysis?.adjFutureGrowthRate.datedValues(dateOrder: .descending, includeThisYear: true)?.first
            if indexPath.row == 0 {
                parameterTitle += yearOnlyDateFormatter.string(from: future1Growth?.date ?? Date())
                value$ = future1Growth?.value.shortString(decimals: 0, formatter: currencyFormatterNoGapWithPence) ?? "-"
            }
            else {
                let future2Growth = share.analysis?.adjFutureGrowthRate.datedValues(dateOrder: .descending,includeThisYear: true)?.last
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
            
            let returns = Calculator.reatesOfReturn(datedValues: dvs) ?? [Double]()
            
            if returns.count > indexPath.row {
                detail$ = returns[indexPath.row].shortString(decimals: 0, formatter: percentFormatter0Digits)
                let greenRange = 0.1...
                detailTextColor = greenRange.contains(returns[indexPath.row]) ? UIColor.systemGreen : UIColor.systemRed
            }

            return Rule1DCFCellData(value$: value$, title: parameterTitle, detail$: detail$, detailColor: detailTextColor)
        }
        
        return Rule1DCFCellData(value$: value$, title: parameterTitle, detail$: detail$)
    }
    
    
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
            // Predictions - Growth and PE
            if indexPath.row == 0 {
                let predictedGrowth = share.analysis?.meanFutureGrowthRate(adjusted: true, salesGrowthRate: true) ?? share.analysis?.meanFutureGrowthRate(adjusted: false, salesGrowthRate: true)
                
                return Rule1DCFCellData(value$: predictedGrowth.shortString(decimals: 1, formatter: percentFormatter2Digits), title: "Pred. growth", detail$: detail$)
            }
            else {
                var value$ = String()
                if let predictedPE = share.analysis?.adjForwardPE.datedValues(dateOrder: .ascending)?.last?.value {
                    value$ = predictedPE.shortString(decimals: 1, formatter: numberFormatterNoFraction)
                } else if let ppe = share.analysis?.forwardPE.datedValues(dateOrder: .ascending)?.last?.value {
                    value$ = ppe.shortString(decimals: 1, formatter: numberFormatterNoFraction)
                } else if (share.pe_min != 0 && share.pe_max != 0) {
                    let mean = (share.pe_min + share.pe_max)/2
                    value$ = mean.shortString(decimals: 1, formatter: numberFormatterNoFraction)
                }
                
                let minPE = share.pe_min
                let maxPE = share.pe_max
                
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
            parameterTitle = "OCF per Share " //(=OCF, used by moatScore)
            parameterDV = share.ratios?.ocfPerShare.datedValues(dateOrder: .descending, oneForEachYear: true).dropZeros()
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
                peDV = share.pe_min
                title = "Past PE min"
            } else {
                peDV = share.pe_max
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
            
            let returns = Calculator.reatesOfReturn(datedValues: dvs) ?? [Double]()
            
            if returns.count > indexPath.row {
                detail$ = returns[indexPath.row].shortString(decimals: 0, formatter: percentFormatter0Digits)
                let greenRange = 0.1...
                detailTextColor = greenRange.contains(returns[indexPath.row]) ? UIColor.systemGreen : UIColor.systemRed
            }
           
        }
        
        return Rule1DCFCellData(value$: value$, title: parameterTitle, detail$: detail$, detailColor: detailTextColor)

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
