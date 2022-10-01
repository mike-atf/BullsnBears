//
//  Share+CoreDataProperties.swift
//  Bulls'N'Bears
//
//  Created by aDav on 10/10/2021.
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
    @NSManaged public var symbol: String?
    @NSManaged public var userEvaluationScore: Double
    @NSManaged public var valueScore: Double
    @NSManaged public var watchStatus: Int16 // 0 watchList, 1 owned, 2 archived
    @NSManaged public var dcfValuation: DCFValuation?
    @NSManaged public var transactions: NSSet?
    @NSManaged public var research: StockResearch?
    @NSManaged public var rule1Valuation: Rule1Valuation?
    @NSManaged public var wbValuation: WBValuation?
    @NSManaged public var moatCategory: String?
    @NSManaged public var moat: Double // transferred to this stored value from rule1Valuation.moatScore() for the purpose of sorting the shares list on fetching
    @NSManaged public var trend_MoatScore: Data?
    @NSManaged public var trend_DCFValue: Data?
    @NSManaged public var trend_LynchScore: Data?
    @NSManaged public var trend_StickerPrice: Data?
    @NSManaged public var trend_pcRatio: Data?
    @NSManaged public var trend_caRatio: Data?
    @NSManaged public var trend_intrinsicValue: Data?
    @NSManaged public var capitalAssetRatio: Double
    @NSManaged public var pcRatio: Double


}

// MARK: Generated accessors for transactions
extension Share {

    @objc(addTransactionsObject:)
    @NSManaged public func addToTransactions(_ value: ShareTransaction)

    @objc(removeTransactionsObject:)
    @NSManaged public func removeFromTransactions(_ value: ShareTransaction)

    @objc(addTransactions:)
    @NSManaged public func addToTransactions(_ values: NSSet)

    @objc(removeTransactions:)
    @NSManaged public func removeFromTransactions(_ values: NSSet)

}

extension Share : Identifiable {

}
