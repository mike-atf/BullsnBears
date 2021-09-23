//
//  SharePurchase+CoreDataClass.swift
//  SharePurchase
//
//  Created by aDav on 22/09/2021.
//
//

import Foundation
import CoreData

@objc(SharePurchase)
public class SharePurchase: NSManagedObject {
    
    static func create(purchase: SharePurchase, in managedObjectContext: NSManagedObjectContext) {
        
        do {
            try  managedObjectContext.save()
        } catch {
            let nserror = error as NSError
            fatalError("Error creating SharePurchase\(nserror), \(nserror.userInfo)")
        }
    }
    
    func save() {
     
     
         if self.managedObjectContext?.hasChanges ?? false {
             do {
                 try self.managedObjectContext?.save()
             } catch {
                 // TODO: - Replace this implementation with code to handle the error appropriately.
                 let nserror = error as NSError
                 fatalError("Error saving SharePurchase\(nserror), \(nserror.userInfo)")
             }
         }

     }



}
