//
//  Key_stats+CoreDataClass.swift
//  Bulls'N'Bears
//
//  Created by aDav on 09/01/2023.
//
//

import Foundation
import CoreData

enum KeyStatsParameters {
    case dividendYield
    case marketCap
    case beta
    case sharesOutstanding
}

@objc(Key_stats)
public class Key_stats: NSManagedObject, Codable {
    
    // MARK: - coding
    
    enum CodingKeys: CodingKey {
        case beta
        case dividendYield
        case marketCap
        case sharesOutstanding
        case insiderShares
        case insiderPurchases
        case insiderSales
        case dividendPayoutRatio
        case share
        case shareSymbol
   }
    
    required convenience public init(from decoder: Decoder) throws {
        
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
            throw DecoderConfigurationError.missingManagedObjectContext
        }
        
        self.init(context: context)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.beta = try container.decodeIfPresent(Data.self, forKey: .beta)
        self.dividendYield = try container.decodeIfPresent(Data.self, forKey: .dividendYield)
        self.marketCap = try container.decodeIfPresent(Data.self, forKey: .marketCap)
        self.sharesOutstanding = try container.decodeIfPresent(Data.self, forKey: .sharesOutstanding)
        self.insiderShares = try container.decodeIfPresent(Data.self, forKey: .insiderShares)
        self.insiderPurchases = try container.decodeIfPresent(Data.self, forKey: .insiderPurchases)
        self.insiderSales = try container.decodeIfPresent(Data.self, forKey: .insiderSales)
        self.dividendPayoutRatio = try container.decodeIfPresent(Data.self, forKey: .dividendPayoutRatio)
//        self.share = try container.decodeIfPresent(Share.self, forKey: .share)
//        self.shareSymbol = try container.decode(String.self, forKey: .shareSymbol)

    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(beta, forKey: .beta)
        try container.encodeIfPresent(dividendYield, forKey: .dividendYield)
        try container.encodeIfPresent(marketCap, forKey: .marketCap)
        try container.encodeIfPresent(sharesOutstanding, forKey: .sharesOutstanding)
        try container.encodeIfPresent(insiderShares, forKey: .insiderShares)
        try container.encodeIfPresent(insiderPurchases, forKey: .insiderPurchases)
        try container.encodeIfPresent(insiderSales, forKey: .insiderSales)
        try container.encodeIfPresent(dividendPayoutRatio, forKey: .dividendPayoutRatio)
//        try container.encodeIfPresent(share, forKey: .share)
//        try container.encode(shareSymbol!, forKey: .shareSymbol)

    }
    
    func getValues(parameter: KeyStatsParameters) -> Labelled_DatedValues? {
        
        var label = String()
        var datedValues: [DatedValue]?
        
        switch parameter {
        case .dividendYield:
            datedValues = dividendYield.datedValues(dateOrder: .ascending)
            label = "DividendYields"
        case .marketCap:
            datedValues = marketCap.datedValues(dateOrder: .ascending)
            label = "MarketCaps"
        case .beta:
            datedValues = beta.datedValues(dateOrder: .ascending)
            label = "Beta"
        case .sharesOutstanding:
            datedValues = sharesOutstanding.datedValues(dateOrder: .ascending)
            label = "ROI"
       }
        
        if let dv = datedValues {
            return Labelled_DatedValues(label:label, datedValues: dv)
        } else {
            return nil
        }
    }

}
