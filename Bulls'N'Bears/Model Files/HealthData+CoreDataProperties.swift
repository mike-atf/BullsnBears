//
//  HealthData+CoreDataProperties.swift
//  Bulls'N'Bears
//
//  Created by aDev on 13/12/2023.
//
//

import Foundation
import CoreData


extension HealthData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HealthData> {
        return NSFetchRequest<HealthData>(entityName: "HealthData")
    }

    @NSManaged public var profitability: Data?
    @NSManaged public var efficiency: Data?
    @NSManaged public var quickRatio: Data?
    @NSManaged public var currentRatio: Data?
    @NSManaged public var solvency: Data?
    @NSManaged public var share: Share?
//    @NSManaged public var shareSymbol: String?

}

extension HealthData : Identifiable {

}
