//
//  Stock.swift
//  TrendMyStocks
//
//  Created by aDav on 01/12/2020.
//

import Foundation

typealias PriceDate = (date: Date, price: Double)
typealias TrendPackage = (endPrice: Double, pctIncrease: Double, increaseMin: Double, increaseMax: Double)

struct Stock {
    
    var name: String
    var dailyPrices: [PricePoint]
    
    init(name: String, dailyPrices:[PricePoint]) {
        self.name = name
        self.dailyPrices = dailyPrices
    }
    
    
    public func findTrends(_ days: TimeInterval, priceOption: PricePointOptions, findOption: FindOptions) -> [StockTrend] {
        
        var endDate = dailyPrices.last!.tradingDate
        let lastDate = dailyPrices.first!.tradingDate
        var previousLowPrice: Double?
        var trends = [StockTrend]()
        
        while endDate >= lastDate {
            let startDate = endDate.addingTimeInterval(-days*24*3600)
            if let price = findPrice(lowOrHigh: findOption, priceOption: priceOption,startDate, endDate) {
                let newTrend = StockTrend(start: startDate, end: endDate, startPrice: price, endPrice: previousLowPrice)
                trends.append(newTrend)
                previousLowPrice = price
           }
            endDate = endDate.addingTimeInterval(-days*24*3600)
        }
                
        trends.sort { (t0, t1) -> Bool in
            if t0.startDate < t1.startDate { return true }
            else { return false }
        }
        return trends
    }
    
    public func findPricePoints(_ days: TimeInterval, priceOption: PricePointOptions, findOption: FindOptions) -> [PriceDate] {
        // extract prices and their tradingDates for all 30 day intervals
        // starting from most recent, so date decending

        var pricePoints = [PriceDate]()
        var endDate = dailyPrices.last!.tradingDate
        let lastDate = dailyPrices.first!.tradingDate
        
        while endDate >= lastDate {
            let startDate = endDate.addingTimeInterval(-days*24*3600)
                        
            var dailyPriceInRange = dailyPrices.filter( { (element) -> Bool in
                if element.tradingDate < startDate { return false }
                if element.tradingDate > endDate { return false }
                return true
            })
            
            dailyPriceInRange.sort { (p0, p1) -> Bool in
                
                if (p0.returnPrice(option: priceOption)) < (p1.returnPrice(option: priceOption)) { return true }
                else { return false }
            }
            
            var newPriceDate: PriceDate!
            
            if findOption == .minimum {
                newPriceDate = (dailyPriceInRange.first!.tradingDate, dailyPriceInRange.first!.returnPrice(option: priceOption))
                
            }
            else {
                newPriceDate = (dailyPriceInRange.last!.tradingDate, dailyPriceInRange.last!.returnPrice(option: priceOption))
            }
                        
            pricePoints.append(newPriceDate)
            endDate = endDate.addingTimeInterval(-days*24*3600)
        }
        return pricePoints
    }
    
    
    public func findPrice(lowOrHigh: FindOptions ,priceOption: PricePointOptions ,_ from: Date? = nil,_ to: Date? = nil) -> Double? {
        
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
        
        let pricesInQuestion = pricesInRange.compactMap { $0.returnPrice(option: priceOption) }

        if lowOrHigh == .minimum { return pricesInQuestion.min() }
        else { return pricesInQuestion.max() }
        
    }
    
    public func lowestPrice(_ from: Date? = nil,_ to: Date? = nil) -> Double? {
        
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
        
        let minDate = dailyPrices.compactMap { $0.tradingDate }.min()
        
        let maxDate = dailyPrices.compactMap { $0.tradingDate }.max()
        
        if minDate != nil && maxDate != nil { return [minDate!, maxDate!] }
        else { return nil }
    }
    
    public func averageTrend(trends: [StockTrend], cutOffQuartiles: Bool = false,_ from: Date? = nil, _ to: Date? = nil) -> Double? {
        
        var trendsInRange = trends
        
        if let validFrom = from {
            trendsInRange = trends.filter({ (trend) -> Bool in
                if trend.endDate < validFrom { return false }
                else if trend.startDate > to! { return false }
                else { return true }
            })
        }
        
        
        var inclinesInRange = trendsInRange.compactMap { $0.incline } // exclude nil elements
//        let start = from ?? dailyPrices.compactMap{ $0.tradingDate }.min()!
//        let end = to ?? dailyPrices.compactMap{ $0.tradingDate }.max()!
//        var inclinesInRange = trendsInRange.compactMap { $0.timeWeightedIncline(totalTimeSpan: (end.timeIntervalSince(start))) } // exclude nil elements

        if cutOffQuartiles {
            let sortedInclinesInRange = inclinesInRange.sorted { (t0, t1) -> Bool in
                if t0 <= t1 { return true }
                else { return false }
            }
            
            let count = sortedInclinesInRange.count
            let quartile = Int(count / 4)
            inclinesInRange = Array(sortedInclinesInRange[quartile..<(count-quartile)])
        }
        
        let count = inclinesInRange.count
        let sum = inclinesInRange.reduce(0,+)
        if count > 0 {
            return sum / Double(count)
        }
        else { return nil }
    }
    
    public func trendRange(trends:[StockTrend], _ from: Date? = nil, _ to: Date? = nil) -> [Double] {
        
        var trendsInRange = trends
        
        if let validFrom = from {
            trendsInRange = trends.filter({ (trend) -> Bool in
                if trend.endDate < validFrom { return false }
                else if trend.startDate > to! { return false }
                else { return true }
            })
        }
        
        let inclinesInRange = trendsInRange.compactMap { $0.incline } // exclude nil elements
        
        return [inclinesInRange.min()!, inclinesInRange.max()!]

    }
    
//    public func recentAverageTrend(trends: [StockTrend],_ from: Date? = nil, _ to: Date? = nil) -> Double? {
//
//        trends.forEach { (trend) in
//            <#code#>
//        }
//
//    }
    
    public func trendInfo(trends:[StockTrend], _ from: Date? = nil, _ to: Date? = nil) -> TrendPackage? {
        
        var percentage: Double?
        var endPrice: Double?
        var minRange: Double?
        var maxRange: Double?
        
        if let validTrend = averageTrend(trends: trends, from, to) {
            let lowTrendAnnualIncrease = validTrend * TimeInterval(365*24*3600)
            percentage = lowTrendAnnualIncrease / dailyPrices.first!.low
            endPrice = validTrend * (395*24*3600) + dailyPrices.first!.low
        }
        
        var trendsInRange = trends
        
        if let validFrom = from {
            trendsInRange = trends.filter({ (trend) -> Bool in
                if trend.endDate < validFrom { return false }
                else if trend.startDate > to! { return false }
                else { return true }
            })
        }
        
        if let minTrend = trendsInRange.compactMap({ $0.incline }).min() {
            if let maxTrend = trendsInRange.compactMap({ $0.incline }).max() {
                
                let lowTrendMinAnnualIncrease = minTrend * TimeInterval(365*24*3600)
                let lowTrendMaxAnnualIncrease = maxTrend * TimeInterval(365*24*3600)
                
                minRange = lowTrendMinAnnualIncrease / dailyPrices.first!.low
                maxRange = lowTrendMaxAnnualIncrease / dailyPrices.first!.low

            }
        }

        
       if percentage == nil || endPrice == nil || minRange == nil || maxRange == nil {
            return nil
        }
        else {
            return TrendPackage(endPrice!, percentage!, minRange!, maxRange!)
        }
    }
    
    /*
    func correlation(trends: [StockTrend], meanIncline: Double) -> Double? {
        
        let startDate = trends.compactMap{ $0.startDate }.min()!
        let endDate = trends.compactMap{ $0.endDate }.max()!
        
        let pricesInTrendRange = dailyPrices.filter { (pricePoint) -> Bool in
            if pricePoint.tradingDate < startDate { return false }
            if pricePoint.tradingDate > endDate { return false }
            else { return true }
        }
        
        var projectedPrices = [Double]()
        guard let startingPrice = pricesInTrendRange.first?.low else { return nil }
        
        for price in pricesInTrendRange {
            let timeSinceStart = price.tradingDate.timeIntervalSince(startDate)
            projectedPrices.append(startingPrice + timeSinceStart * meanIncline)
        }
        
        let sumY = pricesInTrendRange.compactMap{ $0.low }.reduce(0,+)
        let countY = pricesInTrendRange.count
        guard countY > 0 else { return nil }
        let meanY = sumY / Double(countY)
        
        let meanX = 24*3600
        trends.sorted { (t1, t2) -> Bool in
            if t1.startDate < t2.startDate { return true }
            else { return false }
        }.forEach { (trend) in
            <#code#>
        }
    }
    */
    
}

struct StockTrend {
    var startDate: Date
    var endDate: Date
    var startPrice: Double?
    var endPrice: Double?
    var incline: Double?
    
    init(start: Date, end: Date, startPrice: Double?, endPrice: Double?) {
        self.startDate = start
        self.endDate = end
        self.startPrice = startPrice
        self.endPrice = endPrice
        
        if let validStart = startPrice {
            if let validEnd = endPrice {
                incline = (validEnd - validStart) / endDate.timeIntervalSince(startDate)
            }
        }
    }
    
    public func timeWeightedIncline(totalTimeSpan: TimeInterval) -> Double? {
        
        guard let validIncline = incline else { return nil }
        return validIncline * (endDate.timeIntervalSince(startDate) / totalTimeSpan) }
}

struct PricePoint {
    var tradingDate: Date
    var open: Double
    var high: Double
    var low: Double
    var close: Double
    var volume: Double
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = NSLocale.current
        formatter.timeZone = NSTimeZone.local
        formatter.dateStyle = .short
        return formatter
    }()

    
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
    
    public func returnPrice(option: PricePointOptions) -> Double {
        
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
//        default:
//            print("unrecognised price selector in PricePoint - returnPrice")
//            return low
        }
        
    }
}

