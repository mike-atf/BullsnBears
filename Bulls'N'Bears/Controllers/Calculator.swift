//
//  Calculator.swift
//  Bulls'N'Bears
//
//  Created by aDav on 16/02/2021.
//

import Foundation


class Calculator {
    
    class func compoundGrowthRate(endValue: Double, startValue: Double, years: Double) -> Double {
        
        return (pow((endValue / startValue) , (1/(years-1))) - 1)
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
        
        // Removing any empty Double() elements
        
        var elementsToRemove = [Int]()
        for i in 0..<xArray!.count {
            if xArray![i] == Double() || yArray![i] == Double() {
                elementsToRemove.append(i)
            }
        }
        
        let cleanedArrayX = xArray?.enumerated().filter { !elementsToRemove.contains($0.offset) }.map { $0.element} ?? []
        let cleanedArrayY = yArray?.enumerated().filter { !elementsToRemove.contains($0.offset) }.map { $0.element} ?? []
        
        let ySum = cleanedArrayY.reduce(0,+)
        let xSum = cleanedArrayX.reduce(0,+)
        var xyProductArray = [Double]()
        var x2Array = [Double]()
        var y2Array = [Double]()
        var xySumArray = [Double]()
        let n: Double = Double(cleanedArrayY.count)

        var count = 0
        for y in cleanedArrayY {
            xyProductArray.append(y * cleanedArrayX[count])
            x2Array.append(cleanedArrayX[count] * cleanedArrayX[count])
            xySumArray.append(y + cleanedArrayX[count])
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
        
        for y in cleanedArrayY {
            let ydiff = y - yMean
            ydiff2Sum += (ydiff * ydiff)
        }
        for x in cleanedArrayX {
            let xdiff = x - xMean
            xdiff2Sum += (xdiff * xdiff)
        }
        
        let xSD = sqrt(xdiff2Sum / n)
        let ySD = sqrt(ydiff2Sum / n)
        
// m = incline of regression line
        let m = r * (ySD / xSD)
        
// b = y axis intercept of regression line
        let b = yMean - m * xMean

        return Correlation(m: m, b: b, r: r, xElements: cleanedArrayX.count)
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
    
    class func valueChartCorrelation(arrays: [[Double]?]?) -> Correlation? {
        
        guard let array1 = arrays?.first else {
            return nil
        }
        
        var array2: [Double]?
        if arrays?.count ?? 0 > 0 {
            array2 = arrays![1]
        }
        
        var trend: Correlation?
        
        if array2?.count ?? 0 > 1 {
            // proportions - calculate trend of proportions
            
            var years = [Double]()
            var count = 1.0 // important to start with 1.0 to avoid dropping 0 element in correlation
            for _ in array2! {
                years.append(count)
                count += 1.0
            }

            trend = Calculator.correlation(xArray: years, yArray: array2?.reversed())
        } else if (array1 ?? [])?.count ?? 0 > 1 {
            // values only, no proportions - calculate values trend
            
            var years = [Double]()
            var count = 1.0 // important to avoid dropping 0 element in correlation
            for _ in (array1 ?? []) {
                years.append(count)
                count += 1.0
            }

            trend = Calculator.correlation(xArray: years, yArray: array1?.reversed())
        }
        
        return trend

    }
}
