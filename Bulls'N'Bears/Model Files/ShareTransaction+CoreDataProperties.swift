//
//  ShareTransaction+CoreDataProperties.swift
//  Bulls'N'Bears
//
//  Created by aDav on 10/10/2021.
//
//

import Foundation
import CoreData


extension ShareTransaction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShareTransaction> {
        return NSFetchRequest<ShareTransaction>(entityName: "ShareTransaction")
    }

    @NSManaged public var date: Date?
    @NSManaged public var isSale: Bool
    @NSManaged public var lessonsLearnt: String?
    @NSManaged public var price: Double
    @NSManaged public var quantity: Double
    @NSManaged public var reason: String?
    @NSManaged public var share: Share?
//    @NSManaged public var shareSymbol: String?
}

extension ShareTransaction : Identifiable {

}
