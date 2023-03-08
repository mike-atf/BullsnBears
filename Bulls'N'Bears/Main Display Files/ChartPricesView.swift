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
    var share: Share!
    
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
    var currentLabelRefreshTimer: Timer?
    
    let timeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .numeric
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
    
    let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()


    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.backgroundColor = UIColor.systemBackground
        
    }

    
    func configure(share: Share?, topMargin: CGFloat? = 0, verticalHeightFactor: CGFloat? = 1.0) {
        
        guard let validShare = share else { return }
        self.share = validShare
        
        let priceRange = validShare.priceRange(nil, nil)
        lowestPriceInRange = priceRange?.first
        highestPriceInRange = priceRange?.last

        guard lowestPriceInRange != nil else { return }
        guard highestPriceInRange != nil else { return }
        
        // these need to match between ChartView and PricerChartView otherwise priceLabels dont match candleStick chart
        self.topMargin = topMargin ?? 0.0
        self.verticalHeightFactor = verticalHeightFactor ?? 1.0
        
        minPrice = (lowestPriceInRange! * 0.9).rounded()
        maxPrice = (highestPriceInRange! * 1.1).rounded() + 1
        
        if let buyPrice = share?.research?.targetBuyPrice {
            if buyPrice < minPrice { minPrice = buyPrice }
            else if buyPrice > maxPrice { maxPrice = buyPrice }
        }
        
        if let predictions = share?.research?.sharePricePredictions() {
            if let maxPredictedPrice = predictions.values.max() {
                if maxPredictedPrice > maxPrice { maxPrice = maxPredictedPrice }
            }
            
            if let minPredcitedPrice = predictions.values.min() {
                if minPredcitedPrice < minPrice { minPrice = minPredcitedPrice }
            }
        }

        let nonNullLivePrice = (share?.lastLivePrice != 0.0) ? share?.lastLivePrice : nil
        if let validPrice = nonNullLivePrice ?? share?.latestPrice(option: .close) {
            currentPrice = validPrice
            
            let priceDate = share?.lastLivePriceDate ?? share?.getDailyPrices()?.last?.tradingDate
            
            currentPriceLabel = {
                let label = UILabel()
                label.font = UIFont.systemFont(ofSize: 13)
                label.textColor = UIColor(named: "antiLabel")!
                label.textAlignment = .right
                label.numberOfLines = 0
                label.text = " " + currencyFormatterNoGapWithPence.string(from: NSNumber(value: validPrice))! + " "
                if let date = priceDate { label.text! += "\n " + timeFormatter.localizedString(for: date, relativeTo: Date()) + " " }
                label.sizeToFit()
                label.backgroundColor = UIColor.label
                label.isHidden = true
                self.addSubview(label)
                return label
            }()
            
            if (share?.currency ?? "USD") != "USD" {
                currentPriceLabel?.text = currentPriceLabel?.text?.replacingOccurrences(of: "$", with: "€")
            }
            
            if share?.lastLivePriceDate != nil {
               currentLabelRefreshTimer = Timer(timeInterval: 120, target: self, selector: #selector(refreshCurrentLabel), userInfo: nil, repeats: true)
                currentLabelRefreshTimer?.tolerance = 1.0
                RunLoop.current.add(currentLabelRefreshTimer!, forMode: .common) // makes refresh independent of user interacting with App while time fires, which would block the timer execution.
            }
        }

        let step = findYAxisValues(min: minPrice, max: maxPrice)

        var labelPrice = Double(Int(maxPrice / step)) * step
        while labelPrice >= minPrice {
            let newLabel: UILabel = {
                let label = UILabel()

                label.font = UIFont.systemFont(ofSize: 13)
                label.textAlignment = .right
                label.text = currencyFormatterNoGapWithPence.string(from: NSNumber(value: labelPrice))
                label.sizeToFit()
                label.isHidden = true
                self.addSubview(label)
                
                if (share?.currency ?? "USD") != "USD" {
                    label.text = label.text?.replacingOccurrences(of: "$", with: "€")
                }

                return label
            }()
            priceLabels.append(newLabel)
            yAxisNumbers.append(labelPrice)
            labelPrice -= step
        }
        
        
        if let latestSignals = validShare.latest3Crossings() {
            if let lastCrossing = latestSignals[2] {
                
                let labelColor = lastCrossing.signal > 0 ? UIColor(named: "Green") : UIColor(named: "Red")
                let earlierSignalsSame = latestSignals[..<2].compactMap{ $0?.signalIsBuy() }.filter { (buySignal) -> Bool in
                    if buySignal == lastCrossing.signalIsBuy() { return true }
                    else { return false }
                }
                
                if earlierSignalsSame.count == 2 {
                    var price$ = String()
                    if let validPrice = lastCrossing.crossingPrice {
                        buySellPrice = validPrice
                        price$ = currencyFormatterNoGapWithPence.string(from: buySellPrice! as NSNumber) ?? ""
                        
                        buySellPriceLabel = {
                            let label = UILabel()
                            label.font = UIFont.systemFont(ofSize: 13)
                            label.textColor = UIColor.white
                            label.textAlignment = .right
                            label.text = " " + price$ + " "
                            label.sizeToFit()
                            label.backgroundColor = labelColor
                            label.isHidden = true
                            if (share?.currency ?? "USD") != "USD" {
                                label.text = label.text?.replacingOccurrences(of: "$", with: "€")
                            }

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


        setNeedsDisplay()

    }
    
    private func findYAxisValues(min: Double, max: Double) -> Double {
        
        let options = [0.1,0.5,1.0,2.0,2.5,5.0,10.0,20.0,25.0,50.0,100.0,150.0,200.0,250.0,500.0,1000.0,10000.0]
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
    
    @objc
    func refreshCurrentLabel() {
        
        let nonNullLivePrice = (share.lastLivePrice != 0.0) ? share.lastLivePrice : nil
        if let validPrice = nonNullLivePrice ?? share.latestPrice(option: .close) {
            currentPriceLabel?.text = " " + currencyFormatterNoGapWithPence.string(from: NSNumber(value: validPrice))! + " "
            if let date = share.lastLivePriceDate { currentPriceLabel?.text! += "\n " + timeFormatter.localizedString(for: date, relativeTo: Date()) + " " }
            currentPriceLabel?.sizeToFit()
        }
    }

}
