//
//  YChartsScraper.swift
//  Bulls'N'Bears
//
//  Created by aDav on 12/01/2023.
//

import Foundation
import CoreData
import UIKit

class YChartsScraper {
    
    
    /// returns quarterly eps  with dates from YCharts website
    /// in form of [DatedValues] = (date, eps )
    /// ; optional parameter 'date' returns values back to this date and the first set before.
    /// ; throws downlad and analysis errors, which need to be caught by cailler
    class func qepsDownloadAnalyse(url: URL, companyName: String, until date: Date?=nil, downloadRedirectDelegate: DownloadRedirectionDelegate) async -> [DatedValue]? {
        
            var htmlText:String?
            var datedValues = [DatedValue]()
            let downloader = Downloader(task: .qEPS)
        
            do {
                // to catch any redirections
                NotificationCenter.default.addObserver(downloadRedirectDelegate, selector: #selector(DownloadRedirectionDelegate.awaitingRedirection(notification:)), name: Notification.Name(rawValue: "Redirection"), object: nil)
                
                htmlText = try await downloader.downloadDataWithRedirection(url: url)
            } catch {
                ErrorController.addInternalError(errorLocation: #function, errorInfo: "Download failure for YCHarts data for \(url)")
                return nil
            }
        
            guard let validPageText = htmlText else {
                ErrorController.addInternalError(errorLocation: #function, errorInfo: "Download failure for YCHarts data for \(url) - html text nil")
                return nil
            }
                
            do {
                let codes = WebpageExtractionCodes(tableTitle: "Historical EPS Diluted (Quarterly) Data", option: .yCharts, dataCellStartSequence: "<td") // "\">"
                datedValues = try YChartsScraper.extractQEPSTableData(html: validPageText, extractionCodes: codes, untilDate: date)
                return datedValues
            } catch {
                ErrorController.addInternalError(errorLocation: #function, errorInfo: "failed historical q EPS extraction \(url)")
                return nil
            }

    }
    
    class func qepsDownloadAnalyseSave(symbol: String, shortName: String, shareID: NSManagedObjectID, until date: Date?=nil, progressDelegate: ProgressViewDelegate? , downloadRedirectDelegate: DownloadRedirectionDelegate?) async {
        
        var sn = shortName
        if sn.contains(" ") {
            sn = sn.replacingOccurrences(of: " ", with: "-").lowercased()
        }
                
        guard let url = URL(string: ("https://ycharts.com/companies/" + symbol.uppercased() + "/eps")) else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "Download failure for YCHarts data for \(symbol) - URL error")
            return
        }

        
        var htmlText:String?
        var datedValues = [DatedValue]()
        let downloader = Downloader(task: .qEPS)
    
        NotificationCenter.default.addObserver(downloadRedirectDelegate, selector: #selector(DownloadRedirectionDelegate.awaitingRedirection(notification:)), name: Notification.Name(rawValue: "Redirection"), object: nil)
        
        htmlText = await downloader.downloadDataWithRedirectionOption(url: url)
    
        guard let validPageText = htmlText else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "Download failure for YCHarts data for \(url) - html text nil")
            return
        }
        
        let codes = WebpageExtractionCodes(tableTitle: "Historical EPS Diluted (Quarterly) Data", option: .yCharts, dataCellStartSequence: "<td") // "\">"

        let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
        backgroundMoc.automaticallyMergesChangesFromParent = true
        
        do {
            if let bgShare = backgroundMoc.object(with: shareID) as? Share {
                datedValues = try YChartsScraper.extractQEPSTableData(html: validPageText, extractionCodes: codes, untilDate: date)
                bgShare.income_statement?.eps_quarter = datedValues.convertToData()
                try bgShare.managedObjectContext?.save()
            }
        }
        catch {
            ErrorController.addInternalError(errorLocation: #function, systemError: error ,errorInfo: "failed historical q EPS extraction from \(url) for \(symbol)")
        }

    }

    
    // MARK: - Internal functions
    
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


}
