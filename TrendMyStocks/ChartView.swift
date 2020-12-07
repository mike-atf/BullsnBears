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
//    var trendLabels = [UILabel]()
    
    var dateFormatter: DateFormatter!
    var currencyFormatter : NumberFormatter!
    var percentFormatter: NumberFormatter!

    var candleBoxes = UIBezierPath()
    var candleSticks = UIBezierPath()
    
    var stockToShow: Stock? {
        didSet {
            configure()
        }
    }
    
    var lowestPriceInRange: Double?
    var highestPriceInRange: Double?
    var minPrice = Double()
    var maxPrice = Double()
    var dateRange: [Date]?
    
    var chartAreaSize = CGSize()
    var chartOrigin = CGPoint()
    var chartEnd = CGPoint()
    
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
    
    public func configure() {

        guard let validStock = stockToShow else { return }

        lowestPriceInRange = validStock.lowestPrice()
        highestPriceInRange = validStock.highestPrice()
        dateRange = validStock.priceDateRange()
        dateRange![1] = dateRange!.last!.addingTimeInterval(30*24*3600)
        
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
                
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
                
// Y axis
       chartOrigin.x = rect.width * 0.1
        chartEnd.y = rect.height * 0.1
       chartOrigin.y = rect.height * 0.9
        chartEnd.x = rect.width * 0.9
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
        let chartTimeSpan = dateRange!.last!.timeIntervalSince(dateRange!.first!)
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
        let lastPoint: PriceDate = (date: validStock.dailyPrices.last!.tradingDate, price: validStock.dailyPrices.last!.low)
        let lowestPoints = validStock.findPricePoints(10, priceOption: .low, findOption: .minimum)
//        let lowestPoints = validStock.findLowPoints(10, priceOption: .low)
        let lowTrendLine = UIBezierPath()
        lowTrendLine.move(to: plotPricePoint(pricePoint: lastPoint, chartOrigin: CGPoint(x: chartOrigin.x, y: chartOrigin.y), chartTimeSpan: chartTimeSpan))
        
        lowestPoints.forEach( { (element) in
            let point = plotPricePoint(pricePoint: element, chartOrigin: chartOrigin, chartTimeSpan: chartTimeSpan)
            lowTrendLine.addLine(to: point)
        })
        
        UIColor.systemGray.setStroke()
        lowTrendLine.lineWidth = 1.0
        lowTrendLine.stroke()
        
        
        meanTrendLine(stock: validStock, trend: validStock.findTrends(30, priceOption: .low, findOption: .minimum), chartOrigin: chartOrigin, chartEnd: chartEnd, chartTimeSpan: chartTimeSpan)
        
        
        meanTrendLine(stock: validStock, trend: validStock.findTrends(30, priceOption: .high, findOption: .maximum), chartOrigin: chartOrigin, chartEnd: chartEnd, chartTimeSpan: chartTimeSpan)

    }
    
    private func meanTrendLine(stock: Stock, trend: [StockTrend], chartOrigin: CGPoint, chartEnd: CGPoint, chartTimeSpan: TimeInterval) {
        
        // mean Low Trend
        if let meanTrend = stock.averageTrend(trends: trend) {
            let startPointY = chartEnd.y + chartAreaSize.height * CGFloat((maxPrice - stock.dailyPrices.first!.low) / (maxPrice - minPrice))
            
            let projectedlowPrice = stock.dailyPrices.first!.low + meanTrend * chartTimeSpan
            let endPointY = chartEnd.y + chartAreaSize.height * CGFloat((maxPrice - projectedlowPrice) / (maxPrice - minPrice))
            let meanTrendLine = UIBezierPath()
            meanTrendLine.move(to: CGPoint(x: chartOrigin.x, y: startPointY))
            meanTrendLine.addLine(to: CGPoint(x: chartEnd.x, y: endPointY))
            meanTrendLine.lineWidth = 2.0
            UIColor.systemBlue.setStroke()
            meanTrendLine.stroke()
            
            // trendInfo label
            if let trendInfo = stock.trendInfo(trends: trend) {
                let endPrice$ = currencyFormatter.string(from: NSNumber(value: trendInfo.endPrice))!
                let increase$ = percentFormatter.string(from: NSNumber(value: trendInfo.pctIncrease))!
                let min$ = percentFormatter.string(from: NSNumber(value: trendInfo.increaseMin))!
                let max$ = percentFormatter.string(from: NSNumber(value: trendInfo.increaseMax))!
                
                let text = " \(endPrice$) ( \(increase$) [\(min$) - \(max$)]) "
                let newTrendLabel: UILabel = {
                    let label = UILabel()
                    label.font = UIFont.preferredFont(forTextStyle: .caption1)
                    label.textColor = UIColor.white
                    label.backgroundColor = UIColor.systemBlue
                    label.text = text
                    label.sizeToFit()
                    label.frame = CGRect(x: chartEnd.x - label.frame.width,
                                           y: endPointY - label.frame.height,
                                        width: label.frame.width,
                                        height: label.frame.height)
                   return label
                }()
                addSubview(newTrendLabel)
                
            }
        }
    }
    
    private func plotPricePoint(pricePoint: PriceDate, chartOrigin: CGPoint, chartTimeSpan: TimeInterval) -> CGPoint {
        
        let timeFromEarliest = pricePoint.date.timeIntervalSince(dateRange![0])
        let datePoint: CGFloat = chartOrigin.x + CGFloat(timeFromEarliest / chartTimeSpan) * chartAreaSize.width
        let point: CGFloat = chartOrigin.y - CGFloat((pricePoint.price - minPrice) / (maxPrice - minPrice)) * chartAreaSize.height
        return CGPoint(x: datePoint, y: point)
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
