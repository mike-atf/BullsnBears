//
//  Extensions.swift
//  Bulls'N'Bears
//
//  Created by aDav on 14/01/2021.
//

import UIKit

//MARK: - [YahooDictionaryEntry]
extension [YahooDictionaryEntry] {
    
    func pageName(for saveTitle: String) -> String? {
        
        return self.filter { element in
            if element.parameterTitle == saveTitle { return true }
            else { return false }
        }.first?.pageName
    }
    
    func sectionName(for saveTitle: String) -> String? {
        
        return self.filter { element in
            if element.parameterTitle == saveTitle { return true }
            else { return false }
        }.first?.sectionName
    }
    
    func addElement(pageName: String, sectionNames: [String?], rowNames: [[String]], saveNames: [[String?]]) -> [YahooDictionaryEntry] {
        
        var existing = self
        var sectionCount = 0
        var rowCount = 0
        
        for names in rowNames {
            rowCount = 0
            let sections = sectionNames[sectionCount]
            for name in names {
                let new = YahooDictionaryEntry(pageName: pageName, sectionName: sections, rowName: name, parameterTitle: saveNames[sectionCount][rowCount] ?? name)
                rowCount += 1
                existing.append(new)
            }
            sectionCount += 1
        }
        
        return existing
    }

    func rowTitles(for downloadOption: DownloadOptions) -> [String] {
        
        switch downloadOption {
        case .allPossible:
            return [
                [["Revenue","EPS - Earnings Per Share", "Net Income","Interest expense","Income before tax","Income tax expense"]],
                [["Current debt","Long-term Debt","Total liabilities"]],
                [["Free cash flow", "Operating cash flow","Capital expenditure"]],
                [["Total insider shares held", "Purchases", "Sales"]],
                [["Avg. Estimate", "Sales growth (year/est)"], ["Next year", "Next 5 years (per annum)"]],
                [["Forward P/E","Market cap (intra-day)"],["Beta (5Y monthly)","Shares outstanding", "Payout ratio","Trailing annual dividend yield"]],
                [["Sector", "Industry", "Employees", "Description"]],
                [["Market cap","Beta (5Y monthly)", "PE ratio (TTM)","Earnings date"]]].flatMap{ $0 }.flatMap{ $0 }
            case .dcfOnly:
            return [
                [["Total revenue", "Net income", "Interest expense","Income before tax","Income tax expense"]],
                [["Current debt","Long-term debt"]],
                [["Free cash flow","Capital expenditure"]],
                [["Avg. Estimate", "Sales growth (year/est)"], ["Next year", "Next 5 years (per annum)"]],
                [["Market cap (intra-day)"],["Beta (5Y monthly)", "Shares outstanding", "Payout ratio","Trailing annual dividend yield"]],
                [["Market cap","Beta (5Y monthly)", "Earnings date"]]].flatMap{ $0 }.flatMap{ $0 }
        case .rule1Only:
                return [
                [["Total revenue","Basic EPS","Net income"]],
                [["Current debt","Long-term debt"]],
                [["Total insider shares held", "Purchases", "Sales"]],
                [["Avg. Estimate", "Sales growth (year/est)"], ["Next year", "Next 5 years (per annum)"]],
                [["Forward P/E"]]
                ].flatMap{ $0 }.flatMap{ $0 }
        case .wbvOnly:
            return [
                [["Total revenue","Basic EPS","Net income", "Interest expense","Income before tax","Income tax expense"]],
                [["Current debt","Long-term debt", "Total liabilities"]],
                [["Free cash flow","Operating cash flow","Capital expenditure"]],
                [["Total insider shares held", "Purchases", "Sales"]],
                [["Avg. Estimate", "Sales growth (year/est)"], ["Next year", "Next 5 years (per annum)"]],
                [["Forward P/E","Market cap (intra-day)"],["Beta (5Y monthly)", "Shares outstanding", "Payout ratio","Trailing annual dividend yield"]]].flatMap{ $0 }.flatMap{ $0 }
        case .yahooKeyStatistics:
            return [[["Beta (5Y monthly)", "Trailing P/E", "Diluted EPS", "Trailing annual dividend yield"]],
                         [["Market cap","Beta (5Y monthly)", "Earnings date"]]].flatMap{ $0 }.flatMap{ $0 }
        case .yahooProfile:
            return [[["<span>Sector(s)</span>", "<span>Industry</span>", "span>Full-time employees</span>", "<span>Description</span>"]]].flatMap{ $0 }.flatMap{ $0 }
        case .lynchParameters:
            return [[["Trailing annual dividend yield"]], [["PE ratio (TTM)"]]].flatMap{ $0 }.flatMap{ $0 }
        case .wbvIntrinsicValue:
            return []
        case .allValuationDataOnly:
            return [
                [["Total revenue","Basic EPS","Net income", "Interest expense","Income before tax","Income tax expense"]],
                [["Current debt","Long-term debt", "Total liabilities"]],
                [["Free cash flow","Operating cash flow","Capital expenditure"]],
                [["Total insider shares held", "Purchases", "Sales"]],
                [["Avg. Estimate", "Sales growth (year/est)"], ["Next year", "Next 5 years (per annum)"]],
                [["Forward P/E","Market cap (intra-day)"],["Beta (5Y monthly)", "Shares outstanding", "Payout ratio","Trailing annual dividend yield"]],
                [["Market cap","Beta (5Y monthly)", "Earnings date"]]].flatMap{ $0 }.flatMap{ $0 }
        case .researchDataOnly:
            return [
                    [["<span>Sector(s)</span>", "<span>Industry</span>", "span>Full-time employees</span>", "<span>Description</span>"]],
                    [["Market cap","Beta (5Y monthly)", "Earnings date"]]].flatMap{ $0 }.flatMap{ $0 }
        case .mainIndicatorsOnly:
            // none required for moat from Yahoo
            return [[["Trailing annual dividend yield"]], [["PE ratio (TTM)"]]].flatMap{ $0 }.flatMap{ $0 }
        case .screeningInfos:
            var array = [[["Trailing annual dividend yield"]], [["PE ratio (TTM)","Market cap","Beta (5Y monthly)", "Earnings date"]]] // [keyStat, summary]
            array.append([["<span>Sector(s)</span>", "<span>Industry</span>", "span>Full-time employees</span>", "<span>Description</span>"]]) // profile
            return array.flatMap{ $0 }.flatMap{ $0 }
        case .nonUS:
            // extracte from FraBo: [["Revenue","Gross profit","income tax expense","Net income","eps - earnings per share", "Book value per share", "free cash flow per share", "pe ratio historical data", "roe - return on equity", "roa - return on assets", "roi - return on investment", "long-term debt", "current debt","trailing p/e"],["shares outstanding","market cap", "trailing annual dividend yield"]]
            return [
                [["Interest expense"]],
                [[]],
                [["Free cash flow", "Operating cash flow","Capital expenditure"]],
                [["Total insider shares held", "Purchases", "Sales"]],
                [[], []],
                [[],["Beta (5Y monthly)","Payout ratio"]],
                [["Sector", "Industry", "Employees", "Description"]],
                [["Earnings date"]]].flatMap{ $0 }.flatMap{ $0 }
 
        default:
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "[YahooWebDictionary] has been asked to download unknown job \(downloadOption)")
            return []
        }
    }
    
    func findEntries(for rowNames: [String]) -> [YahooDictionaryEntry]? {
        
        return self.filter { entry in
            if rowNames.contains(entry.rowName) { return true }
            else { return false }
        }
    }
    
    func downloadJobs(for option: DownloadOptions, symbol: String, shortName: String) -> [YahooDownloadJob]? {
        
        let rows = self.rowTitles(for: option)
        guard let allMatchingsEntries = findEntries(for: rows) else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "no matching entries for \(rows)")
            return nil
        }
        
        let pages = Set<String>(allMatchingsEntries.compactMap{ $0.pageName })
        
        var jobs = [YahooDownloadJob]()
        for page in pages {
            
            let entriesForPage = allMatchingsEntries.filter({ entry in
                if entry.pageName == page { return true }
                else { return false }
            })
            
            let sectionsSetForPage: Set<String?> = Set<String?>(entriesForPage.map{ $0.sectionName })
            let sectionsForPage = sectionsSetForPage.map { $0 }
            
            var rowsForSections = [[String]]()
            var saveAsForSections = [[String]]()
            for section in sectionsForPage {
                let entriesForSection = entriesForPage.filter { entry in
                    if entry.sectionName == section { return true }
                    else { return false }
                }
                
                let rowsForSection = entriesForSection.compactMap{ $0.rowName }
                let savAsForSection = entriesForSection.compactMap{ $0.parameterTitle }
                rowsForSections.append(rowsForSection)
                saveAsForSections.append(savAsForSection)
            }

            if let newJob = YahooDownloadJob(symbol: symbol, shortName: shortName, pageName: page, tableTitles: sectionsForPage, rowTitles: rowsForSections, saveTitles: saveAsForSections) {
                jobs.append(newJob)
            } else {
                ErrorController.addInternalError(errorLocation: #function, errorInfo: "failed to create job for page \(page), sections \(sectionsSetForPage), rows \(rowsForSections)")
            }
        }
        return jobs
    }

    
}

//MARK: - [DatedValue]
extension [DatedValue] {
    
    /// merge rules: if new elements.count < existing.count replaces existing elements between dates new.earliest-last with new elements
    /// if new.count == existing count: check if newest.date > existing.date; if yes add latest only to existing
    /// if new.count > existing.count discard all existing older than new.latest
    /// Yahoo usully has 4 element sonly, Macrotrend far more
    func mergeIn(newDV: [DatedValue]?, removeZeroes:Bool?=false) -> [DatedValue]? {
        
        guard let new = newDV?.sortByDate(dateOrder: .ascending) else { return self }
        
        guard new.count > 0 else { return self }

        var existing = self.sortByDate(dateOrder: .ascending)
        if new.count < existing.count {
            // replace all existing elements between new.latest and new.earliest
            existing = existing.filter({ dv in
                if dv.date >= new.first!.date && dv.date <= new.last!.date { return false }
                else { return true }
            })
            
            if removeZeroes ?? false {
                existing = existing.filter { dv in
                    if dv.value == 0 { return false }
                    else { return true }
                }
            }
            
            existing.append(contentsOf: new)
            return existing

        }
        else if new.count == existing.count {
            let newerDVs = new.filter ({ dv in
                if dv.date > existing.last!.date { return true }
                else { return false }
            })
            existing.append(contentsOf: newerDVs)
            return existing
        }
        else {
            var newerThanNewonly = existing.filter({ dv in
                if dv.date.timeIntervalSince(new.last!.date) > 24*3600 { return true }
                else { return false }
            })
            newerThanNewonly.append(contentsOf: new)
            return newerThanNewonly
        }
        
    }
    
    func addOrReplaceNewest(newDV: DatedValue?) -> [DatedValue]? {
        
        guard let new = newDV else { return self }

        var existing = self.sortByDate(dateOrder: .ascending)
        
        if existing.count > 0 {
            let latestExisting = existing.last!
            if new.date.timeIntervalSince(latestExisting.date) < 24*3600 {
                existing = existing.dropLast()
                existing.append(new)
            } else {
                existing.append(new)
            }
        }
        else {
            existing = [new]
        }
        return existing

    }
    
    func convertToData() -> Data? {
                
        var array = [Date: Double]()

        for element in self {
            array[element.date] = element.value
        }

        do {
            return try NSKeyedArchiver.archivedData(withRootObject: array, requiringSecureCoding: false)
        } catch let error {
            ErrorController.addInternalError(errorLocation: "datedValuesToData function", systemError: error, errorInfo: "error converting DatedValues to Data")
        }

        return nil
    }
    
    func sortByDate(dateOrder: Order) -> [DatedValue] {
        
        return self.sorted { dv0, dv1 in
            if dateOrder == .ascending {
                if dv0.date < dv1.date { return true }
                else { return false }
            } else {
                if dv0.date > dv1.date { return true }
                else { return false }
            }
        }
    }
    
    func dropZeros() -> [DatedValue] {
        
        return self.filter({ dv in
            if dv.value == 0.0 { return false }
            else { return true }
        })
    }

    func maxYear$() -> String {
        
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return formatter
        }()
        
        if let maxYear = self.compactMap({ $0.date }).max() {
            return dateFormatter.string(from: maxYear)
        }
        else {
            return "max NA"
        }
    }
    
    func minYear$() -> String {
        
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return formatter
        }()

        if let minYear = self.compactMap({ $0.date }).min() {
            return dateFormatter.string(from: minYear)
        }
        else {
            return "min NA"
        }
    }

    func allYear$() -> [String] {
        
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return formatter
        }()

        return self.compactMap{ dateFormatter.string(from: $0.date) }
    }
    
    func values() -> [Double] {
        return self.compactMap{ $0.value }
    }
    
    /// simple element to element change rates
    func growthRates(dateOrder: Order) -> [DatedValue]? {
        
        guard self.count > 1 else { return nil }
        
        let descending = self.sortByDate(dateOrder: .descending)
        
        var rates = [DatedValue]()
        for i in 1..<descending.count {
            var growth = 0.0
            if descending[i].value != 0 {
                growth = (descending[i-1].value - descending[i].value) / descending[i].value
            }
            rates.append(DatedValue(date: descending[i-1].date, value: growth))
        }
        
        return rates.sortByDate(dateOrder: dateOrder)
    }

        
}

extension [DatedValue]? {
    
    func values(dateOrdered: Order) -> [Double]? {
        
        if let ordered = self?.sortByDate(dateOrder: dateOrdered) {
            return ordered.compactMap{ $0.value }
        }
        
        return nil
    }
    
//    func valuesOnly() -> [Double]? {
//        
//        if self == nil { return nil }
//        else {
//            return self!.compactMap{ $0.value }
//        }
//    }
    
    func dropZeros() -> [DatedValue]? {
        
        if self == nil { return nil }
        
        return self!.filter({ dv in
            if dv.value == 0.0 { return false }
            else { return true }
        })
    }

    func maxYear$() -> String? {
        
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return formatter
        }()

        
        if self == nil { return nil }
        if let maxYear = self!.compactMap({ $0.date }).max() {
            
            return dateFormatter.string(from: maxYear)
        } else {
            return nil
        }
    }
    
    func minYear$() -> String? {
        
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return formatter
        }()

        
        if self == nil { return nil }
        if let minYear = self!.compactMap({ $0.date }).max() {
            
            return dateFormatter.string(from: minYear)
        } else {
            return nil
        }
    }
    
    ///merge rules: if new elements.count < existing elements.count discard new elements
    /// if new.count == existing count: check if newest.date > existing.date; if yes add latest only to existing
    /// if new.count > existing.count discard existing and replce with new
    /// Yahoo usully has 4 element sonly, Macrotrend far more

    func mergeIn(newDV: [DatedValue]?) -> [DatedValue]? {
        
        guard let new = newDV?.sortByDate(dateOrder: .ascending) else { return self }
        guard var existing = self?.sortByDate(dateOrder: .ascending) else { return new }

        if new.count < existing.count { return existing }
        else if new.count == existing.count {
            let newerDVs = new.filter ({ dv in
                if dv.date > existing.last!.date { return true }
                else { return false }
            })
            existing.append(contentsOf: newerDVs)
        }
        else {
            return new
        }
        
        return existing
    }
    
    func growthRates(dateOrder: Order) -> [DatedValue]? {
        
        guard let dv = self else { return nil }
        
        guard dv.count > 1 else { return nil }
        
        let descending = dv.sortByDate(dateOrder: .descending)
        
        var rates = [DatedValue]()
        for i in 1..<descending.count {
            let growth = (descending[i-1].value - descending[i].value) / descending[i].value
            rates.append(DatedValue(date: descending[i-1].date, value: growth))
        }
        
        return rates.sortByDate(dateOrder: dateOrder)
    }

    
}

extension [[DatedValue]]? {
    
    /// send  TWO arrays, with only one element per calendar year; array in position two is the denominator, in one the divisor.
    func proportions() -> [DatedValue]? {
        
        guard self != nil else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "can't calculate proportions between two [DatedValue] array due to EMPTY [[DatedValue]]")
            return nil
        }
        
        guard self?.count ?? 0 == 2 else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "can't calculate proportions between two [DatedValue] array due to \(self?.count ?? 0) arrays sent")
            return nil
        }
        
        guard let harmonisedArrays = ValuationDataCleaner.harmonizeDatedValues(arrays: self!) else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "can't calculate proportions between two [DatedValue] array due to array harmonisation failure")
            return nil
        }
        
        let denominatorArray = harmonisedArrays[1]
        let divisorArray = harmonisedArrays[0]
        
        var proportionsDV = [DatedValue]()
        
        for i in 0..<denominatorArray.count {
            var proportion = 0.0
            if denominatorArray[i].value != 0 {
                proportion = divisorArray[i].value / denominatorArray[i].value
            }
            proportionsDV.append(DatedValue(date: denominatorArray[i].date, value: proportion))
        }
        
        return proportionsDV

    }
}

//MARK: - [DatedText]
extension [DatedText] {
    
    func sortByDate(dateOrder: Order) -> [DatedText] {
        
        return self.sorted { dv0, dv1 in
            if dateOrder == .ascending {
                if dv0.date < dv1.date { return true }
                else { return false }
            } else {
                if dv0.date > dv1.date { return true }
                else { return false }
            }
        }
    }
    
    func convertToData() -> Data? {
                
        var array = [Date: String]()

        for element in self {
            array[element.date] = element.text
        }

        do {
            return try NSKeyedArchiver.archivedData(withRootObject: array, requiringSecureCoding: false)
        } catch let error {
            ErrorController.addInternalError(errorLocation: "datedTextToData function", systemError: error, errorInfo: "error converting DatedTExt to Data")
        }

        return nil
    }

}

//MARK: - Labelled_DatedValues
extension Labelled_DatedValues {
    
    func sortDatedValues(dateOrder: Order) -> [DatedValue] {
        
        return self.datedValues.sorted { dv0, dv1 in
            if dateOrder == .ascending {
                if dv0.date < dv1.date { return true }
                else { return false }
            } else {
                if dv0.date > dv1.date { return true }
                else { return false }
            }
        }
    }
    
    func withSortedDatedValues(dateOrder: Order) -> Labelled_DatedValues {
        
        let sortedDV = self.datedValues.sorted { dv0, dv1 in
            if dateOrder == .ascending {
                if dv0.date < dv1.date { return true }
                else { return false }
            } else {
                if dv0.date > dv1.date { return true }
                else { return false }
            }
        }
        
        return Labelled_DatedValues(label: self.label, datedValues: sortedDV)
    }

    
}

//MARK: - [Labelled_DatedValues]
extension [Labelled_DatedValues] {
    
    func convertToLabelledValues(dateOrder: Order) -> [LabelledValues] {
        
        var labelledValues = [LabelledValues]()
        
        for element in self {
            let lvs = element.convertToLabelledValues(dateSortOrder: dateOrder)
            labelledValues.append(lvs)
        }
        
        return labelledValues
    }
    
    func convertToValues(dateOrder: Order) -> [[Double]] {
        
        var values = [[Double]]()
        
        for element in self {
            values.append(element.extractValuesOnly(dateOrder: dateOrder))
        }
        
        return values
    }
    
    func sortAllElementDatedValues(dateOrder: Order) -> [Labelled_DatedValues] {
        
        var sortedLDV = [Labelled_DatedValues]()
        
        for ldv in self {
            let sorted = ldv.sort(dateOrder: dateOrder)
            sortedLDV.append(sorted)
        }
        
        return sortedLDV
    }
    
}

//MARK: - [DatedValue_s]
extension [DatedValues] {
    
    func convertToData() -> Data? {
        
        var array = [Date: [Double]]()

        for element in self {
            array[element.date] = element.values
        }

        do {
            return try NSKeyedArchiver.archivedData(withRootObject: array, requiringSecureCoding: false)
        } catch let error {
            ErrorController.addInternalError(errorLocation: "datedValuesToData function", systemError: error, errorInfo: "error converting DatedValues to Data")
        }

        return nil

    }

}

//MARK: - [Data?]

extension Data? {
        
    func datedValues(dateOrder: Order, oneForEachYear:Bool?=nil, includeThisYear:Bool?=false) -> [DatedValue]? {
        
        guard self != nil else { return nil }

        do {
            if let dictionary = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(self!) as? [Date: Double] {
                var datedValues = [DatedValue]()
                for element in dictionary {
                    datedValues.append(DatedValue(date: element.key, value: element.value))
                }
                
                if !(includeThisYear ?? false ) {
                    let startThisYear = DatesManager.beginningOfYear(of: Date())
                    datedValues = datedValues.filter { dv in
                        if dv.date < startThisYear { return true }
                        else { return false }
                    }
                }
                
                if !(oneForEachYear ?? false) {
                    return datedValues.sorted { (e0, e1) -> Bool in
                        if dateOrder == .ascending {
                            if e0.date < e1.date { return true }
                            else { return false }
                        }
                        else {
                            if e0.date > e1.date { return true }
                            else { return false }
                        }
                    }
                }
                else {
                    
                    let yearDateFormatter: DateFormatter = {
                        let formatter = DateFormatter()
                        formatter.timeZone = TimeZone(identifier: "UTC")!
                        formatter.dateFormat = "yyyy"
                        return formatter
                    }()

                    var oneAnnualElementArray = [DatedValue]()
                    let elementYears = Set<String>(datedValues.compactMap{ yearDateFormatter.string(from: $0.date) })
                    
                    for year$ in elementYears {
                        let elementsInYear = datedValues.filter({ dv in
                            if yearDateFormatter.string(from: dv.date) == year$ { return true }
                            else { return false }
                        })
                        if elementsInYear.count == 1 {
                            oneAnnualElementArray.append(elementsInYear.first!)
                        }
                        else if elementsInYear.count > 1 {
                            let average = elementsInYear.compactMap{ $0.value}.mean()! // zero elements have been removed above
                            let averageDV = DatedValue(date: yearDateFormatter.date(from: year$)!, value: average)
                            oneAnnualElementArray.append(averageDV)
                        }
                    }
                    return oneAnnualElementArray.sortByDate(dateOrder: dateOrder)
                }
            }
        } catch  {
            ErrorController.addInternalError(errorLocation: "Data extension dataToDatedValues", systemError: error, errorInfo: "error decodomg datedValue data")
        }
        return nil

    }
    
    // for oneElement per year, returns the NEWEST element for a given year only
    func datedTexts(dateOrder: Order, oneForEachYear:Bool?=nil) -> [DatedText]? {
        
        guard self != nil else { return nil }
        
        do {
            if let dictionary = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(self!) as? [Date: String] {
                var datedTexts = [DatedText]()
                for element in dictionary {
                    datedTexts.append(DatedText(date: element.key, text: element.value))
                }
                
                if !(oneForEachYear ?? false) {
                    return datedTexts.sorted { (e0, e1) -> Bool in
                        if dateOrder == .ascending {
                            if e0.date < e1.date { return true }
                            else { return false }
                        }
                        else {
                            if e0.date > e1.date { return true }
                            else { return false }
                        }
                    }
                }
                else {
                    
                    let yearDateFormatter: DateFormatter = {
                        let formatter = DateFormatter()
                        formatter.timeZone = TimeZone(identifier: "UTC")!
                        formatter.dateFormat = "yyyy"
                        return formatter
                    }()

                    var oneAnnualElementArray = [DatedText]()
                    let elementYears = Set<String>(datedTexts.compactMap{ yearDateFormatter.string(from: $0.date) })
                    
                    for year$ in elementYears {
                        let elementsInYear = datedTexts.filter({ dv in
                            if yearDateFormatter.string(from: dv.date) == year$ { return true }
                            else { return false }
                        })
                        if elementsInYear.count == 1 {
                            oneAnnualElementArray.append(elementsInYear.first!)
                        }
                        else if elementsInYear.count > 1 {
                            let newest = elementsInYear.sorted { dt0, dt1 in
                                if dt0.date < dt1.date { return true }
                                else { return false }
                            }.last!
                            oneAnnualElementArray.append(newest)
                        }
                    }
                    return oneAnnualElementArray.sortByDate(dateOrder: dateOrder)
                }
            }
        } catch  {
            ErrorController.addInternalError(errorLocation: "Data extension dataToDatedValues", systemError: error, errorInfo: "error decodomg datedValue data")
        }
        return nil

    }
    
    func valuesOnly(dateOrdered: Order, withoutZeroes:Bool?=false, oneElementPerYear:Bool?=false, includeThisYear:Bool?=false) -> [Double]? {
        
        if let dvs = self.datedValues(dateOrder: dateOrdered, oneForEachYear: oneElementPerYear, includeThisYear: includeThisYear) {
            if !(withoutZeroes ?? false) {
                return dvs.compactMap{ $0.value }
            } else {
                return dvs.compactMap{ $0.value}.filter { d in
                    if d == 0.0 { return false }
                    else { return true }
                }
            }
        }
        
        return nil
    }
    
    func textsOnly(dateOrdered: Order, withoutEmpty:Bool?=false, oneElementPerYear:Bool?=false) -> [String]? {
        
        if let dvs = self.datedTexts(dateOrder: dateOrdered, oneForEachYear: oneElementPerYear) {
            if !(withoutEmpty ?? false) {
                return dvs.compactMap{ $0.text }
            } else {
                return dvs.compactMap{ $0.text}.filter { d in
                    if d != "" { return true }
                    else { return false }
                }
            }
        }
        
        return nil
    }

}

extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}


extension Double? {
    
    /// returns fraction number  with 'B', 'M', 'K' or no letter at the end
    /// for nil value returns empty String element
    func shortString(decimals: Int, formatter: NumberFormatter?=nil ,nilString: String? = "-") -> String {
                
        let defaultFormatter: NumberFormatter = {
            if decimals == 0 {
                return currencyFormatterNoGapNoPence
            }
            else  {
                return currencyFormatterNoGapWithPence
            }
        }()

        let formatter = formatter ?? defaultFormatter
        
        var shortString = nilString ?? String()
        
        guard let element = self else { return  shortString }
        
        if abs(element)/1000000000000 > 1 {
            let shortValue = element/1000000000000
            shortString = (formatter.string(from: shortValue  as NSNumber) ?? "-") + "T"
        }
        else if abs(element)/1000000000 > 1 {
            let shortValue = element/1000000000
            shortString = (formatter.string(from: shortValue  as NSNumber) ?? "-") + "B"
        } else if abs(element)/1000000 > 1 {
            let shortValue = element/1000000
            shortString = (formatter.string(from: shortValue  as NSNumber) ?? "-") + "M"
        }
        else if abs(element)/1000 > 1 {
            let shortValue = element/1000
            shortString = (formatter.string(from: shortValue  as NSNumber) ?? "-") + "K"
        } else {
            shortString = (formatter.string(from: element  as NSNumber) ?? "-")
        }
        
        return shortString
    }

}

extension Double {
    
    /// returns fraction number  with 'B', 'M', 'K' or no letter at the end
    func shortString(decimals: Int, formatter: NumberFormatter?=nil) -> String {
        
        let defaultFormatter: NumberFormatter = {
            if decimals == 0 {
                return currencyFormatterNoGapNoPence
            }
            else  {
                return currencyFormatterNoGapWithPence
            }
        }()

        let formatter = formatter ?? defaultFormatter
        var shortString = String()
        
        if abs(self)/1000000000000 > 1 {
            let shortValue = self/1000000000000
            shortString = (formatter.string(from: shortValue  as NSNumber) ?? "-") + "T"
        }
        else if abs(self)/1000000000 > 1 {
            let shortValue = self/1000000000
            shortString = (formatter.string(from: shortValue  as NSNumber) ?? "-") + "B"
        } else if abs(self)/1000000 > 1 {
            let shortValue = self/1000000
            shortString = (formatter.string(from: shortValue  as NSNumber) ?? "-") + "M"
        }
        else if abs(self)/1000 > 1 {
            let shortValue = self/1000
            shortString = (formatter.string(from: shortValue  as NSNumber) ?? "-") + "K"
        } else {
            shortString = (formatter.string(from: self  as NSNumber) ?? "-")
        }
        
        return shortString
    }

}

extension Array where Element == Double {
    
    // divides each element by the corresponding element of the divisor array 'self / divisor'; if element count doesn't match returns only count elements of smaller array
    func divideElements(divisor: [Double]) -> [Double]? {
    
        guard self.count > 0 && divisor.count > 0 else {
            return nil
        }
        
        var result = [Double]()
        
        for i in 0..<self.count {
            if divisor.count > i {
                result.append(self[i] / divisor[i])
            }
        }
        
        return result
        
    }
    
    /// returns fraction number  with 'B', 'M', 'K' or no letter at the end
    func shortStrings(decimals: Int, formatter: NumberFormatter?=nil, nilString: String? = "-") -> [String] {
                
        var shortStrings = [String]()
        
        for element in self {
            
            shortStrings.append(element.shortString(decimals: decimals, formatter: formatter))
            
        }
        
        return shortStrings
    }
    
    mutating func add(value: Double, index: Int) {
                
        if self.count > index {
            self[index] = value
        }
        else {
            self.append(value)
        }
    }

    func excludeQuintiles() -> [Double] {
                
        guard self.count > 4 else {
            return self
        }
        
        let sorted = self.sorted()
        
        let lower_quintile = Int(sorted.count/5)
        let upper_quintile = Int(sorted.count * 4/5)
        
        return Array(sorted[lower_quintile...upper_quintile])
    }
    
    func excludeQuartiles() -> [Double] {
                
        guard self.count > 3 else {
            return self
        }
        
        let sorted = self.sorted()
        
        let lower_quintile = Int(sorted.count/4)
        let upper_quintile = Int(sorted.count * 3/4)
        
        return Array(sorted[lower_quintile...upper_quintile])
    }
    
    func median() -> Double? {
        
        guard self.count > 1 else {
            return nil
        }
        
        let median = Int(self.count / 2)
        
        return self.sorted()[median]
    }
    
    func mean() -> Double? {
        
        guard self.count > 0 else {
            return nil
        }
        
        let sum = self.reduce(0, +)
        
        if count > 0 {
            return sum / Double(self.count)
        }
        else { return nil }
    }
    
    /// assumes (time) ordered array
    /// with element given the largest weights first and the smallest last
    /// (time) distance between array elements are assumed to be equal (e.g. one year)
    func weightedMean() -> Double? {
        
        guard self.count > 0 else {
            return nil
        }
        
        
        var sum = 0.0
        var weightSum = 0.0

        for i in 0..<self.count {
            if self[i] != Double() {
                let weight = (1/Double(i+1))
                sum += weight * self[i]
                weightSum += weight
            }
        }
        
        if weightSum > 0 {
            return sum / weightSum
        }
        else { return nil }
    }
    
    func average(of first: Int) -> Double? {
    
        guard first > 1 else {
            return nil
        }
        
        guard first < self.count else {
            return nil
        }
        
        var sum = 0.0
        for i in 0..<first {
            sum += self[i]
        }
        
        return sum / (Double(first))
    }
    
    /// assumes array is in DESCENDING order
    /// periods is the number of elements to build a moving average for
    /// periods must be greater thn 2 and smaller than array.count-2
    /// use reverse() if it isn't
    func ema(periods: Int) -> Double? {
        
        guard periods > 2 else { return nil }
        
        let noNaN = self.filter { element in
            if !element.isNaN { return true }
            else { return false }
        }
        
        var appliedPeriods = periods
        if noNaN.count < periods+2 {
            appliedPeriods = Int(Double(noNaN.count * 7/12))
            
        }
        
        guard appliedPeriods > 2 else {
            return nil
        }
        
        let ascending = Array(noNaN.reversed())
        
        var sum = Double()
        for i in 0..<appliedPeriods {
            sum += ascending[i]
        }
        let sma = sum / Double(appliedPeriods)
        
        var ema = sma
        
        for i in appliedPeriods..<noNaN.count {
            if ascending[i] != Double() {
//                print()
//                print(ema, ascending[i])
                ema = ascending[i] * (2/(Double(appliedPeriods+1))) + ema * (1 - 2/(Double(appliedPeriods+1)))
//                print(ema)
            }
        }
        
        return ema
    }
    
    func stdVariation() -> Double? {
        
        guard self.count > 1 else {
            return nil
        }
        
        guard let mean = self.mean() else {
            return nil
        }
        
        var differenceSquares = [Double]()
        
        for element in self {
            differenceSquares.append((element - mean) * (element - mean))
        }
        
        let variance = differenceSquares.reduce(0, +)
        
        return sqrt(variance)
    }

    
    /// calculates growth rates from current to preceding element
    /// should have elemetns in time-descending order!
    /// return n-1 elements
    /// can include empty placeholder Double() elements instead of nil
    func growthRates(dateOrder:Order?=nil) -> [Double]? {
        
        guard self.count > 1 else {
            return nil
        }
        
        var rates = [Double]()
        
        if dateOrder ?? .descending == .descending {
            for i in 0..<self.count - 1 {
                if self[i] == Double() {
                    rates.append(Double())
                }
                else if self[i+1] != 0 {
                    rates.append((self[i] - self[i+1]) / abs(self[i+1]))
                }
                else { rates.append(Double()) }
            }
        }
        else {
            for i in 0..<self.count {
                if (i + 1) < self.count {
                    rates.append((self[i+1] - self[i]) / self[i])
                }
            }
        }

        return rates
    }
    
    /// can include empty placeholder Double() elements instead of nil
    func positives() -> [Double]? {
        
        guard self.count > 1 else {
            return nil
        }

        let max = self.max()!
        let min = self.min()!
        
        if max * min > 0 {
            // either all values positive or all  negative
            
            return self.compactMap{ abs($0) }
        }
        else {
            // either 0 (shouldn't) or some postive and some negative values
            return self.compactMap{ $0 * -1 }
        }
    }

    /// returns the fraction of elements that are same or higher than the previous (if increaseIsBetter) or same or lower than previous (is iiB = false
    /// assumes array is DESCENDING in order
    /// return placeholder Double() if unable to calculate
    func consistency(increaseIsBetter: Bool) -> Double {
        
        let nonNilElements = self.compactMap({$0})
        let noPlaceHolderElements = nonNilElements.filter { element in
            if element == Double() { return false }
            else { return true }
        }
    
        guard noPlaceHolderElements.count > 1 else {
            return Double()
        }
        
        var lastNonNilElement = noPlaceHolderElements[0]
        
        var consistentCount = 1
        for i in 1..<noPlaceHolderElements.count {
            if increaseIsBetter {
                if noPlaceHolderElements[i] <= lastNonNilElement { // DESCENDING order!
                    consistentCount += 1
                }
            }
            else {
                if noPlaceHolderElements[i] >= lastNonNilElement {
                    consistentCount += 1
                }
            }
            lastNonNilElement = noPlaceHolderElements[i]
        }
        
        return Double(consistentCount) / Double(nonNilElements.count)
    }

}

extension Array where Element == Double? {
    
    /// returns fraction number  with 'B', 'M', 'K' or no letter at the end
    /// for nil values returns empty String element
    func shortStrings(decimals: Int, formatter: NumberFormatter?=nil ,nilString: String? = "-") -> [String] {
                
        var shortStrings = [String]()
        
        for element in self {
            
            shortStrings.append(element.shortString(decimals: decimals, formatter: formatter))
            
        }
        
        return shortStrings
    }

    /// calculates growth rates from current to next element
    /// should have elemetns in descending order!
    /// i.e. the following element is younger/ usually smaller
    /// return n-1 elements
    func growthRates() -> [Double?]? {
        
        guard self.count > 1 else {
            return nil
        }
        
        var rates = [Double?]()
        
        var hold: Double?
        var steps = 1
        for i in 0..<self.count - 1 {
            if let valid = hold ?? self[i] {
                if let validNext = self[i+1] {
                    for _ in 0..<steps {
                        rates.append((valid - validNext) / (validNext * Double(steps)))
                    }
                    hold = nil
                    steps = 1
                }
                else {
                    // validNext empty
                    hold = valid
                    steps += 1
                }
            }
            else {
                // valid empty
                rates.append(nil)
            }
        }

        return rates
    }
    
    /// calculates the absolute growth = difference element to previous element
    /// array should be sorted in DESCENDING order
    /// returns n-1 elements
    func growth() -> [Double?]? {
        
        guard self.count > 1 else {
            return nil
        }

        var difference = [Double?]()
        var hold: Double?
        var steps = 1
        for i in 0..<self.count - 1 {
            if let valid = hold ?? self[i] {
                if let validNext = self[i+1] {
                    for _ in 0..<steps {
                        difference.append((valid - validNext) / Double(steps))
                    }
                    hold = nil
                    steps = 1
                }
                else {
                    // validNext empty
                    hold = valid
                    steps += 1
                }
            }
            else {
                // valid empty
                difference.append(nil)
            }
        }

        return difference
    }
    
    /// assumes (time) ordered array
    /// with element given the largest weights first and the smallest last
    /// (time) distance between array elements are assumed to be equal (e.g. one year)
    func weightedMean() -> Double? {
        
        guard self.count > 0 else {
            return nil
        }
        
        var sum = 0.0
        var weightSum = 0.0

        for i in 0..<self.count {
            if let valid = self[i] {
                let weight = (1/Double(i+1))
                sum += weight * valid
                weightSum += weight
            }
        }
        
        if weightSum > 0 {
            return sum / weightSum
        }
        else { return nil }
    }
        
    func mean() -> Double? {
        
        guard self.count > 0 else {
            return nil
        }
        
        let sum = self.compactMap{$0}.reduce(0, +)
        
        var validsCount = 0.0
        
        for element in self {
            if element != nil {
                validsCount += 1.0
            }
        }
        
        if validsCount > 0 {
            return sum / validsCount
        }
        else { return nil }
    }

    
    func stdVariation() -> Double? {
        
        guard self.count > 1 else {
            return nil
        }
        
        guard let mean = self.mean() else {
            return nil
        }
        
        var differenceSquares = [Double]()
        var validsCount = 0.0
        
        for element in self {
            if element != nil {
                validsCount += 1.0
                differenceSquares.append((element! - mean) * (element! - mean))
            }
        }
        
        let variance = differenceSquares.reduce(0, +)
        
        return sqrt(variance)
    }
    
    func excludeQuartiles() -> [Double] {
                
        let cleaned = self.compactMap{$0}
        
        guard cleaned.count > 3 else {
            return cleaned
        }
        
        let sorted = cleaned.sorted()
        
        let lower_quintile = Int(sorted.count/4)
        let upper_quintile = Int(sorted.count * 3/4)
        
        var array = [Double]()
        for i in lower_quintile...upper_quintile {
            array.append(sorted[i])
        }
        
        return array
    }
    
    /// for odd-number array provides true median
    /// for even number array provides average of two middle-elements
    func median() -> Double? {
        
        guard self.count > 0 else {
            return nil
        }
        
        guard self.count > 1 else {
            return self[0]
        }
        
        var median: Double?
        
        let ranked = self.compactMap { $0 }.sorted()
        let medianElement = Double(ranked.count) / 2.0
        if medianElement != Double(Int(medianElement)) {
            // odd number of elements
            median = ranked[Int(medianElement)]
        } else {
            // even number - use average of two center elements
            median = (ranked[Int(medianElement)] + ranked[Int(medianElement)+1]) / 2
        }
        
        return median
    }
    
    /// returns the fraction of elements that are same or higher than the previous (if increaseIsBetter) or same or lower than previous (is iiB = false
    /// assumes array is DESCENDING in order
    func consistency(increaseIsBetter: Bool) -> Double? {
        
        let nonNilElements = self.compactMap({$0})
        let noPlaceHolderElements = nonNilElements.filter { element in
            if element == Double() { return false }
            else { return true }
        }
    
        guard noPlaceHolderElements.count > 1 else {
            return nil
        }
        
        var lastNonNilElement = noPlaceHolderElements[0]
        
        var consistentCount = 1
        for i in 1..<noPlaceHolderElements.count {
            if increaseIsBetter {
                if noPlaceHolderElements[i] >= lastNonNilElement {
                    consistentCount += 1
                }
            }
            else {
                if noPlaceHolderElements[i] <= lastNonNilElement {
                    consistentCount += 1
                }
            }
            lastNonNilElement = noPlaceHolderElements[i]
        }
        
        return Double(consistentCount) / Double(nonNilElements.count)
    }
}

extension UILabel {
    /// Sets the attributedText property of UILabel with an attributed string
    /// that displays the characters of the text at the given indices in subscript.
    func setAttributedTextWithSuperscripts(text: String, indicesOfSuperscripts: [Int]) {
        let font = self.font!
        let subscriptFont = font.withSize(font.pointSize * 0.7)
        let subscriptOffset = font.pointSize * 0.3
        let attributedString = NSMutableAttributedString(string: text,
                                                         attributes: [.font : font])
        for index in indicesOfSuperscripts {
            let range = NSRange(location: index, length: 1)
            attributedString.setAttributes([.font: subscriptFont,
                                            .baselineOffset: subscriptOffset],
                                           range: range)
        }
        self.attributedText = attributedString
    }
}

//
//  HTTPCookie+Arquiver.swift
//  Created by Antoine Barrault on 17/01/2018.
//

extension HTTPCookie {

    fileprivate func save(cookieProperties: [HTTPCookiePropertyKey : Any]) -> Data? {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: cookieProperties, requiringSecureCoding: false)
            return data
        } catch let error {
            ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error converting website cookies into data object")
        }
        return nil
    }

    static fileprivate func loadCookieProperties(from data: Data) -> [HTTPCookiePropertyKey : Any]? {
        do {
            let unarchivedDictionary = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [HTTPCookiePropertyKey : Any]
            return unarchivedDictionary
        } catch let error {
            ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error converting website cookies into data object")
        }
        return nil
    }

    static func loadCookie(using data: Data?) -> HTTPCookie? {
        guard let data = data,
            let properties = loadCookieProperties(from: data) else {
                return nil
        }
        return HTTPCookie(properties: properties)
    }

    func archive() -> Data? {
        guard let properties = self.properties else {
            return nil
        }
        return save(cookieProperties: properties)
    }

}

extension UIImage {
    
    func getPixelColor(pos: CGPoint) -> UIColor {
        
        guard !pos.y.isNaN else {
            return UIColor.systemBackground
        }
        
        let pixelData = self.cgImage!.dataProvider!.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        let pixelInfo: Int = ((Int(self.size.width) * Int(pos.y)) + Int(pos.x)) * 4
        
        let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

extension UIView {
    func getPixelColor(fromPoint: CGPoint) -> UIColor {
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitMapInfo =  CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        var pixel: [CUnsignedChar] = [0,0,0,0]
        
        let context = CGContext(data: &pixel,width: 1,height: 1,bitsPerComponent: 8,bytesPerRow: 4, space: colorSpace, bitmapInfo: bitMapInfo.rawValue)
        context?.translateBy(x: -fromPoint.x, y: -fromPoint.y)
        self.layer.render(in: context!)
        
        let r = CGFloat(pixel[0]) / CGFloat(255.0)
        let g = CGFloat(pixel[1]) / CGFloat(255.0)
        let b = CGFloat(pixel[2]) / CGFloat(255.0)
        let a = CGFloat(pixel[3]) / CGFloat(255.0)
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

extension Array where Element == CGFloat {
    
    func mean() -> CGFloat? {
        
        guard self.count > 0 else {
            return nil
        }
        
        let sum = self.reduce(0, +)
        
        if count > 0 {
            return sum / CGFloat(self.count)
        }
        else { return nil }
    }

}

extension String {
    
    func numbersOnly() -> String {
        return self.filter("-0123456789.".contains)
    }
    
    
    /// for english .separated double. Returns the number ^ exponent ?? 1
    func numberFromText(text: String, exponent: Double?=nil) -> Double {
        
        var value = Double()
        
        if self.filter("-0123456789.".contains) != "" {
            if let v = Double(self.filter("-0123456789.".contains)) {
              
                if self.last == "%" {
                    value = v / 100.0
                }
                else if self.uppercased().last == "T" {
                    value = v * pow(10.0, 12) // should be 12 but values are entered as '000
                } else if self.uppercased().last == "B" {
                    value = v * pow(10.0, 9) // should be 9 but values are entered as '000
                }
                else if self.uppercased().last == "M" {
                    value = v * pow(10.0, 6) // should be 6 but values are entered as '000
                }
                else if self.uppercased().last == "K" {
                    value = v * pow(10.0, 3) // should be 6 but values are entered as '000
                }
                // TODO: - removed for YahooPageExtraction - check compatibiity with MT data
//                else if text.contains("Beta") {
//                    value = v
//                }
//                else {
//                    value = v * (pow(10.0, exponent ?? 1.0))
//                }
                else {
                    value = v
                }
//
                if self.last == ")" {
                    value = v * -1
                }
                
            }
        }
        
        return value
    }
    
    /// for english .separated double. Takes into acount TBMK% at the end
    func textToNumber() -> Double? {
        
        var value: Double?
        let filter$ = "-0123456789."
        
        if self.filter(filter$.contains) != "" {
            if let v = Double(self.filter(filter$.contains)) {
              
                if self.last == "%" {
                    value = v / 100.0
                }
                else if self.uppercased().last == "T" {
                    value = v * pow(10.0, 12) // should be 12 but values are entered as '000
                } else if self.uppercased().last == "B" {
                    value = v * pow(10.0, 9) // should be 9 but values are entered as '000
                }
//                else if self.uppercased().last == "M" {
//                    value = v * pow(10.0, 6) // should be 6 but values are entered as '000
//                }
                else if self.uppercased().last == "K" {
                    value = v * pow(10.0, 3) // should be 6 but values are entered as '000
                }
                else if self.uppercased().contains("M") { // FraBo Pages, last char is space
                    value = v * pow(10.0, 6) // should be 6 but values are entered as '000
                }
                else if self.uppercased().contains("BN") { // FraBo Pages, , last char is space
                    value = v * pow(10.0, 9) // should be 6 but values are entered as '000
                }
                else {
                    value = v
                }
            }
        }
        
        return value
    }
    
}

extension [PricePoint] {
    
    /// if new PP have earlier and equal or later datre than existing one replaces exsting ones with new
    /// otherwise, filters out any new pricePoints that are earlier than the latest existing PricePoint
    func mergeIn(pricePoints: [PricePoint]?) -> [PricePoint] {
        
        guard let newPP = pricePoints else {
            return self
        }
        
        guard self.count > 0 else {
            return pricePoints ?? [PricePoint]()
        }
        
        let existingPriceDates = self.compactMap{ $0.tradingDate }
        let earliestExistingDate = existingPriceDates.min()!
        let latestExistingDate = existingPriceDates.max()!
 
        let newPriceDates = newPP.compactMap{ $0.tradingDate }
        let earliestNewDate = newPriceDates.min()!
        let latestNewDate = newPriceDates.max()!
        
        // if new pricePoints are from earlier as well equal/or later than current PP replace existing with newPP
        if earliestNewDate < earliestExistingDate {
            if latestExistingDate <= latestNewDate {
                print("replacing exisitng price points with new from \(earliestNewDate) -- to -- \(latestNewDate)")
                return newPP
            }
        }
        
        var merged = self
        let newerPricePoints = newPP.filter({ pp in
            if pp.tradingDate > latestExistingDate {
                return true
            } else { return false }
        })
        
        merged.append(contentsOf: newerPricePoints)
        
        return merged
    }
    
    func fillGaps(pricePoints: [PricePoint]?) -> [PricePoint] {
        
        guard let newPP = pricePoints else {
            return self
        }
        
        guard self.count > 0 else {
            return pricePoints ?? [PricePoint]()
        }
        
        var mergedPP = [PricePoint]()
        
        for nPP in newPP {
            
            let existing = self.filter({ ePP in
                if ePP.tradingDate == nPP.tradingDate { return true }
                else { return false }
            })
            
            if existing.count == 0 {
                mergedPP.append(nPP)
            }
            
        }
        
        return mergedPP
    }
}
