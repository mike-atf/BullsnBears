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
    
    func configure(share: Share?) {
        self.share = share
        
        if let quantity = share?.quantityOwned() {
            var price = String()
            if let p = share?.purchasePrice() {
                price = currencyFormatterNoGapWithPence.string(from: p as NSNumber) ?? ""
            }
            ownedLabel.text = "own: \(quantity) @ " + price
            ownedLabel.sizeToFit()
            self.setNeedsDisplay()
        }
        else {
            ownedLabel.text = " "
        }
        
    }

}
