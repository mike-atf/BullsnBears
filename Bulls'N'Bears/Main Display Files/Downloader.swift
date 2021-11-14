//
//  Downloader.swift
//  Bulls'N'Bears
//
//  Created by aDav on 04/11/2021.
//

import Foundation

class Downloader {
    
    class func downloadData(url: URL) async throws -> String {
        
        let request = URLRequest(url: url)
            
        let (data,urlResponse) = try await URLSession.shared.data(for: request)
        var htmlText = String()
        
        if let response = urlResponse as? HTTPURLResponse {
            if response.statusCode == 200 {
                if response.mimeType == "text/html" {
                    htmlText = String(data: data, encoding: .utf8) ?? ""
                }
                else {
                    throw DownloadAndAnalysisError.mimeType
                }
            }
            else {
                throw DownloadAndAnalysisError.urlError
            }
        }
        
        return htmlText
    }
    
    
    /// returns the downloaded file in Notification with message  "FileDownloadComplete" with fileURL as object
    /// or returns with throwing an error
    class func downloadFile(url: URL, symbol: String) async throws {
                
        let downloadTask = URLSession.shared.downloadTask(with: url) {  [self]
            urlOrNil, response, errorOrNil in
            
            guard errorOrNil == nil else {
                DispatchQueue.main.async {
                    alertController.showDialog(title: "Download error", alertMessage: "couldn't download \(symbol) due to error \(errorOrNil!.localizedDescription)", viewController: nil, delegate: nil)
                }
                return
            }
            
            guard response != nil else {
                DispatchQueue.main.async {
                    alertController.showDialog(title: "Download error", alertMessage: "couldn't download \(symbol) due to error \(String(describing: response!.textEncodingName))", viewController: nil, delegate: nil)
                }
                return
            }
                        
            guard let fileURL = urlOrNil else { return }
            
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

                try FileManager.default.moveItem(at: fileURL, to: tempURL)
            

                if !CSVImporter.matchesExpectedFormat(url: tempURL) {
                    // this may be due to 'invalid cookie' error
                    // if so download webpage content with table
                    removeFile(tempURL)
                    
                    throw DownloadAndAnalysisError.fileFormatNotCSV
                }
                
                if FileManager.default.fileExists(atPath: targetURL.path) {
                    removeFile(targetURL)
                }

                try FileManager.default.moveItem(at: tempURL, to: targetURL)
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "FileDownloadComplete"), object:   targetURL, userInfo: ["companySymbol": symbol]) // send to StocksListVC
                }
//                // the Company profile (industry, sector and employees) is downloaded after this in StocksController called from StocksListVC as delegate of this here download
//                }

            } catch {
                DispatchQueue.main.async {
                    ErrorController.addErrorLog(errorLocation: #function, systemError: error, errorInfo: "can't move and save downloaded file")
                }
            }
        }

        downloadTask.resume()
    }


    class func removeFile(_ atURL: URL) {
       
        do {
            try FileManager.default.removeItem(at: atURL)
        } catch let error {
            DispatchQueue.main.async {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error trying to remove existing file in the Document folder to be able to move new file of same name from Inbox folder ")
            }
        }
    }


}
