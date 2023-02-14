//
//  Balance_sheet+CoreDataProperties.swift
//  Bulls'N'Bears
//
//  Created by aDav on 08/01/2023.
//
//

import Foundation
import CoreData


extension Balance_sheet {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Balance_sheet> {
        return NSFetchRequest<Balance_sheet>(entityName: "Balance_sheet")
    }

    @NSManaged public var debt_longTerm: Data?
    @NSManaged public var debt_shortTerm: Data?
    @NSManaged public var debt_total: Data?
    @NSManaged public var ppe_net: Data?
    @NSManaged public var sh_equity: Data?
    @NSManaged public var retained_earnings: Data?
    @NSManaged public var share: Share?

}

extension Balance_sheet : Identifiable {

}
