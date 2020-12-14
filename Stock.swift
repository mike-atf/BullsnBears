//
//  Stock.swift
//  TrendMyStocks
//
//  Created by aDav on 01/12/2020.
//

import Foundation

typealias PriceDate = (date: Date, price: Double)
typealias TrendInfoPackage = (incline: Double?, endPrice: Double, pctIncrease: Double, increaseMin: Double, increaseMax: Double)

struct Stock {
    
    var name: String
    var dailyPrices: [PricePoint]
    var fileURL: URL?
    
    init(name: String, dailyPrices:[PricePoint], fileURL: URL?) {
        self.name = name
        self.dailyPrices = dailyPrices
        self.fileURL = fileURL
    }
    
    public func priceOnDate(date: Date, priceOption: PricePointOptions) -> Double {
        
        let prices = dailyPrices.filter { (pricePoint) -> Bool in
            if pricePoint.tradingDate >= date { return true }
            else { return false }
        }
        
        return prices.first!.returnPrice(option: priceOption)
    }
    
    public func findTrends(from: Date? = nil, to: Date? = nil, priceOption: PricePointOptions, findOption: FindOptions) -> [StockTrend] {
        
        let lastDate = to ?? dailyPrices.last!.tradingDate
        let firstDate = from ?? dailyPrices.first!.tradingDate
        var trends = [StockTrend]()
        
        // find turning point by identifying high and low points:
        // from dailyPrice to dailyPrice: check trend to previous price: upward or downward
        // compare with price to next price. If up/downward != previous trend = 'turning point'
        // trends are between turning points
        
        
        let dailyPricesInRange = dailyPrices.filter { (pricePoint) -> Bool in
            if pricePoint.tradingDate < firstDate { return false }
            else if pricePoint.tradingDate > lastDate { return false }
            else { return true }
        }
        
        var trendChangePoints = [dailyPricesInRange.first!]
        
        for index in 1..<dailyPricesInRange.count-1 {
            
            let previous = dailyPricesInRange[index-1].returnPrice(option: priceOption)
            let current = dailyPricesInRange[index].returnPrice(option: priceOption)
            let next = dailyPricesInRange[index+1].returnPrice(option: priceOption)
            
            let trendToCurrent = current - previous
            let trendToNext = next - current
            
            if (trendToCurrent != 0 && trendToNext != 0) {
                let trendToCurrentDirection = (trendToCurrent / abs(trendToCurrent)) // 1 or -1
                let trendToNextDirection = (trendToNext / abs(trendToNext))
                
                if trendToCurrentDirection + trendToNextDirection == 0 {
                    trendChangePoints.append(dailyPricesInRange[index])
                }
            }
        }
        trendChangePoints.append(dailyPricesInRange.last!)
        
        for index in 0..<trendChangePoints.count - 1 {
            let newTrend = StockTrend(start: trendChangePoints[index].tradingDate, end: trendChangePoints[index+1].tradingDate, startPrice: trendChangePoints[index].returnPrice(option: priceOption), endPrice: trendChangePoints[index+1].returnPrice(option: priceOption))
            trends.append(newTrend)
        }
 
        return trends
    }
    
    public func longerTrends(from: Date? = nil, to: Date? = nil, priceOption: PricePointOptions, findOption: FindOptions) -> [StockTrend] {
        
        let lastDate = to ?? dailyPrices.last!.tradingDate
        let firstDate = from ?? dailyPrices.first!.tradingDate
        var trends = [StockTrend]()
        
        let dailyPricesInRange = dailyPrices.filter { (pricePoint) -> Bool in
            if pricePoint.tradingDate < firstDate { return false }
            else if pricePoint.tradingDate > lastDate { return false }
            else { return true }
        }
        
        var currentTrendStart = dailyPricesInRange.first!.tradingDate
        var currentTrendIncline: Double = 0
        var currentTrendStartPrice = dailyPricesInRange.first!.returnPrice(option: priceOption)
        
        for index in 1..<dailyPricesInRange.count-1 {
            
            let previous = dailyPricesInRange[index-1].returnPrice(option: priceOption)
            let current = dailyPricesInRange[index].returnPrice(option: priceOption)
            
            let expectedValue = previous + currentTrendIncline * dailyPricesInRange[index].tradingDate.timeIntervalSince(currentTrendStart)
            if abs(expectedValue) > abs(current) {
                let newTrend = StockTrend(start: currentTrendStart, end: dailyPricesInRange[index-1].tradingDate, startPrice: currentTrendStartPrice, endPrice: dailyPricesInRange[index-1].returnPrice(option: priceOption))
                currentTrendStart = dailyPricesInRange[index-1].tradingDate
                currentTrendStartPrice = dailyPricesInRange[index-1].returnPrice(option: priceOption)
                trends.append(newTrend)
            }
            else {
                currentTrendIncline = (dailyPricesInRange[index].returnPrice(option: priceOption) - currentTrendStartPrice) / dailyPricesInRange[index].tradingDate.timeIntervalSince(currentTrendStart)
            }
        }
        let lastTrend = StockTrend(start: currentTrendStart, end: dailyPricesInRange.last!.tradingDate, startPrice: currentTrendStartPrice, endPrice: dailyPricesInRange.last!.returnPrice(option: priceOption))
        trends.append(lastTrend)
        
        return trends
    }
    
    public func twoLowPointsTrend(priceOption: PricePointOptions, findOption: FindOptions, timeOption: QuarterOption) -> [StockTrend] {
        
        let lastDate = dailyPrices.last!.tradingDate
        let firstDate = dailyPrices.first!.tradingDate
        
        var halfTime = Date()
        var lastQuarterTime = Date()
        if timeOption == .half {
            halfTime = lastDate.addingTimeInterval(-lastDate.timeIntervalSince(firstDate)/2)
            lastQuarterTime = lastDate.addingTimeInterval(-lastDate.timeIntervalSince(firstDate)/4)
        }
        else if timeOption == .quarter {
            halfTime = lastDate.addingTimeInterval(-lastDate.timeIntervalSince(firstDate)/4)
            lastQuarterTime = lastDate.addingTimeInterval(-lastDate.timeIntervalSince(firstDate)/8)
        }

        
        let thirdQuarterPrices = dailyPrices.filter { (pricePoint) -> Bool in
            if pricePoint.tradingDate < halfTime { return false }
            else if pricePoint.tradingDate > lastQuarterTime { return false }
            else { return true }
        }
        
        let fourthQuarterPrices = dailyPrices.filter { (pricePoint) -> Bool in
            if pricePoint.tradingDate > lastQuarterTime { return true }
            else { return false }
        }

        
        let q3Sorted = thirdQuarterPrices.sorted { (p0, p1) -> Bool in
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
        
        let q4Sorted = fourthQuarterPrices.sorted { (p0, p1) -> Bool in
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

        
        let priceDifference = q4Sorted.first!.returnPrice(option: priceOption) - q3Sorted.first!.returnPrice(option: priceOption)
        let timeInterval = q4Sorted.first!.tradingDate.timeIntervalSince(q3Sorted.first!.tradingDate)
        let timeTo30DaysAfterLastDate = dailyPrices.last!.tradingDate.addingTimeInterval(foreCastTime).timeIntervalSince(q3Sorted.first!.tradingDate)
        let incline = priceDifference / timeInterval
        let endTrendPrice = q3Sorted.first!.returnPrice(option: priceOption) + incline * timeTo30DaysAfterLastDate

        let trend = StockTrend(start: q3Sorted.first!.tradingDate, end: dailyPrices.last!.tradingDate.addingTimeInterval(foreCastTime), startPrice: q3Sorted.first!.returnPrice(option: priceOption), endPrice: endTrendPrice)
        
        return [trend]
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
    
    public func findPrice(lowOrHigh: FindOptions, priceOption: PricePointOptions ,_ from: Date? = nil,_ to: Date? = nil) -> PriceDate? {
        
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
        
        var maxPriceDate = PriceDate(date: Date(), price: 0)
        var minPriceDate = PriceDate(date: Date(), price: 10000000)
        
        for pricePoint in pricesInRange {
            let price = pricePoint.returnPrice(option: priceOption)
            if price > maxPriceDate.price {
                maxPriceDate.price = price
                maxPriceDate.date = pricePoint.tradingDate
            }
            if price < minPriceDate.price {
                minPriceDate.price = price
                minPriceDate.date = pricePoint.tradingDate
            }
            
        }
//        let pricesInQuestion = pricesInRange.compactMap { $0.returnPrice(option: priceOption), $0.tradingDate }

        if lowOrHigh == .minimum { return minPriceDate}
        else { return maxPriceDate }
        
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
    
    public func trendsAnalysis(trends: [StockTrend], type: TrendType, priceOption: PricePointOptions, minOrMax: FindOptions, cutOffQuartiles: Bool = false) -> TrendInfoPackage? {
        
        
        var percentage = Double()
        var projectedPriceIn30Days = Double()
        var minRange = Double()
        var maxRange = Double()
        var meanIncline: Double?
        var totalTimeSpan = TimeInterval()
        
        let descendingTrendsInRange = trends.sorted { (t0, t1) -> Bool in
            if t0.startDate > t1.startDate { return true }
            else { return false }
        }
        
        totalTimeSpan = descendingTrendsInRange.first!.endDate.timeIntervalSince(descendingTrendsInRange.last!.startDate)

        if type == .mean {
        
            var inclinesInRange = descendingTrendsInRange.compactMap { $0.incline } // exclude nil elements

            if cutOffQuartiles {
                let sortedInclinesInRange = inclinesInRange.sorted { (t0, t1) -> Bool in
                    if t0 <= t1 { return true }
                    else { return false }
                }
                
                let count = inclinesInRange.count
                let quartile = Int(count / 10)
                inclinesInRange = Array(sortedInclinesInRange[quartile..<(count-quartile)])
            }
            
            meanIncline = inclinesInRange.reduce(0,+) // / totalTimeSpan

        }
        else if type == .recentWeighted {
            let lastDate = descendingTrendsInRange.first!.endDate

            let recentWeightedTrend = descendingTrendsInRange.compactMap { $0.recentWeightedIncline(totalTimeSpan, lastDate: lastDate) }
            meanIncline = (recentWeightedTrend.reduce(0,+)) / Double(recentWeightedTrend.count)
        }
        else {
            // timeWeighted or other
            return nil
        }
        
        
        if let validMeanIncline = meanIncline {
            if let validPrice = descendingTrendsInRange.last?.startPrice { // trends are in descending date order
                let futureDate = dailyPrices.last!.tradingDate.addingTimeInterval(foreCastTime)
                let trendStartToFutureDate = futureDate.timeIntervalSince(descendingTrendsInRange.last!.startDate)
                percentage = validMeanIncline * totalTimeSpan / validPrice
                projectedPriceIn30Days = validPrice + validMeanIncline * trendStartToFutureDate
            }
        }
        if let minIncline = descendingTrendsInRange.compactMap({ $0.incline }).min() {
            if let maxIncline = descendingTrendsInRange.compactMap({ $0.incline }).max() {
                
                let futureDate = descendingTrendsInRange.first!.endDate.addingTimeInterval(foreCastTime)
                let trendStartToFutureDate = futureDate.timeIntervalSince(descendingTrendsInRange.last!.startDate)
                
                let minimumAnnualIncrease = descendingTrendsInRange.last!.startPrice! + minIncline * trendStartToFutureDate
                let maximumAnnualIncrease = descendingTrendsInRange.last!.startPrice! + maxIncline * trendStartToFutureDate
                
                minRange = (minimumAnnualIncrease) / descendingTrendsInRange.last!.startPrice!
                maxRange = (maximumAnnualIncrease) / descendingTrendsInRange.last!.startPrice!

            }
        }
        
        return TrendInfoPackage(incline: meanIncline, endPrice: projectedPriceIn30Days, pctIncrease: percentage, increaseMin: minRange, increaseMax: maxRange)

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
    
    public func recentWeightedTrend(trends: [StockTrend], priceOption: PricePointOptions, minOrMax: FindOptions,_ from: Date? = nil, _ to: Date? = nil) -> Double? {

        var descendingTrends = trends.sorted { (t0, t1) -> Bool in
            if t0.startDate > t1.startDate { return true }
            else { return false }
        }
        
        if let validFrom = from {
            descendingTrends = descendingTrends.filter { (trend) -> Bool in
                if trend.endDate < validFrom { return false }
                if trend.startDate > to! { return false }
                return true
            }
        }
        
        let lastDate = descendingTrends.first!.startDate
        let totalTrendTime = descendingTrends.last!.endDate.timeIntervalSince(descendingTrends.first!.startDate)
        let recentWeightedTrend = trends.compactMap { $0.recentWeightedIncline(totalTrendTime, lastDate: lastDate) }
        return (recentWeightedTrend.reduce(0,+)) / Double(recentWeightedTrend.count)
    }
    
    public func correlationTrend(priceOption: PricePointOptions, minOrMax: FindOptions, from: Date? = nil, _ to: Date? = nil) -> Correlation? {
        
        let lastDate = to ?? dailyPrices.last!.tradingDate
        let firstDate = from ?? dailyPrices.first!.tradingDate
        
        let dailyPricesInRange = dailyPrices.filter { (pricePoint) -> Bool in
            if pricePoint.tradingDate < firstDate { return false }
            else if pricePoint.tradingDate > lastDate { return false }
            else { return true }
        }
        
        let yArray = dailyPricesInRange.compactMap { $0.returnPrice(option: priceOption) }
        let xArray = dailyPricesInRange.compactMap { $0.tradingDate.timeIntervalSince(dailyPricesInRange.first!.tradingDate)}
        
        
        guard yArray.count > 0 else {
            return nil
        }
        
        guard  xArray.count > 0 else {
            return nil
        }
        
        guard xArray.count == yArray.count else {
            print("Error in trend correlation: y.count != x.count")
            return nil
        }
        
        let ySum = yArray.reduce(0,+)
        let xSum = xArray.reduce(0,+)
        var xyProductArray = [Double]()
        var x2Array = [Double]()
        var y2Array = [Double]()
        var xySumArray = [Double]()
        let n: Double = Double(yArray.count)

        var count = 0
        for y in yArray {
            xyProductArray.append(y * xArray[count])
            x2Array.append(xArray[count] * xArray[count])
            xySumArray.append(y + xArray[count])
            y2Array.append(y * y)
            count += 1
        }
        
        let xyProductSum = xyProductArray.reduce(0,+)
        let x2Sum = x2Array.reduce(0,+)
        let y2Sum = y2Array.reduce(0,+)
        
        let numerator = n * xyProductSum - xSum * ySum
        let denom = (n * x2Sum - (xSum * xSum)) * (n * y2Sum - (ySum * ySum))

// Pearson correlation coefficient
        let  r = numerator / sqrt(denom)
        
        let xMean = xSum / n
        let yMean = ySum / n
        
        var xdiff2Sum = Double()
        var ydiff2Sum = Double()
        
//        count = 0
        for y in yArray {
            let ydiff = y - yMean
            ydiff2Sum += (ydiff * ydiff)
        }
        for x in xArray {
            let xdiff = x - xMean
            xdiff2Sum += (xdiff * xdiff)
        }
        
        let xSD = sqrt(xdiff2Sum / n)
        let ySD = sqrt(ydiff2Sum / n)
        
// m = incline of regression line
        let m = r * (ySD / xSD)
        
// b = y axis intercept of regression line
        let b = yMean - m * xMean

        return Correlation(m: m, b: b, r: r)
    }
    
    /*
    public func trendInfo(trends:[StockTrend], type: TrendType, cutOffQuartiles: Bool = false) -> TrendPackage? {
        
        var percentage: Double?
        var endPrice: Double?
        var minRange: Double?
        var maxRange: Double?
        
        var incline: Double?
        
        if type == .mean {
            incline = meanTrendIncline(trends: trends, cutOffQuartiles: type, cutOffQuartiles)
        }
        else if type == .recentWeighted {
            incline = recentWeightedTrend(trends: trends, priceOption: <#T##PricePointOptions#>, minOrMax: <#T##FindOptions#>, <#T##from: Date?##Date?#>, <#T##to: Date?##Date?#>)
        }
        
        if let validTrend = meanTrendIncline(trends: trends, from, to) {
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
    */
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
    
    public func timeWeightedIncline() -> Double? {
        // makes sense only for trends of different time durations.
        // currently al are 30 days
        guard let validIncline = incline else { return nil }
        return validIncline * endDate.timeIntervalSince(startDate)
        
    }
    
    public func recentWeightedIncline(_ totalTime: TimeInterval, lastDate: Date) -> Double? {
        guard let validIncline = incline else { return nil }
        let timeSinceLastDate = lastDate.timeIntervalSince(endDate)
        let factor = 1 - timeSinceLastDate / totalTime
//        print("unweighted incline \(validIncline)  - factor \(factor)")
        return validIncline * factor
    }
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

