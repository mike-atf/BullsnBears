//
//  ChartView.swift
//  TrendMyStocks
//
//  Created by aDav on 02/12/2020.
//

import UIKit

class ChartView: UIView {
    
    @IBOutlet var widthConstraint: NSLayoutConstraint!
    
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
    
    let week: TimeInterval = 7*24*3600
       
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
                
        self.backgroundColor = UIColor.systemBackground
    }
    
    public func configure(stock: Share) {
        
        share = stock

        guard let validStock = share else { return }

        lowestPriceInRange = validStock.lowestPrice()
        highestPriceInRange = validStock.highestPrice()
        dateRange = validStock.priceDateRangeWorkWeeksForCharts()

        guard lowestPriceInRange != nil else { return }
        guard highestPriceInRange != nil else { return }
        guard dateRange != nil else { return }
        
        minPrice = (lowestPriceInRange! * 0.9).rounded()
        maxPrice = (highestPriceInRange! * 1.1).rounded() + 1
        
        if let latestCrossings = share?.latest3Crossings() {
            latestSMA10crossing = latestCrossings.filter({ (crossing) -> Bool in
                if crossing?.type ?? "" == "sma10" { return true }
                else { return false }
            }).first as? LineCrossing
        }

        self.setNeedsDisplay()
        
    }
    
    override func draw(_ rect: CGRect) {
                
        chartOrigin.x = rect.width * 0
        chartEnd.y = rect.height * 0
        chartOrigin.y = rect.height
        chartEnd.x = rect.width
        chartAreaSize.height = chartOrigin.y - chartEnd.y
        chartAreaSize.width = chartEnd.x - chartOrigin.x
        
        guard let validStock = share else { return }
    
        chartTimeSpan = dateRange!.last!.timeIntervalSince(dateRange!.first!)
        let boxWidth = chartAreaSize.width / CGFloat(dateRange!.last!.timeIntervalSince(dateRange!.first!) / (24*3600))
        
        // MARK: - Week Fields
        
        let weekWidth = CGFloat(week / chartTimeSpan) * chartAreaSize.width
        var weekX = rect.maxX - weekWidth
        let weekRects = UIBezierPath()
        while weekX >= rect.minX {
            
            let weekRect = CGRect(x: weekX, y: rect.minY, width: weekWidth, height: rect.height)
            let path = UIBezierPath(rect: weekRect)
            weekRects.append(path)

            weekX -= 2*weekWidth
        }
        
        UIColor.systemGray6.setFill()
        weekRects.fill()

        let dailyPrices = share?.getDailyPrices()
        var sma10:[Double]?
        var sma50: [Double]?
        
        var sma10Line: UIBezierPath?
        var sma50Line: UIBezierPath?
        if dailyPrices?.count ?? 0 > 11 {
            sma10 = [Double]()
            sma10Line = UIBezierPath()
            let firstSMA10 = dailyPrices![..<10].compactMap{ $0.close }.reduce(0, +) / 10
            let x = chartOrigin.x + CGFloat(dailyPrices![10].tradingDate.timeIntervalSince(dateRange!.first!) / chartTimeSpan) * chartAreaSize.width + boxWidth / 2
            let y = chartEnd.y + chartAreaSize.height * (CGFloat((maxPrice - firstSMA10) / (maxPrice - minPrice)))
            sma10Line?.move(to: CGPoint(x: x, y: y))
        }
        
        if dailyPrices?.count ?? 0 > 51 {
            sma50 = [Double]()
            sma50Line = UIBezierPath()
            let firstSMA50 = dailyPrices![..<50].compactMap{ $0.close }.reduce(0, +) / 50
            let x = chartOrigin.x + CGFloat(dailyPrices![50].tradingDate.timeIntervalSince(dateRange!.first!) / chartTimeSpan) * chartAreaSize.width + boxWidth / 2
            let y = chartEnd.y + chartAreaSize.height * (CGFloat((maxPrice - firstSMA50) / (maxPrice - minPrice)))
            sma50Line?.move(to: CGPoint(x: x, y: y))
        }


        // MARK: - candles

        for i in 0..<(dailyPrices ?? []).count {
            let pricePoint = dailyPrices![i]
            let boxLeft = chartOrigin.x + CGFloat(pricePoint.tradingDate.timeIntervalSince(dateRange!.first!) / chartTimeSpan) * chartAreaSize.width //- (boxWidth * 0.8 / 2)
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
                        
            //MARK: - SMA10 Line
            sma10?.append(pricePoint.close)
            if sma10?.count ?? 0 > 10 {
                let sma = (sma10?[..<10].reduce(0, +))! / 10.0 // exclude elements just added so it's sma until day before nbut not including current day
                let x = boxLeft + boxWidth / 2
                let y = chartEnd.y + chartAreaSize.height * (CGFloat((maxPrice - sma) / (maxPrice - minPrice)))
                sma10Line?.addLine(to: CGPoint(x: x, y: y))
                sma10?.removeFirst()
            }
            
            //MARK: - SMA10 Line
            sma50?.append(pricePoint.close)
            if sma50?.count ?? 0 > 50 {
                let sma = (sma50?[..<50].reduce(0, +))! / 50.0 // exclude elements just added so it's sma until day before nbut not including current day
                let x = boxLeft + boxWidth / 2
                let y = chartEnd.y + chartAreaSize.height * (CGFloat((maxPrice - sma) / (maxPrice - minPrice)))
                sma50Line?.addLine(to: CGPoint(x: x, y: y))
                sma50?.removeFirst()
            }

        }
        
        UIColor.systemBlue.setStroke()
        sma10Line?.lineWidth = 1.2
        sma10Line?.stroke()
        
        UIColor.systemRed.setStroke()
        sma50Line?.lineWidth = 1.2
        sma50Line?.stroke()

        
        //MARK: -  latest SMA10 crossing
        if let crossingPoint = latestSMA10crossing {
            let latestSMAcrossing = UIBezierPath()
            let x = chartOrigin.x + CGFloat((crossingPoint.date.timeIntervalSince(dateRange!.first!) / chartTimeSpan)) * chartAreaSize.width + boxWidth / 2
            latestSMAcrossing.move(to: CGPoint(x: x, y: rect.minY))
            latestSMAcrossing.addLine(to: CGPoint(x: x, y: chartOrigin.y))
            
            let color = crossingPoint.signal < 0 ? UIColor(named: "Red")! : UIColor(named: "DarkGreen")!
            color.setStroke()
            latestSMAcrossing.lineWidth = 1.3
            latestSMAcrossing.stroke()
            
        }

        
        //MARK: - current price line
        let nonNullLivePrice = (share?.lastLivePrice != 0.0) ? share?.lastLivePrice : nil
        if let dailyPrices = share?.getDailyPrices() {
            if dailyPrices.count > 0 {
                if let currentPrice = nonNullLivePrice ?? dailyPrices.last?.close {
                    let currentPriceLine = UIBezierPath()
                    let pp1 = PriceDate(dailyPrices.first!.tradingDate, currentPrice)
                    let pp2 = PriceDate(dailyPrices.last!.tradingDate, currentPrice)
                    
                    let startPoint = plotPricePoint(pricePoint: pp1)
                    var endPoint = plotPricePoint(pricePoint: pp2)
                    endPoint.x = rect.maxX // yAxisLabels.first!.frame.maxX + 5
                    currentPriceLine.move(to: startPoint)
                    currentPriceLine.addLine(to: endPoint)
                    
                    UIColor.label.setStroke()
                    currentPriceLine.stroke()
      
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
            guard let trend = stock.lowHighTrend(properties: trendProperties) else {
                return
            }

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

