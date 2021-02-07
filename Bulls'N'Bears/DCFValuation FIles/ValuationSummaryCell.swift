//
//  ValuationSummaryCell.swift
//  Bulls'N'Bears
//
//  Created by aDav on 02/02/2021.
//

import UIKit

protocol ValSummaryCellDelegate {
    func valueWasChanged(futurePER: Double?, futureGrowth: Double?)
}

class ValuationSummaryCell: UITableViewCell, UITextFieldDelegate {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var textField: UITextField!
    
    var indexPath: IndexPath!
    var cellDelegate: ValSummaryCellDelegate?
    var valueFormat: ValuationCellValueFormat!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textField.delegate = self
    }
    
    override func prepareForReuse() {
        titleLabel.text = ""
        textField.text = ""
        textField.placeholder = ""
        indexPath = IndexPath()
        textField.isEnabled = true
        cellDelegate = nil
    }
    
    deinit {
        cellDelegate = nil
    }
    
    public func configure(title: String, value: Double?, format: ValuationCellValueFormat,indexPath: IndexPath, delegate: ValSummaryCellDelegate) {
        
        self.indexPath = indexPath
        self.titleLabel.text = title
        self.cellDelegate = delegate
        self.valueFormat = format
        
        if let valid = value {
            if format == .percent {
                self.textField.placeholder = percentFormatter0Digits.string(from: valid as NSNumber)
                self.textField.text = percentFormatter0Digits.string(from: valid as NSNumber)
            } else if format == .currency {
                self.textField.placeholder = currencyFormatterGapWithPence.string(from: valid as NSNumber)
//                self.textField.text = currencyFormatterGapWithPence.string(from: valid as NSNumber)
            } else {
                self.textField.placeholder = numberFormatterWith1Digit.string(from: valid as NSNumber)
                self.textField.text = numberFormatterWith1Digit.string(from: valid as NSNumber)
            }
        }
        else {
            self.textField.placeholder = "enter your estimate"
        }
        
        if indexPath == IndexPath(row: 0, section: 1) {
            textField.isEnabled = false
        }
        else {
            textField.isEnabled = true
        }
    }
    
    @IBAction func textEntryComplete(_ sender: UITextField) {
        
        let newValueS = textField.text?.filter("-0123456789.".contains) ?? ""
        
        guard let newValue = Double(newValueS) else { return }
        
        var value = newValue
        if valueFormat == .percent {
            value = newValue / 100.0
        }
        
        if indexPath.row == 0 {
            cellDelegate?.valueWasChanged(futurePER: nil, futureGrowth: value)
        }
        else {
            cellDelegate?.valueWasChanged(futurePER: value, futureGrowth: nil)
        }
            
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if valueFormat == .percent {
            let numbers = textField.text?.filter("-0123456789.".contains)
                if let value = (Double(numbers ?? "0")) {
                textField.text = percentFormatter0Digits.string(from: (value / 100.0) as NSNumber)
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
            let numbers = validText.filter("-0123456789.".contains)
            guard let value = (Double(numbers)) else { return }
            
            if (numbers.last == ".") {
                textField.text = "$ \(numbers)"
            }
            else
            if String(numbers.suffix(2)) == ".0" {
                textField.text = "$ \(numbers)"
            }
            else {
                textField.text = "$ " + numberFormatterDecimals.string(from: value as NSNumber)!
            }
        }
        else
        if valueFormat == .numberNoDecimals {
            let numbers = validText.filter("-0123456789.".contains)
            guard let value = (Double(numbers)) else { return }
            let value$ = numberFormatterNoFraction.string(from: value as NSNumber)
            textField.text = value$
        }
        if valueFormat == .numberWithDecimals {
            let numbers = validText.filter("-0123456789.".contains)
            guard let value = (Double(numbers)) else { return }
            
            if (numbers.last == ".") {
                textField.text = "\(numbers)"
            }
            else
            if String(numbers.suffix(2)) == ".0" {
                textField.text = "\(numbers)"
            }
            else {
                textField.text = numberFormatterDecimals.string(from: value as NSNumber)!
            }
        }
    }

}
