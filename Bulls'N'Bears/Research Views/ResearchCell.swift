//
//  ResearchCell.swift
//  Bulls'N'Bears
//
//  Created by aDav on 29/03/2021.
//

import UIKit

protocol ResearchCellDelegate {
    func userEnteredNotes(notes: String, parameter: String)
}


class ResearchCell: UITableViewCell {

    @IBOutlet var textView: UITextView!
    var cellDelegate: ResearchCellDelegate!
    var researchParameter: String!
    var originalText: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        textView.text = " "
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(delegate: ResearchCellDelegate, parameter: String) {
        self.cellDelegate = delegate
        self.researchParameter = parameter
        originalText = textView.text
    }
    
}

extension ResearchCell: UITextViewDelegate {
    
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        
        addDoneButtonToKeyboard(sender: textView)

        if textView.text == "Enter your notes here..." {
            textView.text = ""
            textView.textColor = UIColor.label
        }
        
        return true
    }

    @objc
    func endedTextEntry() {
        
        textView.resignFirstResponder()
        if let validText = textView.text {
            cellDelegate?.userEnteredNotes(notes: validText, parameter: researchParameter)
        }
    }
    
    func addDoneButtonToKeyboard (sender: UITextView) {
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(endedTextEntry))
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTextEntry))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let toolbar = UIToolbar()
        toolbar.frame.size.height = 44.0
        doneButton.width = contentView.frame.width * 1/3
        
        toolbar.items = [cancelButton,space,doneButton]
        
        sender.inputAccessoryView = toolbar
    }
    
    @objc
    func cancelTextEntry() {
        
        textView.text = originalText
        textView.resignFirstResponder()
    }

    
}

