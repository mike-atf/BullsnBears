//
//  SharePurchase+CoreDataProperties.swift
//  SharePurchase
//
//  Created by aDav on 22/09/2021.
//
//

import Foundation
import CoreData


extension SharePurchase {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SharePurchase> {
        return NSFetchRequest<SharePurchase>(entityName: "SharePurchase")
    }

    @NSManaged public var date: Date?
    @NSManaged public var price: Double
    @NSManaged public var quantity: Double
    @NSManaged public var reason: String?
    @NSManaged public var share: String?
    @NSManaged public var sharePurchase: Share?

}

extension SharePurchase : Identifiable {

}
