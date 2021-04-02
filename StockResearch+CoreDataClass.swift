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

    func sections() -> [String] {
                
        return entity.attributesByName.compactMap{ $0.key }.filter { (name) -> Bool in
            if name != "creationDate" && name != "symbol" { return true }
            else { return false }
        }
        
    }
    
    func userEnteredText(text: String, parameter: String, newsCreationDate: Date?=nil) {
        
        switch parameter {
        case "symbol":
            self.symbol = text
        case "growthPlan":
            self.growthPlan = text
        case "crisisPerformance":
            self.crisisPerformance = text
        case "companySize":
            self.companySize = text
        case "competitors":
            if self.competitors == nil {
                self.competitors = [text]
            } else {
                self.competitors?.append(text)
            }
        case "productsNiches":
            if self.productsNiches == nil {
                self.productsNiches = [text]
            } else {
                self.productsNiches?.append(text)
            }
        case "competitiveEdge":
            self.competitiveEdge = text
        case "assets":
            self.assets = text
        case "insiderBuying":
            self.insiderBuying = text
        case "shareBuyBacks":
            self.shareBuyBacks = text
        case "theBuyStory":
            self.theBuyStory = text
        case "news":
            if let date = newsCreationDate {
                for news in returnNews() ?? [] {
                    if news.creationDate == date {
                        news.newsText = text
                    }
                }
            }
        default:
            print("error: default")
        }
    }
}
