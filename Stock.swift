//
//  Stock.swift
//  TrendMyStocks
//
//  Created by aDav on 01/12/2020.
//

import Foundation

typealias PriceDate = (date: Date, price: Double)
typealias TrendInfoPackage = (incline: Double?, endPrice: Double, pctIncrease: Double, increaseMin: Double, increaseMax: Double)

protocol StockDelegate {
    func priceUpdateComplete(symbol: String)
}

class Stock {
    
    var symbol: String
    var name_short: String?
    var name_long: String?
    var dailyPrices: [PricePoint]
    var fileURL: URL?
    var delegate: StockDelegate?
    var needsUpdate: Bool {
        return Date().timeIntervalSince(dailyPrices.last?.tradingDate ?? Date()) > 24*3600 ? true : false
    }
    
    init(name: String, dailyPrices:[PricePoint], fileURL: URL?, delegate: StockDelegate?) {
        self.symbol = name
        self.delegate = delegate
        
        if let dictionary = stockTickerDictionary {
            name_long = dictionary[symbol]
            
            if let longNameComponents = name_long?.split(separator: " ") {
                let removeTerms = ["Inc.","Incorporated" , "Ltd", "Ltd.", "LTD", "Limited","plc." ,"Group", "Corp.", "Corporation","Company" ,"International", "NV","&", "The", "Walt", "Co."]
                let replaceTerms = ["S.A.": "sa "]
                var cleanedName = String()
                for component in longNameComponents {
                    if replaceTerms.keys.contains(String(component)) {
                        cleanedName += replaceTerms[String(component)] ?? ""
                    } else if !removeTerms.contains(String(component)) {
                        cleanedName += String(component) + " "
                    }
                }
                name_short = String(cleanedName.dropLast())
            }
        }
        
        self.dailyPrices = dailyPrices
        self.fileURL = fileURL
    }
    
    //MARK: - File update download function
    func startPriceUpdate(yahooRefDate: Date) {
        
        print("Price update requested for \(symbol)...")
        
        let nowSinceRefDate = Date().timeIntervalSince(yahooRefDate)
        let start = nowSinceRefDate - TimeInterval(3600 * 24 * 366)
        
        let end$ = numberFormatter.string(from: nowSinceRefDate as NSNumber) ?? ""
        let start$ = numberFormatter.string(from: start as NSNumber) ?? ""
        
        var urlComponents = URLComponents(string: "https://query1.finance.yahoo.com/v7/finance/download/\(symbol)")
        urlComponents?.queryItems = [URLQueryItem(name: "period1", value: start$),URLQueryItem(name: "period2", value: end$),URLQueryItem(name: "interval", value: "1d"), URLQueryItem(name: "events", value: "history"), URLQueryItem(name: "includeAdjustedClose", value: "true") ]
        
        var webPath = "https://query1.finance.yahoo.com/v7/finance/download/"
        webPath += symbol+"?"
        webPath += "period1=" + start$
        webPath += "&period2=" + end$
        webPath += "&interval=1d&events=history&includeAdjustedClose=true"
        
        if let sourceURL = urlComponents?.url {
            downLoadWebFile(sourceURL)
        }
    }
    
    func downLoadWebFile(_ url: URL) {
        
        let downloadTask = URLSession.shared.downloadTask(with: url) { [self]
            urlOrNil, responseOrNil, errorOrNil in
            
            guard errorOrNil == nil else {
                DispatchQueue.main.async {
                    ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: errorOrNil, errorInfo: "couldn't download stock update ")
                }
                return
            }
            
            guard responseOrNil != nil else {
                DispatchQueue.main.async {
                    ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "couldn't download stock update, website response \(String(describing: responseOrNil))")
                }
                return
            }
            
            guard let fURL = urlOrNil else { return }
                        
            do {
                let documentsURL = try
                    FileManager.default.url(for: .documentDirectory,
                                            in: .userDomainMask,
                                            appropriateFor: nil,
                                            create: true)
                
                let tempURL = documentsURL.appendingPathComponent(symbol + "-temp.csv")
                let targetURL = documentsURL.appendingPathComponent(symbol + ".csv")
                
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    removeFile(tempURL)
                }

                try FileManager.default.moveItem(at: fURL, to: tempURL)
                
                guard CSVImporter.matchesExpectedFormat(url: tempURL) else {
                    DispatchQueue.main.async {
                        ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "no matching stock symbol, or file error")
                    }
                    return
                }

                if FileManager.default.fileExists(atPath: targetURL.path) {
                    removeFile(targetURL)
                }

                try FileManager.default.moveItem(at: tempURL, to: targetURL)
                extractPriceData(url: targetURL)
                
            } catch {
                DispatchQueue.main.async {
                    ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "can't move and save downloaded file")
                }
            }
        }
        
        downloadTask.resume()
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
    
    func extractPriceData(url: URL) {
        
        print("...Price was updated for \(symbol)")

        if let updatedPrices = CSVImporter.extractPriceData(url: fileURL, symbol: symbol) {
            self.dailyPrices = updatedPrices
            self.fileURL = url
            delegate?.priceUpdateComplete(symbol: symbol)
        }
    }
    
    //MARK: - internal functions
    
//    public func priceOnDate(date: Date, priceOption: PricePointOptions) -> Double {
//
//        let prices = dailyPrices.filter { (pricePoint) -> Bool in
//            if pricePoint.tradingDate >= date { return true }
//            else { return false }
//        }
//
//        return prices.first!.returnPrice(option: priceOption)
//    }
    
    func findDailyPricesIndexFromDate(_ date: Date) -> Int? {
        
        for index in 1..<dailyPrices.count {
            if dailyPrices[index].tradingDate > date { return index-1 }
        }

        return nil
    }
    
    //MARK: - trend functions
    
//    public func longerTrend(_ properties: TrendProperties) -> StockTrend? {
//
//        guard let initialTrend = lowHighTrend(properties: properties) else { return nil }
//        var newTrend = StockTrend(start: initialTrend.startDate, end: initialTrend.endDate, startPrice: initialTrend.startPrice, endPrice: initialTrend.endPrice)
//
//        let lastDate = dailyPrices.last!.tradingDate
//        let firstDate = dailyPrices.first!.tradingDate
//
//        var trendDuration = lastDate.timeIntervalSince(firstDate)
//
//        switch properties.time {
//        case .full:
//            trendDuration = lastDate.timeIntervalSince(firstDate)
//        case .quarter:
//            trendDuration = trendDuration / 4
//        case .half:
//            trendDuration = trendDuration / 2
//        case .month:
//            trendDuration = 30*24*3600
//        case .none:
//            trendDuration = lastDate.timeIntervalSince(firstDate)
//        }
//
//        var priceOption: PricePointOptions!
////        var findOption: FindOptions!
//        if properties.type == .bottom {
//            priceOption = .low
////            findOption = .minimum
//        }
//        else if properties.type == .ceiling {
//            priceOption = .high
////            findOption = .maximum
//        }
//
//        // go backwards in weekly (5point) steps from start of this trend
//        // determine the trend for this week and check wether it's different from the initialTrend
//        // if it's not create new trend from the lowest/highest point of this week to the second point of the initialTrend
//        // if it is return a new trend based on the new start date
//
//        let periodStartDate = initialTrend.startDate
//        guard let startIndex = findDailyPricesIndexFromDate(periodStartDate) else { return newTrend }
//
//        for index in stride(from: startIndex-1, to: 0, by: -1) {
//
//            let price = dailyPrices[index].returnPrice(option: priceOption)
//            let date = dailyPrices[index].tradingDate
//
//            var tolerance = [newTrend.startPrice! + newTrend.startDate.timeIntervalSince(date) * -newTrend.incline! * 0.8]
//            tolerance.append(newTrend.startPrice! + newTrend.startDate.timeIntervalSince(date) * -newTrend.incline! * 1.2)
//
//            if price > tolerance.min()! && price < tolerance.max()! {
//                newTrend = StockTrend(start: date, end: initialTrend.endDate, startPrice: price, endPrice: initialTrend.endPrice)
//            }
//        }
//
//        return newTrend
//
//    }
    
    /// find lowest/ highest price in the first half and a second in the second half, with the lowest/ highest resulting ! incline !
    public func lowHighTrend(properties: TrendProperties) -> StockTrend? {
        
        
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

//    public func twoPointTrend(properties: TrendProperties) -> StockTrend {
//
//        let lastDate = dailyPrices.last!.tradingDate
//        let firstDate = dailyPrices.first!.tradingDate
//
//        var trendDuration = lastDate.timeIntervalSince(firstDate)
//
//        switch properties.time {
//        case .full:
//            trendDuration = lastDate.timeIntervalSince(firstDate)
//        case .quarter:
//            trendDuration = trendDuration / 4
//        case .half:
//            trendDuration = trendDuration / 2
//        case .month:
//            trendDuration = 30*24*3600
//        case .none:
//            trendDuration = lastDate.timeIntervalSince(firstDate)
//        }
//
//        let startDate = lastDate.addingTimeInterval(-trendDuration)
//        let halfDate = lastDate.addingTimeInterval(-trendDuration / 2)
//
//        let dailyPricesInFirstHalf = dailyPrices.filter { (pricePoint) -> Bool in
//            if pricePoint.tradingDate < startDate { return false }
//            else if pricePoint.tradingDate > halfDate { return false }
//            else { return true }
//        }
//
//        let dailyPricesInSecondtHalf = dailyPrices.filter { (pricePoint) -> Bool in
//            if pricePoint.tradingDate > halfDate { return true }
//            else { return false }
//        }
//
//        var priceOption: PricePointOptions!
//        var findOption: FindOptions!
//
//        if properties.type == .bottom {
//            priceOption = .low
//            findOption = .minimum
//        }
//        else if properties.type == .ceiling {
//            priceOption = .high
//            findOption = .maximum
//        }
//
//        let h1Sorted = dailyPricesInFirstHalf.sorted { (p0, p1) -> Bool in
//            if findOption == .minimum {
//                if p0.returnPrice(option: priceOption) < p1.returnPrice(option: priceOption) {
//                    return true
//                } else {
//                    return false
//                }
//            }
//            else {
//                if p0.returnPrice(option: priceOption) > p1.returnPrice(option: priceOption) {
//                    return true
//                } else {
//                    return false
//                }
//            }
//        }
//
//        let h2Sorted = dailyPricesInSecondtHalf.sorted { (p0, p1) -> Bool in
//            if findOption == .minimum {
//                if p0.returnPrice(option: priceOption) < p1.returnPrice(option: priceOption) {
//                    return true
//                } else {
//                    return false
//                }
//            }
//            else {
//                if p0.returnPrice(option: priceOption) > p1.returnPrice(option: priceOption) {
//                    return true
//                } else {
//                    return false
//                }
//            }
//        }
//
//        let trend = StockTrend(start: h1Sorted.first!.tradingDate, end: h2Sorted.first!.tradingDate, startPrice: h1Sorted.first!.returnPrice(option: priceOption), endPrice: h2Sorted.first!.returnPrice(option: priceOption))
//
//        return trend
//    }
    
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
    
//    public func findPricePoints(_ days: TimeInterval, priceOption: PricePointOptions, findOption: FindOptions) -> [PriceDate] {
//        // extract prices and their tradingDates for all 30 day intervals
//        // starting from most recent, so date decending
//
//        var pricePoints = [PriceDate]()
//        var endDate = dailyPrices.last!.tradingDate
//        let lastDate = dailyPrices.first!.tradingDate
//
//        while endDate >= lastDate {
//            let startDate = endDate.addingTimeInterval(-days*24*3600)
//
//            var dailyPriceInRange = dailyPrices.filter( { (element) -> Bool in
//                if element.tradingDate < startDate { return false }
//                if element.tradingDate > endDate { return false }
//                return true
//            })
//
//            dailyPriceInRange.sort { (p0, p1) -> Bool in
//
//                if (p0.returnPrice(option: priceOption)) < (p1.returnPrice(option: priceOption)) { return true }
//                else { return false }
//            }
//
//            var newPriceDate: PriceDate!
//
//            if findOption == .minimum {
//                newPriceDate = (dailyPriceInRange.first!.tradingDate, dailyPriceInRange.first!.returnPrice(option: priceOption))
//
//            }
//            else {
//                newPriceDate = (dailyPriceInRange.last!.tradingDate, dailyPriceInRange.last!.returnPrice(option: priceOption))
//            }
//
//            pricePoints.append(newPriceDate)
//            endDate = endDate.addingTimeInterval(-days*24*3600)
//        }
//        return pricePoints
//    }
    
//    public func findPrice(lowOrHigh: FindOptions, priceOption: PricePointOptions ,_ from: Date? = nil,_ to: Date? = nil) -> PriceDate? {
//        
//        var pricesInRange: [PricePoint]!
//        
//        if let validFrom = from {
//            pricesInRange = dailyPrices.filter({ (element) -> Bool in
//                if element.tradingDate < validFrom {
//                    return false
//                }
//                if element.tradingDate > to! {
//                    return false
//                }
//                
//                return true
//            })
//        }
//        else {
//            pricesInRange = dailyPrices
//        }
//        
//        var maxPriceDate = PriceDate(date: Date(), price: 0)
//        var minPriceDate = PriceDate(date: Date(), price: 10000000)
//        
//        for pricePoint in pricesInRange {
//            let price = pricePoint.returnPrice(option: priceOption)
//            if price > maxPriceDate.price {
//                maxPriceDate.price = price
//                maxPriceDate.date = pricePoint.tradingDate
//            }
//            if price < minPriceDate.price {
//                minPriceDate.price = price
//                minPriceDate.date = pricePoint.tradingDate
//            }
//            
//        }
////        let pricesInQuestion = pricesInRange.compactMap { $0.returnPrice(option: priceOption), $0.tradingDate }
//
//        if lowOrHigh == .minimum { return minPriceDate}
//        else { return maxPriceDate }
//        
//    }
    
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
}

