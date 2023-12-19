//
//  Income_statement+CoreDataClass.swift
//  Bulls'N'Bears
//
//  Created by aDav on 08/01/2023.
//
//

import Foundation
import CoreData

enum IncomeStatementParameter {
    case revenue
    case netIncome
    case operatingIncome
    case preTaxIncome
    case incomeTax
    case eps_annual
    case eps_quarter
    case grossProfit
    case interestExpense
    case rdExpense
    case sgaExpense
}

@objc(Income_statement)
public class Income_statement: NSManagedObject, Codable {
    
    // MARK: - coding
    
    enum CodingKeys: CodingKey {
        case revenue
        case netIncome
        case operatingIncome
        case preTaxIncome
        case incomeTax
        case eps_annual
        case eps_quarter
        case grossProfit
        case interestExpense
        case rdExpense
        case sgaExpense
        case share
        case shareSymbol
    }
    
    required convenience public init(from decoder: Decoder) throws {
        
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
            throw DecoderConfigurationError.missingManagedObjectContext
        }
        
        self.init(context: context)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.revenue = try container.decodeIfPresent(Data.self, forKey: .revenue)
        self.netIncome = try container.decodeIfPresent(Data.self, forKey: .netIncome)
        self.operatingIncome = try container.decodeIfPresent(Data.self, forKey: .operatingIncome)
        self.preTaxIncome = try container.decodeIfPresent(Data.self, forKey: .preTaxIncome)
        self.incomeTax = try container.decodeIfPresent(Data.self, forKey: .incomeTax)
        self.eps_annual = try container.decodeIfPresent(Data.self, forKey: .eps_annual)
        self.eps_quarter = try container.decodeIfPresent(Data.self, forKey: .eps_quarter)
        self.grossProfit = try container.decodeIfPresent(Data.self, forKey: .grossProfit)
        self.interestExpense = try container.decodeIfPresent(Data.self, forKey: .interestExpense)
        self.sgaExpense = try container.decodeIfPresent(Data.self, forKey: .sgaExpense)
        self.rdExpense = try container.decodeIfPresent(Data.self, forKey: .rdExpense)
//        self.share = try container.decodeIfPresent(Share.self, forKey: .share)
//        self.shareSymbol = try container.decode(String.self, forKey: .shareSymbol)

    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(revenue, forKey: .revenue)
        try container.encodeIfPresent(netIncome, forKey: .netIncome)
        try container.encodeIfPresent(operatingIncome, forKey: .operatingIncome)
        try container.encodeIfPresent(preTaxIncome, forKey: .preTaxIncome)
        try container.encodeIfPresent(incomeTax, forKey: .incomeTax)
        try container.encodeIfPresent(eps_annual, forKey: .eps_annual)
        try container.encodeIfPresent(eps_quarter, forKey: .eps_quarter)
        try container.encodeIfPresent(grossProfit, forKey: .grossProfit)
//        try container.encodeIfPresent(share, forKey: .share)
        try container.encodeIfPresent(interestExpense, forKey: .interestExpense)
        try container.encodeIfPresent(sgaExpense, forKey: .sgaExpense)
        try container.encodeIfPresent(rdExpense, forKey: .rdExpense)
//        try container.encode(shareSymbol!, forKey: .shareSymbol)

    }
    
    func getValues(parameter: IncomeStatementParameter) -> Labelled_DatedValues? {
        
        var label = String()
        var datedValues: [DatedValue]?
        
        switch parameter {
        case .revenue:
            datedValues = revenue.datedValues(dateOrder: .ascending)
            label = "Revenue"
        case .netIncome:
            datedValues = netIncome.datedValues(dateOrder: .ascending)
            label = "NetIncome"
        case .operatingIncome:
            datedValues = operatingIncome.datedValues(dateOrder: .ascending)
            label = "OperatingIncome"
        case .preTaxIncome:
            datedValues = preTaxIncome.datedValues(dateOrder: .ascending)
            label = "PreTaxIncome"
        case .grossProfit:
            datedValues = grossProfit.datedValues(dateOrder: .ascending)
            label = "GrossProfit"
        case .interestExpense:
            datedValues = interestExpense.datedValues(dateOrder: .ascending)
            label = "InterestExpense"
        case .rdExpense:
            datedValues = rdExpense.datedValues(dateOrder: .ascending)
            label = "RandDExpense"
        case .sgaExpense:
            datedValues = sgaExpense.datedValues(dateOrder: .ascending)
            label = "SGAExpense"
        case .eps_annual:
            datedValues = eps_annual.datedValues(dateOrder: .ascending)
            label = "EPSAnnual"
        case .eps_quarter:
            datedValues = eps_quarter.datedValues(dateOrder: .ascending)
            label = "EPSQuarter"
        case .incomeTax:
            datedValues = incomeTax.datedValues(dateOrder: .ascending)
            label = "IncomeTax"

       }
        
        if let dv = datedValues {
            return Labelled_DatedValues(label:label, datedValues: dv)
        } else {
            return nil
        }
    }

}
