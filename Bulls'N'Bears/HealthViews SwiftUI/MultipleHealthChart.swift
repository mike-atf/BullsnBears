//
//  MultipleHealthChart.swift
//  Bulls'N'Bears
//
//  Created by aDav on 26/03/2023.
//

import SwiftUI
import Charts

struct MultipleChartsDataSet: Identifiable {
    var title: String
    var date: Date
    var value: Double
    var id = UUID()
}

struct MultipleHealthChart: View {
    
    @State var chartData: [MultipleChartsDataSet]
    var dateFormatter: DateFormatter
    var formatter: NumberFormatter
//    var changeFormatter: NumberFormatter
    var currencySymbol = "$"
    var format: ValuationCellValueFormat
//    var changeRatios: [Double]
    var title = String()
    
    init(dataSets: [LabelledChartDataSet], share:Share, title: String) {
        
        self.title = title
        self.format = dataSets.first?.format ?? .numberWithDecimals

        chartData = {
            var assembly = [MultipleChartsDataSet]()
            print("\(title) assembly data:")
            for set in dataSets {
                for data in set.chartData {
                    let new = MultipleChartsDataSet(title: set.title, date: data.x ?? Date(), value: data.y ?? 0.0)
                    assembly.append(new)
                    print(new)
                }
            }
            print("\(title) chart data count \(assembly.count)")
            print()
            return assembly
        }()

        self.dateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = NSLocale.current
            formatter.timeZone = NSTimeZone.local
            formatter.dateFormat = "MMM.yy"
            return formatter
        }()

        switch format {
        case .percent:
            self.formatter = percentFormatter0Digits
        case .currency:
            self.formatter = currencyFormatterNoGapWithPence
        case .numberWithDecimals:
            self.formatter = numberFormatter2Decimals
        case .numberNoDecimals:
            self.formatter = numberFormatterNoFraction
        default:
            self.formatter = numberFormatterNoFraction
        }
        
        if share.currency == "EUR" {
            currencySymbol = "€"
        }
       
    }

    var body: some View {
        
        Chart(chartData) { data in
                        
            LineMark (
                x: .value("Date", data.date),
                y: .value("Score", data.value),
                series: .value("", data.title)
            )
            .symbol(Circle())
            .foregroundStyle(by: .value("", data.title))
//            .annotation {
//                Text(changeFormatter.string(from: changeRatios[0] as NSNumber) ?? "-")
//            }

        }
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
        .chartYAxis {
            
            if self.format  == .percent {
                AxisMarks(format: Decimal.FormatStyle.Percent.percent.scale(100))
            }
            else if self.format == .currency {
                AxisMarks() { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let d = value.as(Int.self) {
                            Text("\(currencySymbol)\(d)")
                        }
                    }
                }
            } else {
                AxisMarks(format: Decimal.FormatStyle.localizedDecimal(locale: Locale()))
            }

        }


    }
}

struct MultipleHealthChart_Previews: PreviewProvider {
    static var previews: some View {
        MultipleHealthChart(dataSets: [LabelledChartDataSet(title: "Health", chartData: [ChartDataSet(x: DatesManager.dateFromAString(dateString: "01/10/2022"), y: 1.0), ChartDataSet(x: DatesManager.dateFromAString(dateString: "03/03/2023"), y: 3.5), ChartDataSet(x: DatesManager.dateFromAString(dateString: "10/01/2023"), y: 5.0), ChartDataSet(x: DatesManager.dateFromAString(dateString: "2/12/2022"), y: 2.3)], format: .numberNoDecimals), LabelledChartDataSet(title: "Para2", chartData: [ChartDataSet(x: DatesManager.dateFromAString(dateString: "20/10/2022"), y: 11.0), ChartDataSet(x: DatesManager.dateFromAString(dateString: "20/12/2022"), y: 9.5), ChartDataSet(x: DatesManager.dateFromAString(dateString: "31/01/2023"), y: 1.0), ChartDataSet(x: DatesManager.dateFromAString(dateString: "20/02/2023"), y: 8.3)], format: .numberNoDecimals)], share: Share.preview, title: "Sample data")
    }
}
