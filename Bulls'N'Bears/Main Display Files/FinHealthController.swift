//
//  FinHealthController.swift
//  Bulls'N'Bears
//
//  Created by aDav on 13/10/2022.
//

import UIKit

class FinHealthController: NSObject {
    
    var share: Share!
    
    init(share: Share!) {
        self.share = share
    }
    
    
    class func downloadFinHealthData(share: Share?) {
        
        guard let validShare = share else { return }
        
        let symbol = validShare.symbol ?? ""
        let shortName = validShare.name_short ?? ""
        let shareID = validShare.objectID
//
//        Task.init(priority: .background, operation: {
//
//        })
                  
    }
    
    func getQuarterlyEarningsForUpdate(shareSymbol: String, shortName: String, minDate: Date?=nil, latestQEPSDate: Date?) async throws -> Labelled_DatedValues? {
                
        if let valid = latestQEPSDate {
            if Date().timeIntervalSince(valid) < 80*24*3600 {
                return nil
            }
        }
        
        var sn = shortName
        if sn.contains(" ") {
            sn = sn.replacingOccurrences(of: " ", with: "-").lowercased()
        }
        
//        guard let components = URLComponents(string: "https://www.macrotrends.net/stocks/charts/\(shareSymbol)/\(sn)/eps-earnings-per-share-diluted") else {
//            throw DownloadAndAnalysisError.urlInvalid
//        }
        
        guard let ycharts_url = URL(string: ("https://ycharts.com/companies/" + shareSymbol.uppercased() + "/eps")) else {
            throw DownloadAndAnalysisError.urlError
        }
        
//        guard let macrotrends_url = components.url else {
//            throw DownloadAndAnalysisError.urlError
//        }
        
//        do {
//        guard let marketwatch_url = URL(string: ("https://www.marketwatch.com/investing/stock/" + shareSymbol + "/financials/income/quarter")) else {
//            throw DownloadAndAnalysisError.urlError
//        }
//        } catch {
//            print("StocksController2.getQuarterlyEarningsForUpdate marketwatch url error \(error)")
//        }
        
        var values: [DatedValue]?
        
        do {
//            values = try await WebPageScraper2.getqEPSDataFromMacrotrends(url: macrotrends_url, companyName: sn, until: minDate, downloadRedirectDelegate: self)
            values = try await WebPageScraper2.getqEPSDataFromYCharts(url: ycharts_url, companyName: sn, until: minDate, downloadRedirectDelegate: self)
        }  catch let error as DownloadAndAnalysisError {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "a background download or analysis error for \(shareSymbol) occurred: \(error)")
        }
        

        return Labelled_DatedValues(label: shareSymbol, datedValues: values ?? [])

    }

    
}

extension FinHealthController: DownloadRedirectionDelegate {
    
    func awaitingRedirection(notification: Notification) {
        <#code#>
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? {
           
        let object = request
        let notification = Notification(name: Notification.Name(rawValue: "Redirection"), object: object, userInfo: nil)
        NotificationCenter.default.post(notification)

        return nil
    }

    
}
