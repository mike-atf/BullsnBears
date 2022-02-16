//
//  ValueListCell.swift
//  Bulls'N'Bears
//
//  Created by aDav on 16/02/2021.
//

import UIKit

class ValueListCell: UITableViewCell, UITextFieldDelegate {

    @IBOutlet var title: UILabel!
    @IBOutlet var chartView: ValueChart!
    @IBOutlet var rightLowerLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
       
    }
    

    
    override func prepareForReuse() {
        self.title.text = " "
        rightLowerLabel.text = " "
        self.chartView.configure(array: nil, trendLabel: title, valuesAreGrowth: false, latestDataDate: nil, altLatestDate: nil)
    }
    
    /// values1 contains valuation figures, values2 (optional) has the proportions either comnpared to another set of figures, or element-on-element growth
    public func configure(values: [Double]?, biggerIsBetter: Bool?=true ,rightTitle: String?, valuesAreGrowth: Bool, valuesAreProportions:Bool? = false ,latestDataDate: Date?, altLatestDate: Date?) {
                
        rightLowerLabel.text = rightTitle
        rightLowerLabel.textColor = UIColor.label
        
        chartView.configure(array: values, biggerIsBetter: biggerIsBetter ,trendLabel: title, valuesAreGrowth: valuesAreGrowth,valuesAreProportions:valuesAreProportions, latestDataDate: latestDataDate, altLatestDate: altLatestDate)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
        
    }
        
}
