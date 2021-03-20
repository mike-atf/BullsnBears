//
//  MACD_View.swift
//  Bulls'N'Bears
//
//  Created by aDav on 19/03/2021.
//

import UIKit

class MACD_View: UIView {

    var macdLine: [Double]?
    var signalLine: [Double]?
    var histo: [Double]?
    var histoMax: Double?
    var dateRange: [Date]?
    var mac_d: [MAC_D]!

    func configure(share: Share?) {
        
        guard let validShare = share else {
            return
        }
        
        guard let validMACDs = validShare.getMACDs() else { return }
        self.mac_d = validMACDs
        
        dateRange = validShare.priceDateRange()
        dateRange![1] = Date().addingTimeInterval(foreCastTime)

        macdLine = validMACDs.compactMap{ $0.mac_d }
        signalLine = validMACDs.compactMap{ $0.signalLine }
        histo = validMACDs.compactMap{ $0.histoBar }
        let lastquarterHistoCount = 3 * (histo?.count ?? 0) / 4
        histoMax = histo?[lastquarterHistoCount...].max()
        let histoMin = histo?[lastquarterHistoCount...].min() ?? 0
        if abs(histoMin) > histoMax ?? 0 {
            histoMax = abs(histoMin)
        }
        
    }

    override func draw(_ rect: CGRect) {
        
        guard dateRange != nil else {
            return
        }
        
        let leftBorder: CGFloat = 0.0
        let plotWidth = rect.width * 0.95
        let chartTimeSpan = dateRange!.last!.timeIntervalSince(dateRange!.first!)
        
// histogram
        let slotWidth = plotWidth / CGFloat(dateRange!.last!.timeIntervalSince(dateRange!.first!) / (24*3600)) // CGFloat(histo?.count ?? 1)
        let barWidth = slotWidth * 0.8
        let yScale = 0.9 * rect.height / (2 * CGFloat(histoMax ?? 1.0))
        
        var count: CGFloat = 0
        var previousBarHeight: CGFloat?
        var barColor = UIColor(named: "Green")
        
        for macd in mac_d ?? [] {
            let barLeft = leftBorder - (barWidth / 2) + CGFloat(macd.date!.timeIntervalSince(dateRange!.first!) / chartTimeSpan) * plotWidth
            let barHeight = yScale * CGFloat((macd.histoBar ?? 0))
            let barTop = barHeight < 0 ? rect.midY : rect.midY - barHeight
            let barRect = CGRect(x: barLeft, y: barTop, width: barWidth, height: abs(barHeight))
            let newBar = UIBezierPath(roundedRect: barRect, cornerRadius: 1.5)
            
            if barHeight < 0 {
                if -barRect.height < -(previousBarHeight ?? 0) {
                    barColor = UIColor(named: "Red")!
                }
                else {
                    barColor = UIColor(named: "Green")
                }
            }
            else {
                if barRect.height < previousBarHeight ?? 0 {
                    barColor = UIColor(named: "Red")!
                }
                else {
                    barColor = UIColor(named: "Green")
                }
            }
            
            barColor?.setFill()
            newBar.fill()
            
            previousBarHeight = barRect.height

            count += 1.0
        }
        
    }

}
