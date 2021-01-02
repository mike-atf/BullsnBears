//
//  PublicVars.swift
//  TrendMyStocks
//
//  Created by aDav on 01/12/2020.
//

import UIKit

var stocks = [Stock]()
var foreCastTime: TimeInterval = 30*24*3600

enum FindOptions {
    case minimum
    case maximum
}

enum PricePointOptions {
    case open
    case high
    case close
    case low
    case volume
}

enum TrendValue {
    case mean
    case recentWeighted
    case timeWeighted
}

//enum QuarterOption {
//    case half
//    case quarter
//}

enum TrendType {
    case bottom
    case ceiling
    case regression
}

enum TrendTimeOption {
    case half
    case quarter
    case full
    case month
}

struct Correlation {
    var incline = Double()
    var yIntercept = Double()
    var coEfficient = Double()
    
    init(m: Double, b: Double, r: Double) {
        self.incline = m
        self.yIntercept = b
        self.coEfficient = r
    }
}

struct TrendProperties {
    var type: TrendType!
    var time: TrendTimeOption!
    var dash: Bool!
    var color: UIColor!
    
    init(type: TrendType, time: TrendTimeOption, dash: Bool? = false) {
        self.type = type
        self.time = time
        self.dash = dash
        switch type {
        case .bottom:
            self.color = UIColor.systemRed
        case .regression:
            self.color = UIColor.systemBlue
        case .ceiling:
            self.color = UIColor(named: "Green")
        }
    }
}

struct PricePoint {
    var tradingDate: Date
    var open: Double
    var high: Double
    var low: Double
    var close: Double
    var volume: Double
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = NSLocale.current
        formatter.timeZone = NSTimeZone.local
        formatter.dateStyle = .short
        return formatter
    }()

    
    init(open: Double, close: Double, low: Double, high: Double, volume: Double, date: Date) {
        
        self.open = open
        self.close = close
        self.low = low
        self.high = high
        self.volume = volume
        
        var calendar = NSCalendar.current
        calendar.timeZone = NSTimeZone.default
        
        let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]
        var dateComponents = calendar.dateComponents(components, from: date)
        dateComponents.second = 0
        dateComponents.minute = 0
        dateComponents.hour = 0
        self.tradingDate = calendar.date(from: dateComponents) ?? date
    }
    
    public func returnPrice(option: PricePointOptions) -> Double {
        
        switch option {
        case .low:
                return low
            case .high:
                return high
            case .open:
                return open
            case .close:
                return close
            case .volume:
                return volume
        }
        
    }
    
    /// expected that self.tradsingDate is LATER than pricepoint.tradingDate
    /// otherwise a negative incline would be returned instead of a positive and vice versa
    public func returnIncline(pricePoint: PricePoint, priceOption: PricePointOptions) -> Double {
        
        return (pricePoint.returnPrice(option: priceOption) - self.returnPrice(option: priceOption)) / pricePoint.tradingDate.timeIntervalSince(self.tradingDate)

    }
}

