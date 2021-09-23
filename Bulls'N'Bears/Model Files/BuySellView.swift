//
//  BuySellView.swift
//  Bulls'N'Bears
//
//  Created by aDav on 24/03/2021.
//

import UIKit

class BuySellView: UIView {
    
    var readyText = String()
    var buySellText = String()
    var transactionLabel: UILabel?
    var readinessLabel: UILabel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        transactionLabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = UIFont.systemFont(ofSize: 14)
            label.textAlignment = .center
            label.numberOfLines = 0
            return label
        }()
        
        
        readinessLabel = {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 13)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            return label
        }()

        addSubview(transactionLabel!)
        addSubview(readinessLabel!)
        
        readinessLabel?.topAnchor.constraint(equalTo: topAnchor).isActive = true
        readinessLabel?.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
        transactionLabel?.topAnchor.constraint(equalTo: readinessLabel!.bottomAnchor).isActive = true
        transactionLabel?.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
    }
    
    func resetForReuse() {
        readyText = String()
        buySellText = String()

    }
    
    func configure(share: Share?) {
        
        guard let validShare = share else {
            transactionLabel?.text = " "
            readinessLabel?.text = " "
            return
        }

        guard let latest3Crossings = validShare.latest3Crossings() else {
            return
        }
        
        var lastCrossing: LineCrossing
        var has3Signals = false
        if latest3Crossings[2] == nil {
            if latest3Crossings[1] == nil {
                lastCrossing = latest3Crossings.first!!
            }
            else {
                lastCrossing = latest3Crossings[1]!
            }
        }
        else {
            lastCrossing = latest3Crossings.last!!
            has3Signals = true
        }

        buySellText = lastCrossing.signal > 0 ? "Buy" : "Sell"

        buySellText = lastCrossing.signal > 0 ? "Buy" : "Sell"

        let fontColor = lastCrossing.signal > 0 ? UIColor(named: "Green") : UIColor(named: "Red")
        var earlierSignalsSame = [Bool]()
        if has3Signals {
            earlierSignalsSame = latest3Crossings[..<2].compactMap{ $0!.signalIsBuy() }.filter { (buySignal) -> Bool in
                if buySignal == lastCrossing.signalIsBuy() { return true }
                else { return false }
            }
        }

        readyText = earlierSignalsSame.count == 2 ? "Ready to" : "Wait to"

        if readyText.starts(with: "Ready") {
            var date$ = String()
            if let validDate = lastCrossing.date {
                date$ = dateFormatter.string(from: validDate)
                buySellText += "\n" + date$
            }
        }

        readinessLabel?.text = readyText
        transactionLabel?.text = buySellText

        readinessLabel?.textColor = fontColor
        transactionLabel?.textColor = fontColor

        setNeedsDisplay()

    }
    
}
