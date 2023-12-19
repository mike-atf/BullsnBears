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
public class Analysis: NSManagedObject, Codable {
    

    // MARK: - coding
    
    enum CodingKeys: CodingKey {
        case forwardPE
        case future_growthNextYear
        case future_growthNext5pa
        case future_revenue
        case future_revenueGrowthRate
        case adjFutureGrowthRate
        case adjForwardPE
        case share
        case shareSymbol
   }
    
    required convenience public init(from decoder: Decoder) throws {
        
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
            throw DecoderConfigurationError.missingManagedObjectContext
        }
        
        self.init(context: context)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.forwardPE = try container.decodeIfPresent(Data.self, forKey: .forwardPE)
        self.future_growthNextYear = try container.decodeIfPresent(Data.self, forKey: .future_growthNextYear)
        self.future_growthNext5pa = try container.decodeIfPresent(Data.self, forKey: .future_growthNext5pa)
        self.future_revenue = try container.decodeIfPresent(Data.self, forKey: .future_revenue)
        self.future_revenueGrowthRate = try container.decodeIfPresent(Data.self, forKey: .future_revenueGrowthRate)
        self.adjFutureGrowthRate = try container.decodeIfPresent(Data.self, forKey: .adjFutureGrowthRate)
        self.adjForwardPE = try container.decodeIfPresent(Data.self, forKey: .adjForwardPE)
//        self.share = try container.decodeIfPresent(Share.self, forKey: .share)
//        self.shareSymbol = try container.decode(String.self, forKey: .shareSymbol)

    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(forwardPE, forKey: .forwardPE)
        try container.encodeIfPresent(future_growthNextYear, forKey: .future_growthNextYear)
        try container.encodeIfPresent(future_growthNext5pa, forKey: .future_growthNext5pa)
        try container.encodeIfPresent(future_revenue, forKey: .future_revenue)
        try container.encodeIfPresent(future_revenueGrowthRate, forKey: .future_revenueGrowthRate)
        try container.encodeIfPresent(adjFutureGrowthRate, forKey: .adjFutureGrowthRate)
        try container.encodeIfPresent(adjForwardPE, forKey: .adjForwardPE)
//        try container.encodeIfPresent(share, forKey: .share)
//        try container.encode(shareSymbol!, forKey: .shareSymbol)

    }

    
    /// if revenueGrowthRate = true return future_RevenueGrowthRate, else returns future_GrowthRate.
    /// salesgroth will prioritise the sales growth parameters, if false will use adjFutureGrowth > future_growthNextYear > future_revenueGrowthRate
    func meanFutureGrowthRate(adjusted: Bool, salesGrowthRate:Bool?=false) -> Double? {
        
        var growthData = adjusted ? adjFutureGrowthRate : future_growthNextYear
        if growthData == nil {
            growthData = self.future_revenueGrowthRate
        }
        if salesGrowthRate ?? false {
            growthData = future_revenueGrowthRate
        }
        
        if let growthDVs = growthData.datedValues(dateOrder: .ascending, includeThisYear: true) {
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

        if let growthDVs = growthData.datedValues(dateOrder: .ascending, includeThisYear: true) {
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

        if let growthDVs = growthData.datedValues(dateOrder: .ascending, includeThisYear: true) {
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
        
        if let historicalPEs = share?.ratios?.pe_ratios.valuesOnly(dateOrdered: .ascending, withoutZeroes: true, includeThisYear: true) {
            return historicalPEs.mean()
        }
        
        return nil
    }
    
    



}
