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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    public func configure(primaryData: LabelledChartDataSet, secondaryData: LabelledChartDataSet?=nil) {
        
        title.text = primaryData.title
        let labelInfo = ChartLabelInfo(position: .left, text: "%", font: nil, color: nil, alignment: nil)
        chart.configureChart(primaryData: primaryData, secondaryData: secondaryData ,types: [.lineWithFill], chartLabelsData: [labelInfo])
    }
    
}
