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
    
    var dateFormatter: DateFormatter!
    var currencyFormatter : NumberFormatter!
    var percentFormatter: NumberFormatter!
    var numberFormatter: NumberFormatter!

    var candleBoxes = UIBezierPath()
    var candleSticks = UIBezierPath()
    
    var stockToShow: Stock?
    
    var lowestPriceInRange: Double?
    var highestPriceInRange: Double?
    var minPrice = Double()
    var maxPrice = Double()
    var dateRange: [Date]?
    var chartTimeSpan = TimeInterval()
    
    var chartAreaSize = CGSize()
    var chartOrigin = CGPoint()
    var chartEnd = CGPoint()
    
    var drawLows = false
    var drawRegression = false
    var drawHighs = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
                
        dateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = NSLocale.current
            formatter.timeZone = NSTimeZone.local
            formatter.dateFormat = "d.M."
            return formatter
        }()
        
        currencyFormatter = {
            let formatter = NumberFormatter()
            formatter.currencySymbol = "$"
            formatter.numberStyle = NumberFormatter.Style.currency
            return formatter
        }()
        
        percentFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .percent
            formatter.maximumFractionDigits = 0
            formatter.minimumIntegerDigits = 1
            return formatter
        }()
        
        numberFormatter = {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 2
            return formatter
        }()

                
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
    
    public func configure(stock: Stock) {
        
        stockToShow = stock

        guard let validStock = stockToShow else { return }

        lowestPriceInRange = validStock.lowestPrice()
        highestPriceInRange = validStock.highestPrice()
        dateRange = validStock.priceDateRange()
        dateRange![1] = dateRange!.last!.addingTimeInterval(foreCastTime)
        
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
                label.text = currencyFormatter.string(from: NSNumber(value: labelPrice))
                label.sizeToFit()
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
       
       guard let validStock = stockToShow else { return }
       
       
        var index = 0
        yAxisLabels.forEach { (label) in
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

// candles
        chartTimeSpan = dateRange!.last!.timeIntervalSince(dateRange!.first!)
        let boxWidth = chartAreaSize.width / CGFloat(dateRange!.last!.timeIntervalSince(dateRange!.first!) / (24*3600))
        stockToShow?.dailyPrices.forEach({ (pricePoint) in
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

        })
        
// lowest point lines
        trendLabels.forEach { (label) in
            label.removeFromSuperview()
        }
        trendLabels.removeAll()

// low trends
        let trends = validStock.longerTrends(priceOption: .low, findOption: .minimum)
        let autoTrends2 = UIBezierPath()
        var point = plotPricePoint(pricePoint: PriceDate(trends.first!.startDate, trends.first!.startPrice!))
        autoTrends2.move(to: point)
        
        for i in 1..<trends.count {
            point = plotPricePoint(pricePoint: PriceDate(trends[i].startDate, trends[i].startPrice!))
            autoTrends2.addLine(to: point)
        }
        autoTrends2.lineWidth = 2.0
        UIColor.systemPurple.setStroke()
        autoTrends2.stroke()

        if drawLows {
            var twoLowPointTrends = validStock.twoLowPointsTrend(priceOption: .low, findOption: .minimum, timeOption: .half)
            drawTrendLine(stock: validStock, trends: twoLowPointTrends, type: .mean, priceOption: .low, highOrLow: .minimum, quartiles: false ,color: UIColor(named: "Red") ?? UIColor.systemRed)

            twoLowPointTrends = validStock.twoLowPointsTrend(priceOption: .low, findOption: .minimum, timeOption: .quarter)
            drawTrendLine(stock: validStock, trends: twoLowPointTrends, type: .mean, priceOption: .low, highOrLow: .minimum, quartiles: false ,color: UIColor(named: "Red") ?? UIColor.systemRed, dash: true)
            
            plotRegressionLine(from: dateRange!.last!.addingTimeInterval(-121*24*3600), priceOption: .low, highorLow: .minimum, color: UIColor(named: "Red") ?? UIColor.systemRed)
        }
        
        if drawRegression {
            plotRegressionLine(priceOption: .close, highorLow: .minimum, color: UIColor.systemBlue)
            
            plotRegressionLine(from: dateRange!.last!.addingTimeInterval(-121*24*3600), priceOption: .close, highorLow: .minimum, color: UIColor.systemBlue, dash: true)
        }
        
        if drawHighs {
            var twoLowPointTrends = validStock.twoLowPointsTrend(priceOption: .high, findOption: .maximum, timeOption: .half)
            drawTrendLine(stock: validStock, trends: twoLowPointTrends, type: .mean, priceOption: .low, highOrLow: .minimum, quartiles: false ,color: UIColor(named: "Green") ?? UIColor.systemGreen)

            twoLowPointTrends = validStock.twoLowPointsTrend(priceOption: .high, findOption: .maximum, timeOption: .quarter)
            drawTrendLine(stock: validStock, trends: twoLowPointTrends, type: .mean, priceOption: .low, highOrLow: .minimum, quartiles: false ,color: UIColor(named: "Green") ?? UIColor.systemGreen, dash: true)
            
            plotRegressionLine(from: dateRange!.last!.addingTimeInterval(-121*24*3600), priceOption: .high, highorLow: .maximum, color: UIColor(named: "Green") ?? UIColor.systemGreen)


        }
    }
    
    public func drawTrendLine(stock: Stock, trends: [StockTrend]? = nil ,type: TrendType, priceOption: PricePointOptions, highOrLow: FindOptions, quartiles: Bool, color: UIColor, from: Date? = nil, to: Date? = nil, dash: Bool? = nil) {
        
        var trendStart = from ?? dateRange!.first!
        let trendEnd = to ?? dateRange!.last!

        let trends = trends ?? stock.findTrends(from: trendStart, to: trendEnd, priceOption: priceOption, findOption: highOrLow)
        
        let trendInfo = stock.trendsAnalysis(trends: trends, type: type, priceOption: priceOption, minOrMax: highOrLow, cutOffQuartiles: quartiles)
        
        if let validIncline = trendInfo?.incline {
                        
            trendStart = max(trendStart, trends.first!.startDate)
            let startPrice = trends.first!.startPrice!
            let projectedPrice = startPrice + validIncline * trendEnd.timeIntervalSince(trendStart)
            let meanTrendLine = UIBezierPath()
            meanTrendLine.move(to: plotPricePoint(pricePoint: PriceDate(trends.first!.startDate, trends.first!.startPrice!)))

            meanTrendLine.addLine(to: plotPricePoint(pricePoint: PriceDate(trendEnd, projectedPrice)))
            meanTrendLine.lineWidth = 2.0
            if from != nil || (dash ?? false) {
                let dashPattern: [CGFloat] = [5,5]
                meanTrendLine.setLineDash(dashPattern, count: dashPattern.count, phase: 0)
            }
            color.setStroke()
            meanTrendLine.stroke()
            
            let increase = (projectedPrice - trends.first!.startPrice!) / trends.first!.startPrice!
            addTrendLabel(price: projectedPrice, increase: increase, color: color)
        }
    }
    
    public func plotRegressionLine(from: Date? = nil, to: Date? = nil, priceOption: PricePointOptions, highorLow: FindOptions, color: UIColor, dash: Bool? = nil) {
        
        guard let validStock = stockToShow else {
            return
        }
        
        let start = from ?? dateRange!.first!
        let end = to ?? dateRange!.last!

        
        if let correlation = validStock.correlationTrend(priceOption: priceOption, minOrMax: highorLow, from: start, end) {
            let a = PriceDate(date:start, price: correlation.yIntercept)
            let b = PriceDate(date:end, price: correlation.yIntercept + correlation.incline * end.timeIntervalSince(start))
            
            let startPoint = plotPricePoint(pricePoint: a)
            let endPoint = plotPricePoint(pricePoint: b)
            
            let regressionLine = UIBezierPath()
            regressionLine.move(to: startPoint)
            regressionLine.addLine(to: endPoint)
            if (dash ?? false) {
                let dashPattern: [CGFloat] = [5,5]
                regressionLine.setLineDash(dashPattern, count: dashPattern.count, phase: 0)
            }

            regressionLine.lineWidth = 2.0
            color.setStroke()
            regressionLine.stroke()
            
            let projectedPrice = correlation.yIntercept + correlation.incline * dateRange!.last!.timeIntervalSince(start)
            let increase = (projectedPrice - correlation.yIntercept) / correlation.yIntercept
            
            addTrendLabel(price: projectedPrice, increase: increase, correlation: correlation.coEfficient, color: color)
        }

    }
    
    private func plotPricePoint(pricePoint: PriceDate) -> CGPoint {
        
        let timeFromEarliest = pricePoint.date.timeIntervalSince(dateRange![0])
        let datePoint: CGFloat = chartOrigin.x + CGFloat(timeFromEarliest / chartTimeSpan) * chartAreaSize.width
        let point: CGFloat = chartOrigin.y - CGFloat((pricePoint.price - minPrice) / (maxPrice - minPrice)) * chartAreaSize.height
        return CGPoint(x: datePoint, y: point)
    }
    
    private func addTrendLabel(price: Double, increase: Double, correlation: Double? = nil, color: UIColor) {
        
        let endPrice$ = currencyFormatter.string(from: NSNumber(value: price))!
        let increase$ = percentFormatter.string(from: NSNumber(value: increase))!
        let endPointY = chartEnd.y + chartAreaSize.height * CGFloat((maxPrice - price) / (maxPrice - minPrice))
        
        var text = " \(endPrice$) (\(increase$)) "
        if let r = correlation {
            text = text + "r=" + numberFormatter.string(from: NSNumber(value: r))! + " "
        }
        
        let newTrendLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.preferredFont(forTextStyle: .subheadline)
            label.textColor = UIColor.white
            label.backgroundColor = color
            label.text = text
            label.sizeToFit()
            var labelY = endPointY - label.frame.height
            if labelY < chartEnd.y { labelY = chartEnd.y + label.frame.height }
            else if labelY > chartOrigin.y {
                labelY = chartOrigin.y - label.frame.height
            }
            label.frame = CGRect(x: chartEnd.x - label.frame.width,
                                   y: labelY,
                                width: label.frame.width,
                                height: label.frame.height)
            trendLabels.forEach { (tLabel) in
                if label.frame.intersects(tLabel.frame) {
                    label.frame = tLabel.frame.offsetBy(dx: 0, dy: tLabel.frame.height)
                }
            }
            return label
        }()
        addSubview(newTrendLabel)
        trendLabels.append(newTrendLabel)

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
