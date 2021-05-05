//
//  TBYChartViewController.swift
//  Bulls'N'Bears
//
//  Created by aDav on 05/05/2021.
//

import UIKit

class TBYChartViewController: UIViewController {

    @IBOutlet var chartView: ValueChart!
    @IBOutlet var datesLabel: UILabel!
    
    var tbrPriceDates: [PriceDate]? // time-DESCENDING
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let rates = tbrPriceDates?.compactMap{ $0.price }
        if let lastDate = tbrPriceDates?.first?.date {
            if let firstDate = tbrPriceDates?.last?.date {
                let fdate$ = dateFormatter.string(from: firstDate)
                let ldate$ = dateFormatter.string(from: lastDate)
                datesLabel.text = fdate$ + " - " + ldate$
            }
        }
        chartView.configure(array1: rates, array2: nil, trendLabel: nil)
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
