//
//  SharePurchaseDialog.swift
//  SharePurchaseDialog
//
//  Created by aDav on 17/09/2021.
//

import UIKit

class SharePurchaseDialog: UIViewController, UITextViewDelegate, UITextFieldDelegate {

    @IBOutlet var priceField: UITextField!
    @IBOutlet var dateField: UIDatePicker!
    @IBOutlet var diaryField: UITextView!
    @IBOutlet var numberField: UITextField!
    
    var share: Share!
    var needsSaving = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        priceField.text = currencyFormatterNoGapWithPence.string(from: share.lastLivePrice as NSNumber)
        dateField.contentHorizontalAlignment = .leading
        dateField.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        priceField.delegate = self
        diaryField.delegate = self
        numberField.delegate = self
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        if needsSaving {
            confirmAction()
        }
        
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        guard let text = textField.text else {
            return false
        }
        
        let numbers = text.filter("-0123456789.".contains)
        
        if textField.tag == 10 {
        
            textField.text = currencyFormatterNoGapWithPence.string(from: (Double(numbers) ?? 0.0) as NSNumber)
                   
            guard let price = Double(numbers) else {
                print("price: \(numbers)")
                return true
            }
            
            guard price > 0.0 else {
                return true
            }
            needsSaving = true
        }
        else {
            guard let count = Double(numbers) else {
                print("number: \(numbers)")
                return true
            }
            
            guard count > 0.0 else {
                return true
            }
            needsSaving = true

        }
        
        textField.resignFirstResponder()
        
        return true

    }
        
    @objc
    func endedTextEntry() {
                
        diaryField.resignFirstResponder()
    }
    
    func addDoneButtonToKeyboard (sender: UITextView) {
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(endedTextEntry))
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTextEntry))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let toolbar = UIToolbar()
        toolbar.frame.size.height = 44.0
        doneButton.width = view.frame.width * 1/3
        
        toolbar.items = [cancelButton,space,doneButton]
        
        sender.inputAccessoryView = toolbar
    }
    
    @objc
    func dateChanged() {
        needsSaving = true
    }
    
    @objc
    func cancelTextEntry() {
        
        diaryField.resignFirstResponder()
    }
    
    
    @IBAction func confirmAction() {

        if priceField.text != "" && numberField.text != "" {
            let newPurchase = SharePurchase.init(context: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)
            
            var numbers = priceField.text!.filter("-0123456789.".contains)
            guard let price = Double(numbers) else {
                return
            }
            
            numbers = numberField.text!.filter("-0123456789.".contains)
            guard let number = Double(numbers) else {
                return
            }
            
            guard price > 0 else { return }
            guard number > 0 else { return }
            
            newPurchase.price = price
            newPurchase.quantity = number
            newPurchase.date = dateField.date
            newPurchase.reason = diaryField.text
            
            newPurchase.save()
            needsSaving = false
            
            share.addToPurchase(newPurchase)
            share.watchStatus = 1
            share.save()
            print(share.purchase?.count)
            
            self.dismiss(animated: true, completion: nil)
        }

        
    }
    
    @IBAction func cancelAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
