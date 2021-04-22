//
//  StocksListTVC.swift
//  Bulls'N'Bears
//
//  Created by aDav on 13/04/2021.
//

import UIKit
import CoreData

class StocksListTVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var downloadButton: UIBarButtonItem!
    @IBOutlet var sortView: SortView!
    
    var controller: StocksController = {
        
        // how to sort:
        // default: 1. watchStatus, 2 user evaluation
        // same for valueScore, symbol
        // for industry and sector don't use watchStatus

        var firstSortParameter = String()
        var secondSortParameter = String()
        var thirdSortParameter = String()
        
        var firstSortAscending = true
        let secondSortAscending = false
        let thirdSortAscending = false

        let userSortChoice = (UserDefaults.standard.value(forKey: userDefaultTerms.sortParameter) as? String) ?? "userEvaluationScore"
        if [sharesListSortParameter.industry, sharesListSortParameter.sector].contains(userSortChoice) {
            firstSortParameter = userSortChoice
            secondSortParameter = sharesListSortParameter.userEvaluationScore
            thirdSortParameter = sharesListSortParameter.valueScore
            firstSortAscending = false
        }
        else if userSortChoice == sharesListSortParameter.userEvaluationScore {
            firstSortParameter = "watchStatus"
            secondSortParameter = userSortChoice
            thirdSortParameter = sharesListSortParameter.valueScore
        }
        else if userSortChoice == sharesListSortParameter.valueScore {
            firstSortParameter = "watchStatus"
            secondSortParameter = userSortChoice
            thirdSortParameter = sharesListSortParameter.userEvaluationScore
        }
        else if userSortChoice == sharesListSortParameter.symbol {
            firstSortParameter = "watchStatus"
            secondSortParameter = userSortChoice
            thirdSortParameter = sharesListSortParameter.userEvaluationScore
        }
        else if userSortChoice == sharesListSortParameter.growthType {
            firstSortParameter = userSortChoice
            secondSortParameter = sharesListSortParameter.userEvaluationScore
            thirdSortParameter = sharesListSortParameter.valueScore
        }


        let request = NSFetchRequest<Share>(entityName: "Share")

        request.sortDescriptors = [ NSSortDescriptor(key: firstSortParameter, ascending: firstSortAscending), NSSortDescriptor(key: secondSortParameter, ascending: secondSortAscending), NSSortDescriptor(key: thirdSortParameter, ascending: thirdSortAscending)]
        
        let sL = StocksController(fetchRequest: request, managedObjectContext: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext, sectionNameKeyPath: firstSortParameter, cacheName: nil)
        
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
                
        if controller.fetchedObjects?.count ?? 0 > 0 {
            tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
            performSegue(withIdentifier: "stockSelectionSegue", sender: nil)
        }
        else {
            showWelcomeView()
        }
        
        sortView.delegate = self
        sortView.label?.text = "Sorted by " + ((UserDefaults.standard.value(forKey: userDefaultTerms.sortParameter) as? String) ?? "userEvaluationScore")
        
        updateShares()

// temp
        self.controller.research()
// temp
    }
    
    // MARK: - ViewController functions
    
    override func viewWillDisappear(_ animated: Bool) {
        
        controller.delegate = nil // disconnect FRC to avoid TVC update requests in background when changes to shares are made in other VC
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // reconnect FRC to update shares after changing made in other VC
        controller.delegate = self
        do {
            try controller.performFetch()
        } catch let error {
            ErrorController.addErrorLog(errorLocation: #file + #function, systemError: error, errorInfo: "Error updating Stocks list")
        }
        
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        wbValuationView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WBValuationTVC") as? WBValuationTVC

    }
    
    func updateShares() {
        
        let weekDay = Calendar.current.component(.weekday, from: Date())
        guard (weekDay > 1 && weekDay < 7) else {
            return
        }
        
        // jobs to do:
        // 1. - update prices in controller.updatePrices() downloading all shares csv. files from Yahoo
        // 2. - update 'Research' data: harmonize competitors and industries
        // 3. - download keyRatios in share.downloadKeyratios()
        // 4. - inform the StocksListTVC to update charts and infos displayed
        // all this needs to be thread-safe as the AppDelegate's viewContext and all fetch objects from it (!) can only be accessed from the main thread!
        // background tasks - and all downloads are background tasks - that need access to NSManagedObjects and their data need their own private NSMOC as a child of the main viewContext.
        // the merge happens in the saveContext() function of the AppDelegate
        // saving an NSManagedObject in it's moc can be done via e.g. .save(self.context?)
        
        controller.updatePrices()
        // returns to 'updateStocksComplete()' once complete
    }

    // MARK: - Shares functions
    
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
            
            let placeHolder = SharePlaceHolder(share: share)
            placeHolder.downloadKeyRatios(delegate: controller)
            placeHolder.downloadProfile(delegate: controller)

        }
        else {
            ErrorController.addErrorLog(errorLocation: #file + #function, systemError: nil, errorInfo: "Failure to add new share from file \(fileURL)")
       }
    }

    
    // MARK: - TableView functions
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return controller.sections?.count ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return controller.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if let sectionInfo = controller.sections?[section] {
            if sectionInfo.name == "0"  {
                return "Watch list"
            }
            else if sectionInfo.name == "1" {
                return "Owned"
            }
            else if sectionInfo.name == "2" {
                return "Archive"
            }

            else { return sectionInfo.name }
        }
        else { return nil }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
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
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete")
        { (action, view, bool) in
            
            let objectToDelete = self.controller.object(at: indexPath) //stocks[indexPath.row]
            
            ((UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext).delete(objectToDelete)
        }
            
            let swipeActions = UISwipeActionsConfiguration(actions: [deleteAction])
        
            return swipeActions

    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
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


    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
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

    @IBAction func downloadAction(_ sender: Any) {
        
        guard let entryView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "StockSearchTVC") as? StockSearchTVC else { return }

        entryView.callingVC = self
        
        navigationController?.pushViewController(entryView, animated: true)
    }

}

extension StocksListTVC: SortDelegate {
    
    func sortParameterChanged() {
        
        
        let newController: StocksController = {
            
            var firstSortParameter = String()
            var secondSortParameter = String()
            var thirdSortParameter = String()
            
            var firstSortAscending = true
            let secondSortAscending = false
            let thirdSortAscending = false

            
            let userSortChoice = (UserDefaults.standard.value(forKey: userDefaultTerms.sortParameter) as? String) ?? "userEvaluationScore"
            if [sharesListSortParameter.industry, sharesListSortParameter.sector].contains(userSortChoice) {
                firstSortParameter = userSortChoice
                secondSortParameter = sharesListSortParameter.userEvaluationScore
                thirdSortParameter = sharesListSortParameter.valueScore
                firstSortAscending = false
            }
            else if userSortChoice == sharesListSortParameter.userEvaluationScore {
                firstSortParameter = "watchStatus"
                secondSortParameter = userSortChoice
                thirdSortParameter = sharesListSortParameter.valueScore
            }
            else if userSortChoice == sharesListSortParameter.valueScore {
                firstSortParameter = "watchStatus"
                secondSortParameter = userSortChoice
                thirdSortParameter = sharesListSortParameter.userEvaluationScore
            }
            else if userSortChoice == sharesListSortParameter.symbol {
                firstSortParameter = "watchStatus"
                secondSortParameter = userSortChoice
                thirdSortParameter = sharesListSortParameter.userEvaluationScore
            }
            else if userSortChoice == sharesListSortParameter.growthType {
                firstSortParameter = userSortChoice
                secondSortParameter = sharesListSortParameter.userEvaluationScore
                thirdSortParameter = sharesListSortParameter.valueScore
            }


            let request = NSFetchRequest<Share>(entityName: "Share")

            request.sortDescriptors = [ NSSortDescriptor(key: firstSortParameter, ascending: firstSortAscending), NSSortDescriptor(key: secondSortParameter, ascending: secondSortAscending), NSSortDescriptor(key: thirdSortParameter, ascending: thirdSortAscending)]

            let sL = StocksController(fetchRequest: request, managedObjectContext: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext, sectionNameKeyPath: firstSortParameter, cacheName: nil)
            
            do {
                try sL.performFetch()
            } catch let error as NSError {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "can't fetch files")
            }

            return sL
        }()
        
        controller = newController
        controller.delegate = self
        tableView.reloadData()
    }
    
}

extension StocksListTVC: StocksControllerDelegate, ScoreCircleDelegate {
    
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


extension StocksListTVC: NSFetchedResultsControllerDelegate {

    
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
