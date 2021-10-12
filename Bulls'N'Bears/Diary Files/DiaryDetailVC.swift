//
//  DiaryDetailVC.swift
//  Bulls'N'Bears
//
//  Created by aDav on 12/10/2021.
//

import UIKit

class DiaryDetailVC: UIViewController {

    @IBOutlet var chart: ChartView!
    
    var share: Share?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        print ("detail view loaded")
        if share != nil {
            chart.backgroundColor = UIColor.systemBackground
            chart.configure(stock: share!,withForeCast: false)
        }
        else {
            configure()
        }

    }
    
    func configure() {
        loadViewIfNeeded() // leave! essential
        
        if let validChart = chart {
            if let validShare = share {
                validChart.configure(stock: validShare, withForeCast: false)
            }
        }
    }

}
