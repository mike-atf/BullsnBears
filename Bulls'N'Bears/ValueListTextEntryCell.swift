//
//  ValueListTextEntryCell.swift
//  Bulls'N'Bears
//
//  Created by aDav on 02/03/2021.
//

import UIKit

protocol TextEntryCellDelegate {
    func userEnteredNotes(notes: String?, parameter: String)
}

class ValueListTextEntryCell: UITableViewCell  {

    @IBOutlet var textView: UITextView!
    
    var delegate: TextEntryCellDelegate?
    var wbvParameter: String!
    var originalNotes: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()

        textView.text = "Enter your notes here..."
        textView.delegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(text: String?, delegate: TextEntryCellDelegate, wbvParameter: String) {
        
        self.originalNotes = text
        self.textView.text = text ?? "Enter your notes here..."
        textView.textColor = (textView.text == "Enter your notes here...") ? UIColor.systemGray : UIColor.label
        self.delegate = delegate
        self.wbvParameter = wbvParameter
    }
    
}

extension ValueListTextEntryCell: UITextViewDelegate {
    
    
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
        delegate?.userEnteredNotes(notes: textView.text, parameter: wbvParameter)
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
        
        textView.text = originalNotes
        textView.resignFirstResponder()
    }

    
}
