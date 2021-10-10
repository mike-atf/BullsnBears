//
//  ShareTransaction+CoreDataClass.swift
//  Bulls'N'Bears
//
//  Created by aDav on 10/10/2021.
//
//

import Foundation
import CoreData

@objc(ShareTransaction)
public class ShareTransaction: NSManagedObject {
    
    static func create(purchase: ShareTransaction, in managedObjectContext: NSManagedObjectContext) {
        
        do {
            try  managedObjectContext.save()
        } catch {
            let nserror = error as NSError
            fatalError("Error creating ShareTransaction\(nserror), \(nserror.userInfo)")
        }
    }
    
    func save() {
     
     
         if self.managedObjectContext?.hasChanges ?? false {
             do {
                 try self.managedObjectContext?.save()
             } catch {
                 // TODO: - Replace this implementation with code to handle the error appropriately.
                 let nserror = error as NSError
                 fatalError("Error saving ShareTransaction\(nserror), \(nserror.userInfo)")
             }
         }

     }
    
    func delete() {
        
        managedObjectContext?.delete(self)
        do {
            try self.managedObjectContext?.save()
        } catch {
            // TODO: - Replace this implementation with code to handle the error appropriately.
            let nserror = error as NSError
            fatalError("Error saving ShareTransaction\(nserror), \(nserror.userInfo)")
        }

    }


}
