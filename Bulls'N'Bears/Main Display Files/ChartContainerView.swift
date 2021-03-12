//
//  ChartContainerView.swift
//  TrendMyStocks
//
//  Created by aDav on 02/12/2020.
//

import UIKit

protocol ChartButtonDelegate {
    var timeButtons: [CheckButton] { get set }
    var typeButtons: [CheckButton] { get set }
    func trendButtonPressed(button: CheckButton)
}

class ChartContainerView: UIView {

    var shareToShow: Share?
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var contentView: ChartView!
    
    @IBOutlet var button1: CheckButton!
    @IBOutlet var button2: CheckButton!
    @IBOutlet var button3: CheckButton!
    
    @IBOutlet var button4: CheckButton!
    @IBOutlet var button5: CheckButton!
    @IBOutlet var button6: CheckButton!
    let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        formatter.minimumIntegerDigits = 1
        return formatter
    }()
    
    var buttonDelegate: ChartButtonDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        tintColor = UIColor.label
                
    }
    
    public func configure(with: Share) {
        
        button1.configureTrendType(title: "", color: UIColor(named: "Red")!, type: .bottom)
        button2.configureTrendType(title: "", color: UIColor.systemBlue, type: .regression)
        button3.configureTrendType(title: "", color: UIColor(named: "Green")!, type: .ceiling)
        
        button4.configureTrendTime(title: "A", color: UIColor.systemGray, trendTime: .full)
        button5.configureTrendTime(title: "3", color: UIColor.systemGray2, trendTime: .quarter)
        button6.configureTrendTime(title: "1", color: UIColor.systemGray3, trendTime: .month)
        
// button presets
        
        button6.active = true
        button6.setNeedsDisplay()
//
        shareToShow = with
        if let validLabel = titleLabel {
            validLabel.text = shareToShow?.name_long
        }
        if let view = contentView {
            view.configure(stock: with)
        }
        if let scroll = scrollView {
            scroll.contentSize = contentView.bounds.size
            let offset = scroll.contentSize.width
            scroll.setContentOffset(CGPoint(x: offset, y: 0), animated: false)
            buttonDelegate = contentView
            buttonDelegate?.timeButtons = [button4, button5, button6]
            buttonDelegate?.typeButtons = [button1, button2, button3]
        }
        
    }
    
    @IBAction func chartButtonAction(_ sender: CheckButton) {
        sender.active.toggle()
        sender.setNeedsDisplay()
        buttonDelegate?.trendButtonPressed(button: sender)
    }
    
}
