//
//  SharePurchaseDialog.swift
//  SharePurchaseDialog
//
//  Created by aDav on 17/09/2021.
//

import UIKit

class ShareTransactionDialog: UIViewController, UITextViewDelegate, UITextFieldDelegate {

    @IBOutlet var priceField: UITextField!
    @IBOutlet var dateField: UIDatePicker!
    @IBOutlet var diaryField: UITextView!
    @IBOutlet var numberField: UITextField!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var buyButton: UIButton!
    @IBOutlet var sellButton: UIButton!
    
    @IBOutlet var taTypeLabel: UILabel!
    @IBOutlet var taQuantityLabel: UILabel!
    @IBOutlet var taReasonsLabel: UILabel!
    
    var share: Share? // if called for new purchase
    var transaction: ShareTransaction? // if called to edit or delete purchase
    var presentingVC: StockChartVC!
    
    var needsSaving = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        if let validShare = share {
            priceField.text = currencyFormatterNoGapWithPence.string(from: validShare.lastLivePrice as NSNumber)
        }
        
        dateField.contentHorizontalAlignment = .leading
        dateField.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        priceField.delegate = self
        diaryField.delegate = self
        numberField.delegate = self
        
    }
    
    func existingPurchase(transaction: ShareTransaction) {
        
        taTypeLabel.text = transaction.isSale ? "Sale price" : "Purchase price"
        taQuantityLabel.text = transaction.isSale ? "Quantity sold" : "Quantity purchased"
        taReasonsLabel.text = transaction.isSale ? "Why did you sell?" : "Why did you purchase?"
        
        self.transaction = transaction
        priceField.text = currencyFormatterNoGapWithPence.string(from: transaction.price as NSNumber)
        numberField.text = numberFormatterDecimals.string(from: transaction.quantity as NSNumber)
        dateField.date = transaction.date ?? Date()
        diaryField.text = transaction.reason
    }
    
    func setCancelButtonToDelete() {
        
        if transaction != nil {
            cancelButton.setTitle("Delete", for: .normal)
            cancelButton.tintColor = UIColor.systemRed
            
            buyButton.setTitle("Confirm", for: .normal)
            buyButton.tintColor = UIColor.systemBlue
            
            sellButton.isHidden = true
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        guard let text = textField.text else {
            return false
        }
        
        let numbers = text.filter("0123456789.".contains)
        
        if textField.tag == 10 {
        
            textField.text = currencyFormatterNoGapWithPence.string(from: (Double(numbers) ?? 0.0) as NSNumber)
                   
            guard let price = Double(numbers) else {
                return true
            }
            
            guard price > 0.0 else {
                return true
            }
            needsSaving = true
        }
        else {
            guard let count = Double(numbers) else {
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
    
    
    @IBAction func buyAction() {

        if priceField.text != "" && numberField.text != "" {
            
            var purchaseToSave: ShareTransaction!
            if let _ = share {
            
                purchaseToSave = ShareTransaction.init(context: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)
                purchaseToSave.isSale = false
            }
            else if let validPurchase = transaction {
                purchaseToSave = validPurchase
            }
                
            var numbers = priceField.text!.filter("0123456789.".contains)
            guard let price = Double(numbers) else {
                return
            }
            
            numbers = numberField.text!.filter("0123456789.".contains)
            guard let number = Double(numbers) else {
                return
            }
            
            guard price > 0 else { return }
            guard number > 0 else { return }
            
            
            if let wbv = share?.wbValuation {
                var pe$ = "PE: "
                var minMaxValue$ = ""
                if let hxPER = wbv.historicPEratio(for: dateField.date) {
                    pe$ += numberFormatterDecimals.string(from: hxPER as NSNumber) ?? "-"
                }
                let sixMonthsAgo = dateField.date.addingTimeInterval(-183*24*3600)
                let twoYearsAgo = sixMonthsAgo.addingTimeInterval(-365*24*3600)
                if let (min, _, max) = wbv.minMeanMaxPER(from: twoYearsAgo, to: sixMonthsAgo) {
                    minMaxValue$ = " (" + numberFormatterNoFraction.string(from: min as NSNumber)! + " - " + numberFormatterNoFraction.string(from: max as NSNumber)! + ")"
                }
                diaryField.text = diaryField.text + "\n" + pe$ + minMaxValue$
            }
            
            purchaseToSave.price = price
            purchaseToSave.quantity = number
            purchaseToSave.date = dateField.date
            purchaseToSave.reason = diaryField.text
            
            purchaseToSave.save()
            needsSaving = false
        
            share?.addToTransactions(purchaseToSave)
            share?.watchStatus = 1
            share?.save()

            if let validShare = share {
                presentingVC.chart.chartView.configure(stock: validShare)
            }
            presentingVC.chart.chartLegendView.configure(share: purchaseToSave.share, parent: presentingVC.chart)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    
    @IBAction func sellAction(_ sender: UIButton) {
        
        if priceField.text != "" && numberField.text != "" {
            
            var saleToSave: ShareTransaction!
            if let _ = share {
            
                saleToSave = ShareTransaction.init(context: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)
                saleToSave.isSale = true
            }
            else if let validSale = transaction {
                saleToSave = validSale
            }
                
            var numbers = priceField.text!.filter("0123456789.".contains)
            guard let price = Double(numbers) else {
                return
            }
            
            numbers = numberField.text!.filter("0123456789.".contains)
            guard let number = Double(numbers) else {
                return
            }
            
            guard price > 0 else { return }
            guard number > 0 else { return }
            
            
            if let wbv = share?.wbValuation {
                var pe$ = "PE: "
                var minMaxValue$ = ""
                if let hxPER = wbv.historicPEratio(for: dateField.date) {
                    pe$ += numberFormatterDecimals.string(from: hxPER as NSNumber) ?? "-"
                }
                let sixMonthsAgo = dateField.date.addingTimeInterval(-183*24*3600)
                let twoYearsAgo = sixMonthsAgo.addingTimeInterval(-365*24*3600)
                if let (min, _, max) = wbv.minMeanMaxPER(from: twoYearsAgo, to: sixMonthsAgo) {
                    minMaxValue$ = " (" + numberFormatterNoFraction.string(from: min as NSNumber)! + " - " + numberFormatterNoFraction.string(from: max as NSNumber)! + ")"
                }
                diaryField.text = diaryField.text + "\n" + pe$ + minMaxValue$
            }
            
            saleToSave.price = price
            saleToSave.quantity = number
            saleToSave.date = dateField.date
            saleToSave.reason = diaryField.text
            
            saleToSave.save()
            needsSaving = false
        
            share?.addToTransactions(saleToSave)
            share?.watchStatus = 1
            share?.save()

            if let validShare = share {
                presentingVC.chart.chartView.configure(stock: validShare)
            }
            presentingVC.chart.chartLegendView.configure(share: saleToSave.share, parent: presentingVC.chart)
            self.dismiss(animated: true, completion: nil)
        }

    }
    
    @IBAction func cancelAction(_ sender: UIButton) {
        
        if let validTransaction = transaction {
            
            // delete action
            let share = validTransaction.share
            transaction?.delete()
            presentingVC.chart.chartLegendView.configure(share: transaction?.share, parent: presentingVC.chart)
            if share != nil {
                presentingVC.chart.chartView.configure(stock: share!)
            }
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
}
