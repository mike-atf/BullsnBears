//
//  TBYChartViewController.swift
//  Bulls'N'Bears
//
//  Created by aDav on 05/05/2021.
//

import UIKit

class TBYChartViewController: UIViewController {

    @IBOutlet var chartView: ValueChart!
    
    var tbRates: [Double]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        chartView.configure(array1: tbRates, array2: nil, trendLabel: nil)
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
