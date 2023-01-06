//
//  WBValuationController.swift
//  Bulls'N'Bears
//
//  Created by aDav on 16/02/2021.
//

import Foundation
import CoreData
import WebKit

struct WBVParameters {
    // when adding new parameter check impact in WBVValuationController and WBVValuationTVC and ValueListTVC
    // also adapt 'higherIsBetter' parameter in UserEvaluation
    // careful - the '/' characters are used in ValueListVC to determine the charts to show
    let revenueGrowth = "Revenue with YoY growth"
    let earnigsGrowth = "Net earnings with YoY growth"
    let retEarningsGrowth = "Ret. earnings with YoY growth"
    let epsGrowth = "EPS with YoY growth"
    let incomeOfRevenueGrowth = "[Net income / revenue] with YoY growth"
    let profitOfRevenueGrowth = "[Profit / revenue] with YoY growth"
    let capExpendOfEarningsGrowth = "[Cap. expend / net income] with YoY growth"
    let earningsToPERratio = "[Earnings / pe ratio] with YoY growth"
    let debtOfIncomeGrowth = "[LT debt / net income] with YoY growth"
    let opCashFlowGrowth = "Op. cash flow with YoY growth"
    let roiGrowth = "Return on Investment"
    let roeGrowth = "Return on Equity"
    let roaGrowth = "Return on Assets"
    let debtOfEqAndRtEarningsGrowth = "[LT debt / adj. equity] with YoY growth"
    let sgaOfProfitGrowth = "[SGA / profit] with YoY growth"
    let rAdOfProfitGrowth = "[R&D / profit]  with YoY growth"
    
    func allParameters() -> [String] {
        return [earnigsGrowth,retEarningsGrowth, epsGrowth, incomeOfRevenueGrowth, profitOfRevenueGrowth, capExpendOfEarningsGrowth, debtOfIncomeGrowth, roeGrowth, roaGrowth ,debtOfEqAndRtEarningsGrowth, sgaOfProfitGrowth ,rAdOfProfitGrowth]
    }
    
    func structuredTitlesParameters() -> [[[String]]] {
        return [firstSection(), secondSection(), thirdSection()]
    }
        
    func firstSection() -> [[String]] {
        return [[revenueGrowth],
                [earnigsGrowth],
                [retEarningsGrowth],
                [epsGrowth],
                [profitOfRevenueGrowth],
                [opCashFlowGrowth]]
    }
    
    func secondSection() -> [[String]] {
        return [[roiGrowth],
                [roeGrowth],
                [roaGrowth],
        ]
    }
    
    func thirdSection() -> [[String]] {
        return [[capExpendOfEarningsGrowth],
                [debtOfIncomeGrowth],
                [sgaOfProfitGrowth],
                [rAdOfProfitGrowth]]
    }

    /// all other WBVParameters have highIsBetter
    func higherIsWorseParameters() -> [String] {
        return [debtOfIncomeGrowth, debtOfEqAndRtEarningsGrowth, sgaOfProfitGrowth, rAdOfProfitGrowth]
    }
    
    func isHigherBetter(for parameter: String) -> Bool {
        
        for term in higherIsWorseParameters() {
            if parameter == term {
                return false
            }
        }

        return true
    }
}



class WBValuationController: NSObject, WKUIDelegate, WKNavigationDelegate {
    
    var sectionTitles = ["Key financials","Earnings & incomings", "Returns", "Outgoings & debt"]
    var sectionSubTitles: [String?] = [nil,"Trend & growth EMA","Trend & growth EMA","Trend & Ratio"]
    var rowTitles: [[String]]!
    var share: Share!
    var wbValuation: WBValuation?
    var valuationID: NSManagedObjectID?
    var progressDelegate: ProgressViewDelegate?
    var downloadTasks = 0
    var downloadTasksCompleted = 0
    var downloadErrors = [String]()
    var valueListChartLegendTitles = [
        [["Revenue"],
         ["Net income"],
         ["Ret. earnings"],
         ["EPS"],
         ["Profit margin"],
         ["OpCash flow"]
        ],
        [
            ["ROI"],
         ["ROE"],
         ["ROA"],
        ],
        [["capExpend/earnings"],
         ["LT debt/earnings"],
         ["SGA /profit"],
         ["R&D /profit"]
        ]]
    var wbvParameters = WBVParameters()
    var downloadTask: Task<Any?,Error>?
    
    var dcfValuation: DCFValuation?
    var r1Valuation: Rule1Valuation?
    
    //MARK: - init

    init(share: Share, progressDelegate: ProgressViewDelegate) {
        
        super.init()
        
        self.share = share
        self.progressDelegate = progressDelegate
        
        // 1 WBValuation
        if let valuation = share.wbValuation {
            self.wbValuation = valuation
            self.valuationID = valuation.objectID
        }
        else if let valuation = WBValuationController.returnWBValuations(share: share) {
            // find old disconnected valuations persisted after share was deleted
            self.wbValuation = valuation
            self.valuationID = valuation.objectID

        }
        else {
            self.wbValuation = WBValuationController.createWBValuation(share: share)
            // when deleting a WBValuation this doe NOT delete related UserEvaluations
            // these are linked to a company (symbol) as well as wbValuation parameters
            // when (re-)creating a WBValuation check whether there are any old userEvaluations
            // and if so re-add the relationships to this WBValuation via parameters
            self.valuationID = wbValuation?.objectID

            if let ratings = WBValuationController.allUserRatings(for: share.symbol!) {
                if ratings.count > 0 {
                    let set = NSSet(array: ratings)
                    wbValuation?.addToUserEvaluations(set)
                }
            }
        }
        
        // 2 DCF Valuation
        if let valuation = share.dcfValuation {
            self.dcfValuation = valuation
        }
        else if let valuation = CombinedValuationController.returnDCFValuations(company: share.symbol!) {
            // any orphan valuation belonging to this company left after deleting share
            self.dcfValuation = valuation
            share.dcfValuation = dcfValuation
            wbValuation?.capExpend = valuation.capExpend
        }
        else {
            self.dcfValuation = CombinedValuationController.createDCFValuation(company: share.symbol!)
            share.dcfValuation = self.dcfValuation
        }

        // 3 Rule1 Valuation
        
        if let valuation = share.rule1Valuation {
            self.r1Valuation = valuation
        }
        else if let valuation = CombinedValuationController.returnR1Valuations(company: share.symbol!) {
            // any orphan valuation belonging to this company left after deleting share
            share.rule1Valuation = valuation
            self.r1Valuation = valuation
        }
        else {
            self.r1Valuation = CombinedValuationController.createR1Valuation(company: share.symbol!)
            share.rule1Valuation = self.r1Valuation
        }

                
        rowTitles = returnRowTitles()
    }
    
    //MARK: - class functions
    
    static func returnWBValuations(share: Share) -> WBValuation? {
        
        var valuations: [WBValuation]?
        
        let fetchRequest = NSFetchRequest<WBValuation>(entityName: "WBValuation")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: false)]
        fetchRequest.returnsObjectsAsFaults = false
        if let validName = share.symbol {
            let predicate = NSPredicate(format: "company == %@", argumentArray: [validName])
            fetchRequest.predicate = predicate
        }
        
        do {
            valuations = try fetchRequest.execute()
            } catch let error {
                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "error fetching WBValuation")
        }
        
        if valuations?.count ?? 0 > 1 {
            for i in 1..<valuations!.count {
                valuations![i].delete()
            }
        }

        return valuations?.first
    }
    

    static func createWBValuation(share: Share) -> WBValuation? {
        
        if let existingValuation = returnWBValuations(share: share) {
            existingValuation.delete()
        }
        
        let newValuation:WBValuation? = {
            NSEntityDescription.insertNewObject(forEntityName: "WBValuation", into: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext) as? WBValuation
        }()
        newValuation?.company = share.symbol!
        share.wbValuation = newValuation
        
        do {
            try  (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.save()
        } catch {
            let error = error
            ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "error creating and saving Rule1Valuation")
        }

        return newValuation
    }
    
    static func allUserRatings(for symbol: String?) -> [UserEvaluation]? {
        
        var ratings: [UserEvaluation]?
        
        let fetchRequest = NSFetchRequest<UserEvaluation>(entityName: "UserEvaluation")
        fetchRequest.returnsObjectsAsFaults = false
        if let validName = symbol {
            let predicate = NSPredicate(format: "stock == %@", argumentArray: [validName])
            fetchRequest.predicate = predicate
        }
        
        do {
            ratings = try fetchRequest.execute()
            } catch let error {
                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "error fetching UserEvaluations")
        }

        return ratings
    }
    
    func updateData() {
        
        guard let validID = valuationID else {
            ErrorController.addInternalError(errorLocation: "CombinedValuationController.checkValuation", systemError: nil, errorInfo: "controller has no valid NSManagedObjectID to fetch valuation")
            return
        }
        
        self.wbValuation = ((UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.object(with: validID) as? WBValuation)!
    }

    
    //MARK: - TVC controller functions
    
    public func latestDataDate() -> Date? {
        return wbValuation?.latestDataDate
    }

    public func valuationDate() -> Date? {
        return wbValuation?.date
    }
    
    public func rowTitle(path: IndexPath) -> String {
        return rowTitles[path.section][path.row]
    }
    
    public func sectionHeaderText(section: Int) -> String {
        
        return sectionTitles[section]
        
    }
    
    public func sectionSubHeaderText(section: Int) -> String? {
        
        if let date = wbValuation?.date {
            sectionSubTitles[0] =  "Valuation figures from " + dateFormatter.string(from: date)
        }
        return sectionSubTitles[section]
    }


    public func value$(path: IndexPath) -> (String, UIColor?, [String]?) {
        
        guard wbValuation != nil else {
            return ("--", nil, ["no valuation"])
        }
        
        var errors: [String]?
        var color: UIColor?
        var emaPeriod = (UserDefaults.standard.value(forKey: userDefaultTerms.emaPeriodAnnualData) as? Int) ?? 7
        
        if path.section == 0 {
            var value$: String?

            switch path.row {
            case 0:
            //Moat
                if let r1v = share.rule1Valuation {
                    if let moat = r1v.moatScore() {
                        value$ = percentFormatter0Digits.string(from: moat as NSNumber) ?? "-"
                        color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 100, value: moat, greenCutoff: 0.7, redCutOff: 0.5)
                        
                        if let trendData = share.trendValues(trendName: .moatScore) {
                            let pastData = trendData.filter { datedValue in
                                if datedValue.date < r1v.creationDate! { return true }
                                else { return false }
                            }
                            if let mostRecent = pastData.first {
                                value$! += " (" + percentFormatter0Digits.string(from: mostRecent.value as NSNumber)! + ")"
                            }
                        }
                        let moatParams = r1v.r1MoatParameterCount() ?? 0
                        
                        if moatParams < 30 {
                            if errors == nil {
                                errors = ["Only \(moatParams)/50 numbers; reliability is limited"]
                            } else {
                                errors?.append("Only \(moatParams)/50 numbers; reliability is limited")
                            }
                        }

                    }
                }
            case 1:
            // PE ratio
                if share.peRatio != Double() {
                    value$ = numberFormatter2Decimals.string(from: share.peRatio as NSNumber)
                    color = GradientColorFinder.gradientColor(lowerIsGreen: true, min: 0, max: 40, value: share.peRatio, greenCutoff: 10.0, redCutOff: 40.0)
                }
                let sixMonthsAgo = Date().addingTimeInterval(-183*24*3600)
                let twoYearsAgo = sixMonthsAgo.addingTimeInterval(-2*365*24*3600)
                if let (min, _, max) = wbValuation?.minMeanMaxPER(from: twoYearsAgo, to: sixMonthsAgo) {
                    let minMAxValue$ = " (" + numberFormatterNoFraction.string(from: min as NSNumber)! + " - " + numberFormatterNoFraction.string(from: max as NSNumber)! + ")"
                    value$?.append(minMAxValue$)
                }
                
            case 2:
            // BVPSP
                if let values = wbValuation!.bookValuePerPrice() {
                    value$ = "-"
                    var t1$:String?
                    var t2$:String?
                    if let value1 = values[0] {
                        t1$ = percentFormatter0Digits.string(from: value1 as NSNumber) ?? ""
                    }
                    if let value2 = values[1] {
                        t2$ = currencyFormatterNoGapWithPence.string(from: value2 as NSNumber) ?? ""
                    }

                    
                    if t1$ != nil && t2$ != nil {
                        value$ = t1$! + " (" + t2$! + ")"
                    }
                    else {
                        value$ = (t1$ ?? t2$) ?? "-"
                    }
                    
                }
            case 3:
            // Lynch ratio
                if let ratio = wbValuation!.lynchRatio() {
                    value$ = numberFormatterWith1Digit.string(from: ratio as NSNumber) ?? "-"
                    color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 10, value: ratio, greenCutoff: 2.0, redCutOff: 1.0)
                    
                    if let trendData = share.trendValues(trendName: .lynchScore) {
                        let pastData = trendData.filter { datedValue in
                            if datedValue.date < wbValuation!.date! { return true }
                            else { return false }
                        }
                        if let mostRecent = pastData.first {
                            value$! += " (" + numberFormatterWith1Digit.string(from: mostRecent.value as NSNumber)! + ")"
                        }
                    }

                }
            case 4:
            // Return 10/3 years
                value$ = "-/-"
                var v10$ = String()
                var v3$ = String()
                if share.return10y != Double() {
                    v10$ = (numberFormatter2Decimals.string(from: share.return10y as NSNumber) ?? "-") + "x"
                }
                if share.return3y != Double() {
                    v3$ = (numberFormatter2Decimals.string(from: share.return3y as NSNumber) ?? "-") + "x"
                }
                value$ = v10$ + "/" + v3$
            case 5:
            // beta
                if share.beta != Double() {
                    value$ = numberFormatter2Decimals.string(from: share.beta as NSNumber)
                }
            case 6:
            // R1 Price
                if let r1v = share.rule1Valuation {
                    let (stickerprice, es) = r1v.stickerPrice()
                    if let sp =  stickerprice {
                        value$ = currencyFormatterNoGapWithPence.string(from: sp as NSNumber)
                        errors = es
                    }
                    
                    if let trendData = share.trendValues(trendName: .stickerPrice) {
                        let pastData = trendData.filter { datedValue in
                            if datedValue.date < r1v.creationDate! { return true }
                            else { return false }
                        }
                        if let mostRecent = pastData.first {
                            if value$ == nil {
                                value$ = " (" + currencyFormatterNoGapWithPence.string(from: mostRecent.value as NSNumber)! + ")"
                            } else {
                                value$! += " (" + currencyFormatterNoGapWithPence.string(from: mostRecent.value as NSNumber)! + ")"
                            }
                        }
                    }

                }
            case 7:
            // DCF Price
                if let dcfv = share.dcfValuation {
                    let (price,es) = dcfv.returnIValue()
                    if let iv = price {
                        value$ = currencyFormatterGapWithPence.string(from: iv as NSNumber)
                        errors = es
                    }
                    
                    if let trendData = share.trendValues(trendName: .dCFValue) {
                        let pastData = trendData.filter { datedValue in
                            if datedValue.date < dcfv.creationDate! { return true }
                            else { return false }
                        }
                        if let mostRecent = pastData.first {
                            value$! += " (" + currencyFormatterNoGapWithPence.string(from: mostRecent.value as NSNumber)! + ")"
                        }
                    }

                }
            case 8:
            // WB intrinsic value
                if share.peRatio != Double() {

                    let (valid, es$) = wbValuation!.ivalue()
                    errors = es$
                    if valid != nil {
                        value$ = currencyFormatterGapWithPence.string(from: valid! as NSNumber)
                    }
                    
                    if let trendData = share.trendValues(trendName: .intrinsicValue) {
                        let pastData = trendData.filter { datedValue in
                            if datedValue.date < wbValuation!.date! { return true }
                            else { return false }
                        }
                        if let mostRecent = pastData.first {
                            value$! += " (" + currencyFormatterNoGapWithPence.string(from: mostRecent.value as NSNumber)! + ")"
                        }
                    }

                }
            default:
                ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "undefined row in path \(path)")
            }
            
            return (value$ ?? "no value", color, errors)
        }
        else if path.section == 1 {
            
            var value$ = "-"
            switch path.row {
            case 0:
            // Revenue
            
                let sales = wbValuation?.revenue
                if let growth = Calculator.growthRatesYoY(values: sales) {
                    if let growthEMA = growth.ema(periods: emaPeriod) {
                        value$ = percentFormatter0DigitsPositive.string(from: growthEMA as NSNumber) ?? "-"
                        color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 100, value: growthEMA, greenCutoff: 0, redCutOff: 0)

                    }
                }
                return (value$, color, errors)
                
            case 1:
            // net income
                
                let netIncome = wbValuation?.netEarnings
                if let growth = Calculator.growthRatesYoY(values: netIncome) {
                    if let growthEMA = growth.ema(periods: emaPeriod) {
                        value$ = percentFormatter0DigitsPositive.string(from: growthEMA as NSNumber) ?? "-"
                        color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 100, value: growthEMA, greenCutoff: 0, redCutOff: 0)

                    }
                }
                return (value$, color, errors)
                
            case 2:
            // Ret. earnings
                let retEarningsGrowths = Calculator.growthRatesYoY(values: wbValuation?.equityRepurchased)// valuation?.equityRepurchased?.growthRates()
                
                if let meanGrowth = retEarningsGrowths?.ema(periods: emaPeriod) {
                    value$ = percentFormatter0DigitsPositive.string(from: meanGrowth as NSNumber) ?? "-"
                    color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 100, value: meanGrowth, greenCutoff: 0.05, redCutOff: 0.05)
                }

                return (value$, color, errors)

            case 3:
                // EPS
                if let growthRatesMean = Calculator.growthRatesYoY(values: wbValuation!.eps)?.ema(periods: emaPeriod) {
                    value$ = percentFormatter0DigitsPositive.string(from: growthRatesMean as NSNumber) ?? "-"
                    color = growthRatesMean > 0 ? GradientColorFinder.greenGradientColor() : GradientColorFinder.redGradientColor()
                }

                return (value$,color,errors)

           case 4:
            // profit margin
                let (margins, es$) = wbValuation!.grossProfitMargins()
                errors = es$
                if let averageMargin = margins.ema(periods: emaPeriod) { //weightedMean()
                    value$ = percentFormatter0Digits.string(from: averageMargin as NSNumber) ?? "-"
                    color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 40, value: averageMargin, greenCutoff: 0.4, redCutOff: 0.2)
                }
                return (value$,color,errors)
            case 5:
            // op. cash flow
                let fcfGrowth = Calculator.growthRatesYoY(values: wbValuation!.opCashFlow)
                if let meanGrowth = fcfGrowth?.ema(periods: emaPeriod) {
                    value$ = percentFormatter0DigitsPositive.string(from: meanGrowth as NSNumber) ?? "-"
                    color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 40, value: meanGrowth, greenCutoff: 0.15, redCutOff: 0.0)
                }
                return (value$, color, errors)
            default:
                ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "undefined row in path \(path)")
            }
        }
        else if path.section == 2 {
            
            var value$ = "-"
            switch path.row {
            case 0:
            // ROI
                if let roic = wbValuation!.share!.rule1Valuation?.roic {
                    let roiGrowths = Calculator.growthRatesYoY(values: roic)
                    if roiGrowths?.count ?? 10 < emaPeriod {
                        emaPeriod = roiGrowths?.count ?? 0
                    }
                    if let meanGrowth = roiGrowths?.ema(periods: emaPeriod) {
                        value$ = percentFormatter0DigitsPositive.string(from: meanGrowth as NSNumber) ?? "-"
                        color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 100, value: meanGrowth, greenCutoff: 0.3, redCutOff: 0.1)
                    } else {
                        if errors == nil {
                            errors = ["Can't calculate ROI EMA; maybe not enough years"]
                        } else {
                            errors?.append("Can't calculate ROI EMA; maybe not enough years")
                        }
                    }
                    
                    return (value$, color, errors)
                }
            case 1:
            // ROE
                let roeGrowths = Calculator.growthRatesYoY(values: wbValuation!.roe)
                if let meanGrowth = roeGrowths?.ema(periods: emaPeriod) {
                    value$ = percentFormatter0DigitsPositive.string(from: meanGrowth as NSNumber) ?? "-"
                    color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 100, value: meanGrowth, greenCutoff: 0.3, redCutOff: 0.1)
                }

                return (value$, color, errors)


            case 2:
            // ROA
                let roaGrowths = Calculator.growthRatesYoY(values: wbValuation!.roa)

                if let meanGrowth = roaGrowths?.ema(periods: emaPeriod) {
                    value$ = percentFormatter0DigitsPositive.string(from: meanGrowth as NSNumber) ?? "-"
                }

                return (value$, color, errors)

            default:
                ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "undefined row in path \(path)")

            }
        }
        else if path.section == 3 {
            
            var value$ = "-"
            switch path.row {
            case 0:
            // cap expend / earnings
            
                if let sumDiv = wbValuation!.netEarnings?.reduce(0, +) {
                    // use 10 y sums / averages, not ema according to Book Ch 51
                    if let sumDenom = wbValuation!.capExpend?.reduce(0, +) {
                        let tenYAverages = abs(sumDenom / sumDiv)
                        value$ = percentFormatter0Digits.string(from: tenYAverages as NSNumber) ?? "-"
                        color = GradientColorFinder.gradientColor(lowerIsGreen: true, min: 0, max: 1, value: tenYAverages, greenCutoff: 0.25, redCutOff: 0.5)
                    }
                }
                
                return (value$,color,errors)

            case 1:
            // Lt debt / net income
                let (proportions, es$) = wbValuation!.longtermDebtProportion()
                errors = es$
                if let average = proportions.ema(periods: emaPeriod) {
                    value$ = percentFormatter0Digits.string(from: average as NSNumber) ?? "-"
                    color = GradientColorFinder.gradientColor(lowerIsGreen: true, min: 0, max: 100, value: average, greenCutoff: 3.0, redCutOff: 4.0)
                }

                return (value$, color, errors)
 
            case 2:
            // SGA / profit
                let (proportions, es$) = wbValuation!.sgaProportion()
                errors = es$
                if let average = proportions.ema(periods: emaPeriod) {
                    value$ = percentFormatter0Digits.string(from: average as NSNumber) ?? "-"
                    color = GradientColorFinder.gradientColor(lowerIsGreen: true, min: 0, max: 40, value: average, greenCutoff: 0.3, redCutOff: 1.0)
                }
                return (value$, color, errors)

            case 3:
            // R&D / profit
                let (proportions, es$) = wbValuation!.rAndDProportion()
                errors = es$
                if let average = proportions.ema(periods: emaPeriod) {
                    value$ = percentFormatter0Digits.string(from: average as NSNumber) ?? "-"
                }
                return (value$, nil, errors)

            default:
                ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "undefined row in path \(path)")
            }
        }
        
        return ("no value", color, nil)
        
    }
    
    /// if sending 2 arrays returns array with proportion array 0 / array 1
    /// if sending 1 array returns the element to element (year-on-year) rate of growth
    /// the rates returned are in same order as sent
    public func valueListTVCProportions(values: [[Double]?]?) -> [Double]? {
        
        var proportions: [Double]?
        
        if values?.count ?? 0 > 1 {
            proportions = Calculator.proportions(array1: values?.first!, array0: values?.last!) // returns in same order as sent
        }
        else {
            if let array1 = values?.first {
//                proportions = Calculator.compoundGrowthRates(values: array1)
                proportions = Calculator.growthRatesYoY(values: array1) // returns in same order as sent
            }
        }
        return proportions
    }
    
    // MARK: - internal functions
    
    private func returnRowTitles() -> [[String]] {
        // careful when changing these - terms and order are linked to WBVParameters() in public vars
        // and used in identifying UserEvaluation.wbvParameter via 'userEvaluation(for indexpath)' below
        return [["Moat", "P/E ratio", "BVPS/price","Lynch ratio", "Return (10/3y)" ,"beta","R1 price","DCF Price", "intr. value (10y)"],
                ["Revenue", "Net income", "Ret. earnings", "EPS", "Profit margin", "OpCash flow"],
                ["ROI","ROE", "ROA"],
                ["CapEx/earnings", "LT Debt/earnings", "SGA /profit", "R&D /profit"]
        ]
    }
        
    // MARK: - Data download functions
        
    /// MUST be called  on main thread
    func downloadWBValuationData() {
                     
        let symbol = share.symbol
        let shortName = share.name_short
        let wbValuationID = wbValuation?.objectID
        let dcfValuationID = dcfValuation?.objectID
        let r1ValuationID = r1Valuation?.objectID
        let shareID = share.objectID
        
        downloadTask = Task.init(priority: .background) {
            
            do {
                try await WebPageScraper2.keyratioDownloadAndSave(shareSymbol: symbol, shortName: shortName, shareID: shareID)
                try Task.checkCancellation()
                if let validID = wbValuationID {
                    progressDelegate?.allTasks += 1
                    // non-US stocks
                    if symbol?.contains(".") ?? false {
                        
                        try await WebPageScraper2.downloadAnalyseSaveWBValuationDataFromYahoo(shareSymbol: symbol, valuationID: validID, downloadRedirectDelegate: self)
                        
                    }
                    // US stocks
                    else {
                        try await WebPageScraper2.downloadAnalyseSaveWBValuationDataFromMT(shareSymbol: symbol, shortName: shortName, valuationID: validID, downloadRedirectDelegate: self)
                        
                        progressDelegate?.taskCompleted()
                    }
                }
                try Task.checkCancellation()
                
                if r1ValuationID != nil {
                    progressDelegate?.allTasks += 1

                    try await WebPageScraper2.r1DataDownloadAndSave(shareSymbol: symbol, shortName: shortName, valuationID: r1ValuationID!, progressDelegate: nil, downloadRedirectDelegate: self)
                    
                    progressDelegate?.taskCompleted()
                }
                try Task.checkCancellation()
                if dcfValuationID != nil {
                    progressDelegate?.allTasks += 1
                    try await WebPageScraper2.dcfDataDownloadAndSave(shareSymbol: symbol, valuationID: dcfValuationID!, progressDelegate: nil)
                    
                    progressDelegate?.taskCompleted()
                }
                try Task.checkCancellation()

            } catch let error {
                progressDelegate?.downloadError(error: error.localizedDescription)
            }
            
            NotificationCenter.default.removeObserver(self)
            progressDelegate?.downloadComplete()
            return nil
        }

    }
    
    public func stopDownload() {
        NotificationCenter.default.removeObserver(self)
        downloadTask?.cancel()
    }
    
    /// searches for stored evaluation related to controller.wbvValuation with specified wbvParameter
    /// if none is found it returns a new UserEvaluation object linked to the controller.wbvValuation with specified wbvParameter
    func returnUserEvaluation(for parameter: String) -> UserEvaluation? {
        
        let storedEvaluations = wbValuation?.userEvaluations
        if storedEvaluations?.count ?? 0 != 0 {
            
            for element in storedEvaluations! {
                if let evaluation = element as? UserEvaluation {
                    if evaluation.wbvParameter == parameter { return evaluation }
                }
            }
        }

        return addUserEvaluation(for: parameter)
    }
    
    /// for use in WBValuationTVC.cellForRow function
    func userEvaluation(for indexPath: IndexPath) -> UserEvaluation? {
        
        guard indexPath.section > 0 else {
            return nil
        }
        
        let parameters = WBVParameters().structuredTitlesParameters()
        
        guard indexPath.section <= parameters.count  else {
            return nil
        }
        
        let parameter = parameters[indexPath.section-1][indexPath.row].first!
        
        let storedEvaluations = wbValuation?.userEvaluations
        if storedEvaluations?.count ?? 0 != 0 {
            
            for element in storedEvaluations! {
                if let evaluation = element as? UserEvaluation {
                    if evaluation.wbvParameter == parameter { return evaluation }
                }
            }
        }
        
        return nil
    }
    
    func addUserEvaluation(for parameter: String) -> UserEvaluation? {
        
        guard let newValuation = {
            NSEntityDescription.insertNewObject(forEntityName: "UserEvaluation", into: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext) as? UserEvaluation
        }() else { return nil }
         
        newValuation.stock = share.symbol
        newValuation.wbvParameter = parameter
        wbValuation?.addToUserEvaluations(newValuation)
        
        do {
            try  (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.save()
        } catch {
            let error = error
            ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "error creating and saving Rule1Valuation")
        }

        return newValuation

    }
    
}

extension WBValuationController: RatingButtonDelegate, TextEntryCellDelegate {
    
    func userEnteredNotes(notes: String?, parameter: String) {
        if let valid = notes {
            
            guard !valid.starts(with: "Enter your notes here") else {
                return
            }
            
            for element in wbValuation?.userEvaluations ?? [] {
                if let evaluation = element as? UserEvaluation {
                    if evaluation.wbvParameter == parameter {
                        evaluation.comment = valid
                        evaluation.date = Date()
                        evaluation.save()
                    }
                }
            }
        }
    }
        
    func updateRating(rating: Int, parameter: String) {
        
        for element in wbValuation?.userEvaluations ?? [] {
            if let evaluation = element as? UserEvaluation {
                if evaluation.wbvParameter == parameter {
                    evaluation.rating = Int16(rating)
                    evaluation.date = Date()
                    evaluation.save()
                }
            }
        }
    }
    
 }

extension WBValuationController: DownloadRedirectionDelegate {
    
    @objc
    func awaitingRedirection(notification: Notification) {
        
        NotificationCenter.default.removeObserver(self)
        
        if let request = notification.object as? URLRequest {
            if let url = request.url {
                var components = url.pathComponents.dropLast()
                if let component = components.last {
                    let mtShortName = String(component)
                    components = components.dropLast()
                    if let symbolComponent = components.last {
                        let symbol = String(symbolComponent)
                        
                        DispatchQueue.main.async {
                            if self.share.symbol == symbol {
                                self.share.name_short = mtShortName
                                do {
                                    try self.share.managedObjectContext?.save()
                                } catch let error {
                                    ErrorController.addInternalError(errorLocation: "StocksController2.awaitingRedirection", systemError: error, errorInfo: "couldn't save \(symbol) in it's MOC after downlaod re-direction")
                                }
                                
                                if let info = notification.userInfo as? [String:Any] {
                                    if let task = info["task"] as? DownloadTask {
                                        switch task {
                                        case .epsPER:
                                            print("WBValuationController: redirect for \(symbol) epsPER task recevied")
                                        case .test:
                                            print("WBValuationController: redirect for \(symbol) test task recevied")
                                        case .wbValuation:
                                            print("WBValuationController: redirect for \(symbol) wbValuation task recevied")
                                            self.downloadWBValuationData()
                                        case .r1Valuation:
                                            print("WBValuationController: redirect for \(symbol) r1V task recevied")
                                        case .qEPS:
                                            print("WBValuationController: redirect for \(symbol) qEPS task received")
                                        case .healthData:
                                            print("FinHealthController: redirect for \(symbol) healthData task received")

                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? {
           
        print("WBValuationController received redirection method call to \(request.url!)")
        let object = request
        let notification = Notification(name: Notification.Name(rawValue: "Redirection"), object: object, userInfo: nil)
        NotificationCenter.default.post(notification)

        return nil
    }

}


