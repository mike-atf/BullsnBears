//
//  StocksListViewController.swift
//  TrendMyStocks
//
//  Created by aDav on 01/12/2020.
//

import UIKit

class StocksListViewController: UITableViewController {
    
    @IBOutlet var addButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        openCSCFilesInDocumentDirectory()
    }

    @IBAction func addButtonAction(_ sender: Any) {
        
        if let docBrowser = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DocBrowserView") as? DocumentBrowserViewController {

            docBrowser.stockListVC = self
            self.present(docBrowser, animated: true)
        }
    }
    
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
                    else if url.lastPathComponent.contains("Inbox") {
                        let inboxFolder = documentFolder + "/Inbox"
                        let fileURLs = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: inboxFolder), includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                        
                        for url in fileURLs {
                            if url.lastPathComponent.contains(".csv") {
                                if let stock = CSVImporter.csvExtractor(url: URL(fileURLWithPath: documentFolder + url.lastPathComponent)) {
                                    stocks.append(stock)
                                }
                                do {
                                    try FileManager.default.moveItem(at: url, to: URL(fileURLWithPath: documentFolder + "/" + url.lastPathComponent))
                                }
                                catch let error {
                                    print("error trying to move file out of the Inbox into the Document folder \(error)")
                                }
                            }
                        }
                    }
                }
            } catch let error {
               print(error)
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
    
    public func addStock(fileURL: URL) {
        if let stock = CSVImporter.csvExtractor(url: fileURL) {
            stocks.append(stock)
        }

        tableView.reloadData()
    }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return stocks.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "stockListCell", for: indexPath)

        if let label = cell.contentView.viewWithTag(10) as? UILabel {
            label.text = stocks[indexPath.row].name
        }

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
                    print("couldn't remove stock file \(error)")
                }
            }
            
            stocks.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
            
            let swipeActions = UISwipeActionsConfiguration(actions: [deleteAction])
        
            return swipeActions

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
