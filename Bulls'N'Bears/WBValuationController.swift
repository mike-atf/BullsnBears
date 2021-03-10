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
    
    var sectionTitles = ["Key ratios","Main parameters", "Secondary parameters","Expenses"]
    var sectionSubTitles = ["from Yahoo finance","Growth EMA (from MacroTrends data)","Growth EMA (from MacroTrends data)","Growth EMA (from MacroTrends data)"]
    var rowTitles: [[String]]!
    var stock: Stock!
    var valuation: WBValuation?
    weak var progressDelegate: ProgressViewDelegate?
    var downloadTasks = 0
    var downloadTasksCompleted = 0
    var downloadErrors = [String]()
    var downloader: WebDataDownloader?
    var valueListChartLegendTitles = [
        [["YoY Growth","Retained earnings"],
         ["YoY Growth","EPS"],
         ["Growth net income % of revenue","net income","revenue"],
         ["Growth profit % of revenue","profit","revenue"],
         ["Growth LT debt % of net income","LT debt","revenue"]
        ],
        [["YoY Growth","Return of equity"],
         ["YoY Growth","Return on assets"],
         ["Growth lt debt % of [equity+ret. earnings]","lt debt","equity + ret. earnings"]
        ],
        [["Growth SGA % of profit","SGA","profit"],
         ["Growth R&D % of profit","R&D","profit"]
        ]]
    var wbvParameters = WBVParameters()
//    var valueListTVCSectionTitles = [[[String]]]()// [
//                                    [
//                                        ["Growth of retained earnings"],
//                                        ["EPS"],
//                                        ["Growth of net income % of revenue", "Revenue"],
//                                        ["Growth of profit % of revenue", "Revenue"],
//                                        ["Growth of LT debt % of net income", "Net income"]
//                                    ],
//                                    [
//                                        ["Growth of return on equity"],
//                                        ["Growth of return on assets"],
//                                        ["Growth of LT debt % of equity + ret. earnings", "equity + ret. earnings"]
//
//                                    ],
//                                    [
//                                        ["Growth of SGA % of profit", "Profit"],
//                                        ["Growth of R&D % of profit", "Profit"]
//                                    ]
//    ]
 
    
    //MARK: - init

    init(stock: Stock, progressDelegate: ProgressViewDelegate) {
        
        super.init()
        
        self.stock = stock
        self.progressDelegate = progressDelegate
        
        if let valuation = WBValuationController.returnWBValuations(company: stock.symbol)?.first {
            self.valuation = valuation
        }
        else {
            self.valuation = WBValuationController.createWBValuation(company: stock.symbol)
        }
                
        rowTitles = buildRowTitles()
    }
    
    //MARK: - class functions
    
    static func returnWBValuations(company: String? = nil) -> [WBValuation]? {
        
        var valuations: [WBValuation]?
        
        let fetchRequest = NSFetchRequest<WBValuation>(entityName: "WBValuation")
        if let validName = company {
            let predicate = NSPredicate(format: "company BEGINSWITH %@", argumentArray: [validName])
            fetchRequest.predicate = predicate
        }
        
        do {
            valuations = try (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.fetch(fetchRequest)
            } catch let error {
                ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: error, errorInfo: "error fetching Rule1Valuation")
        }

        return valuations
    }
    
    static func summaryRating(symbol: String, type: RatingCircleSymbols) -> RatingCircleData {
        
        var data = RatingCircleData(rating: nil, maximum: nil, symbol: nil)
        
        let stock = stocks.filter { (s) -> Bool in
            if s.symbol == symbol { return true }
            else { return false }
        }.first
        
        guard let wbv = returnWBValuations(company: symbol)?.first else {
            return data
        }
        
        if type == .star {
            var userSummaryScore: Double = 0
            var maximumScoreSum: Double = 0
            
            for element in wbv.userEvaluations ?? [] {
                if let evaluation = element as? UserEvaluation {
                    if let valid = evaluation.userRating() {
                        userSummaryScore += Double(valid)
                        maximumScoreSum += 10.0
                    }
                }
            }
        
            data.max = maximumScoreSum
            data.rating = userSummaryScore
            data.symbol = .star

            stock?.userRatingScore = data
        }
        else {
            
            if let values = valueSummaryScore(valuation: wbv) {
                data.rating = values[1]
                data.max = values[2]
                data.min = values[0]
                data.symbol = .dollar
            }
            stock?.fundamentalsScore = data
        }
        
        return data

    }
    
    
    static func valueSummaryScore(valuation: WBValuation) -> [Double]? {
        
        return valuation.valuesSummaryScores()
    }

    static func createWBValuation(company: String) -> WBValuation? {
        
        let newValuation:WBValuation? = {
            NSEntityDescription.insertNewObject(forEntityName: "WBValuation", into: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext) as? WBValuation
        }()
        newValuation?.company = company
        do {
            try  (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.save()
        } catch {
            let error = error
            ErrorController.addErrorLog(errorLocation: #file + "."  + #function, systemError: error, errorInfo: "error creating and saving Rule1Valuation")
        }

        return newValuation
    }
    
    //MARK: - TVC controller functions
    
    public func rowTitle(path: IndexPath) -> String {
        return rowTitles[path.section][path.row]
    }
    
    public func sectionHeaderText(section: Int) -> (String, String) {
        return (sectionTitles[section], sectionSubTitles[section])
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
                if let valid = stock.peRatio {
                    value$ = numberFormatterDecimals.string(from: valid as NSNumber)
                    color = GradientColorFinder.gradientColor(lowerIsGreen: true, min: 0, max: 40, value: valid, greenCutoff: 10.0, redCutOff: 40.0)
                    valuation?.peRatio = valid
                    valuation?.save()
                }
                let sixMonthsAgo = Date().addingTimeInterval(-183*24*3600)
                let twoYearsAgo = sixMonthsAgo.addingTimeInterval(-2*365*24*3600)
                if let (min, _, max) = valuation?.minMeanMaxPER(from: twoYearsAgo, to: sixMonthsAgo) {
                    let minMAxValue$ = " (" + numberFormatterNoFraction.string(from: min as NSNumber)! + " - " + numberFormatterNoFraction.string(from: max as NSNumber)! + ")"
                    value$?.append(minMAxValue$)
                }
                
            case 1:
                if let valid = stock.eps {
                    value$ = currencyFormatterGapWithPence.string(from: valid as NSNumber)
                    color = valid > 0 ? GradientColorFinder.greenGradientColor() : GradientColorFinder.redGradientColor()
                }
            case 2:
                let lastStockPrice = stock.dailyPrices.last?.close
                if let valid = valuation?.bvps?.first {
                    if lastStockPrice != nil {
                        if let t$ = percentFormatter0Digits.string(from: (valid / lastStockPrice!) as NSNumber) {
                            if let t2$ = currencyFormatterGapWithPence.string(from: valid as NSNumber) {
                                value$ = t$ + " (" + t2$ + ")"
                            }
                            else {
                                value$ = currencyFormatterGapWithPence.string(from: valid as NSNumber)
                            }
                        }
                    }
//                    color = valid > 0 ? GradientColorFinder.greenGradientColor() : GradientColorFinder.redGradientColor()
                }
//                else if let r1v = CombinedValuationController.returnR1Valuations(company: stock.symbol)?.first {
//                    if let valid = r1v.bvps?.first {
//                        value$ = currencyFormatterGapWithPence.string(from: valid as NSNumber)
////                        color = valid > 0 ? GradientColorFinder.greenGradientColor() : GradientColorFinder.redGradientColor()
//                    }
//                }
            case 3:
                if let valid = stock.beta {
                    value$ = numberFormatterDecimals.string(from: valid as NSNumber)
                }
            case 4:
                valuation?.peRatio = stock.peRatio ?? Double()

                let (valid, es$) = valuation!.ivalue()
                errors = es$
                if valid != nil {
                    value$ = currencyFormatterGapWithPence.string(from: valid! as NSNumber)
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
                let retEarningsGrowths = valuation?.equityRepurchased?.growthRates()
                
                if let meanGrowth = retEarningsGrowths?.ema(periods: emaPeriod) {
                    value$ = percentFormatter0DigitsPositive.string(from: meanGrowth as NSNumber) ?? "-"
                    color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 100, value: meanGrowth, greenCutoff: 0.05, redCutOff: 0.05)
                }

                return (value$, color, errors)
            case 1:
                var years = [Double]()
                var count = 0.0
                for _ in valuation?.eps ?? [] {
                    years.append(count)
                    count += 1.0
                }
                
                if let growthRatesMean = valuation?.eps?.growthRates()?.ema(periods: emaPeriod) {
                    value$ = percentFormatter0DigitsPositive.string(from: growthRatesMean as NSNumber) ?? "-"
                    color = growthRatesMean > 0 ? GradientColorFinder.greenGradientColor() : GradientColorFinder.redGradientColor()
                }

                return (value$,color,errors)
            case 2:
                let (proportions, es$) = valuation!.netIncomeProportion()
//                print()
//                print("\(stock.symbol) net income props \(proportions)")
                errors = es$
                if let average = proportions.ema(periods: emaPeriod) {
                    value$ = percentFormatter0Digits.string(from: average as NSNumber) ?? "-"
                    color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 100, value: average, greenCutoff: 0.2, redCutOff: 0.1)
                }
//                print("\(stock.symbol) net income ema \(value$)")
//                print()
                return (value$, color, errors)
            case 3:
                let (margins, es$) = valuation!.grossProfitMargins()
                errors = es$
                if let averageMargin = margins.ema(periods: emaPeriod) { //weightedMean()
                    value$ = percentFormatter0Digits.string(from: averageMargin as NSNumber) ?? "-"
                    color = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 40, value: averageMargin, greenCutoff: 0.4, redCutOff: 0.2)
                }
                return (value$,color,errors)
            case 4:
                let (proportions, es$) = valuation!.longtermDebtProportion()
                errors = es$
                if let average = proportions.ema(periods: emaPeriod) {
                    value$ = percentFormatter0Digits.string(from: average as NSNumber) ?? "-"
                    color = GradientColorFinder.gradientColor(lowerIsGreen: true, min: 0, max: 100, value: average, greenCutoff: 3.0, redCutOff: 4.0)
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
                let roeGrowths = valuation?.roe?.filter({ (element) -> Bool in
                    if element != 0.0 { return true }
                    else { return false }
                }).growthRates()
                
                if let meanGrowth = roeGrowths?.ema(periods: emaPeriod) {
                    value$ = percentFormatter0DigitsPositive.string(from: meanGrowth as NSNumber) ?? "-"
                }

                return (value$, color, errors)

            case 1:
                let roaGrowths = valuation?.roa?.filter({ (element) -> Bool in
                    if element != 0.0 { return true }
                    else { return false }
                }).growthRates()
                
                if let meanGrowth = roaGrowths?.ema(periods: emaPeriod) {
                    value$ = percentFormatter0DigitsPositive.string(from: meanGrowth as NSNumber) ?? "-"
                }

                return (value$, color, errors)

            case 2:
                
                let (shEquityWithRetEarnings, error) = valuation!.addElements(array1: valuation!.shareholdersEquity ?? [], array2: valuation!.equityRepurchased ?? [])
                if error != nil {
                    errors = [error!]
                }
                let first3Average = shEquityWithRetEarnings?.average(of: 3)
                let (proportions, es$) = valuation!.proportions(array1: shEquityWithRetEarnings, array2: valuation?.debtLT)
                if es$ != nil {
                    if errors != nil { errors?.append(contentsOf: es$!) }
                    else { errors = es$! }
                }
                if let average = proportions.ema(periods: emaPeriod) {
                    if first3Average ?? 0 < 0 && average < 0 {
                        // recently negative equity resulting in wrongly negative LT debt
                        value$ = "neg!"
                        errors = ["Long-term debt set against recently negative equity with retained earnings"]
                        color = GradientColorFinder.redGradientColor()
                    }
                    else {
                        value$ = percentFormatter0Digits.string(from: average as NSNumber) ?? "-"
                        color = GradientColorFinder.gradientColor(lowerIsGreen: true, min: 0, max: 100, value: average, greenCutoff: 0.8, redCutOff: 0.8 )
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
                let (proportions, es$) = valuation!.sgaProportion()
                errors = es$
                if let average = proportions.ema(periods: emaPeriod) { //proportions.mean()
                    //.filter({ (element) -> Bool in
//                    if element != 0.0 { return true }
//                    else { return false }
//                })
                    value$ = percentFormatter0Digits.string(from: average as NSNumber) ?? "-"
                    color = GradientColorFinder.gradientColor(lowerIsGreen: true, min: 0, max: 40, value: average, greenCutoff: 0.3, redCutOff: 1.0)
                }
                return (value$, color, errors)
            case 1:
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
    
    public func valueListTVCProportions(values: [[Double]?]?) -> [Double]? {
        
        var proportions: [Double]?
        
        if values?.count ?? 0 > 1 {
            proportions = Calculator.proportions(array1: values?.first!, array0: values?.last!)
        }
        else {
            if let array1 = values!.first {
                proportions = array1?.growthRates()
            }
        }
        return proportions
    }
    
    // MARK: - internal functions
    
    private func buildRowTitles() -> [[String]] {
        // careful when changing these - terms and order are linked to WBVParameters() in public vars
        // and used in identifying UserEvaluation.wbvParameter via 'userEvaluation(for indexpath)' below
        return [["P/E ratio", "EPS", "Book value /share price","beta", "intr. value (10y)"], ["Ret. earnings growth", "EPS growth", "Net inc./ Revenue growth","profit margin growth","LT Debt / net income growth"],["Return on equity growth", "Return on assets growth","LT debt / adj.sh.equity"],["SGA / Revenue growth", "R&D / profit growth"]]
    }
        
    // MARK: - Data download functions
    
    func downloadWBValuationData() {
        
        let webPageNames = ["financial-statements", "balance-sheet", "financial-ratios","pe-ratio", "stock-price-history"]
        
        guard stock.name_short != nil else {
            alertController.showDialog(title: "Unable to load WB valuation data for \(stock.symbol)", alertMessage: "can't find a stock short name in dictionary.")
            return
        }
                
        downloader = WebDataDownloader(stock: stock, delegate: self)
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

        // [["P/E ratio", "EPS", "beta", "intr. value (10y)"], ["Ret. earnings growth", "EPS growth", "Net inc./ Revenue growth","profit margin growth","LT Debt / net income growth"],["Return on equity growth", "Return on assets growth","LT debt / adj.sh.equity"],["SGA / Revenue growth", "R&D / profit growth"]]
        
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
         
        newValuation.stock = stock.symbol
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
            for element in valuation?.userEvaluations ?? [] {
                if let evaluation = element as? UserEvaluation {
                    if evaluation.wbvParameter == parameter {
                        evaluation.comment = valid
                        evaluation.save()
//                        print("user notes saved: \(evaluation.comment)")
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
                    evaluation.save()
                }
            }
        }
    }
    
 }

extension WBValuationController: DataDownloaderDelegate {
    
    func downloadComplete(html$: String?, pageTitle: String?) {
        
        downloadTasksCompleted += 1
        
        guard html$ != nil else {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "download complete, html string is empty")
            return
        }
        
        guard let section = pageTitle else {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "download complete - notification did not contain section info!!")
            return
        }
        
        var result:(array: [Double]?, errors: [String])

        if section == "financial-statements" {
            result = WebpageScraper.scrapeRow(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Revenue")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.revenue = result.array
            
            result = WebpageScraper.scrapeRow(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Gross Profit")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.grossProfit = result.array
            
            result = WebpageScraper.scrapeRow(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Research And Development Expenses")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.rAndDexpense = result.array

            result = WebpageScraper.scrapeRow(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "SG&amp;A Expenses")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.sgaExpense = result.array
            
            result = WebpageScraper.scrapeRow(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Net Income")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.netEarnings = result.array
            
            result = WebpageScraper.scrapeRow(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Operating Income")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.operatingIncome = result.array
            
            result = WebpageScraper.scrapeRow(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "EPS - Earnings Per Share")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.eps = result.array

            DispatchQueue.main.async {
                self.progressDelegate?.progressUpdate(allTasks: self.downloadTasks, completedTasks: self.downloadTasksCompleted)
            }
        }
        else if section == "balance-sheet" {
            result = WebpageScraper.scrapeRow(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Long Term Debt")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.debtLT = result.array
            
            result = WebpageScraper.scrapeRow(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Propoerty, Plant, And Equipment")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.ppe = result.array
            
            result = WebpageScraper.scrapeRow(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Retained Earnings (Accumulated Deficit)")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.equityRepurchased = result.array

            result = WebpageScraper.scrapeRow(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Share Holder Equity")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.shareholdersEquity = result.array
            
            DispatchQueue.main.async {
                self.progressDelegate?.progressUpdate(allTasks: self.downloadTasks, completedTasks: self.downloadTasksCompleted)
            }
        }
        else if section == "financial-ratios" {
            result = WebpageScraper.scrapeRow(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "ROE - Return On Equity")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.roe = result.array

            result = WebpageScraper.scrapeRow(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "ROA - Return On Assets")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.roa = result.array
            
            result = WebpageScraper.scrapeRow(website: .macrotrends, html$: html$, sectionHeader: nil, rowTitle: "Book Value Per Share")
            downloadErrors.append(contentsOf: result.errors)
            valuation?.bvps = result.array
            
            DispatchQueue.main.async {
                self.progressDelegate?.progressUpdate(allTasks: self.downloadTasks, completedTasks: self.downloadTasksCompleted)
            }
        }
        else if section == "pe-ratio" {
            result = WebpageScraper.scrapeColumn(html$: html$, tableHeader: "PE Ratio Historical Data</th>")
            valuation?.peRatio = result.array?.last ?? Double()
            downloadErrors.append(contentsOf: result.errors)
            
            let (results,errors) = WebpageScraper.scrapePERDatesTable(html$: html$, tableHeader: "PE Ratio Historical Data</th>")
            downloadErrors.append(contentsOf: errors)
            valuation?.savePERWithDateArray(datesValuesArray: results)

            DispatchQueue.main.async {
                self.progressDelegate?.progressUpdate(allTasks: self.downloadTasks ,completedTasks: self.downloadTasksCompleted)
            }

        }
        else if section == "stock-price-history" {
            result = WebpageScraper.scrapeColumn(html$: html$, tableHeader: "Historical Annual Stock Price Data</th>", tableTerminal: "</td>\n\t\t\t\t </tr>\n\n\t\t\t\t\t\t\n\t\t\t\t</tbody>\n\t\t\t",noOfColumns: 7, targetColumnFromRight: 5) //    </table>\t\t\t\n\t\t\t\n\t\t\t</div>
            valuation?.avAnStockPrice = result.array?.reversed()
            downloadErrors.append(contentsOf: result.errors)

            DispatchQueue.main.async {
                self.progressDelegate?.progressUpdate(allTasks: self.downloadTasks ,completedTasks: self.downloadTasksCompleted)
            }

        }
        
        if downloadTasksCompleted == downloadTasks {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateValuationData"), object: self.downloadErrors , userInfo: nil)
            }
        }
    }
}
