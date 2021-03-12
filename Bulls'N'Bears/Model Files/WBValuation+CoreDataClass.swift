//
//  WBValuation+CoreDataClass.swift
//  Bulls'N'Bears
//
//  Created by aDav on 16/02/2021.
//
//

import UIKit
import CoreData

@objc(WBValuation)
public class WBValuation: NSManagedObject {
    
    override public func awakeFromInsert() {
        
        opCashFlow = [Double]()
        bvps = [Double]()
        avAnStockPrice = [Double]()
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
        
        // when deleting a WBValuation this doe NOT delete related UserEvaluations
        // these are linked to a company (symbol) as well as wbValuation parameters
        // when (re-)creating a WBValuation check whether there are any old userEvaluations
        // and if so re-add the relationships to this WBValuation via parameters
        if let ratings = WBValuationController.allUserRatings(for: company) {
            if ratings.count > 0 {
                let set = NSSet(array: ratings)
                addToUserEvaluations(set)
            }
        }

    }
    
    func peRatiosWithDates() -> [DatedValue]? {
        
        if let valid = perDates {
            do {
                if let dictionary = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(valid) as? [Date: Double] {
                    var datedValues = [DatedValue]()
                    for element in dictionary {
                        datedValues.append(DatedValue(date: element.key, value: element.value))
                    }
                    return datedValues
                }
            } catch let error {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error retrieving stored P/E ratio historical data")
            }
        }
        
        return nil
    }
    
    func peRatios() -> [Double]? {
       
        if let valid = perDates {
            do {
                if let dictionary = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(valid) as? [Date: Double] {
                    var datedValues = [DatedValue]()
                    for element in dictionary {
                        datedValues.append(DatedValue(date: element.key, value: element.value))
                    }
                    let sorted = datedValues.sorted { (e0, e1) -> Bool in
                        if e0.date > e1.date { return true }
                        else { return false }
                    }
                    return sorted.compactMap{ $0.value }
                }
            } catch let error {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error retrieving stored P/E ratio historical data")
            }
        }
        
        return nil
    }
    
    func savePERWithDateArray(datesValuesArray: [DatedValue]?) {
        
        guard let datedValues = datesValuesArray else { return }
        
        var array = [Date: Double]()

        for element in datedValues {
            array[element.date] = element.value
        }

        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: array, requiringSecureCoding: false)
            perDates = data
            save()
        } catch let error {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error storing stored P/E ratio historical data")
        }
        
    }
    
    func minMeanMaxPER(from:Date, to: Date?=nil) -> (Double, Double, Double)? {
        
        guard let datedValues = peRatiosWithDates() else {
            return nil
        }
        
        let end = to ?? Date()
        
        let inDateRange = datedValues.filter { (element) -> Bool in
            if element.date < from { return false }
            else if element.date > end { return false }
            return true
        }
        
        let valuesInDateRange = inDateRange.compactMap { $0.value }
        if let mean = valuesInDateRange.mean() {
            if let min = valuesInDateRange.min() {
                if let max = valuesInDateRange.max() {
                    return (min, mean, max)
                }
            }
        }
        
        return nil
        
    }
    
    func save() {
        
       do {
            try  (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error in WBValuation.save function \(nserror), \(nserror.userInfo)")
        }
    }

    
    public func grossProfitMargins() -> ([Double], [String]?) {
        
        guard revenue != nil && grossProfit != nil else {
            return ([Double()], ["there are no revenue and/or gross profit data"])
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
            return ([Double()], ["there are no gross profit and/or SGA expense data"])
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
    
    /// returns arary of sums of sahreholdersEquity + equityRepurchased
    public func adjustedEquity() -> [Double] {
        
        var sums = [Double]()
        var count = 0

        if shareholdersEquity?.count ?? 0 > 0 {
        
            for element in shareholdersEquity ?? [] {
                if (equityRepurchased?.count ?? 0) >= count {
                    sums.append(element + equityRepurchased![count])
                }
                
                count += 1
            }
        }
        else {
            sums = equityRepurchased ?? [Double]()
        }
        
        return sums
    }
    
    /// returns porportions of array 2 / array 1 elements
    public func proportions(array1: [Double]?, array2: [Double]?) -> ([Double], [String]?) {
        
        guard array1 != nil && array2 != nil else {
            return ([Double()], ["missing data"])
        }
        
        let rawData = [array1!, array2!]
        
        let (cleanedData, error) = ValuationDataCleaner.cleanValuationData(dataArrays: rawData, method: .wb)
        
        guard cleanedData[0].count == cleanedData[1].count else {
            return ([Double()], ["insufficient data"])
        }
        
        var proportions = [Double]()
        var errorList: [String]?
        for i in 0..<cleanedData[0].count {
            proportions.append(cleanedData[1][i] / cleanedData[0][i])
        }
        
        if let validError = error {
            errorList = [validError]
        }
        return (proportions, errorList)

    }
    
    public func rAndDProportion() -> ([Double], [String]?) {
        
        guard grossProfit != nil && rAndDexpense != nil else {
            return ([Double()], ["there are no gross profit and/or R&D expense data"])
        }
        
        let rawData = [grossProfit!, rAndDexpense!]
        
        let (cleanedData, error) = ValuationDataCleaner.cleanValuationData(dataArrays: rawData, method: .wb)
        
        guard cleanedData[0].count == cleanedData[1].count else {
            return ([Double()], ["insufficient gross profit and R&D expense data"])
        }
        
        var proportions = [Double]()
        var errorList: [String]?
        for i in 0..<cleanedData[0].count {
            proportions.append(cleanedData[1][i] / cleanedData[0][i])
        }
        
        if let validError = error {
            errorList = [validError]
        }
        return (proportions, errorList)

    }
    
    public func netIncomeProportion() -> ([Double], [String]?) {
        
        guard revenue != nil && netEarnings != nil else {
            return ([Double()], ["there are no revenue and/or net income data"])
        }
        
        let rawData = [revenue!, netEarnings!]
        
        let (cleanedData, error) = ValuationDataCleaner.cleanValuationData(dataArrays: rawData, method: .wb)
        
        guard cleanedData[0].count == cleanedData[1].count else {
            return ([Double()], ["insufficient revenue and net income data"])
        }
        
        var proportions = [Double]()
        var errorList: [String]?
        for i in 0..<cleanedData[0].count {
            proportions.append(cleanedData[1][i] / cleanedData[0][i])
        }
        
        if let validError = error {
            errorList = [validError]
        }
        return (proportions, errorList)
    }
    
    public func longtermDebtProportion() -> ([Double], [String]?) {
        
        guard debtLT != nil && netEarnings != nil else {
            return ([Double()], ["there are no net income and/or long-term debt data"])
        }
        
        let rawData = [netEarnings!, debtLT!]
        
        let (cleanedData, error) = ValuationDataCleaner.cleanValuationData(dataArrays: rawData, method: .wb)
        
        guard cleanedData[0].count == cleanedData[1].count else {
            return ([Double()], ["insufficient net income and long-term debt data"])
        }
        
        var proportions = [Double]()
        var errorList: [String]?
        for i in 0..<cleanedData[0].count {
            if cleanedData[0][i] > 0 {
                proportions.append(cleanedData[1][i] / cleanedData[0][i])
            }
            else {
                proportions.append(Double())
                if cleanedData[1][i] > 0 {
                    errorList = ["company made losses and had long term debt!"]
                }
            }
        }
        
        if let validError = error {
            if errorList == nil {
                errorList = [String]()
            }
            errorList!.append(validError)
        }
        return (proportions, errorList)

    }
    
    func valuesSummaryScores() -> RatingCircleData? { // [min,score,max]
        
        let peRatioWeight = 1.5
        let retEarningsGrowthWeight = 1.3
        let epsGrowthWeight = 1.0
        let netIncomeDivProfitWeight = 1.0
        let capExpendDivEarningsWeight = 1.1
        let profitMarginWeight = 1.0
        let ltDebtDivIncomeWeight = 1.0
        let opCashFlowGrowthWeight = 1.1
        let ltDebtDivadjEq = 0.75
        let sgaDivRevenue = 0.75
        let radDivRevenue = 0.75
        
        var allFactors = [Double]()
        var allWeights = [Double]()
        let emaPeriods = (UserDefaults.standard.value(forKey: userDefaultTerms.emaPeriodAnnualData) as? Int) ?? 7
        
        allFactors.append(perValueFactor() * peRatioWeight)
        allWeights.append(peRatioWeight)
        
        if let valid = valueFactor(values1: equityRepurchased, values2: nil, maxCutOff: 1, emaPeriod: emaPeriods) {
            allFactors.append(valid * retEarningsGrowthWeight)
            allWeights.append(retEarningsGrowthWeight)
        }
        if let valid = valueFactor(values1: eps, values2: nil, maxCutOff: 1, emaPeriod: emaPeriods) {
            allFactors.append(valid * epsGrowthWeight)
            allWeights.append(epsGrowthWeight)
        }
        if let valid = valueFactor(values1: revenue, values2: netEarnings, maxCutOff: 1, emaPeriod: emaPeriods) {
            allFactors.append(valid * netIncomeDivProfitWeight)
            allWeights.append(netIncomeDivProfitWeight)
        }
        if let valid = valueFactor(values1: revenue, values2: grossProfit, maxCutOff: 1, emaPeriod: emaPeriods) {
            allFactors.append(valid * profitMarginWeight)
            allWeights.append(profitMarginWeight)
        }
        if let sumDiv = netEarnings?.reduce(0, +) {
            // use 10 y sums / averages, not ema according to Book Ch 51
            if let sumDenom = capExpend?.reduce(0, +) {
                let tenYAverages = abs(sumDenom / sumDiv)
                let maxCutOff = 0.5
                let factor = (tenYAverages < maxCutOff) ? ((maxCutOff - tenYAverages) / maxCutOff) : 0
                allFactors.append(factor * capExpendDivEarningsWeight)
                allWeights.append(capExpendDivEarningsWeight)
            }
        }
        if let valid = valueFactor(values1: opCashFlow, values2: nil, maxCutOff: 1, emaPeriod: emaPeriods) {
            allFactors.append(valid * opCashFlowGrowthWeight)
            allWeights.append(opCashFlowGrowthWeight)
        }
        if let valid = inverseValueFactor(values1: netEarnings, values2: debtLT, maxCutOff: 3, emaPeriod: emaPeriods) {
            allFactors.append(valid * ltDebtDivIncomeWeight)
            allWeights.append(ltDebtDivIncomeWeight)
        }
        if let valid = inverseValueFactor(values1: adjustedEquity(), values2: debtLT, maxCutOff: 1, emaPeriod: emaPeriods) {
            allFactors.append(valid * ltDebtDivadjEq)
            allWeights.append(ltDebtDivadjEq)
        }
        if let valid = valueFactor(values1: revenue, values2: sgaExpense, maxCutOff: 0.4, emaPeriod: emaPeriods) {
            allFactors.append(valid * sgaDivRevenue)
            allWeights.append(sgaDivRevenue)
        }
        if let valid = valueFactor(values1: revenue, values2: rAndDexpense, maxCutOff: 1, emaPeriod: emaPeriods) {
            allFactors.append(valid * radDivRevenue)
            allWeights.append(radDivRevenue)
        }
        
        let scoreSum = allFactors.reduce(0, +)
        let maximum = allWeights.reduce(0, +)
        
        return RatingCircleData(rating: scoreSum, maximum: maximum, minimum: 0, symbol: .dollar)
//        return [0, scoreSum , maximum]
    }
    
    func userEvaluationScore() -> RatingCircleData? {
        
        guard userEvaluations?.count ?? 0 > 0 else {
            return nil
        }
        
        var userSummaryScore: Double = 0
        var maximumScoreSum: Double = 0
        
        for element in userEvaluations ?? [] {
            if let evaluation = element as? UserEvaluation {
                if let valid = evaluation.userRating() {
                    userSummaryScore += Double(valid)
                    maximumScoreSum += 10.0
                }
            }
        }

        return RatingCircleData(rating: userSummaryScore, maximum: maximumScoreSum, minimum: 0, symbol: .star)
//        data.max = maximumScoreSum
//        data.rating = userSummaryScore
//        data.symbol = .star
//
//        stock?.userRatingScore = data
    }
    
    func perValueFactor() -> Double {
        
        guard !(peRatio < 0) else {
            return 0
        }
        
        return ((40 - (abs(peRatio) > 40 ? 40.0 : peRatio)) / 40)
    }
    
    /// for 'higherIsBetter' values; for 'higherIsWorse' use inverseValueFactor()
    /// for 1 value array: returns nil or ema of values based factor between 0-1 for ema 0-maxCutoff
    /// for 2 arrays returns growth-ema of porportions values2 / values1
    /// values above cutOff are returned as 1.0
    /// ema < 0 is returned as 0
    func valueFactor(values1: [Double]?, values2: [Double]?, maxCutOff: Double,emaPeriod: Int) -> Double? {
        
        guard values1 != nil else {
            return nil
        }
        
        var array = values1!
        
        if values2 != nil {
            (array,_) = proportions(array1: values1, array2: values2)
        }
        
        guard let ema = array.ema(periods: emaPeriod) else { return nil }
        
        if ema < 0 { return 0 }
        
        return (ema > maxCutOff ? maxCutOff : ema) / maxCutOff
    }
    
    
    /// same as velueFactor but for 'higherIsWorse' rather than 'higherIsBetter' values
    /// negative ema is good
    /// use postiive value for maxCutOff!
    func inverseValueFactor(values1: [Double]?, values2: [Double]?, maxCutOff: Double, emaPeriod: Int) -> Double? {
        
        guard values1 != nil else {
            return nil
        }
        
        var array = values1!
        
        if values2 != nil {
            (array,_) = proportions(array1: values1, array2: values2)
        }
        
        guard let ema = array.ema(periods: emaPeriod) else { return nil }
        
        if ema > 0 { return 0 }
        
        return 1 - (((ema * -1) > maxCutOff ? maxCutOff : (ema * -1)) / maxCutOff)
    }
    

    /// if at any index i one or both arrays have a nil element then an empty 'Double()' will be inserted as spaceholder at that index
    /// this enables ongoing correlation with other ordered arrays e.g. 'years'
    public func addElements(array1: [Double?], array2: [Double?]) -> ([Double]?, String?) {
        
        var sumArray = [Double]()
        
        guard array1.count == array2.count else {
            return (nil, "two arrays to be added together have differing number of elements")
        }
        
        for i in 0..<array1.count {
            if let valid1 = array1[i] {
                if let valid2 = array2[i] {
                    sumArray.append(valid1 + valid2)
                }
                else {
                    sumArray.append(Double())
                }
            }
            else {
                sumArray.append(Double())
            }
        }
        
        return (sumArray,nil)
    }
    
    public func ivalue() -> (Double?, [String] ){
        
         guard let stock = stocks.filter({ (stock) -> Bool in
            stock.symbol == company
         }).first else {
            return (nil, ["no stock data available for \(company!)"])
         }
        
        guard let price = stock.dailyPrices.last?.close else {
            return (nil, ["no current price available for \(company!)"])
        }
        
        guard price > 0 else {
            return (nil, ["current price for \(company!) = 0"])
        }
              
        
        guard peRatio > 0 else {
            return (nil, ["P/E ratio for \(company!) is negative \(peRatio)"])
        }
        
        var errors = [String]()
        var epsGrowthRates = netEarnings?.growthRates()?.excludeQuartiles()
        if epsGrowthRates == nil {
            errors.append("can't calculate earnigs growth rates; trying EPS growth rates instead")
            epsGrowthRates = eps?.growthRates()
            if epsGrowthRates == nil {
                errors.append("can't calculate EPS growth rates either")
                return (nil, errors)
            }
        }
        
        guard let meanEPSGrowth = epsGrowthRates?.mean() else {
            errors.append("can't calculate mean EPS growth rate")
            return (nil, errors)
        }
        
        if let stdVariation = epsGrowthRates?.stdVariation() {
            if (stdVariation / meanEPSGrowth) > 1.0 {
                errors.append("highly variable past earnings growth rates. Resulting intrinsic value is unreliable")
            }
        }
        
// Method 1
        let futureEPS = Calculator.futureValue(present: eps!.first!, growth: meanEPSGrowth, years: 10.0)
        
        let discountRate = UserDefaults.standard.value(forKey: UserDefaultTerms().longTermCoporateInterestRate) as? Double ?? 0.021
        let discountedCurrentEPS = Calculator.presentValue(growth: discountRate, years: 10.0, endValue: futureEPS)
        let dcCurrentEPSReturn = discountedCurrentEPS / price
        let ivalue = dcCurrentEPSReturn * peRatio
        
        
        return (ivalue, errors)
        
    }

}
