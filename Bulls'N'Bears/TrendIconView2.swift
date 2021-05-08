//
//  TrendIconView2.swift
//  Bulls'N'Bears
//
//  Created by aDav on 06/05/2021.
//

import UIKit

class TrendIconView2: UIView {

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
    
    /// expects wbParameters in time-DESCENDING order
    func configure(correlation: Correlation?, wbParameters: [Double]?) {
        
        self.correlation = correlation
        self.chartValues = wbParameters

        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        
        guard let validCorrelation = correlation else {
            return
        }
        
        guard let latestValue = chartValues?.first else {
            return
        }

        guard chartValues?.count ?? 0 > 3 else {
            return
        }
        
        // MARK: - baseline
        var baselineY = latestValue < 0 ? rect.height * 0.1 : rect.height * 0.9
//        let previous4Values = chartValues![0...3]
        let valuesProduct = chartValues!.reduce(1,*) //previous4Values
        let valuesSum = chartValues!.reduce(0,+) // previous4Values
        if valuesProduct < 0 {
            // positive and negative values exist
            baselineY = rect.midY
        }
               
        let baseLine = UIBezierPath()
        baseLine.move(to: CGPoint(x: rect.width * 0.1, y: baselineY))
        baseLine.addLine(to: CGPoint(x: rect.width * 0.9, y: baselineY))
        baseLine.lineWidth = 1.0
        UIColor.systemGray.setStroke()
        UIColor.systemGray.setFill()
        baseLine.stroke()
        
        guard let r2 = validCorrelation.r2() else { return }
        let trend = validCorrelation.incline // meanGrowth()

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

        var barTops = [CGFloat]()
        if valuesProduct < 0 {
            // positive and negative values exist
            if r2 >= 0.64 {
                barTops.append(baselineY)
                barTops.append(baselineY)
                for i in 2..<barHeights.count {
                    barTops.append(baselineY - barHeights[i])
                }
            }
            else {
                for i in 0..<2 {
                    barTops.append(baselineY - barHeights[i])
                }
                barTops.append(baselineY)
                barTops.append(baselineY)
            }
        }
        else if valuesSum < 0 {
            // all negative values
            for _ in barHeights {
                barTops.append(baselineY)
            }
        }
        else {
            // all positive or 0 values
            for height in barHeights {
                barTops.append(baselineY - height)
            }
        }

        let slotwidth = rect.width * 0.8 / CGFloat(barHeights.count)
        var count = 0
        
        for barHeight in barHeights {
            let left = rect.width * 0.1 + slotwidth * CGFloat(count) + slotwidth * 0.1
            let columnRect = CGRect(x: left, y: barTops[count], width: slotwidth * 0.8, height: barHeight)
            let column = UIBezierPath(roundedRect: columnRect, cornerRadius: 0)
            column.fill()
            
            count +=  1
        }

    }

}
