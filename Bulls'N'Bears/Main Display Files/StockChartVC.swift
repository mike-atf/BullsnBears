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
    
    var buildLabel: UIBarButtonItem!
    var dcfErrors = [String]()
    var r1Errors: [String]?

    override func viewDidLoad() {
        super.viewDidLoad()

        if share != nil {
            configure(share: share)
        }
        
        buildLabel = UIBarButtonItem(title: "Build: " + appBuild, style: .plain, target: nil, action: nil)
        let titleAttributes = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .title3) ,NSAttributedString.Key.foregroundColor: UIColor.label]
        barTitleButton.setTitleTextAttributes(titleAttributes, for: .normal)
                
        self.navigationItem.leftBarButtonItems = [barTitleButton,researchButton]
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
        chart.macdView.setNeedsDisplay()
    }
    
    func configure(share: Share?) {
        
        loadViewIfNeeded() // leave! essential
        
//        updateCharts {
//            self.setValuationTexts()
//        }
        if let validChart = chart {
            if let validShare = share {
                validChart.configure(with: validShare)
            }
        }

        setValuationTexts()
    }
    
//    private func updateCharts(completion: (@escaping () -> Void)) {
//
//        if let validChart = chart {
//            if let validShare = share {
//                validChart.configure(with: validShare)
//            }
//        }
//
//        completion()
//    }
    
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
            self.navigationItem.leftBarButtonItems = [self.barTitleButton,self.researchButton, self.errorButton]
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
