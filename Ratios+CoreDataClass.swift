//
//  Ratios+CoreDataClass.swift
//  Bulls'N'Bears
//
//  Created by aDav on 08/01/2023.
//
//

import Foundation
import CoreData

enum RatiosParameter {
    case pe_ratio
    case roa
    case roe
    case roi
    case bvps
    case ocfPerShare
}

@objc(Ratios)
public class Ratios: NSManagedObject {
    
    func getValues(parameter: RatiosParameter) -> Labelled_DatedValues? {
        
        var label = String()
        var datedValues: [DatedValue]?
        
        switch parameter {
        case .pe_ratio:
            datedValues = pe_ratios.datedValues(dateOrder: .ascending)
            label = "PERatios"
        case .roa:
            datedValues = roa.datedValues(dateOrder: .ascending)
            label = "ROA"
        case .roe:
            datedValues = roe.datedValues(dateOrder: .ascending)
            label = "ROE"
        case .roi:
            datedValues = roi.datedValues(dateOrder: .ascending)
            label = "ROI"
        case .bvps:
            datedValues = bvps.datedValues(dateOrder: .ascending)
            label = "BVPS"
        case .ocfPerShare:
            datedValues = ocfPerShare.datedValues(dateOrder: .ascending)
            label = "OPCF Per Share"
       }
        
        if let dv = datedValues {
            return Labelled_DatedValues(label:label, datedValues: dv)
        } else {
            return nil
        }
    }
    
    func meanPastPE() -> Double? {
        
        if let peDVs = pe_ratios.datedValues(dateOrder: .ascending) {
            let values = peDVs.compactMap{ $0.value }
            return values.mean()
        }
        
        return nil
    }
    
    func minPastPE_ValueOnly() -> Double? {
        
        if let peDVs = pe_ratios.valuesOnly(dateOrdered: .ascending, withoutZeroes: true) {
            return peDVs.min()
        }
        
        return nil
    }
    
    func minPastPE_DV() -> DatedValue? {
        
        
        if let peDVs = pe_ratios.datedValues(dateOrder: .ascending)?.dropZeros() {
            
            var minPE: Double = 1_000_000_000
            var minPEdv: DatedValue?

            for dv in peDVs {
                if dv.value < minPE {
                    minPE = dv.value
                    minPEdv = dv
                }
            }
            return minPEdv
        }
        
        return nil
    }

    
    func maxPastPE_ValueOnly() -> Double? {
        
        if let peDVs = pe_ratios.valuesOnly(dateOrdered: .ascending,withoutZeroes: true){
            return peDVs.max()
        }
        
        return nil
    }

    func maxPastPE_DV() -> DatedValue? {
        
        
        if let peDVs = pe_ratios.datedValues(dateOrder: .ascending)?.dropZeros() {
            
            var maxPE: Double = -1_000_000_000
            var maxPEdv: DatedValue?

            for dv in peDVs {
                if dv.value > maxPE {
                    maxPE = dv.value
                    maxPEdv = dv
                }
            }
            return maxPEdv
        }
        
        return nil
    }

    func minMeanMaxPERatioInDateRange(from:Date, to: Date?=nil) -> (Double, Double, Double)? {
        
        guard let datedValues = pe_ratios.datedValues(dateOrder: .ascending) else {
            return nil
        }
        
        let end = to ?? Date()
        
        let inDateRange = datedValues.filter { (element) -> Bool in
            if element.date < from { return false }
            else if element.date > end { return false }
            return true
        }
        
        let valuesInDateRange = inDateRange.compactMap { $0.value }
        if let mean = valuesInDateRange.mean() {
            if let min = valuesInDateRange.min() {
                if let max = valuesInDateRange.max() {
                    return (min, mean, max)
                }
            }
        }
        
        return nil
        
    }
    
    func historicPEratio(for date: Date) -> Double? {
        
        guard let datedValues = pe_ratios.datedValues(dateOrder: .ascending)?.dropZeros() else {
            return nil
        }
        
        let timesToDate = datedValues.sorted(by: { e0, e1 in
            if abs(e1.date.timeIntervalSince(date)) < abs(e0.date.timeIntervalSince(date)) { return false }
            else { return true }
        })

        let nearest = [timesToDate[0], timesToDate[1]]
        return nearest.compactMap{ $0.value }.mean()
    }





}
