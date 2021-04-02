//
//  CompanyNews+CoreDataProperties.swift
//  Bulls'N'Bears
//
//  Created by aDav on 29/03/2021.
//
//

import Foundation
import CoreData


extension CompanyNews {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CompanyNews> {
        return NSFetchRequest<CompanyNews>(entityName: "CompanyNews")
    }

    @NSManaged public var newsText: String?
    @NSManaged public var creationDate: Date?
    @NSManaged public var research: StockResearch?

}

extension CompanyNews : Identifiable {

}
