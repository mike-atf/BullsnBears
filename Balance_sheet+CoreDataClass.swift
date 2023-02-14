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
public class Balance_sheet: NSManagedObject {
    
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
