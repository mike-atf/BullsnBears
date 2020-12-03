//
//  Stock.swift
//  TrendMyStocks
//
//  Created by aDav on 01/12/2020.
//

import Foundation

struct Stock {
    
    var name: String
    var dailyPrices:[StockPrice_Daily]
    
    init(name: String, dailyPrices:[StockPrice_Daily]) {
        self.name = name
        self.dailyPrices = dailyPrices
    }
    
    public func lowestPrice(_ from: Date? = nil,_ to: Date? = nil) -> Double? {
        
        var pricesInRange: [StockPrice_Daily]!
        
        if let validFrom = from {
            pricesInRange = dailyPrices.filter({ (element) -> Bool in
                if element.tradingDate < validFrom {
                    return false
                }
                if element.tradingDate > to! {
                    return false
                }
                
                return true
            })
        }
        else {
            pricesInRange = dailyPrices
        }
        
        return pricesInRange.compactMap { $0.low }.min()
    }
    
    public func highestPrice(_ from: Date? = nil,_ to: Date? = nil) -> Double? {
        
        var pricesInRange: [StockPrice_Daily]!
        
        if let validFrom = from {
            pricesInRange = dailyPrices.filter({ (element) -> Bool in
                if element.tradingDate < validFrom {
                    return false
                }
                if element.tradingDate > to! {
                    return false
                }
                
                return true
            })
        }
        else {
            pricesInRange = dailyPrices
        }

        return pricesInRange.compactMap { $0.high }.max()
    }
    
    public func priceDateRange() -> [Date]? {
        
        let minDate = dailyPrices.compactMap { $0.tradingDate }.min()
        
        let maxDate = dailyPrices.compactMap { $0.tradingDate }.max()
        
        if minDate != nil && maxDate != nil { return [minDate!, maxDate!] }
        else { return nil }
    }
}

struct StockPrice_Daily {
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
    
}

