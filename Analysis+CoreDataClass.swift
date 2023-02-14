//
//  Analysis+CoreDataClass.swift
//  Bulls'N'Bears
//
//  Created by aDav on 08/01/2023.
//
//

import Foundation
import CoreData

enum AnalysisParameters {
    case forwardPE
    case future_growthRate
    case future_revenue
    case future_revenueGrowthRate
    case adjFutureGrowthRate
    case adjForwardPE

}

@objc(Analysis)
public class Analysis: NSManagedObject {
    
    func getValues(parameter: AnalysisParameters) -> Labelled_DatedValues? {
        
        var label = String()
        var datedValues: [DatedValue]?
        
        switch parameter {
        case .forwardPE:
            datedValues = forwardPE.datedValues(dateOrder: .ascending)
            label = "ForwardPE"
        case .future_revenue:
            datedValues = future_revenue.datedValues(dateOrder: .ascending)
            label = "FutureRevenue"
        case .future_growthRate:
            datedValues = future_growthNextYear.datedValues(dateOrder: .ascending)
            label = "FutureGrowthRates"
        case .future_revenueGrowthRate:
            datedValues = future_revenueGrowthRate.datedValues(dateOrder: .ascending)
            label = "FutureRevenueGrowthRates"
        case .adjFutureGrowthRate:
            datedValues = adjFutureGrowthRate.datedValues(dateOrder: .ascending)
            label = "AdjustedFutureGrowthRates"
        case .adjForwardPE:
            datedValues = adjForwardPE.datedValues(dateOrder: .ascending)
            label = "AdjustedForwardPE"
       }
        
        if let dv = datedValues {
            return Labelled_DatedValues(label:label, datedValues: dv)
        } else {
            return nil
        }
    }
    
    /// if revenueGrowthRate = true return future_RevenueGrowthRate, else returns future_GrowthRate
    func meanFutureGrowthRate(adjusted: Bool, salesGrowthRate:Bool?=false) -> Double? {
        
        var growthData = adjusted ? adjFutureGrowthRate : future_growthNextYear
        if salesGrowthRate ?? false {
            growthData = future_revenueGrowthRate
        }
        
        if let growthDVs = growthData.datedValues(dateOrder: .ascending) {
            let values = growthDVs.compactMap{ $0.value }
            return values.mean()
        }
        
        return nil
    }
    
    /// if revenueGrowthRate = true return future_RevenueGrowthRate, else returns future_GrowthRate
    func minFutureGrowthRate(adjusted: Bool, salesGrowthRate:Bool?=false) -> Double? {
        
        var growthData = adjusted ? adjFutureGrowthRate : future_growthNextYear
        if salesGrowthRate ?? false {
            growthData = future_revenueGrowthRate
        }

        if let growthDVs = growthData.datedValues(dateOrder: .ascending) {
            let values = growthDVs.compactMap{ $0.value }
            return values.min()
        }
        
        return nil
    }
    
    /// if revenueGrowthRate = true return future_RevenueGrowthRate, else returns future_GrowthRate
    func maxFutureGrowthRate(adjusted: Bool, salesGrowthRate:Bool?=false) -> Double? {
        
        var growthData = adjusted ? adjFutureGrowthRate : future_growthNextYear
        if salesGrowthRate ?? false {
            growthData = future_revenueGrowthRate
        }

        if let growthDVs = growthData.datedValues(dateOrder: .ascending) {
            let values = growthDVs.compactMap{ $0.value }
            return values.max()
        }
        
        return nil
    }


    
    func meanFuturePE() -> Double? {
                
        if let futurePEdvs = adjForwardPE.valuesOnly(dateOrdered: .ascending,withoutZeroes: true) ?? forwardPE.valuesOnly(dateOrdered: .ascending, withoutZeroes: true) {
            if let mean = futurePEdvs.mean() {
                if mean != 0 { return mean }
            }
        }
        
        if let historicalPEs = share?.ratios?.pe_ratios.valuesOnly(dateOrdered: .ascending, withoutZeroes: true) {
            return historicalPEs.mean()
        }
        
        return nil
    }
    
    



}
