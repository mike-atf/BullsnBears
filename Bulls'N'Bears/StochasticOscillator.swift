//
//  StochasticOscillator.swift
//  Bulls'N'Bears
//
//  Created by aDav on 21/03/2021.
//

import Foundation

struct StochasticOscillator: Codable {
    var k_fast: Double?
    var d_slow: Double?
    var date: Date?
    
    init(currentPrice: Double?, date: Date?, lowest14: Double?, highest14: Double?, slow2: [Double]?) {
        
        self.date = date

        guard currentPrice != nil else {
            return
        }

        guard lowest14 != nil else {
            return
        }
        
        guard highest14 != nil else {
            return
        }
        
        k_fast = 100 * (currentPrice! - lowest14!) / (highest14! - lowest14!)
        if let valid = k_fast {
            var slow3 = slow2
            slow3?.append(valid)
            if slow3?.count ?? 0 == 3 {
                d_slow = slow3?.mean()
            }
        }
    }
    
}
