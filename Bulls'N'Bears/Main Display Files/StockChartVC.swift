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
    
    var buildLabel: UIBarButtonItem!
    var dcfValuation: DCFValuation?
    var r1Valuation: Rule1Valuation?

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
        if let validValuation = dcfValuation {
            if let intrinsicValue = validValuation.returnIValue() {
                dcfValuationLabrl.text = "DCF value:"
                if intrinsicValue > 0 {
                    let iv$ = currencyFormatterNoGapNoPence.string(from: intrinsicValue as NSNumber) ?? "--"
                    dcfValuationLabrl.text = "DCF value: " + iv$
                }
                else {
                    dcfValuationLabrl.text = "DCF value: neagtive"
                }
            }
        }
        else { dcfValuationLabrl.text = "DCF value: no data"}
        
        if let validValuation = r1Valuation {
            var r1Title = "R#1 value: "
            if let stickerPrice = validValuation.stickerPrice() {
                if stickerPrice > 0 {
                    r1Title += (currencyFormatterNoGapNoPence.string(from: stickerPrice as NSNumber) ?? "--")
                }
                else { r1Title += " negative"}
            }
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
    
    @IBAction func errorButtonAction(_ sender: UIBarButtonItem) {
        
        if let errorList = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ErrorListVC") as? ErrorListVC {
            
            self.present(errorList, animated: true, completion: nil)
        
        }
    }
    
    @objc
    func activateErrorButton() {
        self.navigationItem.leftBarButtonItems = [barTitleButton,errorButton]
        view.setNeedsLayout()

    }

}
