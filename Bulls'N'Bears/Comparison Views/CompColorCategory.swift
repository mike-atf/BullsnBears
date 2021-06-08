//
//  CompColorCategory.swift
//  Bulls'N'Bears
//
//  Created by aDav on 08/06/2021.
//

import UIKit

class ComparisonColorCategory {
    
    class func findColor(biggerIsBetter: Bool, consistency: Double, growth: Double) -> UIColor {
        
        let adjustedGrowth = biggerIsBetter ? growth : growth * -1
        var categoryColor = UIColor.clear
        
        if consistency >= 0.8 {
            if adjustedGrowth >= 0.15 { categoryColor = UIColor(named: "Green")! }
            else if adjustedGrowth >= 0.1 { categoryColor = UIColor.systemYellow }
            else if adjustedGrowth >= 0.0 { categoryColor = UIColor.systemOrange }
            else { categoryColor = UIColor(named: "Red")! }
        }
        else if consistency >= 0.5 {
            if adjustedGrowth >= 0.15 { categoryColor = UIColor.systemYellow }
            else if adjustedGrowth >= 0.1 { categoryColor = UIColor.systemOrange }
            else if adjustedGrowth >= 0.0 { categoryColor = UIColor.systemOrange }
            else { categoryColor = UIColor(named: "Red")! }
        }
        else {
            categoryColor = UIColor(named: "Red")! 
        }
        
        return categoryColor
    }
}
