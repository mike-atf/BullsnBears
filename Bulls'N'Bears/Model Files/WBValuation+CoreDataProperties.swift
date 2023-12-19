//
//  WBValuation+CoreDataProperties.swift
//  Bulls'N'Bears
//
//  Created by aDav on 03/03/2021.
//
//

import Foundation
import CoreData


extension WBValuation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WBValuation> {
        return NSFetchRequest<WBValuation>(entityName: "WBValuation")
    }

    // careful: MT.com row-based webdata are in time-DESCENDING order

//    @NSManaged public var capExpend: [Double]? // converted from NEGATIVE in MacroTrends to positive! also stored in DCFvaluation.capExpend
//    @NSManaged public var opCashFlow: [Double]?
//    @NSManaged public var company: String?
    @NSManaged public var date: Date?
//    @NSManaged public var latestDataDate: Date?
//    @NSManaged public var debtLT: [Double]?
//    @NSManaged public var eps: [Double]?
//    @NSManaged public var equityRepurchased: [Double]?
//    @NSManaged public var grossProfit: [Double]?
//    @NSManaged public var interestExpense: [Double]?
//    @NSManaged public var netEarnings: [Double]?
//    @NSManaged public var operatingIncome: [Double]?
//    @NSManaged public var ppe: [Double]?
//    @NSManaged public var rAndDexpense: [Double]?
//    @NSManaged public var revenue: [Double]?
//    @NSManaged public var roa: [Double]?
//    @NSManaged public var roe: [Double]?
//    @NSManaged public var sgaExpense: [Double]?
//    @NSManaged public var shareholdersEquity: [Double]?
    @NSManaged public var userEvaluations: Set<UserEvaluation>?
//    @NSManaged public var avAnStockPrice: [Double]?
//    @NSManaged public var bvps: [Double]?
//    @NSManaged public var perDates: Data? // these are usually quarterly P/E from MacroTrends
//    @NSManaged public var epsDates: Data? // qEPS TTM
//    @NSManaged public var epsDatesq: Data? // qEPS
    @NSManaged public var intrinsicValueTrend: Data?
    @NSManaged public var share: Share?
//    @NSManaged public var shareSymbol: String?
}

// MARK: Generated accessors for userEvaluations
extension WBValuation {

    @objc(addUserEvaluationsObject:)
    @NSManaged public func addToUserEvaluations(_ value: UserEvaluation)

    @objc(removeUserEvaluationsObject:)
    @NSManaged public func removeFromUserEvaluations(_ value: UserEvaluation)

    @objc(addUserEvaluations:)
    @NSManaged public func addToUserEvaluations(_ values: NSSet)

    @objc(removeUserEvaluations:)
    @NSManaged public func removeFromUserEvaluations(_ values: NSSet)

}

extension WBValuation : Identifiable {

}
