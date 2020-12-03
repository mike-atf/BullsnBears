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
    var xAxisLabels = [UILabel]()
    var dateFormatter: DateFormatter!
    var currencyFormatter : NumberFormatter!
    
    var stockToShow: Stock? {
        didSet {
            setNeedsDisplay()
        }
    }
    var lowestPriceInRange: Double?
    var highestPriceInRange: Double?
    var dateRange: [Date]?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configure()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
//         widthConstraint.isActive = false
//         contentWidthConstraint = contentView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0, constant: 0)
//         contentWidthConstraint.isActive = true
        
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
        
        for _ in 0...10 {
            let newLabel: UILabel = {
                let label = UILabel()
                label.font = UIFont.preferredFont(forTextStyle: .footnote)
                label.textAlignment = .right
                self.addSubview(label)
                return label
            }()
            yAxisLabels.append(newLabel)
            
            let aLabel: UILabel = {
                let label = UILabel()
                label.font = UIFont.preferredFont(forTextStyle: .footnote)
                self.addSubview(label)
                return label
            }()
            xAxisLabels.append(aLabel)
        }

        configure()
    }
    
    public func configure() {

        guard let validStock = stockToShow else { return }

        lowestPriceInRange = validStock.lowestPrice()
        highestPriceInRange = validStock.highestPrice()
        dateRange = validStock.priceDateRange()
        
        guard lowestPriceInRange != nil else { return }
        guard highestPriceInRange != nil else { return }
        guard dateRange != nil else { return }
        
        let minPrice = lowestPriceInRange! * 0.8
        let maxPrice = highestPriceInRange! * 1.2
        let step = (maxPrice - minPrice) / Double(xAxisLabels.count-1)
        
        var count: Double = 0
        yAxisLabels.forEach { (label) in
            label.text = currencyFormatter.string(from: NSNumber(value: maxPrice - count * step))
            label.sizeToFit()
            count += 1
        }
        
        let timeInterval = dateRange![1].timeIntervalSince(dateRange![0])
        count = 0
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
        UIColor.darkText.setStroke()
        yAxis.stroke()
        
        // x axis
        let xAxis = UIBezierPath()
        xAxis.move(to: CGPoint(x: yAxisX, y: xAxisY))
        xAxis.addLine(to: CGPoint(x: xAxisEndX, y: xAxisY))
        xAxis.lineWidth = 2
        xAxis.stroke()
        
        guard let validStock = stockToShow else { return }
        
        var yAxisLabelTop = yAxisTopY
        var step: CGFloat = 0
        yAxisLabels.forEach { (label) in
            label.frame.origin = CGPoint(x: xAxisEndX + 5, y: yAxisLabelTop - label.frame.height / 2)
            step += 1
            yAxisLabelTop += chartAreaHeight / CGFloat(yAxisLabels.count-1)
        }
        
        step = 0
        var xAxisLabelLeft = yAxisX
        xAxisLabels.forEach { (label) in
            label.frame.origin = CGPoint(x: xAxisLabelLeft - label.frame.width / 2, y: xAxisY + 5)
            step += 1
            xAxisLabelLeft += chartAreaWidth / CGFloat(xAxisLabels.count-1)
        }

        
                        
    }

}
