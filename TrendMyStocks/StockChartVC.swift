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
        }
        
        chart.stockToShow = stockToShow
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
