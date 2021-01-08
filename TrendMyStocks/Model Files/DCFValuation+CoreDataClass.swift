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
        
    func save() {
        
        guard let context = managedObjectContext else {
            print("no moc available - can't save vauation")
            return
        }
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
    
    public func returnIValue() -> Double? {
        
        // 1 calculate 'FCF_to_equity' from fFCFo + capExpend
        // 2 calculate 'FCF / netIncome[]' from FCF_t_e / netIncome
        // 3 calculate netIncomeMargins[] from netIncome[] / tRevenue[]
        // 4 calculate predRevenue+3 from predRevenue+2 + predRevenue+2 * adjGrowthRate1
        // 5 calculate tRevenue+4 from predRevenue+3 + predRevenue+3 * adjGrowthRate2
        // 6 calculate predNetIncome[+1-4] from predRevenue[1-4] * min(incomeMargins[])
        // 7 calculate predFCF[+1-4] from predNetIncome[+1-4] * min('FCF / netIncome[]')
        
        // 8 calculate totalDebtRate from interestExpense / (debtST + debtLT)
        // 9 calculate taxRate from taxExpense / preTaxIncome
        // 10 calculate totalCompValue from marketCap + (debtST + debtLT)
        // 11 calculate totalDebtRate from (debtST + debtLT) / totalCompValue
        // 12 CostOfDebt from totalDebtRate * (1 - taxRate)
        // 13 capAssetPrice from usTreasuryBR + beta * (ltMarketReturnRate - usTreasuryBR)
        // 14 calculate wtAvgCostOfCapital from debtRate * costOfDebt + (1 - totalDebtRate) * capAssetPrice
        // 15 calculate discountFactors[+1-4] from (1+wtAvgCostOfCapital)^yearInFuture
        // 16 calculate PVofFutureCF[+1-4] from predFCF[+1-4] / discountFactors[]
        // 17 'terminalValue' from (predFCF[].last * (1 - perpetGrowth)) / (wtAvgCostOfCapital - perpetGrowth)
        // 18 last PVofFutureCF[5] from 'terminalValue' / discountFactors[].last (not 5!)
        // 19 'todaysValue' = sum(PVofFutureCF[+1-5])
        // 20 fairValue = 'todaysValue' / sharesOutstanding (drop last three!)
        
// 1
        var fcfToEquity = [Double]()
        var count = 0
        for annualFCF in tFCFo ?? [] {
            fcfToEquity.append(annualFCF - (capExpend![count])) // capExpend entered as positive
            count += 1
        }
// 2
        var fcfToNetIncome = [Double]()
        count = 0
        for  fcfTE in fcfToEquity {
            fcfToNetIncome.append(fcfTE / netIncome![count])
            count += 1
        }
// 3
        var netIncomeMargins = [Double]()
        count = 0
        for  income in netIncome ?? [] {
            netIncomeMargins.append(income / tRevenueActual![count])
            count += 1
        }
// 4 + 5
        predictedRevenue = tRevenuePred ?? []
        predictedRevenue.append(predictedRevenue.last! + predictedRevenue.last! * revGrowthPredAdj!.first!)
        predictedRevenue.append(predictedRevenue.last! + predictedRevenue.last! * revGrowthPredAdj!.last!)
// 6
        var predNetIncome = [Double]()
        count = 0
        for  revenue in predictedRevenue {
            predNetIncome.append(revenue * netIncomeMargins.min()!)
            count += 1
        }
// 7
        var predFCF = [Double]()
        count = 0
        for  income in predNetIncome {
            predFCF.append(income * fcfToNetIncome.min()!)
            count += 1
        }
// 8
//        let totalDebtRate = expenseInterest / (debtST + debtLT)
// 9
        let taxRate = expenseIncomeTax / incomePreTax
// 10
        let totalCompanyValue = marketCap + (debtST + debtLT)
// 11
        let totalDebtToCompanyValue = (debtST + debtLT) / totalCompanyValue
// 12
        let costOfDebt = totalDebt * (1-taxRate)
// 13
        let capAssetPrice = (UserDefaults.standard.value(forKey: "10YUSTreasuryBondRate") as! Double) + beta * (UserDefaults.standard.value(forKey: "LongTermMarketReturn") as! Double - (UserDefaults.standard.value(forKey: "10YUSTreasuryBondRate") as! Double))
// 14
        let wtAvgCostOfCapital = totalDebtToCompanyValue * costOfDebt + (1-totalDebtToCompanyValue) * capAssetPrice
// 15
        var discountFactors = [Double]()
        for i in 1..<5 {
            let factor = pow((1+wtAvgCostOfCapital), Double(i))
            discountFactors.append(factor)
        }
// 16
        var pvOfFutureCF = [Double]()
        count = 0
        for fcf in predFCF {
            pvOfFutureCF.append(fcf / discountFactors[count])
            count += 1
        }
// 17
        let ppGrowthRate = UserDefaults.standard.value(forKey: "PerpetualGrowthRate") as! Double
        let terminalValue = (predFCF.last! * (1 - ppGrowthRate)) / (wtAvgCostOfCapital - ppGrowthRate)
// 18
        pvOfFutureCF.append(terminalValue / discountFactors.last!)
// 19
        let todaysValue = pvOfFutureCF.reduce(0, +)
// 20
        var fairValue: Double?
        if sharesOutstanding > 0 {
            fairValue = todaysValue / sharesOutstanding
        }
        
        return fairValue
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
