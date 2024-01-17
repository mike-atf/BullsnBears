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
    let revenueGrowth = "Revenue and it's growth"
    let earnigsGrowth = "Net earnings and it's  growth"
    let retEarningsGrowth = "Ret. earnings and it's  growth"
    let epsGrowth = "EPS and it's growth"
    let incomeOfRevenueGrowth = "[Net income / revenue] and it's growth"
    let profitOfRevenueGrowth = "[Profit / revenue] and it's growth"
    let capExpendOfEarningsGrowth = "[Cap. expend / net income]and it's growth"
    let earningsToPERratio = "[Earnings / pe ratio] and it's growth"
    let debtOfIncomeGrowth = "[LT debt / net income] and it's growth"
    let opCashFlowGrowth = "Op. cash flow and it's growth"
    let roiGrowth = "Return on Investment and it's growth"
    let roeGrowth = "Return on Equity and it's growth"
    let roaGrowth = "Return on Assets and it's growth"
    let debtOfEqAndRtEarningsGrowth = "[LT debt / adj. equity] and it's growth"
    let sgaOfProfitGrowth = "[SGA / profit] and it's growth"
    let rAdOfProfitGrowth = "[R&D / profit]  wand it's growth"
    
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
    var sectionSubTitles: [String?] = [nil,"Trend & growth EMA","Trend & Prop >10%","Trend & Ratio"]
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
    var viewController: WBValuationTVC!
    var webViewDownloader: WebViewDownloader?
    
    //MARK: - init

    init(share: Share, progressDelegate: ProgressViewDelegate, viewController: WBValuationTVC) {
        
        super.init()
        
        self.viewController = viewController
        self.share = share
        self.progressDelegate = progressDelegate
        
        wbValuation = share.wbValuation ?? WBValuation(context: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)
        wbValuation?.share = share
        
        r1Valuation = share.rule1Valuation ?? Rule1Valuation(context: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)
        r1Valuation?.share = share
        
        dcfValuation = share.dcfValuation ?? DCFValuation(context: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)
        dcfValuation?.share = share
        
        // 1 WBValuation
//        if let valuation = share.wbValuation {
//            self.wbValuation = valuation
//            self.valuationID = valuation.objectID
//        }
//        else if let valuation = WBValuationController.returnWBValuations(share: share) {
//            // find old disconnected valuations persisted after share was deleted
//            self.wbValuation = valuation
//            self.valuationID = valuation.objectID
//
//        }
//        else {
//            self.wbValuation = WBValuationController.createWBValuation(share: share)
//            // when deleting a WBValuation this doe NOT delete related UserEvaluations
//            // these are linked to a company (symbol) as well as wbValuation parameters
//            // when (re-)creating a WBValuation check whether there are any old userEvaluations
//            // and if so re-add the relationships to this WBValuation via parameters
//            self.valuationID = wbValuation?.objectID
//
//            if let ratings = WBValuationController.allUserRatings(for: share.symbol!) {
//                if ratings.count > 0 {
//                    let set = NSSet(array: ratings)
//                    wbValuation?.addToUserEvaluations(set)
//                }
//            }
//        }
        
        // 2 DCF Valuation
//        if let valuation = share.dcfValuation {
//            self.dcfValuation = valuation
//        }
//        else if let valuation = CombinedValuationController.returnDCFValuations(company: share.symbol!) {
//            // any orphan valuation belonging to this company left after deleting share
//            self.dcfValuation = valuation
//            share.dcfValuation = dcfValuation
//            wbValuation?.capExpend = valuation.capExpend
//        }
//        else {
//            self.dcfValuation = CombinedValuationController.createDCFValuation(company: share.symbol!)
//            share.dcfValuation = self.dcfValuation
//        }

        // 3 Rule1 Valuation
        
//        if let valuation = share.rule1Valuation {
//            self.r1Valuation = valuation
//        }
//        else if let valuation = CombinedValuationController.returnR1Valuations(company: share.symbol!) {
//            // any orphan valuation belonging to this company left after deleting share
//            share.rule1Valuation = valuation
//            self.r1Valuation = valuation
//        }
//        else {
//            self.r1Valuation = CombinedValuationController.createR1Valuation(company: share.symbol!)
//            share.rule1Valuation = self.r1Valuation
//        }

                
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
//        newValuation?.company = share.symbol!
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
    
//    func updateData() {
//        
//        guard let validID = valuationID else {
//            ErrorController.addInternalError(errorLocation: "CombinedValuationController.checkValuation", systemError: nil, errorInfo: "controller has no valid NSManagedObjectID to fetch valuation")
//            return
//        }
//        
//        self.wbValuation = ((UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.object(with: validID) as? WBValuation)!
//    }

    
    //MARK: - TVC controller functions
    
//    public func latestDataDate() -> Date? {
//        return wbValuation?.latestDataDate
//    }

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
        
        guard share.managedObjectContext != nil else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "WBV Controller unexpectedly did not find MOC of share \(share.symbol ?? "") when trying to return value$ for path \(path)")
            return ("", UIColor.label, ["unexpectedly did not find MOC of share \(share.symbol ?? "") when trying to return value$ for path \(path)"])
        }
        
        let wbValuation = share.wbValuation ?? WBValuation(context: share.managedObjectContext!)
        wbValuation.share = share
        
        var errors: [String]?
        var color: UIColor?
        let emaPeriod = (UserDefaults.standard.value(forKey: userDefaultTerms.emaPeriodAnnualData) as? Int) ?? 7
        
        if path.section == 0 {
            var value$: String?

            switch path.row {
            case 0:
            //Moat
                if let r1v = share.rule1Valuation {
                    
                    let (moatErrors, moat) = r1v.moatScore()
                    if moatErrors != nil {
                        if errors == nil {
                            errors = [String]()
                        }
                        errors!.append(contentsOf: moatErrors!)
                    }
                    if moat != nil {
                        value$ = percentFormatter0Digits.string(from: moat! as NSNumber) ?? "-"
                        color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 100, value: moat!, greenCutoff: 0.7, redCutOff: 0.5)
                    }
                    
                    if let trendData = r1v.moatScoreTrend.datedValues(dateOrder: .ascending) { // share.trendValues(trendName: .moatScore) {
                        let pastData = trendData.filter({ datedValue in
                            if datedValue.date < r1v.creationDate { return true }
                            else { return false }
                        })
                        if let mostRecent = pastData.first {
                            if value$ == nil {
                                value$ = " (" + percentFormatter0Digits.string(from: mostRecent.value as NSNumber)! + ")"
                            } else {
                                value$! += " (" + percentFormatter0Digits.string(from: mostRecent.value as NSNumber)! + ")"
                            }
                        }
                    }
                }
            case 1:
            // PE ratio
                if let pe = share.ratios?.pe_ratios.datedValues(dateOrder: .ascending, includeThisYear: true)?.last {
                    value$ = numberFormatter2Decimals.string(from: pe.value as NSNumber)
                    if pe.value > 0 {
                        color = GradientColorFinder.gradientColor(lowerIsGreen: true, min: 0, max: 40, value: pe.value, greenCutoff: 10.0, redCutOff: 40.0)
                    } else if pe.value < 0 {
                        color = UIColor.systemRed
                    } else {
                        color = UIColor.label
                    }
                }
                let sixMonthsAgo = Date().addingTimeInterval(-183*24*3600)
                let twoYearsAgo = sixMonthsAgo.addingTimeInterval(-2*365*24*3600)
                if let (min, _, max) = share.ratios?.minMeanMaxPERatioInDateRange(from: twoYearsAgo, to: sixMonthsAgo) {
                    let minMAxValue$ = " (" + numberFormatterNoFraction.string(from: min as NSNumber)! + " - " + numberFormatterNoFraction.string(from: max as NSNumber)! + ")"
                    value$?.append(minMAxValue$)
                }
                
            case 2:
            // BVPSP
                if let values = share.latestBookValuePerPrice() {
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
                let (lyncherrors, value) = share.lynchRatio()
                if let le = lyncherrors {
                    if errors == nil { errors = le }
                    else {
                        errors?.append(contentsOf: le)
                    }
                }
                if let ratio = value {
                    value$ = numberFormatterWith1Digit.string(from: ratio as NSNumber) ?? "-"
                    color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 10, value: ratio, greenCutoff: 2.0, redCutOff: 1.0)
                    
                    if let trendDVs = share.trendValues(trendName: .lynchScore) {
                        
                        if let pdv = trendDVs.filter({ dv in
                            if dv.date < (wbValuation.date) { return true }
                            else { return false }
                        }).first {
                            value$! += " (" + numberFormatterWith1Digit.string(from: pdv.value as NSNumber)! + ")"
                        }
                    }
                }
                
            case 4:
                // 12m Price/EPS ratio
                
                var priceChange$ = "-"
                var epsChange$ = "-"
                
                let priceCorrelation = share.priceChangeLastyear()
                let priceChange = priceCorrelation?.change()
                
                if priceChange != nil {
                    priceChange$ = percentFormatter0Digits.string(from: priceChange! as NSNumber) ?? "-"
                    if let r2 = priceCorrelation?.r2() {
                        if r2 < 0.5 {
                            priceChange$ = "(\(priceChange$))"
                        }
                    }
                }
                
                let epsCorrelation = share.epsChangeLastYear()
                let epsChange = epsCorrelation?.change()
                
                if epsChange != nil {
                    epsChange$ = percentFormatter0Digits.string(from: epsChange! as NSNumber) ?? "-"
                    if let r2 = epsCorrelation?.r2() {
                        if r2 < 0.5 {
                            epsChange$ = "(\(epsChange$))"
                        }
                    }
                }
                
                value$ = (priceChange$) + " / " + (epsChange$)
                
//                if epsChange != nil && priceChange != nil  {
//                    let ratio = priceChange! / epsChange!
//                    if ratio > 1.2 { color = UIColor.red }
//                    else if ratio < 0.8 && ratio > 0 {
//                        color = UIColor.green
//                    } 
//                    else if ratio < 0 {
//                        if priceChange! > epsChange! { color = .red }
//                        else { color = .green }
//                    }
//                }

            case 5:
            // Return 10/3 years
                value$ = "-/-"
                var v10$ = "-"
                var v3$ = "-"
                if share.return10y != Double() {
                    v10$ = (numberFormatter2Decimals.string(from: share.return10y as NSNumber) ?? "-") + "x"
                }
                if share.return3y != Double() {
                    v3$ = (numberFormatter2Decimals.string(from: share.return3y as NSNumber) ?? "-") + "x"
                }
                value$ = v10$ + "/" + v3$
            case 6:
            // beta
                if let beta = share.key_stats?.beta.valuesOnly(dateOrdered: .ascending, includeThisYear: true)?.last {
                    value$ = numberFormatter2Decimals.string(from: beta as NSNumber)
                }
            case 7:
            // R1 Price
                if let r1v = share.rule1Valuation {
                    let (stickerprice, es) = r1v.stickerPrice()
                    if let sp =  stickerprice {
                        value$ = currencyFormatterNoGapWithPence.string(from: sp as NSNumber)
                        errors = es
                    }
                    
                    if let trendData = share.trendValues(trendName: .stickerPrice) {
                        let pastData = trendData.filter { datedValue in
                            if datedValue.date < r1v.creationDate { return true }
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
            case 8:
            // DCF Price
                if let dcfv = share.dcfValuation {
                    let (price,es) = dcfv.returnIValueNew()
                    if errors == nil {
                        errors = [String]()
                    }
                    errors!.append(contentsOf: es)
                    if let iv = price {
                        value$ = currencyFormatterGapWithPence.string(from: iv as NSNumber)
                        
                        if let trendData = share.trendValues(trendName: .dCFValue) {
                            let pastData = trendData.filter { datedValue in
                                if datedValue.date < dcfv.creationDate { return true }
                                else { return false }
                            }
                            if let mostRecent = pastData.first {
                                value$! += " (" + currencyFormatterNoGapWithPence.string(from: mostRecent.value as NSNumber)! + ")"
                            }
                        }
                    }
                }
            case 9:
            // WB intrinsic value
                    let (valid, es$) = wbValuation.ivalue()
                    errors = es$
                    if valid != nil {
                        value$ = currencyFormatterGapWithPence.string(from: valid! as NSNumber)
                    }
                    
                    if let trendData = share.trendValues(trendName: .intrinsicValue) {
                        let pastData = trendData.filter { datedValue in
                            if datedValue.date < wbValuation.date { return true }
                            else { return false }
                        }
                        if let mostRecent = pastData.first {
                            if value$ == nil { value$ = String() }
                            value$! += " (" + currencyFormatterNoGapWithPence.string(from: mostRecent.value as NSNumber)! + ")"
                        }
                    }

//                }
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
                
                if let revenueDVs = share.income_statement?.revenue.datedValues(dateOrder: .ascending, oneForEachYear: true)?.dropZeros() {
                    
                    if let growthrates = revenueDVs.growthRates(dateOrder: .descending)?.values() {
                        if let growthEMA = growthrates.ema(periods: emaPeriod) {
                            value$ = percentFormatter0DigitsPositive.string(from: growthEMA as NSNumber) ?? "-"
                            color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 100, value: growthEMA, greenCutoff: 0, redCutOff: 0)

                        }
                    }
                }
                
                return (value$, color, errors)
                
            case 1:
            // net income
                
                if let datedValues = share.income_statement?.netIncome.datedValues(dateOrder: .ascending, oneForEachYear: true)?.dropZeros() {
                    
                    if let growthrates = Calculator.reatesOfReturn(datedValues: datedValues) {
                        if let growthEMA = growthrates.ema(periods: emaPeriod) {
                            value$ = percentFormatter0DigitsPositive.string(from: growthEMA as NSNumber) ?? "-"
                            color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 100, value: growthEMA, greenCutoff: 0, redCutOff: 0)

                        }
                    }
                }

                return (value$, color, errors)
                
            case 2:
            // Ret. earnings
                if let datedValues = share.balance_sheet?.retained_earnings.datedValues(dateOrder: .ascending, oneForEachYear: true)?.dropZeros() {
                    
                    if let growthrates = datedValues.growthRates(dateOrder: .descending)?.values() {
                        if let growthEMA = growthrates.ema(periods: emaPeriod) {
                            value$ = percentFormatter0DigitsPositive.string(from: growthEMA as NSNumber) ?? "-"
                            color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 100, value: growthEMA, greenCutoff: 0.05, redCutOff: 0.05)

                        }
                    }
                }

                return (value$, color, errors)

            case 3:
                // EPS
                if let datedValues = share.income_statement?.eps_annual.datedValues(dateOrder: .ascending, oneForEachYear: true)?.dropZeros() {
                    
                    if let growthrates = Calculator.reatesOfReturn(datedValues: datedValues) {
                        if let growthEMA = growthrates.ema(periods: emaPeriod) {
                            value$ = percentFormatter0DigitsPositive.string(from: growthEMA as NSNumber) ?? "-"
                            color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 100, value: growthEMA, greenCutoff: 0.1, redCutOff: 0)
                        }
                    }
                }

                return (value$,color,errors)

           case 4:
            // profit margin
                
                let (profitMargins, error) = share.grossProfitMargins() // values are harmonised in function - zeros removed
                if error != nil {
                    errors = [error!]
                }
                if let datedValues = profitMargins?.sortByDate(dateOrder: .ascending).dropZeros() {
                    
                    if let growthrates = Calculator.reatesOfReturn(datedValues: datedValues) {
                        if let growthEMA = growthrates.ema(periods: emaPeriod) {
                            value$ = percentFormatter0DigitsPositive.string(from: growthEMA as NSNumber) ?? "-"
                            color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 40, value: growthEMA, greenCutoff: 0.4, redCutOff: 0.2)

                        }
                    }
                }

                return (value$,color,errors)
            case 5:
            // op. cash flow
                if let datedValues = share.cash_flow?.opCashFlow.datedValues(dateOrder: .ascending, oneForEachYear: true)?.dropZeros() {
                    
                    if let growthrates = Calculator.reatesOfReturn(datedValues: datedValues) {
                        if let growthEMA = growthrates.ema(periods: emaPeriod) {
                            value$ = percentFormatter0DigitsPositive.string(from: growthEMA as NSNumber) ?? "-"
                            color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 40, value: growthEMA, greenCutoff: 0.15, redCutOff: 0)
                        }
                    }
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
                
                if let values = share.ratios?.roi.valuesOnly(dateOrdered: .ascending) {
                    
                    let over10s = values.filter { roi in
                        if roi < 0.1 { return false }
                        else { return true }
                    }
                    
                    if values.count > 0 {
                        let proportionOver10 = Double(over10s.count) / Double(values.count)
                        value$ = percentFormatter0DigitsPositive.string(from:  proportionOver10 as NSNumber) ?? "-"
                        color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 100, value: proportionOver10, greenCutoff: 0.8, redCutOff: 0.5)
                    }
                    
//                        if let growthEMA = values.ema(periods: emaPeriod) {
//                            value$ = percentFormatter0DigitsPositive.string(from: growthEMA as NSNumber) ?? "-"
//                            color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 100, value: growthEMA, greenCutoff: 0.3, redCutOff: 0.1)
//                        }
                 }
                return (value$, color, errors)
                
            case 1:
            // ROE
                
                if let values = share.ratios?.roe.valuesOnly(dateOrdered: .ascending) {
                    
                    let over10s = values.filter { roe in
                        if roe < 0.1 { return false }
                        else { return true }
                    }
                    
                    if values.count > 0 {
                        let proportionOver10 = Double(over10s.count) / Double(values.count)
                        value$ = percentFormatter0DigitsPositive.string(from:  proportionOver10 as NSNumber) ?? "-"
                        color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 100, value: proportionOver10, greenCutoff: 0.8, redCutOff: 0.5)
                    }
                 }

                return (value$, color, errors)

            case 2:
            // ROA
                if let values = share.ratios?.roa.valuesOnly(dateOrdered: .ascending) {
                    
                    let over10s = values.filter { roa in
                        if roa < 0.1 { return false }
                        else { return true }
                    }
                    
                    if values.count > 0 {
                        let proportionOver10 = Double(over10s.count) / Double(values.count)
                        value$ = percentFormatter0DigitsPositive.string(from:  proportionOver10 as NSNumber) ?? "-"
                        color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 100, value: proportionOver10, greenCutoff: 0.8, redCutOff: 0.5)
                    }
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
                
                if let netIncome = share.income_statement?.netIncome.valuesOnly(dateOrdered: .ascending) {
                    if let capEx = share.cash_flow?.capEx.valuesOnly(dateOrdered: .ascending) {
                        let sum = netIncome.reduce(0, +)
                        let denom = capEx.reduce(0, +)
                        if denom > 0 {
                            let tyaverage = abs(sum/denom)
                            value$ = percentFormatter0Digits.string(from: tyaverage as NSNumber) ?? "-"
                            color = GradientColorFinder.gradientColor(lowerIsGreen: true, min: 0, max: 1, value: tyaverage, greenCutoff: 0.25, redCutOff: 0.5)
                        }
                    }
                }
                return (value$,color,errors)

            case 1:
            // Lt debt / net income
                
                let (proportions, es$) = wbValuation.longtermDebtProportion()
                errors = es$
                if let average = proportions.ema(periods: emaPeriod) {
                    value$ = percentFormatter0Digits.string(from: average as NSNumber) ?? "-"
                    color = GradientColorFinder.gradientColor(lowerIsGreen: true, min: 0, max: 100, value: average, greenCutoff: 3.0, redCutOff: 4.0)
                }

                return (value$, color, errors)
 
            case 2:
            // SGA / profit
                let (proportions, es$) = wbValuation.sgaProportion()
                errors = es$
                if let average = proportions.ema(periods: emaPeriod) {
                    value$ = percentFormatter0Digits.string(from: average as NSNumber) ?? "-"
                    color = GradientColorFinder.gradientColor(lowerIsGreen: true, min: 0, max: 40, value: average, greenCutoff: 0.3, redCutOff: 1.0)
                }
                return (value$, color, errors)

            case 3:
            // R&D / profit
                let (proportions, es$) = wbValuation.rAndDProportion()
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
        return [["Moat", "P/E ratio", "BVPS/price","Lynch ratio", "Price/EPS 1yr" ,"Return (10/3y)" ,"beta","R1 price","DCF Price", "intr. value (10y)"],
                ["Revenue", "Net income", "Ret. earnings", "EPS", "Profit margin", "OpCash flow"],
                ["ROI","ROE", "ROA"],
                ["CapEx/earnings", "LT Debt/earnings", "SGA /profit", "R&D /profit"]
        ]
    }
        
    // MARK: - Data download functions
    /// MUST be called  on main thread
    func downloadAllValuationData() async {
                     
        guard let symbol = share.symbol else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "all data download requested for \(String(describing: share)) but symbol not available")
            return
 
        }
        guard var shortName = share.name_short else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "all data download reauested for \(symbol) but short name not available")
            return
        }
        
        let longName = share.name_long ?? "noLongName"
        let currency = share.currency ?? "noCurrency"
        
        let shortNameComponents = shortName.split(separator: " ")
        let removeTerms = ["Inc.","Incorporated" , "Ltd", "Ltd.", "LTD", "Limited","plc." ,"Corp.", "Corporation","Company" ,"International", "NV","&", "The", "Walt", "Co.", "SE", "o.N", "O.N", "Namens-Aktien", "A/S"] // "Group",
        let replaceTerms = ["S.A.": "sa "]
        var cleanedName = String()
        for component in shortNameComponents {
            if replaceTerms.keys.contains(String(component)) {
                cleanedName += replaceTerms[String(component)] ?? ""
            } else if !removeTerms.contains(String(component)) {
                cleanedName += String(component) + " "
            }
        }
        shortName = String(cleanedName.dropLast())

        
        let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc.automaticallyMergesChangesFromParent = true
        
        let wbv = share.wbValuation ?? WBValuation(context: backgroundMoc)
        wbv.share = share
        wbv.date = Date()
        
        let r1v = share.rule1Valuation ?? Rule1Valuation(context: backgroundMoc)
        r1v.share = share
        r1v.creationDate = Date()
        
        let dcfv = share.dcfValuation ?? DCFValuation(context: backgroundMoc)
        dcfv.share = share
        dcfv.creationDate = Date()
        
        do {
            try backgroundMoc.save()
        }
        catch {
            ErrorController.addInternalError(errorLocation: #function, systemError: error ,errorInfo: "failed to save new valuations dates for \(symbol)")
        }


        let shareID = share.objectID
        
            do {

                if currency == "EUR" {
                    
                    let webKitDownloadTasks = await WebViewDownloader.countOfDownloadTasks()
                    
                    progressDelegate?.allTasks = YahooPageScraper.countOfRowsToDownload(option: .nonUS) + FinanzenScraper.countOfDownloadTasks() + webKitDownloadTasks
                    
                    
                    await YahooPageScraper.dataDownloadAnalyseSave(symbol: symbol, shortName: shortName, shareID: shareID, option: .nonUS, progressDelegate: progressDelegate, downloadRedirectDelegate: self)

                    try Task.checkCancellation()
                    
                    await FinanzenScraper.downloadAnalyseAndSavePredictions(shareSymbol: symbol, companyName: longName, shareID: shareID, progressDelegate: progressDelegate)
                    
                    try Task.checkCancellation()

                    DispatchQueue.main.async {
                        
                        self.webViewDownloader = WebViewDownloader.newWebViewDownloader(delegate: self.viewController!)
                        self.webViewDownloader?.downloadPage(domain: "https://www.boerse-frankfurt.de/equity", companyName: longName, pageName: "key-data", currency: currency, shareID: shareID, in: self.viewController!)
                        
                        self.progressDelegate?.downloadComplete()
                    }
                }
                // US stocks
                else {

                    progressDelegate?.allTasks = MacrotrendsScraper.countOfRowsToDownload(option: .allValuationDataOnly) + YahooPageScraper.countOfRowsToDownload(option: .allValuationDataOnly)
                    
                    await YahooPageScraper.dataDownloadAnalyseSave(symbol: symbol, shortName: shortName, shareID: shareID, option: .allValuationDataOnly, progressDelegate: progressDelegate, downloadRedirectDelegate: self)
                    
                    try Task.checkCancellation()
                    
                    await MacrotrendsScraper.dataDownloadAnalyseSave(shareSymbol: symbol, shortName: shortName, shareID: shareID, downloadOption: .allValuationDataOnly, downloadRedirectDelegate: self)
                    
                    progressDelegate?.downloadComplete()

                }
            } catch {
                ErrorController.addInternalError(errorLocation: #function, systemError: error ,errorInfo: "all data download for \(symbol) failed.")
                progressDelegate?.downloadError(error: error.localizedDescription)
            }
            
            NotificationCenter.default.removeObserver(self)
    }

    
        
    /// MUST be called  on main thread
    func downloadWBValuationData() {
                     
        let symbol = share.symbol
        let shortName = share.name_short
        let shareID = share.objectID
        
        downloadTask = Task.init(priority: .background) {
            
            do {
                try Task.checkCancellation()
                progressDelegate?.allTasks += 1
                // non-US stocks
                if symbol?.contains(".") ?? false {
                    
                    await YahooPageScraper.dataDownloadAnalyseSave(symbol: symbol ?? "missing symbol", shortName: shortName ?? "missing short name", shareID: shareID, option: .wbvOnly, downloadRedirectDelegate: self)
                    
                }
                // US stocks
                else {
                    
                    await YahooPageScraper.dataDownloadAnalyseSave(symbol: symbol ?? "missing symbol", shortName: shortName ?? "missing short name", shareID: shareID, option: .wbvOnly, downloadRedirectDelegate: self)
                    
                    await MacrotrendsScraper.dataDownloadAnalyseSave(shareSymbol: symbol ?? "missing symbol", shortName: shortName ?? "missing short name", shareID: shareID, downloadOption: .wbvOnly, downloadRedirectDelegate: self)

                    progressDelegate?.taskCompleted()
                }
                try Task.checkCancellation()
                
                progressDelegate?.allTasks += 2


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
                if element.wbvParameter == parameter { return element }
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


