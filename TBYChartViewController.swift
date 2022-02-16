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
        chartView.configure(array: rates, biggerIsBetter: false ,trendLabel: nil, valuesAreGrowth: false, showXLabels: false, showsXYearLabel: true,latestDataDate: nil ,altLatestDate: nil)
    }

}
