//
//  StockChartVC.swift
//  TrendMyStocks
//
//  Created by aDav on 01/12/2020.
//

import UIKit

class StockChartVC: UIViewController, UIPopoverPresentationControllerDelegate {

    var share: Share?
    
    @IBOutlet var chart: ChartContainerView!
    @IBOutlet var errorButton: UIBarButtonItem!
    @IBOutlet var barTitleButton: UIBarButtonItem!
    @IBOutlet var dcfButton: UIButton!
    @IBOutlet var priceUpdateButton: UIButton!
    
    @IBOutlet var healthButton: UIButton!
    @IBOutlet var transactionButton: UIButton!
    @IBOutlet var researchButton: UIButton!
    
    var spinner: UIActivityIndicatorView!
    var spinnerMenuButton: UIBarButtonItem!
    var settingsMenuButton: UIBarButtonItem!
    var dcfErrors = [String]()
    var r1Errors: [String]?
    unowned var stocksListVC: StocksListTVC!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if share != nil {
            configure(share: share)
        }
        
        let titleText = share?.name_long ?? "missing company"
        var currencyText = String()
        var exchangeText = String()
        
        
        if let currency = share?.currency {
            currencyText = " (" + currency + ")"
        }
        
        if let exchange = share?.exchange {
            exchangeText = ", " + exchange
        }
        
        let title$ = NSMutableAttributedString(string: titleText, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .title3)])
        let currency$ = NSMutableAttributedString(string: currencyText, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11), NSAttributedString.Key.foregroundColor: UIColor.gray])
        let exchange$ = NSMutableAttributedString(string: exchangeText, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11), NSAttributedString.Key.foregroundColor: UIColor.gray])
        
        title$.append(currency$)
        title$.append(exchange$)
        
        let newLabel: UILabel = {
            let label = UILabel()
            label.attributedText = title$
            label.adjustsFontSizeToFitWidth = true
            label.preferredMaxLayoutWidth = self.view.frame.width * 0.5
            return label
        }()

        
        barTitleButton = UIBarButtonItem(customView: newLabel)
        spinner = UIActivityIndicatorView()
        spinner.style = .medium
        spinner.color = UIColor.label
        spinner.hidesWhenStopped = true
        spinnerMenuButton = UIBarButtonItem(customView: spinner)

        settingsMenuButton = UIBarButtonItem(image: UIImage(systemName: "slider.horizontal.3"), style: .plain, target: self, action: #selector(settingsMenu))

        self.navigationItem.leftBarButtonItems = [barTitleButton]
        self.navigationItem.rightBarButtonItems = [settingsMenuButton, spinnerMenuButton]
        
        NotificationCenter.default.addObserver(self, selector: #selector(activateErrorButton), name: Notification.Name(rawValue: "NewErrorLogged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showCitation), name: Notification.Name(rawValue: "ShowCitation"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadStarted), name: Notification.Name(rawValue: "DownloadStarted"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadEnded), name: Notification.Name(rawValue: "DownloadEnded"), object: nil)

        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        chart?.chartPricesView.currentLabelRefreshTimer?.invalidate()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc
    func settingsMenu() {
        
        if let settingsView = UIStoryboard(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: "SettingsTVC") as? SettingsTVC {
            
            settingsView.modalPresentationStyle = .popover
            settingsView.preferredContentSize = CGSize(width: self.view.bounds.width / 2, height: self.view.bounds.height)

            let popUpController = settingsView.popoverPresentationController
            popUpController!.permittedArrowDirections = .up
            popUpController!.barButtonItem = settingsMenuButton
            popUpController!.delegate = self
            
            present(settingsView, animated: true, completion: nil)
        }
    }
    
    override func viewWillLayoutSubviews() {
        

        chart.chartsContentViewWidth.isActive = false
        chart.chartsContentViewWidth.constant = chart.scrollView.bounds.width * chart.zoomScale
        chart.chartsContentViewWidth.isActive = true
        
        chart.chartView.setNeedsDisplay()
        chart.macdView.setNeedsDisplay()
    }
    
    
    func configure(share: Share?) {
        
        loadViewIfNeeded() // leave! essential
        
        if let validChart = chart {
            chart.chartPricesView.currentLabelRefreshTimer?.invalidate() // when changing a stock invalidate current price update timer of any previously displayed share
            if let validShare = share {
                validChart.configure(with: validShare)
                if validShare.watchStatus == 2 {
                    priceUpdateButton.isHidden = false
                    priceUpdateButton.isEnabled = true
                } else {
                    priceUpdateButton.isHidden = true
                    priceUpdateButton.isEnabled = false
                }
            }
        }

        setValuationTexts()
    }
        
    func setValuationTexts() {
        refreshValuationButton()
    }
    
    func refreshValuationButton() {
        let dcfAge = share?.dcfValuation?.ageOfValuation()
        let r1Age = share?.rule1Valuation?.ageOfValuation()
        let wbvAge = share?.wbValuation?.ageOfValuation()
        
        if let oldestDate = [dcfAge,r1Age,wbvAge].compactMap({$0}).min() {
            if oldestDate > 365*24*3600/2  {
                dcfButton.tintColor = UIColor.systemRed
            } else if oldestDate > 365*24*3600/4 {
                dcfButton.tintColor = UIColor.systemYellow
            }

        }
                
    }

    
    @IBAction func errorButtonAction(_ sender: UIBarButtonItem) {
        
        if let errorList = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ErrorListVC") as? ErrorListVC {
            
            self.present(errorList, animated: true, completion: nil)
        
        }
    }
    
    @IBAction func researchAction(_ sender: UIButton) {
        
        if let researchVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ResearchTVC") as? ResearchTVC {
            researchVC.share = share
            
            self.navigationController?.pushViewController(researchVC, animated: true)
            
            // also show WBvaluationView for financial details
            if let valid = share {
                if let path = stocksListVC.controller.indexPath(forObject: valid) {
                    stocksListVC.showWBValuationView(indexPath: path, chartViewSegue: false)
                }
            }

        }
        
    }
    
    
    @objc
    func activateErrorButton() {
        
        DispatchQueue.main.async {
            self.navigationItem.leftBarButtonItems = [self.barTitleButton,self.errorButton]
            self.view.setNeedsLayout()
        }

    }

    @IBAction func dcfButtonAction(_ sender: UIButton) {
        
        
        stocksListVC.showWBValuationView(indexPath: stocksListVC.tableView.indexPathForSelectedRow ?? IndexPath(row: 0, section: 0), chartViewSegue: false)
                
    }
    
    @objc
    func showCitation() {
                
        let citationView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WelcomeViewController")

        let width = self.splitViewController?.view.bounds.width ?? 1180
        let height = self.splitViewController?.view.bounds.height ?? 820
        
        citationView.view.backgroundColor = UIColor.label
        citationView.modalPresentationStyle = .popover
        citationView.preferredContentSize = CGSize(width: width * 0.4, height: height * 0.3)

        citationView.loadViewIfNeeded()
        if let textView = citationView.view.viewWithTag(10) as? UITextView {
            textView.clipsToBounds = true
            textView.layer.cornerRadius = 8.0
            textView.backgroundColor = UIColor(named: "antiLabel")!
            textView.attributedText = CitationsManager.cite()
        }

        let popUpController = citationView.popoverPresentationController
        popUpController!.permittedArrowDirections = UIPopoverArrowDirection.init(rawValue: 0)
        popUpController?.sourceView = view
        popUpController?.sourceRect = CGRect(x: 20, y: view.frame.height-20, width: 5, height: 5)

        self.parent?.present(citationView, animated: true, completion: nil)

    }
    
    @objc
    func downloadStarted() {
        DispatchQueue.main.async {
            self.spinner.startAnimating()
        }
    }
    
    @objc
    func downloadEnded() {
        DispatchQueue.main.async {
            self.spinner.stopAnimating()
        }
    }
        
    @IBAction func purchaseAction(_ sender: UIButton) {
        
        guard let dialog = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SharePurchaseDialog") as? ShareTransactionDialog else {
            return
        }
        
        dialog.modalPresentationStyle = .popover
        dialog.preferredContentSize = CGSize(width: 400, height: 600)

        let popUpController = dialog.popoverPresentationController
        popUpController!.permittedArrowDirections = .up
        popUpController?.sourceView = transactionButton

        dialog.share = share
        dialog.presentingVC = self
        
        self.present(dialog, animated: true, completion: nil)

    }
    
    @IBAction func healthAction(_ sender: UIButton) {
        
        stocksListVC.showFinHealthView(share: share!)
        
    }
    
    
    func displayPurchaseInfo(button: PurchasedButton) {
        
        guard let dialog = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SharePurchaseDialog") as? ShareTransactionDialog else {
            return
        }
        
        dialog.modalPresentationStyle = .popover
        dialog.preferredContentSize = CGSize(width: 400, height: 600)

        let popUpController = dialog.popoverPresentationController
        popUpController!.permittedArrowDirections = .down
        popUpController?.sourceView = button

        dialog.loadViewIfNeeded()
        
        dialog.existingPurchase(transaction: button.transaction)
        dialog.setCancelButtonToDelete()
        dialog.presentingVC = self

        self.present(dialog, animated: true, completion: nil)

    }
    
    @IBAction func requestPriceUpdate(_ sender: UIButton) {
        if let validShare = share {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SingleShareUpdateRequest"), object: validShare, userInfo: nil)
        }
    }
    
}


//extension StockChartVC: UIPopoverPresentationControllerDelegate {
        
//    func valuationSummaryComplete(toDismiss: ValuationSummaryTVC?) {
//
//        // return point from ValuationSummaryTVC for R1Valuations
//
//        refreshValuationButton()
//
//    }
//
//    func valuationComplete(listView: ValuationListViewController, r1Valuation: Rule1Valuation?) {
//
//        listView.dismiss(animated: true, completion: {
//
//            if let _ = r1Valuation {
//                if let tvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ValuationSummaryTVC") as? ValuationSummaryTVC {
//                    tvc.loadViewIfNeeded()
//                    tvc.delegate = self
//                    tvc.share = self.share
//                    self.present(tvc, animated: true, completion: nil)
//                }
//            }
//            else {
//                self.refreshValuationButton()
//            }
//        })
//    }
    
//}

