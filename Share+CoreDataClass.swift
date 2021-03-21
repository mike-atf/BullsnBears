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
    
    public override func awakeFromInsert() {
        eps = Double()
        peRatio = Double()
        beta = Double()
//        watchStatus = 0 // 0 watchList, 1 owned, 2 archived
    }
    
    public override func awakeFromFetch() {
        priceUpdateComplete = false
        
        let _ = calculateMACDs(shortPeriod: 8, longPeriod: 17)
//        print()
//        print("\(symbol!), \(macd)")
//        if macd == nil {
//            if dailyPrices != nil {
//                let _ = calculateMACDs(shortPeriod: 8, longPeriod: 17)
//                print("\(symbol!) macds updated")
//            }
//            save()
//        }
//        print("\(symbol!), \(macd)")

    }
    
//    func setValues(symbol: String, dailyPrices: [PricePoint]?, fileURL: URL?, deleteFile: Bool?=false) {
//
//        self.symbol = symbol
//        self.dailyPrices = convertDailyPricesToData(dailyPrices: dailyPrices)
//        self.fileURL = fileURL
//
//        if (deleteFile ?? false) {
//            if let url = fileURL {
//                removeFile(url)
//            }
//        }
//    }
        
//    func extractPriceFromData(url: URL) -> [PricePoint]? {
//
//        guard let validSymbol = symbol else {
//            return nil
//        }
//
//        if let extractedPrices = CSVImporter.extractPriceData(url: fileURL, symbol: validSymbol) {
//            return extractedPrices
//        }
//
//        return nil
//    }

    func save() {
              
        DispatchQueue.main.async {
           do {
                try  (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error in WBValuation.save function \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func setDailyPrices(pricePoints: [PricePoint]?) {

        guard let validPoints = pricePoints else { return }

        self.dailyPrices = convertDailyPricesToData(dailyPrices: validPoints)
        save()
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
    func updateDailyPrices(newPrices: [PricePoint]?) {
        
        guard let validNewPoints = newPrices else { return }
        
        if let existingPricePoints = getDailyPrices() {
            var newList = existingPricePoints
            var existingMACDs = getMACDs()
            if let lastExistingDate = existingPricePoints.last?.tradingDate {
                let pointsToAdd = validNewPoints.filter { (element) -> Bool in
                    if element.tradingDate > lastExistingDate { return true }
                    else { return false }
                }
                if pointsToAdd.count > 0 {
                    for point in pointsToAdd {
                        newList.append(point)
                        let lastMACD = existingMACDs?.last
                        existingMACDs?.append(MAC_D(currentPrice: point.close, lastMACD: lastMACD, date: point.tradingDate))
                    }
                    self.macd = convertMACDToData(macds: existingMACDs) // doesn't save
                    setDailyPrices(pricePoints: newList) // saves
                }
            }
        }
    }
    
    func getDailyPrices() -> [PricePoint]? {

        guard let valid = dailyPrices else { return nil }
        
        do {
            if let data = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(valid) as? Data {

                let array = try PropertyListDecoder().decode([PricePoint].self, from: data)
                return array.sorted { (e0, e1) -> Bool in
                    if e0.tradingDate < e1.tradingDate { return true }
                    else { return false }
                }
            }
        } catch let error {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error retrieving stored share price data")
        }
        
        return nil
    }
    
    func getMACDs() -> [MAC_D]? {

        if let valid = macd {
        
            do {
                if let data = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(valid) as? Data {

                    let array = try PropertyListDecoder().decode([MAC_D].self, from: data)
                    return array.sorted { (e0, e1) -> Bool in
                        if e0.date ?? Date() < e1.date ?? Date() { return true }
                        else { return false }
                    }
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

    // MARK: - download / update functions
    
    func startPriceUpdate(yahooRefDate: Date, delegate: StockDelegate) {
        
        let nowSinceRefDate = Date().timeIntervalSince(yahooRefDate)
        let start = nowSinceRefDate - TimeInterval(3600 * 24 * 366)
        
        let end$ = numberFormatter.string(from: nowSinceRefDate as NSNumber) ?? ""
        let start$ = numberFormatter.string(from: start as NSNumber) ?? ""
        
        var urlComponents = URLComponents(string: "https://query1.finance.yahoo.com/v7/finance/download/\(symbol!)")
        urlComponents?.queryItems = [URLQueryItem(name: "period1", value: start$),URLQueryItem(name: "period2", value: end$),URLQueryItem(name: "interval", value: "1d"), URLQueryItem(name: "events", value: "history"), URLQueryItem(name: "includeAdjustedClose", value: "true") ]
        
        var webPath = "https://query1.finance.yahoo.com/v7/finance/download/"
        webPath += symbol!+"?"
        webPath += "period1=" + start$
        webPath += "&period2=" + end$
        webPath += "&interval=1d&events=history&includeAdjustedClose=true"
        
        if let sourceURL = urlComponents?.url {
            downLoadWebFile(sourceURL, delegate: delegate)
        }
    }
    
    func downLoadWebFile(_ url: URL, delegate: StockDelegate) {
        
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
                
                let tempURL = documentsURL.appendingPathComponent(symbol! + "-temp.csv")
                let targetURL = documentsURL.appendingPathComponent(symbol! + ".csv")
                
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
                
                if let updatedPrices = CSVImporter.extractPriceData(url: targetURL, symbol: symbol!) {
                    priceUpdateComplete = true
                    updateDailyPrices(newPrices: updatedPrices)
                    delegate.priceUpdateComplete(symbol: symbol!)
                    removeFile(targetURL)
                }
                
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
    
    // MARk: - technicals
    
    /// also converts to data stored as 'macd' propoerty of share
    func calculateMACDs(shortPeriod: Int, longPeriod: Int) -> [MAC_D]? {
        
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
        
        self.macd = convertMACDToData(macds: mac_ds)
        save()
        
        return mac_ds
    }
    
    /// returns array[0] = fast oascillator K%
    /// arrays[1] = slow oscillator D%
    func calculateSlowStochOscillators() -> [StochasticOscillator]? {
        
        guard let dailyPrices = getDailyPrices() else { return nil }
        
        var last14 = dailyPrices[..<14].compactMap{ $0.close }
        let after14 = dailyPrices[13...]
        
        var last2K = [Double]()
        var lowest14 = last14.min()
        var highest14 = last14.max()
        var slowOsc = [StochasticOscillator]()
        
        for pricePoint in after14 {
            last14.append(pricePoint.close)
            last14.removeFirst()
            
            lowest14 = last14.min()
            highest14 = last14.max()
            
            let newOsc = StochasticOscillator(currentPrice: pricePoint.close, date: pricePoint.tradingDate, lowest14: lowest14, highest14: highest14, slow2: last2K)
            slowOsc.append(newOsc)
            
            if let valid = newOsc.k_fast {
                last2K.append(valid)
                if last2K.count > 2 {
                    last2K.removeFirst()
                }
            }
        }
        
        return slowOsc
    }
        
    // MARK: - keyRatios uopdate
    
    func downloadKeyRatios(delegate: StockKeyratioDownloadDelegate?) {
        
        var components: URLComponents?
                
        components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol!)/key-statistics")
        components?.queryItems = [URLQueryItem(name: "p", value: symbol!), URLQueryItem(name: ".tsrc", value: "fin-srch")]
            
        
        guard let validURL = components?.url else {
            return
        }
        
        let yahooSession = URLSession.shared.dataTask(with: validURL) { (data, urlResponse, error) in
            
            guard error == nil else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error!, errorInfo: "stock keyratio download error")
                return
            }
            
            guard urlResponse != nil else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "stock keyratio download error \(urlResponse.debugDescription)")
                return
            }
            
            guard let validData = data else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "stock keyratio download error - empty website data")
                return
            }

            let html$ = String(decoding: validData, as: UTF8.self)
            self.keyratioDownloadComplete(html$: html$, delegate: delegate)
        }
        yahooSession.resume()
    }
    
    func keyratioDownloadComplete(html$: String, delegate: StockKeyratioDownloadDelegate?) {
        
        let rowTitles = ["Beta (5Y monthly)", "Trailing P/E", "Diluted EPS", "Forward annual dividend yield"] // titles differ from the ones displayed on webpage!
        var loaderrors = [String]()
        
        for title in rowTitles {
            
            let pageText = html$
            
            let (values, errors) = WebpageScraper.scrapeRow(website: .yahoo, html$: pageText, rowTitle: title , rowTerminal: "</tr>", numberTerminal: "</td>")
            loaderrors.append(contentsOf: errors)
            
            if title.starts(with: "Beta") {
                if let valid = values?.first {
                    beta = valid
                }
            } else if title.starts(with: "Trailing") {
                if let valid = values?.first {
                    peRatio = valid
                }
            } else if title.starts(with: "Diluted") {
                if let valid = values?.first {
                    eps = valid
                }
            } else if title == "Forward annual dividend yield" {
                if let valid = values?.first {
                    divYieldCurrent = valid
                }
            }
        }
        
        DispatchQueue.main.async {
            self.save()
        }
       
        
        delegate?.keyratioDownloadComplete(errors: loaderrors)
    }
}
