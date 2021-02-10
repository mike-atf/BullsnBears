//
//  StockSymbolEntry.swift
//  Bulls'N'Bears
//
//  Created by aDav on 19/01/2021.
//

import UIKit

class StockSymbolEntry: UIViewController, UITextFieldDelegate {

    
    @IBOutlet var searchField: UITextField!
    @IBOutlet var textLabel: UILabel!
    
    var rootView: StocksListViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        searchField.becomeFirstResponder()
        textLabel.text = " "
        
    }
        
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        yahooStockDownload(textField.text)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func yahooStockDownload(_ ticker: String?) {
        
        guard let name = ticker else {
            return
        }

// NEW
//        let newStock = Stock(name: name, dailyPrices: [], fileURL: nil)
//        newStock.updatePrices()
//        stocks.append(newStock)
//
//        self.dismiss(animated: true, completion: {
//            self.rootView.tableView.reloadData()
//        })
//
        
//        let numberFormatter: NumberFormatter = {
//            let formatter = NumberFormatter()
//            formatter.maximumFractionDigits = 0
//            formatter.minimumIntegerDigits = 1
//            return formatter
//        }()
//
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
        
        var webPath = "https://query1.finance.yahoo.com/v7/finance/download/"
        webPath += name+"?"
        webPath += "period1=" + start$
        webPath += "&period2=" + end$
        webPath += "&interval=1d&events=history&includeAdjustedClose=true"
        
        if let sourceURL = urlComponents?.url { // URL(fileURLWithPath: webPath)
            downLoadWebFile(sourceURL, stockName: name)
        }

    }
    
    func downLoadWebFile(_ url: URL, stockName: String) {
        
        let downloadTask = URLSession.shared.downloadTask(with: url) { [self]
            urlOrNil, responseOrNil, errorOrNil in
            
            guard errorOrNil == nil else {
                DispatchQueue.main.async {
                    self.textLabel.text = errorOrNil?.localizedDescription
                    self.textLabel.textColor = UIColor(named: "Red")
                }
                return
            }
            
            guard responseOrNil != nil else {
                DispatchQueue.main.async {
                    self.textLabel.text = responseOrNil?.textEncodingName
                    self.textLabel.textColor = UIColor(named: "Red")
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
                
                let savedURL = documentsURL.appendingPathComponent(stockName + ".csv")
                                
                if FileManager.default.fileExists(atPath: savedURL.path) {
                    removeFile(savedURL)
                }

                try FileManager.default.moveItem(at: fileURL, to: savedURL)
                
                if !CSVImporter.matchesExpectedFormat(url: savedURL) {
                    removeFile(savedURL)
                    DispatchQueue.main.async {
                        self.textLabel.text = "No matching stock, or file error"
                        self.searchField.text = nil
                        self.textLabel.textColor = UIColor(named: "Red")
                        self.searchField.becomeFirstResponder()
                    }
                    return
                } else {
                    DispatchQueue.main.async  {
                        self.dismiss(animated: true, completion: {
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "DownloadAttemptComplete"), object: savedURL, userInfo: nil)
                        })
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "can't move and save downloaded file")
                }
            }
        }
        
//        DispatchQueue.main.async {
            downloadTask.resume()
//        }
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

    
//    @IBAction func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//
//
//
//        textField.resignFirstResponder()
//        return true
//    }

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
