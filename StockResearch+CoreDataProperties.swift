//
//  StockResearch+CoreDataProperties.swift
//  Bulls'N'Bears
//
//  Created by aDav on 29/03/2021.
//
//

import Foundation
import CoreData


extension StockResearch {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StockResearch> {
        return NSFetchRequest<StockResearch>(entityName: "StockResearch")
    }

    @NSManaged public var symbol: String?
    @NSManaged public var growthPlan: String?
    @NSManaged public var crisisPerformance: String?
    @NSManaged public var companySize: String?
    @NSManaged public var competitors: [String]?
    @NSManaged public var productsNiches: [String]?
    @NSManaged public var competitiveEdge: String?
    @NSManaged public var creationDate: Date?
    @NSManaged public var assets: String?
    @NSManaged public var insiderBuying: String?
    @NSManaged public var shareBuyBacks: String?
    @NSManaged public var theBuyStory: String?
    @NSManaged public var share: Share?
    @NSManaged public var news: NSSet?

}

// MARK: Generated accessors for news
extension StockResearch {

    @objc(addNewsObject:)
    @NSManaged public func addToNews(_ value: CompanyNews)

    @objc(removeNewsObject:)
    @NSManaged public func removeFromNews(_ value: CompanyNews)

    @objc(addNews:)
    @NSManaged public func addToNews(_ values: NSSet)

    @objc(removeNews:)
    @NSManaged public func removeFromNews(_ values: NSSet)

}

extension StockResearch : Identifiable {

}
