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
    
    let dcfValuationSectionTitles = ["General","Key Statistics", "Income Statement", "", "", "Balance Sheet", "Cash Flow", "", "Revenue & Growth prediction","","Adjusted future growth"]
    let dcfValuationSectionSubtitles = ["General","Yahoo Summary > Key Statistics", "Details > Financials > Income Statement", "", "", "Details > Financials > Balance Sheet", "Details > Financials > Cash Flow", "","Details > Analysis > Revenue estimate", "", ""]
    
       
    init(listView: ValuationListViewController) {
        self.valuationListViewController = listView
        self.valuation = listView.valuation
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
                print("error fetching dcfValuations: \(error)")
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
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }

        return newValuation
    }
    
    public func dcfSectionTitles() -> [String] {
        return dcfValuationSectionTitles
    }
    
    public func dcfSectionSubTitles() -> [String] {
        return dcfValuationSectionSubtitles
    }
    
    internal func dcfCellValueFormat(indexPath: IndexPath) -> ValuationCellValueFormat {
        
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
                print("undefined indexpath \(indexPath) in DCFValuation.returnValuationListItem")
            }
        case 1:
            // 'Key Statistics
            switch indexPath.row {
            case 0:
                return .currency
            case 1:
                return .number
            default:
                print("undefined indexpath \(indexPath) in DCFValuation.returnValuationListItem")
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
                print("undefined indexpath \(indexPath) in DCFValuation.returnValuationListItem")
            }
        case 5:
            // 'balance sheet'
            switch indexPath.row {
            case 0:
                return .currency
            case 1:
                return .currency
            default:
                print("undefined indexpath \(indexPath) in DCFValuation.returnValuationListItem")
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
            print("undefined indexpath \(indexPath) in DCFValuation.returnValuationListItem")
        }
        
        return .number
    }
    
    public func configureCell(indexPath: IndexPath, cell: ValuationTableViewCell) {
        
        let value = getDCFValue(indexPath: indexPath)
        let value$ = getCellValueText(value: value, indexPath: indexPath)
        let rowTitle = (rowTitles ?? buildRowTitles())[indexPath.section][indexPath.row]
        let format = dcfCellValueFormat(indexPath: indexPath)
        
        cell.configure(title: rowTitle, value$: value$, detail: "", indexPath: indexPath, delegate: self, valueFormat: format)
    }
    
    func userEnteredText(sender: UITextField, indexPath: IndexPath) {
        
        guard let validtext = sender.text else {
            return
        }
        
        guard let value = Double(validtext.filter("0123456789.".contains)) else {
            print("error converting entered text to number")
            return
        }
        
        guard let validValuation = valuation else {
            print("error assiging entered text: Controller doesn't have valuation")
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
                print("undefined indexpath \(indexPath) in DCFValuation.getValuationListItem")
            }
        case 1:
            // 'Key Statistics
            switch indexPath.row {
            case 0:
                validValuation.marketCap = value
            case 1:
                validValuation.beta = value
            default:
                print("undefined indexpath \(indexPath) in DCFValuation.returnValuationListItem")
            }
        case 2:
            // 'Income Statement S1 - Revenue
            validValuation.tRevenueActual![indexPath.row] = value
//            for i in 1..<tRevenueActual!.count {
//                if validValuation.tRevenueActual![i] != 0 {
//                    let result = (tRevenueActual![i-1] - tRevenueActual![i]) / tRevenueActual![i]
//                    revenueGrowth.insert(result, at: i-1)
//                }
//                for i in 0..<(revGrowthPredAdj?.count ?? 0) {
//                    revGrowthPredAdj?[i] = averageGrowthRate
//                }
//                if revenueGrowth.count > indexPath.row {
//                    return percentFormatter.string(from: revenueGrowth[indexPath.row] as NSNumber)
//                }
////                else { return nil }
//            }
        case 3:
            // 'Income Statement S2 - net income
            validValuation.netIncome![indexPath.row] = value
        case 4:
            // 'Income Statement S3 -
            switch indexPath.row {
            case 0:
                validValuation.expenseInterest = value
            case 1:
                validValuation.incomePreTax = value
            case 2:
                validValuation.expenseIncomeTax = value
            default:
                print("undefined indexpath \(indexPath) in DCFValuation.returnValuationListItem")
            }
        case 5:
            // 'balance sheet'
            switch indexPath.row {
            case 0:
                validValuation.debtST = value
            case 1:
                validValuation.debtLT = value
            default:
                print("undefined indexpath \(indexPath) in DCFValuation.returnValuationListItem")
            }
        case 6:
            // 'Cash Flow S1
            validValuation.tFCFo![indexPath.row] = value
        case 7:
            // 'Cash Flow S2
            validValuation.capExpend![indexPath.row] = value
        case 8:
            // 'Prediction S1
            validValuation.tRevenuePred![indexPath.row] = value
       case 9:
            // 'Prediction S2
            validValuation.revGrowthPred![indexPath.row] = value / 100.0
        case 10:
            // adjsuted predcited growth rate
            validValuation.revGrowthPredAdj![indexPath.row] = value / 100.0
        default:
            print("undefined indexpath \(indexPath) in DCFValuation.returnValuationListItem")
        }

        
    }

    
    internal func getCellValueText(value: Any?, indexPath: IndexPath) -> String? {
        
        var value$: String?

        if let validValue = value {
            if let date = validValue as? Date {
                value$ = dateFormatter.string(from: date)
            }
            else if let number = validValue as? Double {
                if [0,9,10].contains(indexPath.section) {
                    value$ = percentFormatter.string(from: number as NSNumber)
               }
                else {
                    if indexPath == IndexPath(item: 1, section: 1) {
                        // beta
                        value$ = numberFormatter.string(from: number as NSNumber)
                    } else {
                        value$ = currencyFormatter.string(from: number as NSNumber)
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
                print("undefined indexpath \(indexPath) in DCFValuation.returnValuationListItem")
            }
        case 1:
            // 'Key Statistics
            switch indexPath.row {
            case 0:
                return valuation.marketCap
            case 1:
                return valuation.beta
            default:
                print("undefined indexpath \(indexPath) in DCFValuation.returnValuationListItem")
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
                print("undefined indexpath \(indexPath) in DCFValuation.returnValuationListItem")
            }
        case 5:
            // 'balance sheet'
            switch indexPath.row {
            case 0:
                return valuation.debtST
            case 1:
                return valuation.debtLT
            default:
                print("undefined indexpath \(indexPath) in DCFValuation.returnValuationListItem")
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
            return valuation.revGrowthPredAdj![indexPath.row]
        default:
            print("undefined indexpath \(indexPath) in DCFValuation.returnValuationListItem")
        }
        
        return "error"

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
        let keyStatsTitles = ["Market cap", "beta"]
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
