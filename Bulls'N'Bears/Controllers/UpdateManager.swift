//
//  UpdateManager.swift
//  Bulls'N'Bears
//
//  Created by aDav on 08/01/2023.
//

import UIKit
import CoreData

class UpdateManager {
    /*
    class func updateModelData(shares: [Share]?) {
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
                
        let oneYear: TimeInterval = 365*24*3600

        for share in shares ?? [] {
            
            var lastValDate = share.wbValuation?.share?.creationDate ?? share.rule1Valuation?.creationDate ?? Date().addingTimeInterval(-30*24*3600)
            var descendingEndOfYears = [Date]()
            var ascendingFutureYears = [Date]()
            let endOfThisYear = DatesManager.endOfYear(of: Date())
            for i in 0..<5 {
                ascendingFutureYears.append(endOfThisYear + Double(i)*oneYear)
            }
            for _ in 0..<10 {
                let endOfYear = DatesManager.endOfYear(of: lastValDate)
                descendingEndOfYears.append(endOfYear)
                lastValDate = lastValDate.addingTimeInterval(-oneYear)
            }

            let incomeStatement:Income_statement? = {
                NSEntityDescription.insertNewObject(forEntityName: "Income_statement", into: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext) as? Income_statement
            }()
//            let incomeStatement = Income_statement(context: context)
            let balanceSheet = Balance_sheet(context: context)
            let cashFlow = Cash_flow(context: context)
            let keyStats = Key_stats(context: context)
            let ratios = Ratios(context: context)
            let companyInfo = Company_Info(context: context)
            let analysis = Analysis(context: context)
            
            incomeStatement?.share = share
            incomeStatement?.revenue = createDVArray(array: share.wbValuation?.revenue, yearDates: descendingEndOfYears)
            incomeStatement?.netIncome = createDVArray(array: share.wbValuation?.netEarnings, yearDates: descendingEndOfYears)
            incomeStatement?.operatingIncome = createDVArray(array: share.wbValuation?.grossProfit, yearDates: descendingEndOfYears)
            incomeStatement?.rdExpense = createDVArray(array: share.wbValuation?.rAndDexpense, yearDates: descendingEndOfYears)
            incomeStatement?.sgaExpense = createDVArray(array: share.wbValuation?.sgaExpense, yearDates: descendingEndOfYears)
            incomeStatement?.eps_annual = createDVArray(array: share.wbValuation?.eps, yearDates: descendingEndOfYears)
            incomeStatement?.eps_quarter = share.wbValuation?.epsDatesq
            
            if let ipt = share.dcfValuation?.incomePreTax {
                if ipt != 0 {
                    incomeStatement?.preTaxIncome = createDVArray(array: [ipt], yearDates: descendingEndOfYears)
                }
            }
            if let tax = share.dcfValuation?.expenseIncomeTax {
                if tax != 0 {
                    incomeStatement?.incomeTax = createDVArray(array: [tax], yearDates: descendingEndOfYears)
                }
            }

            balanceSheet.share = share
            balanceSheet.debt_longTerm = createDVArray(array: share.wbValuation?.debtLT, yearDates: descendingEndOfYears)
            balanceSheet.sh_equity = createDVArray(array: share.wbValuation?.shareholdersEquity, yearDates: descendingEndOfYears)
            balanceSheet.ppe_net = createDVArray(array: share.wbValuation?.ppe, yearDates: descendingEndOfYears)
            balanceSheet.retained_earnings = createDVArray(array: share.wbValuation?.equityRepurchased, yearDates: descendingEndOfYears)
            if let debt = share.rule1Valuation?.debt {
                if debt != 0 {
                    balanceSheet.debt_total = createDVArray(array: [debt], yearDates: descendingEndOfYears)
                }
            }
            if let shorttermDebt = share.dcfValuation?.debtST {
                if shorttermDebt != 0.0 {
                    balanceSheet.debt_shortTerm = createDVArray(array: [shorttermDebt], yearDates: descendingEndOfYears)
                }}

            cashFlow.share = share
            cashFlow.capEx = createDVArray(array: share.dcfValuation?.capExpend, yearDates: descendingEndOfYears)
            cashFlow.opCashFlow = createDVArray(array: share.wbValuation?.opCashFlow, yearDates: descendingEndOfYears)
            
            keyStats.share  = share
            if let beta = share.dcfValuation?.beta {
                if beta != 0 {
                    keyStats.beta = createDVArray(array: [beta], yearDates: descendingEndOfYears)
                }
            }
            if let mcp = share.dcfValuation?.marketCap {
                if mcp != 0 {
                    keyStats.marketCap = createDVArray(array: [mcp], yearDates: descendingEndOfYears)
                }
            }
            if let so = share.dcfValuation?.sharesOutstanding {
                if so != 0 {
                    keyStats.sharesOutstanding = createDVArray(array: [so], yearDates: descendingEndOfYears)
                }
            }
            let so = share.divYieldCurrent
                if so != 0 {
                    keyStats.dividendYield = createDVArray(array: [so], yearDates: descendingEndOfYears)
                }
            if let iss = share.rule1Valuation?.insiderStocks {
                keyStats.insiderShares = createDVArray(array: [iss], yearDates: descendingEndOfYears)
            }
            if let isb = share.rule1Valuation?.insiderStockBuys {
                keyStats.insiderPurchases = createDVArray(array: [isb], yearDates: descendingEndOfYears)
            }
            if let issa = share.rule1Valuation?.insiderStockSells {
                keyStats.insiderSales = createDVArray(array: [issa], yearDates: descendingEndOfYears)
            }

            
            ratios.share = share
            ratios.bvps = createDVArray(array: share.wbValuation?.bvps, yearDates: descendingEndOfYears)
            ratios.pe_ratios = share.wbValuation?.perDates
            ratios.ocfPerShare = createDVArray(array: share.rule1Valuation?.opcs, yearDates: descendingEndOfYears)
            ratios.roi = createDVArray(array: share.rule1Valuation?.roic, yearDates: descendingEndOfYears)
            ratios.roe = createDVArray(array: share.wbValuation?.roe, yearDates: descendingEndOfYears)
            ratios.roa = createDVArray(array: share.wbValuation?.roa, yearDates: descendingEndOfYears)
            
            analysis.share = share
            if let dfp = share.rule1Valuation?.adjFuturePE {
                if dfp != 0.0 {
                    analysis.adjForwardPE = createDVArray(array: [dfp], yearDates: descendingEndOfYears)
                }
            }
            analysis.future_revenue = createDVArray(array: share.dcfValuation?.predictedRevenue, yearDates: ascendingFutureYears)
            analysis.future_revenueGrowthRate = createDVArray(array: share.dcfValuation?.revGrowthPred, yearDates: ascendingFutureYears)
            if let fgm = share.research?.futureGrowthMean {
                analysis.future_growthNextYear = createDVArray(array: [fgm], yearDates: ascendingFutureYears)
            }

            companyInfo.share = share
            companyInfo.businessDescription = share.research?.businessDescription
            companyInfo.sector = share.sector
            companyInfo.industry = share.industry
            if share.employees != 0.0 {
                companyInfo.employees = createDVArray(array: [share.employees], yearDates: descendingEndOfYears)
            }
            
            share.income_statement = incomeStatement
            share.balance_sheet = balanceSheet
            share.cash_flow = cashFlow
            share.key_stats = keyStats
            share.analysis = analysis
            share.ratios = ratios
            share.company_info = companyInfo
            
            share.save()

        }
    }
    */
    class func transferValuationTrendData(shares: [Share]?) {
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        for share in shares ?? [] {
            
            let dcfv = share.dcfValuation ?? DCFValuation(context: context)
            dcfv.share = share
            let r1v = share.rule1Valuation ?? Rule1Valuation(context: context)
            r1v.share = share
            let wbv = share.wbValuation ?? WBValuation(context: context)
            wbv.share = share
            
            dcfv.ivalueTrend = share.trend_DCFValue
            r1v.moatScoreTrend = share.trend_MoatScore
            r1v.stickerPriceTrend = share.trend_StickerPrice
            wbv.intrinsicValueTrend = share.trend_intrinsicValue
        }
        
        do {
            try context.save()
        } catch {
            ErrorController.addInternalError(errorLocation: #function, systemError: error)
        }
    }
    
    class func createDVArray(array: [Double]?, yearDates: [Date]) -> Data? {
        
        guard let validArray = array else { return nil }
        
        var datedValues = [DatedValue]()

        var i = 0
        for element in validArray {
            if yearDates.count > i {
                let datedValue = DatedValue(date: yearDates[i], value: element)
                datedValues.append(datedValue)
            }
            i += 1
        }

        return datedValues.convertToData()
        
    }
    
}
