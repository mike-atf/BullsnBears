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
public class Income_statement: NSManagedObject {
    
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
