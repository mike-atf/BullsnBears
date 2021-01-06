//
//  CheckButton.swift
//  TrendMyStocks
//
//  Created by aDav on 14/12/2020.
//

import UIKit

class CheckButton: UIButton {

    var color: UIColor!
    var active = false
    var associatedTrendTime: TrendTimeOption?
    var associatedTrendType: TrendType?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.color = UIColor.label
        backgroundColor = UIColor.clear
    }
    
    func configureTrendTime(title: String, color: UIColor, trendTime: TrendTimeOption) {
        self.setTitle(title, for: .normal)
        self.color = color
        self.associatedTrendTime = trendTime
    }
    
    func configureTrendType(title: String, color: UIColor, type: TrendType) {
        self.setTitle(title, for: .normal)
        self.color = color
        self.associatedTrendType = type
    }

    override func draw(_ rect: CGRect) {
        let square = UIBezierPath(roundedRect: rect.insetBy(dx: 2.5, dy: 2.5), cornerRadius: 5.0)
        square.lineWidth = 2.5
        color.setStroke()
        square.stroke()
        
        if active {
            color.setFill()
            square.fill()
            UIColor.label.setStroke()
            square.stroke()
        }
        
    }

}
