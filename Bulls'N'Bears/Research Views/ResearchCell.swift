//
//  ResearchCell.swift
//  Bulls'N'Bears
//
//  Created by aDav on 29/03/2021.
//

import UIKit

protocol ResearchCellDelegate {
    func userEnteredNotes(notes: String, cellPath: IndexPath)
    func value(indexPath: IndexPath) -> String?
}


class ResearchCell: UITableViewCell {

    @IBOutlet var textView: UITextView!
    var cellDelegate: ResearchCellDelegate!
//    var researchParameter: String!
    var originalText: String?
    var indexPath: IndexPath!
    var textSaved = Bool()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        textView.delegate = self
        textView.backgroundColor = contentView.backgroundColor
    }
    
    override func prepareForReuse() {
        textView.text = " "
        textSaved = false
    }

    func configure(delegate: ResearchCellDelegate?, path: IndexPath) {
        
        self.cellDelegate = delegate
        self.indexPath = path
        
        textView.text = delegate?.value(indexPath: path)
        originalText = textView.text
    }
    
}

extension ResearchCell: UITextViewDelegate {
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        
        addDoneButtonToKeyboard(sender: textView)
        textSaved = false
        
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if !textSaved {
            textSaved = true
            if let validText = textView.text {
                cellDelegate?.userEnteredNotes(notes: validText, cellPath: indexPath)
            }
        }
    }

    @objc
    func endedTextEntry() {
        
        textView.resignFirstResponder()
        textSaved = true
        if let validText = textView.text {
            cellDelegate?.userEnteredNotes(notes: validText, cellPath: indexPath)
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

