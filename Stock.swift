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
    
    func findDailyPricesIndexFromDate(_ date: Date) -> Int? {
        
        for index in 1..<dailyPrices.count {
            if dailyPrices[index].tradingDate > date { return index-1 }
        }

        return nil
    }
    
    /*
    public func findMajorTrends(priceOption: PricePointOptions, findOption: FindOptions, changeThreshold: Double) -> [StockTrend] {
    
        let microTrends = findTrends(priceOption: priceOption, findOption: findOption)
        var macroTrends = [StockTrend]()
        
        
        var previous = microTrends.first!
        var startTrendDate = microTrends.first!.startDate
        var startTrendPrice = microTrends.first!.startPrice
        for i in 1..<microTrends.count {
            let current = microTrends[i]
            
            if abs(current.incline!) * changeThreshold > abs(previous.incline!) {
                let newTrend = StockTrend(start: startTrendDate, end: current.endDate, startPrice: startTrendPrice, endPrice: current.endPrice!)
                macroTrends.append(newTrend)
                startTrendDate = current.startDate
                startTrendPrice = current.startPrice!
            }
            
            previous = current
        }
        var lastTrend = macroTrends.last!
        macroTrends.removeLast()
        lastTrend.endPrice = dailyPrices.last!.returnPrice(option: priceOption)
        lastTrend.endDate = dailyPrices.last!.tradingDate
        let trend = StockTrend(start: lastTrend.startDate, end: lastTrend.endDate, startPrice: lastTrend.startPrice, endPrice: lastTrend.endPrice)

        macroTrends.append(trend)
        return macroTrends
    
    }
    */
    
    
    public func longerTrend(_ properties: TrendProperties) -> StockTrend? {
        
        guard let initialTrend = lowHighTrend(properties: properties) else { return nil }
        var newTrend = StockTrend(start: initialTrend.startDate, end: initialTrend.endDate, startPrice: initialTrend.startPrice, endPrice: initialTrend.endPrice)
        
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

        var priceOption: PricePointOptions!
//        var findOption: FindOptions!
        if properties.type == .bottom {
            priceOption = .low
//            findOption = .minimum
        }
        else if properties.type == .ceiling {
            priceOption = .high
//            findOption = .maximum
        }

        // go backwards in weekly (5point) steps from start of this trend
        // determine the trend for this week and check wether it's different from the initialTrend
        // if it's not create new trend from the lowest/highest point of this week to the second point of the initialTrend
        // if it is return a new trend based on the new start date
        
        let periodStartDate = initialTrend.startDate
        guard let startIndex = findDailyPricesIndexFromDate(periodStartDate) else { return newTrend }
        
        for index in stride(from: startIndex-1, to: 0, by: -1) {
            
            let price = dailyPrices[index].returnPrice(option: priceOption)
            let date = dailyPrices[index].tradingDate
            
//            let calculatedTrendPrice = newTrend.startDate.timeIntervalSince(date) * -newTrend.incline!
            var tolerance = [newTrend.startPrice! + newTrend.startDate.timeIntervalSince(date) * -newTrend.incline! * 0.8]
            tolerance.append(newTrend.startPrice! + newTrend.startDate.timeIntervalSince(date) * -newTrend.incline! * 1.2)
            
            print()
            print("price is \(price)")
            print("price barcket is [\(tolerance.min()!) - \(tolerance.max()!)]")
            
            if price > tolerance.min()! && price < tolerance.max()! {
                newTrend = StockTrend(start: date, end: initialTrend.endDate, startPrice: price, endPrice: initialTrend.endPrice)
            }
        }
        
        return newTrend

        
// find the [dailyPrice] element of the initial Trend start
//        var periodStartDate = initialTrend.startDate.addingTimeInterval(-trendDuration)
//        while periodStartDate >= dailyPrices.first!.tradingDate {
//
//            guard let startIndex = findDailyPricesIndexFromDate(periodStartDate) else { return newTrend }
//            guard let endIndex = findDailyPricesIndexFromDate(periodStartDate.addingTimeInterval(trendDuration)) else { return newTrend }
//
//            let pricesInRange = dailyPrices[startIndex..<endIndex]
//
//            let sortedPricesInRange = pricesInRange.sorted { (d0, d1) -> Bool in
//                if findOption == .minimum {
//                    if d0.returnPrice(option: priceOption) < d1.returnPrice(option: priceOption) { return true }
//                    else { return false }
//                }
//                else {
//                    if d0.returnPrice(option: priceOption) > d1.returnPrice(option: priceOption) { return true }
//                    else { return false }
//                }
//            }
//
//            guard let lowHighPricePoint = sortedPricesInRange.first else {
//                return newTrend
//            }
//
//            let tempTrend = StockTrend(start: lowHighPricePoint.tradingDate, end: newTrend.startDate, startPrice: lowHighPricePoint.returnPrice(option: priceOption), endPrice: newTrend.endPrice!)
//
//            guard let newIncline = tempTrend.incline else { return newTrend }
//
//            if abs((newIncline - initialTrend.incline!) / initialTrend.incline!) < 1.0 { // less than 50% difference
//                newTrend = tempTrend
//                print("trend difference low = \(abs((newIncline - initialTrend.incline!) / initialTrend.incline!) )")
//            }
//            else {
//                print("trend difference high = \(abs((newIncline - initialTrend.incline!) / initialTrend.incline!) )")
//                return newTrend
//            }
//
//            periodStartDate = lowHighPricePoint.tradingDate.addingTimeInterval(-trendDuration)
//        }

//        return newTrend
        
    }
    
    /// find lowest/ highest price in the first half and a second in the second half, with the lowest/ highest resulting ! incline !
    public func lowHighTrend(properties: TrendProperties) -> StockTrend? {
        
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
        let halfDate = lastDate.addingTimeInterval(-trendDuration / 2)
        
        let dailyPricesInFirstHalf = dailyPrices.filter { (pricePoint) -> Bool in
            if pricePoint.tradingDate < startDate { return false }
            else if pricePoint.tradingDate > halfDate { return false }
            else { return true }
        }
        
        let dailyPricesInSecondHalf = dailyPrices.filter { (pricePoint) -> Bool in
            if pricePoint.tradingDate < halfDate { return false }
            else { return true }
        }
        
        guard  dailyPricesInFirstHalf.count > 1 else {
            return nil
        }
        
        guard  dailyPricesInSecondHalf.count > 1 else {
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
        
        for pricePoint in dailyPricesInFirstHalf {
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
        
        for pricePoint in dailyPricesInSecondHalf {
            
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
            let sorted = dailyPricesInSecondHalf.sorted { (pp1, pp2) -> Bool in
                if pp1.returnPrice(option: priceOption) > pp2.returnPrice(option: priceOption) { return true }
                else { return false }
            }
            
            if let topPricePoint = sorted.first {
                let comparatorTrend = StockTrend(start: firstPricePoint.tradingDate, end: topPricePoint.tradingDate, startPrice: firstPricePoint.returnPrice(option: priceOption), endPrice: topPricePoint.returnPrice(option: priceOption))
                
                if (abs(comparatorTrend.incline ?? 0) ) < (abs(initialTrend.incline ?? 0)) {
                    initialTrend = comparatorTrend
                }
            }
        }
        
        
        return initialTrend
    }
    
    /*
    public func findTrends(from: Date? = nil, to: Date? = nil, priceOption: PricePointOptions, findOption: FindOptions, changeThreshold: Double? = nil) -> [StockTrend] {
        
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
                
                if let validThreshold = changeThreshold {
                    if (abs(trendToCurrent) - abs(trendToNext)) > (1.0 + validThreshold) {
                        trendChangePoints.append(dailyPricesInRange[index])
                    }
                }
                else if trendToCurrentDirection + trendToNextDirection == 0 {
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
    */
    
    /*
    public func longerTrends(from: Date? = nil, to: Date? = nil, priceOption: PricePointOptions, findOption: FindOptions, threshold: Double? = nil) -> [StockTrend] {
        
        let lastDate = to ?? dailyPrices.last!.tradingDate
        let firstDate = from ?? dailyPrices.first!.tradingDate
        let validThreshold = 1.0 - (threshold ?? 0)
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
            
            let expectedValue = previous + currentTrendIncline * dailyPricesInRange[index].tradingDate.timeIntervalSince(currentTrendStart) * validThreshold
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
    */

    public func twoPointTrend(properties: TrendProperties) -> StockTrend {
        
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
        let halfDate = lastDate.addingTimeInterval(-trendDuration / 2)
        
        let dailyPricesInFirstHalf = dailyPrices.filter { (pricePoint) -> Bool in
            if pricePoint.tradingDate < startDate { return false }
            else if pricePoint.tradingDate > halfDate { return false }
            else { return true }
        }
        
        let dailyPricesInSecondtHalf = dailyPrices.filter { (pricePoint) -> Bool in
            if pricePoint.tradingDate > halfDate { return true }
            else { return false }
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
        
        let h1Sorted = dailyPricesInFirstHalf.sorted { (p0, p1) -> Bool in
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
        
        let h2Sorted = dailyPricesInSecondtHalf.sorted { (p0, p1) -> Bool in
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
        
        let trend = StockTrend(start: h1Sorted.first!.tradingDate, end: h2Sorted.first!.tradingDate, startPrice: h1Sorted.first!.returnPrice(option: priceOption), endPrice: h2Sorted.first!.returnPrice(option: priceOption))
        
        return trend
    }
    
    public func correlationTrend2(properties: TrendProperties) -> Correlation? {
        
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
        
        return getCorrelation(xArray: xArray, yArray: yArray)
    }
    
    func getCorrelation(xArray: [Double]?, yArray: [Double]?) -> Correlation? {
        
        guard (yArray ?? []).count > 0 else {
            return nil
        }
        
        guard (xArray ?? []).count > 0 else {
            return nil
        }
        
        guard (xArray ?? []).count == (yArray ?? []).count else {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "Error in trend correlation: y.count != x.count")
            return nil
        }
        
        let ySum = yArray!.reduce(0,+)
        let xSum = xArray!.reduce(0,+)
        var xyProductArray = [Double]()
        var x2Array = [Double]()
        var y2Array = [Double]()
        var xySumArray = [Double]()
        let n: Double = Double(yArray!.count)

        var count = 0
        for y in yArray! {
            xyProductArray.append(y * xArray![count])
            x2Array.append(xArray![count] * xArray![count])
            xySumArray.append(y + xArray![count])
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
        for y in yArray! {
            let ydiff = y - yMean
            ydiff2Sum += (ydiff * ydiff)
        }
        for x in xArray! {
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
    
    public func testRegressionReliability(_covering timePeriod: TimeInterval, trendType: TrendType) -> Double? {
        
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
            
            guard let correlation = getCorrelation(xArray: xArray, yArray: yArray) else {
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
            
//            var firstPrice = Double()
//
//            if priceOption == .low {
//                firstPrice = predictionPeriodPrices.first!.low
//            } else {
//                firstPrice = predictionPeriodPrices.first!.high
//            }

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
    
    /// applies trendType method (bottom or ceiling) over a timePeriod (1 or 3 months) for every single trading day and calculates how many of the predicted bottom/ceiling prices are NOT the lowest/ highest price during the forecast period (30 days)
    public func testTwoPointReliability(_covering timePeriod: TimeInterval, trendType: TrendType) -> Double? {
        
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
    
    /*
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
    */
        
}

