//
//  HealthChartView.swift
//  Bulls'N'Bears
//
//  Created by aDav on 21/03/2023.
//

import SwiftUI

struct HealthTableCellView: View {
    
    @ObservedObject var share: Share
    
    var chartDataSet: LabelledChartDataSet
    
    var body: some View {
        
        VStack(alignment: .leading) {
                Text(chartDataSet.title).fontWeight(.bold)
                .foregroundColor(Color(uiColor: .label))
           
                HealthChart(dataSet: chartDataSet, share: self.share)
                .frame(height: 120)
        }
    }
}

struct HealthTableCellView_Previews: PreviewProvider {
    static var previews: some View {
        HealthTableCellView(share: Share.preview, chartDataSet: LabelledChartDataSet(title: "Health", chartData: [ChartDataSet(x: DatesManager.dateFromAString(dateString: "30/01/2023"), y: 1.0), ChartDataSet(x: DatesManager.dateFromAString(dateString: "03/03/2023"), y: 3.5), ChartDataSet(x: DatesManager.dateFromAString(dateString: "10/02/2023"), y: 5.0)], format: .numberNoDecimals))
    }
}

