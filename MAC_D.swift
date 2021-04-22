//
//  MAC_D.swift
//  Bulls'N'Bears
//
//  Created by aDav on 19/03/2021.
//

import Foundation

struct MAC_D : Codable {
    
    var mac_d: Double? // blue
    var signalLine: Double? // yellow
    var histoBar: Double?
    var emaShort: Double?
    var emaLong: Double?
    var date: Date?
    
    init(currentPrice:Double?, lastMACD: MAC_D?, date: Date,shortPeriod: Int?=nil, longPeriod: Int?=nil) {

        self.date = date
        
        if let validPRice = currentPrice {
            emaShort = ema(currentPrice: validPRice, lastEMA: lastMACD?.emaShort, periods: Double(shortPeriod ?? 8))
            emaLong = ema(currentPrice: validPRice, lastEMA: lastMACD?.emaLong, periods: Double(longPeriod ?? 17))
            if emaLong != nil && emaShort != nil {
                self.mac_d = emaShort! - emaLong!
                self.signalLine = ema(currentPrice: mac_d, lastEMA: lastMACD?.signalLine, periods: 9)
                if let validSignal = signalLine {
                    self.histoBar = mac_d! - validSignal
                }
            }
        }
    }
    
    func ema(currentPrice: Double?, lastEMA: Double?, periods: Double) -> Double? {
        
        if let validPRice = currentPrice {
            if let validEMA = lastEMA {
                let weight = 2 / (Double(periods) + 1)
                return (validPRice - validEMA) * weight + validEMA
            }
        }
        
        return nil

    }
}
