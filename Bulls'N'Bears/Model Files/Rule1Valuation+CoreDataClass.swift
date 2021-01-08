//
//  Rule1Valuation+CoreDataClass.swift
//  TrendMyStocks
//
//  Created by aDav on 02/01/2021.
//
//

import Foundation
import CoreData

@objc(Rule1Valuation)
public class Rule1Valuation: NSManagedObject {
    
    static func create(in managedObjectContext: NSManagedObjectContext) {
        let newValuation = self.init(context: managedObjectContext)
        newValuation.creationDate = Date()

        do {
            try  managedObjectContext.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    static func save(in context: NSManagedObjectContext) {
        
        do {
            try  context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error in SiteDetails.save function \(nserror), \(nserror.userInfo)")
        }

    }
    
    func delete(from managedObjectContext: NSManagedObjectContext) {
       
        managedObjectContext.delete(self)
 
        do {
            try managedObjectContext.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

}
