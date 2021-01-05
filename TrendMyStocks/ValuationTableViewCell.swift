//
//  ValuationTableViewCell.swift
//  TrendMyStocks
//
//  Created by aDav on 03/01/2021.
//

import UIKit

protocol CellTextFieldDelegate {
    func userAddedText(textField: UITextField, path: IndexPath)
}

class ValuationTableViewCell: UITableViewCell, UITextFieldDelegate {

    @IBOutlet var title: UILabel!
    @IBOutlet var detail: UILabel!
    @IBOutlet var textField: UITextField!
    
    var delegate: CellTextFieldDelegate!
    var indexPath: IndexPath!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        textField.delegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    public func configure(title: String, detail: String, value: Any?, delegate:CellTextFieldDelegate, indexPath: IndexPath) {
        
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = NSLocale.current
            formatter.timeZone = NSTimeZone.local
            formatter.dateStyle = .short
            return formatter
        }()
        
        let currencyFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.currencySymbol = "$"
            formatter.numberStyle = NumberFormatter.Style.currency
            return formatter
        }()

        let percentFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .percent
            formatter.maximumFractionDigits = 2
            formatter.minimumIntegerDigits = 1
            return formatter
        }()
        self.delegate = delegate
        self.indexPath = indexPath
        self.title.text = title
        
        if let validValue = value {
            if let date = validValue as? Date {
                textField.text = dateFormatter.string(from: date)
            }
            else if let number = validValue as? Double {
                if indexPath.section == 0 {
                    textField.text = percentFormatter.string(from: number as NSNumber)
               }
                else {
                    textField.text = currencyFormatter.string(from: number as NSNumber)
                }
            }
            else if let text = validValue as? String {
                textField.text = text
            }
        }
    }
    
    @IBAction func textEntryComplete(_ sender: UITextField) {
        delegate.userAddedText(textField: sender, path: indexPath)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
