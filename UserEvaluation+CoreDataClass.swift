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

    
    func ratingColor() -> UIColor {
        
        return GradientColorFinder.cleanRatingColor(for: Int(rating), higherIsBetter: higherIsBetter)
        
//        let modRating = higherIsBetter ? rating : (10-rating)
//        switch modRating {
//        case ...2:
//            return UIColor.systemRed
//        case 2...5:
//            return UIColor.systemOrange
//        case 5...8:
//            return UIColor.systemYellow
//        case 8...:
//            return UIColor.systemGreen
//        default:
//            return UIColor.systemGray
//        }
        
//        return GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 10, value: Double(rating), greenCutoff: 9.0, redCutOff: 1.0)
    }

}
