//
//  PurchasedButton.swift
//  Bulls'N'Bears
//
//  Created by aDav on 08/10/2021.
//

import UIKit

protocol PurchasedButtonActivationDelegate {
    func buttonActivated(button: PurchasedButton)
}

class PurchasedButton: UIButton {
    
    var transaction: ShareTransaction!
    var relatedDiaryTransactionCard: DiaryTransactionCard?
    var displayDelegate: PurchasedButtonActivationDelegate?
    
    public func makeActiveButton() {
        relatedDiaryTransactionCard?.isActive = true
        displayDelegate?.buttonActivated(button: self)
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        
        guard let card = relatedDiaryTransactionCard else { return }
        
        if card.isActive {
            
            self.tintColor = UIColor.systemBlue
//            let rim = UIBezierPath(ovalIn: rect.insetBy(dx: 4, dy: 4))
//            rim.lineWidth = 4
//            UIColor.systemBlue.setStroke()
//            rim.stroke()
        }
    }

}
