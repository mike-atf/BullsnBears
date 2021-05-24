//
//  Share+CoreDataClass.swift
//  Bulls'N'Bears
//
//  Created by aDav on 11/03/2021.
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
    
    public override func awakeFromInsert() {
        eps = Double()
        peRatio = Double()
        beta = Double()
//        watchStatus = 0 // 0 watchList, 1 owned, 2 archived
    }
    
    public override func awakeFromFetch() {
        priceUpdateComplete = false
        
        if industry == nil {
            industry = "Unknown"
        }
        
        if sector == nil {
            sector = "Unknown"
        }

        if growthType == nil {
            growthType = "Unknown"
        }
        
        if growthSubType == nil {
            growthSubType = "Unknown"
        }
        
    }
    
   func save() {
    
    
    if self.managedObjectContext?.hasChanges ?? false {
        do {
            try self.managedObjectContext?.save()
        } catch {
            // TODO: - Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

    }
    
    func setDailyPrices(pricePoints: [PricePoint]?) {

        guard let validPoints = pricePoints else { return }

        self.dailyPrices = convertDailyPricesToData(dailyPrices: validPoints)
        save() // saves in the context the object was fetched in
    }
       
    func convertDailyPricesToData(dailyPrices: [PricePoint]?) -> Data? {
        
        guard let validPoints = dailyPrices else { return nil }

        do {
            let data1 = try PropertyListEncoder().encode(validPoints)
            let data2 = try NSKeyedArchiver.archivedData(withRootObject: data1, requiringSecureCoding: false)
            return data2
        } catch let error {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error storing historical price data")
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
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error storing MCD data")
        }

        return nil
    }

    
    /// takes new prices and adds any newer ones than already saved to the exsitng list (rather than replce the existing list)
//    func updateDailyPrices(newPrices: [PricePoint]?) {
//        
//        guard let validNewPoints = newPrices else { return }
//        
//        if let existingPricePoints = getDailyPrices() {
//            var newList = existingPricePoints
//            var existingMACDs = getMACDs()
//            if let lastExistingDate = existingPricePoints.last?.tradingDate {
//                let pointsToAdd = validNewPoints.filter { (element) -> Bool in
//                    if element.tradingDate > lastExistingDate { return true }
//                    else { return false }
//                }
//                if pointsToAdd.count > 0 {
//                    for point in pointsToAdd {
//                        newList.append(point)
//                        let lastMACD = existingMACDs?.last
//                        existingMACDs?.append(MAC_D(currentPrice: point.close, lastMACD: lastMACD, date: point.tradingDate))
//                    }
//                    self.macd = convertMACDToData(macds: existingMACDs) // doesn't save
//                    setDailyPrices(pricePoints: newList) // saves
//                }
//            }
//        }
//    }
    
    func getDailyPrices() -> [PricePoint]? {

        if let alreadyConverted = prices {
            return alreadyConverted
        }
        
        guard let valid = dailyPrices else { return nil }
        
        do {
            if let data = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(valid) as? Data {

                let array = try PropertyListDecoder().decode([PricePoint].self, from: data)
                prices = array.sorted { (e0, e1) -> Bool in
                    if e0.tradingDate < e1.tradingDate { return true }
                    else { return false }
                }
                return prices
            }
        } catch let error {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error retrieving stored share price data")
        }
        
        return nil
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
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error retrieving stored MACD data")
            }
        }
        else { return calculateMACDs(shortPeriod: 8, longPeriod: 17) }
        
        return nil
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
    public func priceDateRangeWorkWeeksForCharts() -> [Date] {
        
        guard let dailyPrices = getDailyPrices() else {
            return [Date(), Date().addingTimeInterval(7*24*3600)]
        }
        
        let minDate = dailyPrices.compactMap { $0.tradingDate }.min()
        
        if let minDate_v = minDate {
                var calendar = NSCalendar.current
                calendar.timeZone = NSTimeZone.default
                let components: Set<Calendar.Component> = [.year, .month, .hour, .minute, .weekOfYear ,.weekday]
                var firstDateComponents = calendar.dateComponents(components, from: minDate_v)
                var lastDateComponents = calendar.dateComponents(components, from: Date().addingTimeInterval(foreCastTime))
                firstDateComponents.second = 0
                firstDateComponents.minute = 0
                firstDateComponents.hour = 0
                firstDateComponents.weekOfYear = (firstDateComponents.weekOfYear! > 0) ? (firstDateComponents.weekOfYear! - 1) : 0
                firstDateComponents.weekday = 2 // Monday, days are numbered 1-7, starting with Sunday
                
                lastDateComponents.second = 0
                lastDateComponents.minute = 0
                lastDateComponents.hour = 0
                lastDateComponents.weekOfYear = (lastDateComponents.weekOfYear! < 52) ? (lastDateComponents.weekOfYear! + 1) : 52
                lastDateComponents.weekday = 2 // Monday, days are numbered 1-7, starting with Sunday

                let firstMondayMidNight = calendar.date(from: firstDateComponents) ?? Date()
                let lastMondayMidNight = calendar.date(from: lastDateComponents) ?? Date()
                
                return [firstMondayMidNight, lastMondayMidNight]
        }
        
        return [Date(), Date().addingTimeInterval(7*24*3600)]
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
            var previousPrice = prices.first!
            for i in 1..<prices.count {
                if prices[i].tradingDate > date {
                    return (prices[i].returnPrice(option: priceOption) + previousPrice.returnPrice(option: priceOption)) / 2
                }
                previousPrice = prices[i]
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
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error trying to remove existing file in the Document folder to be able to move new file of same name from Inbox folder ")
            }
        }
    }
    
    // MARk: - technicals
    
    /// also converts to data stored as 'macd' property of share
    func calculateMACDs(shortPeriod: Int, longPeriod: Int) -> [MAC_D]? {
        
        if let alreadyCalculated = macds {
            return alreadyCalculated
        }
        
        guard let dailyPrices = getDailyPrices() else { return nil }
        guard let closePrices = (getDailyPrices()?.compactMap{ $0.close }) else { return nil }
        
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
        save()
        
        return mac_ds
    }
    
    /// returns array[0] = fast oascillator K%
    /// arrays[1] = slow oscillator D%
    func calculateSlowStochOscillators() -> [StochasticOscillator]? {
        
        if let alreadyCalculated = osc {
            return alreadyCalculated
        }
        
        guard let dailyPrices = getDailyPrices() else { return nil }
        
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
       
    func priceIncreaseAfterMCDCrossings() {
        
        guard let aboveCrossingPoints = macDCrossings(aboveZero: true) else {
            return
        }
        
        var abovePriceIncreases = [Double]()
        
        var firstPositiveCrossingIndex = 0
        for crossing in aboveCrossingPoints {
            if crossing.signal > 0 {
                break
            }
            firstPositiveCrossingIndex += 1
        }

        var lastCrossing = aboveCrossingPoints[firstPositiveCrossingIndex]
        for i in (firstPositiveCrossingIndex+1)..<aboveCrossingPoints.count {
            
            if aboveCrossingPoints[i].crossingPrice != nil && lastCrossing.crossingPrice != nil {
                let percentIncrease = (aboveCrossingPoints[i].crossingPrice! - lastCrossing.crossingPrice!) / lastCrossing.crossingPrice!
                abovePriceIncreases.append(percentIncrease)
            }
            
            lastCrossing = aboveCrossingPoints[i]
        }
        
        guard let belowCrossingPoints = macDCrossings(aboveZero: false) else {
            return
        }
        
        var belowPriceIncreases = [Double]()
        
        firstPositiveCrossingIndex = 0
        for crossing in aboveCrossingPoints {
            if crossing.signal > 0 {
                break
            }
            firstPositiveCrossingIndex += 1
        }

        lastCrossing = belowCrossingPoints[firstPositiveCrossingIndex]
        for i in (firstPositiveCrossingIndex+1)..<belowCrossingPoints.count {
            
            if belowCrossingPoints[i].crossingPrice != nil && lastCrossing.crossingPrice != nil {
                let percentIncrease = (belowCrossingPoints[i].crossingPrice! - lastCrossing.crossingPrice!) / lastCrossing.crossingPrice!
                belowPriceIncreases.append(percentIncrease)
            }
            
            lastCrossing = belowCrossingPoints[i]
        }

        let actualIncreasesAbove = abovePriceIncreases.filter { (increase) -> Bool in
            if increase > 0 { return true }
            else { return false }
        }
        let actualIncreasesBelow = belowPriceIncreases.filter { (increase) -> Bool in
            if increase > 0 { return true }
            else { return false }
        }

        
        let above$ = percentFormatter2Digits.string(from: abovePriceIncreases.mean()! as NSNumber) ?? ""
        let below$ = percentFormatter2Digits.string(from: belowPriceIncreases.mean()! as NSNumber) ?? ""
        
        let abovePct = Double(actualIncreasesAbove.count) / Double(abovePriceIncreases.count)
        let belowPct = Double(actualIncreasesBelow.count) / Double(belowPriceIncreases.count)
        
        let abovePct$ = percentFormatter2Digits.string(from: abovePct as NSNumber) ?? ""
        let belowPct$ = percentFormatter2Digits.string(from: belowPct as NSNumber) ?? ""

        print()
        print("\(symbol!) mean price increase after MACD crossings above zero is " + above$)
        print( abovePct$ + " of \(abovePriceIncreases.count) are actual increases")
        print("\(symbol!) mean price increase after MACD crossings BELOW zero is " +  below$)
        print( belowPct$ + " of \(belowPriceIncreases.count) are actual increases")
        print()

    }
    
    func priceIncreaseAfterOscCrossings() {
        
        guard let aboveCrossingPoints = oscCrossings(oversold: true) else {
            return
        }
        
        var abovePriceIncreases = [Double]()
        
        var firstPositiveCrossingIndex = 0
        for crossing in aboveCrossingPoints {
            if crossing.signal > 0 {
                break
            }
            firstPositiveCrossingIndex += 1
        }

        var lastCrossing = aboveCrossingPoints[firstPositiveCrossingIndex]
        for i in (firstPositiveCrossingIndex+1)..<aboveCrossingPoints.count {
            
            if aboveCrossingPoints[i].crossingPrice != nil && lastCrossing.crossingPrice != nil {
                let percentIncrease = (aboveCrossingPoints[i].crossingPrice! - lastCrossing.crossingPrice!) / lastCrossing.crossingPrice!
                abovePriceIncreases.append(percentIncrease)
            }
            
            lastCrossing = aboveCrossingPoints[i]
        }
        
        guard let belowCrossingPoints = oscCrossings(oversold: false) else {
            return
        }
        
        var belowPriceIncreases = [Double]()
        
        firstPositiveCrossingIndex = 0
        for crossing in aboveCrossingPoints {
            if crossing.signal > 0 {
                break
            }
            firstPositiveCrossingIndex += 1
        }

        lastCrossing = belowCrossingPoints[firstPositiveCrossingIndex]
        for i in (firstPositiveCrossingIndex+1)..<belowCrossingPoints.count {
            
            if belowCrossingPoints[i].crossingPrice != nil && lastCrossing.crossingPrice != nil {
                let percentIncrease = (belowCrossingPoints[i].crossingPrice! - lastCrossing.crossingPrice!) / lastCrossing.crossingPrice!
                belowPriceIncreases.append(percentIncrease)
            }
            
            lastCrossing = belowCrossingPoints[i]
        }

        let actualIncreasesAbove = abovePriceIncreases.filter { (increase) -> Bool in
            if increase > 0 { return true }
            else { return false }
        }
        let actualIncreasesBelow = belowPriceIncreases.filter { (increase) -> Bool in
            if increase > 0 { return true }
            else { return false }
        }

        
        let above$ = percentFormatter2Digits.string(from: (abovePriceIncreases.mean() ?? 0) as NSNumber) ?? ""
        let below$ = percentFormatter2Digits.string(from: (belowPriceIncreases.mean() ?? 0) as NSNumber) ?? ""
        
        let abovePct = Double(actualIncreasesAbove.count) / Double(abovePriceIncreases.count)
        let belowPct = Double(actualIncreasesBelow.count) / Double(belowPriceIncreases.count)
        
        let abovePct$ = percentFormatter2Digits.string(from: abovePct as NSNumber) ?? ""
        let belowPct$ = percentFormatter2Digits.string(from: belowPct as NSNumber) ?? ""

        print()
        print("\(symbol!) mean price increase after OSC crossings in oversold area (>80) " + above$)
        print( abovePct$ + " of \(abovePriceIncreases.count) are actual increases")
//        print(abovePriceIncreases)
        print("\(symbol!) mean price increase after OSC crossings in undersold area (<20) " +  below$)
        print( belowPct$ + " of \(belowPriceIncreases.count) are actual increases")
//        print(belowPriceIncreases)
        print()

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
        
//        var smaBuy: LineCrossing
//        var macDBuy: LineCrossing
//        var oscBuy: LineCrossing
//
//        var smaSell: LineCrossing
//        var macDSell: LineCrossing
//        var oscSell: LineCrossing
        
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
        
    func buyTriggersThreeLowOnly() {
        
    }


}
