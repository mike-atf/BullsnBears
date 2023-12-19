//
//  Cash_flow+CoreDataProperties.swift
//  Bulls'N'Bears
//
//  Created by aDav on 08/01/2023.
//
//

import Foundation
import CoreData


extension Cash_flow {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Cash_flow> {
        return NSFetchRequest<Cash_flow>(entityName: "Cash_flow")
    }

    @NSManaged public var capEx: Data?
    @NSManaged public var opCashFlow: Data?
    @NSManaged public var netBorrowings: Data? // from MT used for DCF. Called 'Debt Issuance/Retirement Net - Total'
    @NSManaged public var freeCashFlow: Data? // use Yhaoo, or MT Operating cash flow - Net change in PPE; should be fcfToEquity for DCF purposes
    @NSManaged public var share: Share?
//    @NSManaged public var shareSymbol: String?
}

extension Cash_flow : Identifiable {

}
