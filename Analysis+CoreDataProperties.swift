//
//  Analysis+CoreDataProperties.swift
//  Bulls'N'Bears
//
//  Created by aDav on 08/01/2023.
//
//

import Foundation
import CoreData


extension Analysis {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Analysis> {
        return NSFetchRequest<Analysis>(entityName: "Analysis")
    }

    @NSManaged public var forwardPE: Data?
    /// general growth as separate to specific revenue (sales) growth; use the analysis get growth functions
    @NSManaged public var future_growthNextYear: Data?
    ///use the analysis get growth functions
    @NSManaged public var future_growthNext5pa: Data?
    /// use the analysis get growth functions
    @NSManaged public var future_revenue: Data?
    /// this quarter, next quarter, this year, next year
    @NSManaged public var future_revenueGrowthRate: Data?
    @NSManaged public var adjFutureGrowthRate: Data?
    @NSManaged public var adjForwardPE: Data?
    @NSManaged public var share: Share?

}

extension Analysis : Identifiable {

}
