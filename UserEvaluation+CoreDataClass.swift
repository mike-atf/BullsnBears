//
//  UserEvaluation+CoreDataClass.swift
//  Bulls'N'Bears
//
//  Created by aDav on 02/03/2021.
//
//

import UIKit
import CoreData

@objc(UserEvaluation)
public class UserEvaluation: NSManagedObject {
    
    static func create(valuation: WBValuation, in managedObjectContext: NSManagedObjectContext) {
        let newEvaluation = self.init(context: managedObjectContext)
        newEvaluation.userEvaluation = valuation

        do {
            try  managedObjectContext.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    func save() {
        
       do {
            try  (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error in WBValuation.save function \(nserror), \(nserror.userInfo)")
        }
    }


}
