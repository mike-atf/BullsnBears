//
//  WBValuationTVC.swift
//  Bulls'N'Bears
//
//  Created by aDav on 15/02/2021.
//

import UIKit

class WBValuationTVC: UITableViewController, ProgressViewDelegate {

    var downloadButton: UIBarButtonItem!
    var controller: WBValuationController!
    var stock: Stock!
    var progressView: DownloadProgressView?
    var fromIndexPath: IndexPath!
    var movingToValueListTVC = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        downloadButton = UIBarButtonItem(image: UIImage(systemName: "icloud.and.arrow.down.fill"), style: .plain, target: self, action: #selector(startDownload))
         self.navigationItem.rightBarButtonItem = downloadButton
        
        self.navigationController?.title = stock.name_short
        tableView.register(UINib(nibName: "WBValuationCell", bundle: nil), forCellReuseIdentifier: "wbValuationCell")
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshRow(notification:)), name: NSNotification.Name(rawValue: "refreshWBValuationTVCRow"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        guard !movingToValueListTVC else {
            return
        }
        
        // this updates the stock user- and fundamentals parametr when returning to StocksListVC for updating ScoreCircle view
        let _ = WBValuationController.summaryRating(symbol: stock.symbol, type: .star)
        let _ = WBValuationController.summaryRating(symbol: stock.symbol, type: .dollar)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        guard !movingToValueListTVC else {
            return
        }

        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshStockListTVCRow"), object: fromIndexPath, userInfo: nil)
    }

    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return controller.sectionTitles.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return controller.rowTitles[section].count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "wbValuationCell", for: indexPath) as! WBValuationCell

        let (value$, color, errors) = controller.value$(path: indexPath)
        let evaluation = controller.userEvaluation(for: indexPath)
        var correlation: Correlation?
        if let arrays = arraysForValueListTVC(indexPath: indexPath) {
            let proportions = controller.valueListTVCProportions(values: arrays)
            let sendArrays = [arrays[0], proportions]
            correlation = Calculator.valueChartCorrelation(arrays:sendArrays)
        }
        cell.configure(title: controller.rowTitle(path: indexPath), detail: value$, detailColor: color,errors: errors, delegate: self, userEvaluation: evaluation, correlation: correlation)
        
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
        return 60
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = UIView()
        let height: CGFloat = (UIDevice().userInterfaceIdiom == .pad) ? 60 : 50
        header.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: height)
        
        let (title, subtitle) = controller.sectionHeaderText(section: section)
        
        let largeFontSize: CGFloat = (UIDevice().userInterfaceIdiom == .pad) ? 22 : 20
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
        
        
        let margins = header.layoutMarginsGuide
        
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.topAnchor.constraint(equalTo: margins.topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 10).isActive = true
        titleLabel.trailingAnchor.constraint(greaterThanOrEqualTo: subTitle.leadingAnchor, constant: 10).isActive = true
        
        subTitle.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: 5).isActive = true
        subTitle.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
        subTitle.trailingAnchor.constraint(greaterThanOrEqualTo: titleLabel.leadingAnchor, constant: 10).isActive = true
        
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
        progressView?.title.text = "Public data download..."

        controller.downloadWBValuationData()
    }
    
    @objc
    func refreshRow(notification: Notification) {
        movingToValueListTVC = false
        if let indexPath = notification.object as? IndexPath {
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        performSegue(withIdentifier: "valueListSegue", sender: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        
        var infoText = String()
        
        switch indexPath.row {
        case 0:
            infoText = "Current P/E ratio, and P/E (mininum - maximum) during the period 6-24 months ago.\nThis allows comparison of current P/E to the recent past in order to help judge whether a stock price is above or below recent levels. Helpful to spot over- or under-pricing"
        case 1:
            infoText = "Not implemented"
        case 2:
            infoText = "Proportion of book value to current share price in %, as well (book value per share).\nHelps to judge the stock price in relation to company assets."
        case 3:
            infoText = "Proportion of book value/ share to current share price in %, as well (book value per share).\nHelps to judge the stock price in relation to company assets."
        case 4:
            infoText = "Intrinsic value based on 10y prediction.\nTaking into account past earnings growth, pre-tax EPS and a long-term discount rate of 2.1%.\nAs calculated in 'Warren Buffet and the Interpretation of Financial Statements' (Simon & Schuster, 2008)"
        default:
            print("Error - default")
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
        
        
        if let destination = segue.destination as? ValueListTVC {
            
            movingToValueListTVC = true
            
            destination.loadViewIfNeeded()
            
            destination.controller = controller
            destination.indexPath = selectedPath
            let titles = controller.wbvParameters.structuredTitlesParameters()[selectedPath.section-1][selectedPath.row]
            destination.sectionTitles.append(contentsOf: titles)
            destination.cellLegendTitles = controller.valueListChartLegendTitles[selectedPath.section-1][selectedPath.row]
            
            let arrays = arraysForValueListTVC(indexPath: selectedPath)
            
            if selectedPath.section == 1 {
                if selectedPath.row == 0 {
                    destination.values = arrays
                    destination.formatter = currencyFormatterGapNoPence
                }
                else if selectedPath.row == 1 {
                    destination.values = arrays
                    destination.formatter = currencyFormatterGapWithPence
                }
                else if selectedPath.row == 2 {
                    destination.values = arrays
                    destination.formatter = currencyFormatterGapNoPence
                    let (margins, _) = controller.valuation!.netIncomeProportion()
                    destination.proportions = margins
                }
                else if selectedPath.row == 3 {
                    destination.values = arrays
                    destination.formatter = currencyFormatterGapNoPence
                    let (margins, _) = controller.valuation!.grossProfitMargins()
                    destination.proportions = margins
                }
                else if selectedPath.row == 4 {
                    destination.values = arrays
                    destination.formatter = currencyFormatterGapNoPence
                    let (margins, _) = controller.valuation!.longtermDebtProportion()
                    destination.proportions = margins
                    destination.higherGrowthIsBetter = false
                }
            }
            else if selectedPath.section == 2 {
                if selectedPath.row == 0 {
                    destination.values = arrays
                    destination.formatter = percentFormatter0Digits
                }
                else if selectedPath.row == 1 {
                    destination.values = arrays
                    destination.formatter = percentFormatter0Digits
                }
                else if selectedPath.row == 2 {
                    destination.values = arrays
                    destination.formatter = currencyFormatterGapNoPence
                    destination.higherGrowthIsBetter = false
                }
            }
            else if selectedPath.section == 3 {
                if selectedPath.row == 0 {
                    destination.values = arrays
                    destination.formatter = currencyFormatterGapNoPence
                    let (margins, _) = controller.valuation!.sgaProportion()
                    destination.proportions = margins
                    destination.higherGrowthIsBetter = false
                    
                }
                else if selectedPath.row == 1 {
                    destination.values = arrays
                    destination.formatter = currencyFormatterGapNoPence
                    let (margins, errors) = controller.valuation!.rAndDProportion()
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
                arrays = [controller.valuation?.equityRepurchased ?? []]
            }
            else if indexPath.row == 1 {
                arrays = [controller.valuation?.eps ?? []]
            }
            else if indexPath.row == 2 {
                arrays = [controller.valuation?.netEarnings ?? [], controller.valuation?.revenue ?? []]
            }
            else if indexPath.row == 3 {
                arrays = [controller.valuation?.grossProfit ?? [], controller.valuation?.revenue ?? []]
            }
            else if indexPath.row == 4 {
                arrays = [controller.valuation?.debtLT ?? [], controller.valuation?.netEarnings ?? []]
            }
        }
        else if indexPath.section == 2 {
            if indexPath.row == 0 {
                arrays = [controller.valuation?.roe ?? []]
            }
            else if indexPath.row == 1 {
                arrays = [controller.valuation?.roa ?? []]
            }
            else if indexPath.row == 2 {
                let (shEquityWithRetEarnings, _) = controller.valuation!.addElements(array1: controller.valuation?.shareholdersEquity ?? [], array2: controller.valuation!.equityRepurchased ?? [])
                arrays = [controller.valuation?.debtLT ?? [], shEquityWithRetEarnings]
            }
        }
        else if indexPath.section == 3 {
            if indexPath.row == 0 {
                arrays = [controller.valuation?.sgaExpense ?? [], controller.valuation?.grossProfit ?? []]
            }
            else if indexPath.row == 1 {
                arrays = [controller.valuation?.rAndDexpense ?? [], controller.valuation?.grossProfit ?? []]
            }
        }

       return arrays

    }
    
    func progressUpdate(allTasks: Int, completedTasks: Int) {
        self.progressView?.updateProgress(tasks: allTasks, completed: completedTasks)
    }
    
    func cancelRequested() {
        controller.stopDownload()
    }
    
    func downloadComplete() {
        self.progressView?.delegate = nil
        progressView?.removeFromSuperview()
        progressView = nil
        
        controller.valuation?.save()
        
        tableView.reloadData()
    }


}

extension WBValuationTVC: StockKeyratioDownloadDelegate, WBValuationCellDelegate {
    
    func keyratioDownloadComplete(errors: [String]) {
        DispatchQueue.main.async {
            self.tableView.reloadSections([0], with: .automatic)

        }
    }
    
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

