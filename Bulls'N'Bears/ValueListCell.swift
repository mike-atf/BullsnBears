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
    @IBOutlet var leftLowerLabel: UILabel!
    @IBOutlet var rightLowerLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
       
    }
    

    
    override func prepareForReuse() {
        self.title.text = "T-G"
        rightLowerLabel.text = " "
        leftLowerLabel.text = " "
        self.chartView.configure(array1: nil, array2: nil, trendLabel: title)
    }
    
    public func configure(values1: [Double]?, values2: [Double]?, rightTitle: String?, leftTitle: String?) {
                
        rightLowerLabel.text = rightTitle
        rightLowerLabel.textColor = UIColor.systemGray
        if let title = leftTitle {
            leftLowerLabel.text = title
            leftLowerLabel.textColor = UIColor.systemYellow
        } else {
            leftLowerLabel.text = "correlation"
            leftLowerLabel.textColor = UIColor.label
        }
        
        chartView.configure(array1: values1, array2: values2, trendLabel: title)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
        
    }
        
}
