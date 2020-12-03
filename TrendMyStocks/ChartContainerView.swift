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
        contentView.stockToShow = validStock
        contentView.configure()
//        contentView.setNeedsDisplay()
        
    }

}
