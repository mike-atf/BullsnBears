//
//  WBValuation+CoreDataProperties.swift
//  Bulls'N'Bears
//
//  Created by aDav on 02/03/2021.
//
//

import Foundation
import CoreData


extension WBValuation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WBValuation> {
        return NSFetchRequest<WBValuation>(entityName: "WBValuation")
    }

    @NSManaged public var capExpend: [Double]?
    @NSManaged public var company: String?
    @NSManaged public var date: Date?
    @NSManaged public var debtLT: [Double]?
    @NSManaged public var eps: [Double]?
    @NSManaged public var equityRepurchased: [Double]?
    @NSManaged public var grossProfit: [Double]?
    @NSManaged public var interestExpense: [Double]?
    @NSManaged public var netEarnings: [Double]?
    @NSManaged public var operatingIncome: [Double]?
    @NSManaged public var peRatio: Double
    @NSManaged public var ppe: [Double]?
    @NSManaged public var rAndDexpense: [Double]?
    @NSManaged public var revenue: [Double]?
    @NSManaged public var roa: [Double]?
    @NSManaged public var roe: [Double]?
    @NSManaged public var sgaExpense: [Double]?
    @NSManaged public var shareholdersEquity: [Double]?
    @NSManaged public var userEvaluations: NSSet?

}

// MARK: Generated accessors for userEvaluation
extension WBValuation {

    @objc(addUserEvaluationObject:)
    @NSManaged public func addToUserEvaluations(_ value: UserEvaluation)

    @objc(removeUserEvaluationObject:)
    @NSManaged public func removeFromUserEvaluations(_ value: UserEvaluation)

    @objc(addUserEvaluation:)
    @NSManaged public func addToUserEvaluations(_ values: NSSet)

    @objc(removeUserEvaluation:)
    @NSManaged public func removeFromUserEvaluations(_ values: NSSet)

}

extension WBValuation : Identifiable {

}
