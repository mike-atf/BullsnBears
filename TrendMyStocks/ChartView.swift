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
    var dateFormatter: DateFormatter!
    var currencyFormatter : NumberFormatter!
    
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
    
    var lowTrendLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.textColor = UIColor.white
        label.backgroundColor = UIColor.systemBlue
        return label
    }()

    let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        formatter.minimumIntegerDigits = 1
        return formatter
    }()

    
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
                
        for _ in 0...30 {
            let aLabel: UILabel = {
                let label = UILabel()
                label.font = UIFont.preferredFont(forTextStyle: .footnote)
                self.addSubview(label)
                return label
            }()
            xAxisLabels.append(aLabel)
        }
        
        lowTrendLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(lowTrendLabel)

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
       let yAxisX: CGFloat = rect.width * 0.1
       let yAxisTopY: CGFloat = rect.height * 0.1
       let xAxisY: CGFloat = rect.height * 0.9
       let xAxisEndX: CGFloat = rect.width * 0.9
       let chartAreaHeight = xAxisY - yAxisTopY
       let chartAreaWidth = xAxisEndX - yAxisX
       
       let yAxis = UIBezierPath()
       yAxis.move(to: CGPoint(x: yAxisX, y:yAxisTopY))
       yAxis.addLine(to: CGPoint(x: yAxisX, y: xAxisY))
       yAxis.lineWidth = 2
        UIColor.systemGray.setStroke()
       yAxis.stroke()
       
// x axis
       let xAxis = UIBezierPath()
       xAxis.move(to: CGPoint(x: yAxisX, y: xAxisY))
       xAxis.addLine(to: CGPoint(x: xAxisEndX, y: xAxisY))
       xAxis.lineWidth = 2
       xAxis.stroke()
       
       guard let validStock = stockToShow else { return }
       
       
        var index = 0
        yAxisLabels.forEach { (label) in
            let labelY: CGFloat = yAxisTopY + chartAreaHeight * CGFloat((maxPrice - yAxisNumbers[index]) / (maxPrice - minPrice))
            label.frame.origin = CGPoint(x: xAxisEndX + 15, y: labelY - label.frame.height / 2)
            index += 1
       }
       
        var step: CGFloat = 0
       var xAxisLabelLeft = yAxisX
       xAxisLabels.forEach { (label) in
           label.frame.origin = CGPoint(x: xAxisLabelLeft - label.frame.width / 2, y: xAxisY + 5)
           step += 1
           xAxisLabelLeft += chartAreaWidth / CGFloat(xAxisLabels.count-1)
       }

// candles
        let chartTimeSpan = dateRange!.last!.timeIntervalSince(dateRange!.first!)
        let boxWidth = chartAreaWidth / CGFloat(dateRange!.last!.timeIntervalSince(dateRange!.first!) / (24*3600))
        stockToShow?.dailyPrices.forEach({ (pricePoint) in
            let boxLeft = yAxisX - (boxWidth * 0.8 / 2) + CGFloat(pricePoint.tradingDate.timeIntervalSince(dateRange!.first!) / chartTimeSpan) * chartAreaWidth
            let boxTop = yAxisTopY + chartAreaHeight * (CGFloat((maxPrice - Swift.max(pricePoint.close, pricePoint.open)) / (maxPrice - minPrice)))
            let boxBottom = yAxisTopY + chartAreaHeight * (CGFloat((maxPrice - Swift.min(pricePoint.close, pricePoint.open)) / (maxPrice - minPrice)))
            let boxHeight = boxBottom - boxTop

            let boxRect = CGRect(x: boxLeft, y: boxTop, width: boxWidth * 0.8, height: boxHeight)
            let newBox = UIBezierPath(rect: boxRect)
            let fillColor = pricePoint.close > pricePoint.open ? UIColor(named: "Green")! : UIColor(named: "Red")!
            fillColor.setFill()
            fillColor.setStroke()
            newBox.fill()
            
            let tick = UIBezierPath()
            let highPoint: CGFloat = yAxisTopY + chartAreaHeight * CGFloat((maxPrice - pricePoint.high) / (maxPrice - minPrice))
            let lowPoint: CGFloat = yAxisTopY + chartAreaHeight * CGFloat((maxPrice - pricePoint.low) / (maxPrice - minPrice))
            tick.move(to: CGPoint(x:-1 + boxLeft + boxWidth / 2, y: highPoint))
            tick.addLine(to: CGPoint(x:-1 + boxLeft + boxWidth / 2, y: lowPoint))
            tick.stroke()

        })
        
// lowest points
        let lastPoint: PriceDate = (date: validStock.dailyPrices.last!.tradingDate, price: validStock.dailyPrices.last!.low)
        let lowestPoints = validStock.findLowPoints(10)
        let lowTrendLine = UIBezierPath()
        lowTrendLine.move(to: plotPricePoint(pricePoint: lastPoint, chartSize: CGSize(width: chartAreaWidth, height: chartAreaHeight), chartOrigin: CGPoint(x: yAxisX, y: xAxisY), chartTimeSpan: chartTimeSpan))
        
        lowestPoints.forEach( { (element) in
            let point = plotPricePoint(pricePoint: element, chartSize: CGSize(width: chartAreaWidth, height: chartAreaHeight), chartOrigin: CGPoint(x: yAxisX, y: xAxisY), chartTimeSpan: chartTimeSpan)
            lowTrendLine.addLine(to: point)
        })
        
        UIColor.systemGray.setStroke()
        lowTrendLine.lineWidth = 1.0
        lowTrendLine.stroke()
        
// mean Low Trend
        if let meanTrend = validStock.averageTrend(trends: validStock.lowTrends, cutOffQuartiles: false) {
            let startPointY = yAxisTopY + chartAreaHeight * CGFloat((maxPrice - validStock.dailyPrices.first!.low) / (maxPrice - minPrice))
            let startPointX = yAxisX
            
            let projectedlowPrice = validStock.dailyPrices.first!.low + meanTrend * chartTimeSpan
            let endPointY = yAxisTopY + chartAreaHeight * CGFloat((maxPrice - projectedlowPrice) / (maxPrice - minPrice))
            let endPointX = xAxisEndX
            let meanTrendLine = UIBezierPath()
            meanTrendLine.move(to: CGPoint(x: startPointX, y: startPointY))
            meanTrendLine.addLine(to: CGPoint(x: endPointX, y: endPointY))
            meanTrendLine.lineWidth = 2.0
            UIColor.systemBlue.setStroke()
            meanTrendLine.stroke()
// trendInfo label
            if let trendInfo = validStock.trendInfo(trends: validStock.lowTrends) {
                let endPrice$ = currencyFormatter.string(from: NSNumber(value: trendInfo.endPrice))!
                let increase$ = percentFormatter.string(from: NSNumber(value: trendInfo.pctIncrease))!
                let min$ = percentFormatter.string(from: NSNumber(value: trendInfo.increaseMin))!
                let max$ = percentFormatter.string(from: NSNumber(value: trendInfo.increaseMax))!
                
                let text = " \(endPrice$) ( \(increase$) [\(min$) - \(max$)] "
                lowTrendLabel.text = text
                lowTrendLabel.sizeToFit()
                
                let labelRect = CGRect(x: endPointX - lowTrendLabel.frame.width,
                                       y: endPointY - lowTrendLabel.frame.height,
              width: lowTrendLabel.frame.width,
              height: lowTrendLabel.frame.height)

                lowTrendLabel.frame = labelRect
            }
            
        }
    }
    
    private func plotPricePoint(pricePoint: PriceDate, chartSize: CGSize, chartOrigin: CGPoint, chartTimeSpan: TimeInterval) -> CGPoint {
        
        let timeFromEarliest = pricePoint.date.timeIntervalSince(dateRange![0])
        let datePoint: CGFloat = chartOrigin.x + CGFloat(timeFromEarliest / chartTimeSpan) * chartSize.width
        let point: CGFloat = chartOrigin.y - CGFloat((pricePoint.price - minPrice) / (maxPrice - minPrice)) * chartSize.height
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
