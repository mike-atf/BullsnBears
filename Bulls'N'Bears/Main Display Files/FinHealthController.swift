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


    init(share: Share!, finHealthTVC: FinHealthTVC) {
        super.init()
        
        self.share = share
        self.finHealthTVC = finHealthTVC
        
        earliestChartDate = DatesManager.beginningOfYear(of: Date())
        
        let shortName = share.name_short!
        let symbol = share.symbol!
        let r1ValuationID = share.rule1Valuation?.objectID
        let dcfValuationID = share.dcfValuation?.objectID
        backgroundMoc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc!.automaticallyMergesChangesFromParent = true

        NotificationCenter.default.addObserver(self, selector: #selector(DownloadRedirectionDelegate.awaitingRedirection(notification:)), name: Notification.Name(rawValue: "Redirection"), object: nil)

        downloadTask = Task.init(priority: .background, operation: {
            do {
                await getR1Data(shortName: shortName, symbol: symbol, r1vID: r1ValuationID, bgMOC: backgroundMoc!)
                try Task.checkCancellation()
                await getDCFData(shortName: shortName, symbol: symbol, dcfvID: dcfValuationID, bgMOC: backgroundMoc!)
                try Task.checkCancellation()
                
                try await profitabilityData(share: self.share) // not saved/ stored
                try await efficiencyData(share: self.share) // not saved/ stored
                try await liquidityData(share: self.share) // not saved/ stored
                try await solvencyData(share: self.share)  // not saved/ stored
            } catch let error {
                ErrorController.addErrorLog(errorLocation: "FinHealthController.init", systemError: error, errorInfo: "can't download Health data for \(symbol)")
            }

            DispatchQueue.main.async {
                self.finHealthTVC.tableView.reloadRows(at: [IndexPath(row: 0, section: 1), IndexPath(row: 0, section: 2),IndexPath(row: 0, section: 3), IndexPath(row: 1, section: 3)], with: .automatic)
                NotificationCenter.default.removeObserver(self)
            }
            return nil
        })
        
    }
    
    public func dataForPath(indexPath: IndexPath) -> LabelledChartDataSet {
        
        var chartData = [ChartDataSet]()
        let labelledChartData = LabelledChartDataSet(title:"Empty", chartData: chartData, format: .numberWithDecimals)

        if indexPath.section == 0 {
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
        else if indexPath.section == 1 {
            // Profitability - net profit margin
            return LabelledChartDataSet(title: "Net Profit Margin", chartData: netProfitMargins, format: .percent)

        } else if indexPath.section == 2 {
            // Efficiency - operating margin
           return LabelledChartDataSet(title: "Operating Margin", chartData: operatingMargins, format: .percent)

        } else if indexPath.section == 3 {
            // Liquidity - operating margin
            if indexPath.row == 0 {
                return LabelledChartDataSet(title: "Quick ratio", chartData: quickRatios, format: .numberWithDecimals)
            } else if indexPath.row == 1 {
                return LabelledChartDataSet(title: "Current ratio", chartData: currentRatios, format: .numberWithDecimals)
            }

        } else if indexPath.section == 4 {
            // Solvency - debt equity ratio
            return LabelledChartDataSet(title: "Debt/equity ratio", chartData: debEquityRatios, format: .numberWithDecimals)
        } else {
            return LabelledChartDataSet(title: "Empty", chartData: chartData, format: .percent)
        }
        
        return labelledChartData

    }
    
    func getR1Data(shortName: String, symbol: String, r1vID: NSManagedObjectID?, bgMOC: NSManagedObjectContext) async {
        
        if (share.rule1Valuation?.creationDate ?? Date()).timeIntervalSince(Date()) > 24*3600 {
            // refresh rule 1 valuation
            // save new r1 moat and sticker price as trend
            
            if let r1ValuationID = r1vID {
                
                // save existing values if necessary
                let r1v = bgMOC.object(with: r1ValuationID) as! Rule1Valuation
                if let moat = r1v.moatScore() {
                    let trendValue = DatedValue(date: r1v.creationDate!, value: moat)
                    share.saveTrendsData(datedValuesToAdd: [trendValue], trendName: .moatScore)
                }
                let (value2, _) = r1v.stickerPrice()
                if value2 != nil {
                    let trendValue = DatedValue(date: r1v.creationDate!, value: value2!)
                    share.saveTrendsData(datedValuesToAdd: [trendValue], trendName: .stickerPrice)
                }
                
//                downloadTask = Task(priority: .background) {
                    
                    do {
                        let _ = try await WebPageScraper2.r1DataDownloadAndSave(shareSymbol: symbol, shortName: shortName, valuationID: r1ValuationID, progressDelegate: self, downloadRedirectDelegate: self)
//                        try Task.checkCancellation()
                    } catch let error {
                        ErrorController.addErrorLog(errorLocation: "FinHealthController.getR1Data", systemError: error, errorInfo: "Error downloading R1 valuation: \(error)")
                    }
                    
//                    return nil
//                }
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
                    try await WebPageScraper2.dcfDataDownloadAndSave(shareSymbol: symbol, valuationID: dcfValuationID, progressDelegate: self)
                    //                        try Task.checkCancellation()
                } catch let error {
                    ErrorController.addErrorLog(errorLocation: "StocksController2.updateStockInformation.dcfValuation", systemError: error, errorInfo: "Error downloading DCF valuation: \(error)")
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
            ErrorController.addErrorLog(errorLocation: "FinHealthController.profitabilityData", systemError: nil, errorInfo: "url components error for \(share.symbol!)")
            return
        }
        
        guard let url = components.url else {
            ErrorController.addErrorLog(errorLocation: "FinHealthController.profitabilityData", systemError: nil, errorInfo: "url error for \(share.symbol!)")
            return
        }
        
        var values: [DatedValue]?
        
        do {
            let earliestDate = Date().addingTimeInterval(-year)
            values = try await WebPageScraper2.getqColumnTableData(url: url, companyName: sn, tableHeader: "Net Profit Margin Historical Data", dateColumn: 0 , valueColumn: 3, until: earliestDate)
            
            for value in values ?? [] {
                if !(value.date < earliestChartDate) {
                    netProfitMargins.append(ChartDataSet(x: value.date, y: value.value))
                }
            }
            
        }  catch let error as DownloadAndAnalysisError {
            ErrorController.addErrorLog(errorLocation: "FinHealthController.profitabilityData", systemError: nil, errorInfo: "a background download or analysis error for \(share.symbol!) occurred: \(error)")
        }
        
    }
    
    func efficiencyData(share: Share) async throws {
        
        var sn = share.name_short ?? ""
        if sn.contains(" ") {
            sn = sn.replacingOccurrences(of: " ", with: "-").lowercased()
        }
        
        guard let components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(share.symbol!)/\(sn)/operating-margin") else {
            ErrorController.addErrorLog(errorLocation: "FinHealthController.efficiencyData", systemError: nil, errorInfo: "url components error for \(share.symbol!)")
            return
        }
        
        guard let url = components.url else {
            ErrorController.addErrorLog(errorLocation: "FinHealthController.efficiencyData", systemError: nil, errorInfo: "url error for \(share.symbol!)")
            return
        }
        
        var values: [DatedValue]?
        
        do {
            let earliestDate = Date().addingTimeInterval(-year)
            values = try await WebPageScraper2.getqColumnTableData(url: url, companyName: sn, tableHeader: "Operating Margin Historical Data", dateColumn: 0 , valueColumn: 3, until: earliestDate)
            
            for value in values ?? [] {
                if !(value.date < earliestChartDate) {
                    operatingMargins.append(ChartDataSet(x: value.date, y: value.value))
                }
            }
        }  catch let error as DownloadAndAnalysisError {
            ErrorController.addErrorLog(errorLocation: "FinHealthController.efficiencyData", systemError: nil, errorInfo: "a background download or analysis error for \(share.symbol!) occurred: \(error)")
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
            throw DownloadAndAnalysisError.urlError
        }

        guard let url = components.url else {
            throw DownloadAndAnalysisError.urlError
        }
        
        var values1: [DatedValue]?
        do {
            let earliestDate = Date().addingTimeInterval(-year)
            values1 = try await WebPageScraper2.getqColumnTableData(url: url, companyName: sn, tableHeader: "Quick Ratio Historical Data", dateColumn: 0 , valueColumn: 3, until: earliestDate)
            
            for value in values1 ?? [] {
                if !(value.date < earliestChartDate) {
                    quickRatios.append(ChartDataSet(x: value.date, y: value.value))
                }
            }
        }  catch let error as DownloadAndAnalysisError {
            throw error
//            ErrorController.addErrorLog(errorLocation: "FinHealthController.liquidityData", systemError: nil, errorInfo: "a background download or analysis error for \(share.symbol!) occurred: \(error)")
        }

 
    }

    func currentRatios(share: Share) async throws  {
        
        var sn = share.name_short ?? ""
        if sn.contains(" ") {
            sn = sn.replacingOccurrences(of: " ", with: "-").lowercased()
        }
        
        guard let components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(share.symbol!)/\(sn)/current-ratio") else {
            throw DownloadAndAnalysisError.urlError
        }

        guard let url = components.url else {
            throw DownloadAndAnalysisError.urlError
        }
        
        var values: [DatedValue]?
        do {
            let earliestDate = Date().addingTimeInterval(-year)
            values = try await WebPageScraper2.getqColumnTableData(url: url, companyName: sn, tableHeader: "Current Ratio Historical Data", dateColumn: 0 , valueColumn: 3, until: earliestDate)
            
            for value in values ?? [] {
                if !(value.date < earliestChartDate) {
                    currentRatios.append(ChartDataSet(x: value.date, y: value.value))
                }
            }
        }  catch let error as DownloadAndAnalysisError {
            throw error
//            ErrorController.addErrorLog(errorLocation: "FinHealthController.liquidityData", systemError: nil, errorInfo: "a background download or analysis error for \(share.symbol!) occurred: \(error)")
        }

 
    }

    func solvencyData(share: Share) async throws  {
        
        var sn = share.name_short ?? ""
        if sn.contains(" ") {
            sn = sn.replacingOccurrences(of: " ", with: "-").lowercased()
        }
        
        guard let components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(share.symbol!)/\(sn)/debt-equity-ratio") else {
            throw DownloadAndAnalysisError.urlError
        }

        guard let url = components.url else {
            throw DownloadAndAnalysisError.urlError
        }
        
        var values: [DatedValue]?
        do {
            let earliestDate = Date().addingTimeInterval(-year)
            values = try await WebPageScraper2.getqColumnTableData(url: url, companyName: sn, tableHeader: "Debt/Equity Ratio Historical Data", dateColumn: 0 , valueColumn: 3, until: earliestDate)
            
            for value in values ?? [] {
                if !(value.date < earliestChartDate) {
                    debEquityRatios.append(ChartDataSet(x: value.date, y: value.value))
                }
            }
        }  catch let error as DownloadAndAnalysisError {
            throw error
//            ErrorController.addErrorLog(errorLocation: "FinHealthController.liquidityData", systemError: nil, errorInfo: "a background download or analysis error for \(share.symbol!) occurred: \(error)")
        }

 
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

extension FinHealthController: ProgressViewDelegate {
    
    func progressUpdate(allTasks: Int, completedTasks: Int) {
        print("download progress update")
    }
    
    func cancelRequested() {
        self.downloadTask?.cancel()
    }
    
    func downloadComplete() {
        DispatchQueue.main.async {
//            self.finHealthTVC.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
            self.finHealthTVC.tableView.reloadData()
        }
    }
    
    func downloadError(error: String) {
        print("download error in FHC \(error)")
    }
    
    
}
