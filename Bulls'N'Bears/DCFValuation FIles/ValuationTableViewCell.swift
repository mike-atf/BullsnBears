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
        
    var dcfDelegate: DCFValuationHelper?
    var r1Delegate: R1ValuationHelper?
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
    
    public func configure(title: String, value$: String?, detail: String, indexPath: IndexPath, dcfDelegate: DCFValuationHelper?, r1Delegate: R1ValuationHelper?, valueFormat: ValuationCellValueFormat, detailColor: UIColor? = UIColor.label) {
        
        self.dcfDelegate = dcfDelegate
        self.r1Delegate = r1Delegate
        self.indexPath = indexPath
        self.title.text = title
//        self.textField.placeholder = value$
        self.valueFormat = valueFormat
        self.detail.text = detail
        self.detail.textColor = detailColor
        let lighterPlaceHolderText = NSAttributedString(string: value$ ?? "",
                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        textField.attributedPlaceholder = lighterPlaceHolderText

    }
    
    @IBAction func textEntryComplete(_ sender: UITextField) {
        
        if let delegate = dcfDelegate {
            delegate.userEnteredText(sender: sender, indexPath: indexPath)
        }
        else {
            r1Delegate!.userEnteredText(sender: sender, indexPath: indexPath)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if valueFormat == .percent {
            let numbers = textField.text?.filter("0123456789.".contains)
                if let value = (Double(numbers ?? "0")) {
                textField.text = percentFormatter2Digits.string(from: (value / 100.0) as NSNumber)
            }
        }
        
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction
    func textWasChanged() {
        
        guard let validText = textField.text else {
            return
        }
        guard validText != "" else {
            return
        }
        
        if valueFormat == .currency {
            let numbers = validText.filter("0123456789.".contains)
            guard let value = (Double(numbers)) else { return }
            
//            var lastTwo = ""
//            if numbers?.count == 2 {
//                let index = (numbers ?? "").index((numbers ?? "").endIndex, offsetBy: -2)
//                lastTwo = String(numbers![index...])
//            }
            
            if (numbers.last == ".") {
                textField.text = "$ \(numbers)"
            }
            else
            if String(numbers.suffix(2)) == ".0" {
                textField.text = "$ \(numbers)"
            }
            else
            if dcfDelegate != nil {
                textField.text = currencyFormatterGapNoPence.string(from: value as NSNumber)
            }
            else {
                textField.text = "$ " + numberFormatterWithFraction.string(from: value as NSNumber)!
            }
        }
        else if valueFormat == .numberNoDecimals {
            let numbers = validText.filter("0123456789.".contains)
            guard let value = (Double(numbers)) else { return }
            let value$ = numberFormatterNoFraction.string(from: value as NSNumber)
            textField.text = value$
        }
    }
}
