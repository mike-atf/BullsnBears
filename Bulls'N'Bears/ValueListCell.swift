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
    @IBOutlet var detail: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
       
        textField.delegate = self
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        self.title.text = ""
        self.detail.text = ""
        self.textField.text = ""
        self.textField.placeholder = ""
    }
    
    public func configure(title: String, attributedTitle: String?=nil, superscriptLetterIndex: Int?=nil,value: Any?, detail: String, detailColor: UIColor?=nil, formatter: NumberFormatter) {
        
        if let attTitle = attributedTitle {
            self.title.setAttributedTextWithSuperscripts(text: attTitle, indicesOfSuperscripts: [superscriptLetterIndex!])
        }
        else {
            self.title.text = title
        }
        self.detail.text = detail
        self.detail.textColor = detailColor ?? UIColor.label
        if let number = value as? Double {
            self.textField.placeholder = formatter.string(from: number as NSNumber)
            self.textField.text = formatter.string(from: number as NSNumber)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        return false
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
    }
        
}
