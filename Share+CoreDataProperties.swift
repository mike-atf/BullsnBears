//
//  Share+CoreDataProperties.swift
//  Bulls'N'Bears
//
//  Created by aDav on 10/01/2023.
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
    @NSManaged public var dividendWDates: Data?
    @NSManaged public var divYieldCurrent: Double
    @NSManaged public var employees: Double
    @NSManaged public var eps_current: Double
    @NSManaged public var exchange: String?
    @NSManaged public var industry: String?
    @NSManaged public var isin: String?
    @NSManaged public var lastLivePrice: Double
    @NSManaged public var lastLivePriceDate: Date?
    @NSManaged public var macd: Data?
    @NSManaged public var moat: Double
    @NSManaged public var moatCategory: String?
    @NSManaged public var name_long: String?
    @NSManaged public var name_short: String?
    @NSManaged public var peRatio_current: Double
    @NSManaged public var purchaseStory: String?
    @NSManaged public var return3y: Double
    @NSManaged public var return10y: Double
    @NSManaged public var sector: String?
    @NSManaged public var symbol: String?
    @NSManaged public var trend_DCFValue: Data?
    @NSManaged public var trend_healthScore: Data?
    @NSManaged public var trend_intrinsicValue: Data?
    @NSManaged public var trend_LynchScore: Data?
    @NSManaged public var trend_MoatScore: Data?
    @NSManaged public var trend_StickerPrice: Data?
    @NSManaged public var userEvaluationScore: Double
    @NSManaged public var valueScore: Double
    @NSManaged public var watchStatus: Int16
    @NSManaged public var analysis: Analysis?
    @NSManaged public var balance_sheet: Balance_sheet?
    @NSManaged public var cash_flow: Cash_flow?
    @NSManaged public var company_info: Company_Info?
    @NSManaged public var dcfValuation: DCFValuation?
    @NSManaged public var income_statement: Income_statement?
    @NSManaged public var key_stats: Key_stats?
    @NSManaged public var ratios: Ratios?
    @NSManaged public var research: StockResearch?
    @NSManaged public var rule1Valuation: Rule1Valuation?
    @NSManaged public var transactions: NSSet?
    @NSManaged public var wbValuation: WBValuation?
    @NSManaged public var currency: String?
    @NSManaged public var avgAnnualPrices: Data?

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
