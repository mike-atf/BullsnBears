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
    
    /// returns positive proportion of max - min / mean
    class func variation(array: [Double]?) -> Double? {
        
        guard let values = array else { return nil }
        
        if let mean = values.mean() {
            
            guard mean != 0 else {
                return nil
            }
            
            if let min = values.min() {
                if let max = values.mean() {
                    return abs((max - min) / mean)
                }
            }
        }
        
        return nil
    }
    
    class func correlation(xArray: [Double]?, yArray: [Double]?) -> Correlation? {
        
        guard (yArray ?? []).count > 0 else {
            return nil
        }
        
        guard (xArray ?? []).count > 0 else {
            return nil
        }
        
        guard (xArray ?? []).count == (yArray ?? []).count else {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "Error in trend correlation: y.count != x.count")
            return nil
        }
        
        let ySum = yArray!.reduce(0,+)
        let xSum = xArray!.reduce(0,+)
        var xyProductArray = [Double]()
        var x2Array = [Double]()
        var y2Array = [Double]()
        var xySumArray = [Double]()
        let n: Double = Double(yArray!.count)

        var count = 0
        for y in yArray! {
            xyProductArray.append(y * xArray![count])
            x2Array.append(xArray![count] * xArray![count])
            xySumArray.append(y + xArray![count])
            y2Array.append(y * y)
            count += 1
        }
        
        let xyProductSum = xyProductArray.reduce(0,+)
        let x2Sum = x2Array.reduce(0,+)
        let y2Sum = y2Array.reduce(0,+)
        
        let numerator = n * xyProductSum - xSum * ySum
        let denom = (n * x2Sum - (xSum * xSum)) * (n * y2Sum - (ySum * ySum))

// Pearson correlation coefficient
        let  r = numerator / sqrt(denom)
        
        let xMean = xSum / n
        let yMean = ySum / n
        
        var xdiff2Sum = Double()
        var ydiff2Sum = Double()
        
//        count = 0
        for y in yArray! {
            let ydiff = y - yMean
            ydiff2Sum += (ydiff * ydiff)
        }
        for x in xArray! {
            let xdiff = x - xMean
            xdiff2Sum += (xdiff * xdiff)
        }
        
        let xSD = sqrt(xdiff2Sum / n)
        let ySD = sqrt(ydiff2Sum / n)
        
// m = incline of regression line
        let m = r * (ySD / xSD)
        
// b = y axis intercept of regression line
        let b = yMean - m * xMean

        return Correlation(m: m, b: b, r: r)
    }
    
    /// returns the proportions of array1 / array0
    class func proportions(array1: [Double]?, array0: [Double]?) -> [Double]? {
        
        guard let values1 = array1 else {
            return nil
        }
        
        guard let values0 = array0 else {
            return nil
        }
        
        guard values0.count == values1.count else {
            return nil
        }
        
        guard values1.count > 0 && values0.count > 0 else {
            return nil
        }
        
        var proportions = [Double]()
        
        for i in 0..<values1.count {
            if values0[i] != 0 {
                proportions.append(values1[i] / values0[i])
            }
            else {
                proportions.append(Double())
            }
        }
        
        return proportions
    }


}
