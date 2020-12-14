//
//  PublicVars.swift
//  TrendMyStocks
//
//  Created by aDav on 01/12/2020.
//

import Foundation

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

enum TrendType {
    case mean
    case recentWeighted
    case timeWeighted
}

enum QuarterOption {
    case half
    case quarter
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
