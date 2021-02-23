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
            let weight = (1/Double(i+1))
            sum += weight * self[i]
            weightSum += weight
        }
        
        if count > 0 {
            return sum / weightSum
        }
        else { return nil }
    }
    
    /// calculates growth rates from current to preceding element
    /// should have elemetns in time-descending order!
    /// return n-1 elements
    func growthRates() -> [Double]? {
        
        guard self.count > 1 else {
            return nil
        }
        
        var rates = [Double]()
        
        for i in 0..<self.count - 1 {
            rates.append((self[i] - self[i+1]) / abs(self[i+1]))
        }
        
        return rates
    }

}

extension Array where Element == Double? {
    
    /// calculates growth rates from current to preceding element
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
        
        if count > 0 {
            return sum / weightSum
        }
        else { return nil }
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
//
//
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
