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

    @NSManaged public var bvps: [Double]?
    @NSManaged public var eps: [Double]?
    @NSManaged public var revenue: [Double]?
    @NSManaged public var opcs: [Double]? // use OPCS = operating cash flow per share in MacroTrends
    @NSManaged public var opCashFlow: Double // use OPCS = operating cash flow per share in MacroTrends
    @NSManaged public var netIncome: Double
    @NSManaged public var roic: [Double]?
    @NSManaged public var debt: Double
    @NSManaged public var hxPE: [Double]?
    @NSManaged public var adjFuturePE: Double
    @NSManaged public var growthEstimates: [Double]?
    @NSManaged public var adjGrowthEstimates: [Double]?
    @NSManaged public var insiderStockBuys: Double
    @NSManaged public var insiderStockSells: Double
    @NSManaged public var company: String?
    @NSManaged public var creationDate: Date?
    @NSManaged public var insiderStocks: Double
    @NSManaged public var ceoRating: Double
}

extension Rule1Valuation : Identifiable {

}
