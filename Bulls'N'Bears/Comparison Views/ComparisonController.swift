//
//  ComparisonController.swift
//  Bulls'N'Bears
//
//  Created by aDav on 28/04/2021.
//

import UIKit

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
                                ["Ret. earnings", "Revenue", "Net income", "Op. Cash flow", "Gross profit", "EPS"],
                                ["Profit margin", "Net earnings margin"],
                                ["ROI", "ROE", "ROA"],
                                ["LT Debt / net income", "LT Debt / adj equity", "cap. exp./net income", "SGA / profit", "R&D / profit"]]
        
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
    
    func rowTexts(forPath: IndexPath) -> ([String], [UIColor]) {
        
        var texts = [String]()
        var colors = [UIColor]()
        var color = UIColor.clear

        switch forPath.section {
        case 0:
            if forPath.row == 0 {
                for share in shares ?? [] {
                    texts.append(share.research?.theBuyStory ?? "")
                    colors.append(UIColor.clear)
                }
            }
        case 1:
            if forPath.row == 0 {
                for share in  shares ?? [] {
                    var text = "-"
                    if share.userEvaluationScore > 0 {
                        text = percentFormatter0Digits.string(from: share.userEvaluationScore as NSNumber) ?? "-"
//                        color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 1, value: share.userEvaluationScore)
                    }
                    texts.append(text)
                    colors.append(color)
                }
            }
            else if forPath.row == 1 {
                for share in  shares ?? [] {
                    var text = "-"
                    if share.valueScore > 0 {
                        text = percentFormatter0Digits.string(from: share.valueScore as NSNumber) ?? "-"
//                        color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 1, value: share.valueScore)
                    }
                    texts.append(text)
                    colors.append(color)
                }
            }
            else if forPath.row == 2 {
                for share in  shares ?? [] {
                    var text = "-"
                    if let moat = share.rule1Valuation?.moatScore() {
                        text = percentFormatter0Digits.string(from: moat as NSNumber) ?? "-"
                        color = findCategoryColor(biggerIsBetter: true, consistency: moat, growth: 1.0, primaryGreenCutoff: 0.75, primaryRedCutOff: 0.5)
                    }
                    texts.append(text)
                    colors.append(color)
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
                    colors.append(color)
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
                    colors.append(color)
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
                    colors.append(color)
                }
            }
        case 2:
            if forPath.row == 0 {
                for share in  shares ?? [] {
                    var text = "-"
                    if share.peRatio != 0 {
                        text = numberFormatterWith1Digit.string(from: share.peRatio as NSNumber) ?? "-"
                        color = findCategoryColor(biggerIsBetter: true, consistency: 100.0 - share.peRatio, growth: 1.0, primaryGreenCutoff: 90, primaryRedCutOff: 60)
//                        color = GradientColorFinder.gradientColor(lowerIsGreen: true, min: 0, max: 10000, value: share.peRatio, greenCutoff: 40, redCutOff: 0)
                    }
                    texts.append(text)
                    colors.append(color)
                }
            }
            else if forPath.row == 1 {
                for share in  shares ?? [] {
                    var text = "-"
                    if share.wbValuation != nil {
                        if let ratio = share.wbValuation!.lynchRatio() {
                            text = numberFormatterWith1Digit.string(from: ratio as NSNumber) ?? "-"
                            color = findCategoryColor(biggerIsBetter: true, consistency: ratio, growth: 1.0, primaryGreenCutoff: 3.0, primaryRedCutOff: 1.0)
//                            color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 10000, value: ratio, greenCutoff: 3, redCutOff: 1)
                        }
                    }
                    texts.append(text)
                    colors.append(color)
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
                                color = findCategoryColor(biggerIsBetter: true, consistency: value1, growth: 1.0, primaryGreenCutoff: 0.8, primaryRedCutOff: 0.2)
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
                    colors.append(color)
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
                                color = UIColor.systemRed
                            }
                            else {
                                let cGrowth = Calculator.compoundGrowthRates(values: retE)
                                if let ema = cGrowth?.ema(periods: 7) {
                                    text = percentFormatter0Digits.string(from: ema as NSNumber) ?? "-"
                                    color = findCategoryColor(biggerIsBetter: true, consistency: ema, growth: 1.0, secondaryGreenCutoff: 0.15, secondaryRedCutOff: 0.0)
//                                    color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 100, value: ema, greenCutoff: 0.05, redCutOff: 0.05)
                                }
                            }
                        }
                    }
                    texts.append(text)
                    colors.append(color)
                }
            }
            else if forPath.row == 1 {
                for share in  shares ?? [] {
                    var text = "-"
                    if let values = share.wbValuation?.revenue { // MT.com row-based data are stored in time-DESCENDING order
                        if let lastRetEarnings = values.first {
                            if lastRetEarnings < 0 {
                                text = "last neg."
                                color = UIColor.systemRed
                            }
                            else {
                                if let ema = Calculator.compoundGrowthRates(values: values)?.ema(periods: 7) {
                                    text = percentFormatter0Digits.string(from: ema as NSNumber) ?? "-"
                                    color = findCategoryColor(biggerIsBetter: true, consistency: ema, growth: 1.0, secondaryGreenCutoff: 0.15, secondaryRedCutOff: 0.0)
//                                   color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 100, value: ema, greenCutoff: 0, redCutOff: 0)
                                }
                            }
                        }
                    }
                    texts.append(text)
                    colors.append(color)
                }
            }
            else if forPath.row == 2 {
                for share in  shares ?? [] {
                    var text = "-"
                    if let values = share.wbValuation?.netEarnings { // MT.com row-based data are stored in time-DESCENDING order
                        if let lastRetEarnings = values.first {
                            if lastRetEarnings < 0 {
                                text = "last neg."
                                color = UIColor.systemRed
                            }
                            else {
                                if let ema = Calculator.compoundGrowthRates(values: values)?.ema(periods: 7) {
                                    text = percentFormatter0Digits.string(from: ema as NSNumber) ?? "-"
                                    color = findCategoryColor(biggerIsBetter: true, consistency: ema, growth: 1.0, secondaryGreenCutoff: 0.15, secondaryRedCutOff: 0.0)
//                                    color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 100, value: ema, greenCutoff: 0, redCutOff: 0)
                                }
                            }
                        }
                    }
                    texts.append(text)
                    colors.append(color)
                }
            }
            else if forPath.row == 3 {
                for share in  shares ?? [] {
                    var text = "-"
                    if let values = share.wbValuation?.opCashFlow { // MT.com row-based data are stored in time-DESCENDING order
                        if let lastRetEarnings = values.first {
                            if lastRetEarnings < 0 {
                                text = "last neg."
                                color = UIColor.systemRed
                            }
                            else {
                                if let ema = Calculator.compoundGrowthRates(values: values)?.ema(periods: 7) {
                                    text = percentFormatter0Digits.string(from: ema as NSNumber) ?? "-"
                                    color = findCategoryColor(biggerIsBetter: true, consistency: ema, growth: 1.0, secondaryGreenCutoff: 0.15, secondaryRedCutOff: 0.0)
//                                    color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 40, value: ema, greenCutoff: 0.15, redCutOff: 0.0)
                                }
                            }
                        }
                    }
                    texts.append(text)
                    colors.append(color)
                }
            }
            else if forPath.row == 4 {
                for share in  shares ?? [] {
                    var text = "-"
                    if let values = share.wbValuation?.grossProfit { // MT.com row-based data are stored in time-DESCENDING order
                        if let lastRetEarnings = values.first {
                            if lastRetEarnings < 0 {
                                text = "last neg."
                                color = UIColor.systemRed
                            }
                            else {
                                if let ema = Calculator.compoundGrowthRates(values: values)?.ema(periods: 7) {
                                    text = percentFormatter0Digits.string(from: ema as NSNumber) ?? "-"
                                    color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 40, value: ema, greenCutoff: 0.0, redCutOff: 0.0)
                                }
                            }
                        }
                    }
                    texts.append(text)
                    colors.append(color)
                }
            }
            else if forPath.row == 5 {
                for share in  shares ?? [] {
                    var text = "-"
                    if let values = share.wbValuation?.eps { // MT.com row-based data are stored in time-DESCENDING order
                        if let lastRetEarnings = values.first {
                            if lastRetEarnings < 0 {
                                text = "last neg."
                                color = UIColor.systemRed
                            }
                            else {
                                if let ema = Calculator.compoundGrowthRates(values: values)?.ema(periods: 7) {
                                    text = percentFormatter0Digits.string(from: ema as NSNumber) ?? "-"
                                    color = ema > 0 ? GradientColorFinder.greenGradientColor() : GradientColorFinder.redGradientColor()
                                }
                            }
                        }
                    }
                    texts.append(text)
                    colors.append(color)
                }
            }
        default:
            texts = [String]()
            colors = [UIColor]()
        }
        
        return (texts, colors)
    }
    
    func financialsTexts(forPath: IndexPath) -> ([[String]], [UIColor])? {
        
        guard forPath.section > 2 else {
            return nil
        }
        
        var finStrings = [[String]]()
        var colors = [UIColor]()
        
        if forPath.section == 3 {
            if forPath.row == 0 {
                for share in  shares ?? [] {
                    let (texts, textColor) = singleFinancialText(values: share.wbValuation?.equityRepurchased,cutOffGreen: 0.15, cutOffRed: 0.00)
                    finStrings.append(texts)
                    colors.append(textColor)
                }
            }
            else if forPath.row == 1 {
                for share in  shares ?? [] {
                    let (texts, textColor) = singleFinancialText(values: share.wbValuation?.revenue, cutOffGreen: 0.15, cutOffRed: 0.00)
                    finStrings.append(texts)
                    colors.append(textColor)
                }
            }
            else if forPath.row == 2 {
                for share in  shares ?? [] {
                    let (texts, textColor) = singleFinancialText(values: share.wbValuation?.netEarnings,cutOffGreen: 0.15, cutOffRed: 0.00)
                    finStrings.append(texts)
                    colors.append(textColor)
                }
            }
            else if forPath.row == 3 {
                for share in  shares ?? [] {
                    let (texts, textColor) = singleFinancialText(values: share.wbValuation?.opCashFlow, cutOffGreen: 0.15, cutOffRed: 0.00)
                    finStrings.append(texts)
                    colors.append(textColor)
                }
            }
            else if forPath.row == 4 {
                for share in  shares ?? [] {
                    let (texts, textColor) = singleFinancialText(values: share.wbValuation?.grossProfit, cutOffGreen: 0.15, cutOffRed: 0.00)
                    finStrings.append(texts)
                    colors.append(textColor)
                }
            }
            else if forPath.row == 5 {
                for share in  shares ?? [] {
                    let (texts, textColor) = singleFinancialText(values: share.wbValuation?.eps, cutOffGreen: 0.15, cutOffRed: 0.0)
                    finStrings.append(texts)
                    colors.append(textColor)
                }
            }
        }
        else if forPath.section == 4 {
            if forPath.row == 0 {
                for share in  shares ?? [] {
                    let (texts, textColor) = twoFinancialsText(values0: share.wbValuation?.revenue, values1: share.wbValuation?.grossProfit, cutOffGreen: 0.05, cutOffRed: 0.0)
                    finStrings.append(texts)
                    colors.append(textColor)
                }
            }
            else if forPath.row == 1 {
                for share in  shares ?? [] {
                    let (texts, textColor) = twoFinancialsText(values0: share.wbValuation?.revenue, values1: share.wbValuation?.netEarnings, cutOffGreen: 0.05, cutOffRed: 0.0)
                    finStrings.append(texts)
                    colors.append(textColor)
                }
            }
        }
        else if forPath.section == 5 { // outgoings - positive increase = BAD
            if forPath.row == 0 {
                for share in  shares ?? [] {
                    let (texts, textColor) = singleFinancialText(values: share.rule1Valuation?.roic, cutOffGreen: 0.10, cutOffRed: 0.0)
                    finStrings.append(texts)
                    colors.append(textColor)
                }
            }
            if forPath.row == 1 {
                for share in  shares ?? [] {
                    let (texts, textColor) = singleFinancialText(values: share.wbValuation?.roe, cutOffGreen: 0.10, cutOffRed: 0.0)
                    finStrings.append(texts)
                    colors.append(textColor)
                }
            }
            if forPath.row == 2 {
                for share in  shares ?? [] {
                    let (texts, textColor) = singleFinancialText(values: share.wbValuation?.roa, cutOffGreen: 0.10, cutOffRed: 0.0)
                    finStrings.append(texts)
                    colors.append(textColor)
                }
            }
        }
        else if forPath.section == 6 {
            if forPath.row == 0 {
                for share in  shares ?? [] {
                    let (texts, textColor) = twoFinancialsText(values0: share.wbValuation?.netEarnings, values1: share.wbValuation?.debtLT, biggerIsBetter: false, cutOffGreen: 0.0, cutOffRed: 0.0)
                    finStrings.append(texts)
                    colors.append(textColor)
                }
            }
            else if forPath.row == 1 {
                for share in  shares ?? [] {
                    if let proportions = share.wbValuation?.ltDebtPerAdjEquityProportions() {
                        let (texts, textColor) = singleFinancialText(values: proportions, growthCutOffRate: 0.0, biggerIsBetter: false, cutOffGreen: 0.0, cutOffRed: 0.0)
                        finStrings.append(texts)
                        colors.append(textColor)
                    }
                }
            }
            else if forPath.row == 2 {
                for share in  shares ?? [] {
                    let (texts, textColor) = singleFinancialText(values: share.wbValuation?.capExpend, growthCutOffRate: 0.0, biggerIsBetter: false, cutOffGreen: 0.0, cutOffRed: 0.0)
                    finStrings.append(texts)
                    colors.append(textColor)
                }
            }
            else if forPath.row == 3 {
                for share in  shares ?? [] {
                    let (texts, textColor) = twoFinancialsText(values0: share.wbValuation?.grossProfit, values1: share.wbValuation?.sgaExpense, biggerIsBetter: false, cutOffGreen: 0, cutOffRed: 0.0)
                    finStrings.append(texts)
                    colors.append(textColor)
                }
            }
            else if forPath.row == 4 {
                for share in  shares ?? [] {
                    let (texts, textColor) = twoFinancialsText(values0: share.wbValuation?.grossProfit, values1: share.wbValuation?.rAndDexpense, biggerIsBetter: false, cutOffGreen: 0, cutOffRed: 0.0)
                    finStrings.append(texts)
                    colors.append(textColor)
                }
            }
        }

        return (finStrings, colors)
    }
    
    private func singleFinancialText(values: [Double]?, growthCutOffRate:Double?=nil, biggerIsBetter: Bool?=true, cutOffGreen:Double, cutOffRed:Double) -> ([String], UIColor) {
        
        var text = [String]()
        var color = UIColor.clear
                
        let consistency2 = values?.consistency(increaseIsBetter: biggerIsBetter ?? true) ?? Double()
        if let compoundGrowthRates = Calculator.compoundGrowthRates(values: values) {
            if let ema = compoundGrowthRates.ema(periods: 7) {
                text.append(percentFormatter0DigitsPositive.string(from: ema as NSNumber) ?? "-")
                color = findCategoryColor(biggerIsBetter: biggerIsBetter ?? true, consistency: consistency2, growth: ema,secondaryGreenCutoff: cutOffGreen, secondaryRedCutOff: cutOffRed)
            } else {
                text.append("-")
            }
            
            text.append(percentFormatter0Digits.string(from: consistency2 as NSNumber) ?? "-")
        }
        else {
            text = ["-","-"]
        }
                
        return (text,color)
    }
    
    /// proportions = values1 / values0
    private func twoFinancialsText(values0: [Double]?, values1:[Double]?, biggerIsBetter: Bool?=nil, cutOffGreen:Double, cutOffRed:Double) -> ([String], UIColor) {
        
        var texts = [String]()
        var color = UIColor.clear
        
        if let proportions = Calculator.proportions(array1: values1, array0: values0) {
            let consistency2 = proportions.consistency(increaseIsBetter: biggerIsBetter ?? true)

            if let compoundGrowthRates = Calculator.compoundGrowthRates(values: proportions) {
                if let ema = compoundGrowthRates.ema(periods: 7) {
                    texts.append(percentFormatter0DigitsPositive.string(from: ema as NSNumber) ?? "-")
                    color = findCategoryColor(biggerIsBetter: biggerIsBetter ?? true, consistency: consistency2, growth: ema, secondaryGreenCutoff: cutOffGreen, secondaryRedCutOff: cutOffRed)
                } else {
                    texts.append("-")

                }
                
                texts.append(percentFormatter0Digits.string(from: consistency2 as NSNumber) ?? "-")
            }
        }
        else {
            texts = ["-","-"]
        } //,"-"
        return (texts, color)
    }
    
    func findCategoryColor(biggerIsBetter: Bool, consistency: Double, growth: Double, primaryGreenCutoff: Double?=nil, primaryRedCutOff: Double?=nil, secondaryGreenCutoff: Double?=nil, secondaryRedCutOff: Double?=nil) -> UIColor {
        
        let adjustedGrowth = biggerIsBetter ? growth : growth * -1
        let growthThresholds = biggerIsBetter ? [secondaryGreenCutoff ?? 0.15, secondaryRedCutOff ?? 0.1] : [secondaryGreenCutoff ?? 0.05 , secondaryRedCutOff ?? 0.0]
        var categoryColor = UIColor.clear
        
        if consistency >= primaryGreenCutoff ?? 0.8 {
            if adjustedGrowth >= growthThresholds[0] { categoryColor = UIColor(named: "Green")! }
            else if adjustedGrowth >= growthThresholds[1] { categoryColor = UIColor.systemOrange }
            else { categoryColor = UIColor(named: "Red")! }
        }
        else if consistency >= primaryRedCutOff ?? 0.5 {
            if adjustedGrowth >= growthThresholds[1] { categoryColor = UIColor.systemOrange }
            else { categoryColor = UIColor(named: "Red")! }
        }
        else {
            categoryColor = UIColor(named: "Red")!
        }
        
        return categoryColor
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
//                    valueArray.append(share.wbValuation?.equityRepurchased)
                    let proportions = proportions(values: [share.wbValuation?.equityRepurchased])
                    let cpGrowth = Calculator.compoundGrowthRates(values: share.wbValuation?.equityRepurchased)
                    valueArray.append(cpGrowth)
                    correlations.append(Calculator.valueChartCorrelation(arrays:[share.wbValuation?.equityRepurchased, proportions]))
                }
            }
            else if forPath.row == 1 {
                for share in shares ?? [] {
//                    valueArray.append(share.wbValuation?.revenue)
                    let proportions = proportions(values: [share.wbValuation?.revenue])
                    let cpGrowth = Calculator.compoundGrowthRates(values: share.wbValuation?.revenue)
                    valueArray.append(cpGrowth)
                    correlations.append(Calculator.valueChartCorrelation(arrays:[share.wbValuation?.revenue, proportions]))
                }

            }
            else if forPath.row == 2 {
                for share in shares ?? [] {
//                    valueArray.append(share.wbValuation?.netEarnings)
                    let proportions = proportions(values: [share.wbValuation?.netEarnings])
                    let cpGrowth = Calculator.compoundGrowthRates(values: share.wbValuation?.netEarnings)
                    valueArray.append(cpGrowth)
                    correlations.append(Calculator.valueChartCorrelation(arrays:[share.wbValuation?.netEarnings, proportions]))
                }

            }
            else if forPath.row == 3 {
                for share in shares ?? [] {
//                    valueArray.append(share.wbValuation?.opCashFlow)
                    let proportions = proportions(values: [share.wbValuation?.opCashFlow])
                    let cpGrowth = Calculator.compoundGrowthRates(values: share.wbValuation?.opCashFlow)
                    valueArray.append(cpGrowth)
                    correlations.append(Calculator.valueChartCorrelation(arrays:[share.wbValuation?.opCashFlow, proportions]))
                }

            }
            else if forPath.row == 4 {
                for share in shares ?? [] {
//                    valueArray.append(share.wbValuation?.grossProfit)
                    let proportions = proportions(values: [share.wbValuation?.grossProfit])
                    let cpGrowth = Calculator.compoundGrowthRates(values: share.wbValuation?.grossProfit)
                    valueArray.append(cpGrowth)
                    correlations.append(Calculator.valueChartCorrelation(arrays:[share.wbValuation?.grossProfit, proportions]))
                }

            }
            else if forPath.row == 5 {
                for share in shares ?? [] {
//                    valueArray.append(share.wbValuation?.eps)
                    let proportions = proportions(values: [share.wbValuation?.eps])
                    let cpGrowth = Calculator.compoundGrowthRates(values: share.wbValuation?.eps)
                    valueArray.append(cpGrowth)
                    correlations.append(Calculator.valueChartCorrelation(arrays:[share.wbValuation?.eps, proportions]))
                }

            }
        }
        else if forPath.section == 4 {
            if forPath.row == 0 {
                for share in shares ?? [] {
//                    valueArray.append(share.wbValuation?.grossProfit)
                    let proportions = proportions(values: [share.wbValuation?.grossProfit, share.wbValuation?.revenue])
                    let cpGrowth = Calculator.compoundGrowthRates(values: proportions)
                    valueArray.append(cpGrowth)
                    correlations.append(Calculator.valueChartCorrelation(arrays:[proportions, proportions]))
                }
            }
            else if forPath.row == 1 {
                for share in shares ?? [] {
//                    valueArray.append(share.wbValuation?.netEarnings)
                    let proportions = proportions(values: [share.wbValuation?.netEarnings, share.wbValuation?.revenue])
                    let cpGrowth = Calculator.compoundGrowthRates(values: proportions)
                    valueArray.append(cpGrowth)
                    correlations.append(Calculator.valueChartCorrelation(arrays:[proportions, proportions]))
                }
            }
        }
        else if forPath.section == 5 {
            if forPath.row == 0 {
                for share in shares ?? [] {
//                    valueArray.append(share.rule1Valuation?.roic)
                    let proportions = proportions(values: [share.rule1Valuation?.roic])
                    let cpGrowth = Calculator.compoundGrowthRates(values: share.rule1Valuation?.roic)
                    valueArray.append(cpGrowth)
                    correlations.append(Calculator.valueChartCorrelation(arrays:[share.rule1Valuation?.roic, proportions]))
                }
            }
            else if forPath.row == 1 {
                for share in shares ?? [] {
//                    valueArray.append(share.wbValuation?.roe)
                    let proportions = proportions(values: [share.wbValuation?.roe])
                    let cpGrowth = Calculator.compoundGrowthRates(values: share.wbValuation?.roe)
                    valueArray.append(cpGrowth)
                    correlations.append(Calculator.valueChartCorrelation(arrays:[share.wbValuation?.roe, proportions]))
                }
            }
            else if forPath.row == 2 {
                for share in shares ?? [] {
//                    valueArray.append(share.wbValuation?.roa)
                    let proportions = proportions(values: [share.wbValuation?.roa])
                    let cpGrowth = Calculator.compoundGrowthRates(values: share.wbValuation?.roa)
                    valueArray.append(cpGrowth)
                    correlations.append(Calculator.valueChartCorrelation(arrays:[share.wbValuation?.roa, proportions]))
                }
            }
        }
        else if forPath.section == 6 {
            if forPath.row == 0 {
                for share in shares ?? [] {
                    let (values, _) = share.wbValuation!.longtermDebtProportion()
//                    valueArray.append(values)
                    let proportions = proportions(values: [values])
                    let cpGrowth = Calculator.compoundGrowthRates(values: values)
                    valueArray.append(cpGrowth)
                    correlations.append(Calculator.valueChartCorrelation(arrays:[values, proportions]))
                }
            }
            else if forPath.row == 1 {
                for share in shares ?? [] {
                    let values = share.wbValuation!.ltDebtPerAdjEquityProportions()
//                    valueArray.append(values)
                    let proportions = proportions(values: [values])
                    let cpGrowth = Calculator.compoundGrowthRates(values: values)
                    valueArray.append(cpGrowth)
                    correlations.append(Calculator.valueChartCorrelation(arrays:[values, proportions]))
                }
            }
            else if forPath.row == 2 {
                for share in shares ?? [] {
//                    valueArray.append(share.wbValuation?.capExpend)
                    let proportions = proportions(values: [share.wbValuation?.capExpend, share.wbValuation?.netEarnings])
                    let cpGrowth = Calculator.compoundGrowthRates(values: proportions)
                    valueArray.append(cpGrowth)
                     correlations.append(Calculator.valueChartCorrelation(arrays:[proportions, proportions]))
                }
            }
            else if forPath.row == 3 {
                for share in shares ?? [] {
//                    valueArray.append(share.wbValuation?.sgaExpense)
                    let proportions = proportions(values: [share.wbValuation?.sgaExpense, share.wbValuation?.grossProfit])
                    let cpGrowth = Calculator.compoundGrowthRates(values: proportions)
                    valueArray.append(cpGrowth)
                    correlations.append(Calculator.valueChartCorrelation(arrays:[cpGrowth, proportions]))
                }
            }
            else if forPath.row == 3 {
                for share in shares ?? [] {
                    let proportions = proportions(values: [share.wbValuation?.rAndDexpense, share.wbValuation?.grossProfit])
                    let cpGrowth = Calculator.compoundGrowthRates(values: proportions)
                    valueArray.append(cpGrowth)
                    correlations.append(Calculator.valueChartCorrelation(arrays:[proportions, proportions]))
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
