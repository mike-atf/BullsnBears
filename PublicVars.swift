//
//  PublicVars.swift
//  TrendMyStocks
//
//  Created by aDav on 01/12/2020.
//

import UIKit
import CoreData

enum ShareTrendNames: CaseIterable {
    
    case healthScore
    case moatScore
    case dCFValue
    case stickerPrice
    case lynchScore
    case intrinsicValue
}

enum WebServiceName {
    case macroTrends
    case yahoo
    case yCharts
    case tagesschau
}

typealias ShareID_Symbol_sName = (id: NSManagedObjectID, symbol: String?, shortName: String?)
typealias ShareID_Value = (id: NSManagedObjectID, value: Double?)
typealias Dated_EPS_PER_Values = (date: Date, epsTTM: Double, peRatio: Double)
typealias ShareID_DatedValues = (id: NSManagedObjectID, values: [DatedValue]?)
typealias TrendInfoPackage = (incline: Double?, endPrice: Double, pctIncrease: Double, increaseMin: Double, increaseMax: Double)
//typealias ShareNamesDictionary = (symbol: String, shortName: String)
typealias LabelledFileURL = (symbol: String, fileURL: URL)
typealias ScoreData = (score: Double, maxScore: Double, factorArray: [String])

var foreCastTime: TimeInterval = 30*24*3600
var errorLog: [InternalError]?
let gradientBarHeight = UIImage(named: "GradientBar")!.size.height - 1
let gradientBar = UIImage(named: "GradientBar")
let userDefaultTerms = UserDefaultTerms()
let sharesListSortParameter = SharesListSortParameter()
var valuationFactors = Financial_Valuation_Factors()
let nonRefreshTimeInterval: TimeInterval  = 300

enum Order {
    case ascending
    case descending
}

struct ProfileData {
    var sector: String
    var industry: String
    var employees: Double
    var description: String
}

struct TitleAndDetail {
    var title = String()
    var detail = String()
    
    init(title: String, detail: String) {
        self.title = title
        self.detail = detail
    }
}

struct PageRowServiceTitle {
    var page: String
    var rowTitle: String
    var service: WebpageExtractionCodes
}

struct LabelledValue: Codable {
    var label: String
    var value: Double?
}

struct LabelledValues: Codable {
    var label: String
    var values: [Double]
}

struct Labelled_DatedValues: Codable {
    var label: String
    var datedValues: [DatedValue]
        
    func convertToLabelledValues(dateSortOrder: Order) -> LabelledValues {
        
        let dv = self.datedValues.sorted { dv0, dv1 in
            if dateSortOrder == .ascending {
                if dv0.date < dv1.date { return true }
                else { return false }
            } else {
                if dv0.date > dv1.date { return true }
                else { return false }
            }
        }
        
        let values = dv.compactMap{ $0.value }
        return LabelledValues(label: self.label, values: values)
        
    }
    
    func extractValuesOnly(dateOrder: Order) -> [Double] {
        
        let dv = self.datedValues.sorted { dv0, dv1 in
            if dateOrder == .ascending {
                if dv0.date < dv1.date { return true }
                else { return false }
            } else {
                if dv0.date > dv1.date { return true }
                else { return false }
            }
        }
        
        return dv.compactMap{ $0.value }

    }
    
    /// converts the datedValues to Data. Label should come come from variable
    func convertToData() -> Data? {
        
         return datedValues.convertToData()
    }

    
    mutating func convertFromData(data: Data, label: String) -> Labelled_DatedValues? {
        
        self.label = label
        
        do {
            if let dictionary = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [Date: Double] {
                var datedValues = [DatedValue]()
                for element in dictionary {
                    datedValues.append(DatedValue(date: element.key, value: element.value))
                }
                self.datedValues = datedValues.sorted { (e0, e1) -> Bool in
                    if e0.date > e1.date { return true }
                    else { return false }
                }
                return self
            }
        } catch {
            ErrorController.addInternalError(errorLocation:"Labelled datedValues convert from storage Data", systemError: error, errorInfo: "error retrieving datedValue data")

        }
        return nil

    }
    
    func sort(dateOrder: Order) -> Labelled_DatedValues {
        
        let sorted = self.datedValues.sorted { dv0, dv1 in
            if dateOrder == .ascending {
                if dv0.date < dv1.date { return true }
                else  { return false }
            } else {
                if dv0.date < dv1.date { return false }
                else  { return true }
            }
        }
        
        return Labelled_DatedValues(label: self.label, datedValues: sorted)
    }

}

struct Labelled_DatedTexts: Codable {
    var label: String
    var datedTexts: [DatedText]
        
    
    func extractTextsOnly(dateOrder: Order) -> [String] {
        
        let dv = self.datedTexts.sorted { dv0, dv1 in
            if dateOrder == .ascending {
                if dv0.date < dv1.date { return true }
                else { return false }
            } else {
                if dv0.date > dv1.date { return true }
                else { return false }
            }
        }
        
        return dv.compactMap{ $0.text }

    }
    
    /// converts the datedTExts to Data. Label should come come from variable
    func convertToData() -> Data? {
        
         return datedTexts.convertToData()
    }
    
    func sort(dateOrder: Order) -> Labelled_DatedTexts {
        
        let sorted = self.datedTexts.sorted { dv0, dv1 in
            if dateOrder == .ascending {
                if dv0.date < dv1.date { return true }
                else  { return false }
            } else {
                if dv0.date < dv1.date { return false }
                else  { return true }
            }
        }
        
        return Labelled_DatedTexts(label: self.label, datedTexts: sorted)
    }

}

struct DatedValues: Codable {
    var date: Date
    var values: [Double]
}

struct DatedValue: Codable {
    var date: Date
    var value: Double
    
}

struct PriceDate: Codable {
    var date: Date
    var price: Double
}

struct DatedText: Codable {
    var date: Date
    var text: String
}

struct WebPageAndTitle {
    var rowColumnTitle = String()
    var pageTitle = String()
}

/// links different web page names for same parameter
struct FinancialParameterNames {
    var macroTrends: WebPageAndTitle
    var yahoo: WebPageAndTitle
    var tagesschau: WebPageAndTitle
    
    init(macroTrends: WebPageAndTitle, yahoo: WebPageAndTitle, tagesschau: WebPageAndTitle) {
        self.macroTrends = macroTrends
        self.yahoo = yahoo
        self.tagesschau = tagesschau
    }
}

struct FinancialParameterDetail {
    
    var pageRowService: PageRowServiceTitle
    
    init(pageRowService: PageRowServiceTitle) {
        self.pageRowService = pageRowService
    }
    
    func url(share: Share, service: WebServiceName) -> URL? {
        
        guard let symbol = share.symbol else {
            return nil
        }
        
        var url: URL?
        
        switch service {
        case .yahoo:
            var components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)/\(pageRowService.page)")
            components?.queryItems = [URLQueryItem(name: "p", value: symbol)]
            url = components?.url
            
        case .macroTrends:
            guard let shortName = share.name_short else {
                return nil
            }
            
            var hyphenatedShortName = String()
            let shortNameComponents = shortName.split(separator: " ")
            hyphenatedShortName = String(shortNameComponents.first ?? "").lowercased()
            
            guard hyphenatedShortName != "" else {
                return nil
            }
            
            for index in 1..<shortNameComponents.count {
                if !shortNameComponents[index].contains("(") {
                    hyphenatedShortName += "-" + String(shortNameComponents[index]).lowercased()
                }
            }
            
            var components: URLComponents?
            components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(symbol)/\(hyphenatedShortName)/" + pageRowService.page)
            url = components?.url
            
        case .tagesschau:
            let webString = symbol.replacingOccurrences(of: " ", with: "+")
            url = URL(string: "https://www.tagesschau.de/wirtschaft/boersenkurse/suche/?suchbegriff=\(webString)")

        case .yCharts:
            url = URL(string: ("https://ycharts.com/companies/" + symbol.uppercased() + "/eps"))

        }
        
        return url
    }
    
}


struct WebpageExtractionCodes {
    var tableTitle:String?
    var tableStartSequence = "<table>"
    var tableEndSequence = "</table>"
    var bodyStartSequence = "<tbody>"
    var bodyEndSequence = "</tbody>"
    var rowStartSequence = "<tr>"
    var rowEndSequence = "</tr>"
    var dataCellStartSequence = "<td>"
    var dataCellEndSequence = "</td>"
    var dateFormatter: DateFormatter!
    var option: WebServiceName!
    
    init(tableTitle: String?, option: WebServiceName?=nil,tableStartSequence: String?=nil, tableEndSequence: String?=nil, bodyStartSequence: String?=nil, bodyEndSequence: String?=nil ,rowStartSequence: String?=nil, rowEndSequence: String?=nil, dataCellStartSequence: String?=nil, dataCellEndSequence: String?=nil, dateFormatter: DateFormatter?=nil) {
        
        self.tableTitle = tableTitle
        self.dateFormatter = dateFormatter
        self.option = option

        if let option = option {
            switch option {
            case .macroTrends:
                self.dateFormatter = DateFormatter()
                self.dateFormatter.locale = Locale(identifier: "en_US")
                self.dateFormatter.setLocalizedDateFormatFromTemplate("MMMMd, yyyy")
                if let valid = dateFormatter {
                    self.dateFormatter = valid
                }
            case .yahoo:
                self.dateFormatter = DateFormatter()
                self.dateFormatter.locale = Locale(identifier: "en_US")
                self.dateFormatter.setLocalizedDateFormatFromTemplate("MMMMd, yyyy")
                if let valid = dateFormatter {
                    self.dateFormatter = valid
                }
            case .yCharts:
                self.dateFormatter = DateFormatter()
                self.dateFormatter.locale = Locale(identifier: "en_US")
                self.dateFormatter.setLocalizedDateFormatFromTemplate("MMMMd, yyyy")
                if let valid = dateFormatter {
                    self.dateFormatter = valid
                }
            default:
                print("undefined web page extraction code \(option)")
            }
        }

        if let valid = tableStartSequence {
            self.tableStartSequence = valid
        }
        if let valid = tableEndSequence {
            self.tableEndSequence = valid
        }
        if let valid = bodyStartSequence {
            self.bodyStartSequence = valid
        }
        if let valid = bodyEndSequence {
            self.bodyEndSequence = valid
        }
        if let valid = rowStartSequence {
            self.rowStartSequence = valid
        }
        if let valid = rowEndSequence {
            self.rowEndSequence = valid
        }
        if let valid = dataCellStartSequence {
            self.dataCellStartSequence = valid
        }
        if let valid = dataCellEndSequence {
            self.dataCellEndSequence = valid
        }
    }
}

var rowTitlesAndPages: [FinancialParameterNames] = {
    
    var parameterNames = [FinancialParameterNames]()
    
    let yahooPageNames = ["financials", "balance-sheet","cash-flow"]
    let mtPageNames = ["financial-statements", "financial-ratios", "balance-sheet"]
    
    let yahooRowTitles = [["Total revenue","Basic EPS","Net income"],["Total non-current liabilities", "Common stock"],["Operating cash flow]"]]
    let mtRowTitles = [["Revenue","EPS - Earnings Per Share","Net Income"],["ROI - Return On Investment","Book Value Per Share","Operating Cash Flow Per Share"],["Long Term Debt"]]
    
    for i in 0..<yahooPageNames.count {
        for j in 0..<yahooRowTitles.count {
            let mt = WebPageAndTitle(rowColumnTitle: mtRowTitles[i][j], pageTitle: mtPageNames[i])
            let yahoo = WebPageAndTitle(rowColumnTitle: yahooRowTitles[i][j], pageTitle: yahooPageNames[i])
            let tageschau = WebPageAndTitle(rowColumnTitle: "", pageTitle: "")
            let new = FinancialParameterNames(macroTrends: mt, yahoo: yahoo, tagesschau: tageschau)
            parameterNames.append(new)
        }
    }
            
    return parameterNames
}()

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
    dateComponents.year! -= 10
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
        ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: error, errorInfo: "can't read stock ticker dictionary data from Main bundle file")
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
    let moat = "moat"
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
    formatter.groupingSize = 3
    return formatter
}()

let currencyFormatterNoGapNoPence: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.currencySymbol = "$"
    formatter.numberStyle = NumberFormatter.Style.currency
    formatter.maximumFractionDigits = 0
    formatter.usesGroupingSeparator = true
    formatter.groupingSize = 3
    return formatter
}()


let currencyFormatterNoGapWithPence: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.currencySymbol = "$"
    formatter.numberStyle = NumberFormatter.Style.currency
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    formatter.usesGroupingSeparator = true
    formatter.groupingSize = 3
    return formatter
}()

let currencyFormatterGapWithPence: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.currencySymbol = "$ "
    formatter.numberStyle = NumberFormatter.Style.currency
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    formatter.usesGroupingSeparator = true
    formatter.groupingSize = 3
    return formatter
}()

let currencyFormatterGapWithOptionalPence: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.currencySymbol = "$ "
    formatter.numberStyle = NumberFormatter.Style.currency
    formatter.maximumFractionDigits = 2
    formatter.usesGroupingSeparator = true
    formatter.groupingSize = 3
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
//    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 1
    formatter.minimumIntegerDigits = 1
    formatter.usesGroupingSeparator = true
    return formatter
}()

let numberFormatter2Decimals: NumberFormatter = {
    let formatter = NumberFormatter()
//    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 2
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

let yahooWebpageDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd MMM yyyy"
    formatter.calendar.timeZone = TimeZone(identifier: "UTC")!
    return formatter
}()

let yahooCSVFileDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.calendar.timeZone = TimeZone(identifier: "UTC")!
    return formatter
}()


/// yInterceptAtZero (m or a)  is at x=0! this may not be where the first x/y pair of the array is
/// xDistance is (positive) difference between x.first and x.last
struct Correlation {
    var incline = Double() // b
    var yInterceptAtZero = Double() // m or a
    var coEfficient = Double()
    var xElementsCount = Int()
    var maxX: Double?
    
    /// xDistance = x-Axis difference between max in min/yInterceptAtZero
    init(m: Double, b: Double, r: Double, xElements: Int, maxX:Double?=nil) {
        self.incline = m
        self.yInterceptAtZero = b
        self.coEfficient = r
        self.xElementsCount = xElements
        self.maxX = maxX
    }

    /// assumes once annual x array elements, NOT timeInterval x-axis; use 'change()' for latter; returns annual change calculated over n=xArray count years
    public func meanGrowth(for xElements: Double?=nil) -> Double? {
        
        guard (xElements ?? Double(self.xElementsCount)) > 0 else {
            return nil
        }
        
        let endPoint = incline * (xElements ?? Double(self.xElementsCount)) + yInterceptAtZero
        let change = (endPoint - yInterceptAtZero) / yInterceptAtZero
        
        return change / (xElements ?? Double(self.xElementsCount))
    }
    
    public func change() -> Double? {
        
        guard maxX != nil else { return nil }
        
        let zeroValue = yInterceptAtZero
        let latestValue = zeroValue + incline * maxX!
        return (latestValue - zeroValue) / zeroValue
    }
    
//    public func compoundGrowthRate(for xElements: Double?=nil) -> Double {
//        
//        let endPoint = incline * (xElements ?? Double(self.xElementsCount)) + yInterceptAtZero
//        return (pow((endPoint/yInterceptAtZero), (1/((xElements ?? Double(self.xElementsCount))-1)))-1)
//    }
    
    public func endValue(for xElements: Double?=nil) -> Double {
        return yInterceptAtZero + (xElements ?? Double(self.xElementsCount)) * incline
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
    
    init() {
        tradingDate = Date()
        open = Double()
        high = Double()
        low = Double()
        close = Double()
        volume = Double()
    }
    
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

struct Financial_Valuation_Factors {
    
    var peRatio = 0.67
    var retEarningsGrowth = 0.67
    var lynchScore = 0.67
    var moatScore = 0.67
    var epsGrowth = 0.67
//    var netIncomeDivRevenue = 1.0
    var capExpendDivEarnings = 0.2
    var profitMargin = 0.2
    var ltDebtDivIncome = 0.2
    var opCashFlowGrowth = 0.2
//    var ltDebtDivadjEq = 1.0
    var sgaDivProfit = 0.2
    var radDivProfit = 0.2
    var revenueGrowth = 0.2
//    var netIncomeGrowth = 0.5
    var roeGrowth = 0.33
    var futureEarningsGrowth = 1.0
    
    var propertyDictionary = [String:Double]()

    
    init() {
        
        if let defaults = UserDefaults.standard.value(forKey: userDefaultTerms.valuationFactorWeights) as? [String: Double] {
            
            self.peRatio = defaults["peRatio"] ?? 1.0
            self.retEarningsGrowth = defaults["retEarningsGrowth"] ?? 1.0
            self.lynchScore = defaults["lynchScore"] ?? 1.0
            self.moatScore =  defaults["moatScore"] ?? 1.0
            self.epsGrowth =  defaults["epsGrowth"] ?? 1.0
            self.capExpendDivEarnings =  defaults["capExpendDivEarnings"] ?? 1.0
            self.profitMargin =  defaults["profitMargin"] ?? 1.0
            self.opCashFlowGrowth =  defaults["opCashFlowGrowth"] ?? 1.0
            self.sgaDivProfit =  defaults["sgaDivProfit"] ?? 1.0
            self.radDivProfit =  defaults["radDivProfit"] ?? 1.0
            self.revenueGrowth =  defaults["revenueGrowth"] ?? 1.0
            self.roeGrowth =  defaults["roeGrowth"] ?? 1.0
            self.futureEarningsGrowth =  defaults["futureEarningsGrowth"] ?? 1.0
        }
        
        let mirror = Mirror(reflecting: self)
        for property in mirror.children {
            if let title = property.label {
                if let value = property.value as? Double {
                    propertyDictionary[title] = value
                }
            }
        }

        propertyDictionary = setPropertyDictionary()
    }
    
    /// ensures values are between 0 and 1.0
    mutating func setPropertyDictionary() -> [String: Double] {
        
        // translate into values 0-1.0
        
        var dictionary = [String: Double]()
        let mirror = Mirror(reflecting: self)
        for property in mirror.children {
            if let title = property.label {
                if let value = property.value as? Double {
                    dictionary[title] = value
                }
            }
        }
        return dictionary

    }
    
    public func saveUserDefaults() {
        
        UserDefaults.standard.set(propertyDictionary, forKey: userDefaultTerms.valuationFactorWeights)
        if let savedDict = UserDefaults.standard.value(forKey: userDefaultTerms.valuationFactorWeights) as? [String: Double] {
            for key in savedDict.keys {
                print(key, savedDict[key])
            }
        }
    }
    
    public func weightsSum() -> Double? {
        
        return propertyDictionary.compactMap { $0.value }.reduce(0, +)
        
    }
    
    public func maxWeightValue() -> Double? {
        
        return propertyDictionary.compactMap { $0.value }.max()

    }
    
    public func minWeightValue() -> Double? {
        
        return propertyDictionary.compactMap { $0.value }.min()

    }
    
    public func weightsCount() -> Int {
        
        return propertyDictionary.count
    }
    
    public func propertyNameList() -> [String] {
        
        let sortedDictionary = propertyDictionary.sorted { member0, member1 in
            if member0.value < member1.value { return false }
            else { return true }
        }
        
        return sortedDictionary.compactMap { $0.key }

    }
    
    public func getValue(forVariable: String) -> Double? {
        
        return propertyDictionary[forVariable]
        
    }
    
    public func getRelativeValue(forVariable: String) -> Double? {

        let mirror = Mirror(reflecting: self)
        let combinedValue = self.weightsSum() ?? 1.0

        for property in mirror.children {
            if let title = property.label {
                if title == forVariable {
                    if let value = property.value as? Double {
                        return value / combinedValue
                    }
                }
            }
        }

        return nil
    }

    
    public mutating func setValue(value: Double, parameter: String) {
        
        
        propertyDictionary[parameter] = value
                
//        propertyDictionary = setPropertyDictionary()
    }
    
    public func financialsScore(forShare: Share) -> ScoreData {
        
        var allFactors = [Double]()
        var allWeights = [Double]()
        var allFactorNames = [String]()
        let emaPeriods = (UserDefaults.standard.value(forKey: userDefaultTerms.emaPeriodAnnualData) as? Int) ?? 7

// 1 future earnings growth estimate
        if self.futureEarningsGrowth > 0 {
//            if let research = forShare.research {
                
                
                let futureGrowth = forShare.analysis?.adjFutureGrowthRate.valuesOnly(dateOrdered: .ascending, withoutZeroes: true)?.last ?? forShare.analysis?.future_growthNextYear.valuesOnly(dateOrdered: .ascending,withoutZeroes: true)?.last

                if futureGrowth != nil {
                    var correctedFactor = Double()
                    if futureGrowth! > 0.15 {
                        correctedFactor = 1.0
                    }
                    else if futureGrowth! > 0.1 {
                        correctedFactor = 0.5
                    }
                    else if futureGrowth! > 0 {
                        correctedFactor = 0.25
                    }
                    else {
                        correctedFactor = 0
                    }

                    allFactors.append(correctedFactor * futureEarningsGrowth)
                    allWeights.append(futureEarningsGrowth)
                    allFactorNames.append("Future earnings growth")
                }
//            }
        }
        
// 2 WBV trailing revenue growth
//        if let wbv = forShare.wbValuation {
            
            if let valid = valueFactor(values1: forShare.income_statement?.revenue.valuesOnly(dateOrdered: .ascending), values2: nil, maxCutOff: 1, emaPeriod: emaPeriods) {

                allFactors.append(valid * revenueGrowth)
                allWeights.append(revenueGrowth)
                allFactorNames.append("Revenue growth trend")
            }
        
// 3 WBC trailing retained earnings growth
            if let valid = valueFactor(values1: forShare.balance_sheet?.retained_earnings.valuesOnly(dateOrdered: .ascending), values2: nil, maxCutOff: 1, emaPeriod: emaPeriods) {

                allFactors.append(valid * retEarningsGrowth)
                allWeights.append(retEarningsGrowth)
                allFactorNames.append("Ret. earnings growth trend")
            }
            
// 4 WBC trailing EPS growth
            if let valid = valueFactor(values1:forShare.income_statement?.eps_annual.valuesOnly(dateOrdered: .ascending), values2: nil, maxCutOff: 1, emaPeriod: emaPeriods) {

                allFactors.append(valid * epsGrowth)
                allWeights.append(epsGrowth)
                allFactorNames.append("EPS growth trend")
            }

// 5 WBV Profit margin growth
            if let valid = valueFactor(values1: forShare.income_statement?.revenue.valuesOnly(dateOrdered: .ascending),
                       values2: forShare.income_statement?.grossProfit.valuesOnly(dateOrdered: .ascending),
                       maxCutOff: 1, emaPeriod: emaPeriods) {

                allFactors.append(valid * profitMargin)
                allWeights.append(profitMargin)
                allFactorNames.append("Growth trend profit margin")
            }

// 6 WBV Lynch score
            if let earningsGrowth = forShare.income_statement?.netIncome.valuesOnly(dateOrdered: .ascending, withoutZeroes: true)?.growthRates(dateOrder: .descending)?.ema(periods: emaPeriods) {
                if let divYield = forShare.key_stats?.dividendYield.valuesOnly(dateOrdered: .ascending)?.last {
                    let denominator = (earningsGrowth + divYield) * 100
                    if let currentPE = forShare.ratios?.pe_ratios.valuesOnly(dateOrdered: .ascending, withoutZeroes: true)?.last {
                        if currentPE > 0 {
                            var value = (denominator / currentPE) - 1
                            if value > 1 { value = 1 }
                            else if value < 0 { value = 0 }
                            
                            allFactors.append(value * lynchScore)
                            allWeights.append(lynchScore)
                            allFactorNames.append("P Lynch sore")
                        }
                    }
                }
            }

// 7 WBV CapEx
            if let sumDiv = forShare.income_statement?.netIncome.valuesOnly(dateOrdered: .ascending, withoutZeroes: true)?.reduce(0, +) {
                // use 10 y sums / averages, not ema according to Book Ch 51
                if let sumDenom = forShare.cash_flow?.capEx.valuesOnly(dateOrdered: .ascending)?.reduce(0, +) {
                    let tenYAverages = abs(sumDenom / sumDiv)
                    let maxCutOff = 0.5
                    let factor = (tenYAverages < maxCutOff) ? ((maxCutOff - tenYAverages) / maxCutOff) : 0

                    allFactors.append(factor * capExpendDivEarnings)
                    allWeights.append(capExpendDivEarnings)
                    allFactorNames.append("Growth trend cap. expenditure / net earnings")
                }
            }
            
            if let valid = valueFactor(values1:forShare.ratios?.roe.valuesOnly(dateOrdered: .ascending), values2: nil, maxCutOff: 1, emaPeriod: emaPeriods) {

                allFactors.append(valid * roeGrowth)
                allWeights.append(roeGrowth)
                allFactorNames.append("ROE growth trend")
            }

            if let valid = valueFactor(values1: forShare.cash_flow?.opCashFlow.valuesOnly(dateOrdered: .ascending), values2: nil, maxCutOff: 1, emaPeriod: emaPeriods) {

                allFactors.append(valid * opCashFlowGrowth)
                allWeights.append(opCashFlowGrowth)
                allFactorNames.append("Op. cash flow growth trend")
            }
            
            if let valid = inverseValueFactor(values1: forShare.income_statement?.netIncome.valuesOnly(dateOrdered: .descending), values2: forShare.balance_sheet?.debt_longTerm.valuesOnly(dateOrdered: .descending) ?? [], maxCutOff: 3, emaPeriod: emaPeriods, removeZeroElements: false) {

                allFactors.append(valid * ltDebtDivIncome)
                allWeights.append(ltDebtDivIncome)
                allFactorNames.append("Growth trend long-term debt / net earnings")
            }

            if let valid = valueFactor(values1: forShare.income_statement?.grossProfit.valuesOnly(dateOrdered: .descending), values2: forShare.income_statement?.sgaExpense.valuesOnly(dateOrdered: .descending) ?? [], maxCutOff: 0.4, emaPeriod: emaPeriods) {

                allFactors.append(valid * sgaDivProfit)
                allWeights.append(sgaDivProfit)
                allFactorNames.append("Growth trend SGA expense / profit")
            }
            
            if let valid = valueFactor(values1: forShare.income_statement?.grossProfit.valuesOnly(dateOrdered: .descending), values2: forShare.income_statement?.rdExpense.valuesOnly(dateOrdered: .descending), maxCutOff: 1, emaPeriod: emaPeriods) {

                allFactors.append(valid * radDivProfit)
                allWeights.append(radDivProfit)
                allFactorNames.append("Growth trend R&D expense / profit")
            }

//        }
        
        if let (errors, moat) = forShare.rule1Valuation?.moatScore() {
            
            if  moat != nil {
                allFactors.append(sqrt(moat!) * moatScore)
                allWeights.append(moat!)
                (errors == nil) ? allFactorNames.append("Moat"): allFactorNames.append("(Moat!)")
            }
        }

        let scoreSum = allFactors.reduce(0, +)
        let maximum = allWeights.reduce(0, +)
        
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
