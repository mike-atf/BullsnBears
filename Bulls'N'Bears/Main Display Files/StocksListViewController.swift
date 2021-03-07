//
//  StocksListViewController.swift
//  TrendMyStocks
//
//  Created by aDav on 01/12/2020.
//

import UIKit
import CoreData

//protocol StocksListDelegate: NSObject {
//    func showValueListChart(array: [Double]?)
//    func removeValueListChart()
//}

class StocksListViewController: UITableViewController {
    
    @IBOutlet var addButton: UIBarButtonItem!
    @IBOutlet var downloadButton: UIBarButtonItem!
    
    var controller: StocksController?
//    weak var valueChartDelegate: StocksListDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "StockListCellTableViewCell", bundle: nil), forCellReuseIdentifier: "stockListCell")
        
        controller = StocksController(delegate: self)
        controller?.loadStockFiles()
        
        NotificationCenter.default.addObserver(self, selector: #selector(filesReceivedInBackground(notification:)), name: Notification.Name(rawValue: "NewFilesArrived"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(fileDownloaded(_:)), name: Notification.Name(rawValue: "DownloadAttemptComplete"), object: nil)
                
        NotificationCenter.default.addObserver(self, selector: #selector(updateOrderReturningFromWBValuationTVC(notification:)), name: NSNotification.Name(rawValue: "refreshStockListTVCRow"), object: nil)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        controller?.updateStockFiles()
        tableView.reloadData()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func addButtonAction(_ sender: Any) {
        
        if let docBrowser = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DocBrowserView") as? DocumentBrowserViewController {

            docBrowser.stockListVC = self
            self.present(docBrowser, animated: true)
            
        }
    }
    
    func showWelcomeView() {
        
        let welcomeView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WelcomeViewController")
        
        welcomeView.loadViewIfNeeded()
        
        self.present(welcomeView, animated: true) {
            if let textView = welcomeView.view.viewWithTag(10) as? UITextView {
                let text = "Thank you for trying Bulls 'N' Bears\n\nThe App displays candle stick charts from .csv files you need to download or import from the Files App, and shows various price trends you select (color buttons).\n\nIt calculates fair share price estimates from data you enter or download from public websites.\n\nHow does it work?\n1. Add a stock using the download button at the top of the list (or import csv files with '+' which you download from 'Yahoo finance' > 'Historical Data').\n2.Select trends by toggling color and time buttons\n(A = all, 3 = 3 months, 1 = 1 month\n4. To get a fair price estimate tap the '$' of a stock listed, then chose a valuation method.\n5. Either let Bulls'N'Bears try to download required data, or enter these from Yahoo finance, MacroTrends or another source, and then adapt predicted values and save."
                textView.text = text
            }

        }
        
    }
        
    public func openDocumentBrowser(with remoteURL: URL, importIfNeeded: Bool) {
        
        if let docBrowser = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DocBrowserView") as?  DocumentBrowserViewController {
        
            self.present(docBrowser, animated: true) {
                docBrowser.openRemoteDocument(remoteURL, importIfNeeded: importIfNeeded)
            }
        }
    }
    
    @objc
    func filesReceivedInBackground(notification: Notification) {
        
        if let paths = notification.object as? [String] {
            for path in paths {
                addStock(fileURL: URL(fileURLWithPath: path))
            }
        }
    }
    
    @objc
    func fileDownloaded(_ notification: Notification) {

        if let url = notification.object as? URL {
            addStock(fileURL: url)
        }
    }
    
    public func addStock(fileURL: URL) {
        
        if let stock = CSVImporter.csvExtractor(url: fileURL) {
            stocks.append(stock)
            
            tableView.reloadData()
            // causing crash on Hanski's iPad - why???
            tableView.selectRow(at: IndexPath(item: stocks.count-1, section: 0), animated: true, scrollPosition: .bottom)
            tableView.delegate?.tableView?(self.tableView, didSelectRowAt: IndexPath(item: stocks.count-1, section: 0))
            performSegue(withIdentifier: "stockSelectionSegue", sender: nil)
        }

    }
    
    @objc
    func updateOrderReturningFromWBValuationTVC(notification: Notification) {
        
//        stocks = (controller!.sortStocksByRatings(stocks: stocks))
//        tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return stocks.count < 1 ? 0 : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return stocks.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "stockListCell", for: indexPath) as! StockListCellTableViewCell

        let userRatingData = stocks[indexPath.row].userRatingScore // WBValuationController.summaryRating(symbol: stocks[indexPath.row].symbol, type: .star)
        let valueRatingData = stocks[indexPath.row].fundamentalsScore // WBValuationController.summaryRating(symbol: stocks[indexPath.row].symbol, type: .dollar)
        cell.configureCell(indexPath: indexPath, stock: stocks[indexPath.row], userRatingData: userRatingData, valueRatingData: valueRatingData)
        
        return cell
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete")
        { (action, view, bool) in
            
            let objectToDelete = stocks[indexPath.row]

            if let validURL = objectToDelete.fileURL {
                do {
                    try FileManager.default.removeItem(at: validURL)
                }
                catch let error {
                    ErrorController.addErrorLog(errorLocation: "ValuationController." + #function, systemError: error, errorInfo: "couldn't remove stock file ")
                }
            }
            
            stocks.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
            
            let swipeActions = UISwipeActionsConfiguration(actions: [deleteAction])
        
            return swipeActions

    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let wbValuationView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WBValuationTVC") as? WBValuationTVC else { return }

        wbValuationView.stock = stocks[indexPath.row]
        wbValuationView.fromIndexPath = indexPath
        wbValuationView.controller = WBValuationController(stock: stocks[indexPath.row], progressDelegate: wbValuationView)
        
        if stocks[indexPath.row].peRatio == nil {
            stocks[indexPath.row].downloadKeyRatios(delegate: wbValuationView)
        }

        performSegue(withIdentifier: "stockSelectionSegue", sender: nil)
        
        navigationController?.pushViewController(wbValuationView, animated: true)
    }
    
    func valuationCompleted(indexPath: IndexPath) {
        tableView.reloadRows(at: [indexPath], with: .automatic)
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        performSegue(withIdentifier: "stockSelectionSegue", sender: nil)
    }
    
        
    @IBAction func downloadAction(_ sender: Any) {
        
        guard let entryView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "StockSearchTVC") as? StockSearchTVC else { return }

        entryView.callingVC = self
        
        navigationController?.pushViewController(entryView, animated: true)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let chartView = segue.destination as? StockChartVC {
            if let indexPath = tableView.indexPathForSelectedRow {
                
                chartView.stockToShow = stocks[indexPath.row]
                chartView.configure()
                
//                self.valueChartDelegate = chartView

            }
        }
        else if let navView = segue.destination as? UINavigationController {
            if let chartView = navView.topViewController as? StockChartVC {
                if let indexPath = tableView.indexPathForSelectedRow {
                    
                    chartView.stockToShow = stocks[indexPath.row]
                    chartView.configure()
                    
//                    self.valueChartDelegate = chartView
                }
            }
        }
    }

}

extension StocksListViewController: StockControllerDelegate {
    
    func updateStocksComplete() {
        self.tableView.reloadData()
        if stocks.count > 0 {
            if tableView.indexPathForSelectedRow == nil {
                tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .top)
                tableView.deselectRow(at: IndexPath(row: 0, section: 0), animated: true)
            }
            performSegue(withIdentifier: "stockSelectionSegue", sender: nil)
        }
    }
    
    func openStocksComplete() {
        
        if stocks.count > 0 {
            self.tableView.reloadData()
            tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .top)
            tableView.deselectRow(at: IndexPath(row: 0, section: 0), animated: true)
            performSegue(withIdentifier: "stockSelectionSegue", sender: nil)
            tableView.deselectRow(at: IndexPath(row: 0, section: 0), animated: true)
        }
        else {
            showWelcomeView()
        }
    }
    
}

//extension StocksListViewController: WBValuationListDelegate {
//
//    func sendArrayForDisplay(array: [Double]?) {
//
//        self.valueChartDelegate?.showValueListChart(array: array)
//    }
//
//    func removeValueChart() {
//
//        self.valueChartDelegate?.removeValueListChart()
//    }
//
//
//}
