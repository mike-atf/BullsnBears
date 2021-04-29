//
//  StockSearchTVC.swift
//  Bulls'N'Bears
//
//  Created by aDav on 11/02/2021.
//

import UIKit

class StockSearchTVC: UITableViewController, UISearchBarDelegate, UISearchResultsUpdating, UISearchControllerDelegate {
    
    var searchController: UISearchController?
    weak var callingVC: StocksListTVC!
    
    var stocksDictionary = Array<(key:String, value:String)>() // [String:String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        searchController = UISearchController(searchResultsController: nil)
        searchController?.searchResultsUpdater = self
        searchController?.searchBar.placeholder = "Enter Symbol - if not listed tap Search"
        searchController?.delegate = self
        searchController?.searchBar.delegate = self
        navigationItem.searchController = searchController
        definesPresentationContext = true
                
//        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addManual))
//        self.navigationItem.rightBarButtonItem = addButton

    }

    override func viewDidAppear(_ animated: Bool) {
        DispatchQueue.main.async {
            self.searchController?.searchBar.becomeFirstResponder()
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return stocksDictionary.count
    }

    func updateSearchResults(for searchController: UISearchController) {
        
        
        guard let searchText = searchController.searchBar.text  else {
            return
        }
        
        guard searchText != "" else {
            return
        }
        
        guard stockTickerDictionary != nil else {
            return
        }
        
        let uSearch$ = searchText.uppercased()
        let cSearch$ = searchText.capitalized
        
        stocksDictionary = stockTickerDictionary!.filter({ (element) -> Bool in
            if element.key.starts(with: uSearch$) { return true }
            else if element.value.starts(with: cSearch$) { return true }
            else { return false }
        }).sorted {
            return $0.key < $1.key
        }
        
        tableView.reloadData()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
        if stocksDictionary.count == 0 {
            // no stock found in dictionary
            if let requestedSymbol = searchBar.text?.uppercased() {
                findNameOnYahoo(symbol: requestedSymbol)
            }
        }
        
        searchBar.resignFirstResponder()
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "stockSearchCell", for: indexPath)

        if let title = cell.viewWithTag(10) as? UILabel {
            title.text = stocksDictionary[indexPath.row].key
        }
        
        if let detail = cell.viewWithTag(20) as? UILabel {
            detail.text = stocksDictionary[indexPath.row].value
        }


        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: false)
        yahooStockDownload(stocksDictionary[indexPath.row].key, companyName: stocksDictionary[indexPath.row].value)
        self.navigationController?.popToRootViewController(animated: true)

    }
    
//    @objc
//    func addManual() {
//
//        guard let manualSearchVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ManualSearchVC") as? ManualSearchVC else {
//            return
//        }
//        manualSearchVC.loadViewIfNeeded()
//
//        self.navigationController?.pushViewController(manualSearchVC, animated: true)
//
//    }

    func yahooStockDownload(_ ticker: String?, companyName: String?) {
        
        guard let symbol = ticker else {
            return
        }

        guard companyName != nil else {
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
        
        var urlComponents = URLComponents(string: "https://query1.finance.yahoo.com/v7/finance/download/\(symbol)")
        urlComponents?.queryItems = [URLQueryItem(name: "period1", value: start$),URLQueryItem(name: "period2", value: end$),URLQueryItem(name: "interval", value: "1d"), URLQueryItem(name: "events", value: "history"), URLQueryItem(name: "includeAdjustedClose", value: "true") ]
        
        
        if let sourceURL = urlComponents?.url { // URL(fileURLWithPath: webPath)
            downLoadWebFile(sourceURL, symbol: symbol, companyName: companyName!)
        }
    }
        
    func downLoadWebFile(_ url: URL, symbol: String, companyName: String) {
        
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpShouldSetCookies = true
        let session = URLSession(configuration: configuration)
        var downloadTask: URLSessionDownloadTask? // URLSessionDataTask stores downloaded data in memory, DownloadTask as File

        downloadTask = session.downloadTask(with: url) { [self]
            urlOrNil, responseOrNil, errorOrNil in
            
            guard errorOrNil == nil else {
                DispatchQueue.main.async {
                    alertController.showDialog(title: "Download error", alertMessage: "couldn't download \(symbol) due to error \(errorOrNil!.localizedDescription)", viewController: self, delegate: nil)
                }
                return
            }
            
            guard responseOrNil != nil else {
                DispatchQueue.main.async {
                    alertController.showDialog(title: "Download error", alertMessage: "couldn't download \(symbol) due to error \(String(describing: responseOrNil!.textEncodingName))", viewController: self, delegate: nil)
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
                

                    guard CSVImporter.matchesExpectedFormat(url: tempURL) else {
                        removeFile(tempURL)
                        return
                    }
                
                    if FileManager.default.fileExists(atPath: targetURL.path) {
                        removeFile(targetURL)
                    }

                    try FileManager.default.moveItem(at: tempURL, to: targetURL)

                    DispatchQueue.main.async {

                        NotificationCenter.default.post(name: Notification.Name(rawValue: "DownloadAttemptComplete"), object:   targetURL, userInfo: ["companyName": companyName]) // send to StocksListVC
                    
                    // the Company profile (industry, sector and employees) is downloaded after this in StocksController called from StocksListVC as delegate of this here download
                    }

            } catch {
                DispatchQueue.main.async {
                    ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "can't move and save downloaded file")
                }
            }
        }

        downloadTask?.resume()
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
    
    //MARK: - find new symbol on Yahoo
    
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
                    stocksDictionary.insert((key: "NotFound", value: "Not found"), at: 0)
                    self.tableView.reloadData()
                }
                return
            }
            
            guard urlResponse != nil else {
                DispatchQueue.main.async {
                    stocksDictionary.insert((key: "NotFound", value: "Not found"), at: 0)
                    self.tableView.reloadData()
                }
                return
            }
            
            guard let validData = data else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "stock keyratio download error - empty website data")
                stocksDictionary.insert((key: "NotFound", value: "Not found"), at: 0)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                return
            }

            let html$ = String(decoding: validData, as: UTF8.self)
            self.nameInWebData(html$: html$, symbol: stockName)
            
            
        }
        downloadTask?.resume()
    }
    
    func nameInWebData(html$: String, symbol: String) {
        
        let nameStarter = ">"
        let symbol$ = "(" + symbol + ")"
        
        guard let symbolIndex = html$.range(of: symbol$) else {
            DispatchQueue.main.async {
                self.stocksDictionary.insert((key: "NotFound", value: "Not found"), at: 0)
                self.tableView.reloadData()
            }
            return
        }
        
        guard let nameStartIndex = html$.range(of: nameStarter, options: .backwards, range: html$.startIndex..<symbolIndex.upperBound, locale: nil) else {
            DispatchQueue.main.async {
                self.stocksDictionary.insert((key: "NotFound", value: "Not found"), at: 0)
                self.tableView.reloadData()
            }
            return
        }
        
        let name$ = html$[nameStartIndex.lowerBound..<symbolIndex.lowerBound].dropFirst()

        DispatchQueue.main.async {
            self.stocksDictionary.insert((key: symbol, value: String(name$.dropLast())), at: 0)
            self.tableView.reloadData()
        }

//        yahooStockDownload(symbol)
    }


}
