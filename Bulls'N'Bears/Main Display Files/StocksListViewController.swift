//
//  StocksListViewController.swift
//  TrendMyStocks
//
//  Created by aDav on 01/12/2020.
//

import UIKit
import CoreData

class StocksListViewController: UITableViewController {
    
    @IBOutlet var addButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "StockListCellTableViewCell", bundle: nil), forCellReuseIdentifier: "stockListCell")
        openCSCFilesInDocumentDirectory()
        
        NotificationCenter.default.addObserver(self, selector: #selector(filesReceivedInBackground(notification:)), name: Notification.Name(rawValue: "NewFilesArrived"), object: nil)
        
        if stocks.count == 0 {
            showWelcomeView()
        }
        
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
                let text = "Thank you for trying Bulls 'N' Bears\n\nThe App displays candle stick charts from .csv files you need to import, and calculates and displays various price trends.\n\nIt also allows calculating a fair share price estimate from data you enter.\n\nHow does it work?\n1. Go to Yahoo Finance, select a stock, and download 'Historical Data' as .csv file.\n2. Inside this App, tap + to import the csv. file from where you downloaded it to on our device.\n\n3.Select trends by toggling color and time buttons\n(A = all, 3 = 3 months, 1 = 1 month\n4. To get a fair price estimate tap the '$' of a stock listed, then chose a valuation method.\n5. Then enter all required data from Yahoo finance or another source, and save."
                textView.text = text
            }

        }
        
    }
    
    
    @objc
    func openCSCFilesInDocumentDirectory() {
        
        let appDocumentPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if let documentFolder = appDocumentPaths.first {
            
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: documentFolder), includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                
                for url in fileURLs {
                    if url.lastPathComponent.contains(".csv") {
                        guard url.startAccessingSecurityScopedResource() else {
                            continue
                        }
                        if let stock = CSVImporter.csvExtractor(url: url) {
                            stocks.append(stock)
                        }
                        url.stopAccessingSecurityScopedResource()
                    }
                }
            } catch let error {
               print(error)
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "can't access contens of directory \(documentFolder)")
                
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
    
    public func addStock(fileURL: URL) {
        if let stock = CSVImporter.csvExtractor(url: fileURL) {
            stocks.append(stock)
        }

        tableView.reloadData()
        tableView.selectRow(at: IndexPath(item: stocks.count-1, section: 0), animated: true, scrollPosition: .top)
        performSegue(withIdentifier: "stockSelectionSegue", sender: nil)
    }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return stocks.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "stockListCell", for: indexPath) as! StockListCellTableViewCell

        let valuation = CombinedValuationController.returnDCFValuations(company: stocks[indexPath.row].name)
        let r1valuation = CombinedValuationController.returnR1Valuations(company: stocks[indexPath.row].name)
        cell.configureCell(indexPath: indexPath, delegate: self, stock: stocks[indexPath.row], valuation: valuation?.first, r1Valuation: r1valuation?.first)
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
        performSegue(withIdentifier: "stockSelectionSegue", sender: nil)
    }
    
    func valuationCompleted(indexPath: IndexPath) {
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */


    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let chartView = segue.destination as? StockChartVC {
            if let indexPath = tableView.indexPathForSelectedRow {
                
                chartView.stockToShow = stocks[indexPath.row]

            }
        }
        else if let navView = segue.destination as? UINavigationController {
            if let chartView = navView.topViewController as? StockChartVC {
                if let indexPath = tableView.indexPathForSelectedRow {
                    
                    chartView.stockToShow = stocks[indexPath.row]
                    chartView.configure()
                }
            }
        }
    }

}

extension StocksListViewController: StockListCellDelegate {
    
    func valuationButtonPressed(indexpath: IndexPath) {
                
        if let choser = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ValuationChoser") as? ValuationChooser {
            choser.loadViewIfNeeded()
            choser.stock = stocks[indexpath.row]
            choser.rootView = self
            choser.sourceCellPath = indexpath
            
            self.present(choser, animated: true)
        }

    }
    
    
}
