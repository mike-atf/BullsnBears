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

    var stock: Share!
    weak var rootView: StocksListTVC?
    var sourceCellPath: IndexPath!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func cancelAction(_ sender: UIButton) {
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func dcfAction(_ sender: UIButton) {
                
        if CombinedValuationController.returnDCFValuations(company: stock.symbol) == nil {
            stock.dcfValuation = CombinedValuationController.createDCFValuation(company: stock.symbol!)
        }

        if let tvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ValuationListViewController") as? ValuationListViewController {
            tvc.valuationMethod = ValuationMethods.dcf
            tvc.sourceIndexPath = sourceCellPath
            tvc.share = stock
            
            self.dismiss(animated: true) {
                self.rootView?.navigationController?.present(tvc, animated: true, completion: nil)
                self.rootView = nil
            }
        }
    }
    
    @IBAction func rule1Action(_ sender: UIButton) {
                
        if CombinedValuationController.returnR1Valuations(company: stock.symbol) == nil {
            stock.rule1Valuation = CombinedValuationController.createR1Valuation(company: stock.symbol!)
        }

        if let tvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ValuationListViewController") as? ValuationListViewController {
            tvc.valuationMethod = ValuationMethods.rule1
            tvc.sourceIndexPath = sourceCellPath
            tvc.share = stock
            
            self.dismiss(animated: true) {
                self.rootView?.present(tvc, animated: true)
                self.rootView = nil
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
//    @IBAction func dcfInfoAction(_ sender: UIButton) {
//        
//    }
//    
//    @IBAction func rule1InfoAction(_ sender: UIButton) {
//        
//    }
}
