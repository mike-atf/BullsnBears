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
    var controlledView: ResearchTVC?
    
    init(share: Share?, researchList: ResearchTVC) {
        
        
        self.share = share
        self.controlledView = researchList
        
        if  share?.research == nil {
            share?.research = StockResearch.init(context: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)
            share?.research?.symbol = share?.symbol
            share?.research?.save()
        }
        
        titleDictionary = titleParameterDictionary()
        
    }
    
    func titleParameterDictionary() -> [String : String]? {
        
        guard let names = share?.research!.sections() else { return nil }
        var allNames = names
        allNames.append("industry")
        allNames.append("growthType")
        
        var sectionTitles = [String: String]()
        
        for name in allNames {
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
            case "industry":
                sectionTitles[name] = "Industry"
            case "growthType":
                sectionTitles[name] = "Growth Category" // enum GrowthCategoryNames
            default:
                print("error: default")
            }

        }
        return sectionTitles
    }
    
    func sectionTitles() -> [String] {
        
        return Array(titleDictionary!.values.sorted())
    }
    
    func findEntityParameter(title: String) -> String? {
        
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
    
    func values(indexPath: IndexPath) -> [String]? {
        
        guard let validDict = titleDictionary else {
            return nil
        }
        
        let parameters = Array(titleDictionary!.values.sorted())
        guard parameters.count > indexPath.section else { return nil }
        
        var parameter = String()
        for key in validDict.keys {
            if validDict[key] == parameters[indexPath.section] {
                parameter = key
            }
        }
        
        switch parameter {
        case "symbol":
            if let valid = share?.research?.symbol { return [valid] }
            else { return nil }
        case "growthPlan":
            if let valid = share?.research?.growthPlan { return [valid] }
            else { return nil }
        case "crisisPerformance":
            if let valid = share?.research?.crisisPerformance { return [valid] }
            else { return nil }
        case "companySize":
            if let valid = share?.research?.companySize { return [valid] }
            else { return nil }
        case "competitors":
            if let valid = share?.research?.competitors { return valid }
            else { return nil }
        case "productsNiches":
            if let valid = share?.research?.productsNiches { return valid }
            else { return nil }
        case "competitiveEdge":
            if let valid = share?.research?.competitiveEdge { return [valid] }
            else { return nil }
        case "assets":
            if let valid = share?.research?.assets { return [valid] }
            else { return nil }
        case "insiderBuying":
            if let valid = share?.research?.insiderBuying { return [valid] }
            else { return nil }
        case "shareBuyBacks":
            if let valid = share?.research?.shareBuyBacks { return [valid] }
            else { return nil }
        case "theBuyStory":
            if let valid = share?.research?.theBuyStory { return [valid] }
            else { return nil }
        case "news":
            return share?.research?.returnNewsTexts()
        case "industry":
            if let valid = share?.industry {
                return [valid]
            }
            else { return nil }
        case "growthType":
            if let valid = share?.growthType {
                return [valid]
            }
            else { return nil }
        default:
            return nil
        }
    }
    
    func deleteObject(cellPath: IndexPath) {
        
        guard let validDict = titleDictionary else { return }
        
        let parameters = Array(titleDictionary!.values.sorted())
        guard parameters.count > cellPath.section else { return }
        
        var parameter = String()
        for key in validDict.keys {
            if validDict[key] == parameters[cellPath.section] {
                parameter = key
            }
        }
        
        switch parameter {
        case "news":
            guard share?.research?.news?.count ?? 0 > cellPath.row else  { return }
            let newsToDelete = share!.research!.returnNews()![cellPath.row]
            share!.research!.removeFromNews(newsToDelete)
            share?.research?.save()
        case "competitors":
            guard share?.research?.competitors?.count ?? 0 > cellPath.row else { return }
            share?.research?.competitors?.remove(at: cellPath.row)
            share?.research?.save()
        case "productsNiches":
            guard share?.research?.productsNiches?.count ?? 0 > cellPath.row else { return }
            share?.research?.productsNiches?.remove(at: cellPath.row)
            share?.research?.save()
        default:
            return
        }
    }

}

extension ResearchController: ResearchCellDelegate {

    func userEnteredNotes(notes: String, cellPath: IndexPath) {
        
        guard let validDict = titleDictionary else { return }
        
        let parameters = Array(titleDictionary!.values.sorted())
        guard parameters.count > cellPath.section else { return }
        
        var parameter = String()
        for key in validDict.keys {
            if validDict[key] == parameters[cellPath.section] {
                parameter = key
            }
        }
        
        switch parameter {
        case "symbol":
            share?.research?.symbol = notes
        case "growthPlan":
            share?.research?.growthPlan = notes
        case "crisisPerformance":
            share?.research?.crisisPerformance = notes
        case "companySize":
            share?.research?.companySize = notes
        case "competitors":
            share?.research?.competitors?[cellPath.row] = notes
//            if share?.research?.competitors == nil {
//                share?.research?.competitors = [notes]
//            } else {
//                share?.research?.competitors?.append(notes)
//            }
        case "productsNiches":
            share?.research?.productsNiches?[cellPath.row] = notes
//            if share?.research?.productsNiches == nil {
//                share?.research?.productsNiches = [notes]
//            } else {
//                share?.research?.productsNiches?.append(notes)
//            }
        case "competitiveEdge":
            share?.research?.competitiveEdge = notes
        case "assets":
            share?.research?.assets = notes
        case "insiderBuying":
            share?.research?.insiderBuying = notes
        case "shareBuyBacks":
            share?.research?.shareBuyBacks = notes
        case "theBuyStory":
            share?.research?.theBuyStory = notes
        case "news":
            share?.research?.returnNews()![cellPath.row].newsText = notes
//            for news in share?.research?.returnNews() ?? [] {
//                if news.creationDate == date {
//                    news.newsText =  notes
//                }
//            }
        case "industry":
            share?.industry = notes
        case "growthType":
            share?.growthType = notes
        default:
            print("error: default")
        }
        
        share?.save()
        share?.research?.save()
    }
    
    func value(indexPath: IndexPath) -> String? {
        
        let allValues = values(indexPath: indexPath)
        if allValues?.count ?? 0 > indexPath.row {
            return allValues![indexPath.row]
        }
        else { return nil }
    }
    
//    func saveUserEntry(text: String, parameter: String, newsCreationDate: Date?=nil) {
//
//        switch parameter {
//        case "symbol":
//            share?.research?.symbol = text
//        case "growthPlan":
//            share?.research?.growthPlan = text
//        case "crisisPerformance":
//            share?.research?.crisisPerformance = text
//        case "companySize":
//            share?.research?.companySize = text
//        case "competitors":
//            if share?.research?.competitors == nil {
//                share?.research?.competitors = [text]
//            } else {
//                share?.research?.competitors?.append(text)
//            }
//        case "productsNiches":
//            if share?.research?.productsNiches == nil {
//                share?.research?.productsNiches = [text]
//            } else {
//                share?.research?.productsNiches?.append(text)
//            }
//        case "competitiveEdge":
//            share?.research?.competitiveEdge = text
//        case "assets":
//            share?.research?.assets = text
//        case "insiderBuying":
//            share?.research?.insiderBuying = text
//        case "shareBuyBacks":
//            share?.research?.shareBuyBacks = text
//        case "theBuyStory":
//            share?.research?.theBuyStory = text
//        case "news":
//            if let date = newsCreationDate {
//                for news in share?.research?.returnNews() ?? [] {
//                    if news.creationDate == date {
//                        news.newsText = text
//                    }
//                }
//            }
//        case "industry":
//            share?.industry = text
//        case "growthType":
//            share?.growthType = text
//        default:
//            print("error: default")
//        }
//
//        share?.save()
//        share?.research?.save()
//    }

    
    
}
