//
//  ChartLegendView.swift
//  Bulls'N'Bears
//
//  Created by aDav on 23/09/2021.
//

import UIKit

class ChartLegendView: UIView {
    
    @IBOutlet var ownedLabel: UILabel!
    
    var share: Share?
    var parentView: ChartContainerView!
    
    func configure(share: Share?, parent: ChartContainerView) {
        self.share = share
        self.parentView = parent
        
        if let quantity = share?.quantityOwned() {
            var price = String()
            if let p = share?.purchasePrice() {
                price = currencyFormatterNoGapWithPence.string(from: p as NSNumber) ?? ""
            }
            ownedLabel.text = "own \(quantity) @ " + price
            ownedLabel.sizeToFit()
            self.setNeedsDisplay()
        }
        else {
            ownedLabel.text = " "
        }
        
    }

//    @IBAction func infoButtonAction(_ sender: UIButton) {
//        parentView.dis
//    }
}
