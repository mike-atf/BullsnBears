//
//  Calculator.swift
//  Bulls'N'Bears
//
//  Created by aDav on 16/02/2021.
//

import Foundation


class Calculator {
    
    ///calculates the compound growth rate from startValue to endValue, assuming years' time between the two
    /// end- and startValue must be either both positive or both negative, otherwise 0 as rate is returned
    /// if end- AND startValue <= 0: if endValue < startvalue (dropping) -> rate inversed to be negative; if both < 0 and endValue > startValue (rising) -> rate inversed to be positive
    /// if startValue < 0 AND endValue > 0:  -> -NaN=Double(), if startValue > 0 and endValue  < 0 -> -NaN=Double()
    class func compoundGrowthRate(endValue: Double, startValue: Double, years: Double) -> Double? {
        
        guard endValue * startValue > 0 else {
            return nil
        }
                
        let rate = pow((endValue / startValue) , (1/years)) - 1// (years-1)
        if endValue <= 0 { return rate * -1 }
        else { return rate }
    }

    /// returns a time-DESCENDING array (n-1 elements) of the compound growth rates from all values to the first value in the array ('end value')
    /// the array should be in time DESCENDING order and the time between each element is assumed to one year
    /// any placeholder (Double()) element will return a growthRate placeholder element (Double())
    class func compoundGrowthRates(values: [Double]?) -> [Double]? {
        
        guard let array = values else {
            return nil
        }
        
        guard let endValue = array.first else {
            return nil
        }
        
        var rates = [Double]()
        
        for i in 1..<array.count {
            if array[i] != 0 && array[i] != Double() {
                let rate = compoundGrowthRate(endValue: endValue, startValue: array[i], years: Double(i)) ?? Double()
                rates.append(rate)
            } else { rates.append(Double()) }
        }
        
        return rates
    }
    
    /// can be sent in ANY date order, returns rates in DESCENDING order
    class func reatesOfReturn(datedValues: [DatedValue]) -> [Double]? {
        
        guard datedValues.count > 1 else { return nil }
        
        var descending = datedValues.sortByDate(dateOrder: .descending)
        
        
        
        
        var futureValue = descending.first!.value
        if futureValue <= 0 {
            // doesn't work with negative FV
            // find next, and if positive continue, if not abandon as too far back in past
            descending.removeFirst()
            guard descending.count > 1 else { return nil }
            futureValue = descending.first!.value
            if futureValue <= 0 { return nil }
        }
        let futureDate = descending.first!.date
        
        var returns = [Double]()
        
        for i in 1..<descending.count {
            let years = futureDate.timeIntervalSince(descending[i].date) / (365*24*3600)

            if let ret = rateOfReturn(years: years, presentValue: descending[i].value, futureValue: futureValue) {
                returns.append(ret)
            }
        }
        
        return returns.filter { d in
            if d != 0.0 { return true }
            else { return false }
        }
        
    }
    
    /// can be sent in ANY date order
    class func ratesOfGrowthWithDate(datedValues: [DatedValue]) -> [DatedValue]? {
        
        guard datedValues.count > 1 else { return nil }
        
        let descending = datedValues.sortByDate(dateOrder: .descending)
        
//        let timeSpan = descending.first!.date.timeIntervalSince(descending.last!.date)
        
        let futureValue = descending.first!.value
        let futureDate = descending.first!.date
        
        var returns = [DatedValue]()
        
        for i in 1..<descending.count {
            let years = futureDate.timeIntervalSince(descending[i].date) / (365*24*3600)

            if let ret = rateOfReturn(years: years, presentValue: descending[i].value, futureValue: futureValue) {
                let dv = DatedValue(date: descending[i].date, value: ret)
                returns.append(dv)
            }
        }
        
        return returns
    }

    
    class func rateOfReturn(years: Double, presentValue: Double, futureValue: Double) -> Double? {
        
        guard years > 0 else { return nil }
        
        let ratio = futureValue / presentValue
        let exponent = 1.0 / years
        
        let rate = pow(ratio, exponent) - 1
        
        return !rate.isNaN ? rate : nil
    }
    
    /// returns a time-DESCENDING array (n-1 elements) of the year-on-year / element to next element  growth rates
    /// the array should be in time DESCENDING order and the time between each element is assumed to one year
    /// any placeholder (Double()) element will return a growthRate placeholder element (0.0)
    class func growthRatesYoY(values: [Double]?) -> [Double]? {
        
        guard let array = values else {
            return nil
        }

        guard array.count > 1 else {
            return nil
        }
        
        let timeAscendingArray = Array(array.reversed())
        var timeAscendingRates = [Double]()
        var current = timeAscendingArray.first!
        
        for i in 1..<timeAscendingArray.count {
            if current != 0 {
                let growth = (timeAscendingArray[i] - current) / abs(current)
                timeAscendingRates.append(growth)
            } else {
                timeAscendingRates.append(0.0)
            }
            current = timeAscendingArray[i]
        }
        
        return timeAscendingRates.reversed()
        
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
            ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "Error in trend correlation: y.count != x.count")
            return nil
        }
        
        // Removing any empty Double() or NaN elements
        
        var elementsToRemove = [Int]()
        for i in 0..<xArray!.count {
            if xArray![i] == Double() || yArray![i] == Double() {
                elementsToRemove.append(i)
            }
            else if xArray![i].isNaN || yArray![i].isNaN {
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
    
    /*
    /// arrays can be sent in ANY date order
    class func correlationForDVs(xArray: [DatedValue]?, yArray: [DatedValue]?) -> Correlation? {
        
        guard (yArray ?? []).count > 0 else {
            return nil
        }
        
        guard (xArray ?? []).count > 0 else {
            return nil
        }
        
        guard (xArray ?? []).count == (yArray ?? []).count else {
            ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "Error in trend correlation: y.count != x.count")
            return nil
        }
        
        let ascendingX = xArray?.sortByDate(dateOrder: .ascending)
        let ascendingY = yArray?.sortByDate(dateOrder: .ascending)
        
        // Removing any empty Double() or NaN elements
        
        var elementsToRemove = [Int]()
        for i in 0..<ascendingX!.count {
            if ascendingX![i].value == Double() || ascendingY![i].value == Double() {
                elementsToRemove.append(i)
            }
            else if ascendingX![i].value.isNaN || ascendingY![i].value.isNaN {
                elementsToRemove.append(i)
            }
        }
        
        let cleanedArrayX = ascendingX?.enumerated().filter { !elementsToRemove.contains($0.offset) }.map { $0.element} ?? []
        let cleanedArrayY = ascendingY?.enumerated().filter { !elementsToRemove.contains($0.offset) }.map { $0.element} ?? []
        
        let ySum = cleanedArrayY.compactMap{ $0.value }.reduce(0,+)
        let xSum = cleanedArrayX.compactMap{ $0.value }.reduce(0,+)
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
    */
    class func correlationDatesToValues(array: [DatedValue]?) -> Correlation? {
        
        guard (array ?? []).count > 0 else {
            return nil
        }
                
        guard let descendingDVs = array?.sortByDate(dateOrder: .descending) else {
            return nil
        }
        
        var timesInYears = [TimeInterval]()
        for i in 0..<descendingDVs.count - 1 {
            timesInYears.append(descendingDVs[i].date.timeIntervalSince(descendingDVs[i+1].date) / (365*24*3600))
        }
        
        let descendingValues = descendingDVs.dropLast(1).compactMap{ $0 .value } // drop last element as is has no previous time
        
        let ySum = timesInYears.reduce(0,+)
        let xSum = descendingValues.reduce(0,+)
        var xyProductArray = [Double]()
        var x2Array = [Double]()
        var y2Array = [Double]()
        var xySumArray = [Double]()
        let n: Double = Double(timesInYears.count)

        var count = 0
        for y in timesInYears {
            xyProductArray.append(y * descendingValues[count])
            x2Array.append(descendingValues[count] * descendingValues[count])
            xySumArray.append(y + descendingValues[count])
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
        
        for y in timesInYears {
            let ydiff = y - yMean
            ydiff2Sum += (ydiff * ydiff)
        }
        for x in descendingValues {
            let xdiff = x - xMean
            xdiff2Sum += (xdiff * xdiff)
        }
        
        let xSD = sqrt(xdiff2Sum / n)
        let ySD = sqrt(ydiff2Sum / n)
        
// m = incline of regression line
        let m = r * (ySD / xSD)
        
// b = y axis intercept of regression line
        let b = yMean - m * xMean

        return Correlation(m: m, b: b, r: r, xElements: descendingValues.count)
    }

    
    /// returns the proportions of array1 /  array0
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
    
    
    /// if two arrays are received ignores array 1 and assumes array 2 contains proportions - returns the Correlation of the proportions and years/ time of the two
    /// if one array is received returns the correlation between array values and time/ years
    class func valueChartCorrelation(arrays: [[Double]?]?) -> Correlation? {
        
        // NaN is frequently passed in compound Growth rates
        guard let array1 = arrays?.first else {
            return nil
        }
        
        var array2: [Double]?
        if arrays?.count ?? 0 > 1 {
            array2 = arrays![1]
        }
        
        var trend: Correlation?
        
        if array2?.count ?? 0 > 1 {
            // proportions - calculate trend of proportions
            // ignore array 1
            
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
