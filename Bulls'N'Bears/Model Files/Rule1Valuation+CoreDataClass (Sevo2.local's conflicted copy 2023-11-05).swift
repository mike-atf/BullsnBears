//
//  Rule1Valuation+CoreDataClass.swift
//  TrendMyStocks
//
//  Created by aDav on 02/01/2021.
//
//

import UIKit
import CoreData

//enum R1ValuationParameters {
//    case bvps
//    case eps
//    case revenue
//    case opcs
//    case debt
//    case insiderStockBuys
//    case insiderStockSells
//    case insiderStocks
//    case opCashFlow
//    case netIncome
//    case roic
//    case hxPE
//
//}

@objc(Rule1Valuation)
public class Rule1Valuation: NSManagedObject {
    
    static func create(in managedObjectContext: NSManagedObjectContext) {
        let newValuation = self.init(context: managedObjectContext)
        newValuation.creationDate = Date()

        do {
            try  managedObjectContext.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    override public func awakeFromInsert() {
        
        bvps = [Double]()
        eps = [Double]()
        revenue = [Double]()
        opcs = [Double]()
        roic = [Double]()
        debt = Double()
        hxPE = [Double]()
        growthEstimates = [Double]()
        insiderStockBuys = Double()
        insiderStockSells = Double()
        company = String()
        creationDate = Date()
        insiderStocks = Double()
        ceoRating = Double()
        adjGrowthEstimates = [Double]()
        opCashFlow = Double()
        netIncome = Double()
        adjFuturePE = Double()
                    
        if let valuation = share?.wbValuation  {
            
            if (valuation.bvps ?? [Double]()).reduce(0, +) != 0 {
                self.bvps = valuation.bvps
            }
            
            if (valuation.revenue ?? [Double]()).reduce(0, +) != 0 {
                self.revenue = valuation.revenue
            }
            
            if (valuation.eps ?? [Double]()).reduce(0, +) != 0 {
                self.eps = valuation.eps
            }
            
            if (valuation.netEarnings?.first ?? 0) != 0 {
                self.netIncome = valuation.netEarnings!.first!
            }
            
            if (valuation.opCashFlow ?? [Double]()).reduce(0, +) != 0 {
                self.opCashFlow = valuation.opCashFlow!.first!
            }
        }
        
        if let valuation = share?.dcfValuation {
            
            if (valuation.netIncome ?? [Double]()).reduce(0, +) != 0 {
                self.netIncome = valuation.netIncome!.first!
            }

        }

        
    }

    
    func save() {
        
        do {
            try managedObjectContext?.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error in SiteDetails.save function \(nserror), \(nserror.userInfo)")
        }

    }

    func delete() {
       
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.delete(self)
 
        do {
            try (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    public func ageOfValuation() -> TimeInterval? {
        
        if let date = creationDate {
            return Date().timeIntervalSince(date)
        }
        
        return nil
    }
    
    func historicalYearsCompleted() -> Int {
        var years = [0]
        years.append(eps?.count ?? 0)
        years.append(roic?.count ?? 0)
        years.append(bvps?.count ?? 0)
        years.append(opcs?.count ?? 0)
        years.append(revenue?.count ?? 0)

        return years.min() ?? 0
    }
    
//    func shortNumberText(parameter: R1ValuationParameters) -> [String] {
//
//        var shortNumberStrings = [String]()
//        var values:[Double]?
//        var formatter = currencyFormatterNoGapWithPence
//
//        switch parameter {
//        case .bvps:
//            values = bvps
//        case .debt:
//            values = [debt]
//        case .eps:
//            values = eps
//        case .netIncome:
//            values = [netIncome]
//        case .insiderStockBuys:
//            values = [insiderStockBuys]
//            formatter = numberFormatter2Decimals
//        case .insiderStockSells:
//            values = [insiderStockSells]
//            formatter = numberFormatter2Decimals
//        case .opCashFlow:
//            values = [opCashFlow]
//        case .opcs:
//            values = opcs
//        case .revenue:
//            values = revenue
//        case .insiderStocks:
//            values = [insiderStocks]
//            formatter = numberFormatter2Decimals
//        case .roic:
//            values = roic
//            formatter = numberFormatter2Decimals
//        case .hxPE:
//            values = hxPE
//            formatter = numberFormatter2Decimals
//        }
//
//        for element in values ?? [] {
//            var value$ = "-"
//            if element/1000000000 > 1 {
//                let shortValue = element/1000000000
//                let value$ = (formatter.string(from: shortValue  as NSNumber) ?? "-") + "B"
//            } else if element/1000000 > 1 {
//                let shortValue = element/1000000
//                let value$ = (formatter.string(from: shortValue  as NSNumber) ?? "-") + "M"
//            }
//            else if element/1000 > 1 {
//                let shortValue = element/1000
//                let value$ = (formatter.string(from: shortValue  as NSNumber) ?? "-") + "K"
//            } else {
//                value$ = (formatter.string(from: element  as NSNumber) ?? "-") + "K"
//            }
//            shortNumberStrings.append(value$)
//        }
//
//        return shortNumberStrings
//    }
    
    func debtProportion() -> Double? {
        
        if netIncome != Double() {
            if netIncome > 0 {
                if debt != Double() {
                    return debt / netIncome
                }
            }
        }
            
        return nil
    }
    
    func insiderSalesProportion() -> Double? {
        
        if insiderStocks != Double() {
            if insiderStockSells != Double() {
                return (insiderStockSells) / insiderStocks
            }
        }
        return nil
    }
    
    func r1MoatParameterCount() -> Int? {
        
        
        
        let arrays = [bvps, eps, revenue, opcs, roic]
        var countNonZero = 0
        for array in arrays {
            countNonZero += array?.compactMap{ $0 }.filter({ (value) -> Bool in
                if value != 0 { return true }
                else { return false }
            }).count ?? 0
        }
        
        return countNonZero
    }

    
    /// 0-1
    func moatScore() -> ([String]?, Double?) {
        
        let bvps = share?.ratios?.bvps.datedValues(dateOrder: .descending).dropZeros() ?? [DatedValue]()
        let Alleps = share?.income_statement?.eps_annual.datedValues(dateOrder: .descending).dropZeros() ?? [DatedValue]()
        let revenue = share?.income_statement?.revenue.datedValues(dateOrder: .descending).dropZeros() ?? [DatedValue]()
        let opcs = share?.ratios?.ocfPerShare.datedValues(dateOrder: .descending).dropZeros() ?? [DatedValue]()
        let roi = share?.ratios?.roi.datedValues(dateOrder: .descending).dropZeros() ?? [DatedValue]()
        
        var errors: [String]?
        var eps = Alleps
        if Alleps.count > 10 {
            eps = [DatedValue]()
            for i in 0..<10 {
                eps.append(Alleps[i])
            }
        }
        
        let moatArrays = [bvps, eps, revenue, opcs]
        var moatGrowthRates = [[Double]]()
        self.share?.moatCategory = "NA"

        var sumValidRates = 0
        for i in 0..<moatArrays.count {
                        
            if let returnRates = Calculator.ratesOfGrowth(datedValues: moatArrays[i]) {
                moatGrowthRates.append(returnRates)
                sumValidRates += returnRates.count
            }
            else {
                moatGrowthRates.append([Double]())
            }
            
        }
        
        sumValidRates += roi.count
        
        guard sumValidRates > 0 else {
            return ( ["None of the Big five moat parameters are available"], nil)
        }
        
        if sumValidRates < 30 {
            errors = ["Only \(sumValidRates)/50 Big Five moat parameters available. Moat score not very reliable"]
        }
        
        var ratesHigher10 = 0
        for growthRateArray in moatGrowthRates {
            ratesHigher10 += growthRateArray.filter({ (rate) -> Bool in
                if rate < 0.1 { return false }
                else { return true }
            }).count
        }
        
        ratesHigher10 += roi.filter({ (dv) -> Bool in
            if dv.value < 0.1 { return false }
            else { return true }
        }).count
        
        let moat = Double(ratesHigher10) / Double(sumValidRates)
        
        self.share?.moat = moat
        let categories = ["Good (>75%)","Intermediate (50-75%)","Low (<50%)"]
        var category = String()
        if moat > 0.75 {
            category = categories[0]
        } else if moat > 0.49 {
            category = categories[1]
        } else {
            category = categories[2]
        }
        
        self.share?.moatCategory = category
        
        return (errors, moat)
    }
    
    /// needs BVPS in date DESCENDING order
    func futureGrowthEstimate(cleanedBVPS: [Double]) -> Double? {
        
        guard let endValue = cleanedBVPS.first else { return nil }
        
        var bvpsGrowthRates = [Double]()
        for yearsBack in 1..<(cleanedBVPS.count) {
            bvpsGrowthRates.append(Calculator.compoundGrowthRate(endValue: endValue, startValue: cleanedBVPS[yearsBack], years: Double(yearsBack)) ?? Double())
        }
        let lowBVPSGrowth = bvpsGrowthRates.mean()
        
        var analystPredictedGrowth:Double?
        if adjGrowthEstimates?.mean() ?? 0.0 != 0 {
            analystPredictedGrowth = adjGrowthEstimates?.mean()
        } else if growthEstimates?.mean() ?? 0.0 != 0 {
            analystPredictedGrowth = growthEstimates?.mean()
        }
        return analystPredictedGrowth != nil ? analystPredictedGrowth! : lowBVPSGrowth
    }
    
    /// needs EPS in date DESCENDING order
    func futureEPS(futureGrowth: Double, cleanedEPS: [Double]) -> Double? {
 
        guard let currentEPS = cleanedEPS.first else { return nil }
        return Calculator.futureValue(present: currentEPS, growth: futureGrowth, years: 10.0)
    }
    
    func futurePER(futureGrowth: Double) -> Double? {
        
        var averageHxPER: Double?
        
        var hxPE: [Double]?
        if let ratios = share?.ratios {
            hxPE = ratios.pe_ratios.valuesOnly(dateOrdered: Order.descending)
        }
        
        var adjFuturePE: Double?
        if let analysis = share?.analysis {
            adjFuturePE = analysis.meanFuturePE()
        }
    
        if (hxPE?.count ?? 0) > 0 {
            averageHxPER = hxPE!.mean()
        }
        
        if (adjFuturePE ?? 0) != 0.0 { return adjFuturePE }
        else {
            return averageHxPER != nil ? [(futureGrowth*2*100),averageHxPER!].min()! : (futureGrowth*2*100)
        }
    }
    
    func stickerPrice() -> (Double?, [String]?) {
        
        let bvps = share?.ratios?.bvps.valuesOnly(dateOrdered: .descending)?.filter({ d in
            if d != 0.0 { return true }
            else { return false }
        })
        let eps = share?.income_statement?.eps_annual.valuesOnly(dateOrdered: .descending)?.filter({ d in
            if d != 0.0 { return true }
            else { return false }
        })
//        let revenue = share?.income_statement?.revenue.valuesOnly(dateOrdered: .descending)?.filter({ d in
//            if d != 0.0 { return true }
//            else { return false }
//        })
//        let opcs = share?.ratios?.ocfPerShare.valuesOnly(dateOrdered: .descending)?.filter({ d in
//            if d != 0.0 { return true }
//            else { return false }
//        })
        

        guard bvps != nil && eps != nil else {
            return (nil, ["missing BVPS +/- EPS."])
        }
        
        var errors = [String]()
        
//        let dataArrays = [bvps!, eps!]
//        let (cleanedArrays,error) = ValuationDataCleaner.cleanValuationData(dataArrays: dataArrays, method: .rule1)
//
//        if let validError = error {
//            errors = [validError]
//        }
        let cleanedBVPS = bvps!
        let cleanedEPS = eps!

        guard cleanedBVPS.count > 1 else {
            errors.append("no book value per share figure available.")
            return (nil, errors)
        }
        
        guard let futureGrowth = futureGrowthEstimate(cleanedBVPS: cleanedBVPS) else {
            errors.append("can't calculate future growth from book values per share.")
            return (nil, errors)
        }
         
        guard let epsIn10Years = futureEPS(futureGrowth: futureGrowth, cleanedEPS: cleanedEPS) else {
            errors.append("can't calculate future eps from earnings per share.")
            return (nil, errors)
        }
        
        if let acceptedFuturePER = share?.analysis?.meanFuturePE() {
            let futureStockPrice = epsIn10Years * acceptedFuturePER
            let stickerPrice = Calculator.presentValue(growth: 0.15, years: 10, endValue: futureStockPrice)
            return (stickerPrice, errors)
        } else {
            
            guard let futurePER = futurePER(futureGrowth: futureGrowth) else {
                errors.append("can't calculate future P/E ratio")
                return (nil, errors)
            }
            
            let acceptedFuturePER = futurePER
            let futureStockPrice = epsIn10Years * acceptedFuturePER
            // 15% is the Rule 1 minimum acceptable annual rate of returna
            let stickerPrice = Calculator.presentValue(growth: 0.15, years: 10, endValue: futureStockPrice)
            
            let returnErrors = errors.count == 0 ? nil : errors
            
            return (stickerPrice, returnErrors)
        }
    }
    
    class func downloadAnalyseAndSave(shareSymbol: String?, shortName: String, shareID: NSManagedObjectID, progressDelegate: ProgressViewDelegate?=nil, downloadRedirectDelegate: DownloadRedirectionDelegate) async throws {
        
        guard let symbol = shareSymbol else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "Rule 1 data download requetw without share symbol")
            return
        }
        
        await MacrotrendsScraper.dataDownloadAnalyseSave(shareSymbol: symbol, shortName: shortName, shareID: shareID, downloadOption: .rule1Only, downloadRedirectDelegate: downloadRedirectDelegate)
        
        await YahooPageScraper.dataDownloadAnalyseSave(symbol: symbol, shortName: shortName, shareID: shareID, option: .rule1Only, downloadRedirectDelegate: downloadRedirectDelegate)
        
        /*
        guard let symbol = shareSymbol else {
            progressDelegate?.downloadError(error: InternalErrorType.shareSymbolMissing.localizedDescription)
            return
        }
        
        guard let shortName = shortName else {
            progressDelegate?.downloadError(error: InternalErrorType.shareShortNameMissing.localizedDescription)
            return
        }
        
        var results = [Labelled_DatedValues]()
        
        if symbol.contains(".") {
            // non-US Stocks
            do {
                
                try await nonMTRule1DataDownload(symbol: symbol, shortName: shortName, shareID: shareID, progressDelegate: progressDelegate)

            } catch {
                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "error trying to download Rule1 data from Yahoo")
            }
        }
        else {
            // US-Stocks
            let pageNamesMT = ["financial-statements", "financial-ratios", "balance-sheet", "cash-flow-statement"]
            let perOnMT = ["pe-ratio"]
            let pageNamesYahoo = ["analysis", "cash-flow","insider-transactions"]
            let mtRowTitles = [["Revenue","EPS - Earnings Per Share","Net Income"],["ROI - Return On Investment","Book Value Per Share","Operating Cash Flow Per Share"],["Long Term Debt"],["Cash Flow From Operating Activities", "Net Change In Property, Plant, And Equipment"]]
        
            progressDelegate?.allTasks = mtRowTitles.compactMap{ $0 }.count + pageNamesYahoo.count + perOnMT.count
            
            
            // 1 Download and analyse web page data first MT then Yahoo
            // MacroTrends downloads for Rule1 Data
//            do {
            if let mtR1Data = await MacrotrendsScraper.rule1DownloadAndAnalyse(symbol: symbol, shortName: shortName, pageNames: pageNamesMT, rowTitles: mtRowTitles, progressDelegate: progressDelegate ,downloadRedirectDelegate: downloadRedirectDelegate) {
                
                results.append(contentsOf: mtR1Data)
            }
//            } catch {
//                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "error trying to download Rule1 data from MacroTrends")
//            }
            
            // 2 Yahoo downloads for Rule1 Data
//            do {
            if let yahooR1Data = await YahooPageScraper.rule1DownloadAndAnalyse(symbol: symbol, shareID: shareID, progressDelegate: progressDelegate, avoidMTTitles: true,  downloadRedirectDelegate: downloadRedirectDelegate) {

                results.append(contentsOf: yahooR1Data)
            }
//            } catch {
//                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "error trying to download Rule1 data from Yahoo")
//            }
        }
        
        
        let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc.automaticallyMergesChangesFromParent = true
        
        do {
            if let bgShare = backgroundMoc.object(with: shareID) as? Share {
                try await bgShare.mergeInDownloadedData(labelledDatedValues: results)
            }
        } catch {
            ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "couldn't save background MOC")
        }
        */
//        print()
//        print("MT and Yahoo Rule 1 Data")
//        for result in results {
//            print(result)
//        }
        

// 3 Save R1 data to background R1Valuation
        /*
        do {
            try await MacrotrendsScraper.saveR1Data(shareID: shareID, labelledDatedValues: results)
        } catch {
            progressDelegate?.downloadError(error: error.localizedDescription)
            throw error
        }
        */
    }

    /// called  by StocksController.updateStocks for non-US stocks when trying to download from MacroTrends
    class func nonMTRule1DataDownload(symbol: String?, shortName: String?, shareID: NSManagedObjectID ,progressDelegate: ProgressViewDelegate?=nil) async throws {
        
        guard let valid = symbol else {
            ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "missing stock symbol")
            progressDelegate?.cancelRequested()
            return
        }
        
        guard let validSN = shortName else {
            ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "missing stock short name")
            progressDelegate?.cancelRequested()
            return
        }

        let webString = valid.replacingOccurrences(of: " ", with: "+")
        let webStringComps = webString.split(separator: ".")
        var tagesschauURL: URL?
        if let symbolNoDots = webStringComps.first {
            tagesschauURL = URL(string: "https://www.tagesschau.de/wirtschaft/boersenkurse/suche/?suchbegriff=\(symbolNoDots)")
        }
        
        let snComponents = validSN.split(separator: " ")
        var arivaComponents = String(snComponents.first!)
        if snComponents.count > 1 {
            if snComponents[1] == "SE" {
                arivaComponents += " " + String(snComponents[1])
            }
        }
        let arivaString = arivaComponents.replacingOccurrences(of: " ", with: "_") + "-aktie"
        let arivaURL = URL(string: "https://www.ariva.de/\(arivaString)/bilanz-guv")
        let tsURL = tagesschauURL
        progressDelegate?.allTasks = 5
        
        // TODO: - download from 3 sites, but an error thrown at each will stop execution so the others don't download
        Task.init {
            do {
                // download from ariva and move on after async let...
                var r1LabelledValues = [Labelled_DatedValues]()

                async let arivaHTML = Downloader.downloadDataNoThrow(url: arivaURL!)
                
                progressDelegate?.taskCompleted()
                
//                async let yahooLVS = YahooPageScraper.rule1DownloadAndAnalyse(symbol: symbol!, shareID: shareID, downloadRedirectDelegate: nil)?.sortAllElementDatedValues(dateOrder: .ascending)
                
                await YahooPageScraper.dataDownloadAnalyseSave(symbol: valid, shortName: validSN, shareID: shareID, option: .rule1Only, downloadRedirectDelegate: nil)
                
                progressDelegate?.taskCompleted()

                // find full url for company on tagesschau search page
                if let html = await Downloader().downloadDataWithRedirectionOption(url: tsURL) {
                    var tagesschauShareURLs = try TagesschauScraper.shareAddressLineTagesschau(htmlText: html)
                    if tagesschauShareURLs?.count ?? 0 > 1 {
                        tagesschauShareURLs = tagesschauShareURLs?.filter({ address in
                            if address.contains("aktie") { return true }
                            else { return false }
                        })
                    }

                    if let firstAddress = tagesschauShareURLs?.first {
                        if let url = URL(string: firstAddress) {

                            // 2 download tagesschau data webpage from full url
                            if let infoPage = await Downloader.downloadDataNoThrow(url: url) {
                                if infoPage != "" {
                                    if let ldvs = try? TagesschauScraper.rule1DownloadAndAnalyse(htmlText: infoPage, symbol: symbol, progressDelegate: progressDelegate) {
                                        r1LabelledValues.append(contentsOf: ldvs.sortAllElementDatedValues(dateOrder: .ascending))
                                    }
                                }
                            }
                        }
                    }
                }
                progressDelegate?.taskCompleted()

                // ...continue analysing arivaHTML here
                if let arivaLDVs = await WebPageScraper2.arivaPageAnalysis(html: arivaHTML ?? "", headers: ["Bewertung"], parameters: [["KGV (Kurs/Gewinn)","Return on Investment in %"]]) {
                    
                    r1LabelledValues.append(contentsOf: arivaLDVs.sortAllElementDatedValues(dateOrder: .ascending))
                }
                progressDelegate?.taskCompleted()

                /*
                if let lvs = await yahooLVS {
                    
                    // TODO: - merge TS and Yahoo Revenue figures
//                    print()
//                    print("Yahoo R1 Values:")
//                    for ldv in lvs {
//                        print()
//                        print(ldv)
//                    }
                    
                    // merge TS/ ARriva and Yahoo results
                    // all [Datedvalues] should be in date ASCENDING order here
                    
                    // Parameters available in Yahoo and TS/ Ariva:
                    for parameter in  ["Revenue","EPS - Earnings Per Share", "Net Income","Long Term Debt", "Common stock","Operating cash flow"]{
                        
                        if var tsParameter = r1LabelledValues.filter({ lvalues in
                            if lvalues.label == parameter { return true }
                            else { return false }
                        }).first {
                            
                            if let yahooRevenue = lvs.filter({ lvalues in
                                if lvalues.label == parameter { return true }
                                else { return false }
                            }).first {
                                // insert the TTM value
                                if let ttm = yahooRevenue.datedValues.last {
                                    if ttm.value != 0.0 {
                                        tsParameter.datedValues.insert(ttm, at: 0)
                                    }
                                }
                            }
                        }
                        else {
                            // no TS parameter available
                            if let yahooParameter = lvs.filter({ lvalues in
                                if lvalues.label == parameter { return true }
                                else { return false }
                            }).first {
                                
                                r1LabelledValues.append(yahooParameter)
                                
                            }
                        }
                    }
                }
                */
                
                for i in 0..<r1LabelledValues.count {
                    if let latest = r1LabelledValues[i].datedValues.first {
                        if latest.value == 0.0 {
                            r1LabelledValues[i].datedValues = Array(r1LabelledValues[i].datedValues.dropFirst())
                        }
                    }
                }

//                try await MacrotrendsScraper.saveR1Data(shareID: shareID, labelledDatedValues: r1LabelledValues)
//                progressDelegate?.taskCompleted()

                progressDelegate?.downloadComplete()
                
                let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
                backgroundMoc.automaticallyMergesChangesFromParent = true
                
                if let bgShare = backgroundMoc.object(with: shareID) as? Share {
                    try await bgShare.mergeInDownloadedData(labelledDatedValues: r1LabelledValues)
                }
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: "DownloadEnded"), object: nil, userInfo: nil)

            } catch {
                progressDelegate?.downloadError(error: error.localizedDescription)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "DownloadEnded"), object: nil, userInfo: nil)
                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "error downloading 'Tageschau' Aktien info page")
            }
        }
    }

    func addMoatTrend(date: Date, moat: Double) {
        
        var existingTrendDv = moatScoreTrend.datedValues(dateOrder: .ascending)
        
        if let latest = existingTrendDv?.last?.date {
            if date.timeIntervalSince(latest) > (365/12 * 24 * 3600) {
                existingTrendDv?.append((DatedValue(date: date, value: moat)))
                moatScoreTrend = existingTrendDv?.convertToData()
            }
        }
        else {
            moatScoreTrend = [DatedValue(date: date, value: moat)].convertToData()
        }

    }
    
    func addStickerPriceTrend(date: Date, price: Double) {
        
        var existingTrendDv = stickerPriceTrend.datedValues(dateOrder: .ascending)
        
        if let latest = existingTrendDv?.last?.date {
            if date.timeIntervalSince(latest) > (365/12 * 24 * 3600) {
                existingTrendDv?.append((DatedValue(date: date, value: price)))
                stickerPriceTrend = existingTrendDv?.convertToData()
            }
        }
        else {
            stickerPriceTrend = [DatedValue(date: date, value: price)].convertToData()
        }

    }

}
