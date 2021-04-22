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
        
        guard let validMACD = validShare.latestMCDCrossing() else {
            return
        }
        guard let validSMA10 = validShare.latestSMA10Crossing() else {
            return
        }
        guard let validOSC = validShare.latestStochastikCrossing() else {
            return
        }
        
        let indicators = [validMACD, validOSC, validSMA10].sorted { (lc0, lc1) -> Bool in
            if lc0.date < lc1.date { return true }
            else { return false }
        }
        buySellText = indicators.last!.signal > 0 ? "Buy" : "Sell"

        let fontColor = indicators.last!.signal > 0 ? UIColor(named: "Green") : UIColor(named: "Red")
        let earlierSignalsSame = indicators[..<2].compactMap{ $0.signalIsBuy() }.filter { (buySignal) -> Bool in
            if buySignal == indicators.last!.signalIsBuy() { return true }
            else { return false }
        }
        
        readyText = earlierSignalsSame.count == 2 ? "Ready to" : "Wait to"
        
        if readyText.starts(with: "Ready") {
//            var price$ = String()
//            if let validPrice = indicators.last!.crossingPrice {
//                price$ = currencyFormatterNoGapWithPence.string(from: validPrice as NSNumber) ?? ""
//                buySellText += " @\n " + price$
//            }
            var date$ = String()
            if let validDate = indicators.last!.date {
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
