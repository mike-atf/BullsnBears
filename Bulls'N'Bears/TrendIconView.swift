//
//  TrendIconView.swift
//  Bulls'N'Bears
//
//  Created by aDav on 04/03/2021.
//

import UIKit

class TrendIconView: UIView {
    
    var correlation: Correlation?
    var chartValues: [Double]?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.clear
    }
    
    func configure(correlation: Correlation, values: [Double]?) {

        self.correlation = correlation
        self.chartValues = values
        setNeedsDisplay()
    }


    override func draw(_ rect: CGRect) {
        
        guard let validCorrelation = correlation else {
            return
        }
        
        var baselineY = rect.height * 0.9
        
//        if (chartValues ?? []).count > 0 {
//
//            let max = chartValues!.max()!
//            let min = chartValues!.min()!
//            if max * min < 0 {
//                // part of the values are < 0, others >0
//                baselineY = rect.height * 0.5
//            }
//            else if max < 0 && min < 0 {
//                baselineY  = rect.height * 0.1
//            }
//        }
        
        let baseLine = UIBezierPath()
        baseLine.move(to: CGPoint(x: rect.width * 0.1, y: baselineY))
        baseLine.addLine(to: CGPoint(x: rect.width * 0.9, y: baselineY))
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
            let heightDifference = (barHeights[1] - barHeights[0]) / 3
            barHeights.insert(barHeights[0] + heightDifference, at: 1)
            barHeights.insert(barHeights[1] + heightDifference, at: 2)
        }
        else {
            let heightDifference = (barHeights[1] - barHeights[0])
            barHeights.insert(barHeights[0] + heightDifference * 0.7, at: 1)
            barHeights.insert(barHeights[0] - heightDifference * 0.15, at: 2)
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
