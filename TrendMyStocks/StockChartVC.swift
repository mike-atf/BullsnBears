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
    

    override func viewDidLoad() {
        super.viewDidLoad()

        if stockToShow == nil {
            stockToShow = stocks.first
            configure()
        }
        
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
