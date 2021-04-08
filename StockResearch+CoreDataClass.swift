//
//  StockResearch+CoreDataClass.swift
//  Bulls'N'Bears
//
//  Created by aDav on 29/03/2021.
//
//

import UIKit
import CoreData

@objc(StockResearch)
public class StockResearch: NSManagedObject {

    public override func awakeFromInsert() {
        self.creationDate = Date()
        
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

    func returnNews() -> [CompanyNews]? {
        
        var newsStories: [CompanyNews]?
        if news?.count ?? 0 > 0 {
            newsStories = [CompanyNews]()
        }
        
        for element in news ?? [] {
            if let newsStory = element as? CompanyNews {
                newsStories?.append(newsStory)
            }
        }
        
        return newsStories
    }
    
    func returnNewsTexts() -> [String]? {
        
        var newsTexts: [String]?
        if news?.count ?? 0 > 0 {
            newsTexts = [String]()
        }
        
        for element in news ?? [] {
            if let newsStory = element as? CompanyNews {
                newsTexts?.append(newsStory.newsText ?? "")
            }
        }
        
        return newsTexts
    }

    
    func sections() -> [String] {
                
        var names = entity.attributesByName.compactMap{ $0.key }.filter { (name) -> Bool in
            if name != "creationDate" && name != "symbol" { return true }
            else { return false }
        }
        
        names.append("news")
        return names
    }
    
}
