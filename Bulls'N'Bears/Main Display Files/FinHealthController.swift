//
//  FinHealthController.swift
//  Bulls'N'Bears
//
//  Created by aDav on 13/10/2022.
//

import UIKit
import CoreData

class FinHealthController: NSObject {
    
    var share: Share!
    var finHealthTVC: FinHealthTVC!
    let mainMOC = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var downloadTask: Task<Any?, Error>?
    var backgroundMoc: NSManagedObjectContext?
    var earliestChartDate: Date!
    
    // values not stored
    var netProfitMargins = [ChartDataSet]()
    var operatingMargins = [ChartDataSet]()
    var quickRatios = [ChartDataSet]()
    var currentRatios = [ChartDataSet]()
    var debEquityRatios = [ChartDataSet]()
    var currentHealthScore: Double?
    
    // progressView
//    var progressView: DownloadProgressView?
//    var allDownloadTasks = 0
//    var completedDownloadTasks = 0

    init(share: Share!, finHealthTVC: FinHealthTVC) {
        super.init()
        
        self.share = share
        self.finHealthTVC = finHealthTVC
        
        earliestChartDate = DatesManager.beginningOfYear(of: Date().addingTimeInterval(-year))
        
        let shortName = share.name_short!
        let symbol = share.symbol!
//        let r1ValuationID = share.rule1Valuation?.objectID
        let dcfValuationID = share.dcfValuation?.objectID
        backgroundMoc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc!.automaticallyMergesChangesFromParent = true

        NotificationCenter.default.addObserver(self, selector: #selector(DownloadRedirectionDelegate.awaitingRedirection(notification:)), name: Notification.Name(rawValue: "Redirection"), object: nil)

        let bgShare = share

        downloadTask = Task.init(priority: .background, operation: {
            do {
                await getR1Data(shortName: shortName, symbol: symbol, shareID: bgShare?.objectID, bgMOC: backgroundMoc!)
                try Task.checkCancellation()
                await getDCFData(shortName: shortName, symbol: symbol, dcfvID: dcfValuationID, bgMOC: backgroundMoc!)
                try Task.checkCancellation()
                
                try await profitabilityData(share: self.share) // not saved/ stored
                try await efficiencyData(share: self.share) // not saved/ stored
                try await liquidityData(share: self.share) // not saved/ stored
                try await solvencyData(share: self.share)  // not saved/ stored
                
                currentHealthScore = healthScore()
                if let healthScoreCurrent = currentHealthScore {
                    let datedValue = DatedValue(date: Date(), value: healthScoreCurrent)
                    bgShare?.saveTrendsData(datedValuesToAdd: [datedValue], trendName: .healthScore)
                }
                
            } catch let error {
                ErrorController.addInternalError(errorLocation: "FinHealthController.init", systemError: error, errorInfo: "can't download Health data for \(symbol)")
            }

            DispatchQueue.main.async {
                self.finHealthTVC.stopActivityView()
                self.finHealthTVC.tableView.reloadData()
                NotificationCenter.default.removeObserver(self)
            }
            return nil
        })
        
    }
    
    public func dataForPath(indexPath: IndexPath) -> LabelledChartDataSet {
        
        var chartData = [ChartDataSet]()
        let labelledChartData = LabelledChartDataSet(title:"Empty", chartData: chartData, format: .numberWithDecimals)

        if indexPath.section == 1 {
            if indexPath.row == 0 {
                // MOAT
                for moatData in share?.trendValues(trendName: .moatScore) ?? [] {
                    let data = ChartDataSet(x: moatData.date, y: moatData.value)
                    chartData.append(data)
                }
                return LabelledChartDataSet(title: "Moat", chartData: chartData, format: .percent)
                
            } else if indexPath.row == 1 {
                for spData in share?.trendValues(trendName: .stickerPrice) ?? [] {
                    let data = ChartDataSet(x: spData.date, y: spData.value)
                    chartData.append(data)
                }
                return LabelledChartDataSet(title: "Sticker", chartData: chartData, format: .currency)
                
            } else if indexPath.row == 2 {
                for spData in share?.trendValues(trendName: .dCFValue) ?? [] {
                    let data = ChartDataSet(x: spData.date, y: spData.value)
                    chartData.append(data)
                }
                return LabelledChartDataSet(title: "DCF", chartData: chartData, format: .currency)
                
            } else if indexPath.row == 3 {
                for spData in share?.trendValues(trendName: .intrinsicValue) ?? [] {
                    let data = ChartDataSet(x: spData.date, y: spData.value)
                    chartData.append(data)
                }
                return LabelledChartDataSet(title: "Intrinsic", chartData: chartData, format: .currency)
                
            }
            else if indexPath.row == 4 {
                for spData in share?.trendValues(trendName: .lynchScore) ?? [] {
                    let data = ChartDataSet(x: spData.date, y: spData.value)
                    chartData.append(data)
                }
                return LabelledChartDataSet(title: "Lynch", chartData: chartData, format: .numberWithDecimals)
            }
        }
        else if indexPath.section == 2 {
            // Profitability - net profit margin
            return LabelledChartDataSet(title: "Net Profit Margin", chartData: netProfitMargins, format: .percent)

        } else if indexPath.section == 3 {
            // Efficiency - operating margin
           return LabelledChartDataSet(title: "Operating Margin", chartData: operatingMargins, format: .percent)

        } else if indexPath.section == 4 {
            // Liquidity - operating margin
            if indexPath.row == 0 {
                return LabelledChartDataSet(title: "Quick ratio", chartData: quickRatios, format: .numberWithDecimals)
            } else if indexPath.row == 1 {
                return LabelledChartDataSet(title: "Current ratio", chartData: currentRatios, format: .numberWithDecimals)
            }

        } else if indexPath.section == 5 {
            // Solvency - debt equity ratio
            return LabelledChartDataSet(title: "Debt/equity ratio", chartData: debEquityRatios, format: .numberWithDecimals)
        } else {
            return LabelledChartDataSet(title: "Empty", chartData: chartData, format: .percent)
        }
        
        return labelledChartData

    }
    
    func getR1Data(shortName: String, symbol: String, shareID: NSManagedObjectID?, bgMOC: NSManagedObjectContext) async {
        
        if (share.rule1Valuation?.creationDate ?? Date()).timeIntervalSince(Date()) > 24*3600 {
            // refresh rule 1 valuation
            // save new r1 moat and sticker price as trend
            
            if let shareID = shareID {
                
                // save existing values if necessary
                guard let bgShare = bgMOC.object(with: shareID) as? Share else {
                    ErrorController.addInternalError(errorLocation: #function, errorInfo: "objectID error: can't load background share by objectID sent")
                    return
                }
                if let r1v = bgShare.rule1Valuation {
                    if let moat = r1v.moatScore() {
                        let trendValue = DatedValue(date: r1v.creationDate!, value: moat)
                        share.saveTrendsData(datedValuesToAdd: [trendValue], trendName: .moatScore)
                    }
                    let (value2, _) = r1v.stickerPrice()
                    if value2 != nil {
                        let trendValue = DatedValue(date: r1v.creationDate!, value: value2!)
                        share.saveTrendsData(datedValuesToAdd: [trendValue], trendName: .stickerPrice)
                    }
                    
                    do {
                        let _ = try await WebPageScraper2.r1DataDownloadAndSave(shareSymbol: symbol, shortName: shortName, shareID: shareID, progressDelegate: nil, downloadRedirectDelegate: self)
                    } catch let error {
                        ErrorController.addInternalError(errorLocation: "FinHealthController.getR1Data", systemError: error, errorInfo: "Error downloading R1 valuation: \(error)")
                    }
                }
            }
        }

    }
    
    func getDCFData(shortName: String, symbol: String, dcfvID: NSManagedObjectID?, bgMOC: NSManagedObjectContext) async {
        
        if (share.dcfValuation?.creationDate ?? Date()).timeIntervalSince(Date()) > 24*3600 {
            // refresh dcf valuation
            // save new dcfvalue as trend
            
            if let dcfValuationID = dcfvID {
                let dcfv = bgMOC.object(with: dcfValuationID) as! DCFValuation
                let (value,_) = dcfv.returnIValue()
                if value != nil {
                    let trendValue = DatedValue(date: dcfv.creationDate!, value: value!)
                    share.saveTrendsData(datedValuesToAdd: [trendValue], trendName: .dCFValue)
                }

                do {
                    try await WebPageScraper2.dcfDataDownloadAndSave(shareSymbol: symbol, valuationID: dcfValuationID, progressDelegate: nil)
                } catch let error {
                    ErrorController.addInternalError(errorLocation: "StocksController2.updateStockInformation.dcfValuation", systemError: error, errorInfo: "Error downloading DCF valuation: \(error)")
                }
            }
        }

    }
    
    func profitabilityData(share: Share) async throws {
        
        var sn = share.name_short ?? ""
        if sn.contains(" ") {
            sn = sn.replacingOccurrences(of: " ", with: "-").lowercased()
        }
        
        guard let components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(share.symbol!)/\(sn)/net-profit-margin") else {
            ErrorController.addInternalError(errorLocation: "FinHealthController.profitabilityData", systemError: nil, errorInfo: "url components error for \(share.symbol!)")
            return
        }
        
        guard let url = components.url else {
            ErrorController.addInternalError(errorLocation: "FinHealthController.profitabilityData", systemError: nil, errorInfo: "url error for \(share.symbol!)")
            return
        }
        
        var values: [DatedValue]?
        
        do {
            values = try await WebPageScraper2.getqColumnTableData(url: url, companyName: sn, tableHeader: "Net Profit Margin Historical Data", dateColumn: 0 , valueColumn: 3, until: earliestChartDate)
            
            for value in values ?? [] {
                if !(value.date < earliestChartDate) {
                    netProfitMargins.append(ChartDataSet(x: value.date, y: value.value))
                }
            }
            
        }  catch let error as InternalErrorType {
            ErrorController.addInternalError(errorLocation: "FinHealthController.profitabilityData", systemError: nil, errorInfo: "a background download or analysis error for \(share.symbol!) occurred: \(error)")
        }
        
    }
    
    func efficiencyData(share: Share) async throws {
        
        var sn = share.name_short ?? ""
        if sn.contains(" ") {
            sn = sn.replacingOccurrences(of: " ", with: "-").lowercased()
        }
        
        guard let components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(share.symbol!)/\(sn)/operating-margin") else {
            ErrorController.addInternalError(errorLocation: "FinHealthController.efficiencyData", systemError: nil, errorInfo: "url components error for \(share.symbol!)")
            return
        }
        
        guard let url = components.url else {
            ErrorController.addInternalError(errorLocation: "FinHealthController.efficiencyData", systemError: nil, errorInfo: "url error for \(share.symbol!)")
            return
        }
        
        var values: [DatedValue]?
        
        do {
            values = try await WebPageScraper2.getqColumnTableData(url: url, companyName: sn, tableHeader: "Operating Margin Historical Data", dateColumn: 0 , valueColumn: 3, until: earliestChartDate)
            
            for value in values ?? [] {
                if !(value.date < earliestChartDate) {
                    operatingMargins.append(ChartDataSet(x: value.date, y: value.value))
                }
            }
        }  catch let error as InternalErrorType {
            ErrorController.addInternalError(errorLocation: "FinHealthController.efficiencyData", systemError: nil, errorInfo: "a background download or analysis error for \(share.symbol!) occurred: \(error)")
        }
        
    }
    
    func liquidityData(share: Share) async throws {
        
        do {
            try await quickRatios(share: share)
            try await currentRatios(share: share)
        } catch let error {
            throw error
        }
    }
    
    func quickRatios(share: Share) async throws  {
        
        var sn = share.name_short ?? ""
        if sn.contains(" ") {
            sn = sn.replacingOccurrences(of: " ", with: "-").lowercased()
        }
        
        guard let components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(share.symbol!)/\(sn)/quick-ratio") else {
            throw InternalErrorType.urlError
        }

        guard let url = components.url else {
            throw InternalErrorType.urlError
        }
        
        var values1: [DatedValue]?
        do {
            values1 = try await WebPageScraper2.getqColumnTableData(url: url, companyName: sn, tableHeader: "Quick Ratio Historical Data", dateColumn: 0 , valueColumn: 3, until: earliestChartDate)
            
            for value in values1 ?? [] {
                if !(value.date < earliestChartDate) {
                    quickRatios.append(ChartDataSet(x: value.date, y: value.value))
                }
            }
        }  catch let error as InternalErrorType {
            throw error
        }

 
    }

    func currentRatios(share: Share) async throws  {
        
        var sn = share.name_short ?? ""
        if sn.contains(" ") {
            sn = sn.replacingOccurrences(of: " ", with: "-").lowercased()
        }
        
        guard let components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(share.symbol!)/\(sn)/current-ratio") else {
            throw InternalErrorType.urlError
        }

        guard let url = components.url else {
            throw InternalErrorType.urlError
        }
        
        var values: [DatedValue]?
        do {
            values = try await WebPageScraper2.getqColumnTableData(url: url, companyName: sn, tableHeader: "Current Ratio Historical Data", dateColumn: 0 , valueColumn: 3, until: earliestChartDate)
            
            for value in values ?? [] {
                if !(value.date < earliestChartDate) {
                    currentRatios.append(ChartDataSet(x: value.date, y: value.value))
                }
            }
        }  catch let error as InternalErrorType {
            throw error
        }

 
    }

    func solvencyData(share: Share) async throws  {
        
        var sn = share.name_short ?? ""
        if sn.contains(" ") {
            sn = sn.replacingOccurrences(of: " ", with: "-").lowercased()
        }
        
        guard let components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(share.symbol!)/\(sn)/debt-equity-ratio") else {
            throw InternalErrorType.urlError
        }

        guard let url = components.url else {
            throw InternalErrorType.urlError
        }
        
        var values: [DatedValue]?
        do {
            values = try await WebPageScraper2.getqColumnTableData(url: url, companyName: sn, tableHeader: "Debt/Equity Ratio Historical Data", dateColumn: 0 , valueColumn: 3, until: earliestChartDate)
            
            for value in values ?? [] {
                if !(value.date < earliestChartDate) {
                    debEquityRatios.append(ChartDataSet(x: value.date, y: value.value))
                }
            }
        }  catch let error as InternalErrorType {
            throw error
        }
    }
    
    func healthScore() -> Double? {
                
        let keyFinTypes: [ShareTrendNames] = [.moatScore, .stickerPrice, .lynchScore, .dCFValue, .intrinsicValue]
        var keyFinScores = [Double?]()
        
        for i in 0..<keyFinTypes.count {
            if let keyFinTrend = share.trendChartData(trendName: keyFinTypes[i]) {
                // chartData are returned date ASCENDING
                
                if keyFinTypes[i] == .moatScore {
                    keyFinScores.append(keyFinTrend.last!.y!)
                    if let trendRatio = firstValueRatioToMax(datedValues: keyFinTrend) {
                        if trendRatio < 0.9 {
                            keyFinScores[i]! *= trendRatio
                        }
                    }
                }
                else if [.stickerPrice, .intrinsicValue, .dCFValue].contains(keyFinTypes[i]) {
                    if keyFinTrend.count > 1 {
                        if let trendRatio = firstValueRatioToMax(datedValues: keyFinTrend) {
                            if trendRatio < 0.9 {
                                keyFinScores.append(trendRatio)
                            } else {
                                keyFinScores.append(1.0)
                            }
                        }
                        else {
                            keyFinScores.append(nil)
                        }
                    } else {
                        keyFinScores.append(nil)
                    }

                    let debug = keyFinScores.count > i ? keyFinScores[i] : nil
                }
                else if keyFinTypes[i] == .lynchScore {
                    
                    if keyFinTrend.last!.y! < 1 {
                        keyFinScores.append(0)
                    } else if keyFinTrend.last!.y! < 2 {
                        keyFinScores.append(keyFinTrend.last!.y!-1)
                    } else {
                        keyFinScores.append(1.0)
                    }
                    
                    if let trendRatio = firstValueRatioToMax(datedValues: keyFinTrend) {
                        if trendRatio < 0.9 {
                            keyFinScores[i]! *= trendRatio
                        }
                    }

                }
            }
        }
        
        // PROFITABILITY
        var profitabilityScore: Double?
        if let netMarginsTrendratio = firstValueRatioToMax(datedValues: netProfitMargins) {
           
            profitabilityScore = 1.0
            if netMarginsTrendratio < 0.9 {
                profitabilityScore! *= netMarginsTrendratio
            }
            
            if netProfitMargins.first!.y! < 0 {
                profitabilityScore = 0
            }

        }
        
        // EFFICIENCY
        var efficiencyScore: Double?
        if let opMarginsTrendratio = firstValueRatioToMax(datedValues: operatingMargins) {
            efficiencyScore = 1.0
            if opMarginsTrendratio < 0.9 {
                efficiencyScore! *= opMarginsTrendratio
            }
            
            if operatingMargins.first!.y! < 0 {
                efficiencyScore = 0
            }

        }
        
        // LIQUIDITY
        let liquidityRatios = [quickRatios, currentRatios]
        let weighting = [0.6, 0.4]
        var liquidityScore: Double?
        
        for i in 0..<liquidityRatios.count {
            
            if let liquidityTrendratio = firstValueRatioToMax(datedValues: liquidityRatios[i]) {
                if liquidityScore == nil {
                    liquidityScore = 0.0
                }
                
                var baseScore: Double = weighting[i]
                // qr and cr = higher is better
                // below 1.0 is concern
                
                // dropping trend is a concern
                if liquidityTrendratio < 0.9 {
                    baseScore *= liquidityTrendratio
                }
                
                if liquidityRatios[i].first!.y! < 1.0 {
                    baseScore *= liquidityRatios[i].first!.y!
                }
                
                liquidityScore! += baseScore
            }
        }
        
        // SOLVENCY
        var solvencyScore: Double?
        if let solvencyRatio = firstValueRatioToMax(datedValues: debEquityRatios, useMax: false) {
            // > 1 is not ideal
            solvencyScore = 1.0
            // trend increase is concern
            if debEquityRatios.first!.y! > 1.0 {
                solvencyScore! /= debEquityRatios.first!.y!
            } else if debEquityRatios.first!.y! < 0 {
                solvencyScore = 0
            }

            if solvencyRatio > 1.2 {
                solvencyScore! /= solvencyRatio
            }
        }

        var allScores = [liquidityScore, profitabilityScore, efficiencyScore, solvencyScore]
        allScores.append(contentsOf: keyFinScores)
        let sum = allScores.compactMap{ $0 }.reduce(0, +)
        let count = allScores.compactMap{ $0 }.count
        
        if count > 0 {
            return sum / Double(count)
        }
        
        return nil
    }
    
    func returnHealthScore$() -> String {
        
        if let valid = currentHealthScore {
            return percentFormatter0Digits.string(from: valid as NSNumber) ?? " - "
        } else {
            return " - "
        }
    }
    
    /// send datedValues in date DESCENDING order which is default after extraction from MacroTrends; useMax compares latest(first) to HIGHEST value, if FALSE compares to LOWEST value
    func firstValueRatioToMax(datedValues: [ChartDataSet], useMax:Bool?=true) -> Double? {
        
        if let max = useMax! ? datedValues.compactMap({ $0.y }).max() : datedValues.compactMap({ $0.y }).min() {
            let latest = datedValues.first!.y!
            let ratioLatestToMax = latest / max
            return ratioLatestToMax
        }
        
        return nil
    }

    
}

extension FinHealthController: DownloadRedirectionDelegate {
    
    func awaitingRedirection(notification: Notification) {
        
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? {
           
        let object = request
        let notification = Notification(name: Notification.Name(rawValue: "Redirection"), object: object, userInfo: nil)
        NotificationCenter.default.post(notification)

        return nil
    }

    
}

//extension FinHealthController: ProgressViewDelegate {
//
//    var completedTasks: Int {
//        get {
//            completedDownloadTasks
//        }
//        set (newValue) {
//            completedDownloadTasks = newValue
//        }
//    }
//
//
//    func taskCompleted() {
//        completedTasks += 1
//        if allDownloadTasks < completedTasks {
//            completedTasks = allDownloadTasks
//        }
//
//        self.progressUpdate(allTasks: allDownloadTasks, completedTasks: completedTasks)
//    }
//
//    var allTasks: Int {
//        get {
//            return allDownloadTasks
//        }
//        set (newValue) {
//            allDownloadTasks = newValue
//        }
//    }
//
//    func progressUpdate(allTasks: Int, completedTasks: Int) {
//        DispatchQueue.main.async {
//            self.progressView?.updateProgress(tasks: allTasks, completed: completedTasks)
//        }
//    }
//
//    func cancelRequested() {
//        self.downloadTask?.cancel()
//    }
//
//    func downloadComplete() {
//        DispatchQueue.main.async {
////            self.finHealthTVC.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
//            self.finHealthTVC.tableView.reloadData()
//        }
//    }
//
//    func downloadError(error: String) {
//        print("download error in FHC \(error)")
//    }
//
//
//}
