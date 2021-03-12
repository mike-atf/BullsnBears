//
//  StockChartVC.swift
//  TrendMyStocks
//
//  Created by aDav on 01/12/2020.
//

import UIKit

class StockChartVC: UIViewController {

//    var stockToShow: Stock?
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
    
    var buildLabel: UIBarButtonItem!
    var dcfValuation: DCFValuation?
    var r1Valuation: Rule1Valuation?
    var dcfErrors = [String]()
    var r1Errors: [String]?
//    var temporaryValueChartView: ValueChartVC?

    override func viewDidLoad() {
        super.viewDidLoad()

        if share != nil {
            configure(dcfVal: dcfValuation, r1Val: r1Valuation)
        }
        
        buildLabel = UIBarButtonItem(title: "Build: " + appBuild, style: .plain, target: nil, action: nil)
        let titleAttributes = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .title1) ,NSAttributedString.Key.foregroundColor: UIColor.label]
        barTitleButton.setTitleTextAttributes(titleAttributes, for: .normal)
        
        self.navigationItem.leftBarButtonItems = [barTitleButton]
        self.navigationItem.rightBarButtonItem = buildLabel
        barTitleButton.title = share?.name_long
        
        NotificationCenter.default.addObserver(self, selector: #selector(activateErrorButton), name: Notification.Name(rawValue: "NewErrorLogged"), object: nil)
        
        dcfErrorsButton.isHidden = true
        r1ErrorsButton.isHidden = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillLayoutSubviews() {
        
        chart.contentView.setNeedsDisplay()
    }
    
    func configure(dcfVal: DCFValuation?, r1Val: Rule1Valuation?) {
        loadViewIfNeeded() // leave! essential
        if let validChart = chart {
            if let validShare = share {
                validChart.configure(with: validShare)
                dcfValuation = dcfVal
                r1Valuation = r1Val

            }
        }
        
        setValuationTexts()
    }
    
    func setValuationTexts() {
        refreshDCFLabel()
        refreshR1Label()
    }
    
    func refreshDCFLabel() {
        if let validValuation = dcfValuation {
            let (value, errors) = validValuation.returnIValue()
            dcfErrorsButton.isHidden = (errors.count == 0)
            dcfErrors = errors
            
            if let intrinsicValue = value {
                dcfValuationLabrl.text = "DCF value:"
                if intrinsicValue > 0 {
                    let iv$ = currencyFormatterNoGapNoPence.string(from: intrinsicValue as NSNumber) ?? "--"
                    dcfValuationLabrl.text = "DCF value: " + iv$
                }
                else {
                    dcfValuationLabrl.text = "DCF value: negative"
                }
            }
            else {
                dcfValuationLabrl.text = "DCF value: invalid"
            }
        }
    }
    
    func refreshR1Label() {
        
        if let validValuation = r1Valuation {
            
            var r1Title = "R#1 value: "
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
                        r1Title = r1Title + " (moat: " + n$ + ")"
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
    
    @objc
    func activateErrorButton() {
        
        DispatchQueue.main.async {
            self.navigationItem.leftBarButtonItems = [self.barTitleButton,self.errorButton]
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
        
        var dcfValuation: DCFValuation!
        
        if let valuation = CombinedValuationController.returnDCFValuations(company: symbol)?.first {
            dcfValuation = valuation
        }
        else {
            dcfValuation = CombinedValuationController.createDCFValuation(company: symbol)
            if let existingR1Valuation = CombinedValuationController.returnR1Valuations(company: symbol)?.first {
                dcfValuation?.getDataFromR1Valuation(r1Valuation: existingR1Valuation)
            }
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

        var r1Valuation: Rule1Valuation!
        
        if let valuation = CombinedValuationController.returnR1Valuations(company: symbol)?.first {
            r1Valuation = valuation
        }
        else {
            r1Valuation = CombinedValuationController.createR1Valuation(company: symbol)
            if let existingDCFValuation = CombinedValuationController.returnDCFValuations(company: symbol)?.first {
                r1Valuation?.getDataFromDCFValuation(dcfValuation: existingDCFValuation)
            }
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
        
}

extension StockChartVC: ValuationListDelegate, ValuationSummaryDelegate {
    
    func valuationComplete(toDismiss: ValuationSummaryTVC?) {
        
        if toDismiss != nil {

            toDismiss?.dismiss(animated: true, completion: nil)
            guard let symbol = self.share?.symbol else {
                return
            }
            r1Valuation = CombinedValuationController.returnR1Valuations(company: symbol)?.first
            refreshR1Label()
        }
        else {
            guard let symbol = self.share?.symbol else {
                return
            }
            dcfValuation = CombinedValuationController.returnDCFValuations(company: symbol)?.first
            refreshDCFLabel()
        }
    }
    
    func valuationComplete(listView: ValuationListViewController, r1Valuation: Rule1Valuation?) {
        
        listView.dismiss(animated: true, completion: {
            

            if let valuation = r1Valuation {

                if let tvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ValuationSummaryTVC") as? ValuationSummaryTVC {
                    tvc.loadViewIfNeeded()
                    tvc.delegate = self
                    tvc.r1Valuation = valuation
                    self.present(tvc, animated: true, completion: nil)
                }
            }
            else {
                guard let symbol = self.share?.symbol else {
                    return
                }
                self.dcfValuation = CombinedValuationController.returnDCFValuations(company: symbol)?.first
                self.refreshDCFLabel()
            }
        })
    }
    
}
