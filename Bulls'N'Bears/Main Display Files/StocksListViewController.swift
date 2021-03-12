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
    
    var controller: StocksController = {
        let request = NSFetchRequest<Share>(entityName: "Share")
        request.sortDescriptors = [NSSortDescriptor(key: "userEvaluationScore", ascending: false), NSSortDescriptor(key: "valueScore", ascending: false),NSSortDescriptor(key: "symbol", ascending: true)]
        
        let sL = StocksController(fetchRequest: request, managedObjectContext: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try sL.performFetch()
        } catch let error as NSError {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "can't fetch files")
        }
        return sL
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "StockListCellTableViewCell", bundle: nil), forCellReuseIdentifier: "stockListCell")
        
        NotificationCenter.default.addObserver(self, selector: #selector(filesReceivedInBackground(notification:)), name: Notification.Name(rawValue: "NewFilesArrived"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(fileDownloaded(_:)), name: Notification.Name(rawValue: "DownloadAttemptComplete"), object: nil)
                
        NotificationCenter.default.addObserver(self, selector: #selector(updateCellReturningFromWBValuationTVC(notification:)), name: NSNotification.Name(rawValue: "refreshStockListTVCRow"), object: nil)
        
        controller.delegate = self
        updateShares()
        if controller.fetchedObjects?.count ?? 0 > 0 {
            tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
            performSegue(withIdentifier: "stockSelectionSegue", sender: nil)
        }

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        controller.delegate = nil
        for share in controller.fetchedObjects ?? [] {
        
            let valueRatingData = share.wbValuation?.valuesSummaryScores()
            let userRatingData = share.wbValuation?.userEvaluationScore()
            
            if let score = valueRatingData?.ratingScore() {
                share.valueScore = score
            }
            if let score = userRatingData?.ratingScore() {
                share.userEvaluationScore = score
            }
        }
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
                addShare(fileURL: URL(fileURLWithPath: path))
            }
        }
    }
    
    @objc
    func fileDownloaded(_ notification: Notification) {

        if let url = notification.object as? URL {
            if let share = StocksController.createShare(from: url, deleteFile: true){
                let indexPath = controller.indexPath(forObject: share)
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                performSegue(withIdentifier: "stockSelectionSegue", sender: nil)
            }
            else {
                ErrorController.addErrorLog(errorLocation: "StocksListVC." + #function, systemError: nil, errorInfo: "File download notification did not contain a url to creat new share from")
            }
        }
    }
    
    public func addShare(fileURL: URL) {

        if let share = StocksController.createShare(from: fileURL, deleteFile: true) {
            if let path = controller.indexPath(forObject: share) {
                tableView.selectRow(at: path, animated: true, scrollPosition: .bottom)
                tableView.delegate?.tableView?(self.tableView, didSelectRowAt: path)
                performSegue(withIdentifier: "stockSelectionSegue", sender: nil)
            }
        }
        else {
            ErrorController.addErrorLog(errorLocation: #file + #function, systemError: nil, errorInfo: "Failure to add new share from file \(fileURL)")
       }
        
//        if let stock = CSVImporter.csvExtractor(url: fileURL) {
//            stocks.append(stock)
//
//            tableView.reloadData()
//            // causing crash on Hanski's iPad - why???
//            tableView.selectRow(at: IndexPath(item: stocks.count-1, section: 0), animated: true, scrollPosition: .bottom)
//            tableView.delegate?.tableView?(self.tableView, didSelectRowAt: IndexPath(item: stocks.count-1, section: 0))
//            performSegue(withIdentifier: "stockSelectionSegue", sender: nil)
//        }

    }
    
    @objc
    func updateCellReturningFromWBValuationTVC(notification: Notification) {
        
        if let path = notification.object as? IndexPath {
            tableView.reloadRows(at: [path], with: .automatic)
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return controller.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let sectionInfo = controller.sections?[section] {
            return sectionInfo.numberOfObjects
        }
        else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "stockListCell", for: indexPath) as! StockListCellTableViewCell

        let share = controller.object(at: indexPath)
        let valueRatingData = share.wbValuation?.valuesSummaryScores()
        let userRatingData = share.wbValuation?.userEvaluationScore()
        
//        if let score = valueRatingData?.ratingScore() {
//            share.valueScore = score
//        }
//        if let score = userRatingData?.ratingScore() {
//            share.userEvaluationScore = score
//        }
        
        cell.configureCell(indexPath: indexPath, stock: share, userRatingData: userRatingData, valueRatingData: valueRatingData)
        
        return cell
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete")
        { (action, view, bool) in
            
            let objectToDelete = self.controller.object(at: indexPath) //stocks[indexPath.row]
            
            ((UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext).delete(objectToDelete)
        }
            
            let swipeActions = UISwipeActionsConfiguration(actions: [deleteAction])
        
            return swipeActions

    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let wbValuationView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WBValuationTVC") as? WBValuationTVC else { return }

        wbValuationView.share = controller.object(at: indexPath)
        wbValuationView.fromIndexPath = indexPath

        performSegue(withIdentifier: "stockSelectionSegue", sender: nil)
        
        navigationController?.pushViewController(wbValuationView, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
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
        
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        
        let share = controller.object(at: indexPath)
//        let dcfValuation = share.dcfValuation
//        let r1Valuation = share.rule1Valuation
        
        if let chartView = segue.destination as? StockChartVC {
                
            chartView.share = controller.object(at: indexPath)
            chartView.configure(share: share)
        }
        else if let navView = segue.destination as? UINavigationController {
            if let chartView = navView.topViewController as? StockChartVC {
                    
            chartView.share = controller.object(at: indexPath)
            chartView.configure(share: share)
            }
        }
    }

}

extension StocksListViewController: SharesUpdaterDelegate {
    
    func updateStocksComplete() {
        
//check if this is required of NSFRC updates list automatically
//        self.tableView.reloadData()
        
        if (controller.fetchedObjects?.count ?? 0) > 0 {
            
            // renew chartContainerView with updated prices
            let currentlySelectedPath = tableView.indexPathForSelectedRow ?? IndexPath(row: 0, section: 0)
            tableView.selectRow(at: currentlySelectedPath, animated: true, scrollPosition: .top)
            performSegue(withIdentifier: "stockSelectionSegue", sender: nil)
        }
    }
    
    func updateShares() {
        
        guard (Calendar.current.component(.weekday, from: Date()) > 2) else {
            return
        }
                
        controller.updateStockFiles()
        // returns to 'updateStocksComplete()' once complete
    }
    
}

extension StocksListViewController: NSFetchedResultsControllerDelegate {

    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .none)
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        @unknown default:
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "undefined change to shares list controller")
        }
    }
    
}
