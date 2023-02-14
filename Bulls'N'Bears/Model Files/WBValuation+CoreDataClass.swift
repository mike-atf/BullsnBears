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
        
//        opCashFlow = [Double]()
//        bvps = [Double]()
//        avAnStockPrice = [Double]()
//        eps = [Double]()
//        revenue = [Double]()
//        grossProfit = [Double]()
//        sgaExpense = [Double]()
//        rAndDexpense = [Double]()
//        interestExpense = [Double]()
//        netEarnings = [Double]()
//        roe = [Double]()
//        capExpend = [Double]()
//        debtLT = [Double]()
//        shareholdersEquity = [Double]()
//        roa = [Double]()
//        ppe = [Double]()
//        operatingIncome = [Double]()
//        equityRepurchased = [Double]()
//        date = Date()
//        
//        if let dcf = share?.dcfValuation {
//            if (dcf.capExpend ?? [Double]()).reduce(0, +) != 0 {
//                self.capExpend = dcf.capExpend
//            }
//            
//            if (dcf.netIncome ?? [Double]()).reduce(0, +) != 0 {
//                self.netEarnings = dcf.netIncome
//            }
//
//        }
//        
//        if let r1 = share?.rule1Valuation {
//            if (r1.bvps ?? [Double]()).reduce(0, +) != 0 {
//                self.bvps = r1.bvps
//            }
//            
//            if (r1.revenue ?? [Double]()).reduce(0, +) != 0 {
//                self.revenue = r1.revenue
//            }
//            
//            if (r1.eps ?? [Double]()).reduce(0, +) != 0 {
//                self.eps = r1.eps
//            }
//
//
//        }
        
    }
    /// qEPS_TTM, returns date ascending Datedvalue within TTM or minDate
    func annualEPS_TTM_DV(minDate:Date?=nil) -> [DatedValue]? {
        
        let annualEPS = share?.income_statement?.eps_annual.datedValues(dateOrder: .ascending)?.dropZeros()
        
        let ttmDate = minDate ?? DatesManager.ttmDate()
        
        return annualEPS?.filter({ dv in
            if dv.date < ttmDate { return false }
            else { return true }
        }).sortByDate(dateOrder: .ascending)
        
    }

    /// qEPS, returns sorted date-value pairs ascending by date
//    func epsQWithDates() -> [DatedValue]? {
//
//        if let valid = epsDatesq {
//            do {
//                if let dictionary = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(valid) as? [Date: Double] {
//                    var datedValues = [DatedValue]()
//                    for element in dictionary {
//                        if element.value != 0 {
//                            datedValues.append(DatedValue(date: element.key, value: element.value))
//                        }
//                    }
//                    return datedValues.sorted { dv0, dv1 in
//                        if dv1.date < dv0.date { return false }
//                        else { return true}
//                    }
//                }
//            } catch let error {
//                ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error retrieving stored P/E ratio historical data")
//            }
//        }
//
//        return nil
//    }
    
    
    /// returns past PE ratios in date descending order
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
                ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error retrieving stored P/E ratio historical data")
            }
        }
        
        return nil
    }
    
    func savePERWithDateArray(datesValuesArray: [DatedValue]?, saveInContext:Bool?=true) {
        
        guard let datedValues = datesValuesArray else { return }
        
        var array = [Date: Double]()

        for element in datedValues {
            array[element.date] = element.value
        }

        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: array, requiringSecureCoding: false)
            perDates = data
            if saveInContext ?? true {
                try self.managedObjectContext?.save()
            }
        } catch let error {
            ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error storing stored P/E ratio historical data")
        }
        
    }
    
    /// takes last four qEPS to calculate annual EPS ttm
    func epsTTMFromQEPSArray(datedValues: [DatedValue]?, saveToMOC: Bool?=true) -> [DatedValue]? {
        
        guard var validArray = datedValues else { return nil }
        
        // sort date descending
        validArray = validArray.sorted(by: { e0, e1 in
            if e0.date < e1.date { return false }
            else { return true }
        })
        
        var ttmDatedValues = [DatedValue]()
        let availableQEPS = validArray.count
        for i in 0..<availableQEPS {
            if availableQEPS > i+3 {
                let sum = validArray[i...i+3].compactMap{ $0.value }.reduce( 0, +)
                let newDV = DatedValue(date: validArray[i].date, value: sum)
                ttmDatedValues.append(newDV)
            }
        }
        
        return ttmDatedValues
    }
    
    func saveEPSTTMWithDateArray(datesValuesArray: [DatedValue]?, saveToMOC: Bool?=true) {
        
        guard let datedValues = datesValuesArray else { return }
        
        var array = [Date: Double]()

        for element in datedValues {
            array[element.date] = element.value
        }

        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: array, requiringSecureCoding: false)
            epsDates = data
            if saveToMOC ?? true {
                try self.managedObjectContext?.save()
            }
        } catch let error {
            ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error storing stored P/E ratio historical data")
        }
        
    }
    
//    func saveQEPSWithDateArray(datesValuesArray: [DatedValue]?, saveToMOC: Bool?=true) {
//
//        guard let datedValues = datesValuesArray else { return }
//
//        let ldv = Labelled_DatedValues(label: "Quarterly EPS", datedValues: datedValues)
//
//
//        var array = [Date: Double]()
//
//        for element in datedValues {
//            array[element.date] = element.value
//        }
//
//        do {
//            let data = try NSKeyedArchiver.archivedData(withRootObject: array, requiringSecureCoding: false)
//            epsDatesq = data
//
//            if saveToMOC ?? true {
//                try self.managedObjectContext?.save()
//            }
//        } catch let error {
//            ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error storing stored P/E ratio historical data")
//        }
        
//    }

    
//    func historicPEratio(for date: Date) -> Double? {
//        
//        guard let datedValues = peRatiosWithDates() else {
//            return nil
//        }
//        
//        let timesToDate = datedValues.sorted(by: { e0, e1 in
//            if abs(e1.date.timeIntervalSince(date)) < abs(e0.date.timeIntervalSince(date)) { return false }
//            else { return true }
//        })
//
//        let nearest = [timesToDate[0], timesToDate[1]]
//        return nearest.compactMap{ $0.value }.mean()
//    }
    
    func historicEPSratio(for date: Date) -> Double? {
        
        guard let datedValues = annualEPS_TTM_DV() else {
            return nil
        }
        
        let timesToDate = datedValues.sorted(by: { e0, e1 in
            if abs(e1.date.timeIntervalSince(date)) < abs(e0.date.timeIntervalSince(date)) { return false }
            else { return true }
        })

        let nearest = [timesToDate[0], timesToDate[1]]
        return nearest.compactMap{ $0.value }.mean()
    }

    
//    func minMeanMaxPER(from:Date, to: Date?=nil) -> (Double, Double, Double)? {
//        
//        guard let datedValues = peRatiosWithDates() else {
//            return nil
//        }
//        
//        let end = to ?? Date()
//        
//        let inDateRange = datedValues.filter { (element) -> Bool in
//            if element.date < from { return false }
//            else if element.date > end { return false }
//            return true
//        }
//        
//        let valuesInDateRange = inDateRange.compactMap { $0.value }
//        if let mean = valuesInDateRange.mean() {
//            if let min = valuesInDateRange.min() {
//                if let max = valuesInDateRange.max() {
//                    return (min, mean, max)
//                }
//            }
//        }
//        
//        return nil
//        
//    }
//    
//    func save() {
//        
//       do {
//            try  (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.save()
//        } catch {
//            let nserror = error as NSError
//            fatalError("Unresolved error in WBValuation.save function \(nserror), \(nserror.userInfo)")
//        }
//    }
    
    func delete() {
       
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.delete(self)
 
        do {
            try (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

    func returnUserEvaluations() -> [UserEvaluation]? {
        
        var evaluations: [UserEvaluation]?
        if userEvaluations?.count ?? 0 > 0 {
            evaluations = [UserEvaluation]()
        }
        
        for element in userEvaluations ?? [] {
            if let evaluation = element as? UserEvaluation {
                evaluations?.append(evaluation)
            }
        }
        
        return evaluations
    }
    
    func returnUserCommentsTexts() -> [String]? {
        
        var texts: [String]?
        if userEvaluations?.count ?? 0 > 0 {
            texts = [String]()
        }
        
        for element in userEvaluations ?? [] {
            if let evaluation = element as? UserEvaluation {
                if !(evaluation.comment ?? "").starts(with: "Enter your notes here...") && (evaluation.comment ?? "") != "" {
                    let text = (evaluation.wbvParameter ?? "") + ": " + (evaluation.comment ?? "")
                    texts?.append(text)
                }
            }
        }
        
        return texts
    }

        
    func grossProfitMargins() -> ([DatedValue]?, String?) {
        
        return share!.grossProfitMargins()
        
       
        // OLD
//        guard revenue != nil && grossProfit != nil else {
//            return ([Double()], ["there are no revenue and/or gross profit data"])
//        }
//
//        let rawData = [revenue!, grossProfit!]
//
//        let (cleanedData, error) = ValuationDataCleaner.cleanValuationData(dataArrays: rawData, method: .wb)
//
//        var margins = [Double]()
//        var errors: [String]?
//        for i in 0..<cleanedData[0].count {
//            margins.append(cleanedData[1][i] / cleanedData[0][i])
//        }
//
//        if let validError = error {
//            errors = [validError]
//        }
//        return (margins, errors)
    }
    
    public func sgaProportion() -> ([Double], [String]?) {
        
        guard let sga = share?.income_statement?.sgaExpense.datedValues(dateOrder: .ascending, oneForEachYear: true), let grossProfit = share?.income_statement?.grossProfit.datedValues(dateOrder: .ascending, oneForEachYear: true) else {
            return ([Double()], ["there are no gross profit and/or SG&A data"])
        }
        
        let rawData = [grossProfit, sga]
        
        guard let cleanedData = ValuationDataCleaner.harmonizeDatedValues(arrays: rawData) else {
            return ([Double()], [#function + " - harmonisation failed"])
        }
 
        let grossProfitValues = cleanedData[0].values()
        let sgaValues = cleanedData[1].values()

        var proportions = [Double]()
//        var errorList: [String]?
        for i in 0..<grossProfitValues.count {
            proportions.append(sgaValues[i] / grossProfitValues[i])
        }


        // OLD
//        guard grossProfit != nil && sgaExpense != nil else {
//            return ([Double()], ["there are no gross profit and/or SGA expense data"])
//        }
//
//        let rawData = [grossProfit!, sgaExpense!]
//
//        let (cleanedData, error) = ValuationDataCleaner.cleanValuationData(dataArrays: rawData, method: .wb)
//
//        guard cleanedData[0].count == cleanedData[1].count else {
//            return ([Double()], ["insufficient gross profit and SGA expense data"])
//        }
//
//        var margins = [Double]()
//        var errorList: [String]?
//        for i in 0..<cleanedData[0].count {
//            margins.append(cleanedData[1][i] / cleanedData[0][i])
//        }
//
//        if let validError = error {
//            errorList = [validError]
//        }

        
        return (proportions, nil)

    }
    
    /// returns arary of sums of sahreholdersEquity + equityRepurchased
    public func adjustedEquity() -> [Double] {
        

        guard let erp = equityRepurchased else {
            return [Double]()
        }

        var sums = [Double]()
        var count = 0

        if shareholdersEquity?.count ?? 0 > 0 {
        
            for element in shareholdersEquity ?? [] {
                if (erp.count) > count {
                    sums.append(element + erp[count])
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
    public func proportions(array1: [Double]?, array2: [Double]?, removeZeroElements: Bool?=true) -> ([Double], [String]?) {
        
        guard array1 != nil && array2 != nil else {
            return ([Double()], ["missing data"])
        }
        
        let rawData = [array1!, array2!]
        
        var cleanedData = [[Double]]()
        var error: String?
        
        if removeZeroElements ?? true {
            (cleanedData, error) = ValuationDataCleaner.cleanValuationData(dataArrays: rawData, method: .wb)
        }
        else {
            cleanedData = ValuationDataCleaner.trimArraysToSameCount(array1: array1!, array2: array2!)
        }
        
        
        guard cleanedData[0].count == cleanedData[1].count else {
            return ([Double()], ["insufficient data"])
        }
        
        var proportions = [Double]()
        var errorList: [String]?
        for i in 0..<cleanedData[0].count {
            if cleanedData[0][i] != 0 {
                proportions.append(cleanedData[1][i] / cleanedData[0][i])
            }
        }
        
        if let validError = error {
            errorList = [validError]
        }
        return (proportions, errorList)

    }
    
    public func rAndDProportion() -> ([Double], [String]?) {
        
        guard let rANDd = share?.income_statement?.rdExpense.datedValues(dateOrder: .ascending, oneForEachYear: true), let grossProfit = share?.income_statement?.grossProfit.datedValues(dateOrder: .ascending, oneForEachYear: true) else {
            return ([Double()], ["there are no gross profit and/or SG&A data"])
        }
        
        let rawData = [grossProfit, rANDd]
        
        guard let cleanedData = ValuationDataCleaner.harmonizeDatedValues(arrays: rawData) else {
            return ([Double()], [#function + " - harmonisation failed"])
        }
 
        let grossProfitValues = cleanedData[0].values()
        let rANDdValues = cleanedData[1].values()

        var proportions = [Double]()
//        var errorList: [String]?
        for i in 0..<grossProfitValues.count {
            proportions.append(rANDdValues[i] / grossProfitValues[i])
        }

        
        //
//        guard grossProfit != nil && rAndDexpense != nil else {
//            return ([Double()], ["there are no gross profit and/or R&D expense data"])
//        }
//
//        let rawData = [grossProfit!, rAndDexpense!]
//
//        let (cleanedData, error) = ValuationDataCleaner.cleanValuationData(dataArrays: rawData, method: .wb)
//
//        guard cleanedData[0].count == cleanedData[1].count else {
//            return ([Double()], ["insufficient gross profit and R&D expense data"])
//        }
//
//        var proportions = [Double]()
//        var errorList: [String]?
//        for i in 0..<cleanedData[0].count {
//            proportions.append(cleanedData[1][i] / cleanedData[0][i])
//        }
//
//        if let validError = error {
//            errorList = [validError]
//        }
        return (proportions, nil)

    }
    
    /*
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
    */
    
    public func longtermDebtProportion() -> ([Double], [String]?) {
        
        guard let ltDebt = share?.balance_sheet?.debt_longTerm.datedValues(dateOrder: .ascending, oneForEachYear: true), let netIncome = share?.income_statement?.netIncome.datedValues(dateOrder: .ascending, oneForEachYear: true) else {
            return ([Double()], ["there are no net income and/or long-term debt data"])
        }
        
        let rawData = [netIncome, ltDebt]
        
        guard let cleanedData = ValuationDataCleaner.harmonizeDatedValues(arrays: rawData) else {
            return ([Double()], ["harmonisation failed"])
        }
 
        let netIncomeValues = cleanedData[0].values()
        let ltDebtvalues = cleanedData[1].values()

        var proportions = [Double]()
        var errorList: [String]?
        for i in 0..<netIncomeValues.count {
            if netIncomeValues[i] > 0 {
                proportions.append(ltDebtvalues[i] / netIncomeValues[i])
            }
            else {
                proportions.append(Double())
                if ltDebtvalues[i] > 0 {
                    errorList = ["company made losses and had long term debt!"]
                }
            }
        }
        
//        if let validError = error {
//            if errorList == nil {
//                errorList = [String]()
//            }
//            errorList!.append(validError)
//        }
        return (proportions, errorList)

    }
    
    public func ltDebtPerAdjEquityProportion() -> (Double?, Double?, [String]?) {
        
        var errors: [String]?
        let (shEquityWithRetEarnings, error) = addElements(array1: shareholdersEquity ?? [], array2: equityRepurchased ?? [])
        
        if error != nil {
            errors = [error!]
        }
        let first3Average = shEquityWithRetEarnings?.average(of: 3)
        let (proportions, es$) = proportions(array1: shEquityWithRetEarnings, array2: debtLT)
        if es$ != nil {
            if errors != nil { errors?.append(contentsOf: es$!) }
            else { errors = es$! }
        }
        let average = proportions.ema(periods: 7)

        return (first3Average, average, errors)
    }
    
    public func ltDebtPerAdjEquityProportions() -> [Double]? {
        
        let (shEquityWithRetEarnings, _) = addElements(array1: shareholdersEquity ?? [], array2: equityRepurchased ?? [])
        let first3Average = shEquityWithRetEarnings?.average(of: 3)
        if first3Average ?? 0 > 0 {
            let (proportions, _) = proportions(array1: shEquityWithRetEarnings, array2: debtLT)
            return proportions
        }
        
        return nil
    }
    
    func valuesSummaryScores() -> RatingCircleData? {
        
        if let validShare = self.share {
            let scoreData = valuationWeightsSingleton.financialsScore(forShare: validShare)
            return RatingCircleData(rating: scoreData.score, maximum: scoreData.maxScore, minimum: 0, symbol: .dollar)
        }
        else { return nil }
        /*
        let weights = valuationWeightsSingleton
        
        var allFactors = [Double]()
        var allFactorNames = [String]()
        var allWeights = [Double]()
        let emaPeriods = (UserDefaults.standard.value(forKey: userDefaultTerms.emaPeriodAnnualData) as? Int) ?? 7
        
        allFactors.append(perValueFactor() * weights.peRatio) // 0-1 with cutOff at 40.0
        allWeights.append(weights.peRatio)
        
        if let research = self.share?.research {
            if research.futureGrowthMean != 0 {
                var correctedFactor = Double()
                if research.futureGrowthMean > 0.15 {
                    correctedFactor = 1.0
                }
                else if research.futureGrowthMean > 0.1 {
                    correctedFactor = 0.5
                }
                else if research.futureGrowthMean > 0 {
                    correctedFactor = 0.25
                }
                else {
                    correctedFactor = 0
                }
                allFactors.append(correctedFactor * weights.futureEarningsGrowth)
                allWeights.append(weights.revenueGrowth)
                allFactorNames.append("Future earnings growth")
            }
        }
        if let valid = valueFactor(values1: revenue, values2: nil, maxCutOff: 1, emaPeriod: emaPeriods) {
            allFactors.append(valid * weights.revenueGrowth)
            allWeights.append(weights.revenueGrowth)
            allFactorNames.append("Revenue growth trend")
        }
        if let valid = valueFactor(values1: netEarnings, values2: nil, maxCutOff: 1, emaPeriod: emaPeriods) {
            allFactors.append(valid * weights.netIncomeGrowth)
            allWeights.append(weights.netIncomeGrowth)
            allFactorNames.append("Net income growth trend")
        }
        if let valid = valueFactor(values1: equityRepurchased, values2: nil, maxCutOff: 1, emaPeriod: emaPeriods) {
            allFactors.append(valid * weights.retEarningsGrowth)
            allWeights.append(weights.retEarningsGrowth)
            allFactorNames.append("Ret. earnings growth trend")
        }
//        if let valid = valueFactor(values1: eps, values2: nil, maxCutOff: 1, emaPeriod: emaPeriods) {
//            allFactors.append(valid * weights.retEarningsGrowth)
//            allWeights.append(weights.retEarningsGrowth)
//            allFactorNames.append("EPS growth trend")
//        }
        if let valid = valueFactor(values1: revenue, values2: netEarnings, maxCutOff: 1, emaPeriod: emaPeriods) {
            allFactors.append(valid * weights.netIncomeDivRevenue)
            allWeights.append(weights.netIncomeDivRevenue)
            allFactorNames.append("Growth trend net earnings / sales")
        }
        if let valid = valueFactor(values1: revenue, values2: grossProfit, maxCutOff: 1, emaPeriod: emaPeriods) {
            allFactors.append(valid * weights.profitMargin)
            allWeights.append(weights.profitMargin)
            allFactorNames.append("Growth trend gross profit / sales")
        }
        if let sumDiv = netEarnings?.reduce(0, +) {
            // use 10 y sums / averages, not ema according to Book Ch 51
            if let sumDenom = capExpend?.reduce(0, +) {
                let tenYAverages = abs(sumDenom / sumDiv)
                let maxCutOff = 0.5
                let factor = (tenYAverages < maxCutOff) ? ((maxCutOff - tenYAverages) / maxCutOff) : 0
                allFactors.append(factor * weights.capExpendDivEarnings)
                allWeights.append(weights.capExpendDivEarnings)
                allFactorNames.append("Growth trend cap. expenditure / net earnings")
            }
        }
        if let valid = valueFactor(values1: opCashFlow, values2: nil, maxCutOff: 1, emaPeriod: emaPeriods) {
            allFactors.append(valid * weights.opCashFlowGrowth)
            allWeights.append(weights.opCashFlowGrowth)
            allFactorNames.append("Op. cash flow growth trend")
        }
        if let valid = inverseValueFactor(values1: netEarnings, values2: debtLT ?? [], maxCutOff: 3, emaPeriod: emaPeriods, removeZeroElements: false) {
            allFactors.append(valid * weights.ltDebtDivIncome)
            allWeights.append(weights.ltDebtDivIncome)
            allFactorNames.append("Growth trend long-term debt / net earnings")
        }
        if let valid = inverseValueFactor(values1: adjustedEquity(), values2: debtLT ?? [], maxCutOff: 1, emaPeriod: emaPeriods, removeZeroElements: false) {
            allFactors.append(valid * weights.ltDebtDivadjEq)
            allWeights.append( weights.ltDebtDivadjEq)
            allFactorNames.append("Growth trend long-term debt / adj. share-holder equity")
        }
        if let valid = valueFactor(values1: grossProfit, values2: sgaExpense ?? [], maxCutOff: 0.4, emaPeriod: emaPeriods) {
            allFactors.append(valid * weights.sgaDivProfit)
            allWeights.append(weights.sgaDivProfit)
            allFactorNames.append("Growth trend SGA expense / profit")
        }
        if let valid = valueFactor(values1: grossProfit, values2: rAndDexpense ?? [], maxCutOff: 1, emaPeriod: emaPeriods) {
            allFactors.append(valid * weights.radDivProfit)
            allWeights.append(weights.radDivProfit)
            allFactorNames.append("Growth trend R&D expense / profit")
        }

        if let yield = share?.divYieldCurrent {
            if let earningsGrowth = share?.wbValuation?.netEarnings?.growthRates()?.ema(periods: emaPeriods) {
                let denominator = (earningsGrowth + yield) * 100
                if share?.peRatio ?? 0 > 0 {
                    var value = (denominator / share!.peRatio) - 1
                    if value > 1 { value = 1 }
                    else if value < 0 { value = 0 }
                    allFactors.append(value * weights.lynchScore)
                    allWeights.append(weights.lynchScore)
                    allFactorNames.append("P Lynch sore")
                }
            }
        }
        
        if let score = share?.rule1Valuation?.moatScore() {
            allFactors.append(sqrt(score)*weights.moatScore)
            allWeights.append(weights.moatScore)
            allFactorNames.append("Moat")
        }
        let scoreSum = allFactors.reduce(0, +)
        let maximum = allWeights.reduce(0, +)
         */
        
//        return RatingCircleData(rating: scoreSum, maximum: maximum, minimum: 0, symbol: .dollar)
    }
    
    func valuesSummaryTexts() -> [String] {
        
        if let validShare = self.share {
            let scoreData = valuationWeightsSingleton.financialsScore(forShare: validShare)
            return scoreData.factorArray
        }
        else { return [] }

        /*
        let weights = Financial_Valuation_Factors()
        
        var allFactorTexts = [String]()
        let emaPeriods = (UserDefaults.standard.value(forKey: userDefaultTerms.emaPeriodAnnualData) as? Int) ?? 7
        
        allFactorTexts.append("PE ratio: " + (numberFormatterWith1Digit.string(from: (perValueFactor() * weights.peRatio) as NSNumber) ?? "-"))
        
        if let valid = share?.research?.futureGrowthMean {
            if valid != 0 {
                let value$ = percentFormatter2Digits.string(from: valid as NSNumber) ?? ""
                allFactorTexts.append("Future earnings growth " + value$)
            }
        }

        if let valid = valueFactor(values1: revenue, values2: nil, maxCutOff: 1, emaPeriod: emaPeriods) {
            allFactorTexts.append("Revenue: " + (numberFormatterWith1Digit.string(from: (valid * weights.revenueGrowth) as NSNumber) ?? "-"))
        }
        if let valid = valueFactor(values1: netEarnings, values2: nil, maxCutOff: 1, emaPeriod: emaPeriods) {
            allFactorTexts.append("Net income: " + (numberFormatterWith1Digit.string(from: (valid * weights.netIncomeGrowth) as NSNumber) ?? "-"))
        }
        if let valid = valueFactor(values1: equityRepurchased, values2: nil, maxCutOff: 1, emaPeriod: emaPeriods) {
            allFactorTexts.append("Ret. earnings: " + (numberFormatterWith1Digit.string(from: (valid * weights.retEarningsGrowth) as NSNumber) ?? "-"))
        }
        if let valid = valueFactor(values1: eps, values2: nil, maxCutOff: 1, emaPeriod: emaPeriods) {
            allFactorTexts.append("EPS: " + (numberFormatterWith1Digit.string(from: (valid * weights.epsGrowth) as NSNumber) ?? "-"))
        }
        if let valid = valueFactor(values1: revenue, values2: netEarnings, maxCutOff: 1, emaPeriod: emaPeriods) {
            allFactorTexts.append("Net earnings / sales: " + (numberFormatterWith1Digit.string(from: (valid * weights.netIncomeDivRevenue) as NSNumber) ?? "-"))
        }
        if let valid = valueFactor(values1: revenue, values2: grossProfit, maxCutOff: 1, emaPeriod: emaPeriods) {
            allFactorTexts.append("Gross profit / sales: " + (numberFormatterWith1Digit.string(from: (valid * weights.profitMargin) as NSNumber) ?? "-"))
        }
        if let sumDiv = netEarnings?.reduce(0, +) {
            // use 10 y sums / averages, not ema according to Book Ch 51
            if let sumDenom = capExpend?.reduce(0, +) {
                let tenYAverages = abs(sumDenom / sumDiv)
                let maxCutOff = 0.5
                let factor = (tenYAverages < maxCutOff) ? ((maxCutOff - tenYAverages) / maxCutOff) : 0
                allFactorTexts.append("Cap. expenditure / net earnings: " + (numberFormatterWith1Digit.string(from: (factor * weights.capExpendDivEarnings) as NSNumber) ?? "-"))
            }
        }
        if let valid = valueFactor(values1: opCashFlow, values2: nil, maxCutOff: 1, emaPeriod: emaPeriods) {
            allFactorTexts.append("Op. cash flow: " + (numberFormatterWith1Digit.string(from: (valid * weights.opCashFlowGrowth) as NSNumber) ?? "-"))
        }
        if let valid = inverseValueFactor(values1: netEarnings, values2: debtLT ?? [], maxCutOff: 3, emaPeriod: emaPeriods, removeZeroElements: false) {
            allFactorTexts.append("Long-term debt / net earnings: " + (numberFormatterWith1Digit.string(from: (valid * weights.ltDebtDivIncome) as NSNumber) ?? "-"))
        }
        if let valid = inverseValueFactor(values1: adjustedEquity(), values2: debtLT ?? [], maxCutOff: 1, emaPeriod: emaPeriods, removeZeroElements: false) {

            allFactorTexts.append("Long-term debt / adj. share-holder equity: " + (numberFormatterWith1Digit.string(from: (valid * weights.ltDebtDivadjEq) as NSNumber) ?? "-"))
        }
        if let valid = valueFactor(values1: grossProfit, values2: sgaExpense, maxCutOff: 0.4, emaPeriod: emaPeriods) {
            allFactorTexts.append("SGA expense / profit: " + (numberFormatterWith1Digit.string(from: (valid * weights.sgaDivProfit) as NSNumber) ?? "-"))
        }
        if let valid = valueFactor(values1: grossProfit, values2: rAndDexpense, maxCutOff: 1, emaPeriod: emaPeriods) {
            allFactorTexts.append("R&D expense / profit: " + (numberFormatterWith1Digit.string(from: (valid * weights.radDivProfit) as NSNumber) ?? "-"))
        }
        let emaPeriod = (UserDefaults.standard.value(forKey: userDefaultTerms.emaPeriodAnnualData) as? Int) ?? 7
        if let yield = share?.divYieldCurrent {
            if let earningsGrowth = share?.wbValuation?.netEarnings?.growthRates()?.ema(periods: emaPeriod) {
                let denominator = (earningsGrowth + yield) * 100
                if share?.peRatio ?? 0 > 0 {
                    var value = (denominator / share!.peRatio) - 1
                    if value > 1 { value = 1 }
                    else if value < 0 { value = 0 }
                    allFactorTexts.append("P Lynch score: " + (numberFormatterWith1Digit.string(from: (value * weights.lynchScore) as NSNumber) ?? "-"))
                }
            }
        }
        
        if let moatScore  = share?.rule1Valuation?.moatScore() {
            let score = sqrt(moatScore)
            allFactorTexts.append("Moat: " + (numberFormatterWith1Digit.string(from: score as NSNumber) ?? "-"))
        }
        return allFactorTexts
         */
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
        
        if let research = share?.research {
            if research.futureGrowthMean > 0.15 {
                userSummaryScore += 10
            }
            else if research.futureGrowthMean > 0.1 {
                userSummaryScore += 5
            }
            else if research.futureGrowthMean < 0 {
                userSummaryScore -= 10
            }
            if userSummaryScore < 0 { userSummaryScore = 0 }
            maximumScoreSum += 10
        }

        return RatingCircleData(rating: userSummaryScore, maximum: maximumScoreSum, minimum: 0, symbol: .star)
    }
    
    func perValueFactor() -> Double {
        guard let validShare = share else {
            return 0
        }
        
        guard !(validShare.peRatio_current <= 0) else {
            return 0
        }
        
        return ((40 - (abs(validShare.peRatio_current) > 40 ? 40.0 : validShare.peRatio_current)) / 40)
    }
    
    /// for 'higherIsBetter' values; for 'higherIsWorse' use inverseValueFactor()
    /// for 1 value array: returns nil or ema of values based factor between 0-1 for ema 0-maxCutoff
    /// for 2 arrays returns growth-ema of porportions values2 / values1
    /// values above cutOff are returned as 1.0
    /// ema < 0 is returned as 0
    func valueFactor(values1: [Double]?, values2: [Double]?, maxCutOff: Double,emaPeriod: Int, removeZeroElements:Bool?=true) -> Double? {
        
        guard values1 != nil else {
            return nil
        }
        
        var array = values1!
        
        if values2 != nil {
            (array,_) = proportions(array1: values1, array2: values2, removeZeroElements: removeZeroElements)
        }
        else {
            array = Calculator.compoundGrowthRates(values: array) ?? []
        }
        
        guard var ema = array.ema(periods: emaPeriod) else { return nil }
        let consistency = array.consistency(increaseIsBetter: true) // may be Double() - 0.0
        
        if ema < 0 { ema = 0 } // TODO: - check EMA<0 for negative/ cost reduction
        
        let growthValue = (ema > maxCutOff ? maxCutOff : ema) / maxCutOff
        let combined = sqrt(sqrt(growthValue) * sqrt(consistency))
        return combined
    }
    
    
    /// same as velueFactor but for 'higherIsWorse' rather than 'higherIsBetter' values
    /// negative ema is good
    /// use postiive value for maxCutOff!
    func inverseValueFactor(values1: [Double]?, values2: [Double]?, maxCutOff: Double, emaPeriod: Int, removeZeroElements:Bool?=true) -> Double? {
        
        guard values1 != nil else {
            return nil
        }
        
        var array = values1!
        
        if values2 != nil {
            (array,_) = proportions(array1: values1, array2: values2, removeZeroElements: removeZeroElements)
        }
        else {
            array = Calculator.compoundGrowthRates(values: array) ?? []
        }

        
        guard var ema = array.ema(periods: emaPeriod) else { return nil }
        let consistency = array.consistency(increaseIsBetter: false) // may be Double() - 0.0

        // maxCutOff is given as positive, despite lower/ negative being better
        // negative ema is better than positive ema
        
        ema *= -1
        if ema < 0 { ema = 0 } // positive growth is bad -> 0 points
        let growthValue = (ema > maxCutOff ? maxCutOff : ema) / maxCutOff

//        let growthValue = 1 - (((ema * -1) > maxCutOff ? maxCutOff : (ema * -1)) / maxCutOff)
        let combined = sqrt(sqrt(growthValue) * sqrt(consistency))
        return combined
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
    
    /// [precent, price] as [Double?, Double?]
//    public func bookValuePerPrice() -> [Double?]? {
//        
//        guard let validShare = share else {
//            return nil
//        }
//
//        
//        let lastStockPrice =  validShare.getDailyPrices()?.last?.close //stock.dailyPrices.last?.close
//        if let valid = bvps?.first {
//            if lastStockPrice != nil {
//                let percent = valid / lastStockPrice!
//                let price = valid
//                return [percent, price]
//            }
//        }
//        
//        return nil
//
//    }
    
    public func lynchRatio() -> ([String]?, Double?) {
        
        if share != nil {
            return share!.lynchRatio()
        } else {
            return (nil, nil)
        }
        
//        guard let validShare = share else {
//            return nil
//        }
//
//        guard let divYield = validShare.key_stats?.dividendYield.valuesOnly(dateOrdered: .ascending)?.last else { return nil }
//
//        guard let currentPE = validShare.ratios?.pe_ratios.valuesOnly(dateOrdered: .ascending)?.last else { return nil }
//
//        if let earningsGrowth = validShare.income_statement?.netIncome.valuesOnly(dateOrdered: .ascending)?.growthRates()?.mean() { // ema(periods: emaPeriod)
//            // use 10 y sums / averages, not ema according to Book Ch 51
//            let denominator = earningsGrowth * 100 + divYield * 100
//            if currentPE > 0 {
//                return (denominator / currentPE)
//            }
//        }

        
//        if let earningsGrowth = netEarnings?.growthRates()?.mean() { // ema(periods: emaPeriod)
//            // use 10 y sums / averages, not ema according to Book Ch 51
//            let denominator = earningsGrowth * 100 + validShare.divYieldCurrent * 100
//            if validShare.peRatio_current > 0 {
//                return (denominator / validShare.peRatio_current)
//            }
//        }
        
//        return nil

    }
    
    public func ivalue() -> (Double?, [String] ){
        
        // latest Price
        // latest pe ratio
        // net income
        // eps
        
        guard let price = share?.getDailyPrices()?.last?.close else {
            return (nil, ["no current price available for \(share?.symbol ?? "missing symbol")"])
        }
        
        guard price > 0 else {
            return (nil, ["current price for \(share?.symbol ?? "missing symbol") = 0"])
        }
              
        
        guard let latestPERDV = share?.ratios?.pe_ratios.datedValues(dateOrder: .ascending)?.dropZeros().last else {
            return (nil, ["latest P/E ratio for \(share?.symbol ?? "missing symbol") is missing"])
        }
        
        guard latestPERDV.value > 0 else {
            return (nil, ["latest P/E ratio for \(share?.symbol ?? "missing symbol") is negative"])
        }
        
        
        guard let incomeDV = share?.income_statement?.netIncome.datedValues(dateOrder: .ascending) else {
            return (nil, ["Missing net income for \(company!)"])
        }
        
        var errors = [String]()

        if latestPERDV.date.timeIntervalSinceNow > 365*24*3600/4 {
            let date$ = dateFormatter.string(from: latestPERDV.date)
            errors.append("latest P/E ratio is from \(date$)")
        }
        
        let incomeGrowthRateDVs = incomeDV.growthRates(dateOrder: .ascending)
        guard let meanEPSGrowth = incomeGrowthRateDVs?.compactMap({ $0.value }).median() else {
            errors.append("can't calculate median EPS growth rate")
            return (nil, errors)
        }
        let correlation = Calculator.correlationDatesToValues(array: incomeGrowthRateDVs)
        if let r2 = correlation?.r2() {
            if r2 < 0.64 {
                let r2$ = percentFormatter2Digits.string(from: r2 as NSNumber) ?? "?"
                errors.append("highly variable past earnings growth rates, R2 \(r2$). Resulting intrinsic value is unreliable")

            }
        }
        
        guard let latestEPS = share?.income_statement?.eps_annual.valuesOnly(dateOrdered: .descending)?.first else {
            return (nil, ["iValue lacks EPS values"])
        }
        
        let futureEPS = Calculator.futureValue(present: latestEPS, growth: meanEPSGrowth, years: 10.0)
        
        let discountRate = UserDefaults.standard.value(forKey: UserDefaultTerms().longTermCoporateInterestRate) as? Double ?? 0.021
        let discountedCurrentEPS = Calculator.presentValue(growth: discountRate, years: 10.0, endValue: futureEPS)
        let dcCurrentEPSReturn = discountedCurrentEPS / price
        let ivalue = dcCurrentEPSReturn * latestPERDV.value
        
        
        return (ivalue, errors)
    }
    
    public func ageOfValuation() -> TimeInterval? {
        
        if let date = self.date {
            return Date().timeIntervalSince(date)
        }
        
        return nil
    }
    
    func addIntrinsicValueTrend(date: Date, value: Double) {
        
        var existingTrendDv = intrinsicValueTrend.datedValues(dateOrder: .ascending)
        
        if let latest = existingTrendDv?.last?.date {
            if date.timeIntervalSince(latest) > (365/12 * 24 * 3600) {
                existingTrendDv?.append((DatedValue(date: date, value: value)))
                intrinsicValueTrend = existingTrendDv?.convertToData()
            }
        }
        else {
            intrinsicValueTrend = [DatedValue(date: date, value: value)].convertToData()
        }
    }



}
