//
//  Downloader.swift
//  Bulls'N'Bears
//
//  Created by aDav on 04/11/2021.
//

import Foundation

enum DownloadTask {
    case test
    case epsPER
    case wbValuation
    case r1Valuation
}

class Downloader: NSObject {
    
    var task: DownloadTask?
    
    //MARK: - instance methods
    convenience init(task: DownloadTask) {
        self.init()
        
        self.task = task
    }
        
    ///  posts notificaiton "Redirection" with object: URlReqeust and userInfo [task:Dowloadtask] and [dellocate:Downloader]
    ///  caller should add a  DownloadRedirectionDelegate observer to NotificationCenter.default to receive any redirection nofitications
    func downloadDataWithRedirection(url: URL) async throws -> String? {
        
        let request = URLRequest(url: url)
            
        let (data,urlResponse) = try await URLSession.shared.data(for: request,delegate: self)
        
        if let response = urlResponse as? HTTPURLResponse {
            if response.statusCode == 200 {
                if response.mimeType == "text/html" {
                  return String(data: data, encoding: .utf8) ?? ""
                }
                else {
                    throw DownloadAndAnalysisError.mimeType
                }
            }
            else {
                throw DownloadAndAnalysisError.generalDownloadError
            }
        }
        
        return nil
    }

    //MARK: - class functions
    
    /// returns true if download results in htmlText, false if not
    /// calls delegate if redirect results (shortName wrong), in this case may return  nil
    /// delegate should extract correct short name for MT from request.url in delegate method
    class func mtTestDownload(url: URL, delegate: DownloadRedirectionDelegate) async throws -> Bool? {
        
            let html$ = try await downloadDataWithRedirectionDelegate(url: url, delegate: delegate)
            if let validPageText = html$ {
                if validPageText != "" {
                    return true
                }
                else { return false }
            }
            else { return false }
    }
    
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
                throw DownloadAndAnalysisError.generalDownloadError
            }
        }
        
        return htmlText
    }
    
    /// call this method when the caller provides a DownloadRedirectionDelegate with functions; this comes without the option of specific taks redirection
    /// otherwise use instance method 'downloadDataWithRedirection' after initialising Downloader with a specific downloadTask for redirection
    class func downloadDataWithRedirectionDelegate(url: URL, delegate: DownloadRedirectionDelegate) async throws -> String? {
        
        let request = URLRequest(url: url)
            
        let (data,urlResponse) = try await URLSession.shared.data(for: request,delegate: delegate)
        
        if let response = urlResponse as? HTTPURLResponse {
            if response.statusCode == 200 {
                if response.mimeType == "text/html" {
                  return String(data: data, encoding: .utf8) ?? ""
                }
                else {
                    throw DownloadAndAnalysisError.mimeType
                }
            }
            else {
                throw DownloadAndAnalysisError.generalDownloadError
            }
        }
        
        return nil
    }
    
    class func downloadDataWithRequest(request: URLRequest?) async throws -> String? {
        
        guard let validRequest = request else {
            return nil
        }
        
        URLCache.shared.removeAllCachedResponses() // to avoid the 'too many redirects' error
        
        let (data,urlResponse) = try await URLSession.shared.data(for: validRequest)
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
                throw DownloadAndAnalysisError.generalDownloadError
            }
        }
        
        return htmlText
    }
    
    /// returns Notification with message  "FileDownloadComplete" with fileURL as object
    /// or - if file not in .csv format - sends a notification 'FileDownloadedNotCSV' with  'symbol' as object and companyName as userInfo
    class func downloadFile(url: URL, symbol: String, companyName: String) async {
                
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
                if FileManager.default.fileExists(atPath: targetURL.path) {
                    removeFile(targetURL)
                }

                try FileManager.default.moveItem(at: fileURL, to: tempURL)
            

                if !CSVImporter.matchesExpectedFormat(url: tempURL) {
                    // this may be due to 'invalid cookie' error
                    // if so download webpage content with table
                    removeFile(tempURL)
                    
                    DispatchQueue.main.async {
                        var userDict = [String:String]()
                        userDict["companyName"] = companyName
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "FileDownloadNotCSV"), object: symbol, userInfo:  userDict) // send to StocksListVC
                    }
                    return
                }

                try FileManager.default.moveItem(at: tempURL, to: targetURL)
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "FileDownloadComplete"), object:   targetURL, userInfo: ["companySymbol": symbol]) // send to StocksListVC
                }

            } catch {
                
                DispatchQueue.main.async {
                    ErrorController.addErrorLog(errorLocation: #function, systemError: error, errorInfo: "can't move and save downloaded file")
                }
            }
        }

        downloadTask.resume()
    }
    
    /// returns the downloaded file in Notification with message  "FileDownloadComplete" with fileURL as object
    /// or returns with throwing an error
    class func downloadAndReturnFile(url: URL, symbol: String, completion: @escaping (URL?) -> Void) async -> Void {
        
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
                
                completion(targetURL)
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

extension Downloader: URLSessionTaskDelegate {

    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? {

        let object = request
        var info: [String:Any]?
        if let validTask = self.task {
            info = [String:Any]()
            info!["task"] = validTask
            info!["deallocate"] = self
        }
        let notification = Notification(name: Notification.Name(rawValue: "Redirection"), object: object, userInfo: info)
        NotificationCenter.default.post(notification)

        return nil
    }
}
