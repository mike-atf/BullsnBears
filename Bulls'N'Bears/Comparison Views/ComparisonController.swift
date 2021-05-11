//
//  ComparisonController.swift
//  Bulls'N'Bears
//
//  Created by aDav on 28/04/2021.
//

import Foundation

class ComparisonController {
    
    var shares: [Share]?
    var controlledView: ComparisonVC
    
    
    init(shares: [Share]?, viewController: ComparisonVC) {
        
        self.shares = shares
        self.controlledView = viewController
    }
    
    func rowTitles() -> [[String]]{
        
        let titleStructure = [["Why to buy"],
                                ["Personal rating score", "Fundamentals score", "Compet. strength" ,"Share price / GB Value" ,"Share price / DCF Value", "Share price / Intrinsic value"],
                                ["PE ratio", "Lynch ratio", "Book value / share price"],
                                ["Ret. earnings growth", "Revenue growth", "Net income growth", "Op. Cash flow growth", "Gross profit growth", "EPS growth"],
                                ["Profit margin growth", "Net earnings margin growth"],
                                ["ROI growth", "ROE growth", "ROA growth"],
                                ["LT Debt / net income", "LT Debt / adj equity", "cap. exp.", "SGA / profit", "R&D / profit"]]
        
        return titleStructure
        
    }
    
    func sectionTitle() -> [String] {
        
        return ["", "Scores & valuations", "Ratios", "Fundamentals" ,"Fundamentals ratios" ,"Returns", "Debt, outgoings & costs"]
    }
    
    func titleForSection(section: Int) -> String {
        
        guard section < sectionTitle().count else {
            return ""
        }
        
        return sectionTitle()[section]
    }
    
    func titleForRow(for path: IndexPath) -> String {
        
        let titles = rowTitles()
        return titles[path.section][path.row]
    }
    
    func rowTexts(forPath: IndexPath) -> [String] {
        
        var texts = [String]()
        
        switch forPath.section {
        case 0:
            if forPath.row == 0 {
                for share in shares ?? [] {
                    texts.append(share.research?.theBuyStory ?? "")
                }
            }
        case 1:
            if forPath.row == 0 {
                for share in  shares ?? [] {
                    var text = "-"
                    if share.userEvaluationScore > 0 {
                        text = percentFormatter0Digits.string(from: share.userEvaluationScore as NSNumber) ?? "-"
                    }
                    texts.append(text)
                }
            }
            else if forPath.row == 1 {
                for share in  shares ?? [] {
                    var text = "-"
                    if share.valueScore > 0 {
                        text = percentFormatter0Digits.string(from: share.valueScore as NSNumber) ?? "-"
                    }
                    texts.append(text)
                }
            }
            else if forPath.row == 2 {
                for share in  shares ?? [] {
                    var text = "-"
                    if let moat = share.rule1Valuation?.moatScore() {
                        text = percentFormatter0Digits.string(from: moat as NSNumber) ?? "-"
                    }
                    texts.append(text)
                }
            }
            else if forPath.row == 3 {
                for share in  shares ?? [] {
                    var text = "-"
                    if share.rule1Valuation != nil {
                        let (price,_) = share.rule1Valuation!.stickerPrice()
                        if let validPrice = price {
                            let ratio = share.latestPrice(option: .close)! / validPrice
                            text = percentFormatter0Digits.string(from: ratio as NSNumber) ?? "-"
                        }
                    }
                    texts.append(text)
                }
            }
            else if forPath.row == 4 {
                for share in  shares ?? [] {
                    var text = "-"
                    if share.dcfValuation != nil {
                        let (price,_) = share.dcfValuation!.returnIValue()
                        if let validPrice = price {
                            let ratio = share.latestPrice(option: .close)! / validPrice
                            text = percentFormatter0Digits.string(from: ratio as NSNumber) ?? "-"
                        }
                    }
                    texts.append(text)
                }
            }
            else if forPath.row == 5 {
                for share in  shares ?? [] {
                    var text = "-"
                    if share.wbValuation != nil {
                        let (price,_) = share.wbValuation!.ivalue()
                        if let validPrice = price {
                            let ratio = share.latestPrice(option: .close)! / validPrice
                            text = percentFormatter0Digits.string(from: ratio as NSNumber) ?? "-"
                        }
                    }
                    texts.append(text)
                }
            }
        case 2:
            if forPath.row == 0 {
                for share in  shares ?? [] {
                    var text = "-"
                    if share.peRatio != 0 {
                        text = numberFormatterWith1Digit.string(from: share.peRatio as NSNumber) ?? "-"
                    }
                    texts.append(text)
                }
            }
            else if forPath.row == 1 {
                for share in  shares ?? [] {
                    var text = "-"
                    if share.wbValuation != nil {
                        if let ratio = share.wbValuation!.lynchRatio() {
                            text = numberFormatterWith1Digit.string(from: ratio as NSNumber) ?? "-"
                        }
                    }
                    texts.append(text)
                }
            }
            else if forPath.row == 2 {
                for share in  shares ?? [] {
                    var text = "-"
                    if share.wbValuation != nil {
                        if let values = share.wbValuation!.bookValuePerPrice() {
                            var t1$:String?
                            var t2$:String?
                            if let value1 = values[0] {
                                t1$ = percentFormatter0Digits.string(from: value1 as NSNumber) ?? ""
                            }
                            if let value2 = values[1] {
                                t2$ = currencyFormatterNoGapWithPence.string(from: value2 as NSNumber) ?? ""
                            }

                            
                            if t1$ != nil && t2$ != nil {
                                text = t1$! + " (" + t2$! + ")"
                            }
                            else {
                                text = (t1$ ?? t2$) ?? "-"
                            }
                        }
                    }
                    texts.append(text)
                }
            }
        case 3:
            if forPath.row == 0 {
                for share in  shares ?? [] {
                    var text = "-"
                    if let retE = share.wbValuation?.equityRepurchased { // MT.com row-based data are stored in time-DESCENDING order
                        if let lastRetEarnings = retE.first {
                            if lastRetEarnings < 0 {
                                text = "last neg."
                            }
                            else {
                                if let ema = retE.growthRates()?.ema(periods: 7) {
                                    text = percentFormatter0Digits.string(from: ema as NSNumber) ?? "-"
                                }
                            }
                        }
                    }
                    texts.append(text)
                }
            }
            else if forPath.row == 1 {
                for share in  shares ?? [] {
                    var text = "-"
                    if let values = share.wbValuation?.revenue { // MT.com row-based data are stored in time-DESCENDING order
                        if let lastRetEarnings = values.first {
                            if lastRetEarnings < 0 {
                                text = "last neg."
                            }
                            else {
                                if let ema = values.growthRates()?.ema(periods: 7) {
                                    text = percentFormatter0Digits.string(from: ema as NSNumber) ?? "-"
                                }
                            }
                        }
                    }
                    texts.append(text)
                }
            }
            else if forPath.row == 2 {
                for share in  shares ?? [] {
                    var text = "-"
                    if let values = share.wbValuation?.netEarnings { // MT.com row-based data are stored in time-DESCENDING order
                        if let lastRetEarnings = values.first {
                            if lastRetEarnings < 0 {
                                text = "last neg."
                            }
                            else {
                                if let ema = values.growthRates()?.ema(periods: 7) {
                                    text = percentFormatter0Digits.string(from: ema as NSNumber) ?? "-"
                                }
                            }
                        }
                    }
                    texts.append(text)
                }
            }
            else if forPath.row == 3 {
                for share in  shares ?? [] {
                    var text = "-"
                    if let values = share.wbValuation?.opCashFlow { // MT.com row-based data are stored in time-DESCENDING order
                        if let lastRetEarnings = values.first {
                            if lastRetEarnings < 0 {
                                text = "last neg."
                            }
                            else {
                                if let ema = values.growthRates()?.ema(periods: 7) {
                                    text = percentFormatter0Digits.string(from: ema as NSNumber) ?? "-"
                                }
                            }
                        }
                    }
                    texts.append(text)
                }
            }
            else if forPath.row == 4 {
                for share in  shares ?? [] {
                    var text = "-"
                    if let values = share.wbValuation?.grossProfit { // MT.com row-based data are stored in time-DESCENDING order
                        if let lastRetEarnings = values.first {
                            if lastRetEarnings < 0 {
                                text = "last neg."
                            }
                            else {
                                if let ema = values.growthRates()?.ema(periods: 7) {
                                    text = percentFormatter0Digits.string(from: ema as NSNumber) ?? "-"
                                }
                            }
                        }
                    }
                    texts.append(text)
                }
            }
            else if forPath.row == 5 {
                for share in  shares ?? [] {
                    var text = "-"
                    if let values = share.wbValuation?.eps { // MT.com row-based data are stored in time-DESCENDING order
                        if let lastRetEarnings = values.first {
                            if lastRetEarnings < 0 {
                                text = "last neg."
                            }
                            else {
                                if let ema = values.growthRates()?.ema(periods: 7) {
                                    text = percentFormatter0Digits.string(from: ema as NSNumber) ?? "-"
                                }
                            }
                        }
                    }
                    texts.append(text)
                }
            }
//        case 4:
//            if forPath.row == 0 {
//                for share in  shares ?? [] {
//                    var text = "-"
//                    if let proportions = Calculator.proportions(array1: share.wbValuation?.grossProfit, array0: share.wbValuation?.revenue) {
//                        if let ema = proportions.ema(periods: 7) {
//                            text = (percentFormatter0DigitsPositive.string(from: ema as NSNumber) ?? "-")
//                        }
//                        var years = [Double]()
//                        for i in 0..<proportions.count {
//                            years.append(Double(proportions.count-i))
//                        }
//                        if let correlation = Calculator.correlation(xArray: years, yArray: proportions) {
//                            let r2 = correlation.r2() ?? 0
//                            var correlation$ = "very low"
//                            if r2 > 0.64 { correlation$ = "high"}
//                            else if r2 > 0.5 { correlation$ = "low" }
//                            text += correlation$
//                            text += percentFormatter0DigitsPositive.string(from: correlation.incline as NSNumber) ?? "-"
//                        }
//                    }
//                    texts.append(text)
//                }
//
//            }
        default:
            texts = [String]()
        }
        
        return texts
    }
    
    func financialsTexts(forPath: IndexPath) -> [[String]]? {
        
        guard forPath.section > 2 else {
            return nil
        }
        
        var textTriplets = [[String]]()
        
        if forPath.section == 3 {
            if forPath.row == 0 {
                for share in  shares ?? [] {
                    let triplet = singleFinancialText(values: share.wbValuation?.equityRepurchased)
                    textTriplets.append(triplet)
                }
            }
            else if forPath.row == 1 {
                for share in  shares ?? [] {
                    
                    let triplet = singleFinancialText(values: share.wbValuation?.revenue)
                    textTriplets.append(triplet)
                }
            }
            else if forPath.row == 2 {
                for share in  shares ?? [] {
                    let triplet = singleFinancialText(values: share.wbValuation?.netEarnings)
                    textTriplets.append(triplet)
                }
            }
            else if forPath.row == 3 {
                for share in  shares ?? [] {
                    let triplet = singleFinancialText(values: share.wbValuation?.opCashFlow)
                    textTriplets.append(triplet)
                }
            }
            else if forPath.row == 4 {
                for share in  shares ?? [] {
                    let triplet = singleFinancialText(values: share.wbValuation?.grossProfit, growthCutOffRate: 0.0)
                    textTriplets.append(triplet)
                }
            }
            else if forPath.row == 5 {
                for share in  shares ?? [] {
                    let triplet = singleFinancialText(values: share.wbValuation?.eps)
                    textTriplets.append(triplet)
                }
            }
        }
        else if forPath.section == 4 {
            if forPath.row == 0 {
                for share in  shares ?? [] {
                    let texts = twoFinancialsText(values0: share.wbValuation?.revenue, values1: share.wbValuation?.grossProfit)
                    textTriplets.append(texts)
                }
            }
            else if forPath.row == 1 {
                for share in  shares ?? [] {
                    let texts = twoFinancialsText(values0: share.wbValuation?.revenue, values1: share.wbValuation?.netEarnings)
                    textTriplets.append(texts)
                }
            }
        }
        else if forPath.section == 5 { // outgoings - positive increase = BAD
            if forPath.row == 0 {
                for share in  shares ?? [] {
                    let texts = singleFinancialText(values: share.rule1Valuation?.roic)
                    textTriplets.append(texts)
                }
            }
            if forPath.row == 1 {
                for share in  shares ?? [] {
                    let texts = singleFinancialText(values: share.wbValuation?.roe)
                    textTriplets.append(texts)
                }
            }
            if forPath.row == 2 {
                for share in  shares ?? [] {
                    let texts = singleFinancialText(values: share.wbValuation?.roa)
                    textTriplets.append(texts)
                }
            }
        }
        else if forPath.section == 6 {
            if forPath.row == 0 {
                for share in  shares ?? [] {
                    let texts = twoFinancialsText(values0: share.wbValuation?.netEarnings, values1: share.wbValuation?.debtLT, growthCutOffRate: 0.0, biggerIsBetter: false)
                    textTriplets.append(texts)
                }
            }
            else if forPath.row == 1 {
                for share in  shares ?? [] {
                    if let proportions = share.wbValuation?.ltDebtPerAdjEquityProportions() {
                        let texts = singleFinancialText(values: proportions, growthCutOffRate: 0.0, biggerIsBetter: false)
                        textTriplets.append(texts)
                    }
                }
            }
            else if forPath.row == 2 {
                for share in  shares ?? [] {
                    let texts = singleFinancialText(values: share.wbValuation?.capExpend, growthCutOffRate: 0.0, biggerIsBetter: false)
                    textTriplets.append(texts)
                }
            }
            else if forPath.row == 3 {
                for share in  shares ?? [] {
                    let texts = twoFinancialsText(values0: share.wbValuation?.grossProfit, values1: share.wbValuation?.sgaExpense, growthCutOffRate: 0.0, biggerIsBetter: false)
                    textTriplets.append(texts)
                }
            }
            else if forPath.row == 4 {
                for share in  shares ?? [] {
                    let texts = twoFinancialsText(values0: share.wbValuation?.grossProfit, values1: share.wbValuation?.rAndDexpense, growthCutOffRate: 0.0, biggerIsBetter: false)
                    textTriplets.append(texts)
                }
            }

        }

        return textTriplets
    }
    
    private func singleFinancialText(values: [Double]?, growthCutOffRate:Double?=nil, biggerIsBetter: Bool?=nil) -> [String] {
        
        var text = [String]()
        
        let lowestAcceptableGrowth = growthCutOffRate ?? 0.1
        let higherIsBetter = biggerIsBetter ?? true
        
        if let compoundGrowthRates = Calculator.compoundGrowthRates(values: values) {
            if let ema = compoundGrowthRates.ema(periods: 7) {
                text.append(percentFormatter0DigitsPositive.string(from: ema as NSNumber) ?? "-")
            } else { text.append("-") }
            
            let countExceedingThreshold = higherIsBetter ? compoundGrowthRates.filter { rate in
                if rate < lowestAcceptableGrowth { return false }
                else { return true }
            } : compoundGrowthRates.filter { rate in
                if rate > lowestAcceptableGrowth { return false }
                else { return true }
            }
            
            let nonNilGrowthRates = compoundGrowthRates //.filter { rate in
//                if rate != Double() { return true }
//                else { return false }
//            }
            
            let consistency = Double(countExceedingThreshold.count) / Double(nonNilGrowthRates.count)
            text.append(percentFormatter0Digits.string(from: consistency as NSNumber) ?? "-")
                
            var years = [Double]()
            for i in 0..<compoundGrowthRates.count {
                years.append(Double(compoundGrowthRates.count-i))
            }

            if let correlation = Calculator.correlation(xArray: years, yArray: compoundGrowthRates) {
                text.append(percentFormatter0DigitsPositive.string(from: correlation.incline as NSNumber) ?? "-")
            }
            else { text.append("-") }
        }
        else { text = ["-","-","-"] }
        
        
// so far
        /*
        if let rates = values?.filter({ (element) -> Bool in
            if element != 0.0 { return true }
            else { return false }
        }).growthRates() {
            if let ema = rates.ema(periods: 7) {
                text.append(percentFormatter0DigitsPositive.string(from: ema as NSNumber) ?? "-")
            }
            var years = [Double]()
            for i in 0..<rates.count {
                years.append(Double(rates.count-i))
            }
            if let correlation = Calculator.correlation(xArray: years, yArray: rates) {
                let r2 = correlation.r2() ?? 0
                var correlation$ = "very low"
                if r2 > 0.64 { correlation$ = "high"}
                else if r2 > 0.5 { correlation$ = "low" }
                text.append(correlation$)
                text.append(percentFormatter0DigitsPositive.string(from: correlation.incline as NSNumber) ?? "-")
            }
            else {
                text.append("-")
                text.append("-")
            }
        }
        else { text = ["-","-","-"] }
        */
        
        return text
    }
    
    /// proportions = values1 / values0
    private func twoFinancialsText(values0: [Double]?, values1:[Double]?, growthCutOffRate:Double?=nil, biggerIsBetter: Bool?=nil) -> [String] {
        
        var texts = [String]()
        let lowestAcceptableGrowth = growthCutOffRate ?? 0.1
        let higherIsBetter = biggerIsBetter ?? true

        if let proportions = Calculator.proportions(array1: values1, array0: values0) {
            if let compoundGrowthRates = Calculator.compoundGrowthRates(values: proportions) {
                if let ema = compoundGrowthRates.ema(periods: 7) {
                    texts.append(percentFormatter0DigitsPositive.string(from: ema as NSNumber) ?? "-")
                } else { texts.append("-") }
                
                let ratesOverTenPct = higherIsBetter ? compoundGrowthRates.filter { rate in
                    if rate < lowestAcceptableGrowth { return false }
                    else { return true }
                } : compoundGrowthRates.filter { rate in
                    if rate > lowestAcceptableGrowth { return false }
                    else { return true }
                }
                
                let nonNilGrowthRates = compoundGrowthRates //.filter { rate in
//                    if rate != Double() { return true }
//                    else { return false }
//                }
                
                let consistency = Double(ratesOverTenPct.count) / Double(nonNilGrowthRates.count)
                texts.append(percentFormatter0Digits.string(from: consistency as NSNumber) ?? "-")
                    
                var years = [Double]()
                for i in 0..<compoundGrowthRates.count {
                    years.append(Double(compoundGrowthRates.count-i))
                }

                if let correlation = Calculator.correlation(xArray: years, yArray: compoundGrowthRates) {
                    texts.append(percentFormatter0DigitsPositive.string(from: correlation.incline as NSNumber) ?? "-")
                }
                else { texts.append("-") }

            }
        }
        else { texts = ["-","-","-"] }

// oLd
//        if let proportions = Calculator.proportions(array1: values1, array0: values0) {
//            if let ema = proportions.ema(periods: 7) {
//                triplet.append(percentFormatter0DigitsPositive.string(from: ema as NSNumber) ?? "-")
//            }
//            var years = [Double]()
//            for i in 0..<proportions.count {
//                years.append(Double(proportions.count-i))
//            }
//            if let correlation = Calculator.correlation(xArray: years, yArray: proportions) {
//                let r2 = correlation.r2() ?? 0
//                var correlation$ = "very low"
//                if r2 > 0.64 { correlation$ = "high"}
//                else if r2 > 0.5 { correlation$ = "low" }
//                triplet.append(correlation$)
//                triplet.append(percentFormatter0DigitsPositive.string(from: correlation.incline as NSNumber) ?? "-")
//            }
//            else {
//                triplet.append("-")
//                triplet.append("-")
//            }
//        }
//        else { triplet = ["-","-","-"] }
        
        return texts
    }
    
    func fundamentals(forPath: IndexPath) -> ([Correlation?]?, [[Double]?]?) {
        
        guard forPath.section > 2 else {
            return (nil, nil)
        }
        
        var valueArray = [[Double]?]()
        var correlations = [Correlation?]()
        
        if forPath.section == 3 {
            if forPath.row == 0 {
                for share in shares ?? [] {
                    valueArray.append(share.wbValuation?.equityRepurchased)
                    let proportions = proportions(values: [share.wbValuation?.equityRepurchased])
                    correlations.append(Calculator.valueChartCorrelation(arrays:[share.wbValuation?.equityRepurchased, proportions]))
                }
            }
            else if forPath.row == 1 {
                for share in shares ?? [] {
                    valueArray.append(share.wbValuation?.revenue)
                    let proportions = proportions(values: [share.wbValuation?.revenue])
                    correlations.append(Calculator.valueChartCorrelation(arrays:[share.wbValuation?.revenue, proportions]))
                }

            }
            else if forPath.row == 2 {
                for share in shares ?? [] {
                    valueArray.append(share.wbValuation?.netEarnings)
                    let proportions = proportions(values: [share.wbValuation?.netEarnings])
                    correlations.append(Calculator.valueChartCorrelation(arrays:[share.wbValuation?.netEarnings, proportions]))
                }

            }
            else if forPath.row == 3 {
                for share in shares ?? [] {
                    valueArray.append(share.wbValuation?.opCashFlow)
                    let proportions = proportions(values: [share.wbValuation?.opCashFlow])
                    correlations.append(Calculator.valueChartCorrelation(arrays:[share.wbValuation?.opCashFlow, proportions]))
                }

            }
            else if forPath.row == 4 {
                for share in shares ?? [] {
                    valueArray.append(share.wbValuation?.grossProfit)
                    let proportions = proportions(values: [share.wbValuation?.grossProfit])
                    correlations.append(Calculator.valueChartCorrelation(arrays:[share.wbValuation?.grossProfit, proportions]))
                }

            }
            else if forPath.row == 5 {
                for share in shares ?? [] {
                    valueArray.append(share.wbValuation?.eps)
                    let proportions = proportions(values: [share.wbValuation?.eps])
                    correlations.append(Calculator.valueChartCorrelation(arrays:[share.wbValuation?.eps, proportions]))
                }

            }
        }
        else if forPath.section == 5 {
            if forPath.row == 0 {
                for share in shares ?? [] {
                    valueArray.append(share.rule1Valuation?.roic)
                    let proportions = proportions(values: [share.rule1Valuation?.roic])
                    correlations.append(Calculator.valueChartCorrelation(arrays:[share.rule1Valuation?.roic, proportions]))
                }
            }
            else if forPath.row == 1 {
                for share in shares ?? [] {
                    valueArray.append(share.wbValuation?.roe)
                    let proportions = proportions(values: [share.wbValuation?.roe])
                    correlations.append(Calculator.valueChartCorrelation(arrays:[share.wbValuation?.roe, proportions]))
                }
            }
            else if forPath.row == 2 {
                for share in shares ?? [] {
                    valueArray.append(share.wbValuation?.roa)
                    let proportions = proportions(values: [share.wbValuation?.roa])
                    correlations.append(Calculator.valueChartCorrelation(arrays:[share.wbValuation?.roa, proportions]))
                }
            }
        }

        return (correlations, valueArray)
        
    }
    
    /// if sending 2 arrays returns array with proportion array 0 / array 1
    /// if sending 1 array returns the rate of growth from array element to element
    /// the rates returned are in time-ASCENDING order
    public func proportions(values: [[Double]?]?) -> [Double]? {
        
        var proportions: [Double]?
        
        if values?.count ?? 0 > 1 {
            proportions = Calculator.proportions(array1: values?.first!, array0: values?.last!) // returns in same order as sent
        }
        else {
            if let array1 = values?.first {
                proportions = array1?.growthRates()
            }
        }
        return proportions
    }

    
    /*
     tableStructure:
     
     == section 0
     0 research.buy story
     
     == section 1
     0 user rating score
     1 fundamentals score
     2 moat score
     3 GB valuation
     4 DCF Valuation
     5 intrinsic WB value
     
     == section 2
     0 PE ratios
     1 Lynch score
     2 Book value/share price
     
     == section 3
     0 ret. earnings
     1 sales
     2 net income
     3 OCF
     4 profit margin
     5 EPS
     
     == section 4
     0 ROI
     1 ROE
     2 ROA
     
     == section 5
     0 debt / net income
     1 debt / adj equity
     2 capEx
     3 SGA / revenue
     4 RD / profit growth
     
     */
    

    
}
