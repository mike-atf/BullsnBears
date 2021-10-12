//
//  ChartTimeLineView.swift
//  Bulls'N'Bears
//
//  Created by aDav on 18/04/2021.
//

import UIKit

class ChartTimeLineView: UIView {
    
    var dateLabels = [UILabel]()
    var sma10Label: UILabel?
    var macdLabel: UILabel?
    var oscLabel: UILabel?
    
    var dateRange = [Date(), Date()]
    var stdLabelWidth: CGFloat!
    var timeIntervalBetweenLabels: TimeInterval!
    
    var sma10Crossing: LineCrossing?
    var macdCrossing: LineCrossing?
    var oscCrossing: LineCrossing?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.backgroundColor = UIColor.systemBackground
        
    }
    
    func configure(share: Share?) {
        
        guard let validShare = share else {
            return
        }

        dateRange = validShare.priceDateRangeWorkWeeksForCharts(withForecastTime: true)
        
        dateLabels = getDateLabels()
        
        if let crossings = share?.latest3Crossings() {
            sma10Crossing = crossings.filter({ (crossing) -> Bool in
                if crossing?.type == "sma10" { return true }
                else { return false }
            }).first as? LineCrossing
            
            macdCrossing = crossings.filter({ (crossing) -> Bool in
                if crossing?.type == "macd" { return true }
                else { return false }
            }).first as? LineCrossing
            
            oscCrossing = crossings.filter({ (crossing) -> Bool in
                if crossing?.type == "osc" { return true }
                else { return false }
            }).first as? LineCrossing

        }
        
        if let sma10Crossing_v = sma10Crossing {

            sma10Label?.removeFromSuperview()
            sma10Label = {
                let label = UILabel()
                label.translatesAutoresizingMaskIntoConstraints = false
                
                label.font = UIFont.systemFont(ofSize: 12)
                label.textAlignment = .right
                let text = sma10Crossing_v.signal < 0 ? " :Sell " : " :Buy "
                label.text = " " + dateFormatter.string(from: sma10Crossing_v.date) + text
                label.backgroundColor = sma10Crossing_v.signal < 0 ? UIColor(named: "Red") : UIColor(named: "DarkGreen")
                label.textColor = UIColor.white
                label.sizeToFit()
                self.addSubview(label)
                label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5).isActive = true
                return label
            }()
        }
        
        if let macdc_v = macdCrossing {
            macdLabel?.removeFromSuperview()
            macdLabel = {
                let label = UILabel()
                label.translatesAutoresizingMaskIntoConstraints = false
                
                label.font = UIFont.systemFont(ofSize: 12)
                label.textAlignment = .right
                let text = macdc_v.signal < 0 ? " :Sell " : " :Buy "
                label.text = " " + dateFormatter.string(from: macdc_v.date) + text
                label.backgroundColor = macdc_v.signal < 0 ? UIColor(named: "Red") : UIColor(named: "DarkGreen")
                label.textColor = UIColor.white
                label.sizeToFit()
                self.addSubview(label)
                label.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
                return label
            }()
        }
        
        if let osc_v = oscCrossing {
            oscLabel?.removeFromSuperview()
            oscLabel = {
                let label = UILabel()
                label.translatesAutoresizingMaskIntoConstraints = false
                
                label.font = UIFont.systemFont(ofSize: 12)
                label.textAlignment = .right
                let text = osc_v.signal < 0 ? " :Sell " : " :Buy "
                label.text = " " + dateFormatter.string(from: osc_v.date) + text
                label.backgroundColor = osc_v.signal < 0 ? UIColor(named: "Red") : UIColor(named: "DarkGreen")
                label.textColor = UIColor.white
                label.sizeToFit()
                self.addSubview(label)
                label.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
                return label
            }()

        }
    }

    private func getDateLabels() -> [UILabel] {
        
        let date$ = dateFormatter.string(from: Date())
        let stdLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.preferredFont(forTextStyle: .footnote)
            label.text = date$
            label.sizeToFit()
            return label
        }()
        let stdLabelWidth = stdLabel.bounds.width * 1.3
        
        var labels = [UILabel]()
        let maxLabelCount = Int(self.bounds.width / stdLabelWidth)
        let labelTimeIntervalOptions:[TimeInterval] = [24*3600, 7*24*3600,14*24*3600,28*24*3600,(365/12)*24*3600,(365/4*24*3600)]
        let totalChartTime = dateRange.last!.timeIntervalSince(dateRange.first!)
        
        var labelCount = 0
        
        for option in labelTimeIntervalOptions {
            if (totalChartTime / option) < Double(maxLabelCount) {
                timeIntervalBetweenLabels = option
                labelCount = Int(totalChartTime / option)
                break
            }
        }
        
        for i in 0..<labelCount {
            let aLabel: UILabel = {
                let label = UILabel()
                label.font = UIFont.preferredFont(forTextStyle: .footnote)
                // building backwards from latest date = dateRange.last
                let labelDate = dateRange.last!.addingTimeInterval(TimeInterval(-i) * timeIntervalBetweenLabels)
                label.text = dateFormatter.string(from: labelDate)
                label.sizeToFit()
                label.isHidden = true
                self.addSubview(label)
                return label
            }()
            labels.insert(aLabel, at: 0)
        }

        return labels
    }
    
    public func resetAfterZoom() {
        for label in dateLabels {
            label.removeFromSuperview()
        }
        dateLabels = getDateLabels()
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        
        let daysWidth = rect.width / CGFloat(dateRange.last!.timeIntervalSince(dateRange.first!) / (24*3600))
    
        let xAxis = UIBezierPath()
        xAxis.move(to: CGPoint(x: 0, y: rect.maxY-1))
        xAxis.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY-1))
        xAxis.move(to: CGPoint(x: 0, y: rect.minY+1))
        xAxis.addLine(to: CGPoint(x: rect.maxX, y: rect.minY+1))

        UIColor.systemGray3.setStroke()
        xAxis.lineWidth = 2
        xAxis.stroke()

        guard dateRange.first != nil && dateRange.last != nil else {
            return
        }
        
        let timeTicks = UIBezierPath()

        let totalChartTimeInterval = dateRange.last!.timeIntervalSince(dateRange.first!)
                
        var labelDate = dateRange.last!
        dateLabels.reversed().forEach { (label) in

            let labelMid = rect.maxX - rect.width * CGFloat(dateRange.last!.timeIntervalSince(labelDate) / totalChartTimeInterval)
            label.frame.origin = CGPoint(x: labelMid - (label.bounds.width / 2), y: rect.midY - label.frame.height / 2)
            labelDate = labelDate.addingTimeInterval(-timeIntervalBetweenLabels)
            label.isHidden = false
            
            timeTicks.move(to: CGPoint(x: labelMid, y: label.frame.maxY))
            timeTicks.addLine(to: CGPoint(x: labelMid, y: rect.maxY))
        }

        timeTicks.lineWidth = 2.0
        timeTicks.stroke()
        
        if let label = sma10Label {
            
            let x = rect.maxX - CGFloat((dateRange.last!.timeIntervalSince(sma10Crossing!.date) / totalChartTimeInterval)) * rect.width + daysWidth / 2
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: x).isActive = true
            
            let smaLine = UIBezierPath()
            smaLine.move(to: CGPoint(x: x, y: label.frame.minY))
            smaLine.addLine(to: CGPoint(x: x, y: rect.maxY))

            label.backgroundColor?.setStroke()
            smaLine.lineWidth = 1.1
            smaLine.stroke()
        }
        
        var macdLeadingConstraint: NSLayoutConstraint?
        var oscLeadingConstraint: NSLayoutConstraint?
        
        if let label = macdLabel {
            
            let x = rect.maxX - CGFloat((dateRange.last!.timeIntervalSince(macdCrossing!.date) / totalChartTimeInterval)) * rect.width
            macdLeadingConstraint = label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: x)
            macdLeadingConstraint?.isActive = true
            
            let mcdLine = UIBezierPath()
            mcdLine.move(to: CGPoint(x: x, y: rect.minY))
            mcdLine.addLine(to: CGPoint(x: x, y: label.frame.maxY))

            label.backgroundColor?.setStroke()
            mcdLine.lineWidth = 1.1
            mcdLine.stroke()

        }
        
        if let label = oscLabel {
            
            let x = rect.maxX - CGFloat((dateRange.last!.timeIntervalSince(oscCrossing!.date) / totalChartTimeInterval)) * rect.width
            oscLeadingConstraint = label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: x)
            
            if let macd = macdLabel {
                if label.frame.intersects(macd.frame) {
                    if oscCrossing!.date < macdCrossing!.date { // osc label left of macd label
                        oscLeadingConstraint = label.trailingAnchor.constraint(equalTo: leadingAnchor, constant: x)
                    }
                    else {
                        let macdX = macdLeadingConstraint?.constant
                        macdLeadingConstraint?.isActive = false
                        macdLeadingConstraint = macdLabel?.trailingAnchor.constraint(equalTo: leadingAnchor, constant: macdX!)
                        macdLeadingConstraint?.isActive = true
                    }
                }
            }
            oscLeadingConstraint?.isActive = true
            
            let oscLine = UIBezierPath()
            oscLine.move(to: CGPoint(x: x, y: rect.minY))
            oscLine.addLine(to: CGPoint(x: x, y: label.frame.maxY))

            label.backgroundColor?.setStroke()
            oscLine.lineWidth = 1.1
            oscLine.stroke()
        }
    }

}
