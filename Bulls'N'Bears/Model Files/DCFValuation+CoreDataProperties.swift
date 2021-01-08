//
//  DCFValuation+CoreDataProperties.swift
//  TrendMyStocks
//
//  Created by aDav on 02/01/2021.
//
//

import Foundation
import CoreData


extension DCFValuation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DCFValuation> {
        return NSFetchRequest<DCFValuation>(entityName: "DCFValuation")
    }

    @NSManaged public var tFCFo: [Double]?
    @NSManaged public var capExpend: [Double]?
    @NSManaged public var netIncome: [Double]?
    @NSManaged public var tRevenueActual: [Double]?
    @NSManaged public var tRevenuePred: [Double]?
    @NSManaged public var revGrowthPred: [Double]?
    @NSManaged public var revGrowthPredAdj: [Double]?
    @NSManaged public var expenseInterest: Double
    @NSManaged public var debtST: Double
    @NSManaged public var debtLT: Double
    @NSManaged public var incomePreTax: Double
    @NSManaged public var expenseIncomeTax: Double
    @NSManaged public var marketCap: Double
    @NSManaged public var beta: Double
    @NSManaged public var sharesOutstanding: Double
    @NSManaged public var company: String?
    @NSManaged public var creationDate: Date?

}

extension DCFValuation : Identifiable {

}
