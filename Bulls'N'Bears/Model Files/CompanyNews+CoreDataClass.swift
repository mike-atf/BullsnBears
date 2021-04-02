//
//  CompanyNews+CoreDataClass.swift
//  Bulls'N'Bears
//
//  Created by aDav on 29/03/2021.
//
//

import UIKit
import CoreData

@objc(CompanyNews)
public class CompanyNews: NSManagedObject {

    func save() {
               
         DispatchQueue.main.async {
            do {
                 try  (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.save()
             } catch {
                 let nserror = error as NSError
                 fatalError("Unresolved error in WBValuation.save function \(nserror), \(nserror.userInfo)")
             }
         }
     }

}
