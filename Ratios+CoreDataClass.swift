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
public class Ratios: NSManagedObject, Codable {
    
    // MARK: - coding
    
    enum CodingKeys: CodingKey {
        case pe_ratios
        case roa
        case roe
        case roi
        case bvps
        case ocfPerShare
        case fcfPerShare
        case share
        case shareSymbol
    }
    
    required convenience public init(from decoder: Decoder) throws {
        
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
            throw DecoderConfigurationError.missingManagedObjectContext
        }
        
        self.init(context: context)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.pe_ratios = try container.decodeIfPresent(Data.self, forKey: .pe_ratios)
        self.roa = try container.decodeIfPresent(Data.self, forKey: .roa)
        self.roe = try container.decodeIfPresent(Data.self, forKey: .roe)
        self.roi = try container.decodeIfPresent(Data.self, forKey: .roi)
        self.bvps = try container.decodeIfPresent(Data.self, forKey: .bvps)
        self.ocfPerShare = try container.decodeIfPresent(Data.self, forKey: .ocfPerShare)
        self.fcfPerShare = try container.decodeIfPresent(Data.self, forKey: .fcfPerShare)
//        self.share = try container.decodeIfPresent(Share.self, forKey: .share)
//        self.shareSymbol = try container.decode(String.self, forKey: .shareSymbol)

    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(pe_ratios, forKey: .pe_ratios)
        try container.encodeIfPresent(roa, forKey: .roa)
        try container.encodeIfPresent(roe, forKey: .roe)
        try container.encodeIfPresent(roi, forKey: .roi)
        try container.encodeIfPresent(bvps, forKey: .bvps)
        try container.encodeIfPresent(ocfPerShare, forKey: .ocfPerShare)
        try container.encodeIfPresent(fcfPerShare, forKey: .fcfPerShare)
//        try container.encodeIfPresent(share, forKey: .share)
//        try container.encode(shareSymbol!, forKey: .shareSymbol)

    }
    
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
        
        guard timesToDate.count > 1 else {
            return nil
        }

        let nearest = [timesToDate[0], timesToDate[1]]
        return nearest.compactMap{ $0.value }.mean()
    }





}
