//
//  Extensions.swift
//  Bulls'N'Bears
//
//  Created by aDav on 14/01/2021.
//

import UIKit

extension Array where Element == Double {
    
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
        
        guard self.count > periods+2 else {
            return nil
        }
        
        let ascending = Array(self.reversed())
        
        var sum = Double()
        for i in 0..<periods {
            sum += ascending[i]
        }
        let sma = sum / Double(periods)
        
        var ema = sma
        
        for i in periods..<self.count {
            if ascending[i] != Double() {
                ema = ascending[i] * (2/(Double(periods+1))) + ema * (1 - 2/(Double(periods+1)))
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

}

extension Array where Element == Double? {
    
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
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error converting website cookies into data object")
        }
        return nil
    }

    static fileprivate func loadCookieProperties(from data: Data) -> [HTTPCookiePropertyKey : Any]? {
        do {
            let unarchivedDictionary = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [HTTPCookiePropertyKey : Any]
            return unarchivedDictionary
        } catch let error {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "error converting website cookies into data object")
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

