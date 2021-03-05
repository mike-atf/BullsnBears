//
//  UserEvaluation+CoreDataProperties.swift
//  Bulls'N'Bears
//
//  Created by aDav on 02/03/2021.
//
//

import Foundation
import CoreData


extension UserEvaluation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserEvaluation> {
        return NSFetchRequest<UserEvaluation>(entityName: "UserEvaluation")
    }

    @NSManaged public var comment: String?
    @NSManaged public var rating: Int16
    @NSManaged public var wbvParameter: String?
    @NSManaged public var stock: String?
    @NSManaged public var userEvaluation: WBValuation?
    @NSManaged public var higherIsBetter: Bool

}

extension UserEvaluation : Identifiable {

}
