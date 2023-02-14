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
        
        else if method == .rule1 || method == .wb {
            
            var elementsToRemoveFromAllArrays = [Int]()
            for i in 0..<valueArrays.count {
                for j in 0..<valueArrays[i].count {
                    if valueArrays[i][j] == Double() { elementsToRemoveFromAllArrays.append(j) }
                }
            }
            
            for i in 0..<valueArrays.count {
                for j in 0..<valueArrays[i].count {
                    if elementsToRemoveFromAllArrays.contains(j) {
                        if valueArrays[i].count > j {
                            valueArrays[i].remove(at: j)
                        }
                    }
                }
            }
            return (valueArrays, "some data were discarded due to gaps. Interpret value with caution")
        }
        
        else {
            return (dataArrays, "data cleaning error - undefined valuation method")
        }
    }
    
    
    /// returns two arrays without any 0-elements, with same element count, with one element per calendar year and with elements in years that are present in both arrays
    class func harmonizeDatedValues(arrays: [[DatedValue]?]) -> [[DatedValue]]? {
        
        let yearDateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone(identifier: "UTC")!
            formatter.dateFormat = "yyyy"
            return formatter
        }()
        
        let allValidArrays = arrays.compactMap{ $0 }
        if allValidArrays.count != arrays.count {
            return nil
        }
        
        var trimmedArrays = [[DatedValue]]()
        
        // 1 remove any 0 elements
        for a in allValidArrays {
            trimmedArrays.append(a.dropZeros())
        }
        
        // 2 if non-0 arrays all have same min and max year as well as same number of elements return
        // an error may arise if elements within each array don;t have one-year agps in between them
        // if not drop all elements of that year from ALL arrays
        let elements = trimmedArrays.compactMap{ $0.count }
        let maxYears$ = trimmedArrays.compactMap{ $0.maxYear$() }
        let minYears$ = trimmedArrays.compactMap{ $0.minYear$() }
        
        if Set(maxYears$).count <= 1 {
            if Set(minYears$).count <= 1 {
                if Set(elements).count <= 1 {
                    return trimmedArrays
                }
            }
        }
         
        // 4 remove any remaining elements with a year that is not present in ALL arrays
        // first find the years missing in some array
        var yearsNotPresentInAll$ = Set<String>()
        for i in 0..<allValidArrays.count {
            let allYears$ = allValidArrays[i].allYear$()
            for year$ in allYears$ {
                for j in 0..<allValidArrays.count {
                    let checkYears$ = allValidArrays[j].allYear$()
                    if !checkYears$.contains(year$) {
                        yearsNotPresentInAll$.insert(year$)
                    }
                }
            }
        }
        
        // then remove elements with these years from all arrays
        var newArrays = [[DatedValue]]()
        for i in 0..<allValidArrays.count {
            
            let array = allValidArrays[i].filter { dv in
                if !(yearsNotPresentInAll$.contains(yearDateFormatter.string(from: dv.date))) {
                    return true
                } else { return false }
            }
            newArrays.append(array)
        }
        
        let elementCounts = newArrays.compactMap{ $0.count }
        let differentCounts = Set<Int>(elementCounts)
        if differentCounts.count == 1 { return newArrays }
        
        // some arrays have more than one element for a given year.
        // merge these into an average so that there's not more than one value per calendar year
        var oneAnnualElementArrays = [[DatedValue]]()
        for new in newArrays {
            // all years as strings
            
//            for n in new {
//                print()
//                print(n.date)
//                print(fullDateFormatter.string(from: n.date))
//                print(yearDateFormatter.string(from: n.date))
//            }
//
            var oneAnElArray = [DatedValue]()
            let elementYears = Set<String>(new.compactMap{ yearDateFormatter.string(from: $0.date) })
            for year$ in elementYears {
                let elementsInYear = new.filter({ dv in
                    if yearDateFormatter.string(from: dv.date) == year$ { return true }
                    else { return false }
                })
                if elementsInYear.count == 1 {
                    oneAnElArray.append(elementsInYear.first!)
                }
                else if elementsInYear.count > 1 {
                    let average = elementsInYear.compactMap{ $0.value}.mean()! // zero elements have been removed above
                    let averageDV = DatedValue(date: yearDateFormatter.date(from: year$)!, value: average)
                    oneAnElArray.append(averageDV)
                }
            }
            oneAnnualElementArrays.append(oneAnElArray)
        }
        
        
        return oneAnnualElementArrays
         
    }
    
    /// assuming descending order - early elemetns more important than later elements
    /// removes later elements if either array to the smallest size of array1 or array2
    /// returned as [array1Trimmed, array2Trimmed]
    class func trimArraysToSameCount(array1: [Double], array2: [Double]) -> [[Double]] {
                
        let count1 = array1.count
        let count2 = array2.count
        
        if count1 == count2 { return [array1, array2] }
        else {
            var trimmed = [Double]()
            
            if count1 > count2 {
                trimmed = array1
                trimmed.removeLast((count1 - count2))
                return [trimmed, array2]
            } else {
                trimmed = array2
                trimmed.removeLast((count2 - count1))
                return [array1, trimmed]
            }
        }
        
    }
}
