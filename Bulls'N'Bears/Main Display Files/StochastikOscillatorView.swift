//
//  StochastikOscillatorView.swift
//  Bulls'N'Bears
//
//  Created by aDav on 21/03/2021.
//

import UIKit

class StochastikOscillatorView: UIView {

    var ssO: [StochasticOscillator]?
    var dateRange: [Date]?

    func configure(share: Share?) {
        
        guard let validShare = share else {
            return
        }
        
        self.ssO = validShare.calculateSlowStochOscillators()
        dateRange = validShare.priceDateRange()
        dateRange![1] = Date().addingTimeInterval(foreCastTime)

        
    }

    override func draw(_ rect: CGRect) {
        
        let bottomMargin = rect.maxY - 5
        let topMargin: CGFloat = rect.minY + 5
        let plotheight = rect.height - 10

        let topBottomLines = UIBezierPath()
        topBottomLines.move(to: CGPoint(x: 0, y: topMargin + 0.2 * plotheight))
        topBottomLines.addLine(to: CGPoint(x: rect.maxX, y: topMargin + 0.2 * plotheight))
        
        topBottomLines.move(to: CGPoint(x: 0, y: bottomMargin - 0.2 * plotheight))
        topBottomLines.addLine(to: CGPoint(x: rect.maxX, y: bottomMargin - 0.2 * plotheight))
        
        UIColor.systemGray4.setStroke()
        topBottomLines.lineWidth = 2.0
        topBottomLines.stroke()

        let chartTimeSpan = dateRange!.last!.timeIntervalSince(dateRange!.first!)
        let plotWidth = rect.width * 0.95
        let slotWidth = plotWidth / CGFloat(dateRange!.last!.timeIntervalSince(dateRange!.first!) / (24*3600))

        var kLine: UIBezierPath?
        var dLine: UIBezierPath?
        
        for osc in ssO ?? [] {
            if let valid = osc.k_fast {
                kLine = UIBezierPath()
                let y = bottomMargin - CGFloat(valid / 100.0) * plotheight
                let x = slotWidth / 2 +  CGFloat(osc.date!.timeIntervalSince(dateRange!.first!) / chartTimeSpan) * plotWidth
                kLine?.move(to: CGPoint(x: x, y: y))
                break
            }
        }
        
        for osc in ssO ?? [] {
            if let valid = osc.d_slow {
                dLine = UIBezierPath()
                let y = bottomMargin - CGFloat(valid / 100.0) * plotheight
                let x = slotWidth / 2 +  CGFloat(osc.date!.timeIntervalSince(dateRange!.first!) / chartTimeSpan) * plotWidth
                dLine?.move(to: CGPoint(x: x, y: y))
                break
            }
        }

        
        ssO?.forEach({ (oscillator) in
            
            let x = slotWidth / 2 +  CGFloat(oscillator.date!.timeIntervalSince(dateRange!.first!) / chartTimeSpan) * plotWidth
            
            if let validK = oscillator.k_fast {
                let y = bottomMargin - plotheight * CGFloat(validK) / 100
                kLine?.addLine(to: CGPoint(x: x, y: y))
            }

            if let validD = oscillator.d_slow {
                let y = bottomMargin - plotheight * CGFloat(validD) / 100
                dLine?.addLine(to: CGPoint(x: x, y: y))
            }
            
        })
        
        UIColor(named: "Red")?.setStroke()
        dLine?.lineWidth = 1.5
        dLine?.stroke()
        
        UIColor.systemTeal.withAlphaComponent(0.75).setStroke()
        kLine?.lineWidth = 1.5
        kLine?.stroke()
    }

}
