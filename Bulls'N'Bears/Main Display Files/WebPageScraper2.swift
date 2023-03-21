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

class WebPageScraper2: NSObject {
    
    var progressDelegate: ProgressViewDelegate?
    
    /// use this to create an instance if you don't wish to use the class functions
    init(progressDelegate: ProgressViewDelegate?) {
        self.progressDelegate = progressDelegate
    }

    /// called  by StocksController.updateStocks for non-US stocks when trying to download from MacroTrends
    class func nonUSDataDownload(symbol: String?, shortName: String?, shareID: NSManagedObjectID ,progressDelegate: ProgressViewDelegate?=nil) async {
        
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
        
//        let snComponents = validSN.split(separator: " ")
//        var arivaComponents = String(snComponents.first!)
//        if snComponents.count > 1 {
//            if snComponents[1] == "SE" {
//                arivaComponents += " " + String(snComponents[1])
//            }
//        }
//        let arivaString = arivaComponents.replacingOccurrences(of: " ", with: "_") + "-aktie"
//        let arivaURL = URL(string: "https://www.ariva.de/\(arivaString)/bilanz-guv")
        let tsURL = tagesschauURL
        progressDelegate?.allTasks = 5
        
        Task.init {
            do {
                // download from ariva and move on after async let...
                var r1LabelledValues = [Labelled_DatedValues]()

//                async let arivaHTML = Downloader.downloadDataNoThrow(url: arivaURL!)
                
                progressDelegate?.taskCompleted()

                // find full url for company on tagesschau search page
                if let html = await Downloader.downloadDataWithRedirectionOption(url: tsURL) {
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
                            if let htmlText = await Downloader.downloadDataNoThrow(url: url) {
                                await TagesschauScraper.dataDownloadAnalyseSave(htmlText: htmlText, symbol: symbol, shareID: shareID, progressDelegate: progressDelegate)
                            }
                        }
                    }
                }
                progressDelegate?.taskCompleted()

                // ...continue analysing arivaHTML here
//                if let arivaLDVs = await ArivaScraper.pageAnalysis(html: arivaHTML ?? "", headers: ["Bewertung"], parameters: [["KGV (Kurs/Gewinn)","Return on Investment in %"]]) {
//                    
//                    r1LabelledValues.append(contentsOf: arivaLDVs.sortAllElementDatedValues(dateOrder: .ascending))
//                }
//                progressDelegate?.taskCompleted()
                
                for i in 0..<r1LabelledValues.count {
                    if let latest = r1LabelledValues[i].datedValues.first {
                        if latest.value == 0.0 {
                            r1LabelledValues[i].datedValues = Array(r1LabelledValues[i].datedValues.dropFirst())
                        }
                    }
                }

                progressDelegate?.downloadComplete()
                
                let backgroundMoc = await (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
                backgroundMoc.automaticallyMergesChangesFromParent = true
                
                if let bgShare = backgroundMoc.object(with: shareID) as? Share {
                    await bgShare.mergeInDownloadedData(labelledDatedValues: r1LabelledValues)
                }
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: "DownloadEnded"), object: nil, userInfo: nil)

            } catch {
                progressDelegate?.downloadError(error: error.localizedDescription)
                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "error downloading 'Tageschau' Aktien info page")
            }
        }
    }
    
    /// calls Downloader function with completion handler to return csv file
    /// returns extracted [DateValue] array through Notification with name ""TBOND csv file downloaded""
    class func downloadAndAnalyseTreasuryYields(url: URL) async {
        
       let treasuryCSVHeaderTitles = ["Date","\"1 Mo\"", "\"2 Mo\"","\"3 Mo\"","\"4 Mo\"","\"6 Mo\"","\"1 Yr\"","\"2 Yr\"","\"3 Yr\"","\"5 Yr\"","\"7 Yr\"","\"10 Yr\"","\"20 Yr\"","\"30 Yr\""]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"

        do {
            if let fileURL = try await Downloader.downloadCSVFile2(url: url, symbol: "TBonds", type: "_TB") {

                if let datedValues = try await YahooPageScraper.analyseCSVFile(localURL: fileURL, expectedHeaderTitles: treasuryCSVHeaderTitles, dateFormatter: dateFormatter) {
                    
                    var tenYDatedRates = [DatedValue]()
                    for value in datedValues {
                        let dValue = DatedValue(date: value.date, value: value.values[11])
                        tenYDatedRates.append(dValue)
                    }

                    NotificationCenter.default.post(name: Notification.Name(rawValue: "TBOND csv file downloaded"), object: tenYDatedRates, userInfo: nil)
                }
            }
        } catch {
            ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "Error downloading TBond rates")
        }
    }

}
