//
//  Extensions.swift
//  Bulls'N'Bears
//
//  Created by aDav on 14/01/2021.
//

import UIKit

extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}


extension Double? {
    
    /// returns fraction number  with 'B', 'M', 'K' or no letter at the end
    /// for nil value returns empty String element
    func shortString(decimals: Int, formatter: NumberFormatter?=nil ,nilString: String? = "-") -> String {
                
        let defaultFormatter: NumberFormatter = {
            if decimals == 0 {
                return currencyFormatterNoGapNoPence
            }
            else  {
                return currencyFormatterNoGapWithPence
            }
        }()

        let formatter = formatter ?? defaultFormatter
        
        var shortString = nilString ?? String()
        
        guard let element = self else { return  shortString }
        
        if abs(element)/1000000000000 > 1 {
            let shortValue = element/1000000000000
            shortString = (formatter.string(from: shortValue  as NSNumber) ?? "-") + "T"
        }
        else if abs(element)/1000000000 > 1 {
            let shortValue = element/1000000000
            shortString = (formatter.string(from: shortValue  as NSNumber) ?? "-") + "B"
        } else if abs(element)/1000000 > 1 {
            let shortValue = element/1000000
            shortString = (formatter.string(from: shortValue  as NSNumber) ?? "-") + "M"
        }
        else if abs(element)/1000 > 1 {
            let shortValue = element/1000
            shortString = (formatter.string(from: shortValue  as NSNumber) ?? "-") + "K"
        } else {
            shortString = (formatter.string(from: element  as NSNumber) ?? "-")
        }
        
        return shortString
    }

}

extension Double {
    
    /// returns fraction number  with 'B', 'M', 'K' or no letter at the end
    func shortString(decimals: Int, formatter: NumberFormatter?=nil) -> String {
        
        let defaultFormatter: NumberFormatter = {
            if decimals == 0 {
                return currencyFormatterNoGapNoPence
            }
            else  {
                return currencyFormatterNoGapWithPence
            }
        }()

        let formatter = formatter ?? defaultFormatter
        var shortString = String()
        
        if abs(self)/1000000000000 > 1 {
            let shortValue = self/1000000000000
            shortString = (formatter.string(from: shortValue  as NSNumber) ?? "-") + "T"
        }
        else if abs(self)/1000000000 > 1 {
            let shortValue = self/1000000000
            shortString = (formatter.string(from: shortValue  as NSNumber) ?? "-") + "B"
        } else if abs(self)/1000000 > 1 {
            let shortValue = self/1000000
            shortString = (formatter.string(from: shortValue  as NSNumber) ?? "-") + "M"
        }
        else if abs(self)/1000 > 1 {
            let shortValue = self/1000
            shortString = (formatter.string(from: shortValue  as NSNumber) ?? "-") + "K"
        } else {
            shortString = (formatter.string(from: self  as NSNumber) ?? "-")
        }
        
        return shortString
    }

}

extension Array where Element == Double {
    
    /// returns fraction number  with 'B', 'M', 'K' or no letter at the end
    func shortStrings(decimals: Int, formatter: NumberFormatter?=nil, nilString: String? = "-") -> [String] {
                
        var shortStrings = [String]()
        
        for element in self {
            
            shortStrings.append(element.shortString(decimals: decimals, formatter: formatter))
            
        }
        
        return shortStrings
    }
    
    mutating func add(value: Double, index: Int) {
                
        if self.count > index {
            self[index] = value
        }
        else {
            self.append(value)
        }
    }

    func excludeQuintiles() -> [Double] {
                
        guard self.count > 4 else {
            return self
        }
        
        let sorted = self.sorted()
        
        let lower_quintile = Int(sorted.count/5)
        let upper_quintile = Int(sorted.count * 4/5)
        
        return Array(sorted[lower_quintile...upper_quintile])
    }
    
    func excludeQuartiles() -> [Double] {
                
        guard self.count > 3 else {
            return self
        }
        
        let sorted = self.sorted()
        
        let lower_quintile = Int(sorted.count/4)
        let upper_quintile = Int(sorted.count * 3/4)
        
        return Array(sorted[lower_quintile...upper_quintile])
    }
    
    func median() -> Double? {
        
        guard self.count > 1 else {
            return nil
        }
        
        let median = Int(self.count / 2)
        
        return self.sorted()[median]
    }
    
    func mean() -> Double? {
        
        guard self.count > 0 else {
            return nil
        }
        
        let sum = self.reduce(0, +)
        
        if count > 0 {
            return sum / Double(self.count)
        }
        else { return nil }
    }
    
    /// assumes (time) ordered array
    /// with element given the largest weights first and the smallest last
    /// (time) distance between array elements are assumed to be equal (e.g. one year)
    func weightedMean() -> Double? {
        
        guard self.count > 0 else {
            return nil
        }
        
        
        var sum = 0.0
        var weightSum = 0.0

        for i in 0..<self.count {
            if self[i] != Double() {
                let weight = (1/Double(i+1))
                sum += weight * self[i]
                weightSum += weight
            }
        }
        
        if weightSum > 0 {
            return sum / weightSum
        }
        else { return nil }
    }
    
    func average(of first: Int) -> Double? {
    
        guard first > 1 else {
            return nil
        }
        
        guard first < self.count else {
            return nil
        }
        
        var sum = 0.0
        for i in 0..<first {
            sum += self[i]
        }
        
        return sum / (Double(first))
    }
    
    /// assumes array is in DESCENDING order
    /// periods is the number of elements to build a moving average for
    /// periods must be greater thn 2 and smaller than array.count-2
    /// use reverse() if it isn't
    func ema(periods: Int) -> Double? {
        
        guard periods > 2 else { return nil }
        
        let noNaN = self.filter { element in
            if !element.isNaN { return true }
            else { return false }
        }
        
        var appliedPeriods = periods
        if noNaN.count < periods+2 {
            appliedPeriods = Int(Double(noNaN.count * 7/12))
            
        }
        
        guard appliedPeriods > 2 else {
            return nil
        }
        
        let ascending = Array(noNaN.reversed())
        
        var sum = Double()
        for i in 0..<appliedPeriods {
            sum += ascending[i]
        }
        let sma = sum / Double(appliedPeriods)
        
        var ema = sma
        
        for i in appliedPeriods..<noNaN.count {
            if ascending[i] != Double() {
                ema = ascending[i] * (2/(Double(appliedPeriods+1))) + ema * (1 - 2/(Double(appliedPeriods+1)))
            }
        }
        
        return ema
    }
    
    func stdVariation() -> Double? {
        
        guard self.count > 1 else {
            return nil
        }
        
        guard let mean = self.mean() else {
            return nil
        }
        
        var differenceSquares = [Double]()
        
        for element in self {
            differenceSquares.append((element - mean) * (element - mean))
        }
        
        let variance = differenceSquares.reduce(0, +)
        
        return sqrt(variance)
    }

    
    /// calculates growth rates from current to preceding element
    /// should have elemetns in time-descending order!
    /// return n-1 elements
    /// can include empty placeholder Double() elements instead of nil
    func growthRates() -> [Double]? {
        
        guard self.count > 1 else {
            return nil
        }
        
        var rates = [Double]()
        
        for i in 0..<self.count - 1 {
            if self[i] == Double() {
                rates.append(Double())
            }
            else if self[i+1] != 0 {
                rates.append((self[i] - self[i+1]) / abs(self[i+1]))
            }
            else { rates.append(Double()) }
        }

        return rates
    }
    
    /// can include empty placeholder Double() elements instead of nil
    func positives() -> [Double]? {
        
        guard self.count > 1 else {
            return nil
        }

        let max = self.max()!
        let min = self.min()!
        
        if max * min > 0 {
            // either all values positive or all  negative
            
            return self.compactMap{ abs($0) }
        }
        else {
            // either 0 (shouldn't) or some postive and some negative values
            return self.compactMap{ $0 * -1 }
        }
    }

    /// returns the fraction of elements that are same or higher than the previous (if increaseIsBetter) or same or lower than previous (is iiB = false
    /// assumes array is DESCENDING in order
    /// return placeholder Double() if unable to calculate
    func consistency(increaseIsBetter: Bool) -> Double {
        
        let nonNilElements = self.compactMap({$0})
        let noPlaceHolderElements = nonNilElements.filter { element in
            if element == Double() { return false }
            else { return true }
        }
    
        guard noPlaceHolderElements.count > 1 else {
            return Double()
        }
        
        var lastNonNilElement = noPlaceHolderElements[0]
        
        var consistentCount = 1
        for i in 1..<noPlaceHolderElements.count {
            if increaseIsBetter {
                if noPlaceHolderElements[i] <= lastNonNilElement { // DESCENDING order!
                    consistentCount += 1
                }
            }
            else {
                if noPlaceHolderElements[i] >= lastNonNilElement {
                    consistentCount += 1
                }
            }
            lastNonNilElement = noPlaceHolderElements[i]
        }
        
        return Double(consistentCount) / Double(nonNilElements.count)
    }

}

extension Array where Element == Double? {
    
    /// returns fraction number  with 'B', 'M', 'K' or no letter at the end
    /// for nil values returns empty String element
    func shortStrings(decimals: Int, formatter: NumberFormatter?=nil ,nilString: String? = "-") -> [String] {
                
        var shortStrings = [String]()
        
        for element in self {
            
            shortStrings.append(element.shortString(decimals: decimals, formatter: formatter))
            
        }
        
        return shortStrings
    }

    /// calculates growth rates from current to next element
    /// should have elemetns in descending order!
    /// i.e. the following element is younger/ usually smaller
    /// return n-1 elements
    func growthRates() -> [Double?]? {
        
        guard self.count > 1 else {
            return nil
        }
        
        var rates = [Double?]()
        
        var hold: Double?
        var steps = 1
        for i in 0..<self.count - 1 {
            if let valid = hold ?? self[i] {
                if let validNext = self[i+1] {
                    for _ in 0..<steps {
                        rates.append((valid - validNext) / (validNext * Double(steps)))
                    }
                    hold = nil
                    steps = 1
                }
                else {
                    // validNext empty
                    hold = valid
                    steps += 1
                }
            }
            else {
                // valid empty
                rates.append(nil)
            }
        }

        return rates
    }
    
    /// calculates the absolute growth = difference element to previous element
    /// array should be sorted in DESCENDING order
    /// returns n-1 elements
    func growth() -> [Double?]? {
        
        guard self.count > 1 else {
            return nil
        }

        var difference = [Double?]()
        var hold: Double?
        var steps = 1
        for i in 0..<self.count - 1 {
            if let valid = hold ?? self[i] {
                if let validNext = self[i+1] {
                    for _ in 0..<steps {
                        difference.append((valid - validNext) / Double(steps))
                    }
                    hold = nil
                    steps = 1
                }
                else {
                    // validNext empty
                    hold = valid
                    steps += 1
                }
            }
            else {
                // valid empty
                difference.append(nil)
            }
        }

        return difference
    }
    
    /// assumes (time) ordered array
    /// with element given the largest weights first and the smallest last
    /// (time) distance between array elements are assumed to be equal (e.g. one year)
    func weightedMean() -> Double? {
        
        guard self.count > 0 else {
            return nil
        }
        
        var sum = 0.0
        var weightSum = 0.0

        for i in 0..<self.count {
            if let valid = self[i] {
                let weight = (1/Double(i+1))
                sum += weight * valid
                weightSum += weight
            }
        }
        
        if weightSum > 0 {
            return sum / weightSum
        }
        else { return nil }
    }
        
    func mean() -> Double? {
        
        guard self.count > 0 else {
            return nil
        }
        
        let sum = self.compactMap{$0}.reduce(0, +)
        
        var validsCount = 0.0
        
        for element in self {
            if element != nil {
                validsCount += 1.0
            }
        }
        
        if validsCount > 0 {
            return sum / validsCount
        }
        else { return nil }
    }

    
    func stdVariation() -> Double? {
        
        guard self.count > 1 else {
            return nil
        }
        
        guard let mean = self.mean() else {
            return nil
        }
        
        var differenceSquares = [Double]()
        var validsCount = 0.0
        
        for element in self {
            if element != nil {
                validsCount += 1.0
                differenceSquares.append((element! - mean) * (element! - mean))
            }
        }
        
        let variance = differenceSquares.reduce(0, +)
        
        return sqrt(variance)
    }
    
    func excludeQuartiles() -> [Double] {
                
        let cleaned = self.compactMap{$0}
        
        guard cleaned.count > 3 else {
            return cleaned
        }
        
        let sorted = cleaned.sorted()
        
        let lower_quintile = Int(sorted.count/4)
        let upper_quintile = Int(sorted.count * 3/4)
        
        var array = [Double]()
        for i in lower_quintile...upper_quintile {
            array.append(sorted[i])
        }
        
        return array
    }
    
    /// for odd-number array provides true median
    /// for even number array provides average of two middle-elements
    func median() -> Double? {
        
        guard self.count > 0 else {
            return nil
        }
        
        guard self.count > 1 else {
            return self[0]
        }
        
        var median: Double?
        
        let ranked = self.compactMap { $0 }.sorted()
        let medianElement = Double(ranked.count) / 2.0
        if medianElement != Double(Int(medianElement)) {
            // odd number of elements
            median = ranked[Int(medianElement)]
        } else {
            // even number - use average of two center elements
            median = (ranked[Int(medianElement)] + ranked[Int(medianElement)+1]) / 2
        }
        
        return median
    }
    
    /// returns the fraction of elements that are same or higher than the previous (if increaseIsBetter) or same or lower than previous (is iiB = false
    /// assumes array is DESCENDING in order
    func consistency(increaseIsBetter: Bool) -> Double? {
        
        let nonNilElements = self.compactMap({$0})
        let noPlaceHolderElements = nonNilElements.filter { element in
            if element == Double() { return false }
            else { return true }
        }
    
        guard noPlaceHolderElements.count > 1 else {
            return nil
        }
        
        var lastNonNilElement = noPlaceHolderElements[0]
        
        var consistentCount = 1
        for i in 1..<noPlaceHolderElements.count {
            if increaseIsBetter {
                if noPlaceHolderElements[i] >= lastNonNilElement {
                    consistentCount += 1
                }
            }
            else {
                if noPlaceHolderElements[i] <= lastNonNilElement {
                    consistentCount += 1
                }
            }
            lastNonNilElement = noPlaceHolderElements[i]
        }
        
        return Double(consistentCount) / Double(nonNilElements.count)
    }
}

extension UILabel {
    /// Sets the attributedText property of UILabel with an attributed string
    /// that displays the characters of the text at the given indices in subscript.
    func setAttributedTextWithSuperscripts(text: String, indicesOfSuperscripts: [Int]) {
        let font = self.font!
        let subscriptFont = font.withSize(font.pointSize * 0.7)
        let subscriptOffset = font.pointSize * 0.3
        let attributedString = NSMutableAttributedString(string: text,
                                                         attributes: [.font : font])
        for index in indicesOfSuperscripts {
            let range = NSRange(location: index, length: 1)
            attributedString.setAttributes([.font: subscriptFont,
                                            .baselineOffset: subscriptOffset],
                                           range: range)
        }
        self.attributedText = attributedString
    }
}

//
//  HTTPCookie+Arquiver.swift
//  Created by Antoine Barrault on 17/01/2018.
//

extension HTTPCookie {

    fileprivate func save(cookieProperties: [HTTPCookiePropertyKey : Any]) -> Data? {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: cookieProperties, requiringSecureCoding: false)
            return data
        } catch let error {
            ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error converting website cookies into data object")
        }
        return nil
    }

    static fileprivate func loadCookieProperties(from data: Data) -> [HTTPCookiePropertyKey : Any]? {
        do {
            let unarchivedDictionary = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [HTTPCookiePropertyKey : Any]
            return unarchivedDictionary
        } catch let error {
            ErrorController.addInternalError(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error converting website cookies into data object")
        }
        return nil
    }

    static func loadCookie(using data: Data?) -> HTTPCookie? {
        guard let data = data,
            let properties = loadCookieProperties(from: data) else {
                return nil
        }
        return HTTPCookie(properties: properties)
    }

    func archive() -> Data? {
        guard let properties = self.properties else {
            return nil
        }
        return save(cookieProperties: properties)
    }

}

extension UIImage {
    
    func getPixelColor(pos: CGPoint) -> UIColor {
        
        guard !pos.y.isNaN else {
            return UIColor.systemBackground
        }
        
        let pixelData = self.cgImage!.dataProvider!.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        let pixelInfo: Int = ((Int(self.size.width) * Int(pos.y)) + Int(pos.x)) * 4
        
        let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

extension UIView {
    func getPixelColor(fromPoint: CGPoint) -> UIColor {
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitMapInfo =  CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        var pixel: [CUnsignedChar] = [0,0,0,0]
        
        let context = CGContext(data: &pixel,width: 1,height: 1,bitsPerComponent: 8,bytesPerRow: 4, space: colorSpace, bitmapInfo: bitMapInfo.rawValue)
        context?.translateBy(x: -fromPoint.x, y: -fromPoint.y)
        self.layer.render(in: context!)
        
        let r = CGFloat(pixel[0]) / CGFloat(255.0)
        let g = CGFloat(pixel[1]) / CGFloat(255.0)
        let b = CGFloat(pixel[2]) / CGFloat(255.0)
        let a = CGFloat(pixel[3]) / CGFloat(255.0)
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

extension Array where Element == CGFloat {
    
    func mean() -> CGFloat? {
        
        guard self.count > 0 else {
            return nil
        }
        
        let sum = self.reduce(0, +)
        
        if count > 0 {
            return sum / CGFloat(self.count)
        }
        else { return nil }
    }

}
