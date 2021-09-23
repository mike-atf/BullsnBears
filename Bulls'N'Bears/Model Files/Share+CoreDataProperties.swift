//
//  Share+CoreDataProperties.swift
//  Share
//
//  Created by aDav on 22/09/2021.
//
//

import Foundation
import CoreData


extension Share {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Share> {
        return NSFetchRequest<Share>(entityName: "Share")
    }

    @NSManaged public var beta: Double
    @NSManaged public var creationDate: Date?
    @NSManaged public var dailyPrices: Data?
    @NSManaged public var divYieldCurrent: Double
    @NSManaged public var employees: Double
    @NSManaged public var eps: Double
    @NSManaged public var growthSubType: String?
    @NSManaged public var growthType: String?
    @NSManaged public var industry: String?
    @NSManaged public var lastLivePrice: Double
    @NSManaged public var lastLivePriceDate: Date?
    @NSManaged public var macd: Data?
    @NSManaged public var name_long: String?
    @NSManaged public var name_short: String?
    @NSManaged public var peRatio: Double
    @NSManaged public var purchaseStory: String?
    @NSManaged public var sector: String?
    @NSManaged public var sharePurchaseReason: String?
    @NSManaged public var symbol: String?
    @NSManaged public var userEvaluationScore: Double
    @NSManaged public var valueScore: Double
    @NSManaged public var watchStatus: Int16
    @NSManaged public var dcfValuation: DCFValuation?
    @NSManaged public var purchase: NSSet?
    @NSManaged public var research: StockResearch?
    @NSManaged public var rule1Valuation: Rule1Valuation?
    @NSManaged public var wbValuation: WBValuation?

}

// MARK: Generated accessors for purchase
extension Share {

    @objc(addPurchaseObject:)
    @NSManaged public func addToPurchase(_ value: SharePurchase)

    @objc(removePurchaseObject:)
    @NSManaged public func removeFromPurchase(_ value: SharePurchase)

    @objc(addPurchase:)
    @NSManaged public func addToPurchase(_ values: NSSet)

    @objc(removePurchase:)
    @NSManaged public func removeFromPurchase(_ values: NSSet)

}

extension Share : Identifiable {

}
