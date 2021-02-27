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
    
    var yAxisLabelsLeft = [UILabel]()
    var yAxisNumbersLeft = [CGFloat]()
    
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
    
    var trendsToShow = [TrendProperties]()
    
    /// 1st array will be bar chart
    /// 2nd array (optional) will line chart
    /// both should have some number of elements, otherwise, the second array will be brought to same size
    func configure(array1: [Double]?, array2: [Double]?) {
        
        guard array1?.count ?? 0 > 0 || array2?.count ?? 0 > 0 else {
            return
        }

        self.valueArray1 = array1?.reversed()
        self.valueArray2 = array2?.reversed()
        
        if let secondArray = array2 {
            if secondArray.count > valueArray1?.count ?? 0 {
                valueArray2 = Array(secondArray[...(valueArray1?.count ?? 0)])
            }
            else if secondArray.count < valueArray1?.count ?? 0 {
                for _ in secondArray.count..<(valueArray1?.count ?? 0) {
                    valueArray2?.append(Double())
                }
            }
        }

        minValue1 = CGFloat(valueArray1?.min() ?? Double())
        maxValue1 = CGFloat(valueArray1?.max() ?? Double())

        minValue2 = CGFloat(valueArray2?.min() ?? Double())
        maxValue2 = CGFloat(valueArray2?.max() ?? Double())
        
        if maxValue1 > 0 && minValue1 < 0 {
            // null axis != xAxis
            let proportion = minValue1 / maxValue1
            minValue2 = maxValue2 * proportion
        } else if maxValue2 > 0 && minValue2 < 0 {
            // null axis != xAxis
            let proportion = minValue2 / maxValue2
            minValue1 = maxValue1 * proportion
        }

        let components: Set<Calendar.Component> = [.year]
        let dateComponents = Calendar.current.dateComponents(components, from: Date())
        let mostRecentYear = dateComponents.year! - 2000
        
        var count = valueArray1?.count ?? 0
        for _ in valueArray1 ?? [] {
                let aLabel: UILabel = {
                    let label = UILabel()
                    label.font = UIFont.preferredFont(forTextStyle: .footnote)
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
    }
    
    override func draw(_ rect: CGRect) {

// Y axis
        chartOrigin.x = rect.width * 0.13
        chartEnd.y = rect.height * 0.05
        chartOrigin.y = rect.height * 0.95
        chartEnd.x = rect.width * 0.87
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

        guard let validValues = valueArray1 else { return }
        
        guard validValues.count > 0 else {
            return
        }
        
//        guard maxValue1 > minValue1 else {
//            return
//        }
        
        var value1Range = maxValue1 - minValue1
        if value1Range == 0 {
            value1Range = 1
            maxValue1 = 1
        }
        
        var value2Range = maxValue2 - minValue2
        if value2Range == 0 {
            value2Range = 1
            maxValue2 = 1
        }

        
        var nullAxisY = chartOrigin.y
        var horizontalNullLine: UIBezierPath?
        if maxValue1 > 0 && minValue1 < 0 {
            nullAxisY = chartEnd.y + chartAreaSize.height * maxValue1 / value1Range
            horizontalNullLine = UIBezierPath()
            horizontalNullLine?.move(to: CGPoint(x: chartOrigin.x, y: nullAxisY))
            horizontalNullLine?.addLine(to: CGPoint(x: chartEnd.x, y: nullAxisY))
            horizontalNullLine?.lineWidth = 1.2
        }

        var index = 0
        yAxisLabelsRight.forEach { (label) in
            let labelY: CGFloat = chartEnd.y + chartAreaSize.height * (maxValue1 - CGFloat(yAxisNumbersRight[index])) / value1Range
            label.frame.origin = CGPoint(x: rect.maxX - 5 - label.frame.width, y: labelY - label.frame.height / 2)
            index += 1
        }
        

        let labelSlotWidth = chartAreaSize.width / CGFloat(xAxisLabels.count)
        var step: CGFloat = 1
        xAxisLabels.forEach { (label) in
            let labelLeft = chartOrigin.x + labelSlotWidth * step - label.frame.width / 2 //+ (step / CGFloat(validValues.count)) * chartAreaSize.width
           label.frame.origin = CGPoint(x: labelLeft - label.frame.width / 2, y: chartOrigin.y + 5)
           step += 1
        }
        
// colums
        
        let boxWidth = chartAreaSize.width / CGFloat(validValues.count + 1)
        
//        var valueRange = CGFloat(value1Range)
        
        var valueCount: CGFloat = 0
        let fillColor = UIColor.darkGray
                
        fillColor.setFill()
        fillColor.setStroke()

        validValues.forEach({ (value) in
            let boxLeft = chartOrigin.x + (boxWidth * 0.8 / 2) + (valueCount / CGFloat(validValues.count)) * chartAreaSize.width
            let boxTop = chartEnd.y + chartAreaSize.height * (maxValue1 - CGFloat(value)) / value1Range
            let boxBottom = nullAxisY
            let boxHeight = boxBottom - boxTop

            let boxRect = CGRect(x: boxLeft, y: boxTop, width: boxWidth * 0.8, height: boxHeight)
            let newBox = UIBezierPath(rect: boxRect)
            newBox.fill()

            valueCount += 1
        })
        
        guard let secondValues = valueArray2 else {
            UIColor.lightGray.setStroke()
            horizontalNullLine?.stroke()
            return
        }
//        guard minValue2 < maxValue2 else {
//            UIColor.lightGray.setStroke()
//            horizontalNullLine?.stroke()
//            return
//        }
        
        index = 0
        yAxisLabelsLeft.forEach { (label) in
            let labelY: CGFloat = chartEnd.y + chartAreaSize.height * (maxValue2 - CGFloat(yAxisNumbersLeft[index])) / value2Range
            label.frame.origin = CGPoint(x: rect.minX + 5 , y: labelY - label.frame.height / 2)
            index += 1
        }

//        valueRange = CGFloat(value2Range)
        
        let linePath = UIBezierPath()
        let lineStartX = chartOrigin.x + labelSlotWidth / 2
        let lineStartY = chartEnd.y + chartAreaSize.height * (maxValue2 - CGFloat(secondValues.first!)) / value2Range
        linePath.move(to: CGPoint(x: lineStartX, y: lineStartY))

        valueCount = 1
        secondValues.forEach({ (value) in

            let lineX = chartOrigin.x + labelSlotWidth * valueCount - labelSlotWidth / 2
            let lineY = chartEnd.y + chartAreaSize.height * (maxValue2 - CGFloat(value)) / value2Range
            linePath.addLine(to: CGPoint(x: lineX, y: lineY))

            valueCount += 1
        })

        UIColor.label.setStroke()
        UIColor.systemOrange.setStroke()
        linePath.lineWidth = 2.5
        linePath.stroke()
        
        UIColor.lightGray.setStroke()
        horizontalNullLine?.stroke()
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
                label.font = UIFont.preferredFont(forTextStyle: .footnote)
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
        } while count > 11.0
        
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
                label.font = UIFont.preferredFont(forTextStyle: .footnote)
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
