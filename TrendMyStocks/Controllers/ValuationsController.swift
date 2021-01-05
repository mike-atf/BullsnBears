//
//  ValuationsController.swift
//  TrendMyStocks
//
//  Created by aDav on 03/01/2021.
//

import Foundation
import CoreData

class ValuationsController {
    
    static func returnDCFValuations(company: String? = nil) -> [DCFValuation]? {
        
        var valuations: [DCFValuation]?
        
        let fetchRequest = NSFetchRequest<DCFValuation>(entityName: "DCFValuation")
        if let validName = company {
            let predicate = NSPredicate(format: "company BEGINSWITH %@", argumentArray: [validName])
            fetchRequest.predicate = predicate
        }
        
        do {
            valuations = try managedObjectContext.fetch(fetchRequest)
            } catch let error {
                print("error fetching dcfValuations: \(error)")
        }

        return valuations
    }
    
    static func createDCFValuation(company: String) -> DCFValuation? {
        let newValuation:DCFValuation? = {
            NSEntityDescription.insertNewObject(forEntityName: "DCFValuation", into: managedObjectContext) as? DCFValuation
        }()
        newValuation?.company = company
        
        do {
            try  managedObjectContext.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }

        return newValuation
    }
}
