//
//  DCFValuation+CoreDataClass.swift
//  TrendMyStocks
//
//  Created by aDav on 02/01/2021.
//
//

import UIKit
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
    
//    static func create(company: String, in managedObjectContext: NSManagedObjectContext) {
//        let newValuation = self.init(context: managedObjectContext)
//        newValuation.company = company
//
//        do {
//            try  managedObjectContext.save()
//        } catch {
//            let nserror = error as NSError
//            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
//        }
//    }
//        
    func save() {
        
        do {
            try  (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error in DCFValuation.save function \(nserror), \(nserror.userInfo)")
        }
    }
    
    func delete() {
       
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.delete(self)
 
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
    
    public func returnIValue() -> (Double?, [String]) {
        
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
        
        guard tRevenueActual != nil && capExpend != nil && netIncome != nil && tFCFo != nil else {
            return (nil, ["revenue, cap expend, net income or FCF data missing"])
        }
        
        var errors = [String]()
        let dataArrays = [tRevenueActual!, capExpend!, netIncome!, tFCFo!]
        let (cleanedData, error) = ValuationDataCleaner.cleanValuationData(dataArrays: dataArrays, method: .dcf)
        if let validError = error {
            errors.append(validError)
        }
        
        let revenueCleaned = cleanedData[0]
        let capExpendCleaned = cleanedData[1]
        let netIncomeCleaned = cleanedData[2]
        let fcfCleaned = cleanedData[3]
// 1
        var fcfToEquity = [Double]() // to accomodate missing figures from website harvesting
        var count = 0
        for annualFCF in fcfCleaned {
                fcfToEquity.append(annualFCF + (capExpendCleaned[count])) // capExpend entered as negative
            count += 1
        }
// 2
        var fcfToNetIncome = [Double]()
        count = 0
        for  fcfTE in fcfToEquity {
            fcfToNetIncome.append(fcfTE / netIncomeCleaned[count])
            count += 1
        }
// 3
        var netIncomeMargins = [Double]()
        count = 0
        for  income in netIncomeCleaned {
            netIncomeMargins.append(income / revenueCleaned[count])
            count += 1
        }
// 4 + 5
        predictedRevenue = tRevenuePred ?? []
        
        guard predictedRevenue.last != nil && predictedRevenue.last != nil && revGrowthPredAdj?.first != nil && revGrowthPredAdj?.last != nil else {
            errors.append("essential data missing")
            return (nil,errors)
        }
        let cleanedAdjGrowth = revGrowthPredAdj?.filter({ (element) -> Bool in
            if element == Double() { return false }
            else { return true }
        })
        
        let growth = [cleanedAdjGrowth?.first ?? revGrowthPred?.first, cleanedAdjGrowth?.last ?? revGrowthPred?.last]
        
        predictedRevenue.append(predictedRevenue.last! + predictedRevenue.last! * growth.first!!)
        predictedRevenue.append(predictedRevenue.last! + predictedRevenue.last! * growth.last!!)
// 6
        var incomeMarginValue = netIncomeMargins.min()
        if incomeMarginValue == nil {
            errors.append("can't calculate minimum net income margin. Value may be too high - use with caution!")
            incomeMarginValue = netIncomeMargins.mean()
            guard incomeMarginValue != nil else {
                errors.append("can't calculate any net income margin.")
                return (nil,errors)
            }
        }
        
        var predNetIncome = [Double]()
        for  revenue in predictedRevenue {
            predNetIncome.append(revenue * incomeMarginValue!)
        }
// 7
        // excluding negative FCF values - which would give a negative minimum value and negative intrinsic value
        
        var fcfToNetIncomeValue = fcfToNetIncome.min()
        if fcfToNetIncomeValue == nil {
            errors.append("can't find an essential minimum 'FCF / net income' value.")
            return (nil,errors)
        }
        else if (fcfToNetIncomeValue ?? 0.0) < 0 {
            errors.append("the minimum 'FCF / net income' value is negative; using mean value instead. Resulting value may be too high - use with caution!")
            fcfToNetIncomeValue = fcfToNetIncome.mean()
            guard fcfToNetIncomeValue ?? 0.0 > 0.0 else {
                errors.removeLast()
                errors.append("the minimum and mean 'FCF / net income' values are negative. The resulting price estimate is negative")
                return (nil,errors)
            }
        }
        
        var predFCF = [Double]()
        for  income in predNetIncome {
            predFCF.append(income * fcfToNetIncomeValue!)
        }
// 8

// 9
        var taxRate = 0.0
        if incomePreTax != 0.0 {
            taxRate = abs(expenseIncomeTax) / incomePreTax
        }
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
        if  let latestPredFCF = predFCF.last {
            let terminalValue = (latestPredFCF * (1 - ppGrowthRate)) / (wtAvgCostOfCapital - ppGrowthRate)
    // 18
            pvOfFutureCF.append(terminalValue / discountFactors.last!)
    // 19
            let todaysValue = pvOfFutureCF.compactMap{ $0 }.reduce(0, +)
    // 20
            var fairValue: Double?
            if sharesOutstanding > 0 {
                fairValue = todaysValue / sharesOutstanding
            }
            
            return (fairValue,errors)
        }
        errors.append("data gaps - can't calculate last predicted FCF")
        return (nil, errors)
    }
    
}
