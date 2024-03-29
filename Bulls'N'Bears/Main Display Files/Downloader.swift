//
//  Downloader.swift
//  Bulls'N'Bears
//
//  Created by aDav on 04/11/2021.
//

import Foundation
import WebKit

enum DownloadTask {
    case test
    case epsPER
    case qEPS
    case wbValuation
    case r1Valuation
    case healthData
}

protocol CSVFileDownloadDelegate {
    
    func csvFileDownloadComplete(localURL: URL, companyName: String)
    func csvFileDownloadWithHeaderError(symbol: String, companyName: String)
    func dataDownloadCompleted(results: [DatedValue]?)
}

class Downloader: NSObject {
    
    var task: DownloadTask?
    
    //MARK: - instance methods
    convenience init(task: DownloadTask) {
        self.init()
        
        self.task = task
    }
        
    ///  posts notificaiton "Redirection" with object: URlReqeust and userInfo [task:Dowloadtask] and [dellocate:Downloader]; see below URLSessionTaskDelegate
    ///  caller should add a  DownloadRedirectionDelegate observer to NotificationCenter.default to receive any redirection nofitications
    func downloadDataWithRedirection(url: URL?) async throws -> String? {
        
        guard url != nil else {
            throw InternalError(location: #function, errorInfo: "Invalid url download request", errorType: .urlInvalid)
        }
        
        let request = URLRequest(url: url!)
            
        let (data,urlResponse) = try await URLSession.shared.data(for: request,delegate: self)
        
        if let response = urlResponse as? HTTPURLResponse {
            if response.statusCode == 200 {
                if response.mimeType == "text/html" {
                  return String(data: data, encoding: .utf8) ?? ""
                }
                else {
                    throw InternalError(location: #function, errorInfo: "download response error for \(url!), mimeType not text but \(String(describing: response.mimeType))", errorType: .mimeType)
                }
            }
            else {
                throw InternalError(location: #function, errorInfo: "download error for \(url!), response \(String(describing: response.statusCode))", errorType: .statusCodeError)
            }
        }
        
        return nil
    }
    
    class func downloadDataWithRedirectionOption(url: URL?) async -> String? {
        
        guard url != nil else {
            return nil
        }
        
        let request = URLRequest(url: url!)
            
        do {
            let (data,urlResponse) = try await URLSession.shared.data(for: request)
            if let response = urlResponse as? HTTPURLResponse {
                if response.statusCode == 200 {
                    if response.mimeType == "text/html" {
                      return String(data: data, encoding: .utf8) ?? ""
                    }
                    else {
                        ErrorController.addInternalError(errorLocation: #function, errorInfo: "download response error for \(url!), mimeType not text but \(String(describing: response.mimeType))", type: .mimeType)
                    }
                }
                else if response.statusCode == 301 {
                    if let location = response.value(forHTTPHeaderField: "Location") {
                        return await downloadDataNoThrow(url: URL(string: location))
                    }
                } else {

                    ErrorController.addInternalError(errorLocation: #function, errorInfo: "download response error for \(url!), response \(String(describing: response.statusCode))", type: .statusCodeError)
                }
            }
        } catch {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "download  with redirection response error for \(url!)", type: .mimeType)
            return nil
        }
        
        return nil

    }

    //MARK: - class functions
    
    /// returns true if download results in htmlText, false if not
    /// calls delegate if redirect results (shortName wrong), in this case may return  nil
    /// delegate should extract correct short name for MT from request.url in delegate method
    class func mtTestDownload(url: URL, delegate: DownloadRedirectionDelegate) async -> Bool? {
        
            let html$ = await downloadDataWithRedirectionOption(url: url)

            if let validPageText = html$ {
                if validPageText != "" {
                    return true
                }
                else { return false }
            }
            else { return false }
    }
    
    class func downloadData(url: URL?) async throws -> String {
        
        guard url != nil else {
            throw InternalError(location: #function, errorInfo: "invalid url download attempt", errorType: .urlInvalid)
        }
        
        let request = URLRequest(url: url!)
            
        let (data,urlResponse) = try await URLSession.shared.data(for: request)
        var htmlText = String()
        
        if let response = urlResponse as? HTTPURLResponse {
            if response.statusCode == 200 {
                if response.mimeType == "text/html" {
                    htmlText = String(data: data, encoding: .utf8) ?? ""
                }
                else {
                    throw InternalError(location: #function, errorInfo: "download response error for \(url!), mimeType not text but \(String(describing: response.mimeType))", errorType: .mimeType)
                }
            }
            else {
                throw InternalError(location: #function, errorInfo: "download error for \(url!), response \(String(describing: response.statusCode))", errorType: .statusCodeError)
            }
        }
        
        return htmlText
    }
    
    class func downloadDataNoThrow(url: URL?) async -> String? {
        
        guard url != nil else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "url is nil")
            return nil
        }
        
        let request = URLRequest(url: url!)
            
        do {
            let (data,urlResponse) = try await URLSession.shared.data(for: request)
            
            if let response = urlResponse as? HTTPURLResponse {
                if response.statusCode == 200 {
                    if response.mimeType == "text/html" {
                        return String(data: data, encoding: .utf8) ?? ""
                    }
                    else {
                        ErrorController.addInternalError(errorLocation: #function, errorInfo: "non-text response")
                        return nil
                    }
                }
                else {
                    ErrorController.addInternalError(errorLocation: #function, errorInfo: "unexpected download response \(urlResponse) for url \(String(describing: url))")
                    return nil
                }
            }
            else {
                ErrorController.addInternalError(errorLocation: #function, errorInfo: "download of url \(String(describing: url)) failed, there was nil response")
                return nil
            }
        } catch {
            ErrorController.addInternalError(errorLocation: #function, systemError: error ,errorInfo: "download error for \(url!)")
            return nil
        }
        
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
                    throw InternalError(location: #function, errorInfo: "download response error for \(String(describing: request?.url)), mimeType not text but \(String(describing: response.mimeType))", errorType: .mimeType)
                }
            }
            else {
                throw InternalError(location: #function, errorInfo: "download error for \(String(describing: request?.url)), response \(String(describing: response.statusCode))", errorType: .statusCodeError)
            }
        }
        
        return htmlText
    }

    
    /// does NOT check header titles; for 'type' use _Div , _PPoints or _TB as without these files dividend and pricePoint files will overwrite each other
    class func downloadCSVFile2(url: URL, symbol: String, type: String) async throws -> URL? {
        
        let (tempURL, _) = try await URLSession.shared.download(from: url)
        do {
            let documentsURL = try
                FileManager.default.url(for: .documentDirectory,
                                        in: .userDomainMask,
                                        appropriateFor: nil,
                                        create: true)
            
            let targetURL = documentsURL.appendingPathComponent(symbol + type + ".csv")
            
            if FileManager.default.fileExists(atPath: targetURL.path) {
                removeFile(targetURL)
            }

            try FileManager.default.moveItem(at: tempURL, to: targetURL)

            return targetURL
                                
        } catch {
            DispatchQueue.main.async {
                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "can't move and save downloaded file \(tempURL)")
            }
        }

        return nil
        
    }
    
    class func removeFile(_ atURL: URL) {
       
        do {
            try FileManager.default.removeItem(at: atURL)
        } catch let error {
            DispatchQueue.main.async {
                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "Downloader - error trying to remove existing file \(atURL) in the Document folder to be able to move new file of same name from Inbox folder ")
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
