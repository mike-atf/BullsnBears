//
//  PublicVars.swift
//  TrendMyStocks
//
//  Created by aDav on 01/12/2020.
//

import UIKit

var stocks = [Stock]()
var foreCastTime: TimeInterval = 30*24*3600
//var managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
var errorLog: [ErrorLog]?
let gradientBarHeight = UIImage(named: "GradientBar")!.size.height - 1
let gradientBar = UIImage(named: "GradientBar")
let userDefaultTerms = UserDefaultTerms()

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

struct DatedValue {
    var date: Date
    var value: Double
    
    init(date: Date, value: Double) {
        self.date = date
        self.value = value
    }
    
    func returnTuple() -> (Date, Double) {
        return (date, value)
    }
}

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

struct WBVParameters {
    // when adding new parameter check impact in WBVValuationController and WBVValuationTVC and ValueListTVC
    // also adapt 'higherIsBetter' parameter in UserEvaluation
    let earnigsGrowth = "Growth of earnings"
    let retEarningsGrowth = "Growth of retained earnings"
    let epsGrowth = "EPS"
    let incomeOfRevenueGrowth = "Growth of net income % of revenue"
    let profitOfRevenueGrowth = "Growth of profit % of revenue"
    let capExpendOfEarningsGrowth = "Growth of cap. expend % of net income"
    let debtOfIncomeGrowth = "Growth of LT debt % of net income"
    let opCashFlowGrowth = "Growth of op. cash flow"
    let roeGrowth = "Growth of return on equity"
    let roaGrowth = "Growth of return on assets"
    let debtOfEqAndRtEarningsGrowth = "Growth of LT debt % of equity + ret. earnings"
    let sgaOfProfitGrowth = "Growth of SGA % of profit"
    let rAdOfProfitGrowth = "Growth of R&D % of profit"
    
    func allParameters() -> [String] {
        return [earnigsGrowth,retEarningsGrowth, epsGrowth, incomeOfRevenueGrowth, profitOfRevenueGrowth, capExpendOfEarningsGrowth, debtOfIncomeGrowth, roeGrowth, roaGrowth ,debtOfEqAndRtEarningsGrowth, sgaOfProfitGrowth ,rAdOfProfitGrowth]
    }
    
    func structuredTitlesParameters() -> [[[String]]] {
        return [firstSection(), secondSection(), thirdSection()]
    }
        
    func firstSection() -> [[String]] {
        return [[retEarningsGrowth],
                [epsGrowth],
                [incomeOfRevenueGrowth, "Revenue"],
                [profitOfRevenueGrowth, "Revenue"],
                [capExpendOfEarningsGrowth, "Net income"],
                [debtOfIncomeGrowth, "Net income"]]
    }
    
    func secondSection() -> [[String]] {
        return [[opCashFlowGrowth],
                [roeGrowth],
                [roaGrowth],
                [debtOfEqAndRtEarningsGrowth, "equity + ret. earnings"]]
    }
    
    func thirdSection() -> [[String]] {
        return [[sgaOfProfitGrowth, "Profit"],
                [rAdOfProfitGrowth, "Profit"]]
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
    formatter.maximumFractionDigits = 2
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

struct PricePoint: Codable {
    
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
    
//    func encode(with coder: NSCoder) {
//        coder.encode(open, forKey: "open")
//        coder.encode(close, forKey: "close")
//        coder.encode(high, forKey: "high")
//        coder.encode(low, forKey: "low")
//        coder.encode(tradingDate, forKey: "tradingDate")
//        coder.encode(volume, forKey: "volume")
//    }
//
//    required convenience init?(coder: NSCoder) {
//        self.close = coder.decodeDouble(forKey: "close")
//        self.open = coder.decodeDouble(forKey: "open")
//        self.low = coder.decodeDouble(forKey: "low")
//        self.high = coder.decodeDouble(forKey: "high")
//        self.tradingDate = coder.decodeObject(forKey: "tradingDate") as? Date ?? Date()
//        self.volume = coder.decodeDouble(forKey: "volume")
//
//
//    }
    
    /// expected that self.tradsingDate is LATER than pricepoint.tradingDate
    /// otherwise a negative incline would be returned instead of a positive and vice versa
    public func returnIncline(pricePoint: PricePoint, priceOption: PricePointOptions) -> Double {
        
        return (pricePoint.returnPrice(option: priceOption) - self.returnPrice(option: priceOption)) / pricePoint.tradingDate.timeIntervalSince(self.tradingDate)

    }
    
}

