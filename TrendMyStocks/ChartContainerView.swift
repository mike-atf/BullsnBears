//
//  ChartContainerView.swift
//  TrendMyStocks
//
//  Created by aDav on 02/12/2020.
//

import UIKit

class ChartContainerView: UIView {

    var stockToShow: Stock? {
        didSet {
            setNeedsDisplay()
        }
    }
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var contentView: ChartView!
    @IBOutlet var meanTrendLabel: UILabel!
    @IBOutlet var trendRangeLabel: UILabel!
    
    let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        formatter.minimumIntegerDigits = 1
        return formatter
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }

    override func draw(_ rect: CGRect) {
        
        guard let validStock = stockToShow else {
            return
        }

        titleLabel.text = validStock.name
//        if let validTrend = validStock.averageTrend(trends: validStock.lowTrends) {
//            let lowTrendAnnualIncrease = validTrend * TimeInterval(365*24*3600)
//            let percentage = NSNumber(value: lowTrendAnnualIncrease / validStock.dailyPrices.first!.low)
//            meanTrendLabel.text = meanTrendLabel.text! + ": " + percentFormatter.string(from: percentage)!
//        }
//
//        if let minTrend = validStock.lowTrends.compactMap({ $0.incline }).min() {
//            if let maxTrend = validStock.lowTrends.compactMap({ $0.incline }).max() {
//
//                let lowTrendMinAnnualIncrease = minTrend * TimeInterval(365*24*3600)
//                let lowTrendMaxAnnualIncrease = maxTrend * TimeInterval(365*24*3600)
//
//                let minRange = NSNumber(value: lowTrendMinAnnualIncrease / validStock.dailyPrices.first!.low)
//                let maxRange = NSNumber(value: lowTrendMaxAnnualIncrease / validStock.dailyPrices.first!.low)
//
//                trendRangeLabel.text = "[" + percentFormatter.string(from: minRange)! + " - "+percentFormatter.string(from: maxRange)! + "]"
//            }
//        }
        contentView.stockToShow = validStock
//        contentView.configure()
        
    }

}
