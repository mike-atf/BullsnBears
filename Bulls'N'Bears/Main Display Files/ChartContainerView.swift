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
    @IBOutlet var chartsContentView: UIView!
    @IBOutlet var chartsContentViewWidth: NSLayoutConstraint!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var chartView: ChartView!
    @IBOutlet var macdView: MACD_View!
    @IBOutlet var stochOscView: StochastikOscillatorView!
    @IBOutlet var timeLineView: ChartTimeLineView!
    @IBOutlet var chartPricesView: ChartPricesView!
    
    @IBOutlet var button1: CheckButton!
    @IBOutlet var button2: CheckButton!
    @IBOutlet var button3: CheckButton!
    
    @IBOutlet var button4: CheckButton!
    @IBOutlet var button5: CheckButton!
    @IBOutlet var button6: CheckButton!
    @IBOutlet var chartLegendView: ChartLegendView!
    @IBOutlet var chartZoomControl: UISegmentedControl!
    var zoomScale: CGFloat = 1.0
    
    let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        formatter.minimumIntegerDigits = 1
        return formatter
    }()
    
    var buttonDelegate: ChartButtonDelegate?
//    var zoomFactor: CGFloat!
    
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
        
        //MARK:- button presets
        button6.active = true
        button6.setNeedsDisplay()

        shareToShow = with
        
        if let view = chartView {
            view.configure(stock: with)
        }
        
        if let view = macdView {
            view.configure(share: shareToShow)
        }

        if let view = stochOscView {
            view.configure(share: shareToShow)
        }
        
        if let view = chartPricesView {
            view.configure(share: shareToShow)
        }

        if let view = timeLineView {
            view.configure(share: shareToShow)
        }
        if let scroll = scrollView {
            
            scroll.minimumZoomScale = 0.01
            scroll.maximumZoomScale = 50.0
            scroll.zoomScale = 1.0
//            scroll.pinchGestureRecognizer?.addTarget(self, action: #selector(customZoom(pinchGesture:)))
            chartZoomControl.selectedSegmentIndex = 4

            scroll.contentSize = chartView.bounds.size
            let offset = scroll.contentSize.width
            scroll.setContentOffset(CGPoint(x: offset, y: 0), animated: false)
            buttonDelegate = chartView
            buttonDelegate?.timeButtons = [button4, button5, button6]
            buttonDelegate?.typeButtons = [button1, button2, button3]
            
//            zoomFactor = 1.0
        }
        
        chartLegendView.configure(share: shareToShow, parent: self)
        
    }
        
    @IBAction func chartZoomAction(_ sender: Any) {
        
        if let control = sender as? UISegmentedControl {
            let allDaysAvailable = shareToShow?.getDailyPrices()?.count ?? 1
            let daysToDisplay = [30,91,182,365,allDaysAvailable][control.selectedSegmentIndex]
            
//            print()
//            print("display days set to \(daysToDisplay)")
//            print("previous zoomScale \(zoomScale)")
//            print("previous width.constant = \(chartsContentViewWidth.constant)")
            zoomScale = CGFloat(allDaysAvailable) / CGFloat(daysToDisplay)
            chartsContentViewWidth.isActive = false
            chartsContentViewWidth.constant = scrollView.bounds.width * zoomScale
            chartsContentViewWidth.isActive = true
//            print("new zoomScale \(zoomScale)")
//            print("new width.constant = \(chartsContentViewWidth.constant)")
            
            var foreCastTimeArea: CGFloat = 0
            if control.selectedSegmentIndex < 4 {
                let forecastDays = (foreCastTime / (24*3600))
                foreCastTimeArea = chartsContentViewWidth.constant * (CGFloat(forecastDays) / CGFloat(allDaysAvailable))
            }
            
//            print("new foreCastTimeArea \(foreCastTimeArea)")
//            print("new contentOffset = \(scrollView.contentOffset.x)")

            stochOscView.setNeedsDisplay()
            macdView.setNeedsDisplay()
            chartView.setNeedsDisplay()
            scrollView.contentSize = CGSize(width: chartsContentViewWidth.constant, height: chartsContentView.bounds.size.height)
            scrollView.setContentOffset(CGPoint(x: scrollView.bounds.width * zoomScale - scrollView.bounds.width - foreCastTimeArea, y: 0), animated: true)
            timeLineView.resetAfterZoom()

        }
        
    }
    
    
    @IBAction func chartButtonAction(_ sender: CheckButton) {
        sender.active.toggle()
        sender.setNeedsDisplay()
        buttonDelegate?.trendButtonPressed(button: sender)
    }
    
//    @objc
//    func customZoom(pinchGesture: UIPinchGestureRecognizer) {
//
//        let change = pinchGesture.scale - 1.0
//        var modifiedScale = 1.0 + change * scrollView.frame.width / scrollView.contentSize.width
//
//
//        if modifiedScale > 1.0 {
//            if chartsContentViewWidth.constant > 6440 {
//                modifiedScale = 1.0
//            }
//        }
//        else if chartsContentViewWidth.constant <= scrollView.bounds.width {
//            chartsContentViewWidth.isActive = false
//            chartsContentViewWidth.constant = scrollView.bounds.width
//            chartsContentViewWidth.isActive = true
//            modifiedScale = 1.0
//            return
//        }
//
//        UIView.animate(withDuration: 0) {
//            self.chartsContentView.transform = CGAffineTransform(scaleX: modifiedScale, y: 1.0)
//            self.chartsContentViewWidth.constant *= modifiedScale
//        }
//
//        if pinchGesture.state == .ended {
//            scrollView.zoomScale = modifiedScale
//            macdView.setNeedsDisplay()
//            stochOscView.setNeedsDisplay()
//            chartView.setNeedsDisplay()
//            timeLineView.resetAfterZoom()
//
//            scrollView.contentSize = chartView.bounds.size
//            let offset = scrollView.contentSize.width
//            scrollView.setContentOffset(CGPoint(x: offset, y: 0), animated: false)
//        }
//            }
    
}
