//
//  ValueChartVC.swift
//  Bulls'N'Bears
//
//  Created by aDav on 21/02/2021.
//

import UIKit

class ValueChartVC: UIViewController {

    var chart: ValueChart!
    var values: [Double]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        chart = ValueChart()
        chart.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(chart)
        let margins = self.view.layoutMarginsGuide
        
        chart?.widthAnchor.constraint(equalTo: margins.widthAnchor, multiplier: 0.8).isActive = true
        chart?.centerXAnchor.constraint(equalTo: margins.centerXAnchor).isActive = true
        chart?.centerYAnchor.constraint(equalTo: margins.centerYAnchor).isActive = true
        chart?.heightAnchor.constraint(equalTo: margins.heightAnchor , multiplier: 0.9).isActive = true
        
        chart.configure(array: values)
        chart.setNeedsDisplay()
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
