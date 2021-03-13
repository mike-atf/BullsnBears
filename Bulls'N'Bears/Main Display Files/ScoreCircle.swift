//
//  ScoreCircle.swift
//  Bulls'N'Bears
//
//  Created by aDav on 06/03/2021.
//

import UIKit

class ScoreCircle: UIView {

    var scoreRatio:CGFloat = 0
    var symbol: RatingCircleSymbols!
    let π: CGFloat = CGFloat(Double.pi)
    let margin: CGFloat = 5.0
    let circleSegment: CGFloat = 2 * CGFloat(Double.pi) / 4
    let circleColors = [UIColor.systemRed, UIColor.systemOrange, UIColor.systemYellow, UIColor.systemGreen]
    var fillColor = UIColor.systemBackground
    var centerImageView: UIImageView!


    func configure(ratingStruct: RatingCircleData?) {
               
        guard let validData = ratingStruct else {
            self.isHidden = true
            return
        }
        
        guard let validRatio = validData.ratingScore() else { return }
        
        self.isHidden = false
        
        self.scoreRatio = CGFloat(validRatio)
        self.symbol = validData.symbol

        if scoreRatio > 1 { scoreRatio = 1.0 }
        else if scoreRatio < 0 { scoreRatio = 0 }
        
        if scoreRatio < 0.25 {
            fillColor = UIColor.systemRed
        }
        else if scoreRatio < 0.5 {
            fillColor = UIColor.systemOrange
        }
        else if scoreRatio < 0.75 {
            fillColor = UIColor.systemYellow
        }
        else {
            fillColor = UIColor.systemGreen
        }
        
        setNeedsDisplay()

        if symbol == .star {
            centerImageView = UIImageView(image: UIImage(systemName: "star.circle")!)
        } else {
            centerImageView = UIImageView(image: UIImage(systemName: "dollarsign.circle")!)
        }

        centerImageView.tintColor = UIColor.systemGray
        addSubview(centerImageView)
        centerImageView.translatesAutoresizingMaskIntoConstraints = false
        
        centerImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        centerImageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        centerImageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.6).isActive = true
        centerImageView.widthAnchor.constraint(equalTo: centerImageView.heightAnchor).isActive = true
        
    }
    
    override func draw(_ rect: CGRect) {
        
        let startAngle = 2 * π // ('eats' - rotated to 'north' below)
        let lineWidth = rect.height * 0.2 + 2
        let endAngle = startAngle - scoreRatio * 2 * π
        let radius = (rect.height - 2) / 2 //- margin - lineWidth / 2
        let centerPoint = CGPoint(x: rect.height / 2, y: rect.width / 2)

        let circleRim = UIBezierPath()
        circleRim.addArc(withCenter: centerPoint, radius: (radius), startAngle: 2 * π, endAngle: 0, clockwise: false)
        UIColor.systemGray3.setStroke()
        circleRim.lineWidth = 2
        circleRim.stroke()
        
        let context = UIGraphicsGetCurrentContext()

        context!.saveGState()
        context!.translateBy(x: 0, y: rect.height)
        context!.rotate(by: -π / 2)
        
        let filledSegment = UIBezierPath()
        filledSegment.addArc(withCenter: centerPoint, radius: rect.height * 0.4 - 3, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        filledSegment.lineWidth = lineWidth
        fillColor.setStroke()
        filledSegment.stroke()

        context!.restoreGState()

    }

}