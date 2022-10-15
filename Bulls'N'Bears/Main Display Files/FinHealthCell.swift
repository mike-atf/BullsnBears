//
//  FinHealthCell.swift
//  Bulls'N'Bears
//
//  Created by aDav on 02/10/2022.
//

import UIKit

class FinHealthCell: UITableViewCell {

    
    @IBOutlet var title: UILabel!
    @IBOutlet var chart: ATFChart!
    var cellPath: IndexPath!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        isUserInteractionEnabled = false
    }

    override func prepareForReuse() {
        cellPath = IndexPath()
        title.text = ""
        chart.prepareForReuse()
    }
    
    public func configure(path: IndexPath,primaryData: LabelledChartDataSet, secondaryData: LabelledChartDataSet?=nil, chartMinimumTime: TimeInterval?=nil) {
        
        self.cellPath = path
        title.text = primaryData.title
        
        chart.minimumTimeAxisTimeSpan = chartMinimumTime ?? year
//        let titleInfo = ChartLabelInfo(position: .left, text: primaryData.title, font: UIFont.systemFont(ofSize: 14), color: nil, alignment: .left)
        chart.configureChart(primaryData: primaryData, secondaryData: secondaryData ,types: [.lineWithFill], chartLabelsData: nil, declineThresholdsForColorChange: [0.2, 0.1])
    }
    
}
