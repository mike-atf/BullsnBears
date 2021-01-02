//
//  StockTrend.swift
//  TrendMyStocks
//
//  Created by aDav on 17/12/2020.
//

import Foundation

struct StockTrend {
    var startDate: Date
    var endDate: Date
    var startPrice: Double?
    var endPrice: Double?
    var incline: Double?
    
    init(start: Date, end: Date, startPrice: Double?, endPrice: Double?) {
        self.startDate = start
        self.endDate = end
        self.startPrice = startPrice
        self.endPrice = endPrice
        
        if let validStart = startPrice {
            if let validEnd = endPrice {
                incline = (validEnd - validStart) / endDate.timeIntervalSince(startDate)
            }
        }
    }
    
    public func timeWeightedIncline() -> Double? {
        // makes sense only for trends of different time durations.
        // currently al are 30 days
        guard let validIncline = incline else { return nil }
        return validIncline * endDate.timeIntervalSince(startDate)
        
    }
    
    public func recentWeightedIncline(_ totalTime: TimeInterval, lastDate: Date) -> Double? {
        guard let validIncline = incline else { return nil }
        let timeSinceLastDate = lastDate.timeIntervalSince(endDate)
        let factor = 1 - timeSinceLastDate / totalTime
//        print("unweighted incline \(validIncline)  - factor \(factor)")
        return validIncline * factor
    }
}
