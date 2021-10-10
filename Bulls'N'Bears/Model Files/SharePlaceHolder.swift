//
//  SharePlaceHolder.swift
//  Bulls'N'Bears
//
//  Created by aDav on 22/04/2021.
//

import Foundation

class SharePlaceHolder: NSObject {
    // required for catching download data on background threads
    // this would create concurrency problems if using the NSManagedObject Share from the AppDel viewContext which can only be accessed on the main thread
    
    var macd: Data?
    var divYieldCurrent: Double = 0.0
    var watchStatus = Int16() // 0 watchList, 1 owned, 2 archived
    var valueScore = Double()
    var userEvaluationScore = Double()
    var beta = Double()
    var peRatio = Double()
    var eps = Double()
    var creationDate: Date?
    var purchaseStory: String?
    var transactions: NSSet?
    var growthType: String?
    var growthSubType: String?
    var industry: String?
    var sector: String?
    var employees = Double()
    var symbol = "missing"
    var name_short: String?
    var name_long: String?
    var dailyPrices: Data?
    var lastLivePrice: Double = 0.0
    var lastLivePriceDate: Date?
    var priceUpdateComplete = false
    var share: Share?

    override init() {
        super.init()
        
    }
    
    convenience init(share: Share?) {
        self.init()
        
        self.share = share
        self.macd = share?.macd
        self.divYieldCurrent = share?.divYieldCurrent ?? Double()
        self.watchStatus = share?.watchStatus ?? Int16() // 0 watchList, 1 owned, 2 archived
        self.valueScore = share?.valueScore ?? Double()
        self.userEvaluationScore = share?.userEvaluationScore ?? Double()
        self.beta = share?.beta ?? Double()
        self.peRatio = share?.peRatio ?? Double()
        self.eps = share?.eps ?? Double()
        self.creationDate = share?.creationDate
        self.purchaseStory = share?.purchaseStory
        self.growthType = share?.growthType
        self.growthSubType = share?.growthSubType
        self.industry = share?.industry
        self.sector = share?.sector
        self.employees = share?.employees ?? Double()
        self.symbol = share?.symbol ?? "missing"
        self.name_short = share?.name_short
        self.name_long = share?.name_long
        self.dailyPrices = share?.dailyPrices
        self.lastLivePrice = share?.lastLivePrice ?? Double()
        self.lastLivePriceDate = share?.lastLivePriceDate
        self.transactions = share?.transactions
    }
    
    /// does NOT save the NSManagedObject Share to it's context
    /// does NOT transfer valuation and research parameters
    public func shareFromPlaceholder(share: Share?) {
        
        share?.macd = self.macd
        share?.divYieldCurrent = self.divYieldCurrent
        share?.watchStatus = self.watchStatus// 0 watchList, 1 owned, 2 archived
        share?.valueScore = self.valueScore
        share?.userEvaluationScore = self.userEvaluationScore
        share?.beta = self.beta
        share?.peRatio = self.peRatio
        share?.eps = self.eps
        share?.creationDate = self.creationDate
        share?.purchaseStory = self.purchaseStory
        share?.growthType = self.growthType
        share?.growthSubType = self.growthSubType
        share?.industry = self.industry
        share?.sector = self.sector
        share?.employees = self.employees
        share?.symbol = self.symbol
        share?.name_short = self.name_short
        share?.name_long = self.name_long
        share?.dailyPrices = self.dailyPrices
        share?.lastLivePrice = self.lastLivePrice
        share?.lastLivePriceDate = self.lastLivePriceDate
        share?.transactions = self.transactions

    }
    
    //MARK: - daily prices functions
    public func getDailyPrices() -> [PricePoint]? {

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
    
    func setDailyPrices(pricePoints: [PricePoint]?) {

        guard let validPoints = pricePoints else { return }

        self.dailyPrices = convertDailyPricesToData(dailyPrices: validPoints)
        shareFromPlaceholder(share: share)
        DispatchQueue.main.async {
            self.share?.save()
        }
        
    }
    
    /// takes new prices and adds any newer ones than already saved to the exsitng list (rather than replce the existing list)
    func updateDailyPrices(newPrices: [PricePoint]?) {
        
//        print("updating daily prices for \(name_short ?? "missing name")")
        guard let validNewPoints = newPrices else { return }

        if let existingPricePoints = getDailyPrices() {
            
            var pricePointsSet = Set<PricePoint>(existingPricePoints)

//            var newList = existingPricePoints
//            var existingMACDs = getMACDs()
            
            for point in validNewPoints {
                pricePointsSet.insert(point)
            }
            
            let pricePointsSortedArray = Array(pricePointsSet).sorted { e0, e1 in
                if e0.tradingDate < e1.tradingDate { return true }
                else { return false }
            }
        
//        self.macd = convertMACDToData(macds: existingMACDs)
        let _ = calculateMACDs(shortPeriod: 8, longPeriod: 17)
        setDailyPrices(pricePoints: pricePointsSortedArray)

                
//                let pointsToAdd = validNewPoints.filter { element in
//                    if pricePointsSet.contains(element) { return false }
//                    else { return true }
//                }
////                print("found \(pointsToAdd.count) new daily prices to add to plot")
//                if pointsToAdd.count > 0 {
//                    for point in pointsToAdd {
//                        newList.append(point)
//                        let lastMACD = existingMACDs?.last
//                        existingMACDs?.append(MAC_D(currentPrice: point.close, lastMACD: lastMACD, date: point.tradingDate))
//                    }
//                    newList.sort { e0, e1 in
//                        if e0.tradingDate < e1.tradingDate { return true }
//                        else { return false }
//                    }
//                    self.macd = convertMACDToData(macds: existingMACDs)
//                    setDailyPrices(pricePoints: newList)
//                }
        }
    }

    public func convertDailyPricesToData(dailyPrices: [PricePoint]?) -> Data? {
        
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
    
    //MARK: - MCD functions
    
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
    
    /// also converts to data stored as 'macd' property of share
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
        
        return mac_ds
    }
    
    /// returns array[0] = fast oascillator K%
    /// arrays[1] = slow oscillator D%
    func calculateSlowStochOscillators() -> [StochasticOscillator]? {
        
        guard let dailyPrices = getDailyPrices() else { return nil }
        
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
        
        return slowOsc
    }


    //MARK: - price update
    
    func startLivePriceUpdate(delegate: StockDelegate) {
        
        var components: URLComponents?
                
        components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)")
        components?.queryItems = [URLQueryItem(name: "p", value: symbol), URLQueryItem(name: ".tsrc", value: "fin-srch")]
        
        guard let validURL = components?.url else {
            return
        }
        
        let yahooSession = URLSession(configuration: .default)
        var dataTask: URLSessionDataTask?
        
        // this will start a background thread
        // do not access the main viewContext or NSManagedObjects fetched from it!
        // the StocksController sending this via startPriceUpdate uses a seperate backgroundMOC and shares fetched from this to execute this tasks
        
        dataTask = yahooSession.dataTask(with: validURL) { (data, urlResponse, error) in
            
            guard error == nil else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error!, errorInfo: "stock live price download error")
                return
            }
            
            guard urlResponse != nil else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "stock live price download error \(urlResponse.debugDescription)")
                return
            }
            
            guard let validData = data else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "stock live price download error - empty website data")
                return
            }

            let html$ = String(decoding: validData, as: UTF8.self)
            self.livePriceDownloadComplete(html$: html$, delegate: delegate)
        }
        dataTask?.resume()

    }
    
    
    func startDailyPriceUpdate(yahooRefDate: Date, delegate: StockDelegate) {
        
        let nowSinceRefDate = yahooPricesEndDate.timeIntervalSince(yahooRefDate)
        let yearAgoSinceRefDate = yahooPricesStartDate.timeIntervalSince(yahooRefDate)

        let end$ = numberFormatter.string(from: nowSinceRefDate as NSNumber) ?? ""
        let start$ = numberFormatter.string(from: yearAgoSinceRefDate as NSNumber) ?? ""
        
        var urlComponents = URLComponents(string: "https://query1.finance.yahoo.com/v7/finance/download/\(symbol)")
        urlComponents?.queryItems = [URLQueryItem(name: "period1", value: start$),URLQueryItem(name: "period2", value: end$),URLQueryItem(name: "interval", value: "1d"), URLQueryItem(name: "events", value: "history"), URLQueryItem(name: "includeAdjustedClose", value: "true") ]
        
        var webPath = "https://query1.finance.yahoo.com/v7/finance/download/"
        webPath += symbol+"?"
        webPath += "period1=" + start$
        webPath += "&period2=" + end$
        webPath += "&interval=1d&events=history&includeAdjustedClose=true"
        
        if let sourceURL = urlComponents?.url {
            downLoadWebFile(sourceURL, delegate: delegate)
        }
    }

    func downLoadWebFile(_ url: URL, delegate: StockDelegate) {
        
        // this will start a background thread
        // do not access the main viewContext or NSManagedObjects fetched from it!
        // the StocksController sending this via startPriceUpdate uses a seperate backgroundMOC and shares fetched from this to execute this tasks
        
        // NEW Data download
        var urlComponents = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)/history?")
        urlComponents?.queryItems = [URLQueryItem(name: "p", value: symbol)]
        if let sourceURL = urlComponents?.url {
            downloadWebData(sourceURL, stockName: symbol, task: "priceHistory", delegate: delegate)
            return
        }
        else {
            return
        }

        
        // OLD - file download
        /*
         let configuration = URLSessionConfiguration.default
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpShouldSetCookies = true
        let session = URLSession(configuration: configuration)
        var downloadTask: URLSessionDownloadTask? // URLSessionDataTask stores downloaded data in memory, DownloadTask as File

        downloadTask = session.downloadTask(with: url) { [self]
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
                    removeFile(tempURL)
                    print("invalid cookie error for \(tempURL)")
                    print()
                    // invalid cookie error - try alternative method
                    var urlComponents = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)/history?")
                    urlComponents?.queryItems = [URLQueryItem(name: "p", value: symbol)]
                    if let sourceURL = urlComponents?.url {
                        downloadWebData(sourceURL, stockName: symbol, task: "priceHistory", delegate: delegate)
                        return
                    }
                    else {
                        return
                    }
                }

                if FileManager.default.fileExists(atPath: targetURL.path) {
                    removeFile(targetURL)
                }

                try FileManager.default.moveItem(at: tempURL, to: targetURL)
                
                if let updatedPrices = CSVImporter.extractPriceData(url: targetURL, symbol: symbol) {
                    priceUpdateComplete = true
                    updateDailyPrices(newPrices: updatedPrices) // this saves the downloaded data to the backgroundMOC used
                    removeFile(targetURL)
                    downloadKeyRatios(delegate: delegate)
                }
            } catch {
                DispatchQueue.main.async {
                    ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "can't move and save downloaded file")
                }
            }
        }
        downloadTask?.resume()
         */
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
    
    func downloadWebData(_ url: URL, stockName: String, task: String, delegate: StockDelegate?) {
        
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpShouldSetCookies = true
        let session = URLSession(configuration: configuration)
        var downloadTask: URLSessionDataTask? // URLSessionDataTask stores downloaded data in memory, DownloadTask as File

        downloadTask = session.dataTask(with: url) { [self]
            data, urlResponse, error in
            
            guard error == nil else {
                print("web data download for \(url) failed with error \(error!.localizedDescription)")
                return
            }
            
            guard urlResponse != nil else {
                print("web data download for \(url) failed due to urlReponse == nil")
                return
            }
            
            guard let validData = data else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "stock keyratio download error - empty website data")
                return
            }

            let html$ = String(decoding: validData, as: UTF8.self)
            if task == "priceHistory" {
                let pricePoints = WebpageScraper.yahooPriceTable(html$: html$)
                
                DispatchQueue.main.async {
                    priceUpdateComplete = true
                    updateDailyPrices(newPrices: pricePoints)
                    downloadKeyRatios(delegate: delegate)
                }
            }
        }
        downloadTask?.resume()
    }


    // MARK: - keyRatios update
    
    func downloadKeyRatios(delegate: StockDelegate?) {
        
        var components: URLComponents?
                
        components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)/key-statistics")
        components?.queryItems = [URLQueryItem(name: "p", value: symbol), URLQueryItem(name: ".tsrc", value: "fin-srch")]
            
        
        guard let validURL = components?.url else {
            return
        }
        
        let yahooSession = URLSession(configuration: .default)
        var dataTask: URLSessionDataTask?
        
        // this will start a background thread
        // do not access the main viewContext or NSManagedObjects fetched from it!
        // the StocksController sending this via startPriceUpdate uses a seperate backgroundMOC and shares fetched from this to execute this tasks
        dataTask = yahooSession.dataTask(with: validURL) { (data, urlResponse, error) in
            
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
        dataTask?.resume()
    }
    
    func keyratioDownloadComplete(html$: String, delegate: StockDelegate?) {
        
        let rowTitles = ["Beta (5Y monthly)", "Trailing P/E", "Diluted EPS", "Forward annual dividend yield"] // titles differ from the ones displayed on webpage!
        var loaderrors = [String]()
        
        for title in rowTitles {
            
            let pageText = html$
            
            let (values, errors) = WebpageScraper.scrapeRowForDoubles(website: .yahoo, html$: pageText, rowTitle: title+"</span>" , rowTerminal: "</tr>", numberTerminal: "</td>")
            loaderrors.append(contentsOf: errors)
            
            if title.starts(with: "Beta") {
                if let valid = values?.first {
                    DispatchQueue.main.async {
                        self.beta = valid
                    }
                }
            } else if title.starts(with: "Trailing") {
                if let valid = values?.first {
                    DispatchQueue.main.async {
                        self.peRatio = valid
                    }
                }
            } else if title.starts(with: "Diluted") {
                if let valid = values?.first {
                    DispatchQueue.main.async {
                        self.eps = valid
                    }
                }
            } else if title == "Forward annual dividend yield" {
                if let valid = values?.first {
                    DispatchQueue.main.async {
                        self.divYieldCurrent = valid
                    }
                }
            }
        }
        
        //exit tthe background thread to enable transferring the sharePlaceHolder object
        //to an NSManagedObject 'Share' to be saved in the main viewContext. This MUST happen on the main thread
        DispatchQueue.main.async {
            delegate?.keyratioDownloadComplete(share: self, errors: loaderrors)
        }
    }
    
    func livePriceDownloadComplete(html$: String, delegate: StockDelegate?) {
        
        let (values, errors) = WebpageScraper.scrapeRowForDoubles(website: .yahoo, html$: html$, rowTitle: "<span class=\"Trsdu(0.3s) Trsdu(0.3s) " , rowTerminal: "</span>", numberTerminal: "</span>")
        
        if let livePrice = values?.first {
            self.lastLivePrice = livePrice
            self.lastLivePriceDate = Date()
            DispatchQueue.main.async {
                delegate?.livePriceDownloadCompleted(share: self, errors: errors)
            }
        }
        else {
            DispatchQueue.main.async {
                delegate?.livePriceDownloadCompleted(share: nil, errors: errors)
            }
        }
        
    }
    
    //MARK: - profile download functions
    
    func downloadProfile(delegate: StockDelegate?) {
        
        var components: URLComponents?
                
        components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)/pfile")
        components?.queryItems = [URLQueryItem(name: "p", value: symbol)]
            
        
        guard let validURL = components?.url else {
            return
        }
        
        let yahooSession = URLSession(configuration: .default)
        var dataTask: URLSessionDataTask?
        
        dataTask = yahooSession.dataTask(with: validURL) { (data, urlResponse, error) in

            guard error == nil else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error!, errorInfo: "stock profile download error")
                return
            }
            
            guard urlResponse != nil else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "stock profile download error \(urlResponse.debugDescription)")
                return
            }
            
            guard let validData = data else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "stock profile download error - empty website data")
                return
            }

            let html$ = String(decoding: validData, as: UTF8.self)
            self.profileDownloadComplete(html$: html$, delegate: delegate)
        }
        dataTask?.resume()
    }
    
    func profileDownloadComplete(html$: String, delegate: StockDelegate?) {
        
        let rowTitles = ["\"sector\":", "\"industry\":", "\"fullTimeEmployees\""] // titles differ from the ones displayed on webpage!
        var loaderrors = [String]()
        
        for title in rowTitles {
            
            let pageText = html$
            
            
            if title.starts(with: "\"sector") {
                let (strings, errors) = WebpageScraper.scrapeRowForText(website: .yahoo, html$: pageText, rowTitle: title , rowTerminal: ",", textTerminal: "\"")
                loaderrors.append(contentsOf: errors)

                if let valid = strings?.first {
                        self.sector = valid
                }
            } else if title.starts(with: "\"industry") {
                let (strings, errors) = WebpageScraper.scrapeRowForText(website: .yahoo, html$: pageText, rowTitle: title , rowTerminal: ",", textTerminal: "\"")
                loaderrors.append(contentsOf: errors)
                
                if let valid = strings?.first {
                        self.industry = valid
                }
            } else if title.starts(with: "\"fullTimeEmployees") {
                let (values, errors) = WebpageScraper.scrapeYahooRowForDoubles(html$: pageText, rowTitle: title , rowTerminal: "\"", numberTerminal: ",")
                loaderrors.append(contentsOf: errors)
                
                if let valid = values?.first {
                        self.employees = valid
                }
            }
        }
        

        DispatchQueue.main.async {

            if loaderrors.count > 0 {
                for error in loaderrors {
                    ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: error)

                }
            }
            delegate?.keyratioDownloadComplete(share: self, errors: loaderrors)
        }
            
    }


}
