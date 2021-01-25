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
    var buildLabel: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        if stockToShow == nil {
            stockToShow = stocks.first
            configure()
        }
        
        buildLabel = UIBarButtonItem(title: "Build: " + appBuild, style: .plain, target: nil, action: nil)
        
        self.navigationItem.leftBarButtonItem = nil
        self.navigationItem.rightBarButtonItem = buildLabel
        
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
        self.navigationItem.leftBarButtonItem = errorButton
        view.setNeedsLayout()

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
