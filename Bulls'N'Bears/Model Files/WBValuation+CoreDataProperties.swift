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

    @NSManaged public var date: Date
    @NSManaged public var intrinsicValueTrend: Data?
    @NSManaged public var share: Share?
    @NSManaged public var userEvaluations: Set<UserEvaluation>?

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
