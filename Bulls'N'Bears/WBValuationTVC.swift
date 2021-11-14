//
//  WBValuationTVC.swift
//  Bulls'N'Bears
//
//  Created by aDav on 15/02/2021.
//

import UIKit
import CoreData

class WBValuationTVC: UITableViewController, ProgressViewDelegate {

    var downloadButton: UIBarButtonItem!
    var controller: WBValuationController?
    var share: Share!
    var progressView: DownloadProgressView?
    var fromIndexPath: IndexPath!
    var movingToValueListTVC = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        downloadButton = UIBarButtonItem(title: "Download", style: .plain, target: self, action: #selector(startDownload))
         self.navigationItem.rightBarButtonItem = downloadButton
        
        self.navigationController?.title = share.name_short
        tableView.register(UINib(nibName: "WBValuationCell", bundle: nil), forCellReuseIdentifier: "wbValuationCell")
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshRow(notification:)), name: NSNotification.Name(rawValue: "refreshWBValuationTVCRow"), object: nil)
        
        controller = WBValuationController(share: share, progressDelegate: self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
//        controller?.deallocate()
//        controller = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        guard !movingToValueListTVC else {
            return
        }
        
        controller?.share.setUserAndValueScores()
        // don't deinit() controller as this function will also be called when maximising the detailView
    }
        
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return controller?.sectionTitles.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return controller?.rowTitles[section].count ?? 0
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "wbValuationCell", for: indexPath) as! WBValuationCell

        let (value$, color, errors) = controller!.value$(path: indexPath)
        let evaluation = controller!.userEvaluation(for: indexPath)
        
        var correlation: Correlation?
        let arrays = arraysForValueListTVC(indexPath: indexPath)
        if arrays != nil {
            let proportions = controller!.valueListTVCProportions(values: arrays!)
            let sendArrays = [arrays![0], proportions]
            correlation = Calculator.valueChartCorrelation(arrays:sendArrays)
        }
        
        cell.configure(title: controller!.rowTitle(path: indexPath), detail: value$, detailColor: color,errors: errors, delegate: self, userEvaluation: evaluation, correlation: correlation,correlationValues: arrays?[0])
        
        if indexPath.section == 0 {
            cell.accessoryType = .detailButton
            if [1,3,4].contains(indexPath.row) {
                cell.accessoryView?.isHidden = true
            }
            else {
                cell.accessoryView?.isHidden = false
            }
        }
        else {
            cell.accessoryType = .disclosureIndicator
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = UIView()
        let height: CGFloat = (UIDevice().userInterfaceIdiom == .pad) ? 50 : 50
        header.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: height)
        
        let title = controller?.sectionHeaderText(section: section) ?? ""
        let subtitle = controller?.sectionSubHeaderText(section: section)

        let largeFontSize: CGFloat = (UIDevice().userInterfaceIdiom == .pad) ? 20 : 20
        let smallFontSize: CGFloat = (UIDevice().userInterfaceIdiom == .pad) ? 16 : 12
        
        let titleLabel: UILabel = {
            let label = UILabel()
            let fontSize = largeFontSize
            label.font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
            label.textAlignment = .left
            label.textColor = UIColor.systemOrange
            label.text = title
            return label
        }()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
                
        header.addSubview(titleLabel)
        
        let margins = header.layoutMarginsGuide
        
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.topAnchor.constraint(equalTo: margins.topAnchor, constant: -10).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 5).isActive = true
        titleLabel.trailingAnchor.constraint(greaterThanOrEqualTo: margins.trailingAnchor, constant: 5).isActive = true
        
        if let sTitle = subtitle {
            let subTitle: UILabel = {
                let label = UILabel()
                label.font = UIFont.systemFont(ofSize: smallFontSize, weight: .regular)
                label.textColor = UIColor.label
                label.adjustsFontSizeToFitWidth = true
                label.minimumScaleFactor = 0.8
                label.text = subtitle
                return label
            }()
            
            subTitle.translatesAutoresizingMaskIntoConstraints = false
            
            header.addSubview(subTitle)
            
            subTitle.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor).isActive = true
            subTitle.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
            subTitle.trailingAnchor.constraint(greaterThanOrEqualTo: titleLabel.leadingAnchor, constant: 10).isActive = true

        
        }
        
        return header
        
    }
    
    @objc
    func startDownload() {
                
        progressView = DownloadProgressView.instanceFromNib()
        progressView?.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(progressView!)
        
        let margins = view.layoutMarginsGuide

        progressView?.widthAnchor.constraint(equalTo: margins.widthAnchor, multiplier: 0.8).isActive = true
        progressView?.centerXAnchor.constraint(equalTo: margins.centerXAnchor).isActive = true
        progressView?.heightAnchor.constraint(equalTo: margins.heightAnchor, multiplier: 0.2).isActive = true
        progressView?.centerYAnchor.constraint(equalTo: margins.centerYAnchor).isActive = true

        progressView?.delegate = self
        progressView?.title.text = "Downloading..."

        controller?.downloadWBValuationData()
    }
    
    @objc
    func refreshRow(notification: Notification) {
        movingToValueListTVC = false
        if let indexPath = notification.object as? IndexPath {
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard indexPath.section > 0 else {
            return
        }
        
        performSegue(withIdentifier: "valueListSegue", sender: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        
        var infoText = String()
        
        switch indexPath.row {
        case 0:
            infoText = "Current P/E ratio, and P/E (minimum - maximum) during the period 6-24 months ago.\nThis allows comparison of current P/E to the recent past in order to help judge whether a stock price is above or below recent levels. Helpful to spot over- or under-pricing"
        case 1:
            infoText = "Not implemented"
        case 2:
            infoText = "Proportion of book value to current share price in %, as well (book value per share).\nHelps to judge the stock price in relation to company assets.\nCurrent real market value of assets may differ from the book value."
        case 3:
            infoText = "Earnings growth + dividend yield divided by P/E ratio.\nLess than 1.0 is poor, 1.5 is ok, >2.0 is interesting.\n'One up on Wall Street' by P Lynch. Simon & Schuster, 1989"
        case 4:
            infoText = "Proportion of book value/ share to current share price in %, as well (book value per share).\nHelps to judge the stock price in relation to company assets."
        case 5:
            infoText = "Intrinsic value based on 10y prediction.\nTaking into account past earnings growth, pre-tax EPS and a long-term discount rate of 2.1%.\nAs calculated in 'Warren Buffet and the Interpretation of Financial Statements' (Simon & Schuster, 2008)"
        default:
            ErrorController.addErrorLog(errorLocation: #file + #function, systemError: nil, errorInfo: "encountered default in switch statement")
        }
        
        let view = tableView.cellForRow(at: indexPath)?.contentView
        
        infoButtonAction(errors: [infoText], sender: view!)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
           
        
        guard let selectedPath = self.tableView.indexPathForSelectedRow else {
            return
        }
        
        // section one has P/E, EPS and beta - no details to show
        guard selectedPath.section > 0 else {
            return
        }
        
        guard let wbVal = controller?.valuation else {
            return
        }
        
        
        if let destination = segue.destination as? ValueListTVC {
            
            guard let validController = controller else {
                return
            }
            
            movingToValueListTVC = true
            
            destination.loadViewIfNeeded()
            
            destination.controller = controller
            destination.indexPath = selectedPath
            let titles = validController.wbvParameters.structuredTitlesParameters()[selectedPath.section-1][selectedPath.row]
            destination.sectionTitles.append(contentsOf: titles)
            destination.cellLegendTitles = validController.valueListChartLegendTitles[selectedPath.section-1][selectedPath.row]
            
            let arrays = arraysForValueListTVC(indexPath: selectedPath)
            
            if selectedPath.section == 1 {
                if selectedPath.row == 0 {
                // Revenue
                    destination.values = arrays
                    destination.formatter = currencyFormatterGapNoPence
                }
                else if selectedPath.row == 1 {
                // Net income
                    destination.values = arrays
                    destination.formatter = currencyFormatterGapWithPence
                }
//                else if selectedPath.row == 2 {
//                // Net income / Revenue
//                    destination.values = arrays
//                    destination.formatter = currencyFormatterGapNoPence
//                    let (margins, _) = validController.valuation!.netIncomeProportion()
//                    destination.proportions = margins
//                }
                else if selectedPath.row == 2 {
                // Ret earnings
                    destination.values = arrays
                    destination.formatter = currencyFormatterGapNoPence
                }
                else if selectedPath.row == 3 {
                // EPS
                    destination.values = arrays
                    destination.formatter = currencyFormatterGapNoPence
                }
               else if selectedPath.row == 4 {
                // Profit margin
                    destination.values = arrays
                    destination.formatter = currencyFormatterGapNoPence
                    let (margins, _) = validController.valuation!.grossProfitMargins()
                    destination.proportions = margins
                
                }
               else if selectedPath.row == 5 {
                // Op. cash flow
                    destination.values = arrays
                    destination.formatter = currencyFormatterGapNoPence
                    let (margins, _) = validController.valuation!.longtermDebtProportion()
                    destination.proportions = margins
                }

            }
            else if selectedPath.section == 2 {
                if selectedPath.row == 0 {
                // ROE
                    destination.values = arrays
                    destination.formatter = percentFormatter0Digits
                }
                else if selectedPath.row == 1 {
                // ROA
                    destination.values = arrays
                    destination.formatter = percentFormatter0Digits
                }
//                else if selectedPath.row == 2 {
//                // Lt debt / adj shareholder equity
//                    destination.values = arrays
//                    destination.formatter = percentFormatter0Digits
//                    destination.higherGrowthIsBetter = false
//                }
            }
            else if selectedPath.section == 3 {
                if selectedPath.row == 0 {
                // CapEx / earnings
                    destination.values = arrays
                    destination.formatter = percentFormatter0Digits
                    let (prop, _) = validController.valuation!.proportions(array1: wbVal.netEarnings, array2: wbVal.capExpend)
                    destination.proportions = prop
                    destination.higherGrowthIsBetter = false
                }
                else if selectedPath.row == 1 {
                // Lt debt / net income
                    destination.values = arrays
                    let (margins, _) = validController.valuation!.longtermDebtProportion()
                    destination.proportions = margins
                    destination.higherGrowthIsBetter = false
                }
                else if selectedPath.row == 2 {
                // SGA / profit
                    destination.values = arrays
                    destination.formatter = currencyFormatterGapNoPence
                    let (margins, _) = validController.valuation!.sgaProportion()
                    destination.proportions = margins
                    destination.higherGrowthIsBetter = false
                }
                else if selectedPath.row == 3 {
                // R&D / profit
                    destination.values = arrays
                    destination.formatter = currencyFormatterGapNoPence
                    let (margins, _) = validController.valuation!.rAndDProportion()
                    destination.proportions = margins
                    destination.higherGrowthIsBetter = false
                }
            }
        }
        
    }

    func arraysForValueListTVC(indexPath: IndexPath) -> [[Double]?]? {
        
        var arrays:[[Double]?]?
        
        if indexPath.section == 1 {
            if indexPath.row == 0 {
            // Revenue
                arrays = [controller?.valuation?.revenue ?? []]
            }
            else if indexPath.row == 1 {
            // net income
                arrays = [controller?.valuation?.netEarnings ?? []]
            }
//            else if indexPath.row == 2 {
//            // net income / revenue
//                arrays = [controller?.valuation?.netEarnings ?? [], controller?.valuation?.revenue ?? []]
//            }
            else if indexPath.row == 2 {
            // Ret. earnings
                arrays = [controller?.valuation?.equityRepurchased ?? []]
            }
            else if indexPath.row == 3 {
            // EPS
                arrays = [controller?.valuation?.eps ?? []]
            }
            else if indexPath.row == 4 {
            // Profit margin
                arrays = [controller?.valuation?.grossProfit ?? [], controller?.valuation?.revenue ?? []]
            }
            else if indexPath.row == 5 {
            // op. cash flow
                arrays = [controller?.valuation?.opCashFlow ?? []]
            }
        }
        else if indexPath.section == 2 {
            if indexPath.row == 0 {
            // ROE
                arrays = [controller?.valuation?.roe ?? []]
            }
            else if indexPath.row == 1 {
            // ROA
                arrays = [controller?.valuation?.roa ?? []]
            }
//            else if indexPath.row == 2 {
//            // Lt debt / adj. shareholder equity
//                if let validController = controller {
//                    let (shEquityWithRetEarnings, _) = validController.valuation!.addElements(array1: validController.valuation?.shareholdersEquity ?? [], array2: validController.valuation!.equityRepurchased ?? [])
//                    arrays = [validController.valuation?.debtLT ?? [], shEquityWithRetEarnings]
//                }
//            }
        }
        else if indexPath.section == 3 {
            if indexPath.row == 0 {
            // capEx / net income
                arrays = [controller?.valuation?.capExpend ?? [], controller?.valuation?.netEarnings ?? []]
            }
            else if indexPath.row == 1 {
            // Lt debt / net income
                arrays = [controller?.valuation?.debtLT ?? [], controller?.valuation?.netEarnings ?? []]
            }
            else if indexPath.row == 2 {
            // SAG / profit
                arrays = [controller?.valuation?.sgaExpense ?? [], controller?.valuation?.grossProfit ?? []]
            }
            else if indexPath.row == 3 {
            // R&D / profit
                arrays = [controller?.valuation?.rAndDexpense ?? [], controller?.valuation?.grossProfit ?? []]
            }
        }

       return arrays

    }
    
    //MARK: - ProgressViewDelegate funcions
    
    func downloadError(error: String) {

        DispatchQueue.main.async {
            self.progressView?.title.font = UIFont.systemFont(ofSize: 14)
            self.progressView?.title.text = error
            self.progressView?.cancelButton.setTitle("OK", for: .normal)
        }
    }
    
    func progressUpdate(allTasks: Int, completedTasks: Int) {
        DispatchQueue.main.async {
            self.progressView?.updateProgress(tasks: allTasks, completed: completedTasks)
        }
    }
    
    func cancelRequested() {
        DispatchQueue.main.async {
            self.controller?.stopDownload()
            self.progressView?.delegate = nil
            self.progressView?.removeFromSuperview()
            self.progressView = nil
        }
    }
    
    func downloadComplete() {
        
        DispatchQueue.main.async {
            self.progressView?.delegate = nil
            self.progressView?.removeFromSuperview()
            self.progressView = nil
            
            self.controller?.updateData()
            self.tableView.reloadData()
        }
        
    }


}

extension WBValuationTVC: WBValuationCellDelegate { //StockDelegate,
        
    func infoButtonAction(errors: [String]?, sender: UIView) {
        
        if let errorsView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ValuationErrorsTVC") as? ValuationErrorsTVC {
            
            errorsView.modalPresentationStyle = .popover
            errorsView.preferredContentSize = CGSize(width: self.view.frame.width * 0.75, height: self.view.frame.height * 0.25)

            let popUpController = errorsView.popoverPresentationController
            popUpController!.permittedArrowDirections = .any
            popUpController!.sourceView = sender
            errorsView.loadViewIfNeeded()
            
            errorsView.errors = errors ?? ["no errors occurred"]
            
            present(errorsView, animated: true, completion:  nil)
        }
    }

    
}

