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
    
    override func awakeFromNib() {
        super.awakeFromNib()
       
//        textField.delegate = self
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        self.title.text = ""
        self.chartView.configure(array1: nil, array2: nil)
    }
    
    public func configure(title: String, values1: [Double]?, values2: [Double]?) {
        
        self.title.text = title
        
        chartView.configure(array1: values1, array2: values2)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
        
    }
        
}
