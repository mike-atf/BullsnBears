//
//  WebPageScraper2.swift
//  Bulls'N'Bears
//
//  Created by aDav on 04/11/2021.
//

import UIKit
import CoreData

@objc protocol DownloadRedirectionDelegate: URLSessionTaskDelegate {
    
    func awaitingRedirection(notification: Notification)
}

struct WebPageInfoDelimiters {
    
    var htmlText: String!
    var pageTitle: String?
    var sectionTitle: String?
    var rowTitle: String?
    var pageStartSequence: String?
    var tableTitle: String?
    var tableStartSequence: String?
    var tableEndSequence: String?
    var rowStartSequence: String?
    var rowEndSequence: String?
    var numberStartSequence: String?
    var numberEndSequence: String?
    var numberExponent: Double?=nil
    var textStartSequence: String?
    var textEndSequence: String?
    var pageType: Website!
    
    let numberEndSequence_Yahoo_default1 = "</span>"
    let numberStartSequence_Yahoo_default = ">"
    let numberEndSequence_Yahoo_default2 = "</span></div>"
    let tableStartSequence_yahoo_default = "<thead "
    let tableEndSequence_default = "</div></div></div></div>"
    let tableEndSequence_yahoo_default1 = "</p>"
    let tableEndSequence_yahoo_default2 = "</tbody><tfoot "
    let rowEndSequence_default = "</div></div></div>"
    let rowEndSequence_default2 =  "</span></div></div>"
    let rowEndSequence_yahoo_default1 = "</span></td>"
    let rowEndSequence_yahoo_default2 = "</span></td></tr>"
    let rowStartSequence_MT_default = "class=\"fas fa-chart-bar\"></i></div></div></div><div role="
    let rowStartSequence_yahoo_default = "Ta(start)"

    let rowEndSequence_Yahoo_default = "\""
    let textStartSequence_yahoo_default = "\""
    let textEndSequence_yahoo_default = "\""
    
    init(html$: String, pageType: Website,pageTitle:String?=nil, pageStarter:String?=nil, sectionTitle: String?=nil, tableTitle:String?=nil, tableStarter:String?=nil, tableEnd:String?=nil, rowTitle:String?=nil, rowStart:String?=nil, rowEnd:String?=nil, numberStart:String?=nil, numberEnd:String?=nil, exponent: Double?=nil, textStart: String?=nil, textEnd:String?=nil) {
        
        self.htmlText = html$
        self.pageType = pageType
        self.pageTitle = pageTitle
        self.pageStartSequence = pageStarter
        self.sectionTitle = (sectionTitle != nil) ? (">" + sectionTitle!) : nil
        self.tableTitle = tableTitle
        self.tableStartSequence = tableStarter
        self.tableEndSequence = tableEnd ?? tableEndSequence_default
        self.rowTitle = rowTitle
        if rowStart != nil {
            self.rowStartSequence = (pageType == .macrotrends) ? (">" + rowStart! + "<") : rowStart!
        } else {
            self.rowStartSequence = (pageType == .macrotrends) ? rowStartSequence_MT_default : nil
        }
        self.rowEndSequence = rowEnd ?? rowEndSequence_default
        self.numberStartSequence = numberStart
        self.numberEndSequence = numberEnd
        self.numberExponent = exponent
        self.textStartSequence = textStart
        self.textEndSequence = textEnd
        
    }
    
}

class WebPageScraper2: NSObject {
    
    var progressDelegate: ProgressViewDelegate?
    
    /// use this to create an instance if you don't wish to use the class functions
    init(progressDelegate: ProgressViewDelegate?) {
        self.progressDelegate = progressDelegate
    }
    //MARK: - specific task functions
    
    /// returns historical pe ratios and eps TTM with dates from macro trends website
    /// in form of [DatedValues] = (date, epsTTM, peRatio )
    /// ; optional parameter 'date' returns values back to this date and the first set before.
    /// ; throws downlad and analysis errors, which need to be caught by cailler
    class func getHxEPSandPEData(url: URL, companyName: String, until date: Date?=nil, downloadRedirectDelegate: DownloadRedirectionDelegate) async throws -> [Dated_EPS_PER_Values]? {
        
            var htmlText:String?
            var tableText = String()
            var tableHeaderTexts = [String]()
            var datedValues = [Dated_EPS_PER_Values]()
//            let title = companyName.capitalized(with: .current)
            let downloader = Downloader(task: .epsPER)
        
            do {
                // to catch any redirections
                NotificationCenter.default.addObserver(downloadRedirectDelegate, selector: #selector(DownloadRedirectionDelegate.awaitingRedirection(notification:)), name: Notification.Name(rawValue: "Redirection"), object: nil)
                
                htmlText = try await downloader.downloadDataWithRedirection(url: url)
            } catch let error as InternalErrorType {
                throw error
            }
        
            guard let validPageText = htmlText else {
                throw InternalErrorType.generalDownloadError // possible result of MT redirection
//                return nil
            }
                
            do {
                tableText = try await extractTable(title:"PE Ratio Historical Data", html: validPageText) // \(title)
            } catch let error as InternalErrorType {
                throw error
            }

            do {
                tableHeaderTexts = try await extractHeaderTitles(html: tableText)
            } catch let error as InternalErrorType {
                throw error
            }
            
            if tableHeaderTexts.count > 0 && tableHeaderTexts.contains("Date") {
                do {
                    datedValues = try extractTableData(html: validPageText, titles: tableHeaderTexts, untilDate: date)
                    return datedValues
                } catch let error as InternalErrorType {
                   throw error
                }
            } else {
                throw InternalErrorType.htmTablelHeaderStartNotFound
            }

    }
    
    /// returns quarterly eps  with dates from macro trends website
    /// in form of [DatedValues] = (date, eps )
    /// ; optional parameter 'date' returns values back to this date and the first set before.
    /// ; throws downlad and analysis errors, which need to be caught by cailler
    class func getqEPSDataFromMacrotrends(url: URL, companyName: String, until date: Date?=nil, downloadRedirectDelegate: DownloadRedirectionDelegate) async throws -> [DatedValue]? {
        
            var htmlText:String?
            var datedValues = [DatedValue]()
            let downloader = Downloader(task: .qEPS)
        
            do {
                // to catch any redirections
                NotificationCenter.default.addObserver(downloadRedirectDelegate, selector: #selector(DownloadRedirectionDelegate.awaitingRedirection(notification:)), name: Notification.Name(rawValue: "Redirection"), object: nil)
                
                htmlText = try await downloader.downloadDataWithRedirection(url: url)
            } catch let error as InternalErrorType {
                throw error
            }
        
            guard let validPageText = htmlText else {
                throw InternalErrorType.generalDownloadError // possible result of MT redirection
            }
                
            do {
                let formatter = DateFormatter()
                formatter.dateFormat = "y-M-d"
                let extractionCodes = WebpageExtractionCodes(tableTitle: "Quarterly EPS", option: .macroTrends, rowStartSequence: "\">", dateFormatter: formatter)
                datedValues = try extractQEPSTableData(html: validPageText, extractionCodes: extractionCodes,untilDate: date)
                return datedValues
            } catch let error as InternalErrorType {
               throw error
            }

    }
    
    /// default for MacroTrends table
    /// should have caller be Download Redirefction delegate as NotificationCenter observer
    class func getqColumnTableData(url: URL, companyName: String, tableHeader: String , dateColumn: Int, valueColumn: Int, until date: Date?=nil) async throws -> [DatedValue]? {
        
            var htmlText:String?
            var datedValues: [DatedValue]?
            let downloader = Downloader(task: .healthData)
        
           do {
               htmlText = try await downloader.downloadDataWithRedirection(url: url)
            } catch let error as InternalErrorType {
                throw error
            }
        
            guard let validPageText = htmlText else {
                throw InternalErrorType.generalDownloadError // possible result of MT redirection
            }
                
            do {
                datedValues = try extractColumnsValuesFromTable(html$: validPageText, tableHeader: tableHeader, dateColumn: dateColumn, valueColumn: valueColumn, until: date)
                return datedValues
            } catch let error as InternalErrorType {
               throw error
            }

    }

    
    /// returns historical pe ratios and eps TTM with dates from macro trends website
    /// in form of [DatedValues] = (date, epsTTM, peRatio )
    /// ; optional parameter 'date' returns values back to this date and the first set before.
    /// ; throws downlad and analysis errors, which need to be caught by cailler
    class func getHxEPSandPEDataNasdaq(url: URL, companyName: String, until date: Date?=nil, downloadRedirectDelegate: DownloadRedirectionDelegate) async throws -> [Dated_EPS_PER_Values]? {
        
            var htmlText:String?
            var tableText = String()
            var tableHeaderTexts = [String]()
            var datedValues = [Dated_EPS_PER_Values]()
//            let title = companyName.capitalized(with: .current)
            let downloader = Downloader(task: .epsPER)
        
            do {
                // to catch any redirections
                NotificationCenter.default.addObserver(downloadRedirectDelegate, selector: #selector(DownloadRedirectionDelegate.awaitingRedirection(notification:)), name: Notification.Name(rawValue: "Redirection"), object: nil)
                
                htmlText = try await downloader.downloadDataWithRedirection(url: url)
            } catch let error as InternalErrorType {
                throw error
            }
        
            guard let validPageText = htmlText else {
                throw InternalErrorType.generalDownloadError // possible result of MT redirection
//                return nil
            }
                
            do {
                tableText = try await extractTable(title:"Quarterly Earnings Surprise Amount", html: validPageText) // \(title)
            } catch let error as InternalErrorType {
                throw error
            }

            do {
                tableHeaderTexts = try await extractHeaderTitles(html: tableText)
            } catch let error as InternalErrorType {
                throw error
            }
            
            if tableHeaderTexts.count > 0 && tableHeaderTexts.contains("Date") {
                do {
                    datedValues = try extractTableData(html: validPageText, titles: tableHeaderTexts, untilDate: date)
                    return datedValues
                } catch let error as InternalErrorType {
                   throw error
                }
            } else {
                throw InternalErrorType.htmTablelHeaderStartNotFound
            }

    }

    
    class func getCurrentPrice(url: URL) async throws -> Double? {
        
        var htmlText = String()

        do {
            htmlText = try await Downloader.downloadData(url: url)
            if let values = scrapeRowForDoubles(website: .yahoo, html$: htmlText, rowTitle: "currentPrice" , rowTerminal: "}",  numberStarter: ":", numberTerminal: "\"") {

                return values.first
            } else {
                return nil
            }
        } catch let error as InternalErrorType {
            ErrorController.addInternalError(errorLocation: "WebScraper2.getCurretnPrice", systemError: error, errorInfo: "error downloading current price data from \(url)")
            throw error
        }

    }
    
    class func downloadAndAnalyseProfile(url: URL) async throws -> ProfileData? {
        
        var htmlText = String()

        do {
            htmlText = try await Downloader.downloadData(url: url)
        } catch let error as InternalErrorType {
            ErrorController.addInternalError(errorLocation: "WebScraper2.getCurretnPrice", systemError: error, errorInfo: "error downloading current price data from \(url)")
            throw error
        }

        
        let rowTitles = ["\"sector\":", "\"industry\":", "\"fullTimeEmployees\""] // titles differ from the ones displayed on webpage!
        
        var sector = String()
        var industry = String()
        var employees = Double()
        
        for title in rowTitles {
            
            let pageText = htmlText
            
            
            if title.starts(with: "\"sector") {
                let strings = try scrapeRowForText(html$: pageText, rowTitle: title , rowTerminal: ",", textTerminal: "\"")

                if let valid = strings.first {
                        sector = valid
                }
            } else if title.starts(with: "\"industry") {
                let strings = try scrapeRowForText(html$: pageText, rowTitle: title , rowTerminal: ",", textTerminal: "\"")

                
                if let valid = strings.first {
                        industry = valid
                }
            } else if title.starts(with: "\"fullTimeEmployees") {
                if let values = scrapeYahooRowForDoubles(html$: pageText, rowTitle: title , rowTerminal: "\"", numberTerminal: ",") {
                
                    if let valid = values.first {
                            employees = valid
                    }
                }
            }
        }
        
        return ProfileData(sector: sector, industry: industry, employees: employees)
    }
    
    class func r1DataDownloadAndSave(shareSymbol: String?, shortName: String?, valuationID: NSManagedObjectID, progressDelegate: ProgressViewDelegate?=nil, downloadRedirectDelegate: DownloadRedirectionDelegate) async throws {
        
        guard let symbol = shareSymbol else {
            progressDelegate?.downloadError(error: InternalErrorType.shareSymbolMissing.localizedDescription)
            throw InternalErrorType.shareSymbolMissing
        }
        
        guard let shortName = shortName else {
            progressDelegate?.downloadError(error: InternalErrorType.shareShortNameMissing.localizedDescription)
            throw InternalErrorType.shareShortNameMissing
        }
        
        var hyphenatedShortName = String()
        let shortNameComponents = shortName.split(separator: " ")
        hyphenatedShortName = String(shortNameComponents.first ?? "").lowercased()
        guard hyphenatedShortName != "" else {
            progressDelegate?.downloadError(error: InternalErrorType.shareShortNameMissing.localizedDescription)
            throw InternalErrorType.shareShortNameMissing
        }
        
        for index in 1..<shortNameComponents.count {
            if !shortNameComponents[index].contains("(") {
                hyphenatedShortName += "-" + String(shortNameComponents[index]).lowercased()
            }
        }

        var results = [LabelledValues]()
        let allTasks = 5
        var progressTasks = 0

// 1 Download and analyse web page data first MT then Yahoo
// MacroTrends downloads for Rule1 Data
        let rowTitles = [["Revenue","EPS - Earnings Per Share","Net Income"],["ROI - Return On Investment","Book Value Per Share","Operating Cash Flow Per Share"],["Long Term Debt"]] // ,["PE Ratio Historical Data"]
        var sectionCount = 0
        let downloader = Downloader(task: .r1Valuation)
        for pageName  in ["financial-statements", "financial-ratios", "balance-sheet"] {
            
            var components: URLComponents?
            components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(symbol)/\(hyphenatedShortName)/" + pageName)
            
            guard let url = components?.url else {
                progressDelegate?.downloadError(error: InternalErrorType.urlInvalid.localizedDescription)
                throw InternalErrorType.urlInvalid
            }
            
            var htmlText: String?

            do {
                NotificationCenter.default.addObserver(downloadRedirectDelegate, selector: #selector(DownloadRedirectionDelegate.awaitingRedirection(notification:)), name: Notification.Name(rawValue: "Redirection"), object: nil)
                
                htmlText = try await downloader.downloadDataWithRedirection(url: url)
            } catch let error as InternalErrorType {
                progressDelegate?.downloadError(error: error.localizedDescription)
                throw error
            }
            
            guard let pageText = htmlText else {
                continue
            }

            progressTasks += 1
            progressDelegate?.progressUpdate(allTasks: allTasks, completedTasks: progressTasks)
            
            let labelledDatedValues = try await extractDatedValuesFromMTTable(htmlText: pageText, rowTitles: rowTitles[sectionCount])
            
            // remove dates
            var dateSet = Set<Date>()
            var labelledValues = [LabelledValues]()
            for value in labelledDatedValues {
                var newLV = LabelledValues(label: value.label, values: [Double]())
                let values = value.datedValues.compactMap{ $0.value }
                let dates = value.datedValues.compactMap{ $0.date }
                newLV.values = values
                labelledValues.append(newLV)
                dateSet.formUnion(dates)
            }
            results.append(contentsOf: labelledValues)
                        
            progressTasks += 1
            progressDelegate?.progressUpdate(allTasks: allTasks, completedTasks: progressTasks)
            
            sectionCount += 1
        }
        
// MT download for PE Ratio in different format than 'Financials'
        for pageName in ["pe-ratio"] {
            var components: URLComponents?
            components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(symbol)/\(hyphenatedShortName)/" + pageName)
            
            guard let url = components?.url else {
                progressDelegate?.downloadError(error: InternalErrorType.urlInvalid.localizedDescription)
                throw InternalErrorType.urlInvalid
            }
            
            // the following values are NOT ANNUAL but quarterly, sort of!
            let values = try await getHxEPSandPEData(url: url, companyName: hyphenatedShortName.capitalized, until: nil, downloadRedirectDelegate: downloadRedirectDelegate)
            var newLabelledValues = LabelledValues(label: "PE Ratio Historical Data", values: [Double]())

            if let per = values?.compactMap({ $0.peRatio }) {
                newLabelledValues.values = per
            }
            
            results.append(newLabelledValues)
        }

// Yahoo downloads for Rule1 Data
        for pageName in ["analysis", "cash-flow","insider-transactions"] {
            
            var components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)/\(pageName)")
            components?.queryItems = [URLQueryItem(name: "p", value: symbol)]
            
            guard let url = components?.url else {
                progressDelegate?.downloadError(error: InternalErrorType.urlInvalid.localizedDescription)
                throw InternalErrorType.urlInvalid
            }

            var htmlText = String()

            do {
                htmlText = try await Downloader.downloadData(url: url)
            } catch let error as InternalErrorType {
                progressDelegate?.downloadError(error: error.localizedDescription)
                throw error
            }

            progressTasks += 1
            progressDelegate?.progressUpdate(allTasks: allTasks, completedTasks: progressTasks)

            if let labelledResults = rule1DataExtraction(htmlText: htmlText, section: pageName) {
                results.append(contentsOf: labelledResults)
            }
            progressTasks += 1
            progressDelegate?.progressUpdate(allTasks: allTasks, completedTasks: progressTasks)
        }

        // 2 Save R1 data to background R!Valuation
        let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc.automaticallyMergesChangesFromParent = true
        
        await backgroundMoc.perform {

            do {
                if let r1v = backgroundMoc.object(with: valuationID) as? Rule1Valuation {
                        
                        for result in results {
                            switch result.label {
                            case "Revenue":
                                r1v.revenue = result.values
                            case "EPS - Earnings Per Share":
                                r1v.eps = result.values
                            case "Net Income":
                                if let value = result.values.first {
                                    r1v.netIncome = value * pow(10, 3)
                                }
                            case "ROI - Return On Investment":
                                r1v.roic = result.values.compactMap{ $0/100.0 }
                            case "Book Value Per Share":
                                r1v.bvps = result.values
                            case "Operating Cash Flow Per Share":
                                r1v.opcs = result.values
                            case "Long Term Debt":
                                let cleanedResult = result.values.filter({ (element) -> Bool in
                                    return element != Double()
                                })
                                if let debt = cleanedResult.first {
                                    r1v.debt = debt * 1000
                                }
                            case "PE Ratio Historical Data":
                                r1v.hxPE = result.values
                            case "Sales growth (year/est)":
                                r1v.growthEstimates = result.values
                            case "Operating cash flow":
                                r1v.opCashFlow = result.values.first ?? Double()
                            case "Purchases":
                                r1v.insiderStockBuys = result.values.last ?? Double()
                            case "Sales":
                                r1v.insiderStockSells = result.values.last ?? Double()
                            case "Total insider shares held":
                                r1v.insiderStocks = result.values.last ?? Double()
                            default:
                                ErrorController.addInternalError(errorLocation: "WebPageScraper2.r1DataDownload", systemError: nil, errorInfo: "unspecified result label \(result.label) for share \(symbol)")
                            }
                        }
                        
                        r1v.creationDate = Date()
                        try backgroundMoc.save()
                    
                    // save new value with date in a share trend
                    if let vShare = r1v.share {
                        if let moat = r1v.moatScore() {
                            let dv = DatedValue(date: r1v.creationDate!, value: moat)
                            vShare.saveTrendsData(datedValuesToAdd: [dv], trendName: .moatScore)
                        }
                        let (price,_) = r1v.stickerPrice()
                        if price != nil {
                            let dv = DatedValue(date: r1v.creationDate!, value: price!)
                            vShare.saveTrendsData(datedValuesToAdd: [dv], trendName: .stickerPrice)
                        }
                    }

                    progressDelegate?.downloadComplete()
                }
            } catch let error {
                progressDelegate?.downloadError(error: error.localizedDescription)
                ErrorController.addInternalError(errorLocation: "WebPageScraper2.r1DataDownload", systemError: error, errorInfo: "Error saving R1 data download results for \(symbol)")
            }
        }
        
    }
    
    class func dcfDataDownloadAndSave(shareSymbol: String?, valuationID: NSManagedObjectID, progressDelegate: ProgressViewDelegate?=nil) async throws {
        
        guard let symbol = shareSymbol else {
            progressDelegate?.downloadError(error: "Failed DCF valuation download: missing share symbol")
            throw InternalErrorType.shareSymbolMissing
        }
         
 // 1 Download and analyse web page data
        var results = [LabelledValues]()
        let allTasks = 6
        var progressTasks = 0
        
        for title in ["key-statistics", "financials", "balance-sheet", "cash-flow", "analysis"] {
            var components: URLComponents?
                    
            components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)/\(title)")
            components?.queryItems = [URLQueryItem(name: "p", value: shareSymbol)]
                    
            guard let url = components?.url else {
                progressDelegate?.downloadError(error: "Failed DCF valuation download for \(symbol): invalid url")
                throw InternalErrorType.urlInvalid
            }
            
            var htmlText = String()
            do {
                htmlText = try await Downloader.downloadData(url: url)
            } catch let error as InternalErrorType {
                progressDelegate?.downloadError(error: "Failed DCF valuation download for \(symbol): \(error.localizedDescription)")
            }
            
            progressTasks += 1
            progressDelegate?.progressUpdate(allTasks: allTasks, completedTasks: progressTasks)
            
            let labelledResults = try dcfDataExtraction(htmlText: htmlText, section: title)
            results.append(contentsOf: labelledResults)
        }
        
// 2 Save data to background DCFValuation
        let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc.automaticallyMergesChangesFromParent = true
        
        await backgroundMoc.perform {
            do {
                if let dcfv = backgroundMoc.object(with: valuationID) as? DCFValuation {

                    do {
                        for result in results {
                            switch result.label {
                            case _ where result.label.starts(with: "Market cap (intra-day)"):
                                dcfv.marketCap = result.values.first ?? Double()
                            case _ where result.label.starts(with: "Beta (5Y monthly)"):
                                dcfv.beta = result.values.first ?? Double()
                            case _ where result.label.starts(with: "Shares outstanding"):
                                dcfv.sharesOutstanding = result.values.first ?? Double()
                            case _ where result.label.starts(with: "Total revenue"):
                                dcfv.tRevenueActual = result.values
                            case _ where result.label.starts(with: "Net income"):
                                dcfv.netIncome = result.values
                            case _ where result.label.starts(with: "Interest expense"):
                                dcfv.expenseInterest = result.values.first ?? Double()
                            case _ where result.label.starts(with: "Income before tax"):
                                dcfv.incomePreTax = result.values.first ?? Double()
                            case _ where result.label.starts(with: "Income tax expense"):
                                dcfv.expenseIncomeTax = result.values.first ?? Double()
                            case _ where result.label.starts(with: "Current debt"):
                                dcfv.debtST = result.values.first ?? Double()
                            case _ where result.label.starts(with: "Long-term debt"):
                                dcfv.debtLT = result.values.first ?? Double()
                            case _ where result.label.starts(with: "Total Debt"):
                                dcfv.totalDebt = result.values.first ?? Double()
                            case _ where result.label.starts(with: "Operating cash flow"):
                                dcfv.tFCFo = result.values
                            case _ where result.label.starts(with: "Capital expenditure"):
                                dcfv.capExpend = result.values
                            case _ where result.label.starts(with: "Avg. Estimate"):
                                dcfv.tRevenuePred = result.values
                            case _ where result.label.starts(with: "Sales growth (year/est)"):
                                dcfv.revGrowthPred = result.values
                            default:
                                ErrorController.addInternalError(errorLocation: "WebPageScraper2.dcfDataDownload", systemError: nil, errorInfo: "unspecified result label \(result.label) for share \(symbol)")
                            }
                        }
                        
                        dcfv.creationDate = Date()
                        try backgroundMoc.save()
                        
                        let (dcfValue, _) = dcfv.returnIValue()
                        if dcfValue != nil {
                            let trendValue = DatedValue(date: dcfv.creationDate!, value: dcfValue!)
                            dcfv.share?.saveTrendsData(datedValuesToAdd: [trendValue], trendName: .dCFValue)
                        }

                        progressDelegate?.downloadComplete()
                        
                    } catch let error {
                        ErrorController.addInternalError(errorLocation: "WebPageScraper2.dcfDataDownload", systemError: error, errorInfo: "Error saving DCF data download results for \(symbol)")
                    }
                   
                }
            }
        }
        
    }
    
    
    /// calls Downloader function with completion handler to return csv file
    /// returns extracted [DateValue] array through Notification with name ""TBOND csv file downloaded""
    class func downloadAndAanalyseTreasuryYields(url: URL) async {
        
       let treasuryCSVHeaderTitles = ["Date","\"1 Mo\"", "\"2 Mo\"","\"3 Mo\"","\"6 Mo\"","\"1 Yr\"","\"2 Yr\"","\"3 Yr\"","\"5 Yr\"","\"7 Yr\"","\"10 Yr\"","\"20 Yr\"","\"30 Yr\""]
        var datedValues: [DatedValue]?
        await Downloader.downloadAndReturnCSVFile(url: url, symbol: "TBonds", expectedHeaderTitles: treasuryCSVHeaderTitles, completion: { fileURL in
            datedValues = CSVImporter.extractTBondRatesFromCSVFile(url: fileURL, expectedHeaderTitles: treasuryCSVHeaderTitles)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "TBOND csv file downloaded"), object: datedValues, userInfo: nil)
        })
    }

    class func downloadAnalyseSaveWBValuationData(shareSymbol: String?, shortName: String?, valuationID: NSManagedObjectID, progressDelegate: ProgressViewDelegate?=nil, downloadRedirectDelegate: DownloadRedirectionDelegate) async throws {
        
//        print("downloadAnalyseSaveWBValuationData for \(shareSymbol ?? "")")
        
        guard let symbol = shareSymbol else {
            throw InternalErrorType.shareSymbolMissing
        }
        
        guard var sn = shortName else {
            throw InternalErrorType.shareShortNameMissing
        }
        
        if sn.contains(" ") {
            sn = sn.replacingOccurrences(of: " ", with: "-")
        }
        var downloadErrors: [InternalErrorType]?
        
        let webPageNames = ["financial-statements", "balance-sheet", "cash-flow-statement" ,"financial-ratios"]
        
        let rowNames = [["Revenue","Gross Profit","Research And Development Expenses","SG&A Expenses","Net Income", "Operating Income", "EPS - Earnings Per Share"],["Long Term Debt","Property, Plant, And Equipment","Retained Earnings (Accumulated Deficit)", "Share Holder Equity"],["Cash Flow From Investing Activities", "Cash Flow From Operating Activities"],["ROE - Return On Equity", "ROA - Return On Assets", "Book Value Per Share"]]
        
        var results = [LabelledValues]()
        var resultDates = [Date]()
        var sectionCount = 0
        let downloader: Downloader? = Downloader(task: .wbValuation)
        for section in webPageNames {
            
            if let components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(symbol)/\(sn)/\(section)")  {
                if let url = components.url  {
                    
                    NotificationCenter.default.addObserver(downloadRedirectDelegate, selector: #selector(DownloadRedirectionDelegate.awaitingRedirection(notification:)), name: Notification.Name(rawValue: "Redirection"), object: nil)

                    let htmlText = try await downloader?.downloadDataWithRedirection(url: url)
                    
                    if let validPageText = htmlText {
                        
                        let labelledDatedValues = try await WebPageScraper2.extractDatedValuesFromMTTable(htmlText: validPageText, rowTitles: rowNames[sectionCount])
                        
                        let labelledValues = labelledDatedValues.compactMap{ LabelledValues(label: $0.label, values: $0.datedValues.compactMap{ $0.value }) }
                        
                        var dates = [Date]()
                        for ldv in labelledDatedValues {
                            let extractedDates = ldv.datedValues.compactMap { $0.date }
                            dates.append(contentsOf: extractedDates)
                        }
                        resultDates.append(contentsOf: dates)
                        results.append(contentsOf: labelledValues)
                        
                        sectionCount += 1
                    }
                    else {
                        if downloadErrors == nil { downloadErrors = [InternalErrorType.generalDownloadError] }
                        else { downloadErrors?.append(InternalErrorType.generalDownloadError)}
                    }
                }
            }
        }
        
// Historical PE and EPS with dates
        var perAndEPSvalues: [Dated_EPS_PER_Values]?
        if let components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(symbol)/\(sn)/pe-ratio") {
            if let url = components.url {
                perAndEPSvalues = try await getHxEPSandPEData(url: url, companyName: sn, until: nil, downloadRedirectDelegate: downloadRedirectDelegate)
            }
        }
            
// Historical stock prices
        var hxPriceValues: [Double]?
        
        if let components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(symbol)/\(sn)/stock-price-history") {
            if let url = components.url {
                
                var htmlText = String()
                do {
                    htmlText = try await Downloader.downloadData(url: url)
                    
                    hxPriceValues = try macrotrendsScrapeColumn(html$: htmlText, tableHeader: "Historical Annual Stock Price Data</th>", tableTerminal: "</tbody>", columnTerminal: "</td>" ,noOfColumns: 7, targetColumnFromRight: 6)
                } catch let error as InternalErrorType {
                    if error == .generalDownloadError {
                        
                        let info = ["Redirection": "Object"]
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "Redirection"), object: info)
                        return
                    } else {
                        ErrorController.addInternalError(errorLocation: "WPS2.downloadAnalyseSaveWBValuationData", systemError: nil, errorInfo: "Error downloading historical price WB Valuation data: \(error.localizedDescription)")
                    }
                }
            }
        }
        

        let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc.automaticallyMergesChangesFromParent = true

        try await backgroundMoc.perform {

            do {

                if let wbv = backgroundMoc.object(with: valuationID) as? WBValuation {
                                                                
                        for result in results {
                            switch result.label {
                            case "Revenue":
                                wbv.revenue = result.values
                            case "Gross Profit":
                                wbv.grossProfit = result.values
                            case "Research And Development Expenses":
                                wbv.rAndDexpense = result.values
                            case "SG&A Expenses":
                                wbv.sgaExpense = result.values
                            case "Net Income":
                                wbv.netEarnings = result.values
                            case "Operating Income":
                                wbv.operatingIncome = result.values
                            case "EPS - Earnings Per Share":
                                wbv.eps = result.values
                            case "Long Term Debt":
                                wbv.debtLT = result.values
                            case "Property, Plant, And Equipment":
                                wbv.ppe = result.values
                            case "Retained Earnings (Accumulated Deficit)":
                                wbv.equityRepurchased = result.values
                            case "Share Holder Equity":
                                wbv.shareholdersEquity = result.values
                            case "Cash Flow From Investing Activities":
                                wbv.capExpend = result.values
                            case "Cash Flow From Operating Activities":
                                wbv.opCashFlow = result.values
                            case "ROE - Return On Equity":
                                wbv.roe = result.values
                            case "ROA - Return On Assets":
                                wbv.roa = result.values
                            case "Book Value Per Share":
                                wbv.bvps = result.values
                            default:
                                ErrorController.addInternalError(errorLocation: "WebScraper2.downloadAndAnalyseWBVData", systemError: nil, errorInfo: "undefined download result with title \(result.label)")
                            }
                        }
                        
                    wbv.latestDataDate = resultDates.max()
                    
                        if let validEPSPER = perAndEPSvalues {
                            let perDates: [DatedValue] = validEPSPER.compactMap{ DatedValue(date: $0.date, value: $0.peRatio) }
                            wbv.savePERWithDateArray(datesValuesArray: perDates, saveInContext: false)
                            let epsDates: [DatedValue] = validEPSPER.compactMap{ DatedValue(date: $0.date, value: $0.epsTTM) }
                            wbv.saveEPSTTMWithDateArray(datesValuesArray: epsDates, saveToMOC: false)
                        }
                        
                        wbv.avAnStockPrice = hxPriceValues?.reversed()
                        wbv.date = Date()
                    
                    if let vShare = wbv.share {
                        if let lynch = wbv.lynchRatio() {
                            let dv = DatedValue(date:wbv.date!, value: lynch)
                            vShare.saveTrendsData(datedValuesToAdd: [dv], trendName: .lynchScore)
                        }
                        let (ivalue,_) = wbv.ivalue()
                        if ivalue != nil {
                            let dv = DatedValue(date:wbv.date!, value: ivalue!)
                            vShare.saveTrendsData(datedValuesToAdd: [dv], trendName: .intrinsicValue)
                        }
                    }
                }
                try backgroundMoc.save()
            } catch let error {
                ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: error, errorInfo: "couldn't save background MOC")
            }
            
            
            if (downloadErrors ?? []).contains(InternalErrorType.generalDownloadError) {
                throw InternalErrorType.generalDownloadError
            }
        }
        
    }
    
    class func keyratioDownloadAndSave(shareSymbol: String?, shortName: String?, shareID: NSManagedObjectID) async throws {
        
        guard let symbol = shareSymbol else {
            throw InternalErrorType.shareSymbolMissing
        }
        
        guard var shortName = shortName else {
            throw InternalErrorType.shareShortNameMissing
        }
        
        if shortName.contains(" ") {
            shortName = shortName.replacingOccurrences(of: " ", with: "-")
        }
        
        guard var components = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)/key-statistics") else {
            throw InternalErrorType.urlInvalid
        }
        components.queryItems = [URLQueryItem(name: "p", value: symbol), URLQueryItem(name: ".tsrc", value: "fin-srch")]

        guard let url = components.url else {
            throw InternalErrorType.urlError
        }
        
        let htmlText = try await Downloader.downloadData(url: url)
                    
        let rowTitles = ["Beta (5Y monthly)", "Trailing P/E", "Diluted EPS", "Forward annual dividend yield"] // titles differ from the ones displayed on webpage!
        var results = [LabelledValues]()
        
        for title in rowTitles {
            var labelledValues = LabelledValues(title, [Double]())
            if let values = WebPageScraper2.scrapeRowForDoubles(website: .yahoo, html$: htmlText, rowTitle: ">" + title+"</span>" , rowTerminal: "</tr>", numberTerminal: "</td>") {
                labelledValues.values = values
            }
            results.append(labelledValues)
        }
        
        let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc.automaticallyMergesChangesFromParent = true
        
        await backgroundMoc.perform {
            
            do {
                if let bgShare = backgroundMoc.object(with: shareID) as? Share {
                    
                    for result in results {
                                    
                        if result.label.starts(with: "Beta") {
                            bgShare.beta = result.values.first ?? Double()
                        } else if result.label.starts(with: "Trailing") {
                            bgShare.peRatio = result.values.first ?? Double()
                        } else if result.label.starts(with: "Diluted") {
                            bgShare.eps = result.values.first ?? Double()
                        } else if result.label == "Forward annual dividend yield" {
                            bgShare.divYieldCurrent = result.values.first ?? Double()
                        } else {
                            ErrorController.addInternalError(errorLocation: "WebScraper2.keyratioDownload", systemError: nil, errorInfo: "undefined download result with title \(result.label)")
                        }
                    }
                    
                }
                
                try backgroundMoc.save()
                
            } catch let error {
                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "couldn't save background MOC")
            }
        }
    }
    
    class func downloadAndAnalyseDailyTradingPrices(shareSymbol: String, minDate:Date?=nil) async throws -> [PricePoint]? {

// 2 data download usually for the last 3 momnths or so
        var urlComponents = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(shareSymbol)/history?")
        urlComponents?.queryItems = [URLQueryItem(name: "p", value: shareSymbol)]
        
        
        guard let sourceURL = urlComponents?.url else {
            throw InternalError(location: "WebScraper2.downloadAndAnalyseDailyTradingPrices", errorInfo: "\(String(describing: urlComponents))", errorType: .urlInvalid)
        }
        
        let dataText = try await Downloader.downloadData(url: sourceURL)

        let downloadedPricePoints = analyseYahooPriceTable(html$: dataText)

        return downloadedPricePoints
    }
        
    //MARK: - general MacroTrend functions
    
    class func extractDatedValuesFromMTTable(htmlText: String, rowTitles: [String]) async throws -> [Labelled_DatedValues] {
        
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = NSLocale.current
            formatter.timeZone = NSTimeZone.local
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter
        }()

        guard let tableText = try extractMTTable2(htmlText: htmlText) else {
            throw InternalError(location: "WebScraper2.extractDatedValuesFromMTTable", errorInfo: "table text not extracted", errorType: .htmlTableTextNotExtracted)
        }
        
        var results = [Labelled_DatedValues]()
        for title in rowTitles {
            var labelledDV = Labelled_DatedValues(label: title, datedValues: [DatedValue]())
            if  let rowText = extractMTTableRowText(tableText: tableText, rowTitle: title) {
                let pairs = rowText.split(separator: ",")
                for pair in pairs {
                    var datedValue: DatedValue
                    let date_Value = pair.split(separator: ":")
                    guard let date$ = date_Value.first?.filter("-0123456789.".contains) else {
                        continue
                    }
                    guard let date = dateFormatter.date(from: String(date$)) else {
                        continue
                    }
                    guard let value$ = date_Value.last else {
                        continue
                    }
                    guard let value = Double(value$.filter("-0123456789.".contains)) else {
                        continue
                    }
                    
                    datedValue = DatedValue(date: date, value: value)
                    labelledDV.datedValues.append(datedValue)
                }
            }
            results.append(labelledDV)
        }
        
        return results
        
    }
    
    class func extractMTTableRowText(tableText: String, rowTitle: String) -> String? {

        let mtRowTitle = ">"+rowTitle+"<"
        let mtRowDataStart = "/div>\","
        let mtRowDataEnd = "},"
        let mtTableEndIndex = "}]"
        
        guard tableText.count > 0 else {
            return nil
        }

        guard let rowStartIndex = tableText.range(of: mtRowTitle) else {
            return nil
        }
        
        var rowDataEndIndex = tableText.range(of: mtRowDataEnd,options: [NSString.CompareOptions.literal], range: rowStartIndex.upperBound..<tableText.endIndex, locale: nil)
        
        if rowDataEndIndex == nil {
            rowDataEndIndex = tableText.range(of: mtTableEndIndex,options: [NSString.CompareOptions.literal], range: rowStartIndex.upperBound..<tableText.endIndex, locale: nil)
        }
        
        guard rowDataEndIndex != nil else {
            return nil
        }

        guard let rowDataStartIndex = tableText.range(of: mtRowDataStart,options: [NSString.CompareOptions.literal], range: rowStartIndex.upperBound..<rowDataEndIndex!.lowerBound, locale: nil) else {
            return nil
        }
        
        return String(tableText[rowDataStartIndex.upperBound..<rowDataEndIndex!.lowerBound])
    }
    
    /// for MT "Financials' only pages with titled rows and dated values
    class func extractMTTable2(htmlText: String) throws -> String? {
        
        let mtTableDataStart = "var originalData = ["
        let mtTableDataEnd = "}];"
        
        let pageText = htmlText
        
        guard pageText.count > 0 else {
            throw InternalErrorType.emptyWebpageText
        }
        
        guard let tableStartIndex = pageText.range(of: mtTableDataStart) else {
            throw InternalErrorType.htmlTableSequenceStartNotFound
        }
        
        guard let tableEndIndex = pageText.range(of: mtTableDataEnd,options: [NSString.CompareOptions.literal], range: tableStartIndex.upperBound..<pageText.endIndex, locale: nil) else {
            throw InternalErrorType.htmlTableEndNotFound
        }
        
        return String(pageText[tableStartIndex.upperBound...tableEndIndex.upperBound]) // lowerBound
    }
    
    /// for MT pages such as 'PE-Ratio' with dated rows and table header
    class func extractTable(title: String, html: String, tableStartSequence: String?=nil, tableEndSequence: String?=nil) async throws -> String {
        
        let tableTitle = title.replacingOccurrences(of: "-", with: " ")
        
        let startSequence = tableStartSequence ?? tableTitle
        
        let tableStartIndex = html.range(of: startSequence)
        
        if tableStartIndex == nil {
            throw InternalError(location: #function, errorInfo: "did not find \(String(describing: tableTitle)) in \(html)", errorType: .htmlTableTitleNotFound)
        }
        
        guard let tableEndIndex = html.range(of: tableEndSequence ?? "</table>",options: [NSString.CompareOptions.literal], range: tableStartIndex!.upperBound..<html.endIndex, locale: nil) else {
            throw InternalError(location: #function, errorInfo: "did not find \(String(describing: tableEndSequence)) in \(html)", errorType: .htmlTableEndNotFound)
        }
        
        let tableText = String(html[tableStartIndex!.upperBound..<tableEndIndex.lowerBound])

        return tableText
    }

    /// for MT pages such as 'PE-Ratio' with dated rows and table header, to assist 'extractTable' and 'extractTableData' func
    class func extractHeaderTitles(html: String) async throws -> [String] {
        
        let headerStartSequence = "</thead>"
        let headerEndSequence = "<tbody><tr>"
        let rowEndSequence = "</th>"
        
        guard let headerStartIndex = html.range(of: headerStartSequence) else {
            throw InternalErrorType.htmTablelHeaderStartNotFound
        }
        
        guard let headerEndIndex = html.range(of: headerEndSequence,options: [NSString.CompareOptions.literal], range: headerStartIndex.upperBound..<html.endIndex, locale: nil) else {
            throw InternalError(location: #function, errorInfo: "did not find \(String(describing: headerEndSequence)) in \(html)", errorType: .htmlTableHeaderEndNotFound)

        }
        
        var headerText = String(html[headerStartIndex.upperBound..<headerEndIndex.lowerBound])
        var rowStartIndex = headerText.range(of: "<th ", options: [NSString.CompareOptions.literal])
        var columnTitles = [String]()
        
        repeat {
            
            if let rsi = rowStartIndex {
                if let rowEndIndex = headerText.range(of: rowEndSequence,options: [NSString.CompareOptions.literal], range: rsi.lowerBound..<headerText.endIndex) {
                    
                    let rowText = String(headerText[rsi.upperBound..<rowEndIndex.lowerBound])
                    
                    if let valueStartIndex = rowText.range(of: "\">", options: .backwards) {
                        
                        let value$ = String(rowText[valueStartIndex.upperBound..<rowText.endIndex])
                        if value$ != "" {
                            columnTitles.append(value$)
                        }
                    }
                    headerText = String(headerText[rowEndIndex.lowerBound..<headerText.endIndex])
                    
                    rowStartIndex = headerText.range(of: "<th ", options: [NSString.CompareOptions.literal])
                    }
                else { break } // no rowEndIndex
            }
            else { break } // no rowStartIndex
        } while rowStartIndex != nil
        
        return columnTitles
    }

    /// for MT pages such as 'PE-Ratio' with dated rows and table header, to assist 'extractTable' and 'extractTableData' func
    class func extractTableData(html: String, titles: [String], untilDate: Date?=nil) throws -> [Dated_EPS_PER_Values] {
        
        let bodyStartSequence = "<tbody><tr>"
        let bodyEndSequence = "</tr></tbody>"
        let rowEndSequence = "</td>"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "y-M-d"
        
        var datedValues = [Dated_EPS_PER_Values]()
        
        guard let bodyStartIndex = html.range(of: bodyStartSequence) else {
            throw InternalError(location: #function, errorInfo: "did not find \(String(describing: bodyStartSequence)) in \(html)", errorType: .htmlTableBodyStartIndexNotFound)
        }
        
        guard let bodyEndIndex = html.range(of: bodyEndSequence,options: [NSString.CompareOptions.literal], range: bodyStartIndex.upperBound..<html.endIndex, locale: nil) else {
            throw InternalError(location: #function, errorInfo: "did not find \(String(describing: bodyEndSequence)) in \(html)", errorType: .htmlTableBodyEndIndexNotFound)
        }
        
        var tableText = String(html[bodyStartIndex.upperBound..<bodyEndIndex.lowerBound])
        var rowStartIndex = tableText.range(of: "<td ", options: [NSString.CompareOptions.literal])

        var columnCount = 0
        let columnsExpected = titles.count
        
        var date: Date?
        var epsValue: Double?
        var peValue: Double?

        outer: repeat {
            
            if let rsi = rowStartIndex {
                if let rowEndIndex = tableText.range(of: rowEndSequence,options: [NSString.CompareOptions.literal], range: rsi.lowerBound..<tableText.endIndex) {
                    
                    let rowText = String(tableText[rsi.upperBound..<rowEndIndex.lowerBound])
                    
                    if let valueStartIndex = rowText.range(of: "\">", options: .backwards) {
                        
                        let value$ = String(rowText[valueStartIndex.upperBound..<rowText.endIndex])

                        if (columnCount)%columnsExpected == 0 {
                            if let validDate = dateFormatter.date(from: String(value$)) {// date
                                date = validDate
                            }
                        }
                        else {
                            let value = Double(value$.filter("-0123456789.".contains)) ?? Double()

                            if (columnCount-2)%columnsExpected == 0 { // EPS value
                                epsValue = value
                            }
                            else if (columnCount+1)%columnsExpected == 0 { // PER value
                                peValue = value
                                if let validDate = date {
                                    let newDV = Dated_EPS_PER_Values(date: validDate,epsTTM: (epsValue ?? Double()),peRatio: (peValue ?? Double()))
                                    datedValues.append(newDV)
                                    if let minDate = untilDate {
                                        if minDate > validDate { return datedValues }
                                    }
                                    date = nil
                                    peValue = nil
                                    epsValue = nil

                                }
                            }
                        }
                    }
                    
                    tableText = String(tableText[rowEndIndex.lowerBound..<tableText.endIndex])
                    
                    rowStartIndex = tableText.range(of: "<td ", options: [NSString.CompareOptions.literal])

                }
                else { break } // no rowEndIndex
            }
            else { break } // no rowStartIndex
            columnCount += 1

            
        } while rowStartIndex != nil

        return datedValues
    }
    
    /// for MT pages such as 'PE-Ratio' with dated rows and table header, to assist 'extractTable' and 'extractTableData' func
    class func extractQEPSTableData(html: String, extractionCodes: WebpageExtractionCodes ,untilDate: Date?=nil) throws -> [DatedValue] {
        
        let bodyStartSequence = extractionCodes.bodyStartSequence
        let bodyEndSequence = extractionCodes.bodyEndSequence
        let rowEndSequence = extractionCodes.rowEndSequence
        
        var datedValues = [DatedValue]()
        
        let startSequence = extractionCodes.tableTitle ?? extractionCodes.tableStartSequence
        
        guard let tableStartIndex = html.range(of: startSequence) else {
            throw InternalError(location: #function, errorInfo: "did not find \(String(describing: startSequence)) in \(html)", errorType: .htmlTableTitleNotFound)
        }
        
        var tableText = String(html[tableStartIndex.upperBound..<html.endIndex])

        guard let bodyStartIndex = tableText.range(of: bodyStartSequence) else {
            throw InternalError(location: #function, errorInfo: "did not find \(String(describing: bodyStartSequence)) in \(tableText)", errorType: .htmlTableBodyStartIndexNotFound)
        }
        
        guard let bodyEndIndex = tableText.range(of: bodyEndSequence,options: [NSString.CompareOptions.literal], range: bodyStartIndex.upperBound..<tableText.endIndex, locale: nil) else {
            throw InternalError(location: #function, errorInfo: "did not find \(String(describing: bodyEndSequence)) in \(tableText)", errorType: .htmlTableBodyEndIndexNotFound)
        }
        
        
        tableText = String(tableText[bodyStartIndex.upperBound..<bodyEndIndex.lowerBound])
        var rowStartIndex = tableText.range(of: extractionCodes.rowStartSequence, options: [NSString.CompareOptions.literal])

        var columnCount = 0
        let columnsExpected = 2
        
        var date: Date?
        var epsValue: Double?

        outer: repeat {
            
            if let rsi = rowStartIndex {
                if let rowEndIndex = tableText.range(of: rowEndSequence, range: rsi.lowerBound..<tableText.endIndex) {
                    
                    var rowText = String(tableText[rsi.upperBound..<rowEndIndex.lowerBound])
                   
                    var valueStartIndex = rowText.range(of: extractionCodes.dataCellStartSequence)
                    inner: repeat {
//                        print("current rowText = \(rowText)")
                        if let vsi = valueStartIndex {
//                            print("found valueStart \(extractionCodes.dataCellStartSequence)")
                            if let valueEndIndex = rowText.range(of: extractionCodes.dataCellEndSequence, range: vsi.lowerBound..<rowText.endIndex) {

                                var value$ = String(rowText[vsi.upperBound..<valueEndIndex.lowerBound])
                                if let formatIndex = value$.range(of: "text-right") {
                                    value$ = String(value$[formatIndex.upperBound..<value$.endIndex])
                                }
//                                print(value$)

                                if columnCount%columnsExpected == 0 {
                                    let date$ = String(value$.dropFirst())
                                    date = extractionCodes.dateFormatter.date(from: date$)
//                                    print(date)
                                }
                                else if (columnCount+1)%columnsExpected == 0 { // EPS value
                                    epsValue = Double(value$.filter("-0123456789.".contains))
//                                    print(epsValue)
                                    if let validDate = date, let validValue = epsValue {
                                        let newDV = DatedValue(date: validDate, value: validValue)
                                        datedValues.append(newDV)
                                        if let minDate = untilDate {
                                            if minDate > validDate { return datedValues }
                                        }
                                    }
                                }
                                rowText = String(rowText[valueEndIndex.upperBound..<rowText.endIndex])
                            }
                            else {
                                ErrorController.addInternalError(errorLocation: #function, errorInfo: "missing valueEndIndex \(extractionCodes.dataCellEndSequence) for \(rowText)")
                                rowText = ""
                            }
                        }
                        valueStartIndex = rowText.range(of: extractionCodes.dataCellStartSequence)
                        columnCount += 1
                    } while valueStartIndex != nil
                        
                    tableText = String(tableText[rowEndIndex.lowerBound..<tableText.endIndex])
                    
                    rowStartIndex = tableText.range(of:extractionCodes.rowStartSequence)

                    }
                else {
                    rowStartIndex = nil
                } // no rowEndIndex
            }
            else {
                rowStartIndex = nil
            } // no rowStartIndex
//            columnCount += 1

            
        } while rowStartIndex != nil
        

        return datedValues
    }

    
    /// macrotrend data are time-DESCENDING from left to right,
    /// so the value arrays - scraped right-to-left  from eadh row - are returned in time_ASCENDING order
    class func macrotrendsRowExtraction(table$: String, rowTitle: String, exponent: Double?=nil, numberTerminal:String?=nil) -> [Double]? {
        
        var valueArray = [Double]()
        let lnumberTerminal = numberTerminal ??  "</div></div>"
        let numberStarter = ">"
        var tableText = table$
        
        var numberEndIndex = tableText.range(of: lnumberTerminal)

        while numberEndIndex != nil && tableText.count > 0 {
            
            if let numberStartIndex = tableText.range(of: numberStarter, options: .backwards, range: tableText.startIndex..<numberEndIndex!.lowerBound, locale: nil)  {
                
                let value$ = tableText[numberStartIndex.upperBound..<numberEndIndex!.lowerBound]

                if value$ == "-" { valueArray.append( 0.0) } // MT.ent hads '-' indicating nil/ 0
                else {
                    let value = numberFromText(value$: String(value$), rowTitle: rowTitle, exponent: exponent)
                    valueArray.append(value)
                }
            }
            else {
                return nil
            }
            
            tableText.removeSubrange(...numberEndIndex!.upperBound)
            numberEndIndex = tableText.range(of: lnumberTerminal)
        }
        
        return valueArray  // in time_DESCENDING order
    }
    
    class func macrotrendsScrapeColumn(html$: String?, tableHeader: String, tableTerminal: String? = nil, columnTerminal: String? = nil, noOfColumns:Int?=4, targetColumnFromRight: Int?=0) throws -> [Double]? {
        
        let tableHeader = tableHeader
        let tableTerminal =  tableTerminal ?? "</td>\n\t\t\t\t </tr></tbody>"
        let localColumnTerminal = columnTerminal ?? "</td>"
        let labelStart = ">"
        
        var pageText = String(html$ ?? "")
        
        guard let titleIndex = pageText.range(of: tableHeader) else {
            throw InternalError(location: #function, errorInfo: "did not find \(String(describing: tableHeader)) in \(pageText)", errorType: .htmlTableHeaderEndNotFound)
        }

        let tableEndIndex = pageText.range(of: tableTerminal,options: [NSString.CompareOptions.literal], range: titleIndex.upperBound..<pageText.endIndex, locale: nil)
        
        guard tableEndIndex != nil else {
            throw InternalError(location: #function, errorInfo: "did not find \(String(describing: tableTerminal)) in \(pageText)", errorType: .htmlTableEndNotFound)
        }
        
        pageText = String(pageText[titleIndex.upperBound..<tableEndIndex!.lowerBound])
        
        var rowEndIndex = pageText.range(of: localColumnTerminal, options: .backwards, range: nil, locale: nil)
        var valueArray = [Double]()
        var count = 0 // row has four values, we only want the last of those four
        
        repeat {
            let labelStartIndex = pageText.range(of: labelStart, options: .backwards, range: nil, locale: nil)
            let value$ = pageText[labelStartIndex!.upperBound...]
            
            if count%(noOfColumns ?? 4) == (targetColumnFromRight ?? 0) {
                valueArray.append(Double(value$.filter("-0123456789.".contains)) ?? Double())
            }

            rowEndIndex = pageText.range(of: localColumnTerminal, options: .backwards, range: nil, locale: nil)
            if rowEndIndex != nil {
                pageText.removeSubrange(rowEndIndex!.lowerBound...)
                count += 1
            }
        }  while rowEndIndex != nil
        
        return valueArray

    }
    
    /// returns a date (assuming format yyyy-MM-dd) from default column 0 and a value from another column (%, T,B,M,K)
    /// columns count begins with 0...,check the website table in question
    /// send webpage html and the Title/Header identifying the start of the table
    /// default html tags are for MacroTrends table, with tableStart <tbody><tr>'  tableTerminal "</tr></tbody>", columnTerminal "</td>", rowTerminal and start "</tr>"
    /// check html and send other values for these if the table text differs
    class func extractColumnsValuesFromTable(html$: String?, tableHeader: String, tableTerminal: String? = nil, columnTerminal: String? = nil, dateColumn: Int?=0, valueColumn: Int, until: Date?=nil) throws -> [DatedValue]? {
        
        let tableHeader = tableHeader
        let tableStart = "<tbody><tr>"
        let tableTerminal =  tableTerminal ?? "</tr></tbody>"
        let localColumnTerminal = columnTerminal ?? "</td>"
//        let labelStart = ">"
        let rowTerminal = "</tr>"
//        let rowStarter = "</tr>"
        
        let websiteDateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.calendar.timeZone = TimeZone(identifier: "UTC")!
            return formatter
        }()

        guard let validHtml = html$ else {
            throw InternalError(location: #function, errorInfo: "empty web page text for \(tableHeader)", errorType: .emptyWebpageText)
        }
        
        let pageText = String(validHtml)
        
        guard let titleIndex = pageText.range(of: tableHeader) else {
            throw InternalError(location: #function, errorInfo: "did not find \(String(describing: tableHeader)) in \(pageText)", errorType: .htmlTableHeaderEndNotFound)
        }

        guard let tableEndIndex = pageText.range(of: tableTerminal,options: [NSString.CompareOptions.literal], range: titleIndex.upperBound..<pageText.endIndex, locale: nil) else {
            throw InternalError(location: #function, errorInfo: "did not find \(String(describing: tableTerminal)) in \(pageText)", errorType: .htmlTableEndNotFound)
        }
                
        guard let tableStartIndex = pageText.range(of: tableStart, range: titleIndex.upperBound..<pageText.endIndex) else {
            throw InternalError(location: #function, errorInfo: "did not find \(String(describing: tableStart)) in \(pageText)", errorType: .htmlTableSequenceStartNotFound)
        }
        
        let tableText = String(pageText[tableStartIndex.upperBound..<tableEndIndex.lowerBound])
        
        var valueArray = [DatedValue]()
        
        let rows$ = tableText.components(separatedBy: rowTerminal)
        for row in rows$ {
            let columns$ = row.components(separatedBy: localColumnTerminal)
            var value: Double?
            var date: Date?
            guard columns$.count > valueColumn else { continue }
            
            let date$ = columns$[0]
            let value$ = columns$[valueColumn]
            
            for column$ in [date$, value$] {
                let data = Data(column$.utf8)
                if let content$ = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil).string {
                    
                    if let dateValue = websiteDateFormatter.date(from: content$) {
                        date = dateValue
                    } else if let validValue = Double(content$.filter("-0123456789.".contains)) {
                        value = validValue
                        switch value$.last! {
                        case "%":
                            value! /= 100
                        case "T":
                            value! *= 1000000000000
                        case "B":
                            value! *= 1000000000
                        case "M":
                            value! *= 1000000
                        case "K":
                            value! *= 1000
                        default:
                            value = validValue
                        }
                    }
                }
            }
            
            if date != nil && value != nil {
                valueArray.append(DatedValue(date: date!, value: value!))
                
                if let stopDate = until {
                    if date! < stopDate { break }
                }
            }

        }
        
        return valueArray

    }

    
    class func rule1DataExtraction(htmlText: String, section: String) -> [LabelledValues]? {
        
        guard htmlText != "" else {
            return nil
//            throw InternalErrorType.emptyWebpageText
        }
        

        var results = [LabelledValues]()
// the first four sections are from MT pages
        if section == "financial-statements" {
            
            for title in ["Revenue","EPS - Earnings Per Share","Net Income"] {
                var labelledResults1 = LabelledValues(label: title, values: [Double]())
                
                if let values = WebPageScraper2.scrapeRowForDoubles(website: .macrotrends, html$: htmlText, sectionHeader: nil, rowTitle: ">" + title) {
                    labelledResults1.values = values
                    results.append(labelledResults1)
                }
            }
        }
        else if section == "financial-ratios" {
            
            for title in ["ROI - Return On Investment","Book Value Per Share","Operating Cash Flow Per Share"] {
                var labelledResults1 = LabelledValues(label: title, values: [Double]())
                if title.starts(with: "ROI") {
                    if let values = WebPageScraper2.scrapeRowForDoubles(website: .macrotrends, html$: htmlText, sectionHeader: nil, rowTitle: title) {
                        labelledResults1.values = values.compactMap{ $0 / 100 }
                    }
                }
                else {
                    if let values  = WebPageScraper2.scrapeRowForDoubles(website: .macrotrends, html$: htmlText, sectionHeader: nil, rowTitle: title) {
                        labelledResults1.values = values
                    }
                }
                results.append(labelledResults1)
            }
        }
        else if section == "balance-sheet" {
            var labelledResults1 = LabelledValues(label: "Long Term Debt", values: [Double]())
            if let values = WebPageScraper2.scrapeRowForDoubles(website: .macrotrends, html$: htmlText, sectionHeader: nil, rowTitle: "Long Term Debt") {
                let cleanedValues = values.filter({ (element) -> Bool in
                    return element != Double()
                })
                if let debt = cleanedValues.first {
                    labelledResults1.values = [Double(debt * 1000)]
                }
            }
            results.append(labelledResults1)
        }
        else if section == "pe-ratio" {
            var labelledResults1 = LabelledValues(label: "PE Ratio Historical Data", values: [Double]())
            if let values = WebPageScraper2.scrapeRowForDoubles(website: .macrotrends, html$: htmlText, sectionHeader: nil, rowTitle: "PE Ratio Historical Data</th>") {
                let pastPER = values.sorted()
                let withoutExtremes = pastPER.excludeQuintiles()
                labelledResults1.values = [withoutExtremes.min()!, withoutExtremes.max()!]
            }
            results.append(labelledResults1)
        }
        
// the following from Yahoo pages
        else if section == "analysis" {
            var labelledResults1 = LabelledValues(label: "Sales growth (year/est)", values: [Double]())

            if let values = WebPageScraper2.scrapeRowForDoubles(website: .yahoo, html$: htmlText, sectionHeader: "Revenue estimate</span>", rowTitle: "Sales growth (year/est)</span>") {
                let reverseValues = values.reversed()
                if let valid = reverseValues.last {
                    var growth = [valid]
                    let droppedLast = reverseValues.dropLast()
                    growth.append(droppedLast.last!)
                    labelledResults1.values = [growth.min()!, growth.max()!]
                }
            }
            results.append(labelledResults1)
        } else if section == "cash-flow" {

            var labelledResults1 = LabelledValues(label: "Operating cash flow", values: [Double]())

            if let values = WebPageScraper2.scrapeRowForDoubles(website: .yahoo, html$: htmlText, sectionHeader: "Cash flow</span>", rowTitle: "Operating cash flow</span>", rowTerminal: "</span></div></div><div") {
                labelledResults1.values = [values.last ?? Double()]
            }
            results.append(labelledResults1)
        } else if section == "insider-transactions" {
            
            for title in ["Purchases","Sales","Total insider shares held"] {
                
                var labelledResults1 = LabelledValues(label: title, values: [Double]())
                if let values = WebPageScraper2.scrapeRowForDoubles(website: .yahoo, html$: htmlText, sectionHeader: "Insider purchases - Last 6 months</span>", rowTitle: title+"</span>", rowTerminal: "</td></tr>", numberTerminal: "</td>") {
                    labelledResults1.values = [values.last ?? Double()]
                }
                results.append(labelledResults1)
            }
        }
        
        return results
    }

    //MARK: - general Yahoo functions
    
    class func dcfDataExtraction(htmlText: String, section: String) throws -> [LabelledValues] {
    
        guard htmlText != "" else {
            throw InternalError(location: #function, errorInfo: "empty web page found for \(section)", errorType: .emptyWebpageText)
        }
        
        let yahooPages = ["key-statistics", "financials", "balance-sheet", "cash-flow", "analysis"]
        var results = [LabelledValues]()

        if section == yahooPages.first! {
// Key stats,
            
            for rowTitle in ["Market cap (intra-day)</span>", "Beta (5Y monthly)</span>", "Shares outstanding</span>"] {
                var labelledValue = LabelledValues(label: rowTitle, values: [Double]())
                if let values = WebPageScraper2.scrapeRowForDoubles(website: .yahoo, html$: htmlText, rowTitle: ">" + rowTitle , rowTerminal: "</tr>", numberTerminal: "</td>", webpageExponent: 3.0) {
                
                    labelledValue.values = [values.first ?? Double()]
                }
                results.append(labelledValue)
            }
        }
        else if section == yahooPages[1] {
// Income
            for rowTitle in ["Total revenue</span>", "Net income</span>", "Interest expense</span>","Income before tax</span>","Income tax expense</span>"] {
                var labelledValue = LabelledValues(label: rowTitle, values: [Double]())
                
                if let values = WebPageScraper2.scrapeRowForDoubles(website: .yahoo, html$: htmlText, rowTitle: rowTitle, rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0) {

                    if rowTitle == "Interest expense</span>" {
                        labelledValue.values = [values.first ?? Double()]
                    } else if rowTitle == "Income before tax</span>"{
                        labelledValue.values = [values.first ?? Double()]
                    } else if rowTitle == "Income tax expense</span>" {
                        labelledValue.values = [values.first ?? Double()]
                    }
                    else {
                        labelledValue.values = values
                    }
                    }
                results.append(labelledValue)
            }
        }
        else if section == yahooPages[2] {
            let rowTitles = ["Current debt</span>","Long-term debt</span>", "Total Debt</span>"]
// Balance sheet
            
            for title in rowTitles {
                var labelledValue = LabelledValues(label: title, values: [Double]())
                if let values = WebPageScraper2.scrapeRowForDoubles(website: .yahoo,html$: htmlText, rowTitle: title, rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0) {
                    if (values.first ?? Double()) != Double() {
                        labelledValue.values = [values.first!]
                        results.append(labelledValue)
                        if title == "Long-term debt</span>" { break }
                    }
                }
            }
        }
        else if section == yahooPages[3] {
// Cash flow
            
            let rowTitles = ["Operating cash flow</span>","Capital expenditure</span>"]
            
            for title in rowTitles {
                var labelledValue = LabelledValues(label: title, values: [Double]())
                if let values = WebPageScraper2.scrapeRowForDoubles(website: .yahoo,html$: htmlText, rowTitle: title, rowTerminal: "</span></div></div>", numberTerminal: "</span></div>", webpageExponent: 3.0) {
                    labelledValue.values = values
                }
                results.append(labelledValue)
            }
            
        }
        else if section == yahooPages[4] {
// Analysis
            
            let rowTitles = ["Avg. Estimate</span>", "Sales growth (year/est)</span>"]
            
            for title in rowTitles {
                var labelledValue = LabelledValues(label: title, values: [Double]())
                if let values = WebPageScraper2.scrapeRowForDoubles(website: .yahoo,html$: htmlText, sectionHeader: "Revenue estimate</span>" ,rowTitle: title, rowTerminal: "</td></tr>", numberTerminal: "</td>" , webpageExponent: 3.0) {

                    let a1 = values.dropLast()
                    let a2 = a1.dropLast()
                    labelledValue.values = a2.reversed()
                }
                results.append(labelledValue)
            }
        }
        
        return results
    }
    
    /// webpageExponent = the exponent used by the webpage to listing financial figures, e.g. 'thousands' on yahoo = 3.0
    class func scrapeRowForDoubles(website: Website, html$: String?, sectionHeader: String?=nil, rowTitle: String, rowTerminal: String? = nil, numberStarter: String?=nil , numberTerminal: String? = nil, webpageExponent: Double?=nil) -> [Double]? {
        
        var pageText = html$
        let sectionTitle: String? = (sectionHeader != nil) ? (">" + sectionHeader!) : nil
        let rowDataStartDelimiter: String? = (website == .macrotrends) ? "class=\"fas fa-chart-bar\"></i></div></div></div><div role=" : nil
        let rowStart = website == .macrotrends ? ">" + rowTitle + "<" : rowTitle
        var rowTerminal2: String = rowTerminal ?? "</div></div></div>" // after ?? is fot MT only
        let tableTerminal = "</div></div></div></div>"

        guard pageText != nil else {
            return nil
        }
        

        if website == .yahoo {
            rowTerminal2 =  rowTerminal ?? "</span></td></tr>"
        }
// 1 Remove leading and trailing parts of the html code
// A Find section header
        if sectionTitle != nil {
            guard let sectionIndex = pageText?.range(of: sectionTitle!) else {
                return nil
            }
            pageText = String(pageText!.suffix(from: sectionIndex.upperBound))
        }
                        
// B Find beginning of row
        var rowStartIndex = pageText?.range(of: rowStart)
        guard rowStartIndex != nil else {
            return nil
        }
        
        if let validStarter = rowDataStartDelimiter {
            if let index = pageText?.range(of: validStarter, options: [NSString.CompareOptions.literal], range: rowStartIndex!.upperBound..<pageText!.endIndex, locale: nil) {
                rowStartIndex = index
            }
        }
        
// C Find end of row - or if last row end of table - and reduce pageText to this row
        if let rowEndIndex = pageText?.range(of: rowTerminal2,options: [NSString.CompareOptions.literal], range: rowStartIndex!.upperBound..<pageText!.endIndex, locale: nil) {
                pageText = String(pageText![rowStartIndex!.upperBound..<rowEndIndex.upperBound])
        } else if let tableEndIndex = pageText?.range(of: "}]",options: [NSString.CompareOptions.literal], range: rowStartIndex!.upperBound..<pageText!.endIndex, locale: nil) {
                pageText = String(pageText![rowStartIndex!.upperBound..<tableEndIndex.upperBound])
        } else if let tableEndIndex = pageText?.range(of: tableTerminal,options: [NSString.CompareOptions.literal], range: rowStartIndex!.upperBound..<pageText!.endIndex, locale: nil) {
                pageText = String(pageText![rowStartIndex!.upperBound..<tableEndIndex.upperBound])
        }
        else {
            return nil
        }
        
        if website == .macrotrends {
            
            
            let values = macrotrendsRowExtraction(table$: pageText ?? "", rowTitle: rowTitle, exponent: webpageExponent)
            return values // MT.com rows are time_DESCENDING from left to right, so the valueArray is in time-ASCENDING order deu to backwards row scraping.
        }
        else {
                let values = yahooRowNumbersExtraction(table$: pageText ?? "", rowTitle: rowTitle, numberStarter: numberStarter, numberTerminal: numberTerminal, exponent: webpageExponent)
                return values
        }
    }
    
    class func scrapeYahooRowForDoubles(html$: String?, rowTitle: String, rowTerminal: String? = nil, numberTerminal: String? = nil) -> [Double]? {
        
        var pageText = html$
        let rowStart = rowTitle
        let rowTerminal = rowTerminal ?? "\""

        guard pageText != nil else {
            return nil
//            throw InternalErrorType.emptyWebpageText
        }
        
                        
// B Find beginning of row
        let rowStartIndex = pageText?.range(of: rowStart)
        guard rowStartIndex != nil else {
            return nil
//            throw InternalErrorType.htmlRowStartIndexNotFound
        }
                
// C Find end of row - or if last row end of table - and reduce pageText to this row
        if let rowEndIndex = pageText?.range(of: rowTerminal,options: [NSString.CompareOptions.literal], range: rowStartIndex!.upperBound..<pageText!.endIndex, locale: nil) {
            pageText = String(pageText![rowStartIndex!.upperBound..<rowEndIndex.upperBound])
        }
        else {
            return nil
//            throw InternalErrorType.htmlRowEndIndexNotFound
        }

        let values = yahooRowNumbersExtraction(table$: pageText ?? "", rowTitle: rowTitle, numberTerminal: numberTerminal)
        return values
    }

    /// expect one table row of html text
    class func yahooRowNumbersExtraction(table$: String, rowTitle: String, numberStarter: String?=nil, numberTerminal: String?=nil, exponent: Double?=nil) -> [Double]? {
        
        var valueArray = [Double]()
        let numberTerminal = numberTerminal ?? "</span>"
        let numberStarter = numberStarter ?? ">"
        var tableText = table$
        
        var labelEndIndex = tableText.range(of: numberTerminal, options: .backwards, range: nil, locale: nil)
        if let index = labelEndIndex {
            tableText.removeSubrange(index.lowerBound...)
        }
        
        guard labelEndIndex != nil else { return nil }

        repeat {
            guard let labelStartIndex = tableText.range(of: numberStarter, options: .backwards, range: tableText.startIndex..<labelEndIndex!.lowerBound, locale: nil) else {
                return nil
//                throw InternalErrorType.contentStartSequenceNotFound
            }
            
            let value$ = tableText[labelStartIndex.upperBound...]
            let value = numberFromText(value$: String(value$), rowTitle: rowTitle, exponent: exponent)
            valueArray.append(value)
            
            
            labelEndIndex = tableText.range(of: numberTerminal, options: .backwards, range: tableText.startIndex..<labelEndIndex!.lowerBound, locale: nil)
            if let index = labelEndIndex {
                tableText.removeSubrange(index.lowerBound...)
            }

        } while labelEndIndex != nil && (tableText.count > 1)

        return valueArray
    }
    
    class func scrapeRowForText(html$: String?, sectionHeader: String?=nil, sectionTerminal: String?=nil, rowTitle: String, rowTerminal: String? = nil, textTerminal: String? = nil, webpageExponent: Double?=nil) throws -> [String] {
        
        var pageText = html$
        let sectionTitle: String? = (sectionHeader != nil) ? (">" + sectionHeader!) : nil
//        let rowDataStartDelimiter: String? = (website == .macrotrends) ? "class=\"fas fa-chart-bar\"></i></div></div></div><div role=" : nil
        let rowStart = rowTitle
        let rowTerminal = (rowTerminal ?? ",")
        let tableTerminal = sectionTerminal ?? "</p>"

        guard pageText != nil else {
            throw InternalError(location: #function, errorInfo: "empty web page found for \(String(describing: sectionTitle))", errorType: .emptyWebpageText)
        }
        
// 1 Remove leading and trailing parts of the html code
// A Find section header
        if sectionTitle != nil {
            guard let sectionIndex = pageText?.range(of: sectionTitle!) else {
                throw InternalError(location: #function, errorInfo: "did not find \(String(describing: sectionTitle)) in \(String(describing: pageText))", errorType: .htmlSectionTitleNotFound)
            }
            pageText = String(pageText!.suffix(from: sectionIndex.upperBound))
        }
                        
// B Find beginning of row
        let rowStartIndex = pageText?.range(of: rowStart)
        guard rowStartIndex != nil else {
            throw InternalError(location: #function, errorInfo: "did not find \(String(describing: rowStart)) in \(String(describing: pageText))", errorType: .htmlRowStartIndexNotFound)
        }
        
// C Find end of row - or if last row end of table - and reduce pageText to this row
        if let rowEndIndex = pageText?.range(of: rowTerminal,options: [NSString.CompareOptions.literal], range: rowStartIndex!.upperBound..<pageText!.endIndex, locale: nil) {
            pageText = String(pageText![rowStartIndex!.upperBound..<rowEndIndex.lowerBound])
        } else if let tableEndIndex = pageText?.range(of: tableTerminal,options: [NSString.CompareOptions.literal], range: rowStartIndex!.upperBound..<pageText!.endIndex, locale: nil) {
            pageText = String(pageText![rowStartIndex!.upperBound..<tableEndIndex.lowerBound])
        }
        else {
            throw InternalError(location: #function, errorInfo: "did not find \(String(describing: rowTerminal)) in \(String(describing: pageText))", errorType: .htmlRowEndIndexNotFound)
        }
        
        let textArray = try yahooRowStringExtraction(table$: pageText ?? "", rowTitle: rowTitle, textTerminal: textTerminal)
        return textArray
    }

    class func yahooRowStringExtraction(table$: String, rowTitle: String, textTerminal: String?=nil) throws -> [String] {
        
        var textArray = [String]()
        let textTerminal = textTerminal ?? "\""
        let textStarter = "\""
        var tableText = table$
        
        var labelEndIndex = tableText.range(of: textTerminal, options: .backwards, range: nil, locale: nil)
        if let index = labelEndIndex {
            tableText.removeSubrange(index.lowerBound...)
        }

        repeat {
            guard let labelStartIndex = tableText.range(of: textStarter, options: .backwards, range: tableText.startIndex..<labelEndIndex!.lowerBound, locale: nil) else {
                throw InternalError(location: #function, errorInfo: "did not find \(String(describing: textStarter)) in \(tableText)", errorType: .contentStartSequenceNotFound)
            }
            
            let value$ = String(tableText[labelStartIndex.upperBound...])
            textArray.append(value$)
            
            labelEndIndex = tableText.range(of: textTerminal, options: .backwards, range: tableText.startIndex..<labelEndIndex!.lowerBound, locale: nil)
            if let index = labelEndIndex {
                tableText.removeSubrange(index.lowerBound...)
            }

        } while labelEndIndex != nil && (tableText.count > 1)

        return textArray
    }
    
    class func analyseYahooPriceTable(html$: String) -> [PricePoint]? {
        
        let tableEnd$ = "</tbody><tfoot>"
        let tableStart$ = "<thead>"
        
        let rowStart$ = "Ta(start)"
        let rowEnd = "</span></td>"
        
        
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM yyyy"
            formatter.calendar.timeZone = TimeZone(identifier: "UTC")!
            return formatter
        }()

        var pageText = html$
        
        // eliminate above table start
        if let tableStartIndex = pageText.range(of: tableStart$) {
            pageText.removeSubrange(...tableStartIndex.upperBound)
        } else {
            return nil
        }

        // eliminate below table end
        if let tableEndIndex = pageText.range(of: tableEnd$) {
            pageText.removeSubrange(tableEndIndex.upperBound...)
        } else {
            return nil
        }

        // table should have 7 columns: Date, Open, High, Low, Close, Ajd. close , Volume
        
        var pricePoints = [PricePoint]()
        
        var rowStartIndex = pageText.range(of: rowStart$, options: .backwards)
        var count = 0
        while rowStartIndex != nil {
            
            var tradingDate: Date?
            
            var values = [Double]()
            
            var rowText = pageText[rowStartIndex!.upperBound...]
            
            count = 0
            var columnEndIndex = rowText.range(of: rowEnd, options: .backwards)
            while columnEndIndex != nil {
                rowText.removeSubrange(columnEndIndex!.lowerBound...)
                if let dataIndex = rowText.range(of: ">", options: .backwards) {
                    // loading webpage outside OS browser loads September as 'Sept' which has no match in dateFormatter.
                    // needs replacing with 'Sep'
                    var data$ = rowText[dataIndex.upperBound...]
                    if data$.contains("Sept") {
                        if let septIndex = data$.range(of: "Sept") {
                            data$.replaceSubrange(septIndex, with: "Sep")
                        }
                    }

                    if count == 6 {
                        if let date = dateFormatter.date(from: String(data$)) {
                            tradingDate = date
                        }
                    }
                    else if let value = Double(data$.filter("-0123456789.".contains)) {
                            values.append(value)
                    }
                }
                else {
                    values.append(Double())
                }
                columnEndIndex = rowText.range(of: rowEnd, options: .backwards)
                count += 1
            }
            
            if values.count == 6 && tradingDate != nil {
                let newPricePoint = PricePoint(open: values[5], close: values[2], low: values[3], high: values[4], volume: values[0], date: tradingDate ?? Date())
                pricePoints.append(newPricePoint)
            }
            
            pageText.removeSubrange(rowStartIndex!.lowerBound...)
            rowStartIndex = pageText.range(of: rowStart$, options: .backwards)
        }

        return pricePoints
    }



    // MARK: - YCharts functions
    
    
    /// returns quarterly eps  with dates from YCharts website
    /// in form of [DatedValues] = (date, eps )
    /// ; optional parameter 'date' returns values back to this date and the first set before.
    /// ; throws downlad and analysis errors, which need to be caught by cailler
    class func getqEPSDataFromYCharts(url: URL, companyName: String, until date: Date?=nil, downloadRedirectDelegate: DownloadRedirectionDelegate) async throws -> [DatedValue]? {
        
            var htmlText:String?
            var datedValues = [DatedValue]()
            let downloader = Downloader(task: .qEPS)
        
            do {
                // to catch any redirections
                NotificationCenter.default.addObserver(downloadRedirectDelegate, selector: #selector(DownloadRedirectionDelegate.awaitingRedirection(notification:)), name: Notification.Name(rawValue: "Redirection"), object: nil)
                
                htmlText = try await downloader.downloadDataWithRedirection(url: url)
//                print("marketwatch html for \(companyName) is:\n\(htmlText)")
            } catch {
                throw error
            }
        
            guard let validPageText = htmlText else {
                throw InternalError(location: #function, errorInfo: "html text = nil for url \(url)", errorType: .generalDownloadError)
            }
                
            do {

                let codes = WebpageExtractionCodes(tableTitle: "Historical EPS Diluted (Quarterly) Data", option: .yCharts, dataCellStartSequence: "<td") // "\">"
                datedValues = try extractQEPSTableData(html: validPageText, extractionCodes: codes, untilDate: date)
                return datedValues
            } catch let error {
                throw InternalError(location: #function, systemError: error as NSError, errorInfo: "failed hist q EPS extraction \(url)", errorType: .generalDownloadError)
            }

    }


    
    //MARK: - general analysis functions
    
    class func numberFromText(value$: String, rowTitle: String, exponent: Double?=nil) -> Double {
        
        var value = Double()
        
        if value$.filter("-0123456789.".contains) != "" {
            if let v = Double(value$.filter("-0123456789.".contains)) {
              
                if value$.last == "%" {
                    value = v / 100.0
                }
                else if value$.uppercased().last == "T" {
                    value = v * pow(10.0, 12) // should be 12 but values are entered as '000
                } else if value$.uppercased().last == "B" {
                    value = v * pow(10.0, 9) // should be 9 but values are entered as '000
                }
                else if value$.uppercased().last == "M" {
                    value = v * pow(10.0, 6) // should be 6 but values are entered as '000
                }
                else if value$.uppercased().last == "K" {
                    value = v * pow(10.0, 3) // should be 6 but values are entered as '000
                }
                else if rowTitle.contains("Beta") {
                    value = v
                }
                else {
                    value = v * (pow(10.0, exponent ?? 0.0))
                }
                
                if value$.last == ")" {
                    value = v * -1
                }
            }
        }
        
        return value
    }
    
    
    class func removeFile(_ atURL: URL) {
       
        do {
            try FileManager.default.removeItem(at: atURL)
        } catch let error {
            DispatchQueue.main.async {
                ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error trying to remove existing file in the Document folder to be able to move new file of same name from Inbox folder ")
            }
        }
    }

}

