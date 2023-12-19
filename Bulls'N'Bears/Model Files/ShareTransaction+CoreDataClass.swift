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
public class ShareTransaction: NSManagedObject, Codable {
    
    // MARK: - coding
    
    enum CodingKeys: CodingKey {
        case date
        case isSale
        case lessonsLearnt
        case price
        case quantity
        case reason
        case share
        case shareSymbol
    }
    
    required convenience public init(from decoder: Decoder) throws {
        
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
            throw DecoderConfigurationError.missingManagedObjectContext
        }
        
        self.init(context: context)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.date = try container.decodeIfPresent(Date.self, forKey: .date)
        self.isSale = try container.decode(Bool.self, forKey: .isSale)
        self.lessonsLearnt = try container.decodeIfPresent(String.self, forKey: .lessonsLearnt)
        self.price = try container.decode(Double.self, forKey: .price)
        self.quantity = try container.decode(Double.self, forKey: .quantity)
        self.reason = try container.decodeIfPresent(String.self, forKey: .reason)
//        self.share = try container.decodeIfPresent(Share.self, forKey: .share)
//        self.shareSymbol = try container.decode(String.self, forKey: .shareSymbol)

    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(date, forKey: .date)
        try container.encode(isSale, forKey: .isSale)
        try container.encodeIfPresent(lessonsLearnt, forKey: .lessonsLearnt)
        try container.encode(price, forKey: .price)
        try container.encode(quantity, forKey: .quantity)
        try container.encodeIfPresent(reason, forKey: .reason)
//        try container.encodeIfPresent(share, forKey: .share)
//        try container.encode(shareSymbol!, forKey: .shareSymbol)

    }
    
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
