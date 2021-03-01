//
//  ValueChart.swift
//  Bulls'N'Bears
//
//  Created by aDav on 21/02/2021.
//

import UIKit

class ValueChart: UIView {

    var valueArray1: [Double]?
    var valueArray2: [Double]?

    var yAxisLabelsRight = [UILabel]()
    var yAxisNumbersRight = [CGFloat]()
//    var yAxisLabelsRightMaxWidth = CGFloat()

    var yAxisLabelsLeft = [UILabel]()
    var yAxisNumbersLeft = [CGFloat]()
//    var yAxisLabelsLeftMaxWidth = CGFloat()
    
    var xAxisLabels = [UILabel]()
    var trendLabels = [UILabel]()
//    var valuationLabels = [UILabel]()
    
    var boxes = UIBezierPath()
    
    var lowestValueInRange: Double?
    var highestValueInRange: Double?
    var minValue1 = CGFloat()
    var maxValue1 = CGFloat()
    
    var minValue2 = CGFloat()
    var maxValue2 = CGFloat()

    var chartAreaSize = CGSize()
    var chartOrigin = CGPoint()
    var chartEnd = CGPoint()
    
    var trend:Correlation!
    var trendlabel: UILabel!
    
    /// 1st array will be bar chart
    /// 2nd array (optional) will line chart
    /// both should have some number of elements, otherwise, the second array will be brought to same size
    func configure(array1: [Double]?, array2: [Double]?, trendLabel: UILabel) {
        
//        self.backgroundColor = UIColor.systemTeal
        
        guard array1?.count ?? 0 > 0 || array2?.count ?? 0 > 0 else {
            return
        }

        self.valueArray1 = array1?.reversed()
        self.valueArray2 = array2?.reversed()
        self.trendlabel = trendLabel
        
        if let secondArray = array2 {
            if secondArray.count > valueArray1?.count ?? 0 {
                valueArray2 = Array(secondArray[...(valueArray1?.count ?? 0)])
            }
            else if secondArray.count < valueArray1?.count ?? 0 {
                for _ in secondArray.count..<(valueArray1?.count ?? 0) {
//                    valueArray2?.append(Double())
                    valueArray2?.insert(Double(), at: 0)
                }
            }
        }

        minValue1 = CGFloat(valueArray1?.min() ?? Double())
        if minValue1 > 0 { minValue1 = 0 }
        maxValue1 = CGFloat(valueArray1?.max() ?? Double())

        minValue2 = CGFloat(valueArray2?.min() ?? Double())
        if minValue2 > 0 { minValue2 = 0 }
        maxValue2 = CGFloat(valueArray2?.max() ?? Double())
        
        var proportion1: CGFloat?
        var proportion2: CGFloat?
        if maxValue1 > 0 && minValue1 < 0 {
            // null axis != xAxis
            proportion1 = minValue1 / maxValue1
        }
        if maxValue2 > 0 && minValue2 < 0 {
            // null axis != xAxis
            proportion2 = minValue2 / maxValue2
        }
        
        if proportion2 != nil  && proportion1 != nil {
            minValue1 = maxValue1 * min(abs(proportion1!), abs(proportion2!))
            minValue2 = maxValue2 * min(abs(proportion1!), abs(proportion2!))
        }
        else if proportion2 != nil {
            if minValue1 >= 0 && maxValue1 > 0 {
                minValue1 = maxValue1 * proportion2!
            } else {
                maxValue1 = minValue1 / proportion2!
            }
        }
        else if proportion1 != nil {
            minValue2 = maxValue2 * proportion1!
        }

        let components: Set<Calendar.Component> = [.year]
        let dateComponents = Calendar.current.dateComponents(components, from: Date())
        let mostRecentYear = dateComponents.year! - 2000
        
        var count = valueArray1?.count ?? 0
        for _ in valueArray1 ?? [] {
                let aLabel: UILabel = {
                    let label = UILabel()
                    label.font = UIFont.systemFont(ofSize: 12)
                    label.text = "\(mostRecentYear-count)"
                    label.sizeToFit()
                    self.addSubview(label)
                    return label
                }()
                xAxisLabels.append(aLabel)
            count -= 1
        }
        
        if array1?.count ?? 0 > 0 {
            findYAxisValuesRight(min: minValue1, max: maxValue1)
        }
        if array2?.count ?? 0 > 0 {
            findYAxisValuesLeft(min: minValue2, max: maxValue2)
        }
        
        
        if array2?.count ?? 0 > 1 {
            // proportions - calculate trend of proportions
            
//            let array1NoEmpties = array2?.filter({ (element) -> Bool in
//                if element == Double() { return false }
//                else { return true }
//            }) ?? []
            var years = [Double]()
            var count = 1.0 // important to avoid dropping 0 element in correlation
            for _ in array2! {
                years.append(count)
                count += 1.0
            }

            trend = Calculator.correlation(xArray: years, yArray: array2?.reversed())
        } else if array1?.count ?? 0 > 1 {
            // values only, no proportions - calculate values trend
            
//            let array1NoEmpties = array1?.filter({ (element) -> Bool in
//                if element == Double() { return false }
//                else { return true }
//            }) ?? []
            var years = [Double]()
            var count = 1.0 // important to avoid dropping 0 element in correlation
            for _ in array1! {
                years.append(count)
                count += 1.0
            }

            trend = Calculator.correlation(xArray: years, yArray: array1?.reversed())
        }
    }
    
    override func draw(_ rect: CGRect) {
        
        guard valueArray1?.count ?? 0 > 0 || valueArray2?.count ?? 0 > 0 else {
            return
        }
        
        chartOrigin.x = rect.width * 0.15
        chartOrigin.y = 10.0
        chartEnd.x = rect.width * 0.87
        chartAreaSize.width = chartEnd.x - chartOrigin.x
        
        var value1Range = maxValue1 - minValue1
        if value1Range == 0 {
            value1Range = 1
            maxValue1 = 1
        }
        
        
//xAxisLabels
        let labelSlotWidth = chartAreaSize.width / CGFloat(xAxisLabels.count)
        var step: CGFloat = 1
        xAxisLabels.forEach { (label) in
            let labelLeft = chartOrigin.x + labelSlotWidth * step - label.frame.width / 2 //+ (step / CGFloat(validValues.count)) * chartAreaSize.width
            label.frame.origin = CGPoint(x: labelLeft - label.frame.width / 2, y: rect.maxY - label.frame.height)
           step += 1
        }
        
        chartEnd.y = xAxisLabels.first!.frame.minY - 5
        chartAreaSize.height = chartEnd.y - chartOrigin.y
        let pixPerValue1 = chartAreaSize.height / CGFloat(value1Range)

        var nullAxisY = chartEnd.y
        var horizontalNullLine: UIBezierPath?
        if (maxValue1 > 0 && minValue1 < 0) {
        // max1 and min1 have been adapted to reflect max2 and min2 in configure()
            nullAxisY = chartOrigin.y + chartAreaSize.height * maxValue1 / value1Range
            horizontalNullLine = UIBezierPath()
            horizontalNullLine?.move(to: CGPoint(x: chartOrigin.x, y: nullAxisY))
            horizontalNullLine?.addLine(to: CGPoint(x: chartEnd.x, y: nullAxisY))
            horizontalNullLine?.lineWidth = 1.2
        }
        else if (maxValue2 > 0 && minValue2 < 0) {
            nullAxisY = chartOrigin.y + chartAreaSize.height * maxValue2 / (maxValue2 - minValue2)
            horizontalNullLine = UIBezierPath()
            horizontalNullLine?.move(to: CGPoint(x: chartOrigin.x, y: nullAxisY))
            horizontalNullLine?.addLine(to: CGPoint(x: chartEnd.x, y: nullAxisY))
            horizontalNullLine?.lineWidth = 1.2

        }
        
// Y axis
        let yAxis = UIBezierPath()
        yAxis.move(to: CGPoint(x: chartOrigin.x, y:chartOrigin.y))
        yAxis.addLine(to: CGPoint(x: chartOrigin.x, y: chartEnd.y))
        yAxis.lineWidth = 2
        UIColor.systemGray.setStroke()
        yAxis.stroke()

// x axis
        let xAxis = UIBezierPath()
        xAxis.move(to: CGPoint(x: chartOrigin.x, y: chartEnd.y))
        xAxis.addLine(to: CGPoint(x: chartEnd.x, y: chartEnd.y))
        xAxis.lineWidth = 2
        xAxis.stroke()

        guard let validValues = valueArray1 else { return }
        
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
//        let boxWidth = chartAreaSize.width / CGFloat(validValues.count + 1)
        
        var valueCount: CGFloat = 0
        let fillColor = UIColor.systemGray4
                
        fillColor.setFill()
        fillColor.setStroke()

        validValues.forEach({ (value) in
//            let boxLeft = chartOrigin.x + (boxWidth * 0.8 / 2) + (valueCount / CGFloat(validValues.count)) * chartAreaSize.width
            let boxLeft = chartOrigin.x + (labelSlotWidth / 2) + labelSlotWidth * valueCount - (labelSlotWidth * 0.8 / 2)
            let boxTop = nullAxisY - CGFloat(value) * pixPerValue1 //chartEnd.y - chartAreaSize.height * CGFloat(value) / maxValue1
            let boxBottom = nullAxisY
            let boxHeight = boxBottom - boxTop

            let boxRect = CGRect(x: boxLeft, y: boxTop, width: labelSlotWidth * 0.8, height: boxHeight)
            let newBox = UIBezierPath(rect: boxRect)
            newBox.fill()

            valueCount += 1
        })
        
// growthline
        
        var value2Range = maxValue2 - minValue2
        if value2Range == 0 {
            value2Range = 1
            maxValue2 = 1
        }
        let pixPerValue2 = chartAreaSize.height / CGFloat(value2Range)

        
        if let secondValues = valueArray2 {
            index = 0

// left yAxis labels
            yAxisLabelsLeft.forEach { (label) in
                let labelY = nullAxisY - CGFloat(yAxisNumbersLeft[index]) * pixPerValue2
                label.frame.origin = CGPoint(x: rect.minX , y: labelY - label.frame.height / 2)
                index += 1
            }

            let linePath = UIBezierPath()
            let lineStartX = chartOrigin.x + labelSlotWidth / 2
            let lineStartY = nullAxisY - CGFloat(secondValues.first!) * pixPerValue2
            linePath.move(to: CGPoint(x: lineStartX, y: lineStartY))

// growth line graph
            valueCount = 0
            secondValues.forEach({ (value) in
                if value != Double() {
                    let lineX = chartOrigin.x + labelSlotWidth / 2 + labelSlotWidth * valueCount
                    let lineY = nullAxisY - CGFloat(value) * pixPerValue2
                    linePath.addLine(to: CGPoint(x: lineX, y: lineY))
                }
                valueCount += 1
            })

            UIColor.label.setStroke()
            UIColor.systemOrange.setStroke()
            linePath.lineWidth = 2.5
            linePath.stroke()
        }
        
//Trend
        if trend != nil {
            let trendLine = UIBezierPath()
            
//            let maxValue = (valueArray2?.count ?? 0 > 0) ? maxValue2 : maxValue1
            let pixPerValue = (valueArray2?.count ?? 0 > 0) ? pixPerValue2 : pixPerValue1

            let trendLineStartY = nullAxisY - CGFloat(trend.yIntercept) * pixPerValue
            let trendLineEndY = nullAxisY - CGFloat(trend.endValue(for: Double(xAxisLabels.count))) * pixPerValue
            
            trendLine.move(to: CGPoint(x: chartOrigin.x, y: trendLineStartY))
            trendLine.addLine(to: CGPoint(x: chartEnd.x, y: trendLineEndY))
            trendLine.lineWidth = 1.5
            let dashPattern:[CGFloat] = [3,7]
            trendLine.setLineDash(dashPattern, count: dashPattern.count, phase: 0)
            UIColor.label.setStroke()
            trendLine.stroke()
            
            UIColor.lightGray.setStroke()
            horizontalNullLine?.stroke()
            
            var r2$ = String()
            var growth$ = String()
            let r2 = trend.r2()
            let growth = trend.meanGrowth(for: Double(xAxisLabels.count))
            if r2 != nil{
                r2$ = percentFormatter0Digits.string(from: r2! as NSNumber) ?? ""
                if r2! > 0.64 {
                    growth$ = percentFormatter0DigitsPositive.string(from: growth as NSNumber) ?? ""
                }
                else {
                    growth$ = "high volatility (" + (percentFormatter0DigitsPositive.string(from: growth as NSNumber) ?? "") + ")"
                }
            }
                        
            trendlabel.font = UIFont.preferredFont(forTextStyle: .footnote)
            trendlabel.numberOfLines = 0

            trendlabel.setAttributedTextWithSuperscripts(text: "R2: \(r2$)  -  Avg. growth pa.: \(growth$)", indicesOfSuperscripts: [1])
            trendlabel.sizeToFit()
            
        }
    }
    
    private func findYAxisValuesRight(min: CGFloat, max: CGFloat) {
        
        guard valueArray1?.count ?? 0 > 0 else {
            return
        }
                
        let options:[CGFloat] = [2.0,2.5,5.0,10.0,20.0,25.0,50.0,100.0,150.0,200.0,250.0,500.0,1000.0, 5000.0,10000.0, 50000.0,100000.0]
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
                label.textColor = UIColor.systemGray
                label.textAlignment = .right
                label.text = (numberFormatterDecimals.string(from: (labelValue / factor) as NSNumber) ?? "") + (lastLetter ?? "")
                label.sizeToFit()
                self.addSubview(label)
                return label
            }()
            yAxisLabelsRight.append(newLabel)
            yAxisNumbersRight.append(labelValue)
            labelValue -= step
        }
    }
    
    private func findYAxisValuesLeft(min: CGFloat, max: CGFloat) {
        
        guard valueArray2?.count ?? 0 > 0 else {
            return
        }

        
        let options:[CGFloat] = [0.01, 0.05, 0.1, 0.25, 0.5, 1.0,2.0,2.5,5.0,10.0,20.0,25.0,50.0,100.0,150.0,200.0,250.0,500.0,1000.0, 5000.0,10000.0, 50000.0,100000.0]
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
}
