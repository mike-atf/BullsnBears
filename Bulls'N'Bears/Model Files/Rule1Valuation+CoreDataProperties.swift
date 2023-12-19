//
//  Rule1Valuation+CoreDataProperties.swift
//  TrendMyStocks
//
//  Created by aDav on 02/01/2021.
//
//

import Foundation
import CoreData


extension Rule1Valuation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Rule1Valuation> {
        return NSFetchRequest<Rule1Valuation>(entityName: "Rule1Valuation")
    }

    @NSManaged public var creationDate: Date
    @NSManaged public var moatScoreTrend: Data?
    @NSManaged public var stickerPriceTrend: Data?
    @NSManaged public var ceoRating: Double
    @NSManaged public var share: Share?

}

extension Rule1Valuation : Identifiable {

}
