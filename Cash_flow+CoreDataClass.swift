//
//  Cash_flow+CoreDataClass.swift
//  Bulls'N'Bears
//
//  Created by aDav on 08/01/2023.
//
//

import Foundation
import CoreData

enum CashFlowParameters {
    case capEx
    case opCashFlow
}

@objc(Cash_flow)
public class Cash_flow: NSManagedObject {
    
    func getValues(parameter: CashFlowParameters) -> Labelled_DatedValues? {
        
        var label = String()
        var datedValues: [DatedValue]?
        
        switch parameter {
        case .capEx:
            datedValues = capEx.datedValues(dateOrder: .ascending)
            label = "CapEx"
        case .opCashFlow:
            datedValues = opCashFlow.datedValues(dateOrder: .ascending)
            label = "OperatingCashFlow"
       }
        
        if let dv = datedValues {
            return Labelled_DatedValues(label:label, datedValues: dv)
        } else {
            return nil
        }
    }
    
    func capExNegative(dateOrder: Order) -> [DatedValue]? {
        
        guard var ce = capEx.datedValues(dateOrder: dateOrder) else { return nil }
        
        for i in 0..<ce.count {
            if ce[i].value > 0 { ce[i].value *= -1 }
        }
        
        return ce
    }
    
    // subtracts netPPEChanges from ocf; if no netPPEC will return opCashFlow or ocf as approximation; will return in date ASCENDING order
    func calculateFCF(ocf: [DatedValue]?, netPPEChange: [DatedValue]?) -> [DatedValue]? {
        
        guard let opCF = ocf else { return opCashFlow.datedValues(dateOrder: .ascending) }
        
        guard let nppec = netPPEChange else { return opCF }
        
        let opDCAscendingDate = opCF.sortByDate(dateOrder: .ascending)
        let nppecAscendingDate = nppec.sortByDate(dateOrder: .ascending)
        
        var fcf = [DatedValue]()
        
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = NSLocale.current
            formatter.timeZone = NSTimeZone.local
            formatter.dateFormat = "yyyy"
            return formatter
        }()

        for i in 0..<opDCAscendingDate.count {
            if nppecAscendingDate.count > i {
                let year1$ = dateFormatter.string(from: opDCAscendingDate[i].date)
                let year2$ = dateFormatter.string(from: nppecAscendingDate[i].date)
                if year1$ == year2$ {
                    let difference = opDCAscendingDate[i].value - nppecAscendingDate[i].value
                    fcf.append(DatedValue(date: opDCAscendingDate[i].date, value: difference))
                }
            }
        }
        
        return fcf
        
    }


}
