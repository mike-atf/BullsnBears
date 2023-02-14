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
public class Key_stats: NSManagedObject {
    
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
