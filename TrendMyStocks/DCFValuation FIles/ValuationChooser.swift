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
    var rootView: UIViewController!
    
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
            self.dismiss(animated: true) {
//                self.rootView.navigationController?.pushViewController(tvc, animated: true)
                self.rootView.present(tvc, animated: true)
            }

        }
        
    }

    
    @IBAction func rule1Action(_ sender: UIButton) {
        
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
