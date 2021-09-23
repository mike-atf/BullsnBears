//
//  WBValuationController.swift
//  Bulls'N'Bears
//
//  Created by aDav on 16/02/2021.
//

import Foundation
import CoreData
import WebKit


class WBValuationController: NSObject, WKUIDelegate, WKNavigationDelegate {
    
    var sectionTitles = ["Key financials","Earnings & incomings", "Returns", "Outgoings & debt"]
    var sectionSubTitles = ["from Yahoo finance","Trend & growth EMA","Trend & growth EMA","Trend & Ratio"]
    var rowTitles: [[String]]!
    var share: Share!
    var valuation: WBValuation?
    weak var progressDelegate: ProgressViewDelegate?
    var downloadTasks = 0
    var downloadTasksCompleted = 0
    var downloadErrors = [String]()
    var downloader: WebDataDownloader?
    var valueListChartLegendTitles = [
        [["Revenue"],
         ["Net income"],
         ["net income / revenue"],
         ["Ret. earnings"],
         ["EPS"],
         ["profit / revenue"],
         ["Op. cash flow"]
        ],
        [
         ["Return on equity"],
         ["Return on assets"],
         ["lt debt / adj. equity"]
        ],
        [["cap.expend / earnings"],
         [" LT debt / net income"],
         ["SGA / profit"],
         ["R&D / profit"]
        ]]

//        [["Comp. Growth","Revenue"],
//         ["Comp. Growth","Net income"],
//         ["Comp. Growth","net income / revenue","revenue"],
//         ["Comp. Growth","Ret. earnings"],
//         ["Comp. Growth","EPS"],
//         ["Comp. Growth","profit / revenue","revenue"],
//         ["Comp. Growth","Op. cash flow"]
//        ],
//        [
//         ["Comp. Growth","Return on equity"],
//         ["Comp. Growth","Return on assets"],
//         ["Comp. Growth","lt debt / adj. equity","equity + ret. earnings"]
//        ],
//        [["Comp. Growth","cap.expend / earnings","earnings"],
//         ["Comp. Growth"," LT debt / net income","revenue"],
//         ["Comp. Growth","SGA / profit","profit"],
//         ["Comp. Growth","R&D / profit","profit"]
//        ]]
    var wbvParameters = WBVParameters()
    
    //MARK: - init

    init(share: Share, progressDelegate: ProgressViewDelegate) {
        
        super.init()
        
        self.share = share
        self.progressDelegate = progressDelegate
        
        if let valuation = share.wbValuation {
            self.valuation = valuation
        }
        else if let valuation = WBValuationController.returnWBValuations(share: share) {
            // find old disconnected valutions persisted after share was deleted
            self.valuation = valuation
        }
        else {
            self.valuation = WBValuationController.createWBValuation(share: share)
            // when deleting a WBValuation this doe NOT delete related UserEvaluations
            // these are linked to a company (symbol) as well as wbValuation parameters
            // when (re-)creating a WBValuation check whether there are any old userEvaluations
            // and if so re-add the relationships to this WBValuation via parameters
            if let ratings = WBValuationController.allUserRatings(for: share.symbol!) {
                if ratings.count > 0 {
                    let set = NSSet(array: ratings)
                    valuation?.addToUserEvaluations(set)
                }
            }

        }
                
        rowTitles = returnRowTitles()
    }
    
    func deallocate() {
        self.downloader?.webView = nil
        self.downloader = nil
        self.progressDelegate = nil
        self.valuation = nil
        
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
//            valuations = try (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.fetch(fetchRequest)
            valuations = try fetchRequest.execute()
            } catch let error {
                ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: error, errorInfo: "error fetching Rule1Valuation")
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
//            ratings = try (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.fetch(fetchRequest)
            ratings = try fetchRequest.execute()
            } catch let error {
                ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: error, errorInfo: "error fetching UserEvaluations")
        }

        return ratings
    }

    
    //MARK: - TVC controller functions
    
    public func rowTitle(path: IndexPath) -> String {
        return rowTitles[path.section][path.row]
    }
    
    public func sectionHeaderText(section: Int) -> String {
        
        var date$ = String()
        if let date = valuation?.date {
            date$ = dateFormatter.string(from: date)
        }
    
        var datedTitles = [sectionTitles[0]] // not dated
        for i in 1..<sectionTitles.count {
            datedTitles.append(sectionTitles[i] + " (" + date$ + ")")
        }
        return datedTitles[section]
    }
    
    public func sectionSubHeaderText(section: Int) -> String {
        
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
                
            case 2:
            // net income / revenue
                let (proportions, es$) = valuation!.netIncomeProportion()
                errors = es$
                if let average = proportions.ema(periods: emaPeriod) {
                    value$ = percentFormatter0Digits.string(from: average as NSNumber) ?? "-"
                    color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 100, value: average, greenCutoff: 0.2, redCutOff: 0.1)
                }
                return (value$, color, errors)
            case 3:
            // Ret. earnings
                let retEarningsGrowths = Calculator.compoundGrowthRates(values: valuation?.equityRepurchased)// valuation?.equityRepurchased?.growthRates()
                
                if let meanGrowth = retEarningsGrowths?.ema(periods: emaPeriod) {
                    value$ = percentFormatter0DigitsPositive.string(from: meanGrowth as NSNumber) ?? "-"
                    color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 100, value: meanGrowth, greenCutoff: 0.05, redCutOff: 0.05)
                }

                return (value$, color, errors)

            case 4:
                // EPS
                if let growthRatesMean = Calculator.compoundGrowthRates(values: valuation!.eps)?.ema(periods: emaPeriod) {
                    value$ = percentFormatter0DigitsPositive.string(from: growthRatesMean as NSNumber) ?? "-"
                    color = growthRatesMean > 0 ? GradientColorFinder.greenGradientColor() : GradientColorFinder.redGradientColor()
                }

                return (value$,color,errors)

           case 5:
            // profit margin
                let (margins, es$) = valuation!.grossProfitMargins()
                errors = es$
                if let averageMargin = margins.ema(periods: emaPeriod) { //weightedMean()
                    value$ = percentFormatter0Digits.string(from: averageMargin as NSNumber) ?? "-"
                    color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 40, value: averageMargin, greenCutoff: 0.4, redCutOff: 0.2)
                }
                return (value$,color,errors)
            case 6:
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

            case 2:
            // LT debt / adj shareholder equity
                
                let (first3Average, average, mistakes) = valuation!.ltDebtPerAdjEquityProportion()
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
                if average != nil {
                    if first3Average ?? 0 < 0 && average! < 0 {
                        // recently negative equity resulting in wrongly negative LT debt
                        value$ = "neg!"
                        errors = ["Long-term debt set against recently negative equity with retained earnings"]
                        color = GradientColorFinder.redGradientColor()
                    }
                    else {
                        errors = mistakes
                        value$ = percentFormatter0Digits.string(from: average! as NSNumber) ?? "-"
                        color = GradientColorFinder.gradientColor(lowerIsGreen: true, min: 0, max: 100, value: average!, greenCutoff: 0.8, redCutOff: 0.8 )
                    }
                }

                return (value$, color, errors)

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
//                proportions = array1?.growthRates()
                proportions = Calculator.compoundGrowthRates(values: array1)
            }
        }
        return proportions
    }
    
    // MARK: - internal functions
    
    private func returnRowTitles() -> [[String]] {
        // careful when changing these - terms and order are linked to WBVParameters() in public vars
        // and used in identifying UserEvaluation.wbvParameter via 'userEvaluation(for indexpath)' below
        return [["P/E ratio", "EPS", "Book value/share price","Lynch ratio","beta", "intr. share value (10y)"],
                ["Revenue", "Net income", "Net inc./ Revenue (Trend & ratio)", "Ret. earnings", "EPS", "Profit margin (Trend & ratio)", "Op. cash flow"],
                ["Return on equity", "Return on assets","LT debt / adj.sh.equity (Trend & ratio)"],
                ["Cap. expend. / earnings", "LT Debt / net income", "SGA / profit", "R&D / profit"]
        ]
    }
        
    // MARK: - Data download functions
        
    func downloadWBValuationData() {
                
        let webPageNames = ["financial-statements", "balance-sheet", "cash-flow-statement" ,"financial-ratios","pe-ratio", "stock-price-history"]
        
        guard share.name_short != nil else {
            
            progressDelegate?.downloadError(error: "Unable to load WB valuation data, can't find a short name in dictionary.")
            return
        }
        
        let placeholder = SharePlaceHolder(share: share)
                
        downloader = WebDataDownloader(stock: placeholder, delegate: self)
        downloader?.macroTrendsDownload(pageTitles: webPageNames)
        downloadTasks = webPageNames.count
    }
    
    public func stopDownload() {
        NotificationCenter.default.removeObserver(self)
        
        downloader?.webView?.stopLoading()
        downloader?.yahooSession?.cancel()
        downloader?.yahooSession = nil
        progressDelegate = nil
        downloader?.request = nil
        downloader?.webView = nil
        downloader = nil
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

extension WBValuationController: DataDownloaderDelegate {
    
    /// caller MUST ensure this is called on the main thread to avoid viewContext concurrency problems
    func downloadComplete(html$: String?, pageTitle: String?) {
        
        downloadTasksCompleted += 1
        
        guard html$ != nil else {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "download complete, html string is empty")
            self.progressDelegate?.progressUpdate(allTasks: self.downloadTasks ,completedTasks: self.downloadTasksCompleted)
            return
        }
        
        guard let section = pageTitle else {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "download complete - notification did not contain section info!!")
            return
        }
        
        var result:(array: [Double]?, errors: [String])

        if section == "financial-statements" {
            result = WebpageScraper.scrapeRowForDoubles(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Revenue")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.revenue = result.array
            
            result = WebpageScraper.scrapeRowForDoubles(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Gross Profit")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.grossProfit = result.array
            
            result = WebpageScraper.scrapeRowForDoubles(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Research And Development Expenses")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.rAndDexpense = result.array

            result = WebpageScraper.scrapeRowForDoubles(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "SG&amp;A Expenses")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.sgaExpense = result.array
            
            result = WebpageScraper.scrapeRowForDoubles(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Net Income")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.netEarnings = result.array
            
            result = WebpageScraper.scrapeRowForDoubles(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Operating Income")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.operatingIncome = result.array
            
            result = WebpageScraper.scrapeRowForDoubles(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "EPS - Earnings Per Share")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.eps = result.array

            self.progressDelegate?.progressUpdate(allTasks: self.downloadTasks, completedTasks: self.downloadTasksCompleted)
        }
        else if section == "balance-sheet" {
            result = WebpageScraper.scrapeRowForDoubles(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Long Term Debt")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.debtLT = result.array
            
            result = WebpageScraper.scrapeRowForDoubles(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Propoerty, Plant, And Equipment")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.ppe = result.array
            
            result = WebpageScraper.scrapeRowForDoubles(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Retained Earnings (Accumulated Deficit)")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.equityRepurchased = result.array

            result = WebpageScraper.scrapeRowForDoubles(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Share Holder Equity")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.shareholdersEquity = result.array
            
            self.progressDelegate?.progressUpdate(allTasks: self.downloadTasks, completedTasks: self.downloadTasksCompleted)
        }
        else if section == "cash-flow-statement" {
            result = WebpageScraper.scrapeRowForDoubles(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Cash Flow From Investing Activities")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.capExpend = result.array?.positives() // converted from negative for more intuitive correlation display in ValueLIstTVC and WBValuationTVC
            
            result = WebpageScraper.scrapeRowForDoubles(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Cash Flow From Operating Activities")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.opCashFlow = result.array

            self.progressDelegate?.progressUpdate(allTasks: self.downloadTasks, completedTasks: self.downloadTasksCompleted)
        }
        else if section == "financial-ratios" {
            result = WebpageScraper.scrapeRowForDoubles(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "ROE - Return On Equity")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.roe = result.array

            result = WebpageScraper.scrapeRowForDoubles(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "ROA - Return On Assets")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.roa = result.array
            
            result = WebpageScraper.scrapeRowForDoubles(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Book Value Per Share")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.bvps = result.array
            
            self.progressDelegate?.progressUpdate(allTasks: self.downloadTasks, completedTasks: self.downloadTasksCompleted)
        }
        else if section == "pe-ratio" {
            result = WebpageScraper.scrapeColumn(html$: html$, tableHeader: "PE Ratio Historical Data</th>")
            share?.peRatio = result.array?.last ?? Double()
            downloadErrors.append(contentsOf: result.errors)
            
            let (results,errors) = WebpageScraper.scrapePERDatesTable(html$: html$, tableHeader: "PE Ratio Historical Data</th>")
            downloadErrors.append(contentsOf: errors)
            valuation?.savePERWithDateArray(datesValuesArray: results)

            self.progressDelegate?.progressUpdate(allTasks: self.downloadTasks ,completedTasks: self.downloadTasksCompleted)
        }
        else if section == "stock-price-history" {
            result = WebpageScraper.scrapeColumn(html$: html$, tableHeader: "Historical Annual Stock Price Data</th>", tableTerminal: "</td>\n\t\t\t\t </tr>\n\n\t\t\t\t\t\t\n\t\t\t\t</tbody>\n\t\t\t",noOfColumns: 7, targetColumnFromRight: 5) //    </table>\t\t\t\n\t\t\t\n\t\t\t</div>
            valuation?.avAnStockPrice = result.array?.reversed()
            downloadErrors.append(contentsOf: result.errors)

            self.progressDelegate?.progressUpdate(allTasks: self.downloadTasks ,completedTasks: self.downloadTasksCompleted)
        }
        
        
        if downloadTasksCompleted == downloadTasks {
            self.valuation?.date = Date()
            self.valuation?.save()

            self.progressDelegate?.downloadComplete()
        }
    }
}



