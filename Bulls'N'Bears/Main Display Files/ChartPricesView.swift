//
//  ChartPricesView.swift
//  Bulls'N'Bears
//
//  Created by aDav on 18/04/2021.
//

import UIKit

class ChartPricesView: UIView {
    
    var lowestPriceInRange: Double?
    var highestPriceInRange: Double?
    
    var minPrice: Double!
    var maxPrice: Double!
    
    var priceLabels = [UILabel]()
    var buySellPriceLabel: UILabel?
    var buySellPrice: Double?
    
    var currentPriceLabel: UILabel?
    var currentPrice: Double?

    
    var yAxisNumbers = [Double]()
    
    var labelVerticalConstraints = [NSLayoutConstraint]()
    var topMargin: CGFloat = 0
    var verticalHeightFactor: CGFloat = 1.0
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.backgroundColor = UIColor.systemBackground
        
    }

    
    func configure(share: Share?, topMargin: CGFloat? = 0, verticalHeightFactor: CGFloat? = 1.0) {
        
        guard let validShare = share else { return }

        lowestPriceInRange = validShare.lowestPrice()
        highestPriceInRange = validShare.highestPrice()
        
        guard lowestPriceInRange != nil else { return }
        guard highestPriceInRange != nil else { return }
        
        // these need to match between ChartView and PricerChartView otherwise priceLabels dont match candleStick chart
        self.topMargin = topMargin ?? 0.0
        self.verticalHeightFactor = verticalHeightFactor ?? 1.0
        
        minPrice = (lowestPriceInRange! * 0.9).rounded()
        maxPrice = (highestPriceInRange! * 1.1).rounded() + 1
        
        if let validPrice = share?.latestPrice(option: .close) {
            currentPrice = validPrice
            
            currentPriceLabel = {
                let label = UILabel()
                label.font = UIFont.preferredFont(forTextStyle: .footnote)
                label.textColor = UIColor(named: "antiLabel")!
                label.textAlignment = .right
                label.text = " " + currencyFormatterNoGapWithPence.string(from: NSNumber(value: validPrice))! + " "
                label.sizeToFit()
                label.backgroundColor = UIColor.label
                label.isHidden = true
                self.addSubview(label)
                return label
            }()

        }

        let step = findYAxisValues(min: minPrice, max: maxPrice)

        var labelPrice = Double(Int(maxPrice / step)) * step
        while labelPrice >= minPrice {
            let newLabel: UILabel = {
                let label = UILabel()

                label.font = UIFont.preferredFont(forTextStyle: .footnote)
                label.textAlignment = .right
                label.text = currencyFormatterNoGapWithPence.string(from: NSNumber(value: labelPrice))
                label.sizeToFit()
                label.isHidden = true
                self.addSubview(label)
                return label
            }()
            priceLabels.append(newLabel)
            yAxisNumbers.append(labelPrice)
            labelPrice -= step
        }
        
        if let validMACD = validShare.latestMCDCrossing() {
            if let validSMA10 = validShare.latestSMA10Crossing() {
                if let validOSC = validShare.latestStochastikCrossing() {
                    
                    let indicators = [validMACD, validOSC, validSMA10].sorted { (lc0, lc1) -> Bool in
                        if lc0.date < lc1.date { return true }
                        else { return false }
                    }

                    let labelColor = indicators.last!.signal > 0 ? UIColor(named: "Green") : UIColor(named: "Red")
                    let earlierSignalsSame = indicators[..<2].compactMap{ $0.signalIsBuy() }.filter { (buySignal) -> Bool in
                        if buySignal == indicators.last!.signalIsBuy() { return true }
                        else { return false }
                    }
                    
                    if earlierSignalsSame.count == 2 {
                        var price$ = String()
                        if let validPrice = indicators.last!.crossingPrice {
                            buySellPrice = validPrice
                            price$ = currencyFormatterNoGapWithPence.string(from: buySellPrice! as NSNumber) ?? ""
                            
                            buySellPriceLabel = {
                                let label = UILabel()
                                label.font = UIFont.preferredFont(forTextStyle: .footnote)
                                label.textAlignment = .right
                                label.text = " " + price$ + " "
                                label.sizeToFit()
                                label.backgroundColor = labelColor
                                label.isHidden = true
                                self.addSubview(label)
                                return label
                            }()
                        }
                    }
                    else {
                        buySellPriceLabel?.removeFromSuperview()
                        buySellPrice = nil
                    }

                }
            }
        }


        setNeedsDisplay()

    }
    
    private func findYAxisValues(min: Double, max: Double) -> Double {
        
        let options = [2.0,2.5,5.0,10.0,20.0,25.0,50.0,100.0,150.0,200.0,250.0,500.0]
        let range = max - min
        
        var count = 100.0
        var index = -1
        repeat {
            index += 1
            count = range / options[index]
        } while count > 11.0
        
        return options[index]
    }

    override func draw(_ rect: CGRect) {
               
        let yAxis = UIBezierPath()
        yAxis.move(to: CGPoint(x: 1, y:0))
        yAxis.addLine(to: CGPoint(x: 1, y: rect.maxY))
        yAxis.lineWidth = 2
        UIColor.systemGray.setStroke()
        yAxis.stroke()
        
        
        if let validLabel = buySellPriceLabel {
            let labelY: CGFloat = self.topMargin + self.verticalHeightFactor * rect.height * CGFloat((maxPrice - buySellPrice!) / (maxPrice - minPrice))
            validLabel.frame.origin = CGPoint(x: rect.maxX - 5 - validLabel.frame.width, y: labelY - validLabel.frame.height / 2)
            validLabel.isHidden = false
            
            let labelLine = UIBezierPath()
            labelLine.move(to: CGPoint(x: validLabel.frame.minX, y:validLabel.frame.midY))
            labelLine.addLine(to: CGPoint(x: rect.minX, y: validLabel.frame.midY))
            labelLine.lineWidth = 1.1
            validLabel.backgroundColor?.setStroke()
            labelLine.stroke()
        }
        
        if let validLabel = currentPriceLabel {
            let labelY: CGFloat = self.topMargin + self.verticalHeightFactor * rect.height * CGFloat((maxPrice - currentPrice!) / (maxPrice - minPrice))
            validLabel.frame.origin = CGPoint(x: rect.maxX - 5 - validLabel.frame.width, y: labelY - validLabel.frame.height / 2)
            
            let labelLine = UIBezierPath()
            labelLine.move(to: CGPoint(x: validLabel.frame.minX, y:validLabel.frame.midY))
            labelLine.addLine(to: CGPoint(x: rect.minX, y: validLabel.frame.midY))
            labelLine.lineWidth = 1.1
            UIColor.systemGray.setStroke()
            labelLine.stroke()
            
            if let validBSLabel = buySellPriceLabel {
                let bsFrame = validBSLabel.frame
                let cpFrame = validLabel.frame
                
                if cpFrame.intersects(bsFrame) {
                    if cpFrame.origin.y < bsFrame.origin.y {
                        validBSLabel.frame = validBSLabel.frame.offsetBy(dx: 0, dy: validBSLabel.frame.height/2)
                        validLabel.frame.origin = CGPoint(x:validLabel.frame.origin.x, y: validBSLabel.frame.minY-validLabel.frame.height)
                    }
                    else {
                        validBSLabel.frame = validBSLabel.frame.offsetBy(dx: 0, dy: -validBSLabel.frame.height/2)
                        validLabel.frame.origin = CGPoint(x:validLabel.frame.origin.x, y: validBSLabel.frame.maxY)
                    }
                }
            }
            
            validLabel.isHidden = false
            
        }

        var index = 0
        for label in priceLabels {
            
            label.sizeToFit()
            let labelY: CGFloat = self.topMargin + self.verticalHeightFactor * rect.height * CGFloat((maxPrice - yAxisNumbers[index]) / (maxPrice - minPrice))
            label.frame.origin = CGPoint(x: 5, y: labelY - label.frame.height / 2)
            label.isHidden = false

            index += 1
        }

        
    }

}
