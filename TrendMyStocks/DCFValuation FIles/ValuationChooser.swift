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
        
        guard let valuation = (ValuationsController.returnDCFValuations(company: stock.name)?.first ?? ValuationsController.createDCFValuation(company: stock.name)) else {
            return
        }

        if let tvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ValuationListViewController") as? ValuationListViewController {
            tvc.valuationMethod = ValuationMethods.dcf
            tvc.valuation = valuation
            tvc.presentingListVC = rootView
            tvc.sourceIndexPath = sourceCellPath
            
            self.dismiss(animated: true) {
//                self.rootView.navigationController?.pushViewController(tvc, animated: true)
                self.rootView.present(tvc, animated: true)
            }

        }
        
    }

    
    @IBAction func rule1Action(_ sender: UIButton) {
        
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       
        let targetVC = segue.destination as UIViewController
        var infoText = String()
        
        if segue.identifier == "dcfInfoSegue" {
            infoText = "Discounted Cash Flow\n\nA suitable valuation method if...\n\n1. The company pays no dividend, or\n\n2. Only pays a small dividend compared to ability to pay, and\n\n3. Free Cash Flow trend aligns with profitability trend, and\n\n4. Investor is taking a control perspective.\n\nSee an introduction at https://youtu.be/fd_emLLzJnk"
        }
        else {
            
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
