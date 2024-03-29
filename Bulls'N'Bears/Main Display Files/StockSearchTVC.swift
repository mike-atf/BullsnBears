//
//  StockSearchTVC.swift
//  Bulls'N'Bears
//
//  Created by aDav on 11/02/2021.
//

import UIKit

protocol StockSearchDataDownloadDelegate {
    func addNewShare(symbol: String, prices: [PricePoint]?)
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
        
            if let searchTerm = searchBar.text?.uppercased() {
                findOtherSharesOnYahoo(searchTerm: searchTerm)
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
    /// if downloaded file not in .csv format Downloader sends notification to start data download instead
    func newCompanyDataDownload(_ ticker: String?, companyName: String?) {
        
        guard let symbol = ticker else {
            return
        }

        guard companyName != nil else {
            return
        }
        
        Task.init(priority: .background) {
            
            if let prices = await YahooPageScraper.dailyPricesDownloadCSV(symbol: symbol) {
                DispatchQueue.main.async {
                    self.callingVC.addShare(url: nil, pricePoints: prices, symbol: symbol, companyName: companyName)
                }
            }
            else if let prices = await dataDownload(symbol: symbol, companyName: companyName!) {
                DispatchQueue.main.async {
                    self.callingVC.addShare(url: nil, pricePoints: prices, symbol: symbol, companyName: companyName)
                }
            }
        }
        
    }
    
    func dataDownload(symbol: String, companyName: String) async -> [PricePoint]? {
        
        let tenYearsSinceRefDate = yahooPricesStartDate.timeIntervalSince(yahooRefDate)
        let nowSinceRefDate = Date().timeIntervalSince(yahooRefDate)

        let start$ = numberFormatter.string(from: tenYearsSinceRefDate as NSNumber) ?? ""
        let end$ = numberFormatter.string(from: nowSinceRefDate as NSNumber) ?? ""
        
        var urlComponents = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(symbol)/history")
        urlComponents?.queryItems = [URLQueryItem(name: "period1", value: end$),URLQueryItem(name: "period2", value: start$),URLQueryItem(name: "interval", value: "1d"),URLQueryItem(name: "includeAdjustedClose", value: "true") ]

        // second, if file download fails download price page table and extract price data
        if let sourceURL = urlComponents?.url {
            return await downloadYahooPriceData(sourceURL, stockName: companyName)
            
        }
        
        return nil

    }

    
    private func removeFile(_ atURL: URL) {
       
        do {
            try FileManager.default.removeItem(at: atURL)
        } catch let error {
            DispatchQueue.main.async {
                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "StockSearchTVC  -error trying to remove existing file \(atURL) in the Document folder to be able to move new file of same name from Inbox folder ")
            }
        }
    }
    
    //MARK: - find new symbol on Yahoo
    
    func findOtherSharesOnYahoo(searchTerm: String?) {
        
        guard let name = searchTerm else {
            return
        }
        
        var urlComponents = URLComponents(string: "https://uk.finance.yahoo.com/quote/\(name)")
        urlComponents?.queryItems = [URLQueryItem(name: "p", value: name)]
        
        if let sourceURL = urlComponents?.url { // URL(string: "https://uk.finance.yahoo.com/quote/\(name)")
            
            Task.init(priority: .background) {
                do {
                    try await downloadYahooNameSearchPage(sourceURL)
                } catch {
                    ErrorController.addInternalError(errorLocation: "StockSearchTVC.findNameOnYahoo", systemError: nil, errorInfo: "failed web data download \(error.localizedDescription)")
                }
            }

        }
    }
    
    func downloadYahooNameSearchPage(_ url: URL) async throws {
        
        var htmlText = String()
        do {
            htmlText = try await Downloader.downloadData(url: url)
            
            let namesDict = try YahooPageScraper.companyNamesListSearchOnPage(html: htmlText)
            
            DispatchQueue.main.async { [self] in
                if namesDict != nil {
                    stockTickerDictionary?.merge(namesDict!) {(current,_) in current}
                    stocksDictionary.append(contentsOf: Array(namesDict!))
                    stocksDictionary.sort { e0, e1 in
                        if e0.key < e1.key { return true }
                        else { return false }
                    }
                }
                else {
                    self.stocksDictionary.insert((key: "NotFound", value: ""), at: 0)
                }
                self.tableView.reloadData()
            }
            
        } catch {
            if let ierror = error as? InternalError {
                ErrorController.addInternalError(errorLocation: ierror.location, systemError: nil, errorInfo: ierror.errorInfo)
            }
            ErrorController.addInternalError(errorLocation: "StockSearchTVC.downloadYahooNameSearchPage", systemError: nil, errorInfo: "Error downloading other company data from Yahoo: \(error.localizedDescription)")
        }

    }


    func downloadYahooPriceData(_ url: URL, stockName: String) async -> [PricePoint]? {
        
        var htmlText = String()
        do {
            htmlText = try await Downloader.downloadData(url: url)
            
            let oneYearAgo = Date().addingTimeInterval(-year)
            return YahooPageScraper.priceTableAnalyse(html$: htmlText, limitDate: oneYearAgo)
                    
        } catch {
            ErrorController.addInternalError(errorLocation: "StockSearchTVC.downloadYahooPriceData", systemError: nil, errorInfo: "Error downloading historical price WB Valuation data: \(error.localizedDescription)")
        }
        
        return nil

    }

}
