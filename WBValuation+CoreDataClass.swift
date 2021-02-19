//
//  WBValuation+CoreDataClass.swift
//  Bulls'N'Bears
//
//  Created by aDav on 16/02/2021.
//
//

import Foundation
import CoreData

@objc(WBValuation)
public class WBValuation: NSManagedObject {
    
    override public func awakeFromInsert() {
        eps = [Double]()
        revenue = [Double]()
        grossProfit = [Double]()
        sgaExpense = [Double]()
        rAndDexpense = [Double]()
        interestExpense = [Double]()
        netEarnings = [Double]()
        roe = [Double]()
        capExpend = [Double]()
        debtLT = [Double]()
        shareholdersEquity = [Double]()
        roa = [Double]()
        ppe = [Double]()
        operatingIncome = [Double]()
        equityRepurchased = [Double]()
        date = Date()

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
            fatalError("Unresolved error in WBValuation.save function \(nserror), \(nserror.userInfo)")
        }
    }

    
    public func grossProfitMargins() -> ([Double], [String]?) {
        
        guard revenue != nil && grossProfit != nil else {
            return ([Double()], ["there are no revenue and gross profit data"])
        }
        
        let rawData = [revenue!, grossProfit!]
        
        let (cleanedData, error) = ValuationDataCleaner.cleanValuationData(dataArrays: rawData, method: .wb)
        
        var margins = [Double]()
        var errors: [String]?
        for i in 0..<cleanedData[0].count {
            margins.append(cleanedData[1][i] / cleanedData[0][i])
        }
        
        if let validError = error {
            errors = [validError]
        }
        return (margins, errors)
    }
    
    public func sgaProportion() -> ([Double], [String]?) {
        
        guard grossProfit != nil && sgaExpense != nil else {
            return ([Double()], ["there are no gross profit and SGA expense data"])
        }
        
        let rawData = [grossProfit!, sgaExpense!]
        
        let (cleanedData, error) = ValuationDataCleaner.cleanValuationData(dataArrays: rawData, method: .wb)
        
        guard cleanedData[0].count == cleanedData[1].count else {
            return ([Double()], ["insufficient gross profit and SGA expense data"])
        }
        
        var margins = [Double]()
        var errorList: [String]?
        for i in 0..<cleanedData[0].count {
            margins.append(cleanedData[1][i] / cleanedData[0][i])
        }
        
        if let validError = error {
            errorList = [validError]
        }

        
        return (margins, errorList)

    }
    
    public func ivalue() -> (Double?, [String] ){
        
         guard let stock = stocks.filter({ (stock) -> Bool in
            stock.symbol == company
         }).first else {
            return (nil, ["no stock data available for \(company)"])
         }
        
        guard let price = stock.dailyPrices.last?.close else {
            return (nil, ["no current price available for \(company)"])
        }
              
        
        guard peRatio > 0 else {
            return (nil, ["P/E ratio for \(company) is negative \(peRatio)"])
        }
        
        var errors = [String]()
        var epsGrowthRates = eps?.growthRates()
        if epsGrowthRates == nil {
            errors.append("can't calculate EPS growth rates; trying revenue growth rates instead")
            epsGrowthRates = revenue?.growthRates()
            if epsGrowthRates == nil {
                errors.append("can't calculate revenue growth rates either")
                return (nil, errors)
            }
        }
        
        guard let meanEPSGrowth = epsGrowthRates?.mean() else {
            errors.append("can't calculate mean EPS growth rate")
            return (nil, errors)
        }
        
        let futureEPS = Calculator.futureValue(present: eps!.first!, growth: meanEPSGrowth, years: 10.0)
        
        let discountRate = UserDefaults.standard.value(forKey: UserDefaultTerms().longTermCoporateInterestRate) as? Double ?? 0.021
        let discountedCurrentEPS = Calculator.presentValue(growth: discountRate, years: 10.0, endValue: futureEPS)
        let dcCurrentEPSReturn = discountedCurrentEPS / price
        let ivalue = dcCurrentEPSReturn * peRatio
        
        return (ivalue, errors)
        
    }

}
