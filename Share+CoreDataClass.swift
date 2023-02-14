//
//  Share+CoreDataClass.swift
//  Bulls'N'Bears
//
//  Created by aDav on 10/01/2023.
//
//

import UIKit
import CoreData

@objc(Share)
public class Share: NSManagedObject {
    
    var priceUpdateComplete: Bool?
    var prices: [PricePoint]?
    var macds: [MAC_D]?
    var osc: [StochasticOscillator]?
    var latestBuySellSignals: [LineCrossing?]?
    var sharePriceSplitCorrected = false
    
    public override func awakeFromInsert() {
        eps_current = Double()
        peRatio_current = Double()
        beta = Double()
        watchStatus = 2
//        watchStatus = 0 // 0 watchList, 1 owned, 3 archived, 2 research
    }
    
    public override func awakeFromFetch() {
        priceUpdateComplete = false
        
        if industry == nil {
            industry = "Unknown"
        }
        
        if sector == nil {
            sector = "Unknown"
        }
        
        if moatCategory == nil {
            moatCategory = "NA"
        }
        
        if let date = self.research?.nextReportDate {
            if date < Date().addingTimeInterval(-quarter) {
                self.research?.nextReportDate = nil
            }
        }
        
        if self.userEvaluationScore.isNaN {
            self.userEvaluationScore = Double()
        }
        
        if self.valueScore.isNaN {
            self.valueScore = Double()
        }
        
    }
    
    func save() {
    
       let context = wbValuation?.managedObjectContext
        if context?.hasChanges ?? false {
            context?.perform {
                do {
                    try context?.save()
                } catch {
                    alertController.showDialog(title: "Fatal error", alertMessage: "The App can't save data due to \(error.localizedDescription)\nPlease quit and re-launch", viewController: nil, delegate: nil)
                }

            }
        }
    }
    
    /// returns trend values with dates in date descending order
    func trendValues(trendName: ShareTrendNames) -> [DatedValue]? {
        
        var data: Data?
        
        switch trendName {
        case .moatScore:
            data = trend_MoatScore
        case .stickerPrice:
            data = trend_StickerPrice
        case .dCFValue:
            data = trend_DCFValue
        case .lynchScore:
            data = trend_LynchScore
        case .intrinsicValue:
            data = trend_intrinsicValue
        case .healthScore:
            data = trend_healthScore
        }
       
        if let valid = data {
            do {
                
                return try dataToDatedValues(data: valid)
            } catch let error {
                ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error retrieving stored P/E ratio historical data")
            }
        } else {
            
            var datedValue: DatedValue?
            
            switch trendName {
            case  .moatScore:
                if let r1v = self.rule1Valuation {
                    let (_, moat) = r1v.moatScore()
                    if moat != nil {
                        let date = r1v.creationDate!
                        datedValue = DatedValue(date:date, value: moat!)
                    }
                }
            case .stickerPrice:
                if let r1v = self.rule1Valuation {
                    let (sp, _) = r1v.stickerPrice()
                    if sp != nil {
                        let date = r1v.creationDate!
                        datedValue = DatedValue(date:date, value: sp!)
                    }
                }
            case .dCFValue:
                if let dcfv = self.dcfValuation {
                    let (sp, _) = dcfv.returnIValueNew()
                    if sp != nil {
                        let date = dcfv.creationDate!
                        datedValue = DatedValue(date:date, value: sp!)
                    }
                }
            case .lynchScore:
//                if let wbv = self.wbValuation {
                    let (_, sp) = lynchRatio()
                    if let price = sp {
                        datedValue = DatedValue(date:Date(), value: price)
                    }
//                }
            case .intrinsicValue:
                if let wbv = self.wbValuation {
                    let (sp, _) = wbv.ivalue()
                    if sp != nil {
                        let date = wbv.date!
                        datedValue = DatedValue(date:date, value: sp!)
                    }
                }
            case .healthScore:
                data = trend_healthScore
            }

            if let valid = datedValue {
                return [valid]
            }

        }
        
        return nil
    }
    
    func trendChartData(trendName: ShareTrendNames) -> [ChartDataSet]? {
        
        var data: Data?
        
        switch trendName {
        case .moatScore:
            data = trend_MoatScore
        case .stickerPrice:
            data = trend_StickerPrice
        case .dCFValue:
            data = trend_DCFValue
        case .lynchScore:
            data = trend_LynchScore
        case .intrinsicValue:
            data = trend_intrinsicValue
        case .healthScore:
            data = trend_healthScore
        }

       
        if let valid = data {
            do {
                if let dictionary = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(valid) as? [Date: Double] {
                    var dataSet = [ChartDataSet]()
                    for element in dictionary {
                        dataSet.append(ChartDataSet(x: element.key, y: element.value))
                    }
                    return dataSet.sorted { (e0, e1) -> Bool in
                        if e0.x! > e1.x! { return true }
                        else { return false }
                    }
                }
            } catch let error {
                ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error retrieving stored P/E ratio historical data")
            }
        } else {
            
            var dataSet: ChartDataSet?
            
            switch trendName {
            case  .moatScore:
                if let r1v = self.rule1Valuation {
                    let (_, moat) = r1v.moatScore()
                    if moat != nil {
                        let date = r1v.creationDate!
                        dataSet = ChartDataSet(x:date, y: moat!)
                    }
                }
            case .stickerPrice:
                if let r1v = self.rule1Valuation {
                    let (sp, _) = r1v.stickerPrice()
                    if sp != nil {
                        let date = r1v.creationDate!
                        dataSet = ChartDataSet(x:date, y: sp)
                    }
                }
            case .dCFValue:
                if let dcfv = self.dcfValuation {
                    let (sp, _) = dcfv.returnIValueNew()
                    if sp != nil {
                        let date = dcfv.creationDate!
                        dataSet = ChartDataSet(x:date, y: sp)
                    }
                }
            case .lynchScore:
                let (_, sp) = lynchRatio()
                if let price = sp {
//                    datedValue = DatedValue(date:Date(), value: price)
                    dataSet = ChartDataSet(x:Date(), y: price)
                }
                
//                if let wbv = self.wbValuation {
//                    if let sp = wbv.lynchRatio() {
//                        let date = wbv.date!
//                        dataSet = ChartDataSet(x:date, y: sp)
//                    }
//                }
            case .intrinsicValue:
                if let wbv = self.wbValuation {
                    let (sp, _) = wbv.ivalue()
                    if sp != nil {
                        let date = wbv.date!
                        dataSet = ChartDataSet(x:date, y: sp)
                    }
                }
            case .healthScore:
                data = trend_healthScore
            }

            if let valid = dataSet {
                return [valid]
            }

        }
        
        return nil
    }
    
    /// adds new data to existing trend Data
    func saveTrendsData(datedValuesToAdd: [DatedValue]?, trendName: ShareTrendNames, saveInContext:Bool?=true) {
        
        var existingValues = trendValues(trendName: trendName) ?? [DatedValue]()
        // check if there's a value for the sent date already
        let existingValueDates = existingValues.compactMap{ $0.date}
        if let values = datedValuesToAdd {
            for value in values {
                if !existingValueDates.contains(value.date) {
                    existingValues.append(value)
                }
            }
        }
                
        if let validData = datedValuesToData(datedValues: existingValues) {


            switch trendName {
            case .moatScore:
                trend_MoatScore = validData
            case .stickerPrice:
                trend_StickerPrice = validData
            case .dCFValue:
                trend_DCFValue = validData
            case .lynchScore:
                trend_LynchScore = validData
            case .intrinsicValue:
                trend_intrinsicValue = validData
            case .healthScore:
                trend_healthScore = validData
            }
            
            if saveInContext ?? true {
                do {
                    try self.managedObjectContext?.save()
                }
                catch let error {
                    ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "error storing share trend data \(trendName)")
                }
            }
        }
        
    }
    
    /// if called from background thread set save to false
    func saveDividendData(datedValues: [DatedValue]?, save:Bool) {
                
        self.dividendWDates = datedValuesToData(datedValues: datedValues)
        
        if save {
            do {
                try self.managedObjectContext?.save()
            } catch {
                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "Error when trying to save share dividend data")
            }
        }
    }
    
    func dividendWithDates() -> [DatedValue]? {
        
        guard let valid = dividendWDates else { return nil }
        
        do {
            return try dataToDatedValues(data: valid)
        } catch {
            ErrorController.addInternalError(errorLocation: #function, systemError: error)
            return nil
        }
        
    }
    
    /// returns compound average growth rate of price gain + dividends paid, over the last 'years' years
    func returnRateCAGR(years: Int) -> Double? {
        
        guard years > 0 else { return nil }
        
        var cagrBase: Double = 0
        var yearCount: Double = 0
        if years <= 3 {
            cagrBase = return3y
            yearCount = 3.0
        } else if years <= 10  {
            cagrBase = return10y
            yearCount = 10.0
        }
        
        guard cagrBase != 0 else { return nil }
        guard yearCount > 0 else { return nil }

        return Calculator.compoundGrowthRate(endValue: cagrBase, startValue: 1.0, years: yearCount)
        
    }
    
    /// returns [DatedValue] array in date DESCENDING order
    func dataToDatedValues(data: Data) throws -> [DatedValue]? {
        
        do {
            if let dictionary = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [Date: Double] {
                var datedValues = [DatedValue]()
                for element in dictionary {
                    datedValues.append(DatedValue(date: element.key, value: element.value))
                }
                return datedValues.sorted { (e0, e1) -> Bool in
                    if e0.date > e1.date { return true }
                    else { return false }
                }
            }
        } catch let error {
            throw InternalError.init(location: #function, systemError: error, errorInfo: "error retrieving datedValue data")

        }
        return nil

    }
    
    func averageAnnualPrices() -> [DatedValue]? {
        
        return self.avgAnnualPrices.datedValues(dateOrder: .ascending)
        
    }
    
    func datedValuesToData(datedValues: [DatedValue]?) -> Data? {
        
        guard let validValues = datedValues else {
            return nil
        }
        
        var array = [Date: Double]()

        for element in validValues {
            array[element.date] = element.value
        }

        do {
            return try NSKeyedArchiver.archivedData(withRootObject: array, requiringSecureCoding: false)
        } catch let error {
            ErrorController.addInternalError(errorLocation: "datedValuesToData function", systemError: error, errorInfo: "error converting DatedValues to Data")
        }

        return nil
    }

    
    /// stores prices in date sorted order.
    func setDailyPrices(pricePoints: [PricePoint]?, saveInMOC: Bool?=true) {

        guard var validPoints = pricePoints else { return }
        
        validPoints = validPoints.sorted(by: { p0, p1 in
            if p0.tradingDate > p1.tradingDate { return false }
            else { return true }
        })
        self.dailyPrices = convertDailyPricesToData(dailyPrices: validPoints)
        self.prices = pricePoints // doesn't promote prices to main moc when called from background thread!
        
        if saveInMOC ?? true {
            save() // saves in the context the wbValuation object was fetched in
        }
    }
       
    func convertDailyPricesToData(dailyPrices: [PricePoint]?) -> Data? {
        
        guard let validPoints = dailyPrices else { return nil }

        do {
            let data1 = try PropertyListEncoder().encode(validPoints)
            let data2 = try NSKeyedArchiver.archivedData(withRootObject: data1, requiringSecureCoding: false)
            return data2
        } catch let error {
            ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error storing historical price data")
        }

        return nil
    }
    
    func convertMACDToData(macds: [MAC_D]?) -> Data? {
        
        guard let validMacd = macds else { return nil }

        do {
            let data1 = try PropertyListEncoder().encode(validMacd)
            let data2 = try NSKeyedArchiver.archivedData(withRootObject: data1, requiringSecureCoding: false)
            return data2
        } catch let error {
            ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error storing MCD data")
        }

        return nil
    }
    

    /// return PricePoint array in date ascending order
    func getDailyPrices(needRecalcDueToNew: Bool?=false) -> [PricePoint]? {

        if (needRecalcDueToNew ?? false) == false {
            if let alreadyConverted = prices {
                return alreadyConverted
            }
        }
        guard let valid = dailyPrices else { return nil }
        
        do {
            if let data = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(valid) as? Data {

                // the 'setDailyPrices' function ensure PricePoints are stored in date sorted order for faster retrieval without sorting
                prices = try PropertyListDecoder().decode([PricePoint].self, from: data)
//once
//                if symbol == "TSLA" && !sharePriceSplitCorrected {
//                    let ratio = Double(1/3)
//                    return shareSplitPriceRecalculation(pricePoints: prices, splitDateString: "08/24/22" , newPerOldShares: ratio)
//                }
                // once

                let nonZeroes = prices?.filter({ pp in
                    if pp.close > 0 { return true }
                    else { return false }
                })
                let sorted = nonZeroes?.sorted(by: { p0, p1 in
                    if p0.tradingDate < p1.tradingDate { return true }
                    else { return false }
                })
                
                setDailyPrices(pricePoints: sorted)
                return sorted
            }
        } catch let error {
            ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error retrieving stored share price data")
        }
        
        return nil
    }

    
    func shareSplitPriceRecalculation(pricePoints: [PricePoint]?, splitDateString: String, newPerOldShares: Double) -> [PricePoint]? {
                
            sharePriceSplitCorrected = true
        
            let dateFormatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.locale = NSLocale.current
                formatter.timeZone = NSTimeZone.local
                formatter.dateFormat = "MM/dd/yy"
                return formatter
            }()
        
            let splitDate = dateFormatter.date(from: "06/23/22")!
            var correctedPrices = [PricePoint]()
            for point in prices ?? [] {
                if point.tradingDate < splitDate {
                    let newPoint = PricePoint(open: point.open / newPerOldShares, close: point.close / newPerOldShares, low: point.low / newPerOldShares, high: point.high / newPerOldShares, volume: point.volume, date: point.tradingDate)
                    correctedPrices.append(newPoint)
                }
                else {
                    correctedPrices.append(point)
                }
            }
        
        print("corrected \(String(describing: symbol)) pricePoints")
            setDailyPrices(pricePoints: correctedPrices)
        
            return correctedPrices
        
    }
    
    func getMACDs() -> [MAC_D]? {

        if let alreadyCalculated = macds {
            return alreadyCalculated
        }
        
        if let valid = macd {
        
            do {
                if let data = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(valid) as? Data {

                    let array = try PropertyListDecoder().decode([MAC_D].self, from: data)
                    macds = array.sorted { (e0, e1) -> Bool in
                        if e0.date ?? Date() < e1.date ?? Date() { return true }
                        else { return false }
                    }
                    return macds
                }
            } catch let error {
                ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error retrieving stored MACD data")
            }
        }
        else { return calculateMACDs(shortPeriod: 8, longPeriod: 17) }
        
        return nil
    }
    
    
    func pe_currentDV() -> DatedValue? {
        
        return ratios?.pe_ratios.datedValues(dateOrder: .ascending)?.last
    }
    
    func pe_current() -> Double? {
        
        return ratios?.pe_ratios.valuesOnly(dateOrdered: .ascending)?.last
    }


    func setUserAndValueScores() {
        
        var needsSaving = false
        if let score = wbValuation?.valuesSummaryScores()?.ratingScore() {
            self.valueScore = score
            needsSaving = true
        }
        if let score = wbValuation?.userEvaluationScore()?.ratingScore() {
            self.userEvaluationScore = score
            needsSaving = true
        }
        
        if needsSaving { save() }
        
    }
    
    // MARK: - price functions
    
    public func priceRange(_ from: Date? = nil,_ to: Date? = nil) -> [Double]? {
        
        guard let dailyPrices = getDailyPrices() else {
            return nil
        }
        
        var pricesInRange: [PricePoint]!
        
        if let validFrom = from {
            pricesInRange = dailyPrices.filter({ (element) -> Bool in
                if element.tradingDate < validFrom {
                    return false
                }
                if element.tradingDate > to! {
                    return false
                }
                
                return true
            })
        }
        else {
            pricesInRange = dailyPrices
        }
        
        let lowPrices = pricesInRange.compactMap { $0.low }
        
        guard let min = lowPrices.min() else {
            return nil
        }
        
        guard let max = lowPrices.max() else {
            return nil
        }
        return [min, max]
    }
    
    public func lowestPrice(_ from: Date? = nil,_ to: Date? = nil) -> Double? {
        
        guard let dailyPrices = getDailyPrices() else {
            return nil
        }
        
        var pricesInRange: [PricePoint]!
        
        if let validFrom = from {
            pricesInRange = dailyPrices.filter({ (element) -> Bool in
                if element.tradingDate < validFrom {
                    return false
                }
                if element.tradingDate > to! {
                    return false
                }
                
                return true
            })
        }
        else {
            pricesInRange = dailyPrices
        }
        
        return pricesInRange.compactMap { $0.low }.min()
    }
    
    public func highestPrice(_ from: Date? = nil,_ to: Date? = nil) -> Double? {
        
        guard let dailyPrices = getDailyPrices() else {
            return nil
        }
        var pricesInRange: [PricePoint]!
        
        if let validFrom = from {
            pricesInRange = dailyPrices.filter({ (element) -> Bool in
                if element.tradingDate < validFrom {
                    return false
                }
                if element.tradingDate > to! {
                    return false
                }
                
                return true
            })
        }
        else {
            pricesInRange = dailyPrices
        }

        return pricesInRange.compactMap { $0.high }.max()
    }

    // returns [earliest, latest] dates of daily prices
    public func priceDateRange() -> [Date]? {
        
        guard let dailyPrices = getDailyPrices() else {
            return nil
        }
        
        let minDate = dailyPrices.compactMap { $0.tradingDate }.min()
        
        let maxDate = dailyPrices.compactMap { $0.tradingDate }.max()
        
        if minDate != nil && maxDate != nil { return [minDate!, maxDate!] }
        else { return nil }
    }
    
    
    /// returns the dates of first Monday before first available tradingDate and the next Monday after today
    public func priceDateRangeWorkWeeksForCharts(withForecastTime: Bool) -> [Date] {
        
        guard let dailyPrices = getDailyPrices() else {
            return [Date(), Date().addingTimeInterval(week)]
        }
        
        let previewTime = withForecastTime ? foreCastTime : 0
        
        let minDate = dailyPrices.compactMap { $0.tradingDate }.min()
        
        if let minDate_v = minDate {
                var calendar = NSCalendar.current
                calendar.timeZone = NSTimeZone.default
            let components: Set<Calendar.Component> = [.year, .month, .hour, .minute, .weekOfYear ,.weekday]
                var firstDateComponents = calendar.dateComponents(components, from: minDate_v)
                var lastDateComponents = calendar.dateComponents(components, from: Date().addingTimeInterval(previewTime))
            
                firstDateComponents.second = 0
                firstDateComponents.minute = 0
                firstDateComponents.hour = 0
                firstDateComponents.weekOfYear! -= 1
                if firstDateComponents.weekOfYear! < 0 {
                    firstDateComponents.year! -= 1
                    firstDateComponents.weekOfYear! += 52
                }
            
                firstDateComponents.weekday = 2 // Monday, days are numbered 1-7, starting with Sunday
                
                lastDateComponents.second = 0
                lastDateComponents.minute = 0
                lastDateComponents.hour = 0
                lastDateComponents.weekOfYear! += 1
                if lastDateComponents.weekOfYear! > 52 {
                    lastDateComponents.year! += 1
                    lastDateComponents.weekOfYear! -= 52
                }
                lastDateComponents.weekday = 2 // Monday, days are numbered 1-7, starting with Sunday

                let firstMondayMidNight = calendar.date(from: firstDateComponents) ?? Date()
                let lastMondayMidNight = calendar.date(from: lastDateComponents) ?? Date()
                
                return [firstMondayMidNight, lastMondayMidNight]
        }
        
        let endOfToday = DatesManager.endOfDay(of: Date())
        let beginningOfToday = DatesManager.beginningOfDay(of: Date())
        return [beginningOfToday, endOfToday.addingTimeInterval(week)]
    }
    
    func priceAtDate(date: Date, priceOption: PricePointOptions) -> Double? {
        
        guard let prices = getDailyPrices() else { return nil }
        
        let exactDates = prices.filter({ (pricePoint) -> Bool in
            if pricePoint.tradingDate == date { return true }
            else { return false }
        })
        if let exactDate = exactDates.first {
            return exactDate.returnPrice(option: priceOption)
        }
        
        else {
            if var previousPrice = prices.first {
                for i in 1..<prices.count {
                    if prices[i].tradingDate > date {
                        return (prices[i].returnPrice(option: priceOption) + previousPrice.returnPrice(option: priceOption)) / 2
                    }
                    previousPrice = prices[i]
                }
            }
        }
        return nil
    }
    
    func latestPrice(option: PricePointOptions) -> Double? {
        
        return getDailyPrices()?.last?.returnPrice(option: option)
        
    }

    // MARK: - correlations and trends
    
    func correlationTrend(properties: TrendProperties) -> Correlation? {
        
        guard let dailyPrices = getDailyPrices() else {
            return nil
        }
        
        let lastDate = dailyPrices.last!.tradingDate
        let firstDate = dailyPrices.first!.tradingDate
        
        var trendDuration = lastDate.timeIntervalSince(firstDate)
        
        switch properties.time {
        case .full:
            trendDuration = lastDate.timeIntervalSince(firstDate)
        case .quarter:
            trendDuration = trendDuration / 4
        case .half:
            trendDuration = trendDuration / 2
        case .month:
            trendDuration = 30*24*3600
        case .none:
            trendDuration = lastDate.timeIntervalSince(firstDate)
        }
        
        let startDate = lastDate.addingTimeInterval(-trendDuration)

        var priceOption: PricePointOptions!
        
        if properties.type == .bottom {
            priceOption = .low
        }
        else if properties.type == .ceiling {
            priceOption = .high
        }
        else if properties.type == .regression {
            priceOption = .close
        }
        
        let dailyPricesInRange = dailyPrices.filter { (pricePoint) -> Bool in
            if pricePoint.tradingDate < startDate { return false }
            else if pricePoint.tradingDate > lastDate { return false }
            else { return true }
        }
        
        let yArray = dailyPricesInRange.compactMap { $0.returnPrice(option: priceOption) }
        let xArray = dailyPricesInRange.compactMap { $0.tradingDate.timeIntervalSince(dailyPricesInRange.first!.tradingDate)}
        
        return Calculator.correlation(xArray: xArray, yArray: yArray)
    }
    
    func lowHighTrend(properties: TrendProperties) -> StockTrend? {
        
        guard let dailyPrices = getDailyPrices() else {
            return nil
        }

        let lastDate = dailyPrices[dailyPrices.count - 6].tradingDate // exclude last five days to show breakthroughs
        let firstDate = dailyPrices.first!.tradingDate
        
        var trendDuration = lastDate.timeIntervalSince(firstDate)
        
        switch properties.time {
        case .full:
            trendDuration = lastDate.timeIntervalSince(firstDate)
        case .quarter:
            trendDuration = trendDuration / 4
        case .half:
            trendDuration = trendDuration / 2
        case .month:
            trendDuration = 30*24*3600
        case .none:
            trendDuration = lastDate.timeIntervalSince(firstDate)
        }
        
        let startDate = lastDate.addingTimeInterval(-trendDuration)
        let threeQDate = lastDate.addingTimeInterval(-trendDuration * 1/4)
                
        let dailyPricesInFirst3Q = dailyPrices.filter { (pricePoint) -> Bool in
            if pricePoint.tradingDate < startDate { return false }
            else if pricePoint.tradingDate > threeQDate { return false }
            else { return true }
        }
        
        let dailyPricesInLastQ = dailyPrices.filter { (pricePoint) -> Bool in
            if pricePoint.tradingDate < threeQDate { return false }
            else if pricePoint.tradingDate < lastDate { return true } // exclude last five days to show breakthroughs
                else { return false }
        }
        
        guard  dailyPricesInFirst3Q.count > 1 else {
            return nil
        }
        
        guard  dailyPricesInLastQ.count > 1 else {
            return nil
        }


        var priceOption: PricePointOptions!
        var findOption: FindOptions!
        
        if properties.type == .bottom {
            priceOption = .low
            findOption = .minimum
        }
        else if properties.type == .ceiling {
            priceOption = .high
            findOption = .maximum
        }
 
        var minOrMax = (findOption == .minimum) ? 1000000.0 : -1000000.0
        var firstPricePoint: PricePoint!
        var secondPricePoint: PricePoint!
        
        for pricePoint in dailyPricesInFirst3Q {
            if findOption == .minimum {
                if pricePoint.returnPrice(option: priceOption) < minOrMax {
                    minOrMax = pricePoint.returnPrice(option: priceOption)
                    firstPricePoint = pricePoint
                }
            }
            else {
                if pricePoint.returnPrice(option: priceOption) > minOrMax {
                    minOrMax = pricePoint.returnPrice(option: priceOption)
                    firstPricePoint = pricePoint
                }
            }
        }
        
        
        minOrMax = (findOption == .minimum) ? 1000000.0 : -1000000.0
        
        for pricePoint in dailyPricesInLastQ {
            
            let incline = pricePoint.returnIncline(pricePoint: firstPricePoint, priceOption: priceOption)
            
            if findOption == .maximum {
                if incline > minOrMax {
                    minOrMax = incline
                    secondPricePoint = pricePoint
                }
            }
            else {
                if incline < minOrMax {
                    minOrMax = incline
                    secondPricePoint = pricePoint
                }
            }
        }
        
        var initialTrend = StockTrend(start: firstPricePoint.tradingDate, end: secondPricePoint.tradingDate, startPrice: firstPricePoint.returnPrice(option: priceOption), endPrice: secondPricePoint.returnPrice(option: priceOption))

        // for maxium = green trend check whether two point tredn of maxima in two half has a lower incline
        // if so, use this
        if findOption == .maximum {
            let sorted = dailyPricesInLastQ.sorted { (pp1, pp2) -> Bool in
                if pp1.returnPrice(option: priceOption) > pp2.returnPrice(option: priceOption) { return true }
                else { return false }
            }
            
            if let topPricePoint = sorted.first {
                let comparatorTrend = StockTrend(start: firstPricePoint.tradingDate, end: topPricePoint.tradingDate, startPrice: firstPricePoint.returnPrice(option: priceOption), endPrice: topPricePoint.returnPrice(option: priceOption))
                
                if (abs(comparatorTrend.incline ?? 0) ) < (abs(initialTrend.incline ?? 00)) {
                    initialTrend = comparatorTrend
                }
            }
        }
        
        
        return initialTrend
    }

    /// applies trendType method (bottom or ceiling) over a timePeriod (1 or 3 months) for every single trading day and calculates how many of the predicted bottom/ceiling prices are NOT the lowest/ highest price during the forecast period (30 days)
    func testTwoPointReliability(_covering timePeriod: TimeInterval, trendType: TrendType) -> Double? {
        
        guard let dailyPrices = getDailyPrices() else {
            return nil
        }

        var predictionFailed = 0
        var totalCounted = 0
        
        for i in 0..<dailyPrices.count-1 {
            
            let day = dailyPrices[i]
            
            let testStart = day.tradingDate
            let testEnd = testStart.addingTimeInterval(timePeriod)
            let halfTime = testStart.addingTimeInterval(timePeriod / 2)
            
            let h1Prices = dailyPrices.filter { (pricePoint) -> Bool in
                if pricePoint.tradingDate < testStart { return false }
                else if pricePoint.tradingDate > halfTime { return false }
                else { return true }
            }
            
            let h2Prices = dailyPrices.filter { (pricePoint) -> Bool in
                if pricePoint.tradingDate < halfTime { return false }
                else if pricePoint.tradingDate > testEnd { return false }
                else { return true }
            }
            
            var priceOption: PricePointOptions!
            var findOption: FindOptions!
            
            if trendType == .bottom {
                priceOption = .low
                findOption = .minimum
            }
            else if trendType == .ceiling {
                priceOption = .high
                findOption = .maximum
            }

            let h1Sorted = h1Prices.sorted { (p0, p1) -> Bool in
                if findOption == .minimum {
                    if p0.returnPrice(option: priceOption) < p1.returnPrice(option: priceOption) {
                        return true
                    } else {
                        return false
                    }
                }
                else {
                    if p0.returnPrice(option: priceOption) > p1.returnPrice(option: priceOption) {
                        return true
                    } else {
                        return false
                    }
                }
            }
            
            let h2Sorted = h2Prices.sorted { (p0, p1) -> Bool in
                if findOption == .minimum {
                    if p0.returnPrice(option: priceOption) < p1.returnPrice(option: priceOption) {
                        return true
                    } else {
                        return false
                    }
                }
                else {
                    if p0.returnPrice(option: priceOption) > p1.returnPrice(option: priceOption) {
                        return true
                    } else {
                        return false
                    }
                }
            }
            
            guard h1Sorted.count > 0 && h2Sorted.count > 0 else {
                continue
            }

            let trend = StockTrend(start: h1Sorted.first!.tradingDate, end: h2Sorted.first!.tradingDate, startPrice: h1Sorted.first!.returnPrice(option: priceOption), endPrice: h2Sorted.first!.returnPrice(option: priceOption))
            
            let futureDate = testEnd.addingTimeInterval(foreCastTime)
            
            // pricePoints between TrendEnd and futureDate
            let predictionPeriodPrices = dailyPrices.filter { (pricePoint) -> Bool in
                if pricePoint.tradingDate > futureDate { return false }
                else if pricePoint.tradingDate <= testEnd { return false }
                else { return true }
            }
            
            guard predictionPeriodPrices.count > 1 else {
                continue
            }
            
            var firstPrice = Double()
            
            if priceOption == .low {
                firstPrice = predictionPeriodPrices.first!.low
            } else {
                firstPrice = predictionPeriodPrices.first!.high
            }

            let predictedPrice = firstPrice + trend.incline! * (foreCastTime)

            totalCounted += 1
            if trendType == .bottom {
                if predictionPeriodPrices.compactMap({ $0.returnPrice(option: priceOption) }).min()! < predictedPrice {
                    predictionFailed += 1
                }
            }
            else {
                if predictionPeriodPrices.compactMap({ $0.returnPrice(option: priceOption) }).max()! > predictedPrice {
                    predictionFailed += 1
                }
            }
        }
        if totalCounted == 0 { return nil }
        else {
            return Double(predictionFailed) / Double(totalCounted)
        }
    }
    
    func testRegressionReliability(_covering timePeriod: TimeInterval, trendType: TrendType) -> Double? {
        
        guard let dailyPrices = getDailyPrices() else {
            return nil
        }

        if trendType == .regression {
            return nil
        }

        var predictionFailed = 0
        var totalCounted = 0
        
        for i in 0..<dailyPrices.count-1 {
            
            let day = dailyPrices[i]
            
            let testStart = day.tradingDate
            let testEnd = testStart.addingTimeInterval(timePeriod)
                        
            var priceOption: PricePointOptions!
            
            if trendType == .bottom {
                priceOption = .low
            }
            else if trendType == .ceiling {
                priceOption = .high
            }
            if trendType == .bottom {
                priceOption = .low
            }
            else if trendType == .ceiling {
                priceOption = .high
            }
            
            let dailyPricesInTest = dailyPrices.filter { (pricePoint) -> Bool in
                if pricePoint.tradingDate < testStart { return false }
                else if pricePoint.tradingDate > testEnd { return false }
                else { return true }
            }
            
            let yArray = dailyPricesInTest.compactMap { $0.returnPrice(option: priceOption) }
            let xArray = dailyPricesInTest.compactMap { $0.tradingDate.timeIntervalSince(dailyPricesInTest.first!.tradingDate)}
            
            guard let correlation = Calculator.correlation(xArray: xArray, yArray: yArray) else {
               continue
            }
            
            let futureDate = testEnd.addingTimeInterval(foreCastTime)
            
            // pricePoints between TrendEnd and futureDate
            let predictionPeriodPrices = dailyPrices.filter { (pricePoint) -> Bool in
                if pricePoint.tradingDate > futureDate { return false }
                else if pricePoint.tradingDate <= testEnd { return false }
                else { return true }
            }
            
            guard predictionPeriodPrices.count > 1 else {
                continue
            }

            let predictedPrice = correlation.yIntercept + correlation.incline * (foreCastTime)

            totalCounted += 1
            if trendType == .bottom {
                if predictionPeriodPrices.compactMap({ $0.returnPrice(option: priceOption) }).min()! < predictedPrice {
                    predictionFailed += 1
                }
            }
            else {
                if predictionPeriodPrices.compactMap({ $0.returnPrice(option: priceOption) }).max()! > predictedPrice {
                    predictionFailed += 1
                }
            }
        }
        if totalCounted == 0 { return nil }
        else {
            return Double(predictionFailed) / Double(totalCounted)
        }

    }
    
    private func removeFile(_ atURL: URL) {
       
        do {
            try FileManager.default.removeItem(at: atURL)
        } catch let error {
            DispatchQueue.main.async {
                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "Share - error trying to remove existing file \(atURL) in the Document folder to be able to move new file of same name from Inbox folder ")
            }
        }
    }
    
    // MARk: - technicals
    
    /// also converts to data stored as 'macd' property of share
    func calculateMACDs(shortPeriod: Int, longPeriod: Int, needRecalcDueToNew: Bool?=false, shouldSaveInMOC: Bool?=true) -> [MAC_D]? {
        
        if (needRecalcDueToNew ?? false) == false {
            if let alreadyCalculated = macds {
                return alreadyCalculated
            }
        }
        
        guard let dailyPrices = getDailyPrices(needRecalcDueToNew: needRecalcDueToNew) else { return nil }
        let closePrices = dailyPrices.compactMap({ $0.close })
        
        guard shortPeriod < dailyPrices.count else {
            return nil
        }
        
        guard longPeriod < dailyPrices.count else {
            return nil
        }

        let initialShortSMA = closePrices[(shortPeriod-1)..<longPeriod].reduce(0, +) / Double(shortPeriod)
        let initialLongSMA = closePrices[0..<longPeriod].reduce(0, +) / Double(longPeriod)
        
        var lastMACD = MAC_D(currentPrice: closePrices[longPeriod-1], lastMACD: nil, date: dailyPrices[longPeriod-1].tradingDate)
        lastMACD.emaShort = initialShortSMA
        lastMACD.emaLong = initialLongSMA

        var mac_ds = [MAC_D(currentPrice: dailyPrices[longPeriod].close, lastMACD: lastMACD, date: dailyPrices[longPeriod].tradingDate)]
        
        var macdSMA = [Double?]()
        for i in longPeriod..<(longPeriod + 9) {
            let macd = MAC_D(currentPrice: dailyPrices[i].close, lastMACD: lastMACD, date: dailyPrices[i].tradingDate)
            mac_ds.append(macd)
            lastMACD = macd
            macdSMA.append(macd.mac_d)
        }
        
        mac_ds[mac_ds.count-1].signalLine = macdSMA.compactMap{$0}.reduce(0, +) / Double(macdSMA.compactMap{$0}.count)
        lastMACD = mac_ds[mac_ds.count-1]

        for i in (longPeriod+9)..<dailyPrices.count {
            let macd = MAC_D(currentPrice: dailyPrices[i].close, lastMACD: lastMACD, date: dailyPrices[i].tradingDate)
            mac_ds.append(macd)
            lastMACD = macd
        }
        
        macds = mac_ds
        self.macd = convertMACDToData(macds: mac_ds)
        if shouldSaveInMOC ?? true {
            save()
        }
        
        return mac_ds
    }
    
    /// recalculates MACD from the sent pricePoints. Please note that these are stored in the macds parameter, and converted to data for the macd managed object property, but not saved to MOC!
    func reCalculateMACDs(newPricePoints: [PricePoint]?, shortPeriod: Int, longPeriod: Int) {
                
        guard let dailyPrices = newPricePoints else { return }
        let closePrices = dailyPrices.compactMap({ $0.close })
        
        guard shortPeriod < dailyPrices.count else {
            return
        }
        
        guard longPeriod < dailyPrices.count else {
            return
        }

        let initialShortSMA = closePrices[(shortPeriod-1)..<longPeriod].reduce(0, +) / Double(shortPeriod)
        let initialLongSMA = closePrices[0..<longPeriod].reduce(0, +) / Double(longPeriod)
        
        var lastMACD = MAC_D(currentPrice: closePrices[longPeriod-1], lastMACD: nil, date: dailyPrices[longPeriod-1].tradingDate)
        lastMACD.emaShort = initialShortSMA
        lastMACD.emaLong = initialLongSMA

        var mac_ds = [MAC_D(currentPrice: dailyPrices[longPeriod].close, lastMACD: lastMACD, date: dailyPrices[longPeriod].tradingDate)]
        
        var macdSMA = [Double?]()
        for i in longPeriod..<(longPeriod + 9) {
            let macd = MAC_D(currentPrice: dailyPrices[i].close, lastMACD: lastMACD, date: dailyPrices[i].tradingDate)
            mac_ds.append(macd)
            lastMACD = macd
            macdSMA.append(macd.mac_d)
        }
        
        mac_ds[mac_ds.count-1].signalLine = macdSMA.compactMap{$0}.reduce(0, +) / Double(macdSMA.compactMap{$0}.count)
        lastMACD = mac_ds[mac_ds.count-1]

        for i in (longPeriod+9)..<dailyPrices.count {
            let macd = MAC_D(currentPrice: dailyPrices[i].close, lastMACD: lastMACD, date: dailyPrices[i].tradingDate)
            mac_ds.append(macd)
            lastMACD = macd
        }
        
        self.macd = convertMACDToData(macds: mac_ds)
        macds = mac_ds
    }
    
    /// returns array[0] = fast oscillator K%
    /// arrays[1] = slow oscillator D%
    func calculateSlowStochOscillators(newPricePoints: [PricePoint]?=nil) -> [StochasticOscillator]? {
        
        if let alreadyCalculated = osc {
            return alreadyCalculated
        }
        
        guard let dailyPrices = (newPricePoints ?? getDailyPrices()) else { return nil }
        
        guard dailyPrices.count > 14 else {
            return nil
        }
        
        var last14 = dailyPrices[..<14].compactMap{ $0.close }
        let after14 = dailyPrices[13...]
        
        var last4K = [Double]()
        var lowest14 = last14.min()
        var highest14 = last14.max()
        var slowOsc = [StochasticOscillator]()

        for pricePoint in after14 {
            last14.append(pricePoint.close)
            last14.removeFirst()
            
            lowest14 = last14.min()
            highest14 = last14.max()
            
            let newOsc = StochasticOscillator(currentPrice: pricePoint.close, date: pricePoint.tradingDate, lowest14: lowest14, highest14: highest14, slow4: last4K)
            slowOsc.append(newOsc)
            
            if let valid = newOsc.k_fast {
                last4K.append(valid)
                if last4K.count > 4 {
                    last4K.removeFirst()
                }
            }
        }
        
        osc = slowOsc
        return slowOsc
    }
    
    func latestMCDCrossing() -> LineCrossing? {
        
        guard let macds = getMACDs() else {
            return nil
        }
        
        let descendingMCDs = Array(macds.reversed())
        var crossingPoint: LineCrossing?
        
        var latestMCD = descendingMCDs.first!
        for i in 1..<descendingMCDs.count {
            
            if latestMCD.histoBar != nil && descendingMCDs[i].histoBar != nil {
                if (latestMCD.histoBar! * descendingMCDs[i].histoBar!) <= 0 {
                    let crossingPrice = priceAtDate(date: latestMCD.date!, priceOption: .close)
                    crossingPoint = LineCrossing(date: latestMCD.date!, signal: (latestMCD.histoBar! - descendingMCDs[i].histoBar!), crossingPrice: crossingPrice, type:"macd")
                    break
                }
            }
            latestMCD = descendingMCDs[i]
        }
        
        return crossingPoint
    }
    
    func latestSMA10Crossing() -> LineCrossing? {
        
        guard let dailyPrices = getDailyPrices() else {
            return nil
        }
        
        let descendingDailyPrices = Array(dailyPrices.reversed())
        
        var crossingPoint: LineCrossing?
        
        var sma10 = Array(descendingDailyPrices[1...10].compactMap{$0.close})
        
        var lastPrice = descendingDailyPrices.first!
        for i in 1..<descendingDailyPrices.count-10 {
            let laterDifference = lastPrice.close - sma10.reduce(0,+)/10.0
            sma10.append(descendingDailyPrices[i+10].close)
            sma10.removeFirst()
            let earlierDifference = descendingDailyPrices[i].close - sma10.reduce(0,+)/10.0
            
            if (earlierDifference * laterDifference) <= 0 {
                crossingPoint = LineCrossing(date: lastPrice.tradingDate, signal: (laterDifference - earlierDifference), crossingPrice: (lastPrice.close), type:"sma10")
                break
            }
            lastPrice = descendingDailyPrices[i]
        }
        
        return crossingPoint
    }
    
    func latestStochastikCrossing() -> LineCrossing? {
        
        guard let oscillators = calculateSlowStochOscillators() else {
            return nil
        }

        let descendingOscillators = Array(oscillators.reversed())
        var crossingPoint: LineCrossing?
        
        var lastOsc = descendingOscillators.first!
        for i in 1..<descendingOscillators.count {
            let lastDifference = lastOsc.k_fast! - lastOsc.d_slow!
            let currentDifference = descendingOscillators[i].k_fast! - descendingOscillators[i].d_slow!
            
            if (currentDifference * lastDifference) <= 0 {
                let timeInBetween = lastOsc.date!.timeIntervalSince(descendingOscillators[i].date!)
                let dateInBetween = lastOsc.date!.addingTimeInterval(-timeInBetween / 2)
                let crossingPrice = priceAtDate(date: dateInBetween, priceOption: .close)
                crossingPoint = LineCrossing(date: dateInBetween, signal: (lastDifference - currentDifference), crossingPrice: crossingPrice, type:"osc")
                break
            }
            lastOsc = descendingOscillators[i]
        }
        
        return crossingPoint
    }
    
    func latest3Crossings() -> [LineCrossing?]? {
        
        if let alreadyCalculated = latestBuySellSignals {
            return alreadyCalculated
        }
        
        guard let latestMACDCrossing = latestMCDCrossing() else {
            return nil
        }
        
        guard let latestOSCDCrossing = latestStochastikCrossing() else {
            return nil
        }

        guard let latestSMACrossing = latestSMA10Crossing() else {
            return nil
        }

        
        guard let firstSignal = [latestSMACrossing, latestMACDCrossing, latestOSCDCrossing].sorted(by: { (lc0, lc1) -> Bool in
            if lc0.date < lc1.date { return true }
            else { return false }
        }).first else { return nil }
        
        
        // find the earliest of the three and determine its'type'
        // check the other two types for the nearest crossings matching the upward/downwards signal of the earliest
        // if there are none take their latest crossings as default
        // otherwise take the later of the two as the 'buy' or sell signal
        
        guard let smaCrossings = sma10Crossings(after: firstSignal.date) else {
            return nil
        }
        
        guard let macdCrossings = macDCrossings(aboveZero: nil, after: firstSignal.date) else {
            return nil
        }
        
        guard let oscCrossings = oscCrossings(oversold: nil, after: firstSignal.date) else {
            return nil
        }
        
        var allCrossings = [LineCrossing]()

        allCrossings = smaCrossings
        allCrossings.append(contentsOf: macdCrossings)
        allCrossings.append(contentsOf: oscCrossings)
        
        // remove all firstSignals types
        allCrossings = allCrossings.filter({ (crossing) -> Bool in
            if crossing.type == firstSignal.type { return false }
            else { return true }
        })
        
//        allCrossings.sort { (cp0, cp1) -> Bool in
//            if cp0.date < cp1.date { return true }
//            else { return false }
//        }
        
        var secondSignal = allCrossings.filter({ (crossing) -> Bool in
//            if crossing.date < firstSignal.date { return false }
            if crossing.signalIsBuy() != firstSignal.signalIsBuy() { return false }
//            else if crossing.type == firstSignal.type { return false }
            else { return true }
        }).sorted( by: { (cp0, cp1) -> Bool in
            if cp0.date < cp1.date { return true }
            else { return false }
        }).first
        
        if secondSignal == nil {
            secondSignal = allCrossings.last
        }
        
        if secondSignal == nil { return [firstSignal, nil, nil] }
        
        var thirdSignal = allCrossings.filter({ (crossing) -> Bool in
//            if crossing.date < secondSignal!.date { return false }
            if crossing.signalIsBuy() != firstSignal.signalIsBuy() { return false }
            else if crossing.type == secondSignal!.type { return false }
            else { return true }
        }).first
        
        if thirdSignal == nil {
            thirdSignal = allCrossings.filter({ (crossing) -> Bool in
//                if crossing.date < secondSignal!.date { return false }
                if crossing.type == secondSignal!.type { return false }
                else { return true }
            }).last
        }

        latestBuySellSignals = [firstSignal, secondSignal, thirdSignal]
        return latestBuySellSignals
    }

    //MARK: - signals research
        
    /// returns all macd line and signalLine crossings,  in time ascending order - latest = last
    /// if aboveZero = true  only if  macd.signalLine > 0
    /// if aboveZero = false  only if  macd.signalLine < 0
    /// if aboveZero = nil all crossings
    func macDCrossings(aboveZero: Bool?, after:Date?=nil) -> [LineCrossing]? {
        
        guard var macds = getMACDs() else {
            return nil
        }
        
        if let validDate = after {
            macds = macds.filter({ (macd) -> Bool in
                if macd.date! < validDate { return false }
                else { return true }
            })
        }
        
        var descendingMCDs: [MAC_D]?
        
        if aboveZero == nil {
            descendingMCDs = Array(macds.reversed())
        }
        else if (aboveZero ?? false) {
            descendingMCDs = Array(macds.reversed()).filter { (macd) -> Bool in
                if macd.signalLine ?? 0 > 0 { return true }
                else { return false }
            }
        }
        else if !(aboveZero ?? true) {
            descendingMCDs = Array(macds.reversed()).filter { (macd) -> Bool in
                if macd.signalLine ?? 0 < 0 { return true }
                else { return false }
            }
        }
        
        
        guard descendingMCDs?.count ?? 0 > 1 else {
            return nil
        }
        
        var crossingPoints = [LineCrossing]()
        
        var latestMCD = descendingMCDs!.first!
        for i in 1..<descendingMCDs!.count {
            
            if latestMCD.histoBar != nil && descendingMCDs![i].histoBar != nil {
                if (latestMCD.histoBar! * descendingMCDs![i].histoBar!) <= 0 { // crossing
                                        
                    let crossingPrice = priceAtDate(date: (latestMCD.date!), priceOption: .close)
                    let crossingPoint = LineCrossing(date: latestMCD.date!, signal: (latestMCD.histoBar! - descendingMCDs![i].histoBar!), crossingPrice: crossingPrice,type: "macd")
                    crossingPoints.append(crossingPoint)
                }
            }
            latestMCD = descendingMCDs![i]
        }

        return crossingPoints.reversed()
    }
    
    /// returns all stoch osc line slow-d and fast-k crossingsas [LineCrossing] in time ascending order - latest = last
    /// if oversold = true  only if  slow_d  >  80
    /// if oversold = false  only if   slow_d < 20
    /// if oversold = nil all crossings
    func oscCrossings(oversold: Bool?, after: Date?=nil) -> [LineCrossing]? {
        
        guard var oscillators = calculateSlowStochOscillators() else {
            return nil
        }

        if let validDate = after {
            oscillators = oscillators.filter({ (oscillator) -> Bool in
                if oscillator.date! < validDate { return false }
                else { return true }
            })
        }
        
        var descendingOscillators: [StochasticOscillator]?
        
        if oversold == nil {
            descendingOscillators = Array(oscillators.reversed())
        }
        else if (oversold ?? false) {
             descendingOscillators = Array(oscillators.reversed()).filter { (stOsc) -> Bool in
                if stOsc.d_slow ?? 100 < 20 { return true }
                else { return false }
            }
        }
        else {
            descendingOscillators = Array(oscillators.reversed()).filter { (stOsc) -> Bool in
               if stOsc.d_slow ?? 0 > 80 { return true }
               else { return false }
           }
        }
        
        guard descendingOscillators?.count ?? 0 > 1 else {
            return nil
        }
        
        var crossingPoints = [LineCrossing]()
        
        var lastOsc = descendingOscillators!.first!
        for i in 1..<descendingOscillators!.count {
            let lastDifference = lastOsc.k_fast! - lastOsc.d_slow!
            
            guard descendingOscillators![i].k_fast != nil && descendingOscillators![i].d_slow != nil else {
                continue
            }
            
            let currentDifference = descendingOscillators![i].k_fast! - descendingOscillators![i].d_slow!
            
            if (currentDifference * lastDifference) <= 0 {
                let timeInBetween = lastOsc.date!.timeIntervalSince(descendingOscillators![i].date!)
                let dateInBetween = lastOsc.date!.addingTimeInterval(-timeInBetween / 2)
                let crossingPrice = priceAtDate(date: dateInBetween, priceOption: .close)
                let crossingPoint = LineCrossing(date: dateInBetween, signal: (lastDifference - currentDifference), crossingPrice: crossingPrice,type: "osc")
                crossingPoints.append(crossingPoint)
            }
            lastOsc = descendingOscillators![i]
        }
        
        return crossingPoints.reversed()
    }
    
    func sma10Crossings(after: Date?=nil) -> [LineCrossing]? {
        
        guard let dailyPrices = getDailyPrices() else {
            return nil
        }
        let earliestDate = after ?? dailyPrices.first!.tradingDate

        let descendingDailyPrices = Array(dailyPrices.reversed())
        
        var crossingPoints = [LineCrossing]()
        
        var sma10 = Array(descendingDailyPrices[1...10].compactMap{$0.close})
        var lastPrice = descendingDailyPrices.first!
        for i in 1..<descendingDailyPrices.count-10 {
            
//            if symbol == "ALL" {
//                let calendar = Calendar.current
//                let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]
//                var dateComponents = calendar.dateComponents(components, from: Date())
//                dateComponents.day = 22
//                dateComponents.month = 3
//                dateComponents.year = 2021
//                dateComponents.second = 0
//                dateComponents.minute = 0
//                dateComponents.hour = 0
//                let theDate = calendar.date(from: dateComponents) ?? Date()
//
//                if descendingDailyPrices[i].tradingDate >= theDate {
//                    print("ALL closing price \(descendingDailyPrices[i].close) @ \(descendingDailyPrices[i].tradingDate)")
//                    print("SMA 10 = \((sma10[..<10].reduce(0, +)) / 10.0)")
//                }
//
//            }
            
            let laterDifference = lastPrice.close - sma10.reduce(0, +)/10.0
            sma10.append(descendingDailyPrices[i+10].close)
            sma10.removeFirst()
            let earlierDifference = descendingDailyPrices[i].close - sma10.reduce(0, +)/10.0
            
            if (earlierDifference * laterDifference) <= 0 {
                let crossingPoint = LineCrossing(date: lastPrice.tradingDate, signal: (laterDifference - earlierDifference), crossingPrice:lastPrice.close, type: "sma10")
                crossingPoints.append(crossingPoint)
            }
            lastPrice = descendingDailyPrices[i]
            if descendingDailyPrices[i].tradingDate <= earliestDate {
                break
            }
            
        }
        
        return crossingPoints.reversed()
    }
    
    func buyTriggersThreeAnywhere() {
        
        guard let smaCrossings = sma10Crossings() else {
            return
        }
        
        guard let macdCrossings = macDCrossings(aboveZero: nil) else {
            return
        }
        
        guard let oscCrossings = oscCrossings(oversold: nil) else {
            return
        }

        var allCrossings = smaCrossings
        allCrossings.append(contentsOf: macdCrossings)
        allCrossings.append(contentsOf: oscCrossings)

        allCrossings = allCrossings.sorted { (cp0, cp1) -> Bool in
            if cp0.date > cp1.date { return false }
            else { return true }
        }
        
        guard let firstUpwardCrossing = allCrossings.filter({ (crossing) -> Bool in
            if crossing.signal < 0 { return false }
            else { return true }
        }).first else { return }
        
        
        //find first signal > 0 with date, then find subsequent crossing.signal > 0 of the other two types
        //take last of the three as buy signal -> price
        //then find first signal < 0 with date, then two <0 signals of the other two tyoe
        //take last of the three as sell signal -> price
        //calculate price difference % between buy date and sell date
        
        
        let upwardCrossing = firstUpwardCrossing
        let secondCrossing = allCrossings.filter { (crossing) -> Bool in
            if crossing.date <= upwardCrossing.date { return false }
            else if crossing.signal < 0 { return false }
            else if crossing.type != upwardCrossing.type { return true }
            else { return false }
        }.first
        
        if secondCrossing == nil { return }
        let thirdCrossing = allCrossings.filter { (crossing) -> Bool in
            if crossing.date <= secondCrossing!.date { return false }
            else if crossing.signal < 0 { return false }
            else if ![upwardCrossing.type, secondCrossing!.type ?? ""].contains(crossing.type) { return true }
            else { return false }
        }.first
        if thirdCrossing == nil { return }
        
        }
        
    func purchasePrice() -> Double? {
                        
        guard let transaction = self.transactions else { return  nil }
        
        var priceSum = Double()
        var quantitySum = Double()
        
        for element in transaction.allObjects {
            if let transaction = element as? ShareTransaction {
                if !transaction.isSale {
                    priceSum += transaction.price * transaction.quantity
                    quantitySum += transaction.quantity
                }
            }
        }
        
        guard quantitySum > 0 else { return nil }
        
        return priceSum / quantitySum
        
    }
    
    func targetBuyPrice() -> Double? {
                        
        guard let research = self.research else { return  nil }
            
        return research.targetBuyPrice
        
    }

    func quantityOwned() -> Double? {
        
        guard let transactions = self.transactions else { return  nil }

        var quantitySum = Double()
        for element in transactions.allObjects {
            if let transaction = element as? ShareTransaction {
                if transaction.isSale {
                    quantitySum -= transaction.quantity
                } else {
                    quantitySum += transaction.quantity
                }
            }
        }
        
        guard quantitySum > 0 else { return nil }
        
        return quantitySum

    }

    public func sortedTransactionsByDate(ascending: Bool) -> [ShareTransaction]? {
        
        guard let transactions = self.transactions as? Set<ShareTransaction> else {
            return nil
        }
        
        let sortedTA = transactions.sorted { t0, t1 in
            if ascending {
                if t0.date! < t1.date! { return true }
                else { return false }
            } else {
                if t0.date! < t1.date! { return false }
                else { return true }

            }
        }
        
        return sortedTA
        
    }
    
    public func lynchRatio() -> ([String]?, Double?) {
        
        // can be zero, so don't drop zeros
        guard let divYieldDV = key_stats?.dividendYield.datedValues(dateOrder: .ascending, oneForEachYear: true)?.last else {
            return (["missing dividend yield value"],nil)
        }
        
        guard let currentPEdv = ratios?.pe_ratios.datedValues(dateOrder: .ascending, oneForEachYear: true)?.dropZeros().last else {
            return (["missing current P/E ratio"],nil)
        }
        
        var errors = [String]()
        let currentPE = currentPEdv.value
        if Date().timeIntervalSince(currentPEdv.date) > 365*24*3600/4 {
            let dateFormatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.locale = NSLocale.current
                formatter.timeZone = NSTimeZone.local
                formatter.dateFormat = "MM.yy"
                return formatter
            }()
            errors = ["last valid P/E ratio is from " + dateFormatter.string(from: currentPEdv.date)]
        }
        
        if let netIncome = income_statement?.netIncome.datedValues(dateOrder: .ascending, oneForEachYear: true)?.dropZeros() { // ema(periods: emaPeriod)
            if let meanGrowth = netIncome.growthRates(dateOrder: .ascending)?.values().mean(){
            // use 10 y sums / averages, not ema according to Book Ch 51
                let denominator = meanGrowth * 100 + divYieldDV.value * 100
                    if currentPE > 0 {
                        return (errors, (denominator / currentPE))
                    } else {
                        errors.append("current P/E ratio is 0 or negative")
                        return (errors,nil)
                    }
            }
        }
        
        errors.append("missing net income growth rates")
        return (errors,nil)

    }
    
    public func latestBookValuePerPrice() -> [Double?]? {
        
        
        if let latestStockPrice =  getDailyPrices()?.last?.close {//stock.dailyPrices.last?.close}
            if let valid = ratios?.bvps.valuesOnly(dateOrdered: .ascending, withoutZeroes: true)?.last {
                let percent = valid / latestStockPrice
                let price = valid
                return [percent, price]
            }
        }
        
        return nil

    }
    
    func mergeInDownloadedTexts(ldTexts: [Labelled_DatedTexts], replace:Bool=false) async throws {
        
        //DEBUG only
//        let dateFormatter: DateFormatter = {
//            let formatter = DateFormatter()
//            formatter.timeZone = TimeZone(identifier: "UTC")!
//            formatter.dateFormat = "d.M.YY"
//            return formatter
//        }()
//
//
//        print()
//        print("\(symbol ?? "") has received downloaded Dated Texts for merge:")
//        for ldv in ldTexts {
//            print(ldv.label)
//            for dvs in  ldv.datedTexts {
//                let date$ = dateFormatter.string(from: dvs.date)
//                print(date$, ": " ,dvs.text)
//            }
//            print()
//        }
        //DEBUG only
        
        guard let backgroundMoc = self.managedObjectContext else {
            throw InternalError(location: #function, errorInfo: "savings downloaded data in background share's own context FAILED!")
        }
        
        do {
            
            let research = self.research ?? StockResearch(context: backgroundMoc)
            research.share = self
            
            for result in ldTexts {
                
                switch result.label.lowercased() {
                    
                case "sector":
                    self.sector = result.datedTexts[0].text
                case "industry":
                    self.industry = result.datedTexts[0].text
                case "description":
                    research.businessDescription = result.datedTexts[0].text
                case "currency":
                    self.currency = result.datedTexts[0].text
                case "exchange":
                    self.exchange = result.datedTexts[0].text
                default:
                    ErrorController.addInternalError(errorLocation: #function, errorInfo: "received unexpected labelled result \(result)")
                }
                
            }
            try self.managedObjectContext?.save()
        
            NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateValuationData"), object: nil, userInfo: nil)
        }  catch {
            ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "Error saving \(self.symbol!) data download")
            throw error
        }



    }

    
    // for MOST but not all integrates into existing value; does NOT convert numbers from throusands or millions inot proper numbers!
    func mergeInDownloadedData(labelledDatedValues: [Labelled_DatedValues],replace:Bool=false) async throws {
        
        //DEBUG only
//        let numberFormatter: NumberFormatter = {
//            let formatter = NumberFormatter()
//            formatter.numberStyle = .decimal
//            formatter.usesGroupingSeparator = true
//            formatter.groupingSize = 3
//            return formatter
//        }()
//        let dateFormatter: DateFormatter = {
//            let formatter = DateFormatter()
//            formatter.timeZone = TimeZone(identifier: "UTC")!
//            formatter.dateFormat = "d.M.YY"
//            return formatter
//        }()
//
//
//        print()
//        print("\(symbol ?? "") has received downloaded Dated Values for merge:")
//        for ldv in labelledDatedValues {
//            print(ldv.label)
//            for dvs in  ldv.datedValues {
//                let date$ = dateFormatter.string(from: dvs.date)
//                let value$ = numberFormatter.string(from: dvs.value as NSNumber) ?? "-'"
//                print(date$, ": " ,value$)
//            }
//            print()
//        }
        //DEBUG only
        
        guard let backgroundMoc = self.managedObjectContext else {
            throw InternalError(location: #function, errorInfo: "savings downloaded data in background share's own context FAILED!")
        }
        
        do {
            
            let incomeStatement = self.income_statement ?? Income_statement(context: backgroundMoc)
            incomeStatement.share = self
            
            let ratios = self.ratios ?? Ratios(context: backgroundMoc)
            ratios.share = self
            
            let cashFlowStatement = self.cash_flow ?? Cash_flow(context: backgroundMoc)
            cashFlowStatement.share = self
            
            let balanceSheet = self.balance_sheet ?? Balance_sheet(context: backgroundMoc)
            balanceSheet.share = self
            
            let analysis = self.analysis ?? Analysis(context: backgroundMoc)
            analysis.share = self
            
            let keyStats = self.key_stats ?? Key_stats(context: backgroundMoc)
            keyStats.share = self
            
            let r1v = self.rule1Valuation ?? Rule1Valuation(context: backgroundMoc)
            r1v.share = self
            
            let dcfv = self.dcfValuation ?? DCFValuation(context: backgroundMoc)
            dcfv.share = self

            let wbv = self.wbValuation ?? WBValuation(context: backgroundMoc)
            wbv.share = self

            
            // save new value with date in a share trend
            let (_, moat) = r1v.moatScore()
            
            if moat != nil {
                r1v.addMoatTrend(date: Date(), moat: moat!)
            }
            
            let (price,_) = r1v.stickerPrice()
            if price != nil {
                r1v.addStickerPriceTrend(date: Date(), price: price!)
            }
            
            // calculate FCF from OCF and netPPEChange
//            let ocf = labelledDatedValues.filter { ldv in
//                if ldv.label.lowercased().contains("operating activities") { return true }
//                else { return false }
//            }.first?.datedValues
//            
//            let netPPE = labelledDatedValues.filter { ldv in
//                if ldv.label.lowercased() == ("net change in property, plant, and equipment") { return true }
//                else { return false }
//            }.first?.datedValues
            
            // prefer FCF from Yahoo
//            if let  fcfDV = cashFlowStatement.calculateFCF(ocf: ocf, netPPEChange: netPPE) {
//                let millions: [DatedValue] = fcfDV.compactMap{ DatedValue(date: $0.date, value: $0.value * 1_000_000) }
//                cashFlowStatement.freeCashFlow = millions.convertToData()
//            }
            
            for result in labelledDatedValues {
                                
                switch result.label.lowercased() {
                case "revenue":
                    if let existingDVs = incomeStatement.revenue.datedValues(dateOrder: .ascending) {
                        incomeStatement.revenue = existingDVs.mergeIn(newDV: result.datedValues)?.convertToData()
                    } else {
                        incomeStatement.revenue = result.datedValues.convertToData()
                    }
                case "eps - earnings per share":
                    if let existingDVs = incomeStatement.eps_annual.datedValues(dateOrder: .ascending) {
                        incomeStatement.eps_annual = existingDVs.mergeIn(newDV: result.datedValues)?.convertToData()
                    } else {
                        incomeStatement.eps_annual = result.datedValues.convertToData()
                    }
                case "diluted eps":
                    if let existingDVs = incomeStatement.eps_annual.datedValues(dateOrder: .ascending) {
                        incomeStatement.eps_annual = existingDVs.mergeIn(newDV: result.datedValues)?.convertToData()
                    } else {
                        incomeStatement.eps_annual = result.datedValues.convertToData()
                    }
                case "quarterly eps":
                    if let existingDVs = incomeStatement.eps_quarter.datedValues(dateOrder: .ascending) {
                        incomeStatement.eps_quarter = existingDVs.mergeIn(newDV: result.datedValues)?.convertToData()
                    } else {
                        incomeStatement.eps_quarter = result.datedValues.convertToData()
                    }

                case "basic eps":
                    if let existingDVs = incomeStatement.eps_annual.datedValues(dateOrder: .ascending) {
                        incomeStatement.eps_annual = existingDVs.mergeIn(newDV: result.datedValues)?.convertToData()
                    } else {
                        incomeStatement.eps_annual = result.datedValues.convertToData()
                    }

                case "net income":
//                    let millions: [DatedValue] = result.datedValues.compactMap{ DatedValue(date: $0.date, value: $0.value * 1_000_000) }
                    if let existingDVs = incomeStatement.netIncome.datedValues(dateOrder: .ascending) {
                        incomeStatement.netIncome = existingDVs.mergeIn(newDV: result.datedValues)?.convertToData()
                    } else {
                        incomeStatement.netIncome = result.datedValues.convertToData()
                    }
                case "roi - return on investment":
//                    let percent: [DatedValue] = result.datedValues.compactMap{ DatedValue(date: $0.date, value: $0.value / 100) }
                    if let existingDVs = ratios.roi.datedValues(dateOrder: .ascending) {
                        ratios.roi = existingDVs.mergeIn(newDV: result.datedValues)?.convertToData()
                    } else {
                        ratios.roi = result.datedValues.convertToData()
                    }
                    r1v.creationDate = Date()
                case "book value per share":
                    if let existingDVs = ratios.bvps.datedValues(dateOrder: .ascending) {
                        ratios.bvps = existingDVs.mergeIn(newDV: result.datedValues)?.convertToData()
                    } else {
                        ratios.bvps = result.datedValues.convertToData()
                    }
                case "cash flow from operating activities":
//                    let millions: [DatedValue] = result.datedValues.compactMap{ DatedValue(date: $0.date, value: $0.value * 1_000_000) }
                    if let existingDVs = cashFlowStatement.opCashFlow.datedValues(dateOrder: .ascending) {
                        cashFlowStatement.opCashFlow = existingDVs.mergeIn(newDV: result.datedValues)?.convertToData()
                    } else {
                        cashFlowStatement.opCashFlow = result.datedValues.convertToData()
                    }
                case "free cash flow":
                    if let existingDVs = cashFlowStatement.freeCashFlow.datedValues(dateOrder: .ascending) {
                        cashFlowStatement.freeCashFlow = existingDVs.mergeIn(newDV: result.datedValues)?.convertToData()
                    } else {
                        cashFlowStatement.freeCashFlow = result.datedValues.convertToData()
                    }
                case "free cash flow per share":
                    if let existingDVs = ratios.fcfPerShare.datedValues(dateOrder: .ascending) {
                        ratios.fcfPerShare = existingDVs.mergeIn(newDV: result.datedValues)?.convertToData()
                    } else {
                        ratios.fcfPerShare = result.datedValues.convertToData()
                    }
                case "operating cash flow per share":
                    if let existingDVs = ratios.ocfPerShare.datedValues(dateOrder: .ascending) {
                        ratios.ocfPerShare = existingDVs.mergeIn(newDV: result.datedValues)?.convertToData()
                    } else {
                        ratios.ocfPerShare = result.datedValues.convertToData()
                    }
               case "long term debt":
                    if let existingDVs = balanceSheet.debt_longTerm.datedValues(dateOrder: .ascending) {
                        balanceSheet.debt_longTerm = existingDVs.mergeIn(newDV: result.datedValues)?.convertToData()
                    } else {
                        balanceSheet.debt_longTerm = result.datedValues.convertToData()
                    }
                case "long-term debt":
                     if let existingDVs = balanceSheet.debt_longTerm.datedValues(dateOrder: .ascending) {
                         balanceSheet.debt_longTerm = existingDVs.mergeIn(newDV: result.datedValues)?.convertToData()
                     } else {
                         balanceSheet.debt_longTerm = result.datedValues.convertToData()
                     }
                case "pe ratio historical data":
                    if let existingDVs = ratios.pe_ratios.datedValues(dateOrder: .ascending)?.dropZeros() {
                        ratios.pe_ratios = existingDVs.mergeIn(newDV: result.datedValues)?.convertToData()
                    } else {
                        ratios.pe_ratios = result.datedValues.convertToData()
                    }
                case "pe ratio (ttm)":
                    if let existingDVs = ratios.pe_ratios.datedValues(dateOrder: .ascending)?.dropZeros() {
                        ratios.pe_ratios = existingDVs.mergeIn(newDV: result.datedValues)?.convertToData()
                    } else {
                        ratios.pe_ratios = result.datedValues.convertToData()
                    }
               case "sales growth (year/est)":
                    // save only last two
                    let count = result.datedValues.count
                    var lastTwo = [DatedValue]()
                    if count == 2 {
                        lastTwo = result.datedValues
                    } else if count > 2 {
                        let last = result.datedValues[count-1]
                        let previous = result.datedValues[count-2]
                        lastTwo = [previous, last]
                    }
                    
                    if let existingDVs = analysis.future_revenueGrowthRate.datedValues(dateOrder: .ascending) {
                        analysis.future_revenueGrowthRate = existingDVs.mergeIn(newDV: lastTwo)?.convertToData()
                    } else {
                        analysis.future_revenueGrowthRate = lastTwo.convertToData()
                    }
                case "purchases":
                    if let r0 = result.datedValues.first { // first or last?
                        keyStats.insiderPurchases = [r0].convertToData()
                    }
                case "sales":
                    if let r0 = result.datedValues.first { // first or last?
                        keyStats.insiderSales = [r0].convertToData()
                    }
                case "total insider shares held":
                    if let r0 = result.datedValues.first { // first or last?
                        keyStats.insiderShares =  [r0].convertToData()
                    }
                case "forward p/e":
                    if let r0 = result.datedValues.first { // first or last?
                        if r0.value != 0 {
                            analysis.forwardPE = [r0].convertToData()
                        }
                    }
                case "rdexpense":
                    if let existingDVs = incomeStatement.rdExpense.datedValues(dateOrder: .ascending) {
                        incomeStatement.rdExpense = existingDVs.mergeIn(newDV: result.datedValues)?.convertToData()
                    } else {
                        incomeStatement.rdExpense = result.datedValues.convertToData()
                    }
                case "research and development expenses":
                    if let existingDVs = incomeStatement.rdExpense.datedValues(dateOrder: .ascending) {
                        incomeStatement.rdExpense = existingDVs.mergeIn(newDV: result.datedValues)?.convertToData()
                    } else {
                        incomeStatement.rdExpense = result.datedValues.convertToData()
                    }
                case "beta":
                    if let value = result.datedValues.values().first {
                        if value != 0 {
                            keyStats.beta = result.datedValues.convertToData()
                        }
                    }
                    dcfv.creationDate = Date()
                 case "trailing p/e":
                    // fetched NEWEST/ current PE
                    if let existingDVs = ratios.pe_ratios.datedValues(dateOrder: .ascending)?.dropZeros() {
                        ratios.pe_ratios = existingDVs.addOrReplaceNewest(newDV: result.datedValues.last)?.convertToData()
                    } else {
                        ratios.pe_ratios = result.datedValues.convertToData()
                    }
                case "diluted eps (ttm)":
                    let ascending = result.datedValues.sortByDate(dateOrder: .ascending)
                        if var existingEPS = incomeStatement.eps_annual.datedValues(dateOrder: .ascending) {
                            if existingEPS.last!.date < ascending.last!.date {
                                existingEPS.append(ascending.last!)
                                incomeStatement.eps_annual = existingEPS.convertToData()
                            }
                        }
//                            bgShare.eps_current = result.values.first ?? Double()
                case "trailing annual dividend yield":
                        keyStats.dividendYield = result.datedValues.convertToData()
//                            bgShare.divYieldCurrent = result.values.
                    
                case "gross profit":
                    incomeStatement.grossProfit = result.datedValues.convertToData()
                case "sg&a expenses":
                    incomeStatement.sgaExpense = result.datedValues.convertToData()
                case "operating income":
                    incomeStatement.operatingIncome = result.datedValues.convertToData()
                case "retained earnings (accumulated deficit)":
                    balanceSheet.retained_earnings = result.datedValues.convertToData()
                    wbv.share?.creationDate = Date()
                case "share holder equity":
                    balanceSheet.sh_equity = result.datedValues.convertToData()
                case "roe - return on equity":
                    ratios.roe = result.datedValues.convertToData()
                case "roa - return on assets":
                    ratios.roa = result.datedValues.convertToData()
                    
// DCF Data
                case "market cap (intra-day)":
                    if let value = result.datedValues.values().first {
                        if value != 0 {
                            keyStats.marketCap = result.datedValues.convertToData()
                        }
                    }
                case "market cap":
                    if let value = result.datedValues.values().first {
                        if value != 0 {
                            keyStats.marketCap = result.datedValues.convertToData()
                        }
                    }
                case "beta (5y monthly)":
                    if let value = result.datedValues.values().first {
                        if value != 0 {
                            keyStats.beta = result.datedValues.convertToData()
                        }
                    }
                case "shares outstanding":
                    for dv in result.datedValues {
                        print(dv)
                    }
                    keyStats.sharesOutstanding = [result.datedValues.last!].convertToData()
                case "total revenue":
                    // don't replace any existing macrotrends data as Yahoo only has last four years
                    if !(incomeStatement.revenue.datedValues(dateOrder: .ascending)?.count ?? 0 > result.datedValues.count) {
                        incomeStatement.revenue = result.datedValues.convertToData()
                    }
                case "interest expense":
                    incomeStatement.interestExpense = result.datedValues.convertToData()
                case "income before tax":
                    // don't replace any existing macrotrends data as Yahoo only has last four years
                    if !(incomeStatement.preTaxIncome.datedValues(dateOrder: .ascending)?.count ?? 0 > result.datedValues.count) {
                        incomeStatement.preTaxIncome = result.datedValues.convertToData()
                    }
                case "income tax expense":
                    incomeStatement.incomeTax = [result.datedValues.last!].convertToData()
                case "current debt":
                    balanceSheet.debt_shortTerm = [result.datedValues.last!].convertToData()
                case "total liabilities":
                    balanceSheet.debt_total = [result.datedValues.last!].convertToData()
                case "operating cash flow":
                    // don't replace any existing macrotrends data as Yahoo only has last four years
                    if !(cashFlowStatement.opCashFlow.datedValues(dateOrder: .ascending)?.count ?? 0 > result.datedValues.count) {
                        cashFlowStatement.opCashFlow = result.datedValues.convertToData()
                    }
                case "capital expenditure":
                    if !(cashFlowStatement.capEx.datedValues(dateOrder: .ascending)?.count ?? 0 > result.datedValues.count) {
                        cashFlowStatement.capEx = result.datedValues.convertToData()
                    }
                    cashFlowStatement.capEx = result.datedValues.convertToData()
                case "avg. estimate":
                    // save only last two
                    let count = result.datedValues.count
                    if count == 2 {
                        analysis.future_revenue = result.datedValues.convertToData()
                    } else if count > 2 {
                        let last = result.datedValues[count-1]
                        let previous = result.datedValues[count-2]
                        analysis.future_revenue = [previous, last].convertToData()
                    }
                case "next year":
                    analysis.future_growthNextYear = result.datedValues.convertToData()
                case "next 5 years (per annum)":
                    analysis.future_growthNext5pa = result.datedValues.convertToData()
                case "debt issuance/retirement net - total":
                    analysis.share?.cash_flow?.netBorrowings = result.datedValues.convertToData()
                case "payout ratio":
                    analysis.share?.key_stats?.dividendPayoutRatio = result.datedValues.convertToData()
                case "historical average annual stock prices":
                    if let existingDVs = avgAnnualPrices.datedValues(dateOrder: .ascending) {
                        avgAnnualPrices = existingDVs.addOrReplaceNewest(newDV: result.datedValues.last)?.convertToData()
                    } else {
                        avgAnnualPrices = result.datedValues.convertToData()
                    }
                case "employees":
                    self.employees = result.datedValues.first?.value ?? 0.0
                default:
                    ErrorController.addInternalError(errorLocation: "Share.mergeInData", systemError: nil, errorInfo: "unspecified result label \(result.label)")
                }                
            }
            
            r1v.creationDate = Date()
            
            try self.managedObjectContext?.save()
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateValuationData"), object: nil, userInfo: nil)

        }
        catch {
            ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "Error saving \(self.symbol!) data download")
            throw error
        }

    }
    
    func grossProfitMargins() -> ([DatedValue]?, String?) {
        
        guard let revenueDVs = income_statement?.revenue.datedValues(dateOrder: .ascending, oneForEachYear: true)?.dropZeros() else {
            return (nil, "missing revenue data")
        }
        
        guard let grossProfitDVs = income_statement?.grossProfit.datedValues(dateOrder: .ascending, oneForEachYear: true)?.dropZeros() else {
            return (nil, "missing gross profit data")
        }
        
        guard let harmonisedArrays = ValuationDataCleaner.harmonizeDatedValues(arrays: [revenueDVs, grossProfitDVs]) else {
            return (nil, "failure to harmonise revenue and gross profit data")
        }
        
        let revenue = harmonisedArrays[0]
        let grossProfit = harmonisedArrays[1]
        
        var profitMargins = [DatedValue]()
        
        for i in 0..<revenue.count {
            let margin = grossProfit[i].value / revenue[i].value
            profitMargins.append(DatedValue(date: revenue[i].date, value: margin))
        }
    
        return (profitMargins, nil)

        
        // OLD
//        guard revenue != nil && grossProfit != nil else {
//            return ([Double()], ["there are no revenue and/or gross profit data"])
//        }
//
//        let rawData = [revenue!, grossProfit!]
//
//        let (cleanedData, error) = ValuationDataCleaner.cleanValuationData(dataArrays: rawData, method: .wb)
//
//        var margins = [Double]()
//        var errors: [String]?
//        for i in 0..<cleanedData[0].count {
//            margins.append(cleanedData[1][i] / cleanedData[0][i])
//        }
//
//        if let validError = error {
//            errors = [validError]
//        }
//        return (margins, errors)
    }

    
}
