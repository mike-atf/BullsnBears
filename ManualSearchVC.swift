//
//  ManualSearchVC.swift
//  Bulls'N'Bears
//
//  Created by aDav on 28/04/2021.
//

import UIKit

class ManualSearchVC: UIViewController, UITextFieldDelegate {

    @IBOutlet var symbolTextField: UITextField!
    
    @IBOutlet var symbolFoundImage: UIImageView!
    @IBOutlet var nameFoundImage: UIImageView!
    @IBOutlet var companyNameLabel: UILabel!
    
    var symbol: String?
    var name: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        companyNameLabel.isHidden = true
        symbolTextField.becomeFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        guard textField.text != "" else { return false }
        textField.text = textField.text?.uppercased()
        
        if textField.placeholder == "Enter symbol" {
            symbol = textField.text
            findNameOnYahoo(symbol: symbol)
        }
        
        textField.resignFirstResponder()
        return false
    }

    
    func findNameOnYahoo(symbol: String?) {
        
        guard let name = symbol else {
            return
        }
        
        var urlComponents = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(name)/profile")
        urlComponents?.queryItems = [URLQueryItem(name: "p", value: name)]
        
        if let sourceURL = urlComponents?.url { // URL(fileURLWithPath: webPath)
            downloadWebData(sourceURL, stockName: name)
        }


    }
    
    func yahooStockDownload(_ ticker: String?) {
        
        guard let name = ticker else {
            return
        }

        let calendar = Calendar.current
        let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]
        var dateComponents = calendar.dateComponents(components, from: Date())
        dateComponents.second = 0
        dateComponents.minute = 0
        dateComponents.hour = 0
        dateComponents.year = 1970
        dateComponents.day = 1
        dateComponents.month = 1
        let yahooRefDate = calendar.date(from: dateComponents) ?? Date()
        let nowSinceRefDate = Date().timeIntervalSince(yahooRefDate)
        let start = nowSinceRefDate - TimeInterval(3600 * 24 * 366)
        
        let end$ = numberFormatter.string(from: nowSinceRefDate as NSNumber) ?? ""
        let start$ = numberFormatter.string(from: start as NSNumber) ?? ""
        
        var urlComponents = URLComponents(string: "https://query1.finance.yahoo.com/v7/finance/download/\(name)")
        urlComponents?.queryItems = [URLQueryItem(name: "period1", value: start$),URLQueryItem(name: "period2", value: end$),URLQueryItem(name: "interval", value: "1d"), URLQueryItem(name: "events", value: "history"), URLQueryItem(name: "includeAdjustedClose", value: "true") ]
                
        if let sourceURL = urlComponents?.url { // URL(fileURLWithPath: webPath)
            downLoadWebFile(sourceURL, stockName: name)
        }
    }
        
    func downLoadWebFile(_ url: URL, stockName: String) {
        
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpShouldSetCookies = true
        let session = URLSession(configuration: configuration)
        var downloadTask: URLSessionDownloadTask? // URLSessionDataTask stores downloaded data in memory, DownloadTask as File

        downloadTask = session.downloadTask(with: url) { [self]
            urlOrNil, responseOrNil, errorOrNil in
            
            guard errorOrNil == nil else {
                DispatchQueue.main.async {
                    symbolFoundImage.image = UIImage(systemName: "x.circle.fill")
                    symbolFoundImage.tintColor = UIColor.systemRed
                }
                return
            }
            
            guard responseOrNil != nil else {
                DispatchQueue.main.async {
                    symbolFoundImage.image = UIImage(systemName: "x.circle.fill")
                    symbolFoundImage.tintColor = UIColor.systemRed
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
                
                let tempURL = documentsURL.appendingPathComponent(stockName + "-temp.csv")
                let targetURL = documentsURL.appendingPathComponent(stockName + ".csv")
                
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    removeFile(tempURL)
                }

                    try FileManager.default.moveItem(at: fileURL, to: tempURL)
                

                    guard CSVImporter.matchesExpectedFormat(url: tempURL) else {
                        removeFile(tempURL)
                        return
                    }
                
                    if FileManager.default.fileExists(atPath: targetURL.path) {
                        removeFile(targetURL)
                    }

                    try FileManager.default.moveItem(at: tempURL, to: targetURL)

                    DispatchQueue.main.async {
                        self.symbolFoundImage.image = UIImage(systemName: "checkmark.circle.fill")
                        self.symbolFoundImage.tintColor = UIColor.systemGreen
                                     
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "DownloadAttemptComplete"), object:   targetURL, userInfo: ["companyName":self.companyNameLabel.text!]) // send to
                    }

            } catch {
                DispatchQueue.main.async {
                    self.symbolFoundImage.image = UIImage(systemName: "x.circle.fill")
                    self.symbolFoundImage.tintColor = UIColor.systemRed
                    ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "can't move and save downloaded file")
                }
            }
        }

        downloadTask?.resume()
    }
    
    func downloadWebData(_ url: URL, stockName: String) {
        
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpShouldSetCookies = true
        let session = URLSession(configuration: configuration)
        var downloadTask: URLSessionDataTask? // URLSessionDataTask stores downloaded data in memory, DownloadTask as File

        downloadTask = session.dataTask(with: url) { [self]
            data, urlResponse, error in
            
            guard error == nil else {
                DispatchQueue.main.async {
                    nameFoundImage.image = UIImage(systemName: "x.circle.fill")
                    nameFoundImage.tintColor = UIColor.systemRed
                }
                return
            }
            
            guard urlResponse != nil else {
                DispatchQueue.main.async {
                    nameFoundImage.image = UIImage(systemName: "x.circle.fill")
                    nameFoundImage.tintColor = UIColor.systemRed
                }
                return
            }
            
            guard let validData = data else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "stock keyratio download error - empty website data")
                nameFoundImage.tintColor = UIColor.systemRed
                nameFoundImage.image = UIImage(systemName: "x.circle.fill")
                return
            }

            let html$ = String(decoding: validData, as: UTF8.self)
            self.nameInWebData(html$: html$)
            
            
        }
        downloadTask?.resume()
    }
    
    func nameInWebData(html$: String) {
        
        let nameStarter = ">"
        let symbol$ = "(" + symbol! + ")"
        
        guard let symbolIndex = html$.range(of: symbol$) else {
            DispatchQueue.main.async {
                self.companyNameLabel.text = "Not found"
                self.companyNameLabel.isHidden = false
                self.nameFoundImage.image = UIImage(systemName: "x.circle.fill")
                self.nameFoundImage.tintColor = UIColor.systemRed
            }
            return
        }
        
        guard let nameStartIndex = html$.range(of: nameStarter, options: .backwards, range: html$.startIndex..<symbolIndex.upperBound, locale: nil) else {
            DispatchQueue.main.async {
                self.companyNameLabel.text = "Not found"
                self.companyNameLabel.isHidden = false
                self.nameFoundImage.image = UIImage(systemName: "x.circle.fill")
                self.nameFoundImage.tintColor = UIColor.systemRed
            }
            return
        }
        
        let name$ = html$[nameStartIndex.lowerBound..<symbolIndex.lowerBound].dropFirst()

        DispatchQueue.main.async {
            self.nameFoundImage.image = UIImage(systemName: "checkmark.circle.fill")
            self.nameFoundImage.tintColor = UIColor.systemGreen
            self.companyNameLabel.text = String(name$.dropLast())
            self.companyNameLabel.isHidden = false
        }

        yahooStockDownload(symbol)
    }
    
    private func removeFile(_ atURL: URL) {
       
        do {
            try FileManager.default.removeItem(at: atURL)
        } catch let error {
            DispatchQueue.main.async {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error trying to remove existing file in the Document folder to be able to move new file of same name from Inbox folder ")
            }
        }
    }

}
