//
//  ResearchController.swift
//  Bulls'N'Bears
//
//  Created by aDav on 01/04/2021.
//

import UIKit

class ResearchController {
    
    var share: Share?
    var titleDictionary: [String: String]?
    
    init(share: Share?) {
        
        
        self.share = share
        
        if  share?.research == nil {
            share?.research = StockResearch.init(context: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)
        }
        
        titleDictionary = sectionTitles()
        
    }
    
    func sectionTitles() -> [String : String]? {
        
        guard let names = share?.research!.sections() else { return nil }
        
        var sectionTitles = [String: String]()
        
        for name in names {
            switch name {
            case "growthPlan":
                sectionTitles[name] = "Future growth plan"
            case "crisisPerformance":
                sectionTitles[name] = "Performance during last crises"
            case "companySize":
                sectionTitles[name] = "Company size"
            case "competitors":
                sectionTitles[name] = "Competitors"
            case "productsNiches":
                sectionTitles[name] = "Special products or niches and their impact"
            case "competitiveEdge":
                sectionTitles[name] = "Competitive advantages"
            case "assets":
                sectionTitles[name] = "Assets and their value"
            case "insiderBuying":
                sectionTitles[name] = "Insider buying & selling"
            case "shareBuyBacks":
                sectionTitles[name] = "Retained earnings"
            case "theBuyStory":
                sectionTitles[name] = "Why do you want to buy this stock?"
            case "news":
                sectionTitles[name] = "Important company news"
            default:
                print("error: default")
            }

        }
        return sectionTitles
    }
    
    func parameter(title: String) -> String? {
        
        switch title {
        case "Future growth plan":
            return "growthPlan"
        case "Performance during last crises":
            return "crisisPerformance"
        case "Company size":
            return "companySize"
        case "Competitors":
            return "competitors"
        case "Special products or niches and their impact":
            return "productsNiches"
        case "Competitive advantages":
            return "competitiveEdge"
        case "Assets and their value":
            return "assets"
        case "Insider buying & selling":
            return "insiderBuying"
        case "Retained earnings":
            return "shareBuyBacks"
        case "Why do you want to buy this stock?":
            return "theBuyStory"
        case "Important company news":
            return "news"
        default:
            return nil
        }

    }

}
