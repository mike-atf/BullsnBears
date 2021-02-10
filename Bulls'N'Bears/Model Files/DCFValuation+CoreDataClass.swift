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
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "no moc available - can't save valuation")
            return
        }
        do {
            try  context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error in DCFValuation.save function \(nserror), \(nserror.userInfo)")
        }
    }
    
    func delete() {
       
        managedObjectContext?.delete(self)
 
        do {
            try managedObjectContext?.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    func getDataFromR1Valuation(r1Valuation: Rule1Valuation?) {
        
        guard let valuation = r1Valuation else {
            return
        }
        
        var count = 0
        for sales in valuation.revenue ?? [] {
            self.tRevenueActual?.insert(sales, at: count)
            count += 1
        }
                
        count = 0
        for sales in valuation.opcs ?? [] {
            self.tFCFo?.insert(sales, at: count)
            count += 1
        }
    }
    
    public func returnIValue() -> (Double?, String?) {
        
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
        
// stop crashes on lading when data has been corrupted
        guard capExpend?.count ?? 0 == 4 else {
            capExpend = [Double(), Double(), Double(), Double()]
            save()
            return (nil,"not enough cap. expend. data")
        }
        guard tRevenueActual?.count == 4 else {
            tRevenueActual = [Double(), Double(), Double(), Double()]
            save()
            return (nil,"not enough revenue data")
        }
        guard netIncome?.count ?? 0 == 4 else {
            netIncome = [Double(), Double(), Double(), Double()]
            save()
            return (nil,"not enough net income data")
        }
        guard tFCFo?.count ?? 0 == 4 else {
            tFCFo = [Double(), Double(), Double(), Double()]
            save()
            return (nil,"not enough cash flow data")
        }
        guard tRevenuePred?.count ?? 0 == 2 else {
            tRevenuePred = [Double(), Double()]
            save()
            return (nil,"not enough pred. revenue data")
        }
        guard revGrowthPred?.count ?? 0 == 2 else {
            revGrowthPred = [Double(), Double()]
            save()
            return (nil,"not enough pred. growth data")
        }
        guard revGrowthPredAdj?.count ?? 0 == 2 else {
            revGrowthPredAdj = [Double(), Double()]
            save()
            return (nil,"not enough adj. pred. growth data")
        }
//
        
        
// 1
        var fcfToEquity = [Double]()
        var count = 0
        for annualFCF in tFCFo ?? [] {
            if capExpend?.count ?? 0 > count {
                fcfToEquity.append(annualFCF + (capExpend![count])) // capExpend entered as negative
            }
            else { return (nil,"not enough cap. expend. data") } // error missing value
            count += 1
        }
// 2
        var fcfToNetIncome = [Double]()
        count = 0
        for  fcfTE in fcfToEquity {
            if netIncome?.count ?? 0 > count {
                fcfToNetIncome.append(fcfTE / netIncome![count])
            }
            else { return (nil,"not enough net income data") } // error missing value
            count += 1
        }
// 3
        var netIncomeMargins = [Double]()
        count = 0
        for  income in netIncome ?? [] {
            if tRevenueActual?.count ?? 0 > count {
                netIncomeMargins.append(income / tRevenueActual![count])
            }
            else { return (nil,"not enough revenue data") } // error missing value
            count += 1
        }
// 4 + 5
        predictedRevenue = tRevenuePred ?? []
        
        guard predictedRevenue.last != nil && predictedRevenue.last != nil && revGrowthPredAdj?.first != nil && revGrowthPredAdj?.last != nil else {
            return (nil,"essential data missing")
        }
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
        
        return (fairValue,nil)
    }
    
}
