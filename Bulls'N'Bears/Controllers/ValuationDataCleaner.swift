//
//  ValuationDataCleaner.swift
//  Bulls'N'Bears
//
//  Created by aDav on 13/02/2021.
//

import Foundation

class ValuationDataCleaner {
    
    /// expected Double arrays with possible 'empty' Double() elements to clean out
    /// all arrays should be expected to have the same number of elements on return, in a connected order !(financial years)
    /// the arrays will be sent back 'trimmed' without empty Double() elements...
    /// ... in a 'lowest common denominator order' of elements
    class func cleanValuationData(dataArrays: [[Double]], method: ValuationMethods) -> ([[Double]], String?) {
        
        var uncleanedElementCounts = [Int]()
        var cleanedElementCounts = [Int]()
        
        var valueArrays = [[Double]]()
        
        for array in dataArrays {
            uncleanedElementCounts.append(array.count)
            let count = array.filter({ (element) -> Bool in
                if element != Double() { return true }
                else { return false }
            }).count
            cleanedElementCounts.append(count)
            
            valueArrays.append(array)
        }
        
        // all arrays have full set of non-empty elements
        if uncleanedElementCounts.max() == cleanedElementCounts.min() {
            return (dataArrays, nil)
        }
        
        // maximum number per array will be cleanedElementCounts.min()
        // it is assumed that arrays with fewer elements are the result of webpage table with fewer columns
        // and that any empty elements are the leading elements of the arrays, not in the middle ot towards the end,
        // as coming from Yahoo columns missing TTM and most recent year figures
        // this may be different in Macrotrends rows with false = empty elements at the beginning as well as end of the array
        
        if method == .dcf {
            // yahoo webdata, first elements may be empty ones
            
            for i in 0..<valueArrays.count {
                let moreThanMinElementsIndex = valueArrays[i].count - (cleanedElementCounts.min() ?? valueArrays[i].count)
                valueArrays[i] = Array(valueArrays[i][moreThanMinElementsIndex...])
            }
            
            return (valueArrays, "some data were discarded due to gaps. Interpret value with caution")
        }
        
        else if method == .rule1 {
            
            var elementsToRemoveFromAllArrays = [Int]()
            for i in 0..<valueArrays.count {
                for j in 0..<valueArrays[i].count {
                    if valueArrays[i][j] == Double() { elementsToRemoveFromAllArrays.append(j) }
                }
            }
            
            for i in 0..<valueArrays.count {
                for j in 0..<valueArrays[i].count {
                    if elementsToRemoveFromAllArrays.contains(j) {
                        valueArrays[i].remove(at: j)
                    }
                }
            }
            return (valueArrays, "some data were discarded due to gaps. Interpret value with caution")
        }
        
        else {
            return (dataArrays, "data cleaning error - undefined valuation method")
        }
    }
}
