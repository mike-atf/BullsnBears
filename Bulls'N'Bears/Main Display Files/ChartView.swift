//
//  ChartView.swift
//  TrendMyStocks
//
//  Created by aDav on 02/12/2020.
//

import UIKit

class ChartView: UIView {
    
    @IBOutlet var widthConstraint: NSLayoutConstraint!
    
    var yAxisLabels = [UILabel]()
    var yAxisNumbers = [Double]()
    var xAxisLabels = [UILabel]()
    var trendLabels = [UILabel]()
    var valuationLabels = [UILabel]()
    var buySellLabel: UILabel?

    var candleBoxes = UIBezierPath()
    var candleSticks = UIBezierPath()
    
    var share: Share?
    
    var lowestPriceInRange: Double?
    var highestPriceInRange: Double?
    var minPrice = Double()
    var maxPrice = Double()
    var dateRange: [Date]?
    var chartTimeSpan = TimeInterval()
    
    var chartAreaSize = CGSize()
    var chartOrigin = CGPoint()
    var chartEnd = CGPoint()
    
    var trendsToShow = [TrendProperties]()
    var buttonGroupTime = [CheckButton]()
    var buttonGroupType = [CheckButton]()

    var latestSMA10crossing: LineCrossing?
       
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
                

        for _ in 0...30 {
            let aLabel: UILabel = {
                let label = UILabel()
                label.font = UIFont.preferredFont(forTextStyle: .footnote)
                self.addSubview(label)
                return label
            }()
            xAxisLabels.append(aLabel)
        }
        
    }
    
    public func configure(stock: Share) {
        
        share = stock

        guard let validStock = share else { return }

        lowestPriceInRange = validStock.lowestPrice()
        highestPriceInRange = validStock.highestPrice()
        dateRange = validStock.priceDateRange()
        dateRange![1] = Date().addingTimeInterval(foreCastTime)
        
        guard lowestPriceInRange != nil else { return }
        guard highestPriceInRange != nil else { return }
        guard dateRange != nil else { return }
        
        minPrice = (lowestPriceInRange! * 0.9).rounded()
        maxPrice = (highestPriceInRange! * 1.1).rounded() + 1

        let step = findYAxisValues(min: minPrice, max: maxPrice)
        yAxisLabels.removeAll()
        yAxisNumbers.removeAll()
        var labelPrice = Double(Int(maxPrice / step)) * step
        while labelPrice >= minPrice {
            let newLabel: UILabel = {
                let label = UILabel()
                label.font = UIFont.preferredFont(forTextStyle: .footnote)
                label.textAlignment = .right
                label.text = currencyFormatterNoGapWithPence.string(from: NSNumber(value: labelPrice))
//                label.sizeToFit()
                self.addSubview(label)
                return label
            }()
            yAxisLabels.append(newLabel)
            yAxisNumbers.append(labelPrice)
            labelPrice -= step
        }
                
        let timeInterval = dateRange![1].timeIntervalSince(dateRange![0])
        var count = 0.0
        xAxisLabels.forEach { (label) in
            label.text = dateFormatter.string(from: dateRange![0].addingTimeInterval(count * timeInterval / Double(xAxisLabels.count-1)))
            label.sizeToFit()
            count += 1
        }
                
        latestSMA10crossing = share?.latestSMA10Crossing()
        self.setNeedsDisplay()
        
    }

    override func draw(_ rect: CGRect) {
                
        
// Y axis
        chartOrigin.x = rect.width * 0
        chartEnd.y = rect.height * 0
        chartOrigin.y = rect.height * 0.95
        chartEnd.x = rect.width * 0.95
        chartAreaSize.height = chartOrigin.y - chartEnd.y
        chartAreaSize.width = chartEnd.x - chartOrigin.x
       
       let yAxis = UIBezierPath()
       yAxis.move(to: CGPoint(x: chartOrigin.x, y:chartEnd.y))
       yAxis.addLine(to: CGPoint(x: chartOrigin.x, y: chartOrigin.y))
       yAxis.lineWidth = 2
        UIColor.systemGray.setStroke()
       yAxis.stroke()
       
// x axis
       let xAxis = UIBezierPath()
       xAxis.move(to: CGPoint(x: chartOrigin.x, y: chartOrigin.y))
       xAxis.addLine(to: CGPoint(x: chartEnd.x, y: chartOrigin.y))
       xAxis.lineWidth = 2
       xAxis.stroke()
       
       guard let validStock = share else { return }
       
        var index = 0
        yAxisLabels.forEach { (label) in
            label.sizeToFit()
            let labelY: CGFloat = chartEnd.y + chartAreaSize.height * CGFloat((maxPrice - yAxisNumbers[index]) / (maxPrice - minPrice))
            label.frame.origin = CGPoint(x: chartEnd.x + 15, y: labelY - label.frame.height / 2)
            index += 1
       }
       
        var step: CGFloat = 0
       var xAxisLabelLeft = chartOrigin.x
       xAxisLabels.forEach { (label) in
           label.frame.origin = CGPoint(x: xAxisLabelLeft - label.frame.width / 2, y: chartOrigin.y + 5)
           step += 1
            xAxisLabelLeft += chartAreaSize.width / CGFloat(xAxisLabels.count-1)
       }
        
        chartTimeSpan = dateRange!.last!.timeIntervalSince(dateRange!.first!)
        let boxWidth = chartAreaSize.width / CGFloat(dateRange!.last!.timeIntervalSince(dateRange!.first!) / (24*3600))

        let dailyPrices = share?.getDailyPrices()
        var sma10:[Double]?
        var smaLine: UIBezierPath?
        if dailyPrices?.count ?? 0 > 11 {
            sma10 = [Double]()
            smaLine = UIBezierPath()
            let firstSMA = dailyPrices![..<10].compactMap{ $0.close }.reduce(0, +) / 10
            let x = CGFloat(dailyPrices![9].tradingDate.timeIntervalSince(dateRange!.first!) / chartTimeSpan) * chartAreaSize.width + boxWidth / 2
            let y = chartEnd.y + chartAreaSize.height * (CGFloat((maxPrice - firstSMA) / (maxPrice - minPrice)))
            smaLine?.move(to: CGPoint(x: x, y: y))
        }

// candles
                
        dailyPrices?.forEach({ (pricePoint) in
            let boxLeft = chartOrigin.x - (boxWidth * 0.8 / 2) + CGFloat(pricePoint.tradingDate.timeIntervalSince(dateRange!.first!) / chartTimeSpan) * chartAreaSize.width
            let boxTop = chartEnd.y + chartAreaSize.height * (CGFloat((maxPrice - Swift.max(pricePoint.close, pricePoint.open)) / (maxPrice - minPrice)))
            let boxBottom = chartEnd.y + chartAreaSize.height * (CGFloat((maxPrice - Swift.min(pricePoint.close, pricePoint.open)) / (maxPrice - minPrice)))
            let boxHeight = boxBottom - boxTop

            let boxRect = CGRect(x: boxLeft, y: boxTop, width: boxWidth * 0.8, height: boxHeight)
            let newBox = UIBezierPath(rect: boxRect)
            let fillColor = pricePoint.close > pricePoint.open ? UIColor(named: "Green")! : UIColor(named: "Red")!
            fillColor.setFill()
            fillColor.setStroke()
            newBox.fill()
            
            let tick = UIBezierPath()
            let highPoint: CGFloat = chartEnd.y + chartAreaSize.height * CGFloat((maxPrice - pricePoint.high) / (maxPrice - minPrice))
            let lowPoint: CGFloat = chartEnd.y + chartAreaSize.height * CGFloat((maxPrice - pricePoint.low) / (maxPrice - minPrice))
            tick.move(to: CGPoint(x:-1 + boxLeft + boxWidth / 2, y: highPoint))
            tick.addLine(to: CGPoint(x:-1 + boxLeft + boxWidth / 2, y: lowPoint))
            tick.stroke()
            
//SMA Line
            sma10?.append(pricePoint.close)
            if sma10?.count ?? 0 == 10 {
                let sma = (sma10?.reduce(0, +))! / 10.0
                let x = boxLeft + boxWidth * 0.4
                let y = chartEnd.y + chartAreaSize.height * (CGFloat((maxPrice - sma) / (maxPrice - minPrice)))
                smaLine?.addLine(to: CGPoint(x: x, y: y))
                sma10!.removeFirst()
            }
            
// latest SMA10 crossing
            if let crossingPoint = latestSMA10crossing {
                let latestSMAcrossing = UIBezierPath()
                let x = chartOrigin.x - (boxWidth * 0.8 / 2) + CGFloat(crossingPoint.date.timeIntervalSince(dateRange!.first!) / chartTimeSpan) * chartAreaSize.width
                latestSMAcrossing.move(to: CGPoint(x: x, y: rect.minY))
                latestSMAcrossing.addLine(to: CGPoint(x: x, y: chartOrigin.y))
                
                UIColor.systemGray3.setStroke()
                latestSMAcrossing.lineWidth = 2.0
                latestSMAcrossing.stroke()
                
                buySellLabel?.removeFromSuperview()
                buySellLabel = {
                    let label = UILabel()
                    label.font = UIFont.systemFont(ofSize: 12)
                    label.textAlignment = .right
                    let text = crossingPoint.signal < 0 ? " :Sell" : " :Buy"
                    let signal$ = numberFormatter.string(from: crossingPoint.signal as NSNumber) ?? "-"
                    var priceText = " "
                    if let validPrice = crossingPoint.crossingPrice {
                        priceText = " @ " + (currencyFormatterNoGapWithPence.string(from: validPrice as NSNumber) ?? "-")
                    }
                    label.text = " " + dateFormatter.string(from: crossingPoint.date) + text + priceText + " (" + signal$ + ") "
                    label.backgroundColor = crossingPoint.signal < 0 ? UIColor(named: "Red") : UIColor(named: "DarkGreen")
                    label.sizeToFit()
                    self.addSubview(label)
                    return label
                }()
                buySellLabel?.frame.origin = CGPoint(x: x, y: rect.minY)

            }

        })
        
        UIColor.systemBlue.setStroke()
        smaLine?.lineWidth = 1.2
        smaLine?.stroke()
        
// current price line
        
        if let dailyPrices = share?.getDailyPrices(){
            if let currentPrice = dailyPrices.last?.close {
                let currentPriceLine = UIBezierPath()
                let pp1 = PriceDate(dailyPrices.first!.tradingDate, currentPrice)
                let pp2 = PriceDate(dailyPrices.last!.tradingDate, currentPrice)
                
                let startPoint = plotPricePoint(pricePoint: pp1)
                var endPoint = plotPricePoint(pricePoint: pp2)
                endPoint.x = yAxisLabels.first!.frame.maxX + 5
                currentPriceLine.move(to: startPoint)
                currentPriceLine.addLine(to: endPoint)
                
                UIColor.label.setStroke()
                currentPriceLine.stroke()
      
    // DCF Label
                
                for label in valuationLabels {
                    label.removeFromSuperview()
                }
                valuationLabels.removeAll()

                if let existingValuation = CombinedValuationController.returnDCFValuations(company: share!.symbol) {
                    let (fairValue, errors) = existingValuation.returnIValue()
                    if (fairValue ?? 0.0) > 0 {
                        let ratio = currentPrice / fairValue!
                        let ratio$ = " DCF " + (numberFormatterWith1Digit.string(from: ratio as NSNumber) ?? "") + "x "

                        let newLabel: UILabel = {
                            let label = UILabel()
                            label.numberOfLines = 1
                            label.font = UIFont.preferredFont(forTextStyle: .footnote)
                            label.textColor = UIColor(named: "antiLabel")
                            label.backgroundColor = (errors.count == 0) ? UIColor.label : UIColor.systemYellow
                            label.text = ratio$
                            label.sizeToFit()
                            
                            let labelTop = endPoint.y - label.frame.height - 2
                            
                            label.frame = label.frame.offsetBy(dx: endPoint.x, dy:labelTop)
                            return label
                        }()
                        valuationLabels.append(newLabel)
                        addSubview(newLabel)
                    }
                }
                
    // R1 Label
                // R1 Label
                if let existingValuation = CombinedValuationController.returnR1Valuations(company: share!.symbol) {
                    let (fairValue,errors) = existingValuation.stickerPrice()
                        if (fairValue ?? 0) > 0 {
                            let ratio = currentPrice / fairValue!
                            let ratio$ = " Growth " + (numberFormatterWith1Digit.string(from: ratio as NSNumber) ?? "") + "x "

                            let newLabel: UILabel = {
                                let label = UILabel()
                                label.numberOfLines = 1
                                label.font = UIFont.preferredFont(forTextStyle: .footnote)
                                label.textColor = UIColor(named: "antiLabel")
                                label.backgroundColor = (errors == nil) ? UIColor.label : UIColor.systemYellow
                                label.text = ratio$
                                label.sizeToFit()
                                
                                let labelTop = endPoint.y + 2
                                
                                label.frame = label.frame.offsetBy(dx: endPoint.x, dy:labelTop)
                                return label
                            }()
                            valuationLabels.append(newLabel)
                            addSubview(newLabel)
                        }

            }
        }
        }
        trendLabels.forEach { (label) in
            label.removeFromSuperview()
        }
            
        trendLabels.removeAll()

        trendsToShow.forEach { (trend) in
            drawTrend(stock: validStock, trendProperties: trend)
        }


    }
    
    private func drawTrend(stock: Share, trendProperties: TrendProperties) {
        
        var trendDuration = dateRange!.last!.timeIntervalSince(dateRange!.first!)
        
        switch trendProperties.time {
        case .full:
            trendDuration = dateRange!.last!.timeIntervalSince(dateRange!.first!)
        case .quarter:
            trendDuration = trendDuration / 4
        case .half:
            trendDuration = trendDuration / 2
        case .month:
            trendDuration = 30*24*3600
        case .none:
            trendDuration = dateRange!.last!.timeIntervalSince(dateRange!.first!)
        }
        
        let trendStart = dateRange!.last!.addingTimeInterval(-trendDuration-foreCastTime)
        let trendEnd = dateRange!.last!
        
        var startPoint = CGPoint()
        var endPoint = CGPoint()
        var startPrice = Double()
        var projectedPrice = Double()
        var coCoEff:Double?
        
        if trendProperties.type == TrendType.regression {
            // draw regression trends
            if let correlation = stock.correlationTrend(properties: trendProperties) {
                let a = PriceDate(date:trendStart, price: correlation.yIntercept)
                let b = PriceDate(date:trendEnd, price: correlation.yIntercept + correlation.incline * trendEnd.timeIntervalSince(trendStart))
                
                coCoEff = correlation.coEfficient
                startPrice = a.price
                projectedPrice = b.price
                startPoint = plotPricePoint(pricePoint: a)
                endPoint = plotPricePoint(pricePoint: b)
            }
        }
        else {
            // twoPoints
//            let trend = stock.twoPointTrend(properties: trendProperties)
            guard let trend = stock.lowHighTrend(properties: trendProperties) else {
                return
            }
//            guard let trend = stock.lowHighTrend(properties: trendProperties) else { return }
            startPrice = trend.startPrice!
            projectedPrice = startPrice + trend.incline! * dateRange!.last!.timeIntervalSince(trend.startDate)
            startPoint = plotPricePoint(pricePoint: PriceDate(trend.startDate,startPrice))
            endPoint = plotPricePoint(pricePoint: PriceDate(trendEnd, projectedPrice))
            
        }
        
        let trendLine = UIBezierPath()
        trendLine.move(to:startPoint)

        trendLine.addLine(to: endPoint)
        trendLine.lineWidth = 2.0
        if trendProperties.dash {
            
            var dashPattern = [CGFloat]()
            if trendProperties.time == TrendTimeOption.quarter {
                dashPattern = [6,7]
            }
            else if trendProperties.time == TrendTimeOption.month {
                dashPattern = [3,7]
            }
            else {
                dashPattern = [7,7]
            }
            trendLine.setLineDash(dashPattern, count: dashPattern.count, phase: 0)
        }
        trendProperties.color.setStroke()
        trendLine.stroke()
        
        var reliability: Double?
        if trendProperties.type != .regression {
            if let failureRate = stock.testTwoPointReliability(_covering: trendDuration, trendType: trendProperties.type) {
                reliability = 1 - failureRate
            }
        }
        else {
            if let failureRate = stock.testRegressionReliability(_covering: trendDuration, trendType: trendProperties.type) {
                reliability = 1 - failureRate
            }
        }
        
        let increase = (projectedPrice - startPrice) / startPrice
        if let latestPrice = stock.getDailyPrices()?.last {
            let increaseFromLatest = (projectedPrice - latestPrice.close) / latestPrice.close
            addTrendLabel(price: projectedPrice, increase1: increase, increase2: increaseFromLatest, correlation: coCoEff , reliability: reliability,color: trendProperties.color)
        }
    }
    
    private func plotPricePoint(pricePoint: PriceDate) -> CGPoint {
        
        let timeFromEarliest = pricePoint.date.timeIntervalSince(dateRange![0])
        let datePoint: CGFloat = chartOrigin.x + CGFloat(timeFromEarliest / chartTimeSpan) * chartAreaSize.width
        let point: CGFloat = chartOrigin.y - CGFloat((pricePoint.price - minPrice) / (maxPrice - minPrice)) * chartAreaSize.height
        return CGPoint(x: datePoint, y: point)
    }
    
    private func addTrendLabel(price: Double, increase1: Double, increase2: Double? = nil, correlation: Double? = nil, reliability: Double? = nil, color: UIColor) {
        
        let endPrice$ = currencyFormatterNoGapWithPence.string(from: NSNumber(value: price))!
        let increase1$ = percentFormatter0Digits.string(from: NSNumber(value: increase1))!
        var increase2$ = ""
        if let validIncrease2 = increase2 {
            increase2$ = percentFormatter0Digits.string(from: NSNumber(value: validIncrease2))!
        }
        let labelMidY = chartEnd.y + chartAreaSize.height * CGFloat((maxPrice - price) / (maxPrice - minPrice))
        
        var text = " \(endPrice$) = \(increase1$) \n From latest: \(increase2$) "
        var superscriptIndex = Int()
        if let r = correlation {
            superscriptIndex = text.count + 3
            text = text + "\n R2=" + percentFormatter0Digits.string(from: NSNumber(value: r))! + " "
        }
        if let r = reliability {
            superscriptIndex = text.count + 1
            text = text + "\n success=" + percentFormatter0Digits.string(from: NSNumber(value: r))! + " "
        }
        
        let newTrendLabel: UILabel = {
            let label = UILabel()
            label.numberOfLines = 0
            label.font = UIFont.preferredFont(forTextStyle: .callout)
            label.textColor = UIColor.white
            label.backgroundColor = color
            label.setAttributedTextWithSuperscripts(text: text, indicesOfSuperscripts: [superscriptIndex])
            label.sizeToFit()
            
            let labelTop = labelMidY - label.frame.height / 2
            let labelBottom = labelMidY + label.frame.height / 2
            
            label.frame = label.frame.offsetBy(dx: chartEnd.x - label.frame.width, dy:labelTop)
            
            if labelTop < chartEnd.y {
                label.frame.origin = CGPoint(x: chartEnd.x - label.frame.width, y: 0)
            }
            else if labelBottom > chartEnd.y + chartAreaSize.height {
                label.frame = label.frame.offsetBy(dx: 0, dy: labelBottom + chartEnd.y - chartAreaSize.height)
            }
            
            return label
        }()
    
        addSubview(newTrendLabel)
        trendLabels.append(newTrendLabel)
        
        trendLabels.sort { (l0, l1) -> Bool in
            if l0.frame.minY < l1.frame.minY { return true }
            else { return false }
        }
        
        for i in 0..<trendLabels.count {
            for j in 0..<i {
                if trendLabels[i].frame.intersects(trendLabels[j].frame) {
                    let intersect = trendLabels[i].frame.intersection(trendLabels[j].frame)
                    trendLabels[i].frame = trendLabels[i].frame.offsetBy(dx: 0, dy: intersect.height)
                }
            }
        }
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
    
}

extension ChartView: ChartButtonDelegate {
        
    var timeButtons: [CheckButton] {
        get {
            return buttonGroupTime
        }
        set {
            buttonGroupTime = newValue
        }
    }
    
    var typeButtons: [CheckButton] {
        get {
            return buttonGroupType
        }
        set {
            buttonGroupType = newValue
        }
    }
    
    
    func trendButtonPressed(button: CheckButton) {
                
        let typesShown = buttonGroupType.filter { (button) -> Bool in
            return button.active
        }
        
        let timesShown = buttonGroupTime.filter { (button) -> Bool in
            return button.active
        }
        
        trendsToShow.removeAll()
        for typeButton in typesShown {
            for timeButton in timesShown {
                var dashedLine = true
                if timeButton.associatedTrendTime == TrendTimeOption.full { dashedLine = false }
                let newTrend = TrendProperties(type: typeButton.associatedTrendType!, time: timeButton.associatedTrendTime ?? TrendTimeOption.full, dash: dashedLine)
                trendsToShow.append(newTrend)
            }
        }
        
        setNeedsDisplay()
    }
    
    
}

