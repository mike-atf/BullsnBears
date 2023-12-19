//
//  Key_stats+CoreDataProperties.swift
//  Bulls'N'Bears
//
//  Created by aDav on 09/01/2023.
//
//

import Foundation
import CoreData


extension Key_stats {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Key_stats> {
        return NSFetchRequest<Key_stats>(entityName: "Key_stats")
    }

    @NSManaged public var beta: Data?
    @NSManaged public var dividendYield: Data?
    @NSManaged public var marketCap: Data?
    @NSManaged public var sharesOutstanding: Data?
    @NSManaged public var insiderShares: Data?
    @NSManaged public var insiderPurchases: Data?
    @NSManaged public var insiderSales: Data?
    @NSManaged public var dividendPayoutRatio: Data?
    @NSManaged public var share: Share?
//    @NSManaged public var shareSymbol: String?
}

extension Key_stats : Identifiable {

}
