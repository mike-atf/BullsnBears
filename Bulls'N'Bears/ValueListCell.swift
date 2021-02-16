//
//  ValueListCell.swift
//  Bulls'N'Bears
//
//  Created by aDav on 16/02/2021.
//

import UIKit

class ValueListCell: UITableViewCell, UITextFieldDelegate {

    @IBOutlet var title: UILabel!
    @IBOutlet var textField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
       
        textField.delegate = self
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    public func configure(title: String, value: Any?) {
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        return false
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
    }
        
}
