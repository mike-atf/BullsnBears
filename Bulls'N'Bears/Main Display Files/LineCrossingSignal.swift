//
//  LineCrossingSignal.swift
//  Bulls'N'Bears
//
//  Created by aDav on 23/03/2021.
//

import Foundation

class LineCrossing: NSObject {
    var date: Date!
    var signal: Double!
    var crossingPrice: Double?
    var type: String? // sma10, osc or macd
    
    init(date: Date, signal: Double, crossingPrice: Double?=nil, type: String?=nil) {
        super.init()
        
        self.date = date
        self.signal = signal
        self.crossingPrice = crossingPrice
        self.type = type
    }
    
    func signalIsBuy() -> Bool {
        return (signal > 0)
    }
}
