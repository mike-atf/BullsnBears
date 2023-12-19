//
//  Ratios+CoreDataProperties.swift
//  Bulls'N'Bears
//
//  Created by aDav on 08/01/2023.
//
//

import Foundation
import CoreData


extension Ratios {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Ratios> {
        return NSFetchRequest<Ratios>(entityName: "Ratios")
    }

    @NSManaged public var pe_ratios: Data?
    @NSManaged public var roa: Data?
    @NSManaged public var roe: Data?
    @NSManaged public var roi: Data?
    @NSManaged public var bvps: Data?
    @NSManaged public var ocfPerShare: Data?
    @NSManaged public var fcfPerShare: Data?
    @NSManaged public var share: Share?
//    @NSManaged public var shareSymbol: String?
}

extension Ratios : Identifiable {

}
