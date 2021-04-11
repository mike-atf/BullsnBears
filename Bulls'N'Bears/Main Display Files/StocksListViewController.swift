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
        request.sortDescriptors = [ NSSortDescriptor(key: "watchStatus", ascending: true), NSSortDescriptor(key: "userEvaluationScore", ascending: false), NSSortDescriptor(key: "valueScore", ascending: false),NSSortDescriptor(key: "symbol", ascending: true)]
        
        let sL = StocksController(fetchRequest: request, managedObjectContext: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext, sectionNameKeyPath: "watchStatus", cacheName: nil)
        
        do {
            try sL.performFetch()
        } catch let error as NSError {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "can't fetch files")
        }
        return sL
    }()
    
    var  wbValuationView: WBValuationTVC?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "StockListCellTableViewCell", bundle: nil), forCellReuseIdentifier: "stockListCell")
        
        NotificationCenter.default.addObserver(self, selector: #selector(filesReceivedInBackground(notification:)), name: Notification.Name(rawValue: "NewFilesArrived"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(fileDownloaded(_:)), name: Notification.Name(rawValue: "DownloadAttemptComplete"), object: nil)
                
        controller.delegate = self
        controller.pricesUpdateDelegate = self
        
        updateShares()
        if controller.fetchedObjects?.count ?? 0 > 0 {
            tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
            performSegue(withIdentifier: "stockSelectionSegue", sender: nil)
        }
        else {
            showWelcomeView()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        controller.delegate = nil // disconnect FRC to avoid TVC update requests in background when changes to shares are made in other VC
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // reconnect FRC to update shares after changing made in other VC
        controller.delegate = self
        do {
            try controller.performFetch()
        } catch let error {
            ErrorController.addErrorLog(errorLocation: #file + #function, systemError: error, errorInfo: "Error updating Sstocks list")
        }
        
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        wbValuationView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WBValuationTVC") as? WBValuationTVC

    }
    
    func updateShares() {
        
        let weekDay = Calendar.current.component(.weekday, from: Date())
        guard (weekDay > 0 && weekDay < 6) else {
            return
        }
                
        controller.updateStockFiles()
        // returns to 'updateStocksComplete()' once complete
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
                let text = "Welcome and thank you for choosing Bulls 'N' Bears as your shares research and investment tool\n\nBulls N Bears downloads publicly available finance and trading data (from Yahoo Finance, MacroTrends.com and other websites) about shares traded on the NYSE and displays analyses and summaries. Trading prices from the last 12 months are displayed in a stock chart.\n\nStart with ↓ to add a stock.\nOr with + you can import a .csv file with historical trading prices that you have downloaded from Yahoo finance.\n\nIn the stock price chart, tap the coloured and A,3,1 buttons to add trend lines (red = support, green = ceiling, blue = average, A = all, 3 = last 3 months, 1 = last month). The chart also shows a 10-day moving average line.\n\nAt the top there are graph plots for Mac D and the Slow stochastic oscillator.\nVertical lines are shown for the latest buy or sell thresholds.\n\nTapping on a stock in the list will show detailed financial data. Key data will be downloaded automatically, further data can be downloaded via the Cloud button at the top.\nEach row will contain a key financial indicator. In the lower sections these will be the EMA (exponentially moving average) of annual data downloaded from MacroTrends.\n\nTap on a row to show a chart of the numbers and a change trend for the last 10 years. This will allow judging growth trends at a glance and you can enter a personal value score in the top row by tapping repeatedly on the stars. You can also enter comments here to help your stock research and valuation.\n\nFinancial data and your rating scores are summarised in two icons in the stock list. The circle with a star in the centre shows a summary of all your ratings, the $ circle shows summarised financial data, to allow a quick overview in the list.\nTap on the star-centred circle to see a list of your evaluation comments.\n\nBased on the buy / sell thresholds detected in the stock price chart a Wait or Ready to Buy / Sell message is shown.\n\nAdd stock valuations by tapping on the yellow $ buttons at the top of the price chart. These are for Discounted Cash Flow- and Value based stock valuations and will give an idea of an estimated current stock value"
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
            addShare(fileURL: url)
        }
    }
    
    public func addShare(fileURL: URL) {
        
        if let share = StocksController.createShare(from: fileURL, deleteFile: true) {
            
            do {
                try (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.save()
            } catch let error {
                ErrorController.addErrorLog(errorLocation: #file + #function, systemError: error, errorInfo: "Failure to add new share from file \(fileURL)")
            }

            if let indexPath = controller.indexPath(forObject: share) {
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                performSegue(withIdentifier: "stockSelectionSegue", sender: nil)
            }
            
        }
        else {
            ErrorController.addErrorLog(errorLocation: #file + #function, systemError: nil, errorInfo: "Failure to add new share from file \(fileURL)")
       }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return controller.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return controller.sections?[section].numberOfObjects ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ["Watch list", "Owned", "Archived"][section]
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "stockListCell", for: indexPath) as! StockListCellTableViewCell

        let share = controller.object(at: indexPath)
        let valueRatingData = share.wbValuation?.valuesSummaryScores()
        let userRatingData = share.wbValuation?.userEvaluationScore()
        
        let evaluationsCount = share.wbValuation?.returnUserEvaluations()?.compactMap{ $0.comment }.filter({ (comment) -> Bool in
            if !comment.starts(with: "Enter your notes here...") { return true }
            else { return false }
        }).count ?? 0
        
        cell.configureCell(indexPath: indexPath, stock: share, userRatingData: userRatingData, valueRatingData: valueRatingData, scoreDelegate: self, userCommentCount: evaluationsCount)
        
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
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let objectOwned = self.controller.object(at: indexPath)

        let ownAction = UIContextualAction(style: .normal, title: "Own")
        { (action, view, bool) in
            
            objectOwned.watchStatus = 1
            objectOwned.save()
        }
        ownAction.backgroundColor = UIColor.systemGreen
        ownAction.image = UIImage(systemName: "bag.badge.plus")

        let watchAction = UIContextualAction(style: .normal, title: "Watch")
        { (action, view, bool) in
            
            objectOwned.watchStatus = 0
            objectOwned.save()
        }
        watchAction.backgroundColor = UIColor.systemGray
        watchAction.image = UIImage(systemName: "eyeglasses")
        
        let archiveAction = UIContextualAction(style: .normal, title: "Archive")
        { (action, view, bool) in
            
            objectOwned.watchStatus = 2
            objectOwned.save()
        }
        archiveAction.backgroundColor = UIColor.systemOrange
        archiveAction.image = UIImage(systemName: "archivebox")
        

        
        if objectOwned.watchStatus == 0 {
            return UISwipeActionsConfiguration(actions: [ownAction, archiveAction])
        }
        else if objectOwned.watchStatus == 1 {
            return UISwipeActionsConfiguration(actions: [watchAction, archiveAction])
        }
        else {
            return UISwipeActionsConfiguration(actions: [watchAction, ownAction])
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
//        guard let wbValuationView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WBValuationTVC") as? WBValuationTVC else { return }


        DispatchQueue.main.async {
            self.wbValuationView?.share = self.controller.object(at: indexPath)
            self.wbValuationView?.fromIndexPath = indexPath

            if self.wbValuationView != nil  {
                self.navigationController?.pushViewController(self.wbValuationView!, animated: true)
            }
        }
        
        performSegue(withIdentifier: "stockSelectionSegue", sender: nil)
        tableView.deselectRow(at: indexPath, animated: true)

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

extension StocksListViewController: StocksControllerDelegate, ScoreCircleDelegate {
    
    func tap(indexPath: IndexPath, isUserScoreType: Bool, sender: UIView) {
        
        if let evaluationsView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ValuationErrorsTVC") as? ValuationErrorsTVC {
            
            evaluationsView.modalPresentationStyle = .popover
            evaluationsView.preferredContentSize = CGSize(width: self.view.frame.width * 0.75, height: self.view.frame.height * 0.5)

            let popUpController = evaluationsView.popoverPresentationController
            popUpController!.permittedArrowDirections = .any
            popUpController!.sourceView = sender
            evaluationsView.loadViewIfNeeded()
            
            let share = controller.object(at: indexPath)
            
            var texts:[String]?
            if isUserScoreType {
                texts = share.wbValuation?.returnUserCommentsTexts()
            }
            else {
                texts = share.wbValuation?.valuesSummaryTexts()
            }
            
            evaluationsView.errors = texts ?? []
            
            present(evaluationsView, animated: true, completion:  nil)
        }

    }
    
    
    func allSharesHaveUpdatedTheirPrices() {
                
        DispatchQueue.main.async {
            let currentlySelectedPath = self.tableView.indexPathForSelectedRow ?? IndexPath(row: 0, section: 0)
            self.tableView.selectRow(at: currentlySelectedPath, animated: true, scrollPosition: .top)
            self.performSegue(withIdentifier: "stockSelectionSegue", sender: nil)
        }
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
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        let indexSet = NSIndexSet(index: sectionIndex) as IndexSet
        switch type {
        case .insert:
            tableView.insertSections(indexSet, with: .automatic)
        case .delete:
            tableView.deleteSections(indexSet, with: .automatic)
        case .update:
            tableView.reloadSections([sectionIndex], with: .automatic)
        case .move:
            tableView.reloadSections([sectionIndex], with: .automatic)
        @unknown default:
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "undefined change to shares list sections")
        }

    }
    
}
