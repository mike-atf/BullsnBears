//
//  MACD_View.swift
//  Bulls'N'Bears
//
//  Created by aDav on 19/03/2021.
//

import UIKit

class MACD_View: UIView {

    var macdLine: [Double]?
    var signals: [Double]?
    var histo: [Double]?
    var histoMax: Double?
    var macdMax: Double?
    var signalMax: Double?
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
        signals = validMACDs.compactMap{ $0.signalLine }
        histo = validMACDs.compactMap{ $0.histoBar }
        
        let lastquarterHistoCount = 3 * (histo?.count ?? 0) / 4
        
        histoMax = histo?[lastquarterHistoCount...].max()
        let histoMin = histo?[lastquarterHistoCount...].min() ?? 0
        if abs(histoMin) > histoMax ?? 0 {
            histoMax = abs(histoMin)
        }
        
        macdMax = macdLine?[lastquarterHistoCount...].max()
        let macdMin = macdLine?[lastquarterHistoCount...].min() ?? 0
        if abs(macdMin) > macdMax ?? 0 {
            macdMax = abs(macdMin)
        }
        
        signalMax = signals?[lastquarterHistoCount...].max()
        let signalMin = signals?[lastquarterHistoCount...].min() ?? 0
        if abs(histoMin) > signalMax ?? 0 {
            signalMax = abs(signalMin)
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
        let histo_yScale = 0.9 * rect.height / (2 * CGFloat(histoMax ?? 1.0))
        let macd_yScale = 0.9 * rect.height / (2 * CGFloat(macdMax ?? 1.0))
        let signal_yScale = 0.9 * rect.height / (2 * CGFloat(signalMax ?? 1.0))

        var count: CGFloat = 0
        var previousBarHeight: CGFloat?
        var barColor = UIColor(named: "Green")
        
        let macdLine = UIBezierPath()
        var firstMacd = Double()
        var firstDate = Date()
    
        var firstSignal = Double()
        var firstSignalDate = Date()

        
        for macd in mac_d ?? [] {
            if let valid = macd.mac_d {
                firstMacd = valid
                firstDate = macd.date ?? Date()
                break
            }
        }
        
        for macd in mac_d ?? [] {
            if let valid = macd.signalLine {
                firstSignal = valid
                firstSignalDate = macd.date ?? Date()
                break
            }
        }

        let x = slotWidth / 2 +  CGFloat(firstDate.timeIntervalSince(dateRange!.first!) / chartTimeSpan) * plotWidth
        let y = rect.midY - macd_yScale * CGFloat(firstMacd)
        macdLine.move(to: CGPoint(x: x, y: y))
        
        let signalLine = UIBezierPath()
        let s_x = slotWidth / 2 +  CGFloat(firstSignalDate.timeIntervalSince(dateRange!.first!) / chartTimeSpan) * plotWidth
        let s_y = rect.midY - macd_yScale * CGFloat(firstSignal)
        signalLine.move(to: CGPoint(x: s_x, y: s_y))
        
        for macd in mac_d ?? [] {
            // histogram
            let barLeft = leftBorder - (barWidth / 2) + CGFloat(macd.date!.timeIntervalSince(dateRange!.first!) / chartTimeSpan) * plotWidth
            let barHeight = histo_yScale * CGFloat((macd.histoBar ?? 0))
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
            
            // macdLine
            let x = slotWidth / 2 +  CGFloat(macd.date!.timeIntervalSince(dateRange!.first!) / chartTimeSpan) * plotWidth
            let y = rect.midY - macd_yScale * CGFloat(macd.mac_d!)
            macdLine.addLine(to: CGPoint(x: x, y: y))

            // signalLine
            if let signal = macd.signalLine {
                let x = slotWidth / 2 +  CGFloat(macd.date!.timeIntervalSince(dateRange!.first!) / chartTimeSpan) * plotWidth
                let y = rect.midY - macd_yScale * CGFloat(signal)
                signalLine.addLine(to: CGPoint(x: x, y: y))
            }
            count += 1.0
        }
        
        UIColor.systemBlue.setStroke()
        macdLine.lineWidth = 1.2
        macdLine.stroke()
        
        UIColor.systemYellow.setStroke()
        signalLine.lineWidth = 1.2
        signalLine.stroke()
        
        
        let bottomLine = UIBezierPath()
        bottomLine.move(to: CGPoint(x: 0, y: rect.maxY - 2))
        bottomLine.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 2))
        UIColor.systemGray3.setStroke()
        bottomLine.lineWidth = 1
        bottomLine.stroke()

    }

}
