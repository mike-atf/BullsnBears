//
//  GradientColorFinder.swift
//  Bulls'N'Bears
//
//  Created by aDav on 24/02/2021.
//

import UIKit

class GradientColorFinder: NSObject {
    
    class func gradientColor(lowerIsGreen: Bool, min: Double, max: Double, value: Double, greenCutoff: Double?=nil, redCutOff: Double?=nil) -> UIColor {
        
        let range = max - min
        var relativeValue = CGFloat()
        
        if lowerIsGreen {
            
            if let validGreenCutoff = greenCutoff {
                if value < validGreenCutoff { return greenGradientColor() }
                else if value > redCutOff! { return redGradientColor() }
                else {
                    relativeValue = CGFloat(value - validGreenCutoff) / CGFloat(redCutOff! - validGreenCutoff)
                    return gradientBar!.getPixelColor(pos: CGPoint(x: 2, y: relativeValue * gradientBarHeight))
                }
            }
            
            relativeValue = CGFloat(value / range)
        }
        else {
            // lowerIsRed
            if let validGreenCutoff = greenCutoff {
                if value > validGreenCutoff { return greenGradientColor() }
                else if value < redCutOff! { return redGradientColor() }
                else {
                    relativeValue = 1 - CGFloat(value - redCutOff!) / CGFloat(validGreenCutoff - redCutOff!)
                    return gradientBar!.getPixelColor(pos: CGPoint(x: 2, y: relativeValue * gradientBarHeight))
                }
            }
            
            relativeValue = 1 - CGFloat(value / range)
        }
        
        return gradientBar!.getPixelColor(pos: CGPoint(x: 2, y: relativeValue * gradientBarHeight))
    }
    
    class func redGradientColor() -> UIColor {
        return gradientBar!.getPixelColor(pos: CGPoint(x: 2, y: 0.99 * gradientBarHeight))
    }
    
    class func greenGradientColor() -> UIColor {
        return gradientBar!.getPixelColor(pos: CGPoint(x: 2, y: 0.01 * gradientBarHeight))
    }
    
    class func cleanRatingColor(for rating: Int, higherIsBetter:Bool) -> UIColor {
        
//        let modRating = higherIsBetter ? rating : (10-rating)
        switch rating {
        case ...2:
            return UIColor.systemRed
        case 2...5:
            return UIColor.systemOrange
        case 5...7:
            return UIColor.systemYellow
        case 7...:
            return UIColor.systemGreen
        default:
            return UIColor.systemGray
        }

    }
}
