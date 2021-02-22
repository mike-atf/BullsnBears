//
//  ValueChart.swift
//  Bulls'N'Bears
//
//  Created by aDav on 21/02/2021.
//

import UIKit

class ValueChart: UIView {

    var valueArray: [Double]?
    
    var yAxisLabels = [UILabel]()
    var yAxisNumbers = [CGFloat]()
    var xAxisLabels = [UILabel]()
    var trendLabels = [UILabel]()
    var valuationLabels = [UILabel]()
    
    var boxes = UIBezierPath()
    
    var lowestValueInRange: Double?
    var highestValueInRange: Double?
    var minValue = CGFloat()
    var maxValue = CGFloat()
    var dateRange: [Date]?
    var chartTimeSpan = TimeInterval()
    
    var chartAreaSize = CGSize()
    var chartOrigin = CGPoint()
    var chartEnd = CGPoint()
    
    var trendsToShow = [TrendProperties]()
    var buttonGroupTime = [CheckButton]()
    var buttonGroupType = [CheckButton]()

    
    func configure(array: [Double]?) {
        self.valueArray = array?.reversed()
        
        minValue = CGFloat(valueArray?.min() ?? Double())
        maxValue = CGFloat(valueArray?.max() ?? Double())
        
        let components: Set<Calendar.Component> = [.year]
        let dateComponents = Calendar.current.dateComponents(components, from: Date())
        let mostRecentYear = dateComponents.year! - 2000
        
        var count = valueArray?.count ?? 0
        for _ in valueArray ?? [] {
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
        
        let step = findYAxisValues(min: minValue, max: maxValue)
        yAxisLabels.removeAll()
        yAxisNumbers.removeAll()
        var labelValue = CGFloat(Int(maxValue / step)) * step
        while labelValue >= minValue {
            let newLabel: UILabel = {
                let label = UILabel()
                label.font = UIFont.preferredFont(forTextStyle: .footnote)
                label.textAlignment = .right
                label.text = numberFormatterDecimals.string(from: labelValue as NSNumber)
                label.sizeToFit()
                self.addSubview(label)
                return label
            }()
            yAxisLabels.append(newLabel)
            yAxisNumbers.append(labelValue)
            labelValue -= step
        }

//        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {

// Y axis
        chartOrigin.x = rect.width * 0.05
        chartEnd.y = rect.height * 0.05
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

        guard let validValues = valueArray else { return }

        var index = 0
        yAxisLabels.forEach { (label) in
            let labelY: CGFloat = chartEnd.y + chartAreaSize.height * (maxValue - CGFloat(yAxisNumbers[index])) / (maxValue - minValue)
            label.frame.origin = CGPoint(x: chartEnd.x, y: labelY - label.frame.height / 2)
            index += 1
        }

        var step: CGFloat = 0
        var xAxisLabelLeft = chartOrigin.x
        xAxisLabels.forEach { (label) in
           label.frame.origin = CGPoint(x: xAxisLabelLeft - label.frame.width / 2, y: chartOrigin.y + 5)
           step += 1
            xAxisLabelLeft += chartAreaSize.width / CGFloat(xAxisLabels.count-1)
        }
        
// colums
        
        let boxWidth = chartAreaSize.width / CGFloat(validValues.count + 1)
        
        let valueRange = CGFloat(maxValue - minValue)
        
        var valueCount: CGFloat = 0
        let fillColor = UIColor.systemOrange
        validValues.forEach({ (value) in
            let boxLeft = chartOrigin.x + (boxWidth * 0.8 / 2) + (valueCount / CGFloat(validValues.count)) * chartAreaSize.width
            let boxTop = chartEnd.y + chartAreaSize.height * (maxValue - CGFloat(value)) / valueRange
            let boxBottom = chartEnd.y + chartAreaSize.height //* ((maxValue - CGFloat(value)) / (valueRange))
            let boxHeight = boxBottom - boxTop

            let boxRect = CGRect(x: boxLeft, y: boxTop, width: boxWidth * 0.8, height: boxHeight)
            let newBox = UIBezierPath(rect: boxRect)
            fillColor.setFill()
            fillColor.setStroke()
            newBox.fill()
            
            valueCount += 1
        })


    }
    
    private func findYAxisValues(min: CGFloat, max: CGFloat) -> CGFloat {
        
        let options:[CGFloat] = [2.0,2.5,5.0,10.0,20.0,25.0,50.0,100.0,150.0,200.0,250.0,500.0,1000.0, 5000.0,10000.0, 50000.0]
        let range = max - min
        
        var count: CGFloat = 100.0
        var index = -1
        repeat {
            index += 1
            count = range / options[index]
        } while count > 11.0
        
        return options[index]
    }
    

}
