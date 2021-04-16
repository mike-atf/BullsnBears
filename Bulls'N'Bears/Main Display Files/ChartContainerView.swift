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
    @IBOutlet var chartsContentView: UIView!
    @IBOutlet var chartsContentViewWidth: NSLayoutConstraint!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var chartView: ChartView!
    @IBOutlet var macdView: MACD_View!
    @IBOutlet var stochOscView: StochastikOscillatorView!
    
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
    var zoomFactor: CGFloat!
    var contentOffsetFromRight : CGFloat {
        set {
            self.scrollView.isScrollEnabled = false
            self.scrollView.setContentOffset(CGPoint(x: self.scrollView.contentSize.width - self.scrollView.frame.width, y: 0), animated: false)
            self.scrollView.isScrollEnabled = true
        }
        get {
            return self.scrollView.contentSize.width - self.scrollView.frame.width - self.scrollView.contentOffset.x
        }
    }
 
    
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
        
        if let view = chartView {
            view.configure(stock: with)
        }
        
        if let view = macdView {
            view.configure(share: shareToShow)
        }

        if let view = stochOscView {
            view.configure(share: shareToShow)
        }

        if let scroll = scrollView {
//            scroll.delegate = self
            scroll.minimumZoomScale = 0.2
            scroll.maximumZoomScale = 2.0
            scroll.zoomScale = 1.0
            scroll.pinchGestureRecognizer?.addTarget(self, action: #selector(customZoom(pinchGesture:)))

            scroll.contentSize = chartView.bounds.size
            let offset = scroll.contentSize.width
            scroll.setContentOffset(CGPoint(x: offset, y: 0), animated: false)
            buttonDelegate = chartView
            buttonDelegate?.timeButtons = [button4, button5, button6]
            buttonDelegate?.typeButtons = [button1, button2, button3]
            
            zoomFactor = 1.0
        }
        
    }
    
    @IBAction func chartButtonAction(_ sender: CheckButton) {
        sender.active.toggle()
        sender.setNeedsDisplay()
        buttonDelegate?.trendButtonPressed(button: sender)
    }
    
    @objc
    func customZoom(pinchGesture: UIPinchGestureRecognizer) {
        
        let currentWidth = chartsContentViewWidth.constant
        let change = (pinchGesture.scale > 1.0) ? currentWidth * 0.025 : currentWidth * -0.025
        let newWidth = currentWidth + change

        
        guard newWidth < 6640 && newWidth > scrollView.bounds.width else {
            return
        }
        
        chartsContentViewWidth.constant = newWidth
        chartsContentView.setNeedsDisplay()
        macdView.setNeedsDisplay()
        stochOscView.setNeedsDisplay()
        chartView.setNeedsDisplay()
//        contentOffsetFromRight = 0.0
//        self.scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x + change , y: 0.0), animated: true)
        
        zoomFactor = change
    }

    
}
