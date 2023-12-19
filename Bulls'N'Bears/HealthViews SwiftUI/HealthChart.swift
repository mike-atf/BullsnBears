//
//  HealthChart.swift
//  Bulls'N'Bears
//
//  Created by aDav on 21/03/2023.
//

import SwiftUI
import Charts


struct HealthChart: View {
    
    var share: Share
    var dataSet: LabelledChartDataSet
    var formatter: NumberFormatter
    var dateFormatter: DateFormatter
    var changeFormatter: NumberFormatter
    var higherIsBetter: Bool
    var changeRatio: Double
//    var areaColor: Color
    
    init(dataSet: LabelledChartDataSet, share: Share) {
        
        self.dataSet = dataSet
        self.share = share
        self.dateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = NSLocale.current
            formatter.timeZone = NSTimeZone.local
            formatter.dateFormat = "MMM.yy"
            return formatter
        }()
        self.changeFormatter = percentFormatter0DigitsPositive

        self.higherIsBetter = false

        switch dataSet.format {
        case .percent:
            self.formatter = percentFormatter0Digits
            higherIsBetter = true
        case .currency:
            self.formatter = currencyFormatterNoGapWithPence
            higherIsBetter = true
        case .numberWithDecimals:
            self.formatter = numberFormatter2Decimals
        case .numberNoDecimals:
            self.formatter = numberFormatterNoFraction
        default:
            self.formatter = numberFormatterNoFraction
        }
        
//        areaColor = Color(uiColor: UIColor.systemBlue.withAlphaComponent(0.25))
        changeRatio = 0.0
        
        if dataSet.chartData.count > 1 {
//            var color: UIColor
            
            let dateAscending = dataSet.chartData.sorted(by: { s0, s1 in
                if s0.x ?? Date() < s1.x ?? Date() { return true }
                else { return false}
            })
            
            let valueFirst = dateAscending.compactMap { $0.y }.first!
            let valueLast = dateAscending.compactMap { $0.y }.last!
            
            changeRatio = (valueLast - valueFirst) / valueFirst
            
//            switch lastToFirstRatio {
//            case 1.1..<1.2:
////                color = higherIsBetter ? UIColor.systemGreen : UIColor.systemOrange
//            case 1.2...:
////                color = higherIsBetter ? UIColor.systemGreen : UIColor.systemRed
//            case 0.8...0.9:
////                color = higherIsBetter ? UIColor.systemOrange : UIColor.systemGreen
//            case ...0.8:
////                color = higherIsBetter ? UIColor.systemRed : UIColor.systemGreen
//            default:
////                color = UIColor.systemBlue
//            }
            
//            areaColor = Color(uiColor: color.withAlphaComponent(0.25))
        }
    }

    var body: some View {
        
        
        Chart(dataSet.chartData) { item in
                        
//                AreaMark (
//                    x: .value("Date", item.x ?? Date()),
//                    y: .value("Score", (item.y ?? 0.0))
//                )
//                .foregroundStyle(areaColor)

                LineMark(
                    x: .value("Date", item.x ?? Date()),
                    y: .value("Score", (item.y ?? 0.0))
                )
                .symbol(Circle())
                .annotation {
                    Text(changeFormatter.string(from: changeRatio as NSNumber) ?? "-")
                }

        }
        .chartYAxis {
            
            if dataSet.format  == .percent {
                AxisMarks(format: Decimal.FormatStyle.Percent.percent.scale(100))
            }
            else if dataSet.format == .currency {
                AxisMarks() { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let d = value.as(Int.self) {
                            let cSymbol = share.currency == "EUR" ? "€" : "$"
                            Text("\(cSymbol)\(d)")
                        }
                    }
                }
            } else {
                AxisMarks(format: Decimal.FormatStyle.localizedDecimal(locale: Locale()))
            }

        }
//        .chartYScale(domain: dataSet.format == .percent ? 0...1 : ScaleRange)
        .chartXAxis {
            AxisMarks() { value in
                
                AxisGridLine()
                AxisValueLabel {
                    if let d = value.as(Date.self) {
                        Text(dateFormatter.string(from: d))
                    }
                }
            }

        }

    }
}

struct HealthChart_Previews: PreviewProvider {
    static var previews: some View {
        HealthChart(dataSet: LabelledChartDataSet(title: "Health", chartData: [ChartDataSet(x: DatesManager.dateFromAString(dateString: "01/10/2022"), y: 1.0), ChartDataSet(x: DatesManager.dateFromAString(dateString: "03/03/2023"), y: 3.5), ChartDataSet(x: DatesManager.dateFromAString(dateString: "10/01/2023"), y: 5.0), ChartDataSet(x: DatesManager.dateFromAString(dateString: "2/12/2022"), y: 2.3)], format: .numberNoDecimals), share: Share.preview)
    }
}
