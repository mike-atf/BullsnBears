//
//  StockChartVC.swift
//  TrendMyStocks
//
//  Created by aDav on 01/12/2020.
//

import UIKit

class StockChartVC: UIViewController {

    var stockToShow: Stock?
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
    var temporaryValueChartView: ValueChartVC?

    override func viewDidLoad() {
        super.viewDidLoad()

        if stockToShow == nil {
            stockToShow = stocks.first
            configure()
        }
        
        buildLabel = UIBarButtonItem(title: "Build: " + appBuild, style: .plain, target: nil, action: nil)
        let titleAttributes = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .title1) ,NSAttributedString.Key.foregroundColor: UIColor.label]
        barTitleButton.setTitleTextAttributes(titleAttributes, for: .normal)
        
        self.navigationItem.leftBarButtonItems = [barTitleButton]
        self.navigationItem.rightBarButtonItem = buildLabel
        barTitleButton.title = stockToShow?.name_long
        
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
    
    func configure() {
        loadViewIfNeeded() // leave! essential
        if let validChart = chart {
            if let stock = stockToShow {
                validChart.configure(with: stock)
                dcfValuation = CombinedValuationController.returnDCFValuations(company: stock.symbol)?.first
                r1Valuation = CombinedValuationController.returnR1Valuations(company: stock.symbol)?.first
            }
        }
        
        setValuationTexts()
    }
    
    func setValuationTexts() {
        refreshDCFLabel()
        refreshR1Label()
    }
    
//    func addValueChartView(array: [Double]?) {
//
//        temporaryValueChartView = ValueChart()
//        chart.translatesAutoresizingMaskIntoConstraints = false
//
//        self.view.addSubview(temporaryValueChartView!)
//        let margins = self.view.layoutMarginsGuide
//
//        temporaryValueChartView?.leadingAnchor.constraint(equalTo: margins.leadingAnchor).isActive = true
//        temporaryValueChartView?.topAnchor.constraint(equalTo: margins.topAnchor).isActive = true
//        temporaryValueChartView?.trailingAnchor.constraint(equalTo: margins.trailingAnchor).isActive = true
//        temporaryValueChartView?.bottomAnchor.constraint(equalTo: margins.bottomAnchor).isActive = true
//
//        temporaryValueChartView?.configure(array: array)
//
//    }
    
//    func removeValueChartView() {
//
//        self.temporaryValueChartView?.removeFromSuperview()
//        temporaryValueChartView = nil
//    }
    
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
        
        guard let stock = stockToShow else {
            return
        }

        
        var dcfValuation: DCFValuation!
        
        if let valuation = CombinedValuationController.returnDCFValuations(company: stock.symbol)?.first {
            dcfValuation = valuation
        }
        else {
            dcfValuation = CombinedValuationController.createDCFValuation(company: stock.symbol)
            if let existingR1Valuation = CombinedValuationController.returnR1Valuations(company: stock.symbol)?.first {
                dcfValuation?.getDataFromR1Valuation(r1Valuation: existingR1Valuation)
            }
        }

        if let tvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ValuationListViewController") as? ValuationListViewController {
            tvc.valuationMethod = ValuationMethods.dcf
            tvc.stock = stock
            tvc.delegate = self
            
            self.present(tvc, animated: true, completion: nil)
        }

    }
    
    @IBAction func r1ButtonAction(_ sender: UIButton) {
        
        guard let validStock = stockToShow else {
            return
        }
        
        var r1Valuation: Rule1Valuation!
        
        if let valuation = CombinedValuationController.returnR1Valuations(company: validStock.symbol)?.first {
            r1Valuation = valuation
        }
        else {
            r1Valuation = CombinedValuationController.createR1Valuation(company: validStock.symbol)
            if let existingDCFValuation = CombinedValuationController.returnDCFValuations(company: validStock.symbol)?.first {
                r1Valuation?.getDataFromDCFValuation(dcfValuation: existingDCFValuation)
            }
        }

        if let tvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ValuationListViewController") as? ValuationListViewController {
            
            tvc.valuationMethod = ValuationMethods.rule1
            tvc.stock = validStock
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
            r1Valuation = CombinedValuationController.returnR1Valuations(company: stockToShow!.symbol)?.first
            refreshR1Label()
        }
        else {
            dcfValuation = CombinedValuationController.returnDCFValuations(company: stockToShow!.symbol)?.first
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
                self.dcfValuation = CombinedValuationController.returnDCFValuations(company: self.stockToShow!.symbol)?.first
                self.refreshDCFLabel()
            }
        })
    }
    
}

extension StockChartVC: StocksListDelegate {
    
    func showValueListChart(array: [Double]?) {
        
        return
            
        temporaryValueChartView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ValueChartVC") as? ValueChartVC
            
        temporaryValueChartView?.values = array
        
        self.present(temporaryValueChartView!, animated: true, completion: nil)
        
    }
    
    func removeValueListChart() {
        
        temporaryValueChartView?.dismiss(animated: true, completion: {
            self.temporaryValueChartView = nil
        })
        
    }
    
    
}
