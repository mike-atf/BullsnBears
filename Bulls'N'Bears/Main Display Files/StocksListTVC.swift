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
    @IBOutlet var treasuryBondYieldsButton: UIBarButtonItem!
    @IBOutlet var sortView: SortView!
    
    var controller: StocksController2 = {
        
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
        
        let sL = StocksController2(fetchRequest: request, managedObjectContext: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext, sectionNameKeyPath: firstSortParameter, cacheName: nil)
        
        do {
            try sL.performFetch()
        } catch let error as NSError {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "can't fetch files")
        }
        return sL
    }()
    
    var wbValuationView: WBValuationTVC?
    var selectedSharesToCompare = Set<Share>()
    var refreshControl: UIRefreshControl!
    
    var searchController: UISearchController?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "StockListCellTableViewCell", bundle: nil), forCellReuseIdentifier: "stockListCell")
        
        NotificationCenter.default.addObserver(self, selector: #selector(filesReceivedInBackground(notification:)), name: Notification.Name(rawValue: "NewFilesArrived"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(userChangedValuationWeights), name: Notification.Name(rawValue: "userChangedValuationWeights"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(fileDownloaded(_:)), name: Notification.Name(rawValue: "FileDownloadComplete"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateShares), name: Notification.Name(rawValue: "ActivatedFromBackground"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateSingleShare(notification:)), name: Notification.Name(rawValue: "SingleShareUpdateRequest"), object: nil)

        
        
        controller.delegate = self
        controller.controllerDelegate = self
        controller.viewController = self
                
        sortView.delegate = self
        let sort = SharesListSortParameter()
        let sortTitle = sort.displayTerm(term: (UserDefaults.standard.value(forKey: userDefaultTerms.sortParameter) as! String))
        sortView.label?.text = "Sorted by " + sortTitle
        
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(updateShares), for: .valueChanged)
        
        if controller.fetchedObjects?.count ?? 0 > 0 {
            if tableView.indexPathForSelectedRow == nil {
                tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
            }
            performSegue(withIdentifier: "showChartSegue", sender: nil)
            // updateShares() call here NOT necessary as TVC acts as observer to "ActivatedFromBackground" even if launching (?)
        }
        else {
            showWelcomeView()
        }
        
        searchController = UISearchController(searchResultsController: nil)
        searchController?.searchResultsUpdater = self
        searchController?.searchBar.placeholder = "Enter symbol"
        searchController?.delegate = self
        searchController?.searchBar.delegate = self
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
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
    
    /// called when App activated from background
    @objc
    func updateShares() {
                
        NotificationCenter.default.post(name: Notification.Name(rawValue: "ShowCitation"), object: nil, userInfo: nil)
        
        guard controller.fetchedObjects?.count ?? 0 > 0 else {
            return
        }
            do {
                try controller.updateStocksData()
            } catch let error {
                ErrorController.addErrorLog(errorLocation: "StocksListVC - updateShares", systemError: nil, errorInfo: "error when trying to update stock data: \(error)")
            }
            tableView.refreshControl?.endRefreshing()
        
    }
    
    @objc
    func updateSingleShare(notification: Notification) {
        
        guard let share = notification.object as? Share else { return }
        
        do {
            try controller.updateStocksData(singleShare: share)
        } catch let error {
            alertController.showDialog(title: "Update failure", alertMessage: "Couldn't update \(share); \(error.localizedDescription)", viewController: self, delegate: nil)
        }
    }

    // MARK: - Shares functions
    
    func showWelcomeView() {
        
        let welcomeView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WelcomeViewController")
        
        welcomeView.loadViewIfNeeded()
        
        self.navigationController?.present(welcomeView, animated: true) {
            if let textView = welcomeView.view.viewWithTag(10) as? UITextView {
                let text = "Welcome and thank you for choosing Bulls 'N' Bears as your shares research and investment tool\n\nBulls N Bears downloads publicly available finance and trading data (from Yahoo Finance, MacroTrends.com and other websites) about shares traded on the NYSE and displays analyses and summaries. Trading prices from the last 12 months are displayed in a stock chart.\n\nStart with ↓ to add a stock.\nOr with + you can import a .csv file with historical trading prices that you have downloaded from Yahoo finance.\n\nIn the stock price chart, tap the coloured and A,3,1 buttons to add trend lines (red = support, green = ceiling, blue = average, A = all, 3 = last 3 months, 1 = last month). The chart also shows a 10-day moving average line.\n\nAt the top there are graph plots for Mac D and the Slow stochastic oscillator.\nVertical lines are shown for the latest buy or sell thresholds.\n\nTapping on a stock in the list will show detailed financial data. Key data will be downloaded automatically, further data can be downloaded via the Cloud button at the top.\nEach row will contain a key financial indicator. In the lower sections these will be the EMA (exponentially moving average) of annual data downloaded from MacroTrends.\n\nTap on a row to show a chart of the numbers and a change trend for the last 10 years. This will allow judging growth trends at a glance and you can enter a personal value score in the top row by tapping repeatedly on the stars. You can also enter comments here to help your stock research and valuation.\n\nFinancial data and your rating scores are summarised in two icons in the stock list. The circle with a star in the centre shows a summary of all your ratings, the $ circle shows summarised financial data, to allow a quick overview in the list.\nTap on the star-centred circle to see a list of your evaluation comments.\n\nBased on the buy / sell thresholds detected in the stock price chart a Wait or Ready to Buy / Sell message is shown.\n\nAdd stock valuations by tapping on the yellow $ buttons at the top of the price chart. These are for Discounted Cash Flow- and Value based stock valuations and will give an idea of an estimated current stock value"
                textView.text = text
            }

        }
        
    }

    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
       
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
            addShare(fileURL: url, companyName: notification.userInfo?["companyName"] as? String)
        }
    }
    
    public func addShare(fileURL: URL, companyName: String?=nil) {
        
            do {
                if let share = try controller.createShare(from: fileURL, companyName: companyName ,deleteFile: true) {
                    try (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.save()
                    let shareID = share.objectID // is thread safe
                        
                    
                    Task.init(priority: .background) {
                        try await controller.downloadProfile(symbol: share.symbol!, shareID: shareID)
                    }
                    if let indexPath = controller.indexPath(forObject: share) {
                        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                        performSegue(withIdentifier: "showChartSegue", sender: nil)
                    }

                }
            } catch let error {
                ErrorController.addErrorLog(errorLocation: #file + #function, systemError: error, errorInfo: "Failure to add new share from file \(fileURL)")
            }
    }
    
    @objc
    func userChangedValuationWeights() {
        tableView.reloadData()
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
        
        let evaluationsCount = share.wbValuation?.returnUserEvaluations()?.compactMap{ $0.comment }.filter({ (comment) -> Bool in
            if !comment.starts(with: "Enter your notes here...") { return true }
            else { return false }
        }).count ?? 0

        cell.configureCell(indexPath: indexPath, stock: share, userRatingScore: share.userEvaluationScore, valueRatingScore: share.valueScore, scoreDelegate: self, userCommentCount: evaluationsCount)
        
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
            do {
                try self.controller.updateStocksData(singleShare: objectOwned)
            } catch let error {
                ErrorController.addErrorLog(errorLocation: "StocksListTVC", systemError: error, errorInfo: "unable to update data for \(objectOwned.symbol ?? "") when moving from archive to watch list.")
            }
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
        
        if !tableView.isEditing {
            performSegue(withIdentifier: "showChartSegue", sender: nil)
        }
        else {
            let selectedShare = controller.object(at: indexPath)
            selectedSharesToCompare.insert(selectedShare)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        if tableView.isEditing {
            let selectedShare = controller.object(at: indexPath)
            if selectedSharesToCompare.compactMap({ $0.symbol }).contains(selectedShare.symbol) {
                selectedSharesToCompare.remove(selectedShare)
            }
        }
 
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        
        DispatchQueue.main.async {
            self.wbValuationView?.share = self.controller.object(at: indexPath)
            self.wbValuationView?.fromIndexPath = indexPath

            if self.wbValuationView != nil  {
                self.navigationController?.pushViewController(self.wbValuationView!, animated: true)
            }
        }
        
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)

        performSegue(withIdentifier: "showChartSegue", sender: nil)
//        tableView.deselectRow(at: indexPath, animated: true)

    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle(rawValue: 3)!
    }
    
    @IBAction func selectToCompare(_ sender: UIBarButtonItem) {
        
        sortView.label?.text = "Select shares to compare"

        tableView.allowsSelectionDuringEditing = false
        
        var editingStatus = tableView.isEditing
        editingStatus.toggle()

        tableView.allowsMultipleSelection = editingStatus ? true : false

        tableView.setEditing(editingStatus, animated: true)
        
        if !editingStatus {
            // editing ended
            let sort = SharesListSortParameter()
            let sortTitle = sort.displayTerm(term: (UserDefaults.standard.value(forKey: userDefaultTerms.sortParameter) as! String))
            sortView.label?.text = "Sorted by " + sortTitle
            
            if selectedSharesToCompare.count > 0 {
                
                
                guard let comparisonVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ComparisonVC") as? ComparisonVC else {
                    return
                }

                comparisonVC.modalPresentationStyle = .popover
                if let rootView = splitViewController {
                    comparisonVC.preferredContentSize = CGSize(width: rootView.view.frame.width * 0.9, height: rootView.view.frame.height * 0.9)
                }

                comparisonVC.shares = Array(selectedSharesToCompare)
                selectedSharesToCompare.removeAll()

                let popUpController = comparisonVC.popoverPresentationController
                popUpController!.permittedArrowDirections = UIPopoverArrowDirection.init(rawValue: 0)
                popUpController?.sourceView = splitViewController?.view ?? view
                popUpController?.sourceRect = splitViewController?.view.frame ?? view.frame
                    
                self.splitViewController?.present(comparisonVC, animated: true, completion: nil)

            }
        }
        
    }
        
    @IBAction func showDiary(_ sender: Any) {
        
        guard let diarySplitView = UIStoryboard(name: "Diary", bundle: nil).instantiateViewController(withIdentifier: "DiarySplitView") as? UISplitViewController else {
            return
        }

        self.splitViewController?.present(diarySplitView, animated: true, completion: nil)

    }
    
    @IBAction func showTBYView(_ sender: Any) {
        
        guard let tbyVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TBYChartViewController") as? TBYChartViewController else {
            return
        }

        tbyVC.modalPresentationStyle = .popover
        tbyVC.preferredContentSize = CGSize(width: 400, height: 250)

        tbyVC.tbrPriceDates = controller.treasuryBondYields

        let popUpController = tbyVC.popoverPresentationController
        popUpController!.permittedArrowDirections = .up
        popUpController?.barButtonItem = treasuryBondYieldsButton
            
        self.splitViewController?.present(tbyVC, animated: true, completion: nil)
    }
    
    
    // MARK: - Navigation

 override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
     
         let share = controller.object(at: indexPath)
         
         if let navView = segue.destination as? UINavigationController {
             if let chartView = navView.topViewController as? StockChartVC {
                 chartView.share = controller.object(at: indexPath)
                 chartView.configure(share: share)
                 
//                 if share.watchStatus == 2 {
//                     // archived stocks
//                     do {
//                         try controller.updateStocksData(singleShare: share)
//                     } catch let error {
//                         ErrorController.addErrorLog(errorLocation: "StocksListVC", systemError: error, errorInfo: "error when trying to update data for archived \(share.name_short ?? "missing")")
//                     }
//                 }
             }
         }

 }

    @IBAction func downloadAction(_ sender: Any) {
        
        guard let entryView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "StockSearchTVC") as? StockSearchTVC else { return }

        entryView.callingVC = self
        entryView.downloadDelegate = self
        
        navigationController?.pushViewController(entryView, animated: true)
    }

}

extension StocksListTVC: SortDelegate, StockSearchDataDownloadDelegate {
    
    func newShare(symbol: String, prices: [PricePoint]?) {
                
            do {
                if let share = try controller.createShare(with: prices, symbol: symbol) {
                    try (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.save()
                                            
                    Task.init(priority: .background) {
                        try await controller.downloadProfile(symbol: share.symbol!, shareID: share.objectID)
                    }

                    if let indexPath = controller.indexPath(forObject: share) {
                        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                        performSegue(withIdentifier: "showChartSegue", sender: nil)
                    }

                }
            } catch let error {
                ErrorController.addErrorLog(errorLocation: #file + #function, systemError: nil, errorInfo: "Failure to add new share from pricepoint data \(symbol) \(error)")
            }
    }

    
    func sortParameterChanged() {
        
        
        let newController: StocksController2 = {
            
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

            let sL = StocksController2(fetchRequest: request, managedObjectContext: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext, sectionNameKeyPath: firstSortParameter, cacheName: nil)
            
            do {
                try sL.performFetch()
            } catch let error as NSError {
                ErrorController.addErrorLog(errorLocation: #function, systemError: error, errorInfo: "can't fetch files")
            }

            return sL
        }()
        
        controller = newController
        controller.delegate = self
        tableView.reloadData()
    }
    
}

extension StocksListTVC: StocksController2Delegate, ScoreCircleDelegate {
    
    func shareUpdateComplete(atPath: IndexPath) {
                
        tableView.reloadRows(at: [atPath], with: .none)
        
        if tableView.indexPathForSelectedRow == nil {
            tableView.selectRow(at: atPath, animated: false, scrollPosition: .none)
        }
        
        // only these two steps seem to be able to move changes saved to background moc to mainThread moc
        let share = controller.object(at: atPath)
        let _ = share.getDailyPrices(needRecalcDueToNew: true)
        
        var researchViewOpen = false
        if let nav = self.splitViewController?.navigationController {
            for vc in nav.viewControllers {
                if let _ = vc as? ResearchTVC {
                    researchViewOpen = true
                }
            }
        }
        if !researchViewOpen {
            performSegue(withIdentifier: "showChartSegue", sender: nil)
        }
        
    }
    
    func tap(indexPath: IndexPath, isUserScoreType: Bool, sender: UIView) {
        
        if let evaluationsView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ValuationErrorsTVC") as? ValuationErrorsTVC {
            
            evaluationsView.modalPresentationStyle = .popover
            evaluationsView.preferredContentSize = CGSize(width: self.view.frame.width * 0.75, height: self.view.frame.height * 0.5)

            let popUpController = evaluationsView.popoverPresentationController
            popUpController!.permittedArrowDirections = .any
            popUpController!.sourceView = sender
            evaluationsView.loadViewIfNeeded()
            evaluationsView.firstCellHeight = 200
            
            let share = controller.object(at: indexPath)
        
            var texts = ["Why to buy: " + (share.research?.theBuyStory ?? "")]
            if isUserScoreType {
                evaluationsView.otherCellHeight = 75
                evaluationsView.otherCellsFontSize = 14
                texts.append(contentsOf: share.wbValuation?.returnUserCommentsTexts() ?? [])
            }
            else {
                evaluationsView.otherCellHeight = 50
                texts.append(contentsOf:share.wbValuation?.valuesSummaryTexts() ?? [])
            }
            
            evaluationsView.errors = texts
            
            present(evaluationsView, animated: true, completion:  nil)
        }

    }

    func treasuryBondRatesDownloaded() {
        
        if let yieldDates = controller.treasuryBondYields {
            let yields = yieldDates.compactMap{ $0.value }
            if let ema = yields.ema(periods: 10) {
                treasuryBondYieldsButton.isEnabled = true
                let latest = yields.first!
                let change = (latest - ema) / ema
                let change$ = percentFormatter2DigitsPositive.string(from: change as NSNumber) ?? "TBY"
                treasuryBondYieldsButton.title = change$
                treasuryBondYieldsButton.tintColor = change <= 0 ? UIColor.systemGreen : UIColor.systemRed
            }
        }
        else {
            treasuryBondYieldsButton.isEnabled = false
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
            let _ = controller.object(at: indexPath!) as! Share
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

extension StocksListTVC: UISearchBarDelegate, UISearchResultsUpdating, UISearchControllerDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        
        guard let searchText = searchController.searchBar.text  else {
            return
        }
        
        guard searchText != "" else {
            return
        }
        
        NotificationCenter.default.addObserver(
          forName: UIResponder.keyboardWillHideNotification,
          object: nil, queue: .main) { (notification) in
            self.searchKeyBoardDismissed()
        }
        
        let request = NSFetchRequest<Share>(entityName: "Share")

        let namePredicate = NSPredicate(format: "symbol contains[c] %@", searchText.lowercased())
    
        request.predicate = namePredicate
        request.sortDescriptors = [NSSortDescriptor(key: "symbol", ascending: true)]
        controller.delegate = nil
        controller = StocksController2(fetchRequest: request, managedObjectContext: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext, sectionNameKeyPath: "watchStatus", cacheName: nil)

        do {
            try controller.performFetch()
        } catch let error as NSError {
            alertController.showDialog(title: "Search failed", alertMessage: "Couldn't fetch symbols: \(error.localizedDescription)", viewController: self, delegate: nil)
        }

        self.navigationItem.leftBarButtonItem?.isEnabled = true
        tableView.reloadData()
        controller.delegate = self
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        sortParameterChanged()

    }


    
    @objc
    func searchKeyBoardDismissed() {
        searchController?.isActive = false
        
    }

    
}

