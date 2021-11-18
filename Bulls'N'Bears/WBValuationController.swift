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
    let revenueGrowth = "Revenue and its compound growth"
    let earnigsGrowth = "Net earnings and their compound growth"
    let retEarningsGrowth = "Ret. earnings and their compound growth"
    let epsGrowth = "EPS and its compound growth"
    let incomeOfRevenueGrowth = "[Net income / revenue] and its compound growth"
    let profitOfRevenueGrowth = "[Profit / revenue] and its compound growth"
    let capExpendOfEarningsGrowth = "[Cap. expend / net income] and its compound growth"
    let earningsToPERratio = "[Earnings / pe ratio] and its compound growth"
    let debtOfIncomeGrowth = "[LT debt / net income] and its compound growth"
    let opCashFlowGrowth = "Op. cash flow and its compound growth"
    let roeGrowth = "Return on equity and its compound growth"
    let roaGrowth = "Rturn on assets and its compound growth"
    let debtOfEqAndRtEarningsGrowth = "[LT debt / adj. equity] and its compound growth"
    let sgaOfProfitGrowth = "[SGA / profit] and its compound growth"
    let rAdOfProfitGrowth = "[R&D / profit]  and its compound growth"
    
    func allParameters() -> [String] {
        return [earnigsGrowth,retEarningsGrowth, epsGrowth, incomeOfRevenueGrowth, profitOfRevenueGrowth, capExpendOfEarningsGrowth, debtOfIncomeGrowth, roeGrowth, roaGrowth ,debtOfEqAndRtEarningsGrowth, sgaOfProfitGrowth ,rAdOfProfitGrowth]
    }
    
    func structuredTitlesParameters() -> [[[String]]] {
        return [firstSection(), secondSection(), thirdSection()]
    }
        
    func firstSection() -> [[String]] {
        return [[revenueGrowth],
                [earnigsGrowth],
//                [incomeOfRevenueGrowth], //, "Revenue"
                [retEarningsGrowth],
                [epsGrowth],
                [profitOfRevenueGrowth], //, "Revenue"
                [opCashFlowGrowth]]
    }
    
    func secondSection() -> [[String]] {
        return [[roeGrowth],
                [roaGrowth],
//                [debtOfEqAndRtEarningsGrowth]
        ] // , "equity + ret. earnings"
    }
    
    func thirdSection() -> [[String]] {
        return [[capExpendOfEarningsGrowth], //, "Net income"
                [debtOfIncomeGrowth], //, "Net income"
                [sgaOfProfitGrowth], // , "Profit"
                [rAdOfProfitGrowth]] // , "Profit"]
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
    var valuation: WBValuation?
    var valuationID: NSManagedObjectID?
    var progressDelegate: ProgressViewDelegate?
    var downloadTasks = 0
    var downloadTasksCompleted = 0
    var downloadErrors = [String]()
//    var downloader: WebDataDownloader?
    var valueListChartLegendTitles = [
        [["Revenue"],
         ["Net income"],
//         ["net income / revenue"],
         ["Ret. earnings"],
         ["EPS"],
         ["Profit margin"],
         ["OpCash flow"]
        ],
        [
         ["ROE"],
         ["ROA"],
//         ["lt debt / adj. equity"]
        ],
        [["capExpend/earnings"],
         ["LT debt/earnings"],
         ["SGA /profit"],
         ["R&D /profit"]
        ]]
    var wbvParameters = WBVParameters()
    var downloadTask: Task<Any?,Error>?
    
    //MARK: - init

    init(share: Share, progressDelegate: ProgressViewDelegate) {
        
        super.init()
        
        self.share = share
        self.progressDelegate = progressDelegate
        
        if let valuation = share.wbValuation {
            self.valuation = valuation
            self.valuationID = valuation.objectID
        }
        else if let valuation = WBValuationController.returnWBValuations(share: share) {
            // find old disconnected valutions persisted after share was deleted
            self.valuation = valuation
            self.valuationID = valuation.objectID

        }
        else {
            self.valuation = WBValuationController.createWBValuation(share: share)
            // when deleting a WBValuation this doe NOT delete related UserEvaluations
            // these are linked to a company (symbol) as well as wbValuation parameters
            // when (re-)creating a WBValuation check whether there are any old userEvaluations
            // and if so re-add the relationships to this WBValuation via parameters
            self.valuationID = valuation?.objectID

            if let ratings = WBValuationController.allUserRatings(for: share.symbol!) {
                if ratings.count > 0 {
                    let set = NSSet(array: ratings)
                    valuation?.addToUserEvaluations(set)
                }
            }
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
                ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: error, errorInfo: "error fetching WBValuation")
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
            ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: error, errorInfo: "error creating and saving Rule1Valuation")
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
                ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: error, errorInfo: "error fetching UserEvaluations")
        }

        return ratings
    }
    
    func updateData() {
        
        guard let validID = valuationID else {
            ErrorController.addErrorLog(errorLocation: "CombinedValuationController.checkValuation", systemError: nil, errorInfo: "controller has no valid NSManagedObjectID to fetch valuation")
            return
        }
        
        self.valuation = ((UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.object(with: validID) as? WBValuation)!
    }

    
    //MARK: - TVC controller functions
    
    public func rowTitle(path: IndexPath) -> String {
        return rowTitles[path.section][path.row]
    }
    
    public func sectionHeaderText(section: Int) -> String {
        
        return sectionTitles[section]
        
    }
    
    public func sectionSubHeaderText(section: Int) -> String? {
        
        if let date = valuation?.date {
            sectionSubTitles[0] =  "Valuation figures from " + dateFormatter.string(from: date)
        }
        return sectionSubTitles[section]
    }


    public func value$(path: IndexPath) -> (String, UIColor?, [String]?) {
        
        guard valuation != nil else {
            return ("--", nil, ["no valuation"])
        }
        
        var errors: [String]?
        var color: UIColor?
        let emaPeriod = (UserDefaults.standard.value(forKey: userDefaultTerms.emaPeriodAnnualData) as? Int) ?? 7
        
        if path.section == 0 {
            var value$: String?

            switch path.row {
            case 0:
            // PE ratio
                if share.peRatio != Double() {
                    value$ = numberFormatterDecimals.string(from: share.peRatio as NSNumber)
                    color = GradientColorFinder.gradientColor(lowerIsGreen: true, min: 0, max: 40, value: share.peRatio, greenCutoff: 10.0, redCutOff: 40.0)
                }
                let sixMonthsAgo = Date().addingTimeInterval(-183*24*3600)
                let twoYearsAgo = sixMonthsAgo.addingTimeInterval(-2*365*24*3600)
                if let (min, _, max) = valuation?.minMeanMaxPER(from: twoYearsAgo, to: sixMonthsAgo) {
                    let minMAxValue$ = " (" + numberFormatterNoFraction.string(from: min as NSNumber)! + " - " + numberFormatterNoFraction.string(from: max as NSNumber)! + ")"
                    value$?.append(minMAxValue$)
                }
                
            case 1:
            // EPS
                if share.eps != Double() {
                    value$ = currencyFormatterGapWithPence.string(from: share.eps as NSNumber)
                    color = share.eps > 0 ? GradientColorFinder.greenGradientColor() : GradientColorFinder.redGradientColor()
                }
            case 2:
            // BVPSP
                if let values = valuation!.bookValuePerPrice() {
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
                if let ratio = valuation!.lynchRatio() {
                    value$ = numberFormatterWith1Digit.string(from: ratio as NSNumber) ?? "-"
                    color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 10, value: ratio, greenCutoff: 2.0, redCutOff: 1.0)
                }
            case 4:
            // beta
                if share.beta != Double() {
                    value$ = numberFormatterDecimals.string(from: share.beta as NSNumber)
                }
            case 5:
            // WB intrinsic value
                if share.peRatio != Double() {

                    let (valid, es$) = valuation!.ivalue()
                    errors = es$
                    if valid != nil {
                        value$ = currencyFormatterGapWithPence.string(from: valid! as NSNumber)
                    }
                }
            default:
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "undefined row in path \(path)")
            }
            
            return (value$ ?? "no value", color, errors)
        }
        else if path.section == 1 {
            
            var value$ = "-"
            switch path.row {
            case 0:
            // Revenue
            
//                let sales = valuation?.revenue?.filter({ (element) -> Bool in
//                    if element != 0.0 { return true }
//                    else { return false }
//                })
                let sales = valuation?.revenue
                if let growth = Calculator.compoundGrowthRates(values: sales) { //sales?.growthRates()
                    if let growthEMA = growth.ema(periods: emaPeriod) {
                        value$ = percentFormatter0DigitsPositive.string(from: growthEMA as NSNumber) ?? "-"
                        color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 100, value: growthEMA, greenCutoff: 0, redCutOff: 0)

                    }
                }
                return (value$, color, errors)
                
            case 1:
            // net income
                
//                let netIncome = valuation?.netEarnings?.filter({ (element) -> Bool in
//                    if element != 0.0 { return true }
//                    else { return false }
//                })
                let netIncome = valuation?.netEarnings
                if let growth = Calculator.compoundGrowthRates(values: netIncome) {
                    if let growthEMA = growth.ema(periods: emaPeriod) {
                        value$ = percentFormatter0DigitsPositive.string(from: growthEMA as NSNumber) ?? "-"
                        color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 100, value: growthEMA, greenCutoff: 0, redCutOff: 0)

                    }
                }
                return (value$, color, errors)
                
//            case 2:
//            // net income / revenue
//                let (proportions, es$) = valuation!.netIncomeProportion()
//                errors = es$
//                if let average = proportions.ema(periods: emaPeriod) {
//                    value$ = percentFormatter0Digits.string(from: average as NSNumber) ?? "-"
//                    color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 100, value: average, greenCutoff: 0.2, redCutOff: 0.1)
//                }
//                return (value$, color, errors)
            case 2:
            // Ret. earnings
                let retEarningsGrowths = Calculator.compoundGrowthRates(values: valuation?.equityRepurchased)// valuation?.equityRepurchased?.growthRates()
                
                if let meanGrowth = retEarningsGrowths?.ema(periods: emaPeriod) {
                    value$ = percentFormatter0DigitsPositive.string(from: meanGrowth as NSNumber) ?? "-"
                    color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 100, value: meanGrowth, greenCutoff: 0.05, redCutOff: 0.05)
                }

                return (value$, color, errors)

            case 3:
                // EPS
                if let growthRatesMean = Calculator.compoundGrowthRates(values: valuation!.eps)?.ema(periods: emaPeriod) {
                    value$ = percentFormatter0DigitsPositive.string(from: growthRatesMean as NSNumber) ?? "-"
                    color = growthRatesMean > 0 ? GradientColorFinder.greenGradientColor() : GradientColorFinder.redGradientColor()
                }

                return (value$,color,errors)

           case 4:
            // profit margin
                let (margins, es$) = valuation!.grossProfitMargins()
                errors = es$
                if let averageMargin = margins.ema(periods: emaPeriod) { //weightedMean()
                    value$ = percentFormatter0Digits.string(from: averageMargin as NSNumber) ?? "-"
                    color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 40, value: averageMargin, greenCutoff: 0.4, redCutOff: 0.2)
                }
                return (value$,color,errors)
            case 5:
            // op. cash flow
                let fcfGrowth = Calculator.compoundGrowthRates(values: valuation!.opCashFlow)
                if let meanGrowth = fcfGrowth?.ema(periods: emaPeriod) {
                    value$ = percentFormatter0DigitsPositive.string(from: meanGrowth as NSNumber) ?? "-"
                    color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 40, value: meanGrowth, greenCutoff: 0.15, redCutOff: 0.0)
                }
                return (value$, color, errors)
            default:
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "undefined row in path \(path)")
            }
        }
        else if path.section == 2 {
            
            var value$ = "-"
            switch path.row {
            case 0:
            // ROE
                let roeGrowths = Calculator.compoundGrowthRates(values: valuation!.roe)
                if let meanGrowth = roeGrowths?.ema(periods: emaPeriod) {
                    value$ = percentFormatter0DigitsPositive.string(from: meanGrowth as NSNumber) ?? "-"
                    color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 100, value: meanGrowth, greenCutoff: 0.3, redCutOff: 0.1)
                }

                return (value$, color, errors)


            case 1:
            // ROA
//                let roaGrowths = valuation?.roa?.filter({ (element) -> Bool in
//                    if element != 0.0 { return true }
//                    else { return false }
//                }).growthRates()
                let roaGrowths = Calculator.compoundGrowthRates(values: valuation!.roa)

                if let meanGrowth = roaGrowths?.ema(periods: emaPeriod) {
                    value$ = percentFormatter0DigitsPositive.string(from: meanGrowth as NSNumber) ?? "-"
                }

                return (value$, color, errors)

//            case 2:
//            // LT debt / adj shareholder equity
//
//                let (first3Average, average, mistakes) = valuation!.ltDebtPerAdjEquityProportion()
//                let (shEquityWithRetEarnings, error) = valuation!.addElements(array1: valuation!.shareholdersEquity ?? [], array2: valuation!.equityRepurchased ?? [])
//                if error != nil {
//                    errors = [error!]
//                }
//                let first3Average = shEquityWithRetEarnings?.average(of: 3)
//                let (proportions, es$) = valuation!.proportions(array1: shEquityWithRetEarnings, array2: valuation?.debtLT)
//                if es$ != nil {
//                    if errors != nil { errors?.append(contentsOf: es$!) }
//                    else { errors = es$! }
//                }
//                if average != nil {
//                    if first3Average ?? 0 < 0 && average! < 0 {
//                        // recently negative equity resulting in wrongly negative LT debt
//                        value$ = "neg!"
//                        errors = ["Long-term debt set against recently negative equity with retained earnings"]
//                        color = GradientColorFinder.redGradientColor()
//                    }
//                    else {
//                        errors = mistakes
//                        value$ = percentFormatter0Digits.string(from: average! as NSNumber) ?? "-"
//                        color = GradientColorFinder.gradientColor(lowerIsGreen: true, min: 0, max: 100, value: average!, greenCutoff: 0.8, redCutOff: 0.8 )
//                    }
//                }
//
//                return (value$, color, errors)

            default:
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "undefined row in path \(path)")

            }
        }
        else if path.section == 3 {
            
            var value$ = "-"
            switch path.row {
            case 0:
            // cap expend / earnings
            
                if let sumDiv = valuation!.netEarnings?.reduce(0, +) {
                    // use 10 y sums / averages, not ema according to Book Ch 51
                    if let sumDenom = valuation!.capExpend?.reduce(0, +) {
                        let tenYAverages = abs(sumDenom / sumDiv)
                        value$ = percentFormatter0Digits.string(from: tenYAverages as NSNumber) ?? "-"
                        color = GradientColorFinder.gradientColor(lowerIsGreen: true, min: 0, max: 1, value: tenYAverages, greenCutoff: 0.25, redCutOff: 0.5)
                    }
                }
                
                return (value$,color,errors)

            case 1:
            // Lt debt / net income
                let (proportions, es$) = valuation!.longtermDebtProportion()
                errors = es$
                if let average = proportions.ema(periods: emaPeriod) {
                    value$ = percentFormatter0Digits.string(from: average as NSNumber) ?? "-"
                    color = GradientColorFinder.gradientColor(lowerIsGreen: true, min: 0, max: 100, value: average, greenCutoff: 3.0, redCutOff: 4.0)
                }

                return (value$, color, errors)
 
            case 2:
            // SGA / profit
                let (proportions, es$) = valuation!.sgaProportion()
                errors = es$
                if let average = proportions.ema(periods: emaPeriod) {
                    value$ = percentFormatter0Digits.string(from: average as NSNumber) ?? "-"
                    color = GradientColorFinder.gradientColor(lowerIsGreen: true, min: 0, max: 40, value: average, greenCutoff: 0.3, redCutOff: 1.0)
                }
                return (value$, color, errors)

            case 3:
            // R&D / profit
                let (proportions, es$) = valuation!.rAndDProportion()
                errors = es$
                if let average = proportions.ema(periods: emaPeriod) {
                    value$ = percentFormatter0Digits.string(from: average as NSNumber) ?? "-"
                }
                return (value$, nil, errors)

            default:
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "undefined row in path \(path)")
            }
        }
        
        return ("no value", color, nil)
        
    }
    
    /// if sending 2 arrays returns array with proportion array 0 / array 1
    /// if sending 1 array returns the compund rate of growth from array element to element
    /// the rates returned are in time-ASCENDING order
    public func valueListTVCProportions(values: [[Double]?]?) -> [Double]? {
        
        var proportions: [Double]?
        
        if values?.count ?? 0 > 1 {
            proportions = Calculator.proportions(array1: values?.first!, array0: values?.last!) // returns in same order as sent
        }
        else {
            if let array1 = values?.first {
                proportions = Calculator.compoundGrowthRates(values: array1)
            }
        }
        return proportions
    }
    
    // MARK: - internal functions
    
    private func returnRowTitles() -> [[String]] {
        // careful when changing these - terms and order are linked to WBVParameters() in public vars
        // and used in identifying UserEvaluation.wbvParameter via 'userEvaluation(for indexpath)' below
        return [["P/E ratio", "EPS", "BVPS/price","Lynch ratio","beta", "intr. value (10y)"],
                ["Revenue", "Net income", "Ret. earnings", "EPS", "Profit margin", "OpCash flow"],
                ["ROE", "ROA"],
                ["CapEx/earnings", "LT Debt/earnings", "SGA /profit", "R&D /profit"]
        ]
    }
        
    // MARK: - Data download functions
        
    /// MUST be called  on main thread
    func downloadWBValuationData() {
                     
        let symbol = share.symbol
        let shortName = share.name_short
        let valuationID = valuation?.objectID
        let shareID = share.objectID
        
        downloadTask = Task.init(priority: .background) {
            let allTasks = 2
            var completedTasks = 0
            
            do {
                if let validID = valuationID {
                    try await WebPageScraper2.downloadAnalyseSaveWBValuationData(shareSymbol: symbol, shortName: shortName, valuationID: validID, downloadRedirectDelegate: self)
                    
                    completedTasks += 1
                    progressDelegate?.progressUpdate(allTasks: allTasks, completedTasks: completedTasks)
                }
                
                try Task.checkCancellation()
                try await WebPageScraper2.keyratioDownloadAndSave(shareSymbol: symbol, shortName: shortName, shareID: shareID)
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
        
        let storedEvaluations = valuation?.userEvaluations
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
        
        let storedEvaluations = valuation?.userEvaluations
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
        valuation?.addToUserEvaluations(newValuation)
        
        do {
            try  (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.save()
        } catch {
            let error = error
            ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: error, errorInfo: "error creating and saving Rule1Valuation")
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
            
            for element in valuation?.userEvaluations ?? [] {
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
        
        for element in valuation?.userEvaluations ?? [] {
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
                                    ErrorController.addErrorLog(errorLocation: "StocksController2.awaitingRedirection", systemError: error, errorInfo: "couldn't save \(symbol) in it's MOC after downlaod re-direction")
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


