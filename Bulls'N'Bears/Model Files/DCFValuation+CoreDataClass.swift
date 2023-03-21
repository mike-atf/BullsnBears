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
    var aalDebtRate = Double()
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
//        tFCFo = [Double]()
//        capExpend = [Double]()
//        netIncome = [Double]()
//        tRevenueActual = [Double]()
//        tRevenuePred = [Double]()
//        revGrowthPred = [Double]()
//        revGrowthPredAdj = [Double]()
//
//        for _ in 0..<reviewYears {
//            tRevenueActual?.append(Double())
//            tFCFo?.append(Double())
//            capExpend?.append(Double())
//            netIncome?.append(Double())
//        }
//
//        for _ in 0..<predictionYears {
//            revGrowthPred?.append(Double())
//            tRevenuePred?.append(Double())
//            revGrowthPredAdj?.append(Double())
//        }
//
//        expenseInterest = Double()
//        debtST = Double()
//        debtLT = Double()
//        incomePreTax = Double()
//        expenseIncomeTax = Double()
//        marketCap = Double()
//        beta = Double()
//        sharesOutstanding = Double()
//
//        company = String()
        creationDate = Date()
        
//        copyDataFromDCFaR1Valuations()
    }
    
    public func ageOfValuation() -> TimeInterval? {
        
        if let date = creationDate {
            return Date().timeIntervalSince(date)
        }
        
        return nil
    }
    
    func save() {
        
        do {
            try self.managedObjectContext?.save()
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
    
    /*
    func copyDataFromDCFaR1Valuations() {

        // own properties are set to [0,0,0,0] as default on insert!
        
        if (self.tRevenueActual ?? [Double]()).reduce(0,+) == 0 {
            if let valuation = share?.rule1Valuation  {
                if (valuation.revenue ?? [Double]()).reduce(0, +) != 0 {
                    self.tRevenueActual = valuation.revenue
                }
            }
        }

        if (self.tFCFo ?? [Double]()).reduce(0,+) == 0 {
            if let valuation = share?.rule1Valuation {
                if (valuation.opcs ?? [Double]()).reduce(0, +) != 0 {
                    self.tFCFo = valuation.opcs
                }
            }
        }
        
        if (self.capExpend ?? [Double]()).reduce(0,+) == 0 {
            if let valuation = share?.wbValuation {
                if (valuation.capExpend ?? [Double]()).reduce(0, +) != 0 {
                    self.capExpend = valuation.capExpend
                }
            }
        }
        
        if (self.netIncome ?? [Double]()).reduce(0,+) == 0 {
            if let valuation = share?.wbValuation {
                if (valuation.capExpend ?? [Double]()).reduce(0,+) != 0 {
                    self.capExpend = valuation.capExpend
                }
            }
        }

    }
    */
    
    /*
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
        
        copyDataFromDCFaR1Valuations()
        
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
        guard tRevenuePred?.count ?? 0 < 5 else {
            errors.append("too many DCFValuation.rRevenuePred data (\(tRevenuePred?.count ?? 0)")
            tRevenuePred?.removeAll()
            self.save()
            return (nil, errors)
        }
        predictedRevenue = tRevenuePred ?? []
        
        guard predictedRevenue.first != nil && predictedRevenue.last != nil && revGrowthPredAdj?.first != nil && revGrowthPredAdj?.last != nil else {
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
        let totalCompanyValue = marketCap + (debtLT + debtST) // ltDebt + stDebt
// 11
        let totalDebtToCompanyValue = (debtLT + debtST) / totalCompanyValue
// 12
        let costOfDebt = (debtLT + debtST) * (1-taxRate)
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
            let terminalValue = (latestPredFCF * (1 - ppGrowthRate)) / (wtAvgCostOfCapital * ppGrowthRate)
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
    */
    
    public func returnIValueNew() -> (Double?, [String]) {
        
        // pre-conditions - ONE NEEDS TO APPLY:
        // 1. DOESN'T PAY DIVIDENDS, OR ONLY VERY LITTLE COMPARED TO WHAT IT COULD
        // 2. FCF ALIGNS WITH PROFITABILITY: net income (alt:  ROI, ROA, ROE, Gross profit margin)
        // 3. INVESTOR IS TAKING A CONTROL PERSPECTIVE:  investment controlling not only encompasses controlling activities but also can include areas from compliance to performance review. Actively review and monitor the companies invested in
        
        // 1 calculate 'FCF_to_equity' from opCashFlow - capExpend or use FCF from Yahoo
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
        
        
        // Mark: - 0 - prepare required parameters
        guard let niDV = share?.income_statement?.netIncome.datedValues(dateOrder: .ascending) else {
            return (nil,["missing netIncome in DCF fair price"])
        }
        
        var fcfDV = share?.cash_flow?.freeCashFlow.datedValues(dateOrder: .ascending) ?? [DatedValue]()
        
        var harmonizedArrays = [[DatedValue]]()
        
        if fcfDV.count < 4 {
            // if fcf not available use opFC - capEx + netBorrowings as approximation
            // 'net borrowings' = MT: Debt Issuance/Retirement Net - Total
            guard let capExDV = share?.cash_flow?.capExNegative(dateOrder: .ascending) else {
                return (nil,["missing fcf and capEx in DCF fair price"])
            }
            guard let ocfDV = share?.cash_flow?.opCashFlow.datedValues(dateOrder: .ascending) else {
                return (nil,["missing fcf and ocf in DCF fair price"])
            }
            guard let netBorrowing = share?.cash_flow?.netBorrowings.datedValues(dateOrder: .ascending) else {
                return (nil,["missing fcf and netBorrowing in DCF fair price"])
            }
            
            let fcfArrays = ValuationDataCleaner.harmonizeDatedValues(arrays: [capExDV, ocfDV,netBorrowing]) ?? [[DatedValue]]()
            
            fcfDV = [DatedValue]()
            for i in 0..<capExDV.count {
                let fcfValue = fcfArrays[1][i].value + fcfArrays[0][i].value + fcfArrays[2][i].value
                fcfDV.append(DatedValue(date: capExDV[i].date, value: fcfValue))
            }
        }
        
        harmonizedArrays = ValuationDataCleaner.harmonizeDatedValues(arrays: [niDV, fcfDV]) ?? [[DatedValue]]()
        
        guard harmonizedArrays.count == 2 else {
            return (nil, ["revenue, cap expend, net income or FCF data harmonisation failed"])
        }
        
        // MARK: - 1 check alignment fo FCFe to netIncome
        let netIncomeDV = harmonizedArrays[0]
        fcfDV = harmonizedArrays[1]

        var fcfToNetincome = [Double]()
        for i in 0..<fcfDV.count {
            var alignment = 0.0
            if netIncomeDV[i].value != 0 {
                alignment = fcfDV[i].value / netIncomeDV[i].value
            }
            fcfToNetincome.append(alignment)
        }
        
        var errors = [String]()
        
        if let correlation = Calculator.correlation(xArray: fcfDV.compactMap{ $0.value }, yArray: netIncomeDV.compactMap{ $0.value })?.r2() {
            if correlation < 0.7 {
                let r2 = numberFormatter2Decimals.string(from: correlation as NSNumber)!
                errors.append("Low correlation \(r2) between net income and free cash flow possibly means company not suitable for DCf intrinsic value calculation")
            }
        }
        
        if let dividenPayoutRatio = share?.key_stats?.dividendPayoutRatio.valuesOnly(dateOrdered: .ascending)?.first {
            if dividenPayoutRatio > 0.5 {
                let pr = numberFormatter2Decimals.string(from: dividenPayoutRatio as NSNumber)!
                errors.append("Dividend payout ratio is  \(pr). Company may not suitable for DCf intrinsic value calculation")
            }
        }
        
        // MARK: - 2 calculate net income for the next four years, either directly or via Revenu and net income margins
        
        // A take past net income growth and user adjusted/next years growth rate
        var predictedGrowth = [DatedValue]()
        
        let pastNetIncomeGrowth = netIncomeDV.compactMap{ $0.value }.growthRates(dateOrder: .ascending)
        
        let predictedGrowthNextYear = share?.analysis?.adjFutureGrowthRate.datedValues(dateOrder: .ascending)?.first ?? share?.analysis?.future_growthNextYear.datedValues(dateOrder: .ascending)?.first
        if predictedGrowthNextYear == nil {
            if let latestPastRate = pastNetIncomeGrowth?.first {
                let nextYear = Date().addingTimeInterval(365*254*3600)
                let endOfNextYear = DatesManager.endOfYear(of: nextYear)
                predictedGrowth = [DatedValue(date: endOfNextYear, value: latestPastRate)]
            }
        } else {
            predictedGrowth = [predictedGrowthNextYear!]
        }
        
        // for years 2-5 take analysts predictions or the mean rate for next year
        if let analyst5YearGrowthPredictions = share?.analysis?.future_growthNext5pa.datedValues(dateOrder: .ascending) {
            predictedGrowth.append(contentsOf: analyst5YearGrowthPredictions)
        }
        
        if predictedGrowth.count < 5 {
            for i in predictedGrowth.count..<5 {
                let futureDate = Date().addingTimeInterval(Double(i) * 365 * 24 * 3600)
                let eoy = DatesManager.endOfYear(of: futureDate)
                if predictedGrowthNextYear != nil {
                    let growthDV = DatedValue(date: eoy, value: predictedGrowthNextYear!.value)
                    predictedGrowth.append(growthDV)
                }
                else if pastNetIncomeGrowth?.mean() != nil {
                    let growthDV = DatedValue(date: eoy, value: pastNetIncomeGrowth!.mean()!)
                    predictedGrowth.append(growthDV)
                } else if predictedGrowth.count > 1 {
                    let growthDV = DatedValue(date: eoy, value: predictedGrowth.first!.value)
                    predictedGrowth.append(growthDV)
                }
            }
        }
        
        guard predictedGrowth.count == 5 else {
            return (nil, ["insufficient future growth estimates"])
        }
        
        var predictedNetIncomes = [DatedValue]()
        var latestNetIncome = netIncomeDV.compactMap{ $0.value }.last!
        for i in 0..<4 {
            let futureDate = DatesManager.endOfYear(of: Date().addingTimeInterval(Double(i) * 365 * 24 * 3600))
            let futureNetIncome = latestNetIncome * (1.0+predictedGrowth[i].value)
            predictedNetIncomes.append(DatedValue(date: futureDate, value: futureNetIncome))
            latestNetIncome *= (1+predictedGrowth[i].value)
        }
        
        // excluding negative FCF values - which would give a negative minimum value and negative intrinsic value
        fcfToNetincome = fcfToNetincome.filter({ d in
            if d < 0 { return false }
            else { return true }
        })
        
        guard var fcfToNetIncomeMinimum = fcfToNetincome.min() else {
            errors.append("can't find an essential minimum 'FCF / net income' value.")
            return (nil,errors)
        }
        
        if fcfToNetIncomeMinimum < 0  {
            errors.append("the minimum 'FCF / net income' ratio is negative; using mean value instead. Resulting value is less conservative")

            fcfToNetIncomeMinimum = fcfToNetincome.mean() ?? 0
            guard fcfToNetIncomeMinimum > 0.0 else {
                errors.removeLast()
                errors.append("the minimum and mean 'FCF / net income' ratios are negative. The resulting price estimate is negative")
                return (nil,errors)
            }
        }
        
        // calculating future free cash flows estimates via smallest or mean fcf/net income ratio
        var predictedFCF = [DatedValue]()
        for i in 0..<predictedNetIncomes.count {
            let futureFCF = predictedNetIncomes[i].value * fcfToNetIncomeMinimum
            predictedFCF.append(DatedValue(date: predictedNetIncomes[i].date, value: futureFCF))
        }
        
        // MARK: - calculating WACC
        guard let incomePreTax = share?.income_statement?.preTaxIncome.valuesOnly(dateOrdered: .ascending,withoutZeroes: true)?.last else {
            errors.append("income pre tax data missing")
            return (nil,errors)
        }
        
        let incomeTax = share?.income_statement?.incomeTax.valuesOnly(dateOrdered: .ascending)?.last ?? 0.0
        if incomeTax == 0.0 {
            errors.append("income tax data may be missing or is 0")
        }
        
        var taxRate = 0.0
        if incomePreTax != 0.0 {
            taxRate = abs(incomeTax) / incomePreTax
        }
        
        guard let mCap = share?.key_stats?.marketCap.valuesOnly(dateOrdered: .ascending,withoutZeroes: true, includeThisYear: true)?.last else {
            errors.append("market cap data missing")
            return (nil,errors)
        }
        guard let debt_lt = share?.balance_sheet?.debt_longTerm.valuesOnly(dateOrdered: .ascending, includeThisYear: true)?.last else {
            errors.append("long term debt data missing")
            return (nil,errors)
        }
        
        guard let debt_st = share?.balance_sheet?.debt_shortTerm.valuesOnly(dateOrdered: .ascending, includeThisYear: true)?.last else {
            errors.append("short term debt data missing")
            return (nil,errors)
        }

        guard let interestExpense = share?.income_statement?.interestExpense.valuesOnly(dateOrdered: .ascending, includeThisYear: true)?.last else {
            errors.append("interest expense data missing")
            return (nil,errors)
        }
        
        guard let beta = share?.key_stats?.beta.valuesOnly(dateOrdered: .ascending,withoutZeroes: true, includeThisYear: true)?.last else {
            errors.append("missing beta value")
            return (nil,errors)
        }

        let totalCompanyValue = mCap + (debt_lt + debt_st)
        let totalDebtToCompanyValue = (debt_lt + debt_st) / totalCompanyValue
        let costOfDebt = (interestExpense / (debt_lt + debt_st)) * (1-taxRate)// 13
        let capAssetPrice = (UserDefaults.standard.value(forKey: "10YUSTreasuryBondRate") as! Double) + beta * (UserDefaults.standard.value(forKey: "LongTermMarketReturn") as! Double - (UserDefaults.standard.value(forKey: "10YUSTreasuryBondRate") as! Double))
        
        // wacc
        let wtAvgCostOfCapital = totalDebtToCompanyValue * costOfDebt + (1-totalDebtToCompanyValue) * capAssetPrice
        
        // calculating future years discount factors
        var discountFactors = [Double]()
        for i in 1..<5 {
            let factor = pow((1+wtAvgCostOfCapital), Double(i))
            discountFactors.append(factor)
        }

        // divide future FCF by discount factora
        var pvOfFutureCF = [Double]()
        for i in 0..<predictedFCF.count {
            pvOfFutureCF.append(predictedFCF[i].value / discountFactors[i])
        }
        
        let ppGrowthRate = UserDefaults.standard.value(forKey: "PerpetualGrowthRate") as! Double
        guard  let latestPredictedFCF = predictedFCF.last?.value else {
            errors.append("data gaps - can't calculate last predicted FCF")
            return (nil, errors)
        }
        let terminalValue = (latestPredictedFCF * (1 + ppGrowthRate)) / (wtAvgCostOfCapital - ppGrowthRate)

        // add discounted terminal value to estimated future FCF
        pvOfFutureCF.append(terminalValue / discountFactors.last!)

        //add up all future est. FCF
        let todaysValue = pvOfFutureCF.compactMap{ $0 }.reduce(0, +)
        var fairValue: Double?
                
        guard let outstandingShares = share?.key_stats?.sharesOutstanding.datedValues(dateOrder: .descending, includeThisYear: true).dropZeros()?.values().first else {
            errors.append("outstanding shares data missing")
            return (nil,errors)
        }
        
        if outstandingShares > 0 {
            fairValue = todaysValue / outstandingShares
        } else {
            errors.append("outstanding shares are 0!")
        }
        
        return (fairValue,errors)
    }

    func addIntrinsiceValueTrendAndSave(date: Date, price: Double) {
        
        var existingTrendDv = ivalueTrend.datedValues(dateOrder: .ascending, includeThisYear: true)
        
        if let latest = existingTrendDv?.last?.date {
            if date.timeIntervalSince(latest) > (365/12 * 24 * 3600) {
                existingTrendDv?.append((DatedValue(date: date, value: price)))
                ivalueTrend = existingTrendDv?.convertToData()
            }
        }
        else {
            ivalueTrend = [DatedValue(date: date, value: price)].convertToData()
        }

    }

}
