//
//  Company_Info+CoreDataProperties.swift
//  Bulls'N'Bears
//
//  Created by aDav on 08/01/2023.
//
//

import Foundation
import CoreData


extension Company_Info {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Company_Info> {
        return NSFetchRequest<Company_Info>(entityName: "Company_Info")
    }

    @NSManaged public var employees: Data?
    @NSManaged public var industry: String?
    @NSManaged public var sector: String?
    @NSManaged public var businessDescription: String?
    @NSManaged public var share: Share?
//    @NSManaged public var shareSymbol: String?
}

extension Company_Info : Identifiable {

}
