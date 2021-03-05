//
//  TrendIconView.swift
//  Bulls'N'Bears
//
//  Created by aDav on 04/03/2021.
//

import UIKit

class TrendIconView: UIView {
    
    var correlation: Correlation?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.clear
    }
    
    func configure(correlation: Correlation) {

        self.correlation = correlation
        setNeedsDisplay()
    }


    override func draw(_ rect: CGRect) {
        
        guard let validCorrelation = correlation else {
            return
        }
        
        let baseLine = UIBezierPath()
        baseLine.move(to: CGPoint(x: rect.width * 0.1, y: rect.height * 0.9))
        baseLine.addLine(to: CGPoint(x: rect.width * 0.9, y: rect.height * 0.9))
        baseLine.lineWidth = 1.0
        UIColor.systemGray.setStroke()
        UIColor.systemGray.setFill()
        baseLine.stroke()
        
        guard let r2 = validCorrelation.r2() else { return }
        guard let trend = validCorrelation.meanGrowth() else { return }
        
        var barHeights = [CGFloat]()
        let plotHeight = rect.height * 0.85
        if trend > 0.15 {
            barHeights.append(plotHeight*0.15)
            barHeights.append(plotHeight*0.85)
        }
        else if trend > 0.1 {
            barHeights.append(plotHeight*0.3)
            barHeights.append(plotHeight*0.7)
        }
        else if trend > 0 {
            barHeights.append(plotHeight*0.45)
            barHeights.append(plotHeight*0.55)
        }
        else if trend > -0.1 {
            barHeights.append(plotHeight*0.55)
            barHeights.append(plotHeight*0.45)
        }
        else if trend > -0.15 {
            barHeights.append(plotHeight*0.7)
            barHeights.append(plotHeight*0.3)
        }
        else {
            barHeights.append(plotHeight*0.85)
            barHeights.append(plotHeight*0.15)
        }
        
        if r2 >= 0.64 {
            let height = (max(barHeights.last!,barHeights.first!) + min(barHeights.last!,barHeights.first!)) / 2
            barHeights.insert(height, at: 1)
        }
        else {
            let height: CGFloat = 0
            barHeights.insert(height, at: 1)
        }
        
        let bottom = rect.height * 0.85
        let slotwidth = rect.width * 0.8 / CGFloat(barHeights.count)
        var count: CGFloat = 0
        
        for barHeight in barHeights {
            let left = rect.width * 0.1 + slotwidth * count + slotwidth * 0.1
            let top = bottom - barHeight
            let columnRect = CGRect(x: left, y: top, width: slotwidth * 0.8, height: barHeight)
            let column = UIBezierPath(roundedRect: columnRect, cornerRadius: 0)
            column.fill()
            
            count +=  1
        }
        
    }

}
