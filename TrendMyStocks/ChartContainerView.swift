//
//  ChartContainerView.swift
//  TrendMyStocks
//
//  Created by aDav on 02/12/2020.
//

import UIKit

class ChartContainerView: UIView {

    var stockToShow: Stock?
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var contentView: ChartView!
    @IBOutlet var meanTrendLabel: UILabel!
    @IBOutlet var trendRangeLabel: UILabel!
    @IBOutlet var lastDateLabel: UILabel!
    
    
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
    
    public func configure(with: Stock) {
        stockToShow = with
        if let validLabel = titleLabel {
            validLabel.text = stockToShow?.name
        }
        if let view = contentView {
            view.configure(stock: with)
        }
        if let scroll = scrollView {
            scroll.contentSize = contentView.bounds.size
            let offset = scroll.contentSize.width - scrollView.bounds.width
            scroll.setContentOffset(CGPoint(x: offset, y: 0), animated: false)
        }
        
    }
    
}
