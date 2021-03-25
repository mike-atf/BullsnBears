//
//  LineCrossingSignal.swift
//  Bulls'N'Bears
//
//  Created by aDav on 23/03/2021.
//

import Foundation

struct LineCrossing {
    var date: Date!
    var signal: Double!
    var crossingPrice: Double?
    
    init(date: Date, signal: Double, crossingPrice: Double?=nil) {
        self.date = date
        self.signal = signal
        self.crossingPrice = crossingPrice
    }
    
    func signalIsBuy() -> Bool {
        return (signal > 0)
    }
}
