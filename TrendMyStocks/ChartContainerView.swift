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
    
    @IBOutlet var button1: CheckButton!
    @IBOutlet var button2: CheckButton!
    @IBOutlet var button3: CheckButton!
    
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
        tintColor = UIColor.label
                
    }
    
    public func configure(with: Stock) {
        
        button1.configure(title: "", color: UIColor(named: "Red")!)
        button2.configure(title: "", color: UIColor.systemBlue)
        button3.configure(title: "", color: UIColor(named: "Green")!)
        
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
    
    @IBAction func button3Action(_ sender: CheckButton) {
        sender.active.toggle()
        sender.setNeedsDisplay()
        
        contentView.drawHighs = sender.active
        contentView.setNeedsDisplay()
    }
    
    @IBAction func button2Action(_ sender: CheckButton) {
        sender.active.toggle()
        sender.setNeedsDisplay()
        
        contentView.drawRegression = sender.active
        contentView.setNeedsDisplay()

    }
    
    @IBAction func button1Action(_ sender: CheckButton) {
        sender.active.toggle()
        sender.setNeedsDisplay()
        
        contentView.drawLows = sender.active
        contentView.setNeedsDisplay()
        
    }
}
