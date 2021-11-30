//
//  PublicVars.swift
//  TrendMyStocks
//
//  Created by aDav on 01/12/2020.
//

import UIKit
import CoreData

enum DownloadAndAnalysisError: Error {
    case mimeType
    case urlError
    case emptyWebpageText
    case htmlTableTitleNotFound
    case htmlTableEndNotFound
    case htmTablelHeaderStartNotFound
    case htmlTableHeaderEndNotFound
    case htmlTableRowEndNotFound
    case htmlTableRowStartIndexNotFound
    case htmlTableBodyStartIndexNotFound
    case htmlTableBodyEndIndexNotFound
    case htmlTableSequenceStartNotFound
    case urlInvalid
    case shareSymbolMissing
    case shareShortNameMissing
    case shareWBValuationMissing
    case noBackgroundShareWithSymbol
    case htmlSectionTitleNotFound
    case htmlRowStartIndexNotFound
    case htmlRowEndIndexNotFound
    case contentStartSequenceNotFound
    case noBackgroundMOC
    case htmlTableTextNotExtracted
    case fileFormatNotCSV
    case couldNotFindCompanyProfileData
    case generalDownloadError
    case downloadedFileURLinvalid
}

enum InternalErrors: Error {
    case missingPricePointsInShareCreation
    case noValidBackgroundMOC
    case noShareFetched
    case urlPathError
    case mocReadError
}

typealias ShareID_Symbol_sName = (id: NSManagedObjectID, symbol: String?, shortName: String?)
typealias ShareID_Value = (id: NSManagedObjectID, value: Double?)
typealias Dated_EPS_PER_Values = (date: Date, epsTTM: Double, peRatio: Double)
typealias ShareID_DatedValues = (id: NSManagedObjectID, values: [DatedValue]?)
typealias PriceDate = (date: Date, price: Double)
typealias TrendInfoPackage = (incline: Double?, endPrice: Double, pctIncrease: Double, increaseMin: Double, increaseMax: Double)
typealias ProfileData = (sector: String, industry: String, employees: Double)
typealias LabelledValue = (label: String, value: Double?)
typealias LabelledValues = (label: String, values: [Double])
typealias Labelled_DatedValues = (label: String, datedValues: [DatedValue])
typealias DatedValue = (date: Date, value: Double)
typealias ShareNamesDictionary = (symbol: String, shortName: String)
typealias LabelledFileURL = (symbol: String, fileURL: URL)
typealias ScoreData = (score: Double, maxScore: Double, factorArray: [String])

//var stocks = [Stock]()
var foreCastTime: TimeInterval = 30*24*3600
//var managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
var errorLog: [ErrorLog]?
let gradientBarHeight = UIImage(named: "GradientBar")!.size.height - 1
let gradientBar = UIImage(named: "GradientBar")
let userDefaultTerms = UserDefaultTerms()
let sharesListSortParameter = SharesListSortParameter()
var valuationWeightsSingleton = ShareFinancialsValueWeights()

var yahooRefDate: Date = {
    let calendar = Calendar.current
    let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]
    var dateComponents = calendar.dateComponents(components, from: Date())
    dateComponents.second = 0
    dateComponents.minute = 0
    dateComponents.hour = 0
    dateComponents.year = 1970
    dateComponents.day = 1
    dateComponents.month = 1
    return calendar.date(from: dateComponents) ?? Date()
}()

var yahooPricesStartDate: Date {
    let calendar = Calendar.current
    let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]
    var dateComponents = calendar.dateComponents(components, from: Date())
    dateComponents.second = 0
    dateComponents.minute = 0
    dateComponents.hour = 0
    dateComponents.year! -= 1
    return calendar.date(from: dateComponents) ?? Date()
}

var yahooPricesEndDate: Date {
    let calendar = Calendar.current
    let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]
    var dateComponents = calendar.dateComponents(components, from: Date())
    dateComponents.second = 0
    dateComponents.minute = 0
    dateComponents.hour = 0
    return calendar.date(from: dateComponents) ?? Date()
}


var stockTickerDictionary: [String:String]? = {
        
    guard let fileURL = Bundle.main.url(forResource: "StockTickerDictionary", withExtension: "csv") else {
        return nil
    }
    
    do {
        if let data = FileManager.default.contents(atPath: fileURL.path) {
            return try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String: String]
        }
    } catch let error {
        ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "can't read stock ticker dictionary data from Main bundle file")
    }
    
    return nil
}()

var appVersion:String = {
    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
        return version
    } else { return "Version Number not Available" }
}()
    
var appBuild: String = {
    if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
        return build
    } else { return "Build Number not Available" }
}()

var alertController = AlertController()

enum Website {
    case yahoo
    case macrotrends
}

enum ValuationCellValueFormat {
    case currency
    case percent
    case numberWithDecimals
    case numberNoDecimals
    case date
    case text
}

enum ValuationMethods {
    case dcf
    case rule1
    case wb
}

enum FindOptions {
    case minimum
    case maximum
}

enum PricePointOptions {
    case open
    case high
    case close
    case low
    case volume
}

enum TrendValue {
    case mean
    case recentWeighted
    case timeWeighted
}

enum TrendType {
    case bottom
    case ceiling
    case regression
}

enum TrendTimeOption {
    case half
    case quarter
    case full
    case month
}


struct RatingCircleData {
    var rating: Double?
    var max: Double?
    var min: Double = 0.0
    var symbol: RatingCircleSymbols?
    
    init(rating: Double?, maximum: Double?, minimum: Double?=0.0, symbol: RatingCircleSymbols?) {
        self.rating = rating
        self.max = maximum
        self.min = minimum ?? 0.0
        self.symbol = symbol
    }
    
    func ratingScore() -> Double? {
        
        guard let validMax = max else { return nil }
        
        guard let validRating = rating else { return nil }
        
        let range = validMax - min
        return validRating / range
    }
}

enum RatingCircleSymbols {
    case star
    case dollar
}

struct UserDefaultTerms {
    let longTermCoporateInterestRate = "LongTermCoporateInterestRate"
    let treasuryBondRate = "10YUSTreasuryBondRate"
    let perpetualGrowthRate = "PerpetualGrowthRate"
    let longTermMarketReturn = "LongTermMarketReturn"
    let emaPeriodAnnualData = "emaPeriodAnnualData"
    let sortParameter = "sortParameter"
    let lastCitation = "lastCitation"
    let newestMTDataDate = "NewestMTDataDate"
    let valuationFactorWeights = "valuationFactorWeights"
}

struct SharesListSortParameter {
    
    let userEvaluationScore = "userEvaluationScore"
    let valueScore = "valueScore"
    let industry = "industry"
    let sector = "sector"
    let growthType = "growthType"
    let symbol = "symbol"
    
    func options() -> [String] {
        
        var properties = [String]()
        
        let mirror = Mirror(reflecting: self)
        
        for child in mirror.children {
            if let label = child.value as? String {
            properties.append(label)
            }
        }
        return properties
    }
    
    func displayTerm(term: String) -> String {
        if term == userEvaluationScore { return "User rating" }
        else if term == valueScore { return "Financials score" }
        else if term == growthType { return "Growth type" }
        else { return term.capitalized }
    }
    
    func displayToUserDefaults(term: String) -> String {
        if term == "User rating" { return userEvaluationScore }
        else if term == "Financials score" { return  valueScore}
        else if term == "Growth type" { return growthType }
        else { return term.lowercased() }

    }
}


let currencyFormatterGapNoPence: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.currencySymbol = "$ "
    formatter.numberStyle = NumberFormatter.Style.currency
    formatter.maximumFractionDigits = 0
    formatter.usesGroupingSeparator = true
    return formatter
}()

let currencyFormatterNoGapNoPence: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.currencySymbol = "$"
    formatter.numberStyle = NumberFormatter.Style.currency
    formatter.maximumFractionDigits = 0
    formatter.usesGroupingSeparator = true
    return formatter
}()


let currencyFormatterNoGapWithPence: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.currencySymbol = "$"
    formatter.numberStyle = NumberFormatter.Style.currency
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    formatter.usesGroupingSeparator = true
    return formatter
}()

let currencyFormatterGapWithPence: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.currencySymbol = "$ "
    formatter.numberStyle = NumberFormatter.Style.currency
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    formatter.usesGroupingSeparator = true
    return formatter
}()

let currencyFormatterGapWithOptionalPence: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.currencySymbol = "$ "
    formatter.numberStyle = NumberFormatter.Style.currency
    formatter.maximumFractionDigits = 2
    formatter.usesGroupingSeparator = true
    return formatter
}()



let percentFormatter2Digits: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .percent
    formatter.maximumFractionDigits = 2
    formatter.minimumIntegerDigits = 1
    return formatter
}()

let percentFormatter0Digits: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .percent
    formatter.maximumFractionDigits = 0
    formatter.minimumIntegerDigits = 1
    return formatter
}()

let percentFormatter2DigitsPositive: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .percent
    formatter.positivePrefix = "+"
//    formatter.positiveFormat =
    formatter.maximumFractionDigits = 2
    formatter.minimumIntegerDigits = 1
    return formatter
}()

let percentFormatter0DigitsPositive: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .percent
    formatter.positivePrefix = "+"
//    formatter.positiveFormat =
    formatter.maximumFractionDigits = 0
    formatter.minimumIntegerDigits = 1
    return formatter
}()


let numberFormatterWith1Digit: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 1
    formatter.minimumIntegerDigits = 1
    formatter.usesGroupingSeparator = true
    return formatter
}()

let numberFormatterDecimals: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 2
//    formatter.minimumFractionDigits = 2
    formatter.minimumIntegerDigits = 1
    formatter.usesGroupingSeparator = true
    return formatter
}()

let numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = 0
    formatter.minimumIntegerDigits = 1
    return formatter
}()


let numberFormatterNoFraction: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = 0
    formatter.numberStyle = .decimal
    formatter.minimumIntegerDigits = 1
    formatter.usesGroupingSeparator = true
    return formatter
}()


let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = NSLocale.current
    formatter.timeZone = NSTimeZone.local
    formatter.dateStyle = .short
    return formatter
}()

struct ErrorLog {
    var location = String()
    var systemMessage: Error?
    var errorInfo = String()
    
    mutating func create(location: String, systemError: NSError? = nil, errorInfo: String) {
        self.location = location
        self.errorInfo = errorInfo
        if systemError != nil {
            self.systemMessage = NSError()
            self.systemMessage = systemError
        }
    }
}


struct Correlation {
    var incline = Double()
    var yIntercept = Double()
    var coEfficient = Double()
    var xElements = Int()
    
    init(m: Double, b: Double, r: Double, xElements: Int) {
        self.incline = m
        self.yIntercept = b
        self.coEfficient = r
        self.xElements = xElements
    }
    
    /// increase/ decline in % from yIntercept to endpoint using timeInterval as x-axis
    public func meanGrowth(for xElements: Double?=nil) -> Double? {
        
        guard (xElements ?? Double(self.xElements)) > 0 else {
            return nil
        }
        
        let intercept = (yIntercept != 0) ? yIntercept : 1
        
        let endPoint = incline * (xElements ?? Double(self.xElements)) + yIntercept
        let change = (endPoint - yIntercept) / abs(intercept)
        
        return change / (xElements ?? Double(self.xElements))
    }
    
    public func compoundGrowthRate(for xElements: Double?=nil) -> Double {
        
        let endPoint = incline * (xElements ?? Double(self.xElements)) + yIntercept
        return (pow((endPoint/yIntercept), (1/((xElements ?? Double(self.xElements))-1)))-1)
    }
    
    public func endValue(for xElements: Double?=nil) -> Double {
        return yIntercept + (xElements ?? Double(self.xElements)) * incline
    }
    
    public func r2() -> Double? {
        if coEfficient != Double() {
            return (coEfficient * coEfficient) // should be '*100' but use precentFormatter to display as %
        }
        else { return nil }
    }
}

struct TrendProperties {
    var type: TrendType!
    var time: TrendTimeOption!
    var dash: Bool!
    var color: UIColor!
    
    init(type: TrendType, time: TrendTimeOption, dash: Bool? = false) {
        self.type = type
        self.time = time
        self.dash = dash
        switch type {
        case .bottom:
            self.color = UIColor.systemRed
        case .regression:
            self.color = UIColor.systemBlue
        case .ceiling:
            self.color = UIColor(named: "Green")
        }
    }
}

struct PricePoint: Codable, Hashable {
    
    var tradingDate: Date
    var open: Double
    var high: Double
    var low: Double
    var close: Double
    var volume: Double
    
    init(open: Double, close: Double, low: Double, high: Double, volume: Double, date: Date) {
        
        self.open = open
        self.close = close
        self.low = low
        self.high = high
        self.volume = volume
        
        var calendar = NSCalendar.current
        calendar.timeZone = NSTimeZone.default
        
        let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]
        var dateComponents = calendar.dateComponents(components, from: date)
        dateComponents.second = 0
        dateComponents.minute = 0
        dateComponents.hour = 0
        self.tradingDate = calendar.date(from: dateComponents) ?? date
    }
    
    func returnPrice(option: PricePointOptions) -> Double {
    
    switch option {
    case .low:
            return low
        case .high:
            return high
        case .open:
            return open
        case .close:
            return close
        case .volume:
            return volume
    }
}
    
    /// expected that self.tradsingDate is LATER than pricepoint.tradingDate
    /// otherwise a negative incline would be returned instead of a positive and vice versa
    public func returnIncline(pricePoint: PricePoint, priceOption: PricePointOptions) -> Double {
        
        return (pricePoint.returnPrice(option: priceOption) - self.returnPrice(option: priceOption)) / pricePoint.tradingDate.timeIntervalSince(self.tradingDate)

    }
    
}

struct ShareFinancialsValueWeights {
    
    var peRatio = 1.0
    var retEarningsGrowth = 1.0
    var lynchScore = 1.0
    var moatScore = 1.0
    var epsGrowth = 1.0
//    var netIncomeDivRevenue = 1.0
    var capExpendDivEarnings = 0.25
    var profitMargin = 0.25
    var ltDebtDivIncome = 0.25
    var opCashFlowGrowth = 0.25
//    var ltDebtDivadjEq = 1.0
    var sgaDivProfit = 0.25
    var radDivProfit = 0.25
    var revenueGrowth = 0.25
//    var netIncomeGrowth = 0.5
    var roeGrowth = 0.5
    var futureEarningsGrowth = 1.5
    
    init() {
        if let defaults = UserDefaults.standard.value(forKey: userDefaultTerms.valuationFactorWeights) as? ShareFinancialsValueWeights {
            self.peRatio = defaults.peRatio
            self.retEarningsGrowth = defaults.retEarningsGrowth
            self.lynchScore = defaults.lynchScore
            self.moatScore = defaults.moatScore
            self.epsGrowth = defaults.epsGrowth
//            self.netIncomeDivRevenue = defaults.netIncomeDivRevenue
            self.capExpendDivEarnings = defaults.capExpendDivEarnings
            self.profitMargin = defaults.profitMargin
//            self.ltDebtDivadjEq = defaults.ltDebtDivadjEq
            self.opCashFlowGrowth = defaults.opCashFlowGrowth
            self.sgaDivProfit = defaults.sgaDivProfit
            self.radDivProfit = defaults.radDivProfit
            self.revenueGrowth = defaults.revenueGrowth
//            self.netIncomeGrowth = defaults.netIncomeGrowth
            self.roeGrowth = defaults.roeGrowth
            self.futureEarningsGrowth = defaults.futureEarningsGrowth
        }
    }
    
    public func saveUserDefaults() {
        UserDefaults.standard.set(self, forKey: userDefaultTerms.valuationFactorWeights)
    }
    
    public func weightsSum() -> Double? {
        
        let mirror = Mirror(reflecting: self)
        
        var sum: Double?
        for child in mirror.children {
            if sum == nil { sum = Double() }
            if let value = child.value as? Double {
                sum! += value
            }
        }
        return sum
    }
    
    public func maxWeightValue() -> Double? {
        
        let mirror = Mirror(reflecting: self)
        var sum = [Double]()
        
        for property in mirror.children {
            if let value = property.value as? Double {
                sum.append(value)
            }
        }
        
        return sum.max()
    }
    
    public func minWeightValue() -> Double? {
        
        let mirror = Mirror(reflecting: self)
        var sum = [Double]()
        
        for property in mirror.children {
            if let value = property.value as? Double {
                sum.append(value)
            }
        }
        
        return sum.min()
    }

    
    public func weightsCount() -> Int {
        
        let mirror = Mirror(reflecting: self)
        
        return mirror.children.count
    }
    
    public func propertyNameList() -> [String] {
        
        let mirror = Mirror(reflecting: self)
        var list = [String]()
        
        for property in mirror.children {
            if let title = property.label {
                list.append(title)
            }
        }
        
        return list
    }
    
    public func value(forVariable: String) -> Double? {
        
        let mirror = Mirror(reflecting: self)
        
        for property in mirror.children {
            if let title = property.label {
                if title == forVariable {
                    return property.value as? Double
                }
            }
        }
        
        return nil
    }
    
    /// ret
    public func financialsScore(forShare: Share) -> ScoreData {
        
        print("financials score for \(forShare.symbol!)")
        var allFactors = [Double]()
        var allWeights = [Double]()
        var allFactorNames = [String]()
        let emaPeriods = (UserDefaults.standard.value(forKey: userDefaultTerms.emaPeriodAnnualData) as? Int) ?? 7

// 1 future earnings growth estimate
        if self.futureEarningsGrowth > 0 {
            if let research = forShare.research {
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
                    print("Future earnings growth \(correctedFactor * futureEarningsGrowth) / \(futureEarningsGrowth)")
                    allFactors.append(correctedFactor * futureEarningsGrowth)
                    allWeights.append(futureEarningsGrowth)
                    allFactorNames.append("Future earnings growth")
                }
            }
        }
        
// 2 WBV trailing revenue growth
        if let wbv = forShare.wbValuation {
            
            if let valid = valueFactor(values1: wbv.revenue, values2: nil, maxCutOff: 1, emaPeriod: emaPeriods) {
                print("Revenue growth \(valid * revenueGrowth) / \(revenueGrowth)")
                allFactors.append(valid * revenueGrowth)
                allWeights.append(revenueGrowth)
                allFactorNames.append("Revenue growth trend")
            }
        
// 3 WBC trailing retained earnings growth
            if let valid = valueFactor(values1: wbv.equityRepurchased, values2: nil, maxCutOff: 1, emaPeriod: emaPeriods) {
                print("Ret. earnings growth \(valid * retEarningsGrowth) / \(retEarningsGrowth)")
                allFactors.append(valid * retEarningsGrowth)
                allWeights.append(retEarningsGrowth)
                allFactorNames.append("Ret. earnings growth trend")
            }
            
// 4 WBC trailing EPS growth
            if let valid = valueFactor(values1: wbv.eps, values2: nil, maxCutOff: 1, emaPeriod: emaPeriods) {
                print("EPS growth \(valid * epsGrowth) / \(epsGrowth)")
                allFactors.append(valid * epsGrowth)
                allWeights.append(epsGrowth)
                allFactorNames.append("EPS growth trend")
            }

// 5 WBV Profit margin growth
            if let valid = valueFactor(values1: wbv.revenue, values2: wbv.grossProfit, maxCutOff: 1, emaPeriod: emaPeriods) {
                print("Profit margin growth \(valid * profitMargin) / \(profitMargin)")
                allFactors.append(valid * profitMargin)
                allWeights.append(profitMargin)
                allFactorNames.append("Growth trend profit margin")
            }

// 6 WBV Lynch score
            if let earningsGrowth = wbv.netEarnings?.growthRates()?.ema(periods: emaPeriods) {
                let denominator = (earningsGrowth + forShare.divYieldCurrent) * 100
                if forShare.peRatio > 0 {
                    var value = (denominator / forShare.peRatio) - 1
                    if value > 1 { value = 1 }
                    else if value < 0 { value = 0 }
                    print("Lynch score \(value * lynchScore) / \(lynchScore)")
                    allFactors.append(value * lynchScore)
                    allWeights.append(lynchScore)
                    allFactorNames.append("P Lynch sore")
                }
            }

// 7 WBV CapEx
            if let sumDiv = wbv.netEarnings?.reduce(0, +) {
                // use 10 y sums / averages, not ema according to Book Ch 51
                if let sumDenom = wbv.capExpend?.reduce(0, +) {
                    let tenYAverages = abs(sumDenom / sumDiv)
                    let maxCutOff = 0.5
                    let factor = (tenYAverages < maxCutOff) ? ((maxCutOff - tenYAverages) / maxCutOff) : 0
                    print("CapEx / earnings growth \(factor * capExpendDivEarnings) / \(capExpendDivEarnings)")
                    allFactors.append(factor * capExpendDivEarnings)
                    allWeights.append(capExpendDivEarnings)
                    allFactorNames.append("Growth trend cap. expenditure / net earnings")
                }
            }
            
            if let valid = valueFactor(values1: wbv.roe, values2: nil, maxCutOff: 1, emaPeriod: emaPeriods) {
                print("ROE growth \(valid * roeGrowth) / \(roeGrowth)")
                allFactors.append(valid * roeGrowth)
                allWeights.append(roeGrowth)
                allFactorNames.append("ROE growth trend")
            }

            if let valid = valueFactor(values1: wbv.opCashFlow, values2: nil, maxCutOff: 1, emaPeriod: emaPeriods) {
                print("OCF growth \(valid * opCashFlowGrowth) / \(opCashFlowGrowth)")
                allFactors.append(valid * opCashFlowGrowth)
                allWeights.append(opCashFlowGrowth)
                allFactorNames.append("Op. cash flow growth trend")
            }
            
            if let valid = inverseValueFactor(values1: wbv.netEarnings, values2: wbv.debtLT ?? [], maxCutOff: 3, emaPeriod: emaPeriods, removeZeroElements: false) {
                print("LtDebt / Revenue growth \(valid * ltDebtDivIncome) / \(ltDebtDivIncome)")
                allFactors.append(valid * ltDebtDivIncome)
                allWeights.append(ltDebtDivIncome)
                allFactorNames.append("Growth trend long-term debt / net earnings")
            }

            if let valid = valueFactor(values1: wbv.grossProfit, values2: wbv.sgaExpense ?? [], maxCutOff: 0.4, emaPeriod: emaPeriods) {
                print("SGA growth \(valid * sgaDivProfit) / \(sgaDivProfit)")
                allFactors.append(valid * sgaDivProfit)
                allWeights.append(sgaDivProfit)
                allFactorNames.append("Growth trend SGA expense / profit")
            }
            
            if let valid = valueFactor(values1: wbv.grossProfit, values2: wbv.rAndDexpense ?? [], maxCutOff: 1, emaPeriod: emaPeriods) {
                print("R&D growth \(valid * radDivProfit) / \(radDivProfit)")
                allFactors.append(valid * radDivProfit)
                allWeights.append(radDivProfit)
                allFactorNames.append("Growth trend R&D expense / profit")
            }

        }
        
        if let score = forShare.rule1Valuation?.moatScore() {
            print("Moat \(sqrt(score)*moatScore) / \(moatScore)")
            allFactors.append(sqrt(score)*moatScore)
            allWeights.append(moatScore)
            allFactorNames.append("Moat")
        }
        
        
        let scoreSum = allFactors.reduce(0, +)
        let maximum = allWeights.reduce(0, +)
        
        print("Total factor sum \(scoreSum) / \(maximum)")

        return ScoreData(score: scoreSum, maxScore: maximum, factorArray: allFactorNames)
    }
    
    /// for 'higherIsBetter' values; for 'higherIsWorse' use inverseValueFactor()
    /// for 1 value array: returns nil or ema of values based factor between 0-1 for ema 0-maxCutoff
    /// for 2 arrays returns growth-ema of porportions values2 / values1
    /// values above cutOff are returned as 1.0
    /// ema < 0 is returned as 0
    private func valueFactor(values1: [Double]?, values2: [Double]?, maxCutOff: Double,emaPeriod: Int, removeZeroElements:Bool?=true) -> Double? {
        
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
    private func inverseValueFactor(values1: [Double]?, values2: [Double]?, maxCutOff: Double, emaPeriod: Int, removeZeroElements:Bool?=true) -> Double? {
        
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
    
    /// returns porportions of array 2 / array 1 elements
    private func proportions(array1: [Double]?, array2: [Double]?, removeZeroElements: Bool?=true) -> ([Double], [String]?) {
        
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


        
}
