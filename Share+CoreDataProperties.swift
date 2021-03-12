//
//  Share+CoreDataProperties.swift
//  Bulls'N'Bears
//
//  Created by aDav on 11/03/2021.
//
//

import Foundation
import CoreData


extension Share {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Share> {
        return NSFetchRequest<Share>(entityName: "Share")
    }

    @NSManaged public var valueScore: Double
    @NSManaged public var userEvaluationScore: Double
    @NSManaged public var beta: Double
    @NSManaged public var peRatio: Double
    @NSManaged public var eps: Double
    @NSManaged public var creationDate: Date?
    @NSManaged public var purchaseStory: String?
    @NSManaged public var growthType: String?
    @NSManaged public var industry: String?
    @NSManaged public var symbol: String?
    @NSManaged public var name_short: String?
    @NSManaged public var name_long: String?
    @NSManaged public var dailyPrices: Data?
    @NSManaged public var wbValuation: WBValuation?
    @NSManaged public var dcfValuation: DCFValuation?
    @NSManaged public var rule1Valuation: Rule1Valuation?

}

extension Share : Identifiable {

}
