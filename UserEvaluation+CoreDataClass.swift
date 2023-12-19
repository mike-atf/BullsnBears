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
public class UserEvaluation: NSManagedObject, Codable {
    
    // MARK: - coding
    
    enum CodingKeys: CodingKey {
        case comment
        case rating
        case wbvParameter
        case stock
        case userEvaluation
        case higherIsBetter
        case date
    }
    
    required convenience public init(from decoder: Decoder) throws {
        
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
            throw DecoderConfigurationError.missingManagedObjectContext
        }
        
        self.init(context: context)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.comment = try container.decodeIfPresent(String.self, forKey: .comment)
        self.rating = try container.decode(Int16.self, forKey: .rating)
        self.wbvParameter = try container.decodeIfPresent(String.self, forKey: .wbvParameter)
        self.stock = try container.decodeIfPresent(String.self, forKey: .stock)
        self.userEvaluation = try container.decodeIfPresent(WBValuation.self, forKey: .userEvaluation)
        self.higherIsBetter = try container.decode(Bool.self, forKey: .higherIsBetter)
        self.date = try container.decodeIfPresent(Date.self, forKey: .date)

    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encode(rating, forKey: .rating)
        try container.encodeIfPresent(wbvParameter, forKey: .wbvParameter)
        try container.encodeIfPresent(stock, forKey: .stock)
        try container.encodeIfPresent(userEvaluation, forKey: .userEvaluation)
        try container.encode(higherIsBetter, forKey: .higherIsBetter)
        try container.encodeIfPresent(date, forKey: .date)

    }
        
    static func create(valuation: WBValuation, in managedObjectContext: NSManagedObjectContext) {
        let newEvaluation = self.init(context: managedObjectContext)
        newEvaluation.userEvaluation = valuation
        newEvaluation.date = Date()

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
