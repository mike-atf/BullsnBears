//
//  DiaryTransactionCard.swift
//  Bulls'N'Bears
//
//  Created by aDav on 12/10/2021.
//

import UIKit

protocol CardActivatedByButtonDelegate {
    func hasBeenActivated(transactionCard: DiaryTransactionCard)
}

class DiaryTransactionCard: UIView {

    @IBOutlet var title: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var priceLabel: UILabel!
    @IBOutlet var quantityLabel: UILabel!
    @IBOutlet var reason: UITextView!
    @IBOutlet var lessonLearnt: UITextView!
    @IBOutlet var reasonTitle: UILabel!
    
    var transaction: ShareTransaction!
    var tempText: String?
    var isActive: Bool = false
    var relatedChartButton: PurchasedButton?
    var buttonActivationDelegate: CardActivatedByButtonDelegate?
    var positionInArray: Int!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    class func instanceFromNib() -> DiaryTransactionCard {
        return UINib(nibName: "DiaryTransactionCard", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! DiaryTransactionCard
    }

    
    public func configure(transaction: ShareTransaction, buttonActivationDelegate: CardActivatedByButtonDelegate) {
        
        title.text = transaction.isSale ? "Sale" : "Purchase"
        reasonTitle.text = transaction.isSale ? "Why did you sell?" : "Why did you buy?"
        dateLabel.text = dateFormatter.string(from: transaction.date!)
        priceLabel.text = currencyFormatterNoGapWithPence.string(from: transaction.price as NSNumber)
        quantityLabel.text = numberFormatterWith1Digit.string(from: transaction.quantity as NSNumber)
        
        reason.text = transaction.reason
        lessonLearnt.text = transaction.lessonsLearnt
        
        reason.delegate = self
        lessonLearnt.delegate = self
        
        self.transaction = transaction
        self.buttonActivationDelegate = buttonActivationDelegate
        
    }
    
    @objc
    func endedTextEntry() {
                
        if reason.isFirstResponder {
            reason.resignFirstResponder()
        } else if lessonLearnt.isFirstResponder {
            lessonLearnt.resignFirstResponder()
        }
        
    }
    
    @objc
    func cancelTextEntry() {
        
        if reason.isFirstResponder {
            reason.text = tempText
            reason.resignFirstResponder()
        } else if lessonLearnt.isFirstResponder {
            lessonLearnt.text = tempText
            lessonLearnt.resignFirstResponder()
        }
    }

    func addDoneButtonToKeyboard (sender: UITextView) {
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(endedTextEntry))
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTextEntry))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let toolbar = UIToolbar()
        toolbar.frame.size.height = 44.0
        doneButton.width = self.frame.width * 1/3
        
        toolbar.items = [cancelButton,space,doneButton]
        
        sender.inputAccessoryView = toolbar
    }
    
    public func activatedByButton() {
        isActive = true
        relatedChartButton?.setNeedsDisplay()
        buttonActivationDelegate?.hasBeenActivated(transactionCard: self)
    }

    override func draw(_ rect: CGRect) {
        
        guard isActive else { return }
        
        let frame = rect.insetBy(dx: 5, dy: 5)
        let glowFrame = UIBezierPath(roundedRect: frame, cornerRadius: 5)
        glowFrame.lineWidth = 5
        
        UIColor.tintColor.setStroke()
        glowFrame.stroke()
        
    }

}

extension DiaryTransactionCard: UITextViewDelegate {
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        if textView .isEqual(reason) {
            transaction.reason = textView.text
        } else {
            transaction.lessonsLearnt = textView.text
        }
        
        transaction.save()
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        
        tempText = textView.text
        addDoneButtonToKeyboard(sender: textView)
        return true
    }

    
}
