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
    
    public override func awakeFromFetch() {
        //TODO: - temporary, remove for release
        if let valid = self.wbvParameter {
            for term in WBVParameters().higherIsWorseParameters() {
                if valid == term {
                    higherIsBetter = false
                    save()
                }
            }
        }
    }
    
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
        
        if let valid = self.wbvParameter {
            for term in WBVParameters().higherIsWorseParameters() {
                if valid == term {
                    higherIsBetter = false
                }
            }
        }
        
       do {
            try  (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error in WBValuation.save function \(nserror), \(nserror.userInfo)")
        }
    }

    func userRating() -> Int? {
        if rating < 0 { return nil }
        else { return Int(rating) }
    }
    
    func ratingColor() -> UIColor {
        
        return GradientColorFinder.cleanRatingColor(for: userRating() ?? 0, higherIsBetter: higherIsBetter)
        
    }

}
