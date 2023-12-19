//
//  Balance_sheet+CoreDataClass.swift
//  Bulls'N'Bears
//
//  Created by aDav on 08/01/2023.
//
//

import Foundation
import CoreData

enum BalanceSheetParameters {
    case debt_longTerm
    case debt_shortTerm
    case debt_total
    case ppe_net
    case she_equity
}

@objc(Balance_sheet)
public class Balance_sheet: NSManagedObject, Codable {
    
    // MARK: - coding
    
    enum CodingKeys: CodingKey {
        case debt_longTerm
        case debt_shortTerm
        case debt_total
        case ppe_net
        case sh_equity
        case retained_earnings
        case share
        case shareSymbol
    }
    
    required convenience public init(from decoder: Decoder) throws {
        
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
            throw DecoderConfigurationError.missingManagedObjectContext
        }
        
        self.init(context: context)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.debt_longTerm = try container.decodeIfPresent(Data.self, forKey: .debt_longTerm)
        self.debt_shortTerm = try container.decodeIfPresent(Data.self, forKey: .debt_shortTerm)
        self.debt_total = try container.decodeIfPresent(Data.self, forKey: .debt_total)
        self.ppe_net = try container.decodeIfPresent(Data.self, forKey: .ppe_net)
        self.sh_equity = try container.decodeIfPresent(Data.self, forKey: .sh_equity)
        self.retained_earnings = try container.decodeIfPresent(Data.self, forKey: .retained_earnings)
//        self.share = try container.decodeIfPresent(Share.self, forKey: .share)
//        self.shareSymbol = try container.decode(String.self, forKey: .shareSymbol)

    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(debt_longTerm, forKey: .debt_longTerm)
        try container.encodeIfPresent(debt_shortTerm, forKey: .debt_shortTerm)
        try container.encodeIfPresent(debt_total, forKey: .debt_total)
        try container.encodeIfPresent(ppe_net, forKey: .ppe_net)
        try container.encodeIfPresent(sh_equity, forKey: .sh_equity)
        try container.encodeIfPresent(retained_earnings, forKey: .retained_earnings)
//        try container.encodeIfPresent(share, forKey: .share)
//        try container.encode(shareSymbol!, forKey: .shareSymbol)

    }
    
    func getValues(parameter: BalanceSheetParameters) -> Labelled_DatedValues? {
        
        var label = String()
        var datedValues: [DatedValue]?
        
        switch parameter {
        case .debt_shortTerm:
            datedValues = debt_shortTerm.datedValues(dateOrder: .ascending)
            label = "ShortTermDebt"
        case .debt_longTerm:
            datedValues = debt_longTerm.datedValues(dateOrder: .ascending)
            label = "LongTermDebt"
        case .debt_total:
            datedValues = debt_total.datedValues(dateOrder: .ascending)
            label = "TotalDebt"
        case .ppe_net:
            datedValues = ppe_net.datedValues(dateOrder: .ascending)
            label = "PPEnet"
        case .she_equity:
            datedValues = sh_equity.datedValues(dateOrder: .ascending)
            label = "ShareholdersEquity"
       }
        
        if let dv = datedValues {
            return Labelled_DatedValues(label:label, datedValues: dv)
        } else {
            return nil
        }
    }
    
    func totalDebtProportion() -> DatedValue? {
        
        guard let latestNetIncomes = share?.income_statement?.netIncome.datedValues(dateOrder: .ascending) else { return nil }
        guard let latestNetIncome = latestNetIncomes.last else { return nil }
        guard let latestTotalDebt = debt_total.datedValues(dateOrder: .ascending)?.last else { return nil }
        guard latestNetIncome.value != 0.0 else { return nil }
        
        let maxDate = [latestNetIncome.date, latestTotalDebt.date].max()!
        
        return DatedValue(date: maxDate, value: (latestTotalDebt.value / latestNetIncome.value))

    }


}
