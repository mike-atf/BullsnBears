//
//  Extensions.swift
//  Bulls'N'Bears
//
//  Created by aDav on 14/01/2021.
//

import Foundation

extension Array where Element == Double {
    
    mutating func add(value: Double, index: Int) {
                
        if self.count > index {
            self[index] = value
        }
        else {
            self.append(value)
        }
    }
}
