//
//  ValueChart.swift
//  Bulls'N'Bears
//
//  Created by aDav on 21/02/2021.
//

import UIKit

class ValueChart: UIView {

    var valueArray: [Double]?

    var yAxisLabelsRight = [UILabel]()
    var yAxisNumbersRight = [CGFloat]()
    var yAxisLabelMaxWidth: CGFloat = 0.0
    
    var xAxisLabels = [UILabel]()
    var trendLabels = [UILabel]()
    
    var boxes = UIBezierPath()
    
    var lowestValueInRange: Double?
    var highestValueInRange: Double?
    var minValue1 = CGFloat()
    var maxValue1 = CGFloat()
    
    var chartAreaSize = CGSize()
    var chartOrigin = CGPoint()
    var chartEnd = CGPoint()
    
    var valuesTrend: Correlation?
    var growthTrend:Correlation!
    var trendlabel: UILabel?
    var yAxisNumberFormatter: NumberFormatter!
    var valuesAreGrowth: Bool!
    var titleIsLong = true
    var biggerIsBetter = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.systemBackground

    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
                
        self.backgroundColor = UIColor.systemBackground
    }

    
    func configure(array: [Double]?, biggerIsBetter:Bool?=true,trendLabel: UILabel?, longTitle: Bool?=true ,valuesAreGrowth: Bool, valuesAreProportions:Bool? = false, showXLabels: Bool=true, showYLabels: Bool=true, showsXYearLabel: Bool=false, latestDataDate: Date?, altLatestDate: Date?) {
        
        guard array?.count ?? 0 > 0  else {
            return
        }

        self.titleIsLong = longTitle ?? true
        self.biggerIsBetter = biggerIsBetter ?? true
        self.valueArray = array?.reversed() // MT.net row based data are stored in time-DESCENDING order
        self.trendlabel = trendLabel
        trendlabel?.numberOfLines = 0
        self.valuesAreGrowth = valuesAreGrowth
        self.yAxisNumberFormatter = valuesAreGrowth ? percentFormatter0DigitsPositive : numberFormatter2Decimals
        if valuesAreProportions ?? false {
            self.yAxisNumberFormatter = percentFormatter0Digits
        }
        
        // compoundGrowth can return NaN values
        let v1noNaN = valueArray?.filter({ value in
            if value.isNaN { return false }
            else { return true }
        }) ?? []
                
        minValue1 = CGFloat(v1noNaN.min() ?? Double())
        if minValue1 > 0 { minValue1 = 0 }
        maxValue1 = CGFloat(v1noNaN.max() ?? Double())
        
        var mostRecentYear: Int?
        if let validDate = latestDataDate {
            let components: Set<Calendar.Component> = [.year]
    //        let newestMTDataDate = UserDefaults.standard.value(forKey: UserDefaultTerms().newestMTDataDate) as? Date
            let dateComponents = Calendar.current.dateComponents(components, from:  validDate)
            mostRecentYear = dateComponents.year! - 2000
        } else if let validDate = altLatestDate {
            let components: Set<Calendar.Component> = [.year]
    //        let newestMTDataDate = UserDefaults.standard.value(forKey: UserDefaultTerms().newestMTDataDate) as? Date
            let dateComponents = Calendar.current.dateComponents(components, from:  validDate)
            mostRecentYear = dateComponents.year! - 2000 - 1
        }
        
        if showXLabels{
            var count = valueArray?.count ?? 0
            for _ in valueArray ?? [] {
                    let aLabel: UILabel = {
                        let label = UILabel()
                        label.font = UIFont.systemFont(ofSize: 12)
                        label.text = mostRecentYear != nil ? "\(mostRecentYear!-count)" : " "
                        label.textAlignment = .center
                        label.sizeToFit()
                        self.addSubview(label)
                        return label
                    }()
                    xAxisLabels.append(aLabel)
                count -= 1
            }
        }
                
        if showsXYearLabel {
            let dateFormatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.locale = NSLocale.current
                formatter.timeZone = NSTimeZone.local
                formatter.dateFormat = "YYYY"
                return formatter
            }()
            let year$ = dateFormatter.string(from: Date())
            
            let aLabel: UILabel = {
                let label = UILabel()
                label.font = UIFont.systemFont(ofSize: 12)
                label.text = year$
                label.textAlignment = .center
                label.sizeToFit()
                self.addSubview(label)
                return label
            }()
            xAxisLabels.append(aLabel)
        }
        
        if array?.count ?? 0 > 0 && showYLabels {
            findYAxisValuesRight(min: minValue1, max: maxValue1)
        }

        valuesTrend = Calculator.valueChartCorrelation(arrays: [array ?? []])
    }
    
    override func draw(_ rect: CGRect) {
        
        guard valueArray?.count ?? 0 > 0 else {
            return
        }
        
        chartOrigin.x = 0
        chartOrigin.y = 0
        chartEnd.x = rect.width - yAxisLabelMaxWidth - 5
        chartAreaSize.width = chartEnd.x - chartOrigin.x
        
        var value1Range = maxValue1 - minValue1
        if value1Range == 0 {
            value1Range = 1
            maxValue1 = 1
        }
        
        
//xAxisLabels
        let labelSlotWidth = (xAxisLabels.count > 1) ? chartAreaSize.width / CGFloat(xAxisLabels.count) : chartAreaSize.width / CGFloat(valueArray?.count ?? 1)
        var step: CGFloat = 0
        xAxisLabels.forEach { (label) in
            let labelCentreX = chartOrigin.x + labelSlotWidth * step + labelSlotWidth / 2
            label.frame.origin = CGPoint(x: labelCentreX - label.frame.width / 2, y: rect.maxY - label.frame.height)
//            label.center.x = labelCentreX
           step += 1
        }
        
        chartEnd.y = xAxisLabels.first?.frame.minY ?? rect.height - 5
        chartAreaSize.height = chartEnd.y - chartOrigin.y
        let pixPerValue1 = chartAreaSize.height / CGFloat(value1Range)

        var nullAxisY = chartEnd.y
        let horizontalNullLine = UIBezierPath()
        if maxValue1 * minValue1 < 0 { // one of them is positive, the other negative
            nullAxisY = chartOrigin.y + chartAreaSize.height * maxValue1 / value1Range
        } else if (maxValue1 <= 0 && minValue1 < 0) {
            nullAxisY = chartOrigin.y
        }
        horizontalNullLine.move(to: CGPoint(x: chartOrigin.x, y: nullAxisY))
        horizontalNullLine.addLine(to: CGPoint(x: chartEnd.x, y: nullAxisY))
        horizontalNullLine.lineWidth = 1.0
        UIColor.systemGray.setStroke()
        horizontalNullLine.stroke()
        
// Y axis
        let yAxis = UIBezierPath()
        yAxis.move(to: CGPoint(x: chartOrigin.x, y:chartOrigin.y))
        yAxis.addLine(to: CGPoint(x: chartOrigin.x, y: chartEnd.y))
        yAxis.lineWidth = 2
        yAxis.stroke()

// x axis
        let xAxis = UIBezierPath()
        xAxis.move(to: CGPoint(x: chartOrigin.x, y: chartEnd.y))
        xAxis.addLine(to: CGPoint(x: chartEnd.x, y: chartEnd.y))
        xAxis.lineWidth = 2
        xAxis.stroke()

        guard let validValues = valueArray else { return }
        
        guard validValues.count > 0 else {
            return
        }
                
        
// right yAxis labels
        var index = 0
        yAxisLabelsRight.forEach { (label) in
            let labelY = nullAxisY - CGFloat(yAxisNumbersRight[index]) * pixPerValue1
            label.frame.origin = CGPoint(x: rect.maxX - label.frame.width, y: labelY - label.frame.height / 2)
            index += 1
        }
                
// colums
        var valueCount: CGFloat = 0
        var fillColor = UIColor.systemGray4
                
        fillColor.setFill()
        fillColor.setStroke()

        var previousValue = validValues.first!
        validValues.forEach({ (value) in
            let boxLeft = chartOrigin.x + (labelSlotWidth / 2) + labelSlotWidth * valueCount - (labelSlotWidth * 0.8 / 2)
            let boxTop = nullAxisY - CGFloat(value) * pixPerValue1
            let boxBottom = nullAxisY
            let boxHeight = boxBottom - boxTop

            let boxRect = CGRect(x: boxLeft, y: boxTop, width: labelSlotWidth * 0.8, height: boxHeight)
            let newBox = UIBezierPath(rect: boxRect)
            if biggerIsBetter {
                fillColor = (previousValue < value) ? UIColor(named: "Green")! : UIColor(named: "Red")!
            }
            else {
                fillColor = (previousValue > value) ? UIColor(named: "Green")! : UIColor(named: "Red")!
            }
            fillColor.setFill()
            newBox.fill()
            
            previousValue = value
            valueCount += 1
        })
        
        // growth trend line
                        
        //MARK: - Values trend
        if valuesTrend != nil {
            let trendLine = UIBezierPath()
            
            let pixPerValue = pixPerValue1

            let trendLineStartY = nullAxisY - CGFloat(valuesTrend!.yIntercept) * pixPerValue
            let trendLineEndY = nullAxisY - CGFloat(valuesTrend!.endValue(for: Double(xAxisLabels.count))) * pixPerValue // -
            trendLine.move(to: CGPoint(x: chartOrigin.x, y: trendLineStartY))
            trendLine.addLine(to: CGPoint(x: chartEnd.x, y: trendLineEndY))
            trendLine.lineWidth = 1.5
            let dashPattern:[CGFloat] = [3,7]
            trendLine.setLineDash(dashPattern, count: dashPattern.count, phase: 0)
            UIColor.label.setStroke()
            trendLine.stroke()
            
            // Label above chart
            var r2$ = "-"
            var growthEMA$ = String() // correlation incline based
            var meanChangeOfGrowth$ = String() // correlation incline based
            let r2 = valuesTrend!.r2()
            let rates = valuesAreGrowth ? valueArray!.reversed().filter({ (element) -> Bool in
                if element != 0.0 { return true }
                else { return false }
            }) : valueArray!.reversed().growthRates()
            
            if let ema = rates?.ema(periods: 7) {
                //calculates changes of growth rates yoy then ema
                if r2 != nil{
                    r2$ = percentFormatter0Digits.string(from: r2! as NSNumber) ?? ""
                }
                growthEMA$ = valuesAreGrowth ? "EMA: " + (percentFormatter0DigitsPositive.string(from: ema as NSNumber) ?? "-") : ""
                meanChangeOfGrowth$ = valuesAreGrowth ? "Compound growth trend " + (percentFormatter0Digits.string(from: valuesTrend!.incline as NSNumber) ?? "-") + " to " : ""
            }
            
            if titleIsLong {
                trendlabel?.setAttributedTextWithSuperscripts(text: "R2: \(r2$) \(meanChangeOfGrowth$) \(growthEMA$)", indicesOfSuperscripts: [1])
            }
            else {
                trendlabel?.setAttributedTextWithSuperscripts(text: "R2: \(r2$), \(growthEMA$)", indicesOfSuperscripts: [1])
            }
            trendlabel?.sizeToFit()
        }

    }
    
    private func findYAxisValuesRight(min: CGFloat, max: CGFloat) {
        
        guard valueArray?.count ?? 0 > 0 else {
            return
        }
                
        let options:[CGFloat] = [0.01, 0.025, 0.05, 0.1, 0.25, 0.5,1.0, 2.0,2.5,5.0,10.0,20.0,25.0,50.0,100.0,150.0,200.0,250.0,500.0,1000.0, 5000.0,10000.0, 50000.0,100000.0]
        let range = max - min
        
        var count: CGFloat = 100.0
        var index = -1
        repeat {
            index += 1
            count = range / options[index]
        } while count > 6
        
        let step = options[index]
        
        yAxisLabelsRight.removeAll()
        yAxisNumbersRight.removeAll()
        var labelValue = CGFloat(Int(maxValue1 / step)) * step
        
        var lastLetter: String?
        var factor: CGFloat = 1.0
        if labelValue > 1000000000 {
            lastLetter = "B"
            factor = 1000000000
        } else if labelValue > 1000000 {
            lastLetter = "M"
            factor = 1000000
        }
        else if labelValue > 1000 {
            lastLetter = "K"
            factor = 1000
        }
        
        while labelValue >= minValue1 {
            let newLabel: UILabel = {
                let label = UILabel()
                label.font = UIFont.systemFont(ofSize: 12)
                label.textColor = UIColor.label
                label.textAlignment = .right
                label.text = (yAxisNumberFormatter.string(from: (labelValue / factor) as NSNumber) ?? "") + (lastLetter ?? "")
                label.sizeToFit()
                if label.frame.width > yAxisLabelMaxWidth {
                    yAxisLabelMaxWidth = label.frame.width
                }
                self.addSubview(label)
                return label
            }()
            yAxisLabelsRight.append(newLabel)
            yAxisNumbersRight.append(labelValue)
            labelValue -= step
        }
    }
    
    /*
    private func findYAxisValuesLeft(min: CGFloat, max: CGFloat) {
        
        guard valueArray2?.count ?? 0 > 0 else {
            return
        }

        
        let options:[CGFloat] = [0.01, 0.05, 0.1, 0.25, 0.5, 1.0,2.0,2.5,5.0,10.0,20.0,25.0,50.0,100.0,150.0,200.0,250.0,500.0,1000.0, 5000.0,10000.0, 50000.0,100000.0,250000.0, 500000.0,1000000.0]
        let range = max - min
        
        var count: CGFloat = 100.0
        var index = -1
        repeat {
            index += 1
            count = range / options[index]
        } while count > 6
        
        let step = options[index]
        
        yAxisLabelsLeft.removeAll()
        yAxisNumbersLeft.removeAll()
        var labelValue = CGFloat(Int(maxValue2 / step)) * step
        
        var lastLetter: String?
        var factor: CGFloat = 1.0
        if labelValue > 1000000000 {
            lastLetter = "B"
            factor = 1000000000
        } else if labelValue > 1000000 {
            lastLetter = "M"
            factor = 1000000
        }
        else if labelValue > 1000 {
            lastLetter = "K"
            factor = 1000
        }
        
        while labelValue >= minValue2 {
            let newLabel: UILabel = {
                let label = UILabel()
                label.font = UIFont.systemFont(ofSize: 12)
                label.textColor = UIColor.systemYellow
                label.textAlignment = .right
                label.text = (percentFormatter0Digits.string(from: (labelValue / factor) as NSNumber) ?? "") + (lastLetter ?? "")
                label.sizeToFit()
                self.addSubview(label)
                return label
            }()
            yAxisLabelsLeft.append(newLabel)
            yAxisNumbersLeft.append(labelValue)
            labelValue -= step
        }
    }
     */
}
