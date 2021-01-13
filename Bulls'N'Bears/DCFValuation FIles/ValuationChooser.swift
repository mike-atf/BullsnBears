//
//  ValuationChooser.swift
//  TrendMyStocks
//
//  Created by aDav on 03/01/2021.
//

import UIKit

class ValuationChooser: UIViewController {

    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var dcfButton: UIButton!
    @IBOutlet weak var rule1Button: UIButton!

    var stock: Stock!
    var rootView: StocksListViewController!
    var sourceCellPath: IndexPath!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func cancelAction(_ sender: UIButton) {
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func dcfAction(_ sender: UIButton) {
        
        var dcfValuation: DCFValuation!
        
        if let valuation = ValuationsController.returnDCFValuations(company: stock.name)?.first {
            dcfValuation = valuation
        }
        else {
            dcfValuation = ValuationsController.createDCFValuation(company: stock.name)
            if let existingR1Valuation = Rule1ValuationController.returnR1Valuations(company: stock.name)?.first {
                dcfValuation?.getDataFromR1Valuation(r1Valuation: existingR1Valuation)
            }
        }

        if let tvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ValuationListViewController") as? ValuationListViewController {
            tvc.valuationMethod = ValuationMethods.dcf
//            tvc.dcfValuation = dcfValuation
            tvc.presentingListVC = rootView
            tvc.sourceIndexPath = sourceCellPath
            tvc.stock = stock
            
            self.dismiss(animated: true) {
                self.rootView.present(tvc, animated: true)
            }

        }
        
    }
    
    @IBAction func rule1Action(_ sender: UIButton) {
        
        var r1Valuation: Rule1Valuation!
        
        if let valuation = Rule1ValuationController.returnR1Valuations(company: stock.name)?.first {
            r1Valuation = valuation
        }
        else {
            r1Valuation = Rule1ValuationController.createR1Valuation(company: stock.name)
            if let existingDCFValuation = ValuationsController.returnDCFValuations(company: stock.name)?.first {
                r1Valuation?.getDataFromDCFValuation(dcfValuation: existingDCFValuation)
            }
        }

        if let tvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ValuationListViewController") as? ValuationListViewController {
            tvc.valuationMethod = ValuationMethods.rule1
//            tvc.r1Valuation = r1Valuation
            tvc.presentingListVC = rootView
            tvc.sourceIndexPath = sourceCellPath
            tvc.stock = stock
            
            self.dismiss(animated: true) {
                self.rootView.present(tvc, animated: true)
            }

        }

    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       
        let targetVC = segue.destination as UIViewController
        var infoText = String()
        
        if segue.identifier == "dcfInfoSegue" {
            infoText = "Discounted Cash Flow\n\nA suitable valuation method if...\n\n1. The company pays no dividend, or\n\n2. Only pays a small dividend compared to ability to pay, and\n\n3. Free Cash Flow trend aligns with profitability trend, and\n\n4. Investor is taking a control perspective.\n\nNot applicable to companies with negative revenue or net income in the last 3 years!\n\nSee an introduction at https://youtu.be/fd_emLLzJnk"
        }
        else {
            infoText = "Rule #1 valuation\n\nNot applicable to companies with negative revenue or net income in the last 10 years!\n\nEnter annual data up to 10 years back.\n\nAvailable e.g. on www.macrotrends.net.\n\nMore information about methodology on https://www.ruleoneinvesting.com"
        }
        
        if let textView = targetVC.view.viewWithTag(10) as? UITextView {
            textView.text = infoText
        }

    }
    @IBAction func dcfInfoAction(_ sender: UIButton) {
        
    }
    
    @IBAction func rule1InfoAction(_ sender: UIButton) {
        
    }
}
