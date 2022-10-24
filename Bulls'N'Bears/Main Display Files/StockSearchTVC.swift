//
//  StockSearchTVC.swift
//  Bulls'N'Bears
//
//  Created by aDav on 11/02/2021.
//

import UIKit

protocol StockSearchDataDownloadDelegate {
    func newShare(symbol: String, prices: [PricePoint]?)
}

class StockSearchTVC: UITableViewController, UISearchBarDelegate, UISearchResultsUpdating, UISearchControllerDelegate {
    
    var searchController: UISearchController?
    weak var callingVC: StocksListTVC!
    var downloadDelegate: StockSearchDataDownloadDelegate?
    
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
        newCompanyDataDownload(stocksDictionary[indexPath.row].key, companyName: stocksDictionary[indexPath.row].value)
        self.navigationController?.popToRootViewController(animated: true)

    }
    
    /// attempts to download from Yahoo finance either price as file
    /// if downloaded file not in .csv format Downloader sends notification to start data download insteae
    func newCompanyDataDownload(_ ticker: String?, companyName: String?) {
        
        guard let symbol = ticker else {
            return
        }

        guard companyName != nil else {
            return
        }
        
        let nowSinceRefDate = yahooPricesStartDate.timeIntervalSince(yahooRefDate)
        let yearAgoSinceRefDate = yahooPricesEndDate.timeIntervalSince(yahooRefDate)

        let start$ = numberFormatter.string(from: nowSinceRefDate as NSNumber) ?? ""
        let end$ = numberFormatter.string(from: yearAgoSinceRefDate as NSNumber) ?? ""
        
        var urlComponents = URLComponents(string: "https://query1.finance.yahoo.com/v7/finance/download/\(symbol)")
        urlComponents?.queryItems = [URLQueryItem(name: "period1", value: start$),URLQueryItem(name: "period2", value: end$),URLQueryItem(name: "interval", value: "1d"), URLQueryItem(name: "events", value: "history"), URLQueryItem(name: "includeAdjustedClose", value: "true") ]
        
        
        if let sourceURL = urlComponents?.url { // URL(fileURLWithPath: webPath)
            
            NotificationCenter.default.addObserver(self, selector: #selector(dataDownload(notification:)), name: Notification.Name(rawValue: "FileDownloadNotCSV"), object: nil)

            // first try to download historical prices from Yahoo finance as CSV file
            Task.init(priority: .background) {
                    // the next functions returns by sending notification 'FileDownloadComplete' with fileURL in object sent
                    // this should be picked up by StocksListTVC
                await Downloader.downloadCSVFile(url: sourceURL, symbol: symbol, companyName: companyName!, expectedHeaderTitles: ["Date","Open","High","Low","Close","Adj Close","Volume"])
            }
        }
    }
    
    /// called by notification from  Downloader if Yahoo file downloaded is not in .csv format
    @objc
    func dataDownload(notification: Notification) async {
        
        guard let symbol = notification.object as? String else { return }
        
        guard let companyName = notification.userInfo?["companyName"] as? String else { return }

        var urlComponents = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)/history?")
        urlComponents?.queryItems = [URLQueryItem(name: "p", value: symbol)]
        
        // second, if file download fails download price page table and extract price data
        if let sourceURL = urlComponents?.url { // URL(fileURLWithPath: webPath)
            do {
                try await downloadWebData(sourceURL, stockName: companyName, task: "priceHistory")
            } catch let error {
                alertController.showDialog(title: "Dowload failed", alertMessage: "can't find any company data for \(symbol) on Yahoo finance \(error.localizedDescription)")
                return
            }
        }

    }

    
    private func removeFile(_ atURL: URL) {
       
        do {
            try FileManager.default.removeItem(at: atURL)
        } catch let error {
            DispatchQueue.main.async {
                ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error trying to remove existing file in the Document folder to be able to move new file of same name from Inbox folder ")
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
            Task.init(priority: .background) {
                do {
                    try await downloadWebData(sourceURL, stockName: name, task: "name")
                } catch let error {
                    ErrorController.addInternalError(errorLocation: "StockSearchTVC.findNameOnYahoo", systemError: nil, errorInfo: "failed web data download \(error.localizedDescription)")
                }
            }

        }


    }

    func downloadWebData(_ url: URL, stockName: String, task: String) async throws {
        
        var htmlText = String()
        do {
            htmlText = try await Downloader.downloadData(url: url)
            
            if task == "name" {
                self.nameInWebData(html$: htmlText, symbol: stockName)
            }
            else if task == "priceHistory" {
                let pricePoints = WebPageScraper2.analyseYahooPriceTable(html$: htmlText)
                
                DispatchQueue.main.async {
                    self.downloadDelegate?.newShare(symbol: stockName,  prices: pricePoints)
                }
            }
 
            
        } catch let error {
            ErrorController.addInternalError(errorLocation: "WPS2.downloadAnalyseSaveWBValuationData", systemError: nil, errorInfo: "Error downloading historical price WB Valuation data: \(error.localizedDescription)")
        }

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
            stockTickerDictionary?[symbol] = String(name$.dropLast()) // TODO: - doesn't save expanded dictionary to file!!
            self.tableView.reloadData()
        }

    }


}
