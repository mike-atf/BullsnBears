//
//  DCFValuation+CoreDataClass.swift
//  TrendMyStocks
//
//  Created by aDav on 02/01/2021.
//
//

import Foundation
import CoreData

@objc(DCFValuation)
public class DCFValuation: NSManagedObject {
    
    let reviewYears = 4
    let predictionYears = 2
    
    var revenueGrowth = [Double]()
    var netIncomeMargins = [Double]()
    var fcfToEquity = [Double]()
    var fcfDivNetIncome = [Double]()
    var predictedRevenue = [Double]()
    var totalDebt = Double()
    var totalDebtRate = Double()
    var taxRate = Double()
    var marketCapAndTotalDebt = Double()
    var totalDebtDivMarketCap = Double()
    var weightedAvCostofCapital = Double()
    var costOfDebt = Double()
    var capitalAssetPrice = Double()
    var averageGrowthRate:Double {
        (revenueGrowth.reduce(0, +) + predictedRevenue.reduce(0, +)) / (Double(revenueGrowth.count) + Double(predictedRevenue.count))
    }
    
    let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        formatter.minimumIntegerDigits = 1
        return formatter
    }()

    
    override public func awakeFromInsert() {
        tFCFo = [Double]()
        capExpend = [Double]()
        netIncome = [Double]()
        tRevenueActual = [Double]()
        tRevenuePred = [Double]()
        revGrowthPred = [Double]()
        revGrowthPredAdj = [Double]()
        
        for _ in 0..<reviewYears {
            tRevenueActual?.append(Double())
            tFCFo?.append(Double())
            capExpend?.append(Double())
            netIncome?.append(Double())
        }
        
        for _ in 0..<predictionYears {
            revGrowthPred?.append(Double())
            tRevenuePred?.append(Double())
            revGrowthPredAdj?.append(Double())
        }
        
        expenseInterest = Double()
        debtST = Double()
        debtLT = Double()
        incomePreTax = Double()
        expenseIncomeTax = Double()
        marketCap = Double()
        beta = Double()
        sharesOutstanding = Double()
        
        company = String()
        creationDate = Date()
    }
    
    static func create(company: String, in managedObjectContext: NSManagedObjectContext) {
        let newValuation = self.init(context: managedObjectContext)
        newValuation.company = company

        do {
            try  managedObjectContext.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
        
    static func save(in context: NSManagedObjectContext) {
        
        do {
            try  context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error in SiteDetails.save function \(nserror), \(nserror.userInfo)")
        }

    }
    
    func delete(from managedObjectContext: NSManagedObjectContext) {
       
        managedObjectContext.delete(self)
 
        do {
            try managedObjectContext.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

    public func returnIvalue() -> String? {
        var intrinsicValue: Double?
        
        if let value = intrinsicValue {
            return currencyFormatter.string(from: value as NSNumber)
        }
        else {
            return nil
        }
    }
    
    public func returnValuationListItem(indexPath: IndexPath) -> Any {
        
        switch indexPath.section {
        case 0:
            // 'General
            switch indexPath.row {
            case 0:
                return creationDate!
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
                return marketCap
            case 1:
                return beta
            default:
                print("undefined indexpath \(indexPath) in DCFValuation.returnValuationListItem")
            }
        case 2:
            // 'Income Statement S1 - Revenue
            return tRevenueActual![indexPath.row]
        case 3:
            // 'Income Statement S2 - net income
            return netIncome![indexPath.row]
        case 4:
            // 'Income Statement S3 - 
            switch indexPath.row {
            case 0:
                return expenseInterest
            case 1:
                return incomePreTax
            case 2:
                return expenseIncomeTax
            default:
                print("undefined indexpath \(indexPath) in DCFValuation.returnValuationListItem")
            }
        case 5:
            // 'balance sheet'
            switch indexPath.row {
            case 0:
                return debtST
            case 1:
                return debtLT
            default:
                print("undefined indexpath \(indexPath) in DCFValuation.returnValuationListItem")
            }
        case 6:
            // 'Cash Flow S1
            return tFCFo![indexPath.row]
        case 7:
            // 'Cash Flow S2
        return capExpend![indexPath.row]
        case 8:
            // 'Prediction S1
            return tRevenuePred![indexPath.row]
       case 9:
            // 'Prediction S2
            return revGrowthPred![indexPath.row]
        case 10:
            // adjsuted predcited growth rate
            return revGrowthPredAdj![indexPath.row]
        default:
            print("undefined indexpath \(indexPath) in DCFValuation.returnValuationListItem")
        }
        
        return "error"
        
    }
    
    public func setValuationListItem(indexPath: IndexPath, text: String?) -> String? {
        
        guard let validtext = text else {
            return nil
        }
        
        guard let value = Double(validtext) else {
            print("error converting entered text to number")
            return nil
        }
        
        switch indexPath.section {
        case 0:
            // 'General
            switch indexPath.row {
            case 0:
                // date - do nothing
                return nil
            case 1:
                UserDefaults.standard.set(value, forKey: "10YUSTreasuryBondRate")
            case 2:
                UserDefaults.standard.set(value, forKey: "PerpetualGrowthRate")
            case 3:
                UserDefaults.standard.set(value, forKey: "LongTermMarketReturn")
            default:
                print("undefined indexpath \(indexPath) in DCFValuation.getValuationListItem")
            }
        case 1:
            // 'Key Statistics
            switch indexPath.row {
            case 0:
                marketCap = value
            case 1:
                beta = value
            default:
                print("undefined indexpath \(indexPath) in DCFValuation.returnValuationListItem")
            }
        case 2:
            // 'Income Statement S1 - Revenue
            tRevenueActual![indexPath.row] = value
            for i in 1..<tRevenueActual!.count {
                if tRevenueActual![i] != 0 {
                    let result = (tRevenueActual![i-1] - tRevenueActual![i]) / tRevenueActual![i]
                    revenueGrowth.insert(result, at: i-1)
                }
                for i in 0..<(revGrowthPredAdj?.count ?? 0) {
                    revGrowthPredAdj?[i] = averageGrowthRate
                }
                if revenueGrowth.count > indexPath.row {
                    return percentFormatter.string(from: revenueGrowth[indexPath.row] as NSNumber)
                }
//                else { return nil }
            }
        case 3:
            // 'Income Statement S2 - net income
            netIncome![indexPath.row] = value
        case 4:
            // 'Income Statement S3 -
            switch indexPath.row {
            case 0:
                expenseInterest = value
            case 1:
                incomePreTax = value
            case 2:
                expenseIncomeTax = value
            default:
                print("undefined indexpath \(indexPath) in DCFValuation.returnValuationListItem")
            }
        case 5:
            // 'balance sheet'
            switch indexPath.row {
            case 0:
                debtST = value
            case 1:
                debtLT = value
            default:
                print("undefined indexpath \(indexPath) in DCFValuation.returnValuationListItem")
            }
        case 6:
            // 'Cash Flow S1
            tFCFo![indexPath.row] = value
        case 7:
            // 'Cash Flow S2
            capExpend![indexPath.row] = value
        case 8:
            // 'Prediction S1
            tRevenuePred![indexPath.row] = value
       case 9:
            // 'Prediction S2
            revGrowthPred![indexPath.row] = value
        case 10:
            // adjsuted predcited growth rate
            revGrowthPredAdj![indexPath.row] = value
        default:
            print("undefined indexpath \(indexPath) in DCFValuation.returnValuationListItem")
        }

        return nil
    }


}
