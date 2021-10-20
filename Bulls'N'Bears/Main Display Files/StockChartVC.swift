//
//  StockChartVC.swift
//  TrendMyStocks
//
//  Created by aDav on 01/12/2020.
//

import UIKit

class StockChartVC: UIViewController {

    var share: Share?
    
    @IBOutlet var chart: ChartContainerView!
    @IBOutlet var errorButton: UIBarButtonItem!
    @IBOutlet var barTitleButton: UIBarButtonItem!
    @IBOutlet var dcfValuationLabrl: UILabel!
    @IBOutlet var r1ValuationLabel: UILabel!
    @IBOutlet var dcfButton: UIButton!
    @IBOutlet var r1Button: UIButton!
    @IBOutlet var dcfErrorsButton: UIButton!
    @IBOutlet var r1ErrorsButton: UIButton!
    @IBOutlet var researchButton: UIBarButtonItem!
    @IBOutlet var purchaseButton: UIBarButtonItem!
    
    var buildLabel: UIBarButtonItem!
    var dcfErrors = [String]()
    var r1Errors: [String]?

    override func viewDidLoad() {
        super.viewDidLoad()

        if share != nil {
            configure(share: share)
        }
        
        barTitleButton.title = share?.name_long

        buildLabel = UIBarButtonItem(title: "Build " + appBuild, style: .plain, target: nil, action: nil)
                
        let fixedSizeItem = UIBarButtonItem.fixedSpace(100)
        self.navigationItem.leftBarButtonItems = [barTitleButton,researchButton, purchaseButton, fixedSizeItem]
        self.navigationItem.rightBarButtonItem = buildLabel
        
        NotificationCenter.default.addObserver(self, selector: #selector(activateErrorButton), name: Notification.Name(rawValue: "NewErrorLogged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showCitation), name: Notification.Name(rawValue: "ShowCitation"), object: nil)
        
        dcfErrorsButton.isHidden = true
        r1ErrorsButton.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        chart?.chartPricesView.currentLabelRefreshTimer?.invalidate()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillLayoutSubviews() {
        
        chart.chartView.setNeedsDisplay()
        chart.macdView.setNeedsDisplay()
    }
    
    
    func configure(share: Share?) {
        
        loadViewIfNeeded() // leave! essential
        
        if let validChart = chart {
            chart.chartPricesView.currentLabelRefreshTimer?.invalidate() // when changing a stock invalidate current price update timer of any previously displayed share
            if let validShare = share {
                validChart.configure(with: validShare)
            }
        }

        setValuationTexts()
    }
        
    func setValuationTexts() {
        refreshDCFLabel()
        refreshR1Label()
    }
    
    func refreshDCFLabel() {
        if let validValuation = share?.dcfValuation {
            let (value, errors) = validValuation.returnIValue()
            dcfErrorsButton.isHidden = (errors.count == 0)
            dcfErrors = errors
            
            if let intrinsicValue = value {
                dcfValuationLabrl.text = "DCF :"
                if intrinsicValue > 0 {
                    let iv$ = currencyFormatterNoGapNoPence.string(from: intrinsicValue as NSNumber) ?? "--"
                    dcfValuationLabrl.text = "DCF : " + iv$
                }
                else {
                    dcfValuationLabrl.text = "DCF : negative"
                }
            }
            else {
                dcfValuationLabrl.text = "DCF : invalid"
            }
        }
    }
    
    func refreshR1Label() {
        
        if let validValuation = share?.rule1Valuation {
            
            var r1Title = "GBV: "
            let (value, errors) = validValuation.stickerPrice()
            r1ErrorsButton.isHidden = (errors == nil)
            r1Errors = errors
            
            if let stickerPrice = value {
                if stickerPrice > 0 {
                    r1Title += (currencyFormatterNoGapNoPence.string(from: stickerPrice as NSNumber) ?? "--")
                }
                else { r1Title += " negative"}

                if let score = validValuation.moatScore() {
                    if !score.isNaN {
                        let n$ = percentFormatter0Digits.string(from: score as NSNumber) ?? ""
                        r1Title = r1Title + " (Compet. strength: " + n$ + ")"
                    }
                }
                
                if let proportion = validValuation.debtProportion() {
                    if proportion > 3.0 {
                        r1Title += ", debt: " + (percentFormatter0Digits.string(from: proportion as NSNumber) ?? "-")
                    }
                }

                if let proportion = validValuation.insiderSalesProportion() {
                    if proportion > 0.1 {
                        r1Title += ", insider sales: " + (percentFormatter0Digits.string(from: proportion as NSNumber) ?? "-")
                    }
                }

                r1ValuationLabel.text = r1Title
            }
        }
    }
    
    @IBAction func errorButtonAction(_ sender: UIBarButtonItem) {
        
        if let errorList = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ErrorListVC") as? ErrorListVC {
            
            self.present(errorList, animated: true, completion: nil)
        
        }
    }
    
    @IBAction func researchAction(_ sender: UIBarButtonItem) {
        
        if let researchVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ResearchTVC") as? ResearchTVC {
            researchVC.share = share
            
            self.navigationController?.pushViewController(researchVC, animated: true)
        
        }
    }
    
    
    @objc
    func activateErrorButton() {
        
        DispatchQueue.main.async {
            self.navigationItem.leftBarButtonItems = [self.barTitleButton,self.researchButton, self.purchaseButton ,self.errorButton]
            self.view.setNeedsLayout()
        }

    }

    @IBAction func dcfButtonAction(_ sender: UIButton) {
        
        guard let validShare = share else {
            return
        }
        
        guard let symbol = validShare.symbol else {
            return
        }
                
        if CombinedValuationController.returnDCFValuations(company: symbol) == nil {
            share?.dcfValuation = CombinedValuationController.createDCFValuation(company: symbol)
        }

        if let tvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ValuationListViewController") as? ValuationListViewController {
            tvc.valuationMethod = ValuationMethods.dcf
            tvc.share = validShare
            tvc.delegate = self
            
            self.present(tvc, animated: true, completion: nil)
        }

    }
    
    @IBAction func r1ButtonAction(_ sender: UIButton) {
        
        guard let validShare = share else {
            return
        }
        
        guard let symbol = validShare.symbol else {
            return
        }

        if CombinedValuationController.returnR1Valuations(company: symbol) == nil {
            share?.rule1Valuation = CombinedValuationController.createR1Valuation(company: symbol)
        }

        if let tvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ValuationListViewController") as? ValuationListViewController {
            
            tvc.valuationMethod = ValuationMethods.rule1
            tvc.share = validShare
            tvc.delegate = self
            
            self.present(tvc, animated: true, completion: nil)
        }
    }

    @IBAction func dcfErrorsButtonAction(_ sender: UIButton) {
        
        if let errorsView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ValuationErrorsTVC") as? ValuationErrorsTVC {
            
            errorsView.modalPresentationStyle = .popover
            errorsView.preferredContentSize = CGSize(width: self.view.frame.width * 0.5, height: self.view.frame.height * 0.5)

            let popUpController = errorsView.popoverPresentationController
            popUpController!.permittedArrowDirections = .any
            popUpController!.sourceView = sender
            errorsView.loadViewIfNeeded()
            
            errorsView.errors = dcfErrors
            
            present(errorsView, animated: true, completion:  nil)
        }
    }
    
    @IBAction func r1ErrorsButtonAction(_ sender: UIButton) {
        
        if let errorsView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ValuationErrorsTVC") as? ValuationErrorsTVC {
            
            errorsView.modalPresentationStyle = .popover
            errorsView.preferredContentSize = CGSize(width: self.view.frame.width * 0.5, height: self.view.frame.height * 0.5)

            let popUpController = errorsView.popoverPresentationController
            popUpController!.permittedArrowDirections = .any
            popUpController!.sourceView = sender
            errorsView.loadViewIfNeeded()
            
            errorsView.errors = r1Errors!
            
            present(errorsView, animated: true, completion:  nil)
        }
    }
    
    @objc
    func showCitation() {
                
        let citationView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WelcomeViewController")

        let width = self.splitViewController?.view.bounds.width ?? 1180
        let height = self.splitViewController?.view.bounds.height ?? 820
        
        citationView.view.backgroundColor = UIColor.systemGray
        citationView.modalPresentationStyle = .popover
        citationView.preferredContentSize = CGSize(width: width * 0.4, height: height * 0.3)

        citationView.loadViewIfNeeded()
        if let textView = citationView.view.viewWithTag(10) as? UITextView {
            textView.backgroundColor = UIColor.systemGray4
            textView.attributedText = CitationsManager.cite()
        }

        let popUpController = citationView.popoverPresentationController
        popUpController!.permittedArrowDirections = UIPopoverArrowDirection.init(rawValue: 0)
//        popUpController!.permittedArrowDirections = [.down, .right]
        popUpController?.sourceView = view
        popUpController?.sourceRect = CGRect(x: 20, y: view.frame.height-20, width: 5, height: 5)

        self.parent?.present(citationView, animated: true, completion: nil)

    }
        
    @IBAction func purchaseAction(_ sender: UIBarButtonItem) {
        
        guard let dialog = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SharePurchaseDialog") as? ShareTransactionDialog else {
            return
        }
        
        dialog.modalPresentationStyle = .popover
        dialog.preferredContentSize = CGSize(width: 400, height: 600)

        let popUpController = dialog.popoverPresentationController
        popUpController!.permittedArrowDirections = .up
        popUpController?.barButtonItem = sender

        dialog.share = share
        dialog.presentingVC = self
        
        self.present(dialog, animated: true, completion: nil)

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

}

extension StockChartVC: ValuationListDelegate, ValuationSummaryDelegate {
    
    func valuationSummaryComplete(toDismiss: ValuationSummaryTVC?) {

        // return point from ValuationSummaryTVC for R1Valuations
        
        if toDismiss != nil {

            toDismiss?.dismiss(animated: true, completion: nil)
            refreshR1Label()
        }
        else {
            refreshDCFLabel()
        }
    }
    
    func valuationComplete(listView: ValuationListViewController, r1Valuation: Rule1Valuation?) {

        listView.dismiss(animated: true, completion: {

            if let _ = r1Valuation {
                if let tvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ValuationSummaryTVC") as? ValuationSummaryTVC {
                    tvc.loadViewIfNeeded()
                    tvc.delegate = self
                    tvc.share = self.share
                    self.present(tvc, animated: true, completion: nil)
                }
            }
            else {
                self.refreshDCFLabel()
            }
        })
    }
    
}
