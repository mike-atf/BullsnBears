//
//  Calculator.swift
//  Bulls'N'Bears
//
//  Created by aDav on 16/02/2021.
//

import Foundation


class Calculator {
    
    class func compoundGrowthRate(endValue: Double, startValue: Double, years: Double) -> Double {
        
        return (pow((endValue / startValue) , (1/years)) - 1)
    }

    class func futureValue(present: Double, growth: Double, years: Double) -> Double {
        return present * pow((1+growth), years)
    }
    
    class func presentValue(growth: Double, years: Double, endValue: Double) -> Double {
        return endValue * (1 / pow(1+growth, years))
    }

}
