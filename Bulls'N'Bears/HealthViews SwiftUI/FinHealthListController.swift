//
//  FinHealthListController.swift
//  Bulls'N'Bears
//
//  Created by aDav on 25/03/2023.
//


import UIKit
import CoreData
import OSLog

class FinHealthListController: NSObject {
    
    var share: Share!
    var downloadTask: Task<Any?, Error>?
    var earliestChartDate: Date!
    
    // values not stored
    var netProfitMargins = [ChartDataSet]()
    var operatingMargins = [ChartDataSet]()
    var quickRatios = [ChartDataSet]()
    var currentRatios = [ChartDataSet]()
    var debEquityRatios = [ChartDataSet]()
    var currentHealthScore: Double?
    var allTrendDataSets = [LabelledChartDataSet]()
    
    var healthData: HealthData?
    let logger = Logger()
    
    init(share: Share) {
        super.init()
        
        self.share = share
        earliestChartDate = DatesManager.beginningOfYear(of: Date().addingTimeInterval(-year))
        allTrendDataSets = trendData()
        
        do {
            healthData = try PersistenceController.shared.persistentContainer.viewContext.fetch(HealthData.fetchRequest()).filter({ data in
                if data.share == share { return true }
                else { return false}
            }).first
            if healthData == nil {
                healthData = HealthData(context: PersistenceController.shared.persistentContainer.viewContext)
                healthData?.share = self.share
                try PersistenceController.shared.persistentContainer.viewContext.save()
            }
        } catch {
            ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "Error fetching healthData for share \(share.symbol)")
        }

    }
    
    func trendData() -> [LabelledChartDataSet] {
                
        var allSets = [LabelledChartDataSet]()

        ShareTrendNames.allCases.forEach { trendType in
                        
            let dataSet = share.trendChartData(trendName: trendType)

            var title = ""
            var lds: LabelledChartDataSet
            var format: ValuationCellValueFormat
            
            switch trendType {
            case .moatScore:
                title = "Moat"
                format = .percent
            case .lynchScore:
                title = "Lynch"
                format = .numberWithDecimals
            case .dCFValue:
                title = "DCF"
                format = .currency
            case .stickerPrice:
                title = "Sticker"
                format = .currency
            case .healthScore:
                title = "Health"
                format = .percent
            case .intrinsicValue:
                title = "Intrinsic"
                format = .currency
            }
            
            lds = LabelledChartDataSet(title: title, chartData: dataSet, format: format)
            
            allSets.append(lds)
        }
        
        return allSets
    }
    
    func returnTrendDataSet(for types: [ShareTrendNames]) -> [LabelledChartDataSet] {
        
        var lds = [LabelledChartDataSet]()
        var title = String()
        
        for type in types {
           
            switch type {
            case .moatScore:
                title = "Moat"
            case .lynchScore:
                title = "Lynch"
            case .dCFValue:
                title = "DCF"
            case .stickerPrice:
                title = "Sticker"
            case .healthScore:
                title = "Health"
            case .intrinsicValue:
                title = "Intrinsic"
            }
            
            if let selected = allTrendDataSets.filter({ lds in
                if title == lds.title { return true }
                else { return false }
            }).first {
                
                lds.append(selected)
            }

        }
        
        return lds
   }
    
    func returnTrendChange(for type: ShareTrendNames) -> String? {
        
            var title = String()
           
            switch type {
            case .moatScore:
                title = "Moat"
            case .lynchScore:
                title = "Lynch"
            case .dCFValue:
                title = "DCF"
            case .stickerPrice:
                title = "Sticker"
            case .healthScore:
                title = "Health"
            case .intrinsicValue:
                title = "Intrinsic"
            }
            
            if let selected = allTrendDataSets.filter({ lds in
                if title == lds.title { return true }
                else { return false }
            }).first {
                
                if selected.chartData.count > 1 {
                    
                    let dateAscending = selected.chartData.sorted { c0, c1 in
                        if c0.x ?? Date() < c1.x ?? Date() { return true }
                        else { return false }
                    }
                    
                    let first = dateAscending.first?.y
                    let last = dateAscending.last?.y
                    
                    if first != nil && last != nil {
                        if first! != 0.0 {
                            let ratio = (last! - first!) / first!
                            return percentFormatter0DigitsPositive.string(from: ratio as NSNumber)
                        }
                    }
                    
                }
            }
                
            return nil
    }
    
    func profitabilityAndEfficiencyData() async -> [LabelledChartDataSet] {
        
        netProfitMargins = await profitabilityData()
        operatingMargins = await efficiencyData()

        let prof = LabelledChartDataSet(title: "Profitability", chartData: netProfitMargins, format: .percent)
        let eff = LabelledChartDataSet(title: "Efficiency", chartData: operatingMargins, format: .percent)
        
        return [prof, eff]

    }
    
    func profitabilityData() async -> [ChartDataSet] {
        
        netProfitMargins = [ChartDataSet]()
        var sn = (share.name_short ?? "").lowercased()

        if sn.contains(" ") {
            sn = sn.replacingOccurrences(of: " ", with: "-").lowercased()
        }
        
        if let bracket = sn.firstIndex(of: "(") {
            sn = String(sn[sn.startIndex..<bracket])
        }
        
        if sn.last == "-" {
            sn = String(sn.dropLast())
        }
        guard let components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(share.symbol!)/\(sn)/net-profit-margin") else {
            ErrorController.addInternalError(errorLocation: "FinHealthController.profitabilityData", systemError: nil, errorInfo: "url components error for \(share.symbol!)")
            return netProfitMargins
        }
        
        guard let url = components.url else {
            ErrorController.addInternalError(errorLocation: "FinHealthController.profitabilityData", systemError: nil, errorInfo: "url error for \(share.symbol!)")
            return netProfitMargins
        }
        
        var existingProfitabilities = healthData?.profitability.datedValues(dateOrder: .ascending)
        var values: [DatedValue]?
        let earliestChartDate = DatesManager.beginningOfYear(of: Date().addingTimeInterval(-year))
        
        do {
            values = try await MacrotrendsScraper.getqColumnTableData(url: url, companyName: sn, tableHeader: "Net Profit Margin Historical Data", dateColumn: 0 , valueColumn: 3, until: earliestChartDate)
            existingProfitabilities = existingProfitabilities?.add(newDV: values, replaceOldValues: true)  ?? values
            healthData?.profitability = existingProfitabilities?.convertToData()
            healthData?.save()
            
            for value in existingProfitabilities ?? [] {
                if (value.date > earliestChartDate) {
                    netProfitMargins.append(ChartDataSet(x: value.date, y: value.value))
                }
            }
            
        }  catch {
            logger.warning("a profitmargin download or analysis error from Macrotrends for \(self.share.symbol!) occurred: \(error)")
        }
        	
        return netProfitMargins
        
    }
    
    func efficiencyData() async -> [ChartDataSet] {
        
        operatingMargins = [ChartDataSet]()
        var sn = (share.name_short ?? "").lowercased()
        
        if sn.contains(" ") {
            sn = sn.replacingOccurrences(of: " ", with: "-").lowercased()
        }
        
        if let bracket = sn.firstIndex(of: "(") {
            sn = String(sn[sn.startIndex..<bracket])
        }
        
        if sn.last == "-" {
            sn = String(sn.dropLast())
        }
        
        guard let components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(share.symbol!)/\(sn)/operating-margin") else {
            ErrorController.addInternalError(errorLocation: "FinHealthController.efficiencyData", systemError: nil, errorInfo: "url components error for \(share.symbol!)")
            return operatingMargins
        }
        
        guard let url = components.url else {
            ErrorController.addInternalError(errorLocation: "FinHealthController.efficiencyData", systemError: nil, errorInfo: "url error for \(share.symbol!)")
            return operatingMargins
        }
        
        var existingEfficiencies = healthData?.efficiency.datedValues(dateOrder: .ascending)
        let earliestChartDate = DatesManager.beginningOfYear(of: Date().addingTimeInterval(-year))

        do {
            let values = try await MacrotrendsScraper.getqColumnTableData(url: url, companyName: sn, tableHeader: "Operating Margin Historical Data", dateColumn: 0 , valueColumn: 3, until: earliestChartDate)
            existingEfficiencies = existingEfficiencies?.add(newDV: values, replaceOldValues: true) ?? values
            healthData?.efficiency = existingEfficiencies?.convertToData()
            healthData?.save()

            for value in existingEfficiencies ?? [] {
                if !(value.date < earliestChartDate) {
                    operatingMargins.append(ChartDataSet(x: value.date, y: value.value))
                }
            }
        }  catch {
            logger.warning("a effiency data download or analysis error from Macrotrends for \(self.share.symbol!) occurred: \(error)")
        }
        
        return operatingMargins
        
    }
    
    func liquidityData() async -> [LabelledChartDataSet] {
        
        quickRatios = await quickRatios()
        currentRatios = await currentRatios()
            
        let lQR = LabelledChartDataSet(title: "Quick ratio", chartData: quickRatios, format: .numberWithDecimals)
        let lCR = LabelledChartDataSet(title: "Current ratio", chartData: currentRatios, format: .numberWithDecimals)
        
        return [lQR, lCR]
}
    
    func quickRatios() async -> [ChartDataSet]  {
        
        var emptyChartData = [ChartDataSet]()
        var sn = (share.name_short ?? "").lowercased()
        
        if sn.contains(" ") {
            sn = sn.replacingOccurrences(of: " ", with: "-").lowercased()
        }
        
        if let bracket = sn.firstIndex(of: "(") {
            sn = String(sn[sn.startIndex..<bracket])
        }
        
        if sn.last == "-" {
            sn = String(sn.dropLast())
        }
        guard let components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(share.symbol!)/\(sn)/quick-ratio") else {
            ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "quick ratio download or analysis failed for \(share.symbol!) due to invalid url")
            return emptyChartData
        }

        guard let url = components.url else {
            ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "quick ratio download or analysis failed for \(share.symbol!) due to invalid url \(components)")
            return emptyChartData
        }
        
        var existingQR = healthData?.quickRatio.datedValues(dateOrder: .ascending)

        let earliestChartDate = DatesManager.beginningOfYear(of: Date().addingTimeInterval(-year))

        do {
            let values = try await MacrotrendsScraper.getqColumnTableData(url: url, companyName: sn, tableHeader: "Quick Ratio Historical Data", dateColumn: 0 , valueColumn: 3, until: earliestChartDate)
            existingQR = existingQR?.add(newDV: values, replaceOldValues: true) ?? values
            healthData?.quickRatio = existingQR?.convertToData()
            healthData?.save()

            for value in existingQR ?? [] {
                if !(value.date < earliestChartDate) {
                    emptyChartData.append(ChartDataSet(x: value.date, y: value.value))
                }
            }
            
        }  catch  {
            ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "quick ratio download or analysis failed for \(share.symbol!) due to download or analysis error")
        }

        return emptyChartData
 
    }

    func currentRatios() async -> [ChartDataSet]  {
        
        var emptyChartData = [ChartDataSet]()
        var sn = (share.name_short ?? "").lowercased()
        
        if sn.contains(" ") {
            sn = sn.replacingOccurrences(of: " ", with: "-").lowercased()
        }
        
        if let bracket = sn.firstIndex(of: "(") {
            sn = String(sn[sn.startIndex..<bracket])
        }
        
        if sn.last == "-" {
            sn = String(sn.dropLast())
        }
        guard let components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(share.symbol!)/\(sn)/current-ratio") else {
            ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "current ratio download or analysis failed for \(share.symbol!) due to invalid url")
            return emptyChartData
        }

        guard let url = components.url else {
            ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "current ratio download or analysis failed for \(share.symbol!) due to invalid url \(components)")
            return emptyChartData
        }
        
        var existingCR = healthData?.quickRatio.datedValues(dateOrder: .ascending)

        let earliestChartDate = DatesManager.beginningOfYear(of: Date().addingTimeInterval(-year))

        do {
            let values = try await MacrotrendsScraper.getqColumnTableData(url: url, companyName: sn, tableHeader: "Current Ratio Historical Data", dateColumn: 0 , valueColumn: 3, until: earliestChartDate)
            existingCR = existingCR?.add(newDV: values, replaceOldValues: true) ?? values
            healthData?.currentRatio = existingCR?.convertToData()
            healthData?.save()

            for value in existingCR ?? [] {
                if !(value.date < earliestChartDate) {
                    emptyChartData.append(ChartDataSet(x: value.date, y: value.value))
                }
            }
        }  catch {
            ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "Current ratio download or analysis failed for \(share.symbol!) due to download or analysis error")
        }

        return emptyChartData
 
    }

    func solvencyData() async -> LabelledChartDataSet  {
        
        debEquityRatios = [ChartDataSet]()
        var emptylabellChartData = LabelledChartDataSet(title: "Solvency", chartData: debEquityRatios, format: .numberWithDecimals)
        var sn = (share.name_short ?? "").lowercased()
        
        if sn.contains(" ") {
            sn = sn.replacingOccurrences(of: " ", with: "-").lowercased()
        }
        
        if let bracket = sn.firstIndex(of: "(") {
            sn = String(sn[sn.startIndex..<bracket])
        }
        
        if sn.last == "-" {
            sn = String(sn.dropLast())
        }
        guard let components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(share.symbol!)/\(sn)/debt-equity-ratio") else {
            ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "debt/equity ratio download or analysis failed for \(share.symbol!) due to invalid url components")
            return emptylabellChartData
        }

        guard let url = components.url else {
            ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "debt/equity ratio download or analysis failed for \(share.symbol!) due to invalid url \(components)")
            return emptylabellChartData
        }
        
        var existingSolvencies = healthData?.solvency.datedValues(dateOrder: .ascending)        
        let earliestChartDate = DatesManager.beginningOfYear(of: Date().addingTimeInterval(-year))
        
        do {
            let values = try await MacrotrendsScraper.getqColumnTableData(url: url, companyName: sn, tableHeader: "Debt/Equity Ratio Historical Data", dateColumn: 0 , valueColumn: 3, until: earliestChartDate)
            
            existingSolvencies = existingSolvencies?.add(newDV: values, replaceOldValues: true) ?? values
            healthData?.quickRatio = existingSolvencies?.convertToData()
            healthData?.save()

            
            for value in existingSolvencies ?? [] {
                if !(value.date < earliestChartDate) {
                    debEquityRatios.append(ChartDataSet(x: value.date, y: value.value))
                }
            }
            emptylabellChartData.chartData = debEquityRatios
        }  catch {
            ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "Debt/equity ratio download or analysis failed for \(share.symbol!) due to download or analysis error")
        }
        return emptylabellChartData

    }
    
    func healthScore() -> Double? {
        
        let keyFinTypes: [ShareTrendNames] = [.moatScore, .stickerPrice, .lynchScore, .dCFValue, .intrinsicValue]
        var keyFinScores = [Double?]()
        
        for i in 0..<keyFinTypes.count {
                // chartData are returned date ASCENDING
                let keyFinTrend = share!.trendChartData(trendName: keyFinTypes[i])
            
                if keyFinTypes[i] == .moatScore {
                    // add latest moatScore
                    keyFinScores.append(keyFinTrend.last?.y)
                    if let trendRatio = firstValueRatioToMax(datedValues: keyFinTrend) {
                        if trendRatio < 0.9 {
                            // if moat score lates / earliest < 90% = dropping trend multiply current moat with trendRatio
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

                }
                else if keyFinTypes[i] == .lynchScore {
                    
                    if let lastY = keyFinTrend.last?.y {
                        
                        if lastY < 1 { // 0 if lynch < 1
                            keyFinScores.append(0)
                        } else if lastY < 2 { // 0-1 score if lynch 1-2
                            keyFinScores.append(lastY-1)
                        } else {
                            keyFinScores.append(1.0) // add 1 if lynch > 2
                        }
                    }
                    if let trendRatio = firstValueRatioToMax(datedValues: keyFinTrend) {
                        if trendRatio < 0.9 {
                            keyFinScores[i]! *= trendRatio
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
            
            if let firstY = netProfitMargins.first?.y {
                if firstY < 0 {
                    profitabilityScore = 0
                }
            }

        }
        
        // EFFICIENCY
        var efficiencyScore: Double?
        if let opMarginsTrendratio = firstValueRatioToMax(datedValues: operatingMargins) {
            
            efficiencyScore = 1.0
            if opMarginsTrendratio < 0.9 {
                efficiencyScore! *= opMarginsTrendratio
            }
            
            if let firstY = operatingMargins.first?.y {
                if firstY < 0 {
                    efficiencyScore = 0
                }
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
                if let firstY = liquidityRatios[i].first?.y {
                    
                    if firstY < 1.0 {
                        baseScore *= firstY
                    }
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
            
            if let firstY = debEquityRatios.first?.y {
                
                if firstY > 1.0 {
                    solvencyScore! /= firstY
                } else if firstY < 0 {
                    solvencyScore = 0
                }
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
            currentHealthScore = sum / Double(count)
            
            let dv = DatedValue(date: Date(), value: currentHealthScore!)
            share.saveTrendsData(datedValuesToAdd: [dv], trendName: .healthScore)
            
            return currentHealthScore
        }
        
        return nil
    }
    
    func healthScore$() -> String {
        
        if let valid = currentHealthScore {
            return percentFormatter0Digits.string(from: valid as NSNumber) ?? " - "
        } else if let score = healthScore() {
            return percentFormatter0Digits.string(from: score as NSNumber) ?? " - "
        } else {
            return " - "
        }
    }
    
    func firstValueRatioToMax(datedValues: [ChartDataSet], useMax:Bool?=true) -> Double? {
        
        let descending = datedValues.sorted { ds0, ds1 in
            if ds0.x ?? Date() > ds1.x ?? Date() { return true }
            else { return false }
        }
        
        if let max = useMax! ? descending.compactMap({ $0.y }).max() : descending.compactMap({ $0.y }).min() {
            let latest = descending.first!.y!
            let ratioLatestToMax = latest / max
            return ratioLatestToMax
        }
        
        return nil
    }
    
    func earliestToLatestChange(datedValues: [ChartDataSet]) -> String? {
        
        if datedValues.count < 2 {
            return nil
        }
        
        let ascending = datedValues.sorted { ds0, ds1 in
            if ds0.x ?? Date() < ds1.x ?? Date() { return true }
            else { return false }
        }
        
        let earliest = ascending.first!.y
        let latest = ascending.last!.y
        
        if earliest != nil && latest != nil {
            if earliest != 0.0 {
                let ratio = (latest! - earliest!) / earliest!
                return percentFormatter0DigitsPositive.string(from: ratio as NSNumber)
            }
        }
        
        
        return nil
    }


    
}


