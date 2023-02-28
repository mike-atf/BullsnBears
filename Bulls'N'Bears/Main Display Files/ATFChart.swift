//
//  ATFChart.swift
//  Bulls'N'Bears
//
//  Created by aDav on 02/10/2022.
//

import UIKit

enum ChartLinePositions {
    case top
    case bottom
    case left
    case right
    case horizontal
    case vertical
}

enum ChartType {
    case bar
    case stackedBar
    case line
    case lineWithFill
    case pie
}

enum ChartLineType {
    case major
    case minor
}

enum Position {
    case top
    case bottom
    case left
    case right
    case legend1
    case legend2
}

enum ChartAxis {
    case vertical
    case horizontal
}

enum ChartAxisScale {
    case linear
    case logarithmic
}

enum AxisUnit {
    case double
    case time
    case currency
    case percent
}

typealias Inset = (position: Position, inset: CGFloat)
typealias ChartLabelInfo = (position: Position, text: String, font: UIFont?, color: UIColor?, alignment: NSTextAlignment?)
typealias ChartDataSet = (x: Date?, y: Double?)
typealias AxisParameters = (min: Double, max: Double, noOfTicks: Int, scale: ChartAxisScale)
typealias LabelledChartDataSet = (title: String, chartData: [ChartDataSet], format: ValuationCellValueFormat)


/// NOT rotation safe
class ATFChart: UIView {

    // chart line parameters
    var visibleChartLines: [ChartLinePositions] = [.left, .bottom,. horizontal, .vertical]
    var chartLineWidth: [ChartLineType: CGFloat] = [.major: 2.0, .minor: 1.0]
    var chartLineColor: [ChartLineType: UIColor] = [.major: UIColor.label, .minor: UIColor.lightGray]
    
    var insets: [Position: CGFloat] = [.top: 5, .bottom : 5, .left : 5.0, .right: 5.0]
    
    var chartTypes: [ChartType] = [.bar]
    var declineIsBad = true
    
    // chart data
    var primaryData: LabelledChartDataSet?
    var secondaryData: LabelledChartDataSet?
    var chartLabelData: [ChartLabelInfo]?
    var chartLabels = [Position : UILabel]()

    // axis data
    var axisParameters = [ChartAxis : AxisParameters]()
    var minimumTimeAxisTimeSpan: TimeInterval = 365*24*3600/12 // default one month
    var maximumYAxisValue: Double?
    var minimumYAxisValue: Double?
    var timeAxisStartDate = DatesManager.beginningOfFirstWeekDay(ofDate: Date())
    var timeAxisEndDate = DatesManager.endOflastWeekDay(ofDate: Date())
    var timeAxisStepInterval = day
    var axisLabels = [ChartAxis: [UILabel]]()
    var showVerticalAxisLabels = true
    var showHorizontalAxisLabels = true
    
    var allLabels = [UILabel]()
    
    var dataColors = [UIColor.systemBlue, UIColor.systemOrange]
    /// set the thresholds for ratio reduction (1-last value / first value). If exceeding the first value (concern) then the line fill or bar color will change to red, if the second (caution) then to orange
    var thresholdsForColorChange_decline: [Double]?

    
    // formatters
    let currencyFormatter = {
        let formatter = NumberFormatter()
        formatter.currencySymbol = "$"
        formatter.numberStyle = NumberFormatter.Style.currency
        return formatter
    }()
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = NSLocale.current
        formatter.dateStyle = .short
        return formatter
    }()
    let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = NSLocale.current
        formatter.setLocalizedDateFormatFromTemplate("dMM")
        return formatter
    }()
    var yAxisFormat = ValuationCellValueFormat.currency



    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.backgroundColor = UIColor.clear
        
    }

    /// declineThresholdsForColorChange is an optional  array of 1-2 Doubles between 0-1, indicating decline thresholds from last primaryData value to last primaryDats value the first is the concern threshold for changing color to red, the second (optional) is the caution alert changing color to orange
    func configureChart(primaryData: LabelledChartDataSet?, secondaryData: LabelledChartDataSet?=nil, types: [ChartType], chartLabelsData:[ChartLabelInfo]?, declineThresholdsForColorChange: [Double]?=nil) {
        
        
        // ensure chartData are date ascending
        if let validP = primaryData {
            let sortedChartData = validP.chartData.sorted(by: { e0, e1 in
                if e0.x! < e1.x! { return true }
                else { return false }
            })
            self.primaryData = LabelledChartDataSet(title: validP.title, chartData: sortedChartData, format: validP.format)
        } else { self.primaryData = primaryData }
        
        if let validS = secondaryData {
            let sortedChartData = validS.chartData.sorted(by: { e0, e1 in
                if e0.x! < e1.x! { return true }
                else { return false }
            })
            self.secondaryData = LabelledChartDataSet(title: validS.title, chartData: sortedChartData, format: validS.format)
        } else { self.secondaryData = secondaryData }
        
        self.chartTypes = types
        self.chartLabelData = chartLabelsData
        self.yAxisFormat = primaryData?.format ?? .currency
        self.thresholdsForColorChange_decline = declineThresholdsForColorChange
        
        createSurroundingLabels()
        
        axisParameters[.horizontal] = findAxisParameters(axis: .horizontal)
        axisParameters[.vertical] = findAxisParameters(axis: .vertical)
        
        createAxisLabels()
                
        layoutIfNeeded()
        
    }
    
    func prepareForReuse() {
        for label in allLabels {
            label.removeFromSuperview()
        }
        allLabels = [UILabel]()
        axisLabels[.vertical] = nil
        axisLabels[.horizontal] = nil
        
        chartLabels[.top] = nil
        chartLabels[.bottom] = nil
        chartLabels[.left] = nil
        chartLabels[.right] = nil
        chartLabels[.legend1] = nil
        chartLabels[.legend2] = nil

        chartLabelData = nil
        
        primaryData = nil
        secondaryData = nil
        
        insets = [.top: 5, .bottom : 5, .left : 5.0, .right: 5.0]
        
        setNeedsLayout()
        setNeedsDisplay()
        
    }
    
    
    override func draw(_ rect: CGRect) {
        
        
        //MARK: - adjust chart inset to accomodate surrounding labels
        for label in chartLabels {
            switch label.key {
            case .top:
                insets[.top] = label.value.frame.height + 5
            case .bottom:
                insets[.bottom] = label.value.frame.height + 5
            case .left:
                insets[.left] = label.value.frame.width + 5
            case .right:
                insets[.right] = label.value.frame.width + 5
            case .legend1:
                if label.value.frame.width > [(chartLabels[.legend2]?.frame.width ?? 0), (chartLabels[.right]?.frame.width ?? 0)].max() ?? 0 {
                    insets[.right] = label.value.frame.width + 5
                }
            case .legend2:
                if label.value.frame.width > [(chartLabels[.legend1]?.frame.width ?? 0), (chartLabels[.right]?.frame.width ?? 0)].max() ?? 0 {
                    insets[.right] = label.value.frame.width + 5
                }
            }
        }
                
        // adjust left and bottom insets to accomodate vertical and horizontal axis labels
        var maxVAxisLabelWidth: CGFloat = 0
        for label in axisLabels[.vertical] ?? [] {
            if label.frame.width > maxVAxisLabelWidth { maxVAxisLabelWidth = label.frame.width }
        }
        insets[.left]! += maxVAxisLabelWidth + 5.0
        
        var maxHAxisLabelHeight: CGFloat = 0
        for label in axisLabels[.horizontal] ?? [] {
            if label.frame.height > maxHAxisLabelHeight { maxHAxisLabelHeight = label.frame.height }
        }
        insets[.bottom]! += maxHAxisLabelHeight

        
        //MARK: - draw Chart Lines
        let chartLines = UIBezierPath()
        let chartGrid = UIBezierPath()
        for line in visibleChartLines {
            switch line {
            case .top:
                // thin line in case top line is zero line
                chartGrid.move(to: CGPoint(x: insets[.left]!, y: insets[.top]!))
                chartGrid.addLine(to: CGPoint(x: rect.width - insets[.right]!, y: insets[.top]!))
            case .left:
                chartLines.move(to: CGPoint(x: insets[.left]!, y: insets[.top]!))
                chartLines.addLine(to: CGPoint(x: insets[.left]!, y: rect.height - insets[.bottom]!))
            case .bottom:
                // thin line in case bottom line is zero line, but may not be
                chartGrid.move(to: CGPoint(x: insets[.left]!, y: rect.height - insets[.bottom]!))
                chartGrid.addLine(to: CGPoint(x: rect.width - insets[.right]!, y: rect.height - insets[.bottom]!))
            case .right:
                chartLines.move(to: CGPoint(x: rect.width - insets[.right]!, y: insets[.top]!))
                chartLines.addLine(to: CGPoint(x: rect.width - insets[.right]!, y: rect.height - insets[.bottom]!))
                
            case .horizontal:
                let hGridLines = axisParameters[.vertical]!.noOfTicks
                let lineGap = (rect.height - insets[.top]! - insets[.bottom]!) / CGFloat(hGridLines)
                var lineX = insets[.top]! + lineGap
                
                for _ in 0..<hGridLines {
                    chartGrid.move(to: CGPoint(x: insets[.left]!, y: lineX))
                    chartGrid.addLine(to: CGPoint(x: rect.width - insets[.right]!, y: lineX))
                    lineX += lineGap
                }
                
            case .vertical:
                // set by axs step time intervals
                let vGridLines = axisParameters[.horizontal]!.noOfTicks
                let lineGap = (rect.width - insets[.left]! - insets[.right]!) / CGFloat(vGridLines)
                var lineY = insets[.left]! + lineGap
                
                for _ in 0..<vGridLines {
                    chartGrid.move(to: CGPoint(x: lineY, y: insets[.top]!))
                    chartGrid.addLine(to: CGPoint(x: lineY, y: rect.height - insets[.bottom]!))
                    lineY += lineGap
                }
            }
        }
        
        // zero horizontal line
        let zeroLineStartPoint = plotDataPoint(dataPoint: ChartDataSet(x: timeAxisStartDate, y: 0.0), frame: rect)
        let zeroLineEndPoint = plotDataPoint(dataPoint: ChartDataSet(x: timeAxisEndDate, y: 0.0), frame: rect)
        chartLines.move(to: zeroLineStartPoint)
        chartLines.addLine(to: zeroLineEndPoint)
        
        chartGrid.lineWidth = chartLineWidth[.minor]!
        chartLineColor[.minor]!.setStroke()
        chartGrid.stroke()
        
        chartLines.lineWidth = chartLineWidth[.major]!
        chartLineColor[.major]!.setStroke()
        chartLines.stroke()
        
        //MARK: - vertical axis labels
        let vRange = (axisParameters[.vertical]!.max - axisParameters[.vertical]!.min)
        let vRangeScale = (rect.height - insets[.top]! - insets[.bottom]!) / vRange
        let vTickStep = vRange / Double(axisParameters[.vertical]!.noOfTicks)
        let vTickStepCGF = vTickStep * vRangeScale
        let chartBottom = rect.height - insets[.bottom]!
        for i in 1..<(axisLabels[.vertical]?.count ?? 0) {
                
            guard let label = axisLabels[.vertical]?[i] else { continue }
            
            let yValue = chartBottom - CGFloat(i) * vTickStepCGF
            let yValueMultiplier =  yValue / rect.midY
            
            label.trailingAnchor.constraint(equalTo: leadingAnchor, constant: insets[.left]! - 5).isActive = true
            
            if let leftLabel = chartLabels[.left] {
                label.leadingAnchor.constraint(greaterThanOrEqualTo: leftLabel.trailingAnchor, constant: 5).isActive = true
            } else {
                label.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor,constant: 5).isActive = true
            }
            
            NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: yValueMultiplier, constant: 0).isActive = true
            
            label.isHidden = false
        }
        
        //MARK: - horizontal axis labels
        let hTickStepCGF = (rect.width - insets[.left]! - insets[.right]!) / CGFloat(axisParameters[.horizontal]!.noOfTicks)
        let chartLeft = insets[.left]!
        for i in 0..<(axisLabels[.horizontal]?.count ?? 0) {
                
            guard let label = axisLabels[.horizontal]?[i] else { continue }
            
            let xValue = chartLeft + CGFloat(i) * hTickStepCGF - label.frame.width / 2
            let yValueMultiplier = (rect.height - insets[.bottom]! + label.frame.height/2) / rect.midY
            NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: yValueMultiplier, constant: 0).isActive = true
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: xValue).isActive = true
            
            label.isHidden = false

        }
        
        //MARK: - line graph
        if chartTypes.contains(.line) || chartTypes.contains(.lineWithFill) {
            
            let lineGraphs = [primaryData, secondaryData]
            var lineCount = 0
            
            for lineData in lineGraphs {
                
                guard let validDataSet = lineData?.chartData else { continue }
                guard validDataSet.count > 0 else { continue }
                
                let lineColor = dataColors[lineCount]
                let linePath = UIBezierPath()
                var linePathPoints = [CGPoint]()
                
                var startPoint = CGPoint()
                var endPoint = CGPoint()
                if let start = validDataSet.first {
                    startPoint = plotDataPoint(dataPoint: start, frame: rect)
                    linePath.move(to: startPoint)
                    linePathPoints.append(startPoint)
                    endPoint = startPoint
                }
                if validDataSet.count > 1 {
                    for i in 1..<(lineData?.chartData.count ?? 0) {
                        endPoint = plotDataPoint(dataPoint: validDataSet[i], frame: rect)
                        linePath.addLine(to: endPoint)
                        linePathPoints.append(endPoint)
                    }
                }
                
                if chartTypes == [.lineWithFill] {
                    let filledLinePath = linePath.copy() as! UIBezierPath
                    filledLinePath.addLine(to: CGPoint(x: endPoint.x, y: rect.height - insets[.bottom]!))
                    filledLinePath.addLine(to: CGPoint(x: startPoint.x, y: rect.height - insets[.bottom]!))
                    filledLinePath.addLine(to: startPoint)
                    
                    if let thresholds = thresholdsForColorChange_decline {
                        let max = declineIsBad ? validDataSet.compactMap{ $0.y }.max()! : validDataSet.compactMap{ $0.y }.min()!
                        
                        let latest = validDataSet.last!.y!
                        let changeFromLastToFirstRatio = abs(max - latest) / max
                        if changeFromLastToFirstRatio > thresholds.first! {
                            UIColor.systemRed.withAlphaComponent(0.5).setFill()
                        } else if changeFromLastToFirstRatio > thresholds.last! {
                            UIColor.systemOrange.withAlphaComponent(0.5).setFill()
                        } else {
                            lineColor.withAlphaComponent(0.5).setFill()
                        }
                    }
                    else {
                        lineColor.withAlphaComponent(0.5).setFill()
                    }
                    filledLinePath.fill()

                }
                
                linePath.lineWidth = 2.5
                linePath.miterLimit = 5
                linePath.lineJoinStyle = .round
                lineColor.setStroke()
                lineColor.setFill()
                linePath.stroke()
                
                
                let pointRadius: CGFloat = 8
                for linePoint in linePathPoints {
                    let pointRect = CGRect(x: linePoint.x - pointRadius/2, y: linePoint.y - pointRadius/2, width: pointRadius, height: pointRadius)
                    let pointPath = UIBezierPath(ovalIn: pointRect)
                    let centerPin = UIBezierPath(ovalIn: pointRect.insetBy(dx: 2, dy: 2))
                    lineColor.setFill()
                    pointPath.fill()
                    UIColor.white.setFill()
                    centerPin.fill()
                }
                lineCount += 1
            }
        }
        
        //MARK: - bar graph
        if chartTypes.contains(.bar) {
            
            let barGraphs = [primaryData, secondaryData]
            var barGraphCount = 0
            
            let barBottom = rect.height - insets[.bottom]!
            let barWidth: CGFloat = 6.0
            let multipleBarGraphOffset: CGFloat = 4.0
            for barData in barGraphs {
 
                guard let validDataSet = barData?.chartData else { continue }
                for data in validDataSet {
                    let horizontalOffset = CGFloat(barGraphCount) * multipleBarGraphOffset
                    var barColor = dataColors[barGraphCount].withAlphaComponent(0.6)
                    let barTopPoint = plotDataPoint(dataPoint: data, frame: rect)
                    let barRect = CGRect(x: horizontalOffset + barTopPoint.x - barWidth / 2, y: barTopPoint.y, width: barWidth, height: barBottom - barTopPoint.y)
                    let barPath = UIBezierPath(roundedRect: barRect, cornerRadius: 1)
                    
                    if let thresholds = thresholdsForColorChange_decline {
                        let max = validDataSet.compactMap{ $0.y }.max()!
                        let latest = validDataSet.last!.y!
                        let changeFromLastToFirstRatio = (max - latest) / max
                        if changeFromLastToFirstRatio > thresholds.first! {
                            barColor = UIColor.systemRed.withAlphaComponent(0.5)
                        } else if changeFromLastToFirstRatio > thresholds.last! {
                            barColor = UIColor.systemOrange.withAlphaComponent(0.5)
                        }
                    }
                    
                    barColor.setFill()
                    barPath.fill()
                    
                }
                barGraphCount += 1
            }
        }
        
    }
    
    internal func plotDataPoint(dataPoint: ChartDataSet, frame: CGRect) -> CGPoint {
        
        // x axis
        let chartWidth = frame.width - insets[.right]! - insets[.left]!
        let timeScale = timeAxisEndDate.timeIntervalSince(timeAxisStartDate) / Double(chartWidth)
        let dataTimeFromStart = dataPoint.x!.timeIntervalSince(timeAxisStartDate)
        let x = insets[.left]! + CGFloat(dataTimeFromStart / timeScale)
        
        // y axis
        let chartHeight =  frame.height - insets[.bottom]! -  insets[.top]!
        let valueScale = ((axisParameters[.vertical]?.max ?? 1) - (axisParameters[.vertical]?.min ?? 0)) / Double(chartHeight)
        let valueFromMax = (axisParameters[.vertical]?.max ?? 1) - dataPoint.y!
        let y = insets[.top]! + CGFloat(valueFromMax / valueScale)

        return CGPoint(x: x, y: y)
        
    }
    
    internal func findAxisParameters(axis: ChartAxis) -> AxisParameters {
        
        if axis == .vertical {
            
            let primary_Max = primaryData?.chartData.compactMap{ $0.y }.max() ?? 1.0
            let primary_Min = primaryData?.chartData.compactMap{ $0.y }.min() ?? 0.0
            
            var combinedMax = primary_Max
            var combinedMin = primary_Min
            
            if let secondary_Max = secondaryData?.chartData.compactMap({ $0.y }).max() {
                if combinedMax > secondary_Max {
                    combinedMax = secondary_Max
                }
                
            }
            if let secondary_Min = secondaryData?.chartData.compactMap({ $0.y }).min() {
                if combinedMin < secondary_Min {
                    combinedMin = secondary_Min
                }
            }
                        
            let minMax: [Double] = findAxisMinMax(minMax: [combinedMin, combinedMax]) ?? [0.0, 1.0]
            
            let axisRange = minMax.last! - minMax.first!
            let axisStep = abs(axisRange) / 5
            let noOfTicks = Int(axisRange / axisStep)
            
            return AxisParameters(min: minMax.first!, max: minMax.last!, noOfTicks: noOfTicks, scale: .linear)
            
        } else {
            // horizontal time axis
            
            let primary_Max = primaryData?.chartData.compactMap{ $0.x }.max() ?? Date()
            let primary_Min = primaryData?.chartData.compactMap{ $0.x }.min() ?? Date()
            
            var combinedMax = primary_Max
            var combinedMin = primary_Min
            
            if let secondary_Max = secondaryData?.chartData.compactMap({ $0.x }).max() {
                if combinedMax > secondary_Max {
                    combinedMax = secondary_Max
                }
                
            }
            if let secondary_Min = secondaryData?.chartData.compactMap({ $0.x }).min() {
                if combinedMin < secondary_Min {
                    combinedMin = secondary_Min
                }
            }
            
            let dateRange = combinedMax.timeIntervalSince(combinedMin)
            
            if dateRange > minimumTimeAxisTimeSpan {
                if dateRange < 24*3600 {
                    minimumTimeAxisTimeSpan = day
                }
                else if dateRange < week {
                    minimumTimeAxisTimeSpan = week
                } else if dateRange < month {
                    minimumTimeAxisTimeSpan = month
                } else if dateRange < quarter {
                    minimumTimeAxisTimeSpan = quarter
                } else if dateRange < year {
                    minimumTimeAxisTimeSpan = year
                } else if  dateRange < 2*year {
                        minimumTimeAxisTimeSpan = 2 * year
                } else {
                    minimumTimeAxisTimeSpan = 5 * year
                }
            }
            
            switch minimumTimeAxisTimeSpan {
            case 0...24*3600:
                // hours...
                timeAxisStartDate = DatesManager.beginningOfDay(of: combinedMin)
                timeAxisEndDate = DatesManager.endOfDay(of: combinedMax)
                timeAxisStepInterval = 3600
            case 24*3600...7*24*3600:
                // days...
                timeAxisStartDate = DatesManager.beginningOfFirstWeekDay(ofDate: combinedMin)
                timeAxisEndDate = DatesManager.endOflastWeekDay(ofDate: combinedMax)
                timeAxisStepInterval = day
            case 7*24*3600...365*24*3600/12:
                // weeks...
                timeAxisStartDate = DatesManager.firstDayOfThisMonth(date: combinedMin)
                timeAxisEndDate = DatesManager.endOflastDayOfThisMonth(date: combinedMax)
                timeAxisStepInterval = week
            case 365*24*3600/12...365*24*3600/4:
                // weeks...
                timeAxisStartDate = DatesManager.beginningOfQuarter(of: combinedMin)
                timeAxisEndDate = DatesManager.endOfQuarter(of: combinedMax)
                timeAxisStepInterval = week
            case 365*24*3600/4...365*24*3600:
                // one year...
                timeAxisStartDate = DatesManager.beginningOfYear(of: combinedMin)
                timeAxisEndDate = DatesManager.endOfYear(of: combinedMax)
                timeAxisStepInterval = month
            default:
                // >more than one year...
                timeAxisStartDate = DatesManager.beginningOfYear(of: combinedMin)
                timeAxisEndDate = DatesManager.endOfYear(of: combinedMax)
                timeAxisStepInterval = quarter
            }
            
            let axisTimeSpan = timeAxisEndDate.timeIntervalSince(timeAxisStartDate)
            var axisStep = timeAxisStepInterval
            var noOfTicks = Int(axisTimeSpan / axisStep)
            if noOfTicks > 4 {
                timeAxisStepInterval *= 2
                axisStep = timeAxisStepInterval
                noOfTicks = Int(axisTimeSpan / axisStep)
            }

            return AxisParameters(min: timeAxisStartDate.timeIntervalSince1970, max: timeAxisEndDate.timeIntervalSince1970, noOfTicks: noOfTicks, scale: .linear)
            
        }
    }
        
    internal func findAxisMinMax(minMax: [Double]) -> [Double]? {
        
        guard let min = minMax.first else { return nil }
        guard let max = minMax.last else { return nil }
        
        var axisMax: Double = 1
        var axisMin: Double = 0
        
        if min == 0.0 && max == 0.0 {
            return [axisMin, axisMax]
        }

        if max < 0 {
            axisMax = 0
        } else {
            var e:Double = 0
            let options = [0.01, 0.025, 0.05,0.1,0.25,0.5, 0.75, 1.0]
            
            while axisMax / abs(max) <= 1.0 {
                e += 1.0
                axisMax = pow(10, e)
            }
            for option in options {
                if option * axisMax > max {
                    axisMax *= option
                    break
                }
            }
            
        }


        if min < 0 {
            var e:Double = 0
            axisMin = -1 * pow(10, e)
            let options = [0.1,0.25,0.5, 0.75, 1.0]
            
            while axisMin / min <= 1.0 {
                e += 1.0
                axisMin = -1 * pow(10, e)
            }
            for option in options {
                if option * axisMin < min {
                    axisMin *= option
                    break
                }
            }
        }
        
//        let zeroToOne = 0.0..<1.0
//        
//        if zeroToOne.contains(axisMin) && axisMax < 1.0 {
//            axisMax = 1.0
//        }
        
        return [minimumYAxisValue ?? axisMin, maximumYAxisValue ?? axisMax]
    }
    
    internal func createSurroundingLabels() {
                
        for labelData in chartLabelData ?? [] {
                        
            let newLabel: UILabel = {
                let defaultLabel = UILabel()
                defaultLabel.font = labelData.font ?? UIFont.preferredFont(forTextStyle: .title3)
                defaultLabel.text = labelData.text
                defaultLabel.textColor = labelData.color ?? UIColor.label
                defaultLabel.textAlignment = labelData.alignment ?? .left
                return defaultLabel
            }()
            
            newLabel.translatesAutoresizingMaskIntoConstraints = false
            addSubview(newLabel)
            allLabels.append(newLabel)
            
            switch labelData.position {
            case .top:
                newLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
                newLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
                insets[.top] = newLabel.frame.maxX + 5
                chartLabels[.top] = newLabel
            case .bottom:
                newLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
                newLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
                insets[.bottom] = newLabel.frame.height + 5
                chartLabels[.bottom] = newLabel
            case .left:
                newLabel.numberOfLines = 0
                newLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
                newLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
                insets[.left] = newLabel.frame.width + 5
                chartLabels[.left] = newLabel
            case .right:
                newLabel.numberOfLines = 0
                newLabel.text = labelData.text
                newLabel.textColor = labelData.color
                newLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
                newLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
                insets[.right] = newLabel.frame.width + 5
                chartLabels[.right] = newLabel
            case .legend1:
                newLabel.numberOfLines = 0
                newLabel.font = UIFont.systemFont(ofSize: 12)
                newLabel.text = primaryData?.title
                newLabel.textColor = dataColors.first!
                newLabel.textAlignment = .left
                
                newLabel.topAnchor.constraint(equalTo: topAnchor, constant: insets[.top]!).isActive = true
                newLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
                chartLabels[.legend1] = newLabel
            case .legend2:
                newLabel.numberOfLines = 0
                newLabel.font = UIFont.systemFont(ofSize: 12)
                newLabel.text = secondaryData?.title
                newLabel.textColor = dataColors[1]
                newLabel.textAlignment = .left
                newLabel.sizeToFit()
                newLabel.topAnchor.constraint(equalTo: chartLabels[.legend1]!.bottomAnchor).isActive = true
                newLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
                chartLabels[.legend2] = newLabel
            }
            
        }
        

    }
    
    internal func createAxisLabels() {
        // the positions/ constraints for these labels need to be set in the 'draw' function
        
        if showVerticalAxisLabels {
                        
            var yAxisFormatter = NumberFormatter()
            switch yAxisFormat {
            case .percent:
                yAxisFormatter = percentFormatter0Digits
                if axisParameters[.vertical]!.max < 1 {
                    yAxisFormatter = percentFormatter2Digits
                }
            case .numberWithDecimals:
                yAxisFormatter = numberFormatterWith1Digit
                if axisParameters[.vertical]!.max < 1 {
                    yAxisFormatter = numberFormatter2Decimals
                }
            default:
                yAxisFormatter = currencyFormatterNoGapWithPence
                if axisParameters[.vertical]!.max > 10 {
                    yAxisFormatter = currencyFormatterGapNoPence
                } else if axisParameters[.vertical]!.max < 1 {
                    yAxisFormatter = currencyFormatterNoGapWithPence
                }
            }
            
            let range = axisParameters[.vertical]!.max - axisParameters[.vertical]!.min
            let step = range / Double(axisParameters[.vertical]!.noOfTicks)
            var vAxisLabels = [UILabel]()
            for i in 0..<axisParameters[.vertical]!.noOfTicks {
                
                let value = axisParameters[.vertical]!.min + Double(i) * step
                
                var shortCurrency$: String?
                if yAxisFormat == .currency && value > 1000 {
                    shortCurrency$ = value.shortString(decimals: 0)
                }
                
                let newLabel: UILabel = {
                    let defaultLabel = UILabel()
                    defaultLabel.font = UIFont.systemFont(ofSize: 11)
                    defaultLabel.text = shortCurrency$ ?? yAxisFormatter.string(from: value as NSNumber)
                    defaultLabel.textColor = UIColor.label
                    return defaultLabel
                }()
                
                newLabel.translatesAutoresizingMaskIntoConstraints = false
                addSubview(newLabel)
                
                newLabel.isHidden = true

                vAxisLabels.append(newLabel)
            }
            axisLabels[.vertical] = vAxisLabels
            allLabels.append(contentsOf: vAxisLabels)
        }
        
        if showHorizontalAxisLabels {
                        
            let dateRangeStep = timeAxisEndDate.timeIntervalSince(timeAxisStartDate) / Double(axisParameters[.horizontal]!.noOfTicks)
            var hAxisLabels = [UILabel]()
            
            for i in 0...axisParameters[.horizontal]!.noOfTicks {
                
                let date = timeAxisStartDate.addingTimeInterval(Double(i) * dateRangeStep)
                var date$ = String()
                if i == 0 {
                    date$ = dateFormatter.string(from: date)
                } else {
                    date$ = shortDateFormatter.string(from: date)
                }
                
                let newLabel: UILabel = {
                    let defaultLabel = UILabel()
                    defaultLabel.font = UIFont.systemFont(ofSize: 11)
                    defaultLabel.text = date$
                    defaultLabel.textColor = UIColor.label
                    return defaultLabel
                }()
                
                newLabel.translatesAutoresizingMaskIntoConstraints = false
                addSubview(newLabel)
                
                newLabel.isHidden = true
                hAxisLabels.append(newLabel)
            }
            axisLabels[.horizontal] = hAxisLabels
            allLabels.append(contentsOf: hAxisLabels)
            
        }
        
    }
    
    }


