//
//  Income_statement+CoreDataProperties.swift
//  Bulls'N'Bears
//
//  Created by aDav on 08/01/2023.
//
//

import Foundation
import CoreData


extension Income_statement {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Income_statement> {
        return NSFetchRequest<Income_statement>(entityName: "Income_statement")
    }

    @NSManaged public var revenue: Data?
    @NSManaged public var netIncome: Data?
    @NSManaged public var operatingIncome: Data?
    @NSManaged public var preTaxIncome: Data?
    @NSManaged public var incomeTax: Data?
    @NSManaged public var eps_annual: Data?
    @NSManaged public var eps_quarter: Data?
    @NSManaged public var grossProfit: Data?
    @NSManaged public var interestExpense: Data?
    @NSManaged public var rdExpense: Data?
    @NSManaged public var sgaExpense: Data?
    @NSManaged public var share: Share?

}

extension Income_statement : Identifiable {

}
