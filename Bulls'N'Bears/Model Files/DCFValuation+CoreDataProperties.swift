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
    
    @NSManaged public var creationDate: Date
    @NSManaged public var ivalueTrend: Data?
    @NSManaged public var share: Share?
    
}

extension DCFValuation : Identifiable {

}
