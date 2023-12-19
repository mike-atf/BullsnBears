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
public class CompanyNews: NSManagedObject, Codable {
    
    // MARK: - coding
    
    enum CodingKeys: CodingKey {
        case newsText
        case creationDate
        case research
        case shareSymbol
    }
    
    required convenience public init(from decoder: Decoder) throws {
        
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
            throw DecoderConfigurationError.missingManagedObjectContext
        }
        
        self.init(context: context)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.newsText = try container.decodeIfPresent(String.self, forKey: .newsText)
        self.creationDate = try container.decodeIfPresent(Date.self, forKey: .creationDate)
        self.research = try container.decodeIfPresent(StockResearch.self, forKey: .research)
//        self.shareSymbol = try container.decode(String.self, forKey: .shareSymbol)

    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(newsText, forKey: .newsText)
        try container.encodeIfPresent(creationDate, forKey: .creationDate)
        try container.encodeIfPresent(research, forKey: .research)
//        try container.encode(shareSymbol!, forKey: .shareSymbol)

    }

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
