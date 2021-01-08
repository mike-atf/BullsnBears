//
//  ValuationTableViewCell.swift
//  TrendMyStocks
//
//  Created by aDav on 03/01/2021.
//

import UIKit

//protocol CellTextFieldDelegate {
//    func userAddedText(textField: UITextField, path: IndexPath)
//}

class ValuationTableViewCell: UITableViewCell, UITextFieldDelegate {

    @IBOutlet var title: UILabel!
    @IBOutlet var detail: UILabel!
    @IBOutlet var textField: UITextField!
        
    var delegate: DCFValuationHelper!
    var indexPath: IndexPath!
    var valueFormat: ValuationCellValueFormat!
    
    override func awakeFromNib() {
        super.awakeFromNib()

//        #selector(), for: .valueChanged  )
        
        textField.delegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        title.text = ""
        detail.text = ""
        textField.text = ""
        indexPath = IndexPath()
    }
    
    public func configure(title: String, value$: String?, detail: String, indexPath: IndexPath, delegate: DCFValuationHelper, valueFormat: ValuationCellValueFormat) {
        
        self.delegate = delegate
        self.indexPath = indexPath
        self.title.text = title
        self.textField.placeholder = value$
        self.valueFormat = valueFormat
        self.detail.text = detail
    }
    
    @IBAction func textEntryComplete(_ sender: UITextField) {
        
        delegate.userEnteredText(sender: sender, indexPath: indexPath)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if valueFormat == .percent {
            let numbers = textField.text?.filter("0123456789.".contains)
                if let value = (Double(numbers ?? "0")) {
                textField.text = percentFormatter.string(from: (value / 100.0) as NSNumber)
            }
        }
        
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction
    func textWasChanged() {
        
        if valueFormat == .currency {
            let numbers = textField.text?.filter("0123456789.".contains)
            guard let value = (Double(numbers ?? "0")) else { return }
            textField.text = currencyFormatterGapNoPence.string(from: value as NSNumber)
        }
        else if valueFormat == .numberNoDecimals {
            let numbers = textField.text?.filter("0123456789.".contains)
            guard let value = (Double(numbers ?? "0")) else { return }
            let value$ = numberFormatterNoFraction.string(from: value as NSNumber)
            textField.text = value$
        }
    }
}
