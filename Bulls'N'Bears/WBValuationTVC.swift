//
//  WBValuationTVC.swift
//  Bulls'N'Bears
//
//  Created by aDav on 15/02/2021.
//

import UIKit
import CoreData

enum WBVInfoSection {
    case PE
    case BVPStoPrice
    case Returns
    case Lynch
    case intrinsicValue
}

class WBValuationTVC: UITableViewController, ProgressViewDelegate {

    var downloadButton: UIBarButtonItem!
    var downloadButtonConfiguration: UIButton.Configuration!
    var controller: WBValuationController?
    var share: Share!
    var fromIndexPath: IndexPath!
    var movingToValueListTVC = false
    var r1DataReload = false
    var dcfDataReload = false
    var valuationInfosTexts = [WBVInfoSection: String]()
    
    // progressView
    var progressView: DownloadProgressView?
    var allDownloadTasks = 0
    var completedDownloadTasks = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        downloadButtonConfiguration = UIButton.Configuration.filled()
        downloadButtonConfiguration.title = "Download"
//        downloadButtonConfiguration.attributedTitle = AttributedString("Download")
//        downloadButtonConfiguration.attributedTitle?.font = UIFont.systemFont(ofSize: 14)
        downloadButtonConfiguration.buttonSize = .small
        downloadButtonConfiguration.titleAlignment = .center
        downloadButtonConfiguration.cornerStyle = .small
        let db = UIButton(configuration: downloadButtonConfiguration, primaryAction: UIAction() {_ in
//            self.downloadButtonConfiguration.showsActivityIndicator = true
            self.startDownload()
        })
        
        downloadButton = UIBarButtonItem(customView: db)
         self.navigationItem.rightBarButtonItem = downloadButton
        
        
        setValuationInfoTexts()
        
        self.navigationController?.title = share.name_short
        tableView.register(UINib(nibName: "WBValuationCell", bundle: nil), forCellReuseIdentifier: "wbValuationCell")
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshRow(notification:)), name: NSNotification.Name(rawValue: "refreshWBValuationTVCRow"), object: nil)

        controller = WBValuationController(share: share, progressDelegate: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if r1DataReload {
            r1DataReload = false
            tableView.reloadRows(at: [IndexPath(row: 0, section: 0),IndexPath(row: 6, section: 0) ], with: .automatic)
        } else if dcfDataReload {
            dcfDataReload = false
            tableView.reloadRows(at: [IndexPath(row: 0, section: 7)], with: .automatic)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
        
        cell.accessoryType = .disclosureIndicator

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
        
        var title = controller?.sectionHeaderText(section: section) ?? ""
        let subtitle = controller?.sectionSubHeaderText(section: section)
        
        if section == 0 {
            title = "\(share.symbol!) " + title
        }

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
                label.text = sTitle
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
        progressView?.title.text = "Downloading data ..."

        Task {
            await controller?.downloadAllValuationData()
        }
    }
    
    @objc
    func refreshRow(notification: Notification) {
        movingToValueListTVC = false
        if let indexPath = notification.object as? IndexPath {
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // key financial values for Moat, R1 price and DCF price
        let valuationInfoPaths = [IndexPath(row: 0, section: 0), IndexPath(row: 6, section: 0),IndexPath(row: 7, section: 0)]
        
        if valuationInfoPaths.contains(indexPath) {
            // DCF and R1 valuations display 'ValuationListVC'
            performSegue(withIdentifier: "showDCFR1DetailsSegue", sender: nil)
        }

        else if indexPath.section > 0 {
            // WBV valuation details
            performSegue(withIdentifier: "valueListSegue", sender: nil)
        }
        else {
            // simple info texts about non-DCF/R1 rows in section 0
            performSegue(withIdentifier: "showWBVInfoSegue", sender: nil)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func setValuationInfoTexts() {
        
        valuationInfosTexts[.PE] = "Shows the current P/E (price per earnings) ratio, and past P/E's (minimum - maximum) during the period 6-24 months ago.\n\nThe number of years of earnings at current level to earn back the amount invested now.\n\nCurrent to past range comparison helps to judge whether a stock price is above or below recent levels. Helpful to spot over- or under-pricing"
        valuationInfosTexts[.BVPStoPrice] = "The Book value per share to current share price (in %), and the book value per share)in $.\n\nHelps to judge the stock price in relation to company assets.\n\n Note that the book value may differ from real market value of assets."
        valuationInfosTexts[.Lynch] = "Earnings growth + dividend yield divided by PE ratio.\n\nLess than 1.0 is poor, 1.5 is ok, >2.0 is interesting.\n'One up on Wall Street' by Peter Lynch\nSimon & Schuster, 1989"

        valuationInfosTexts[.intrinsicValue] = "The Intrinsic value based on 10y prediction.\nTaking into account past earnings growth, pre-tax EPS and a long-term discount rate of 2.1%.\n\nAs calculated in 'Warren Buffet and the Interpretation of Financial Statements'\n(Simon & Schuster, 2008)"
        valuationInfosTexts[.Returns] = "If you invested $1000 10 (3) years ago, the value would now be..."
        
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
           
        
        guard let selectedPath = self.tableView.indexPathForSelectedRow else {
            return
        }
         
        if let destination = segue.destination as? ValueListTVC {
            
//            destination.delegate = self
            
            guard let validController = controller else {
                return
            }
            
            movingToValueListTVC = true
            
            destination.loadViewIfNeeded()
            
            destination.controller = controller
//            destination.indexPath = selectedPath
            let titles = validController.wbvParameters.structuredTitlesParameters()[selectedPath.section-1][selectedPath.row]
            destination.sectionTitles.append(contentsOf: titles)
            destination.cellLegendTitles = validController.valueListChartLegendTitles[selectedPath.section-1][selectedPath.row]
            
//            let arrays = arraysForValueListTVC(indexPath: selectedPath)
            destination.datedValues = datedValuesForValueListTVC(indexPath: selectedPath)
            
            if selectedPath.section == 1 {
                if selectedPath.row == 0 {
                // Revenue
//                    destination.values = arrays
                    destination.formatter = currencyFormatterGapNoPence
                }
                else if selectedPath.row == 1 {
                // Net income
//                    destination.values = arrays
                    destination.formatter = currencyFormatterGapWithPence
                }
                else if selectedPath.row == 2 {
                // Ret earnings
//                    destination.values = arrays
                    destination.formatter = currencyFormatterGapNoPence
                }
                else if selectedPath.row == 3 {
                // EPS
//                    destination.values = arrays
                    destination.formatter = currencyFormatterGapNoPence
                }
               else if selectedPath.row == 4 {
                // Profit margin
//                    destination.values = arrays
                    destination.formatter = currencyFormatterGapNoPence
                    destination.datedValues = [destination.datedValues.proportions() ?? [DatedValue]()]
//                   let (dvs, _) = validController.wbValuation!.grossProfitMargins()
//                   let margins = dvs.values(dateOrdered: .ascending)
//                    destination.proportions = margins
                }
               else if selectedPath.row == 5 {
                // Op. cash flow
//                    destination.values = arrays
                    destination.formatter = currencyFormatterGapNoPence
//                    let (margins, _) = validController.wbValuation!.longtermDebtProportion()
//                    destination.proportions = margins
                }

            }
            else if selectedPath.section == 2 {
                if selectedPath.row == 0 {
                // ROE
//                    destination.values = arrays
                    destination.formatter = percentFormatter0Digits
                }
                else if selectedPath.row == 1 {
                // ROA
//                    destination.values = arrays
                    destination.formatter = percentFormatter0Digits
                }
            }
            else if selectedPath.section == 3 {
                if selectedPath.row == 0 {
                // CapEx / earnings
//                    destination.values = arrays
                    destination.formatter = percentFormatter0Digits
//                    let (prop, _) = validController.wbValuation!.proportions(array1: wbVal.netEarnings, array2: wbVal.capExpend)
//                    destination.proportions = prop
                    destination.datedValues = [destination.datedValues.proportions() ?? [DatedValue]()]
                    destination.higherGrowthIsBetter = false
                }
                else if selectedPath.row == 1 {
                // Lt debt / net income
//                    destination.values = arrays
//                    let (margins, _) = validController.wbValuation!.longtermDebtProportion()
                    destination.datedValues = [destination.datedValues.proportions() ?? [DatedValue]()]
                    destination.higherGrowthIsBetter = false
                }
                else if selectedPath.row == 2 {
                // SGA / profit
//                    destination.values = arrays
                    destination.formatter = currencyFormatterGapNoPence
                    destination.datedValues = [destination.datedValues.proportions() ?? [DatedValue]()]
                    destination.higherGrowthIsBetter = false
                }
                else if selectedPath.row == 3 {
                // R&D / profit
//                    destination.values = arrays
                    destination.formatter = currencyFormatterGapNoPence
//                    let (margins, _) = validController.wbValuation!.rAndDProportion()
                    destination.datedValues = [destination.datedValues.proportions() ?? [DatedValue]()]
                    destination.higherGrowthIsBetter = false
                }
            }
        }
        else if let destination = segue.destination as? ValuationListViewController {
            if ([0,6].contains(selectedPath.row)) {
                destination.valuationMethod = .rule1
                r1DataReload = true
            } else {
                destination.valuationMethod = .dcf
                dcfDataReload = true
            }
            destination.share = share
        }
        else if let destination = segue.destination as? ValuationErrorsTVC {
            
            var headerText = "What is "
            
            switch selectedPath.row {
            case 1:
                destination.errors = [valuationInfosTexts[.PE]!]
                headerText += "the PE ratio?"
            case 2:
                destination.errors = [valuationInfosTexts[.BVPStoPrice]!]
                headerText += "the BVPS / Price ratio?"
            case 3:
                destination.errors = [valuationInfosTexts[.Lynch]!]
                
                var score = "NA"
                var yield$ = String()
                var currentPE$ = String()
                var incomeGrowth = String()
                
                let (_,lynch) = share.lynchRatio()
                if lynch != nil {
                    score = numberFormatterWith1Digit.string(from: lynch! as NSNumber) ?? "NA"
                }
                
                if let divYieldDV = share.key_stats?.dividendYield.valuesOnly(dateOrdered: .ascending, withoutZeroes: true, includeThisYear: true)?.last {
                    yield$ += percentFormatter2Digits.string(from: divYieldDV as NSNumber)!
                } else {
                    yield$ += "NA"
                }
                
                if let currentPEdv = share.ratios?.pe_ratios.valuesOnly(dateOrdered: .ascending, withoutZeroes: true, includeThisYear: true)?.last {
                    currentPE$ += numberFormatter2Decimals.string(from: currentPEdv as NSNumber)!
                }
                else {
                    currentPE$ += "NA"
                }
                if let netIncome = share.income_statement?.netIncome.datedValues(dateOrder: .ascending)?.dropZeros() { // ema(periods: emaPeriod)
                    if let growth = netIncome.growthRates(dateOrder: .ascending)?.values() {
                        if let mean = growth.mean() {
                            incomeGrowth += percentFormatter2Digits.string(from: mean as NSNumber)!
                        }
                        else {
                            incomeGrowth += "NA"
                        }
                    }
                    else {
                        incomeGrowth += "NA"
                    }
                }
                else {
                    incomeGrowth += "NA"
                }
                
                destination.otherInfoTexts = [TitleAndDetail]()
                destination.otherInfoTexts?.append(TitleAndDetail(title: "Lynch ratio", detail: score))
                destination.otherInfoTexts?.append(TitleAndDetail(title: "Dividend yield", detail: yield$))
                destination.otherInfoTexts?.append(TitleAndDetail(title: "Current P/E", detail: currentPE$))
                destination.otherInfoTexts?.append(TitleAndDetail(title: "Mean Income growth", detail: incomeGrowth))
                headerText += "the 'Lynch' score?"
            case 4:
                destination.errors = [valuationInfosTexts[.Returns]!]
                
                var currentValue = "-/-"
                if share.return10y != 0 {
                    currentValue = (currencyFormatterNoGapNoPence.string(from: (share.return10y * 1000) as NSNumber) ?? "-")
                }
                if share.return3y != 0 {
                    currentValue += " (" + (currencyFormatterNoGapNoPence.string(from: (share.return3y * 1000) as NSNumber) ?? "-") + ")"
                }
                destination.errors.append(currentValue)
                
                var cagr$ = String()
                if let cagr10 = share.returnRateCAGR(years: 10) {
                    cagr$ += percentFormatter2Digits.string(from: cagr10 as NSNumber) ?? "-"
                }
                if let cagr3 = share.returnRateCAGR(years: 3) {
                    cagr$ += " (" + (percentFormatter2Digits.string(from: cagr3 as NSNumber) ?? "-") + ")"
                }
                cagr$ += " annual compound return"
                
                destination.errors.append(cagr$)
                headerText += "this?"
            case 8:
                destination.errors = [valuationInfosTexts[.intrinsicValue]!]
                headerText += "the Intrinsic value?"
            default:
                headerText = "Unimplemented Info Section"
                destination.errors = ["Not implemented"]
            }
            
            destination.sectionHeaderTexts = [headerText]
        }
        
    }

    func arraysForValueListTVC(indexPath: IndexPath) -> [[Double]?]? {
        
        var arrays:[[Double]?]?
        
        if indexPath.section == 1 {
            if indexPath.row == 0 {
            // Revenue
//                arrays = [controller?.wbValuation?.revenue ?? []]
                arrays = [share.income_statement?.revenue.valuesOnly(dateOrdered: .ascending, oneElementPerYear: true) ?? []]
            }
            else if indexPath.row == 1 {
            // net income
//                arrays = [controller?.wbValuation?.netEarnings ?? []]
                arrays = [share.income_statement?.netIncome.valuesOnly(dateOrdered: .ascending, oneElementPerYear: true) ?? []]
            }
            else if indexPath.row == 2 {
            // Ret. earnings
//                arrays = [controller?.wbValuation?.equityRepurchased ?? []]
                arrays = [share.balance_sheet?.retained_earnings.valuesOnly(dateOrdered: .ascending, oneElementPerYear: true) ?? []]
            }
            else if indexPath.row == 3 {
            // EPS
//                arrays = [controller?.wbValuation?.eps ?? []]
                arrays = [share.income_statement?.eps_annual.valuesOnly(dateOrdered: .ascending, oneElementPerYear: true) ?? []]
            }
            else if indexPath.row == 4 {
            // Profit margin
//                arrays = [controller?.wbValuation?.grossProfit ?? [], controller?.wbValuation?.revenue ?? []]
                arrays = [share.income_statement?.grossProfit.valuesOnly(dateOrdered: .ascending, oneElementPerYear: true) ?? []]
            }
            else if indexPath.row == 5 {
            // op. cash flow
//                arrays = [controller?.wbValuation?.opCashFlow ?? []]
                arrays = [share.cash_flow?.opCashFlow.valuesOnly(dateOrdered: .ascending, oneElementPerYear: true) ?? []]
            }
        }
        else if indexPath.section == 2 {
            if indexPath.row == 0 {
            // ROE
//                arrays = [controller?.wbValuation?.roe ?? []]
                arrays = [share.ratios?.roe.valuesOnly(dateOrdered: .ascending, oneElementPerYear: true) ?? []]
            }
            else if indexPath.row == 1 {
            // ROA
//                arrays = [controller?.wbValuation?.roa ?? []]
                arrays = [share.ratios?.roa.valuesOnly(dateOrdered: .ascending, oneElementPerYear: true) ?? []]
            }
        }
        else if indexPath.section == 3 {
            if indexPath.row == 0 {
            // capEx / net income
//                arrays = [controller?.wbValuation?.capExpend ?? [], controller?.wbValuation?.netEarnings ?? []]
                arrays = [share.cash_flow?.capEx.valuesOnly(dateOrdered: .ascending, oneElementPerYear: true) ?? [], share.income_statement?.netIncome.valuesOnly(dateOrdered: .ascending, oneElementPerYear: true) ?? []]
            }
            else if indexPath.row == 1 {
            // Lt debt / net income
//                arrays = [controller?.wbValuation?.debtLT ?? [], controller?.wbValuation?.netEarnings ?? []]
                arrays = [share.balance_sheet?.debt_longTerm.valuesOnly(dateOrdered: .ascending, oneElementPerYear: true) ?? [], share.income_statement?.netIncome.valuesOnly(dateOrdered: .ascending, oneElementPerYear: true) ?? []]
            }
            else if indexPath.row == 2 {
            // sga / profit
//                arrays = [controller?.wbValuation?.sgaExpense ?? [], controller?.wbValuation?.grossProfit ?? []]
                arrays = [share.income_statement?.sgaExpense.valuesOnly(dateOrdered: .ascending, oneElementPerYear: true) ?? [], share.income_statement?.grossProfit.valuesOnly(dateOrdered: .ascending, oneElementPerYear: true) ?? []]
            }
            else if indexPath.row == 3 {
            // R&D / profit
//                arrays = [controller?.wbValuation?.rAndDexpense ?? [], controller?.wbValuation?.grossProfit ?? []]
                arrays = [share.income_statement?.rdExpense.valuesOnly(dateOrdered: .ascending, oneElementPerYear: true) ?? [], share.income_statement?.grossProfit.valuesOnly(dateOrdered: .ascending, oneElementPerYear: true) ?? []]
            }
        }

       return arrays

    }
    
    func datedValuesForValueListTVC(indexPath: IndexPath) -> [[DatedValue]]? {
        
        var datedValues:[[DatedValue]]?
        let defaultDV = [DatedValue]()
        
        if indexPath.section == 1 {
            if indexPath.row == 0 {
            // Revenue
                datedValues = [share.income_statement?.revenue.datedValues(dateOrder: .ascending, oneForEachYear: true) ?? defaultDV]
//                arrays = [share.income_statement?.revenue.valuesOnly(dateOrdered: .ascending, oneElementPerYear: true) ?? []]
            }
            else if indexPath.row == 1 {
            // net income
                datedValues = [share.income_statement?.netIncome.datedValues(dateOrder: .ascending, oneForEachYear: true) ?? defaultDV]
            }
            else if indexPath.row == 2 {
            // Ret. earnings
                datedValues = [share.balance_sheet?.retained_earnings.datedValues(dateOrder: .ascending, oneForEachYear: true) ?? defaultDV]
            }
            else if indexPath.row == 3 {
            // EPS
                datedValues = [share.income_statement?.eps_annual.datedValues(dateOrder: .ascending, oneForEachYear: true) ?? defaultDV]
            }
            else if indexPath.row == 4 {
            // Profit margin
                datedValues = [share.income_statement?.grossProfit.datedValues(dateOrder: .ascending, oneForEachYear: true) ?? defaultDV, share.income_statement?.revenue.datedValues(dateOrder: .ascending, oneForEachYear: true) ?? []]
            }
            else if indexPath.row == 5 {
            // op. cash flow
                datedValues = [share.cash_flow?.opCashFlow.datedValues(dateOrder: .ascending, oneForEachYear: true) ?? defaultDV]
            }
        }
        else if indexPath.section == 2 {
            if indexPath.row == 0 {
            // ROE
                datedValues = [share.ratios?.roe.datedValues(dateOrder: .ascending, oneForEachYear: true) ?? defaultDV]
            }
            else if indexPath.row == 1 {
            // ROA
                datedValues = [share.ratios?.roa.datedValues(dateOrder: .ascending, oneForEachYear: true) ?? defaultDV]
            }
        }
        else if indexPath.section == 3 {
            if indexPath.row == 0 {
            // capEx / net income
                datedValues = [share.cash_flow?.capEx.datedValues(dateOrder: .ascending, oneForEachYear: true) ?? defaultDV, share.income_statement?.netIncome.datedValues(dateOrder: .ascending, oneForEachYear: true) ?? defaultDV]
            }
            else if indexPath.row == 1 {
            // Lt debt / net income
                datedValues = [share.balance_sheet?.debt_longTerm.datedValues(dateOrder: .ascending, oneForEachYear: true) ?? defaultDV, share.income_statement?.netIncome.datedValues(dateOrder: .ascending, oneForEachYear: true) ?? defaultDV]
            }
            else if indexPath.row == 2 {
            // sga / profit
                datedValues = [share.income_statement?.sgaExpense.datedValues(dateOrder: .ascending, oneForEachYear: true) ?? defaultDV, share.income_statement?.grossProfit.datedValues(dateOrder: .ascending, oneForEachYear: true) ?? defaultDV]
            }
            else if indexPath.row == 3 {
            // R&D / profit
                datedValues = [share.income_statement?.rdExpense.datedValues(dateOrder: .ascending, oneForEachYear: true) ?? defaultDV, share.income_statement?.grossProfit.datedValues(dateOrder: .ascending, oneForEachYear: true) ?? defaultDV]
            }
        }

       return datedValues

    }

    
    //MARK: - ProgressViewDelegate functions
    
    var completedTasks: Int {
        get {
            completedDownloadTasks
        }
        set (newValue) {
            completedDownloadTasks = newValue
        }
    }
    
    
    func taskCompleted() {
        completedTasks += 1
        if allDownloadTasks < completedTasks {
            completedTasks = allDownloadTasks
        }
        
        self.progressUpdate(allTasks: allDownloadTasks, completedTasks: completedTasks)
    }
    
    var allTasks: Int {
        get {
            return allDownloadTasks
        }
        set (newValue) {
            allDownloadTasks = newValue
        }
    }

    func downloadError(error: String) {
        
//        allDownloadTasks -= 1
        completedTasks += 1
        self.progressUpdate(allTasks: allDownloadTasks, completedTasks: completedTasks)

        DispatchQueue.main.async {
            self.progressView?.title.font = UIFont.systemFont(ofSize: 14)
            self.progressView?.title.text = error
            self.progressView?.cancelButton.setTitle("OK", for: .normal)
        }
    }
    
    func progressUpdate(allTasks: Int, completedTasks: Int) {
        DispatchQueue.main.async {
            self.progressView?.updateProgress(tasks: allTasks, completed: completedTasks)
            if completedTasks >= allTasks {
                self.downloadComplete()
            }
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
            
//            self.controller?.updateData()
            self.tableView.reloadData()
        }
        
    }

}

extension WBValuationTVC: WBValuationCellDelegate {
        
    func infoButtonAction(errors: [String]?, otherInfo: [TitleAndDetail]? ,sender: UIView) {
        
        if let errorsView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ValuationErrorsTVC") as? ValuationErrorsTVC {
            
            errorsView.modalPresentationStyle = .popover
            errorsView.preferredContentSize = CGSize(width: self.view.frame.width * 0.75, height: self.view.frame.height * 0.25)

            let popUpController = errorsView.popoverPresentationController
            popUpController!.permittedArrowDirections = .any
            popUpController!.sourceView = sender
            errorsView.loadViewIfNeeded()
            
            errorsView.errors = errors ?? ["no errors occurred"]
            errorsView.otherInfoTexts = otherInfo
            errorsView.firstCellHeight = errorsView.preferredContentSize.height
            
            present(errorsView, animated: true, completion:  nil)
        }
    }

    
}
