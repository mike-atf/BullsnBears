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
        
        fillParameters()
        
        titleDictionary = titleParameterDictionary()
    }
    
    func fillParameters() {
        
        if let validShare = share {
            
            if validShare.research?.companySize == nil {
                if let validDCF = validShare.dcfValuation {
                    let mcap = validDCF.marketCap
                    share?.research?.companySize = "MCap = " + (currencyFormatterGapNoPence.string(from: mcap as NSNumber) ?? "-")
                }
            }

            if let validR1 = validShare.rule1Valuation {
                
                if validShare.research?.insiderBuying == nil {
                    if validR1.insiderStocks > 0 {
                        let buying = validR1.insiderStockBuys / validR1.insiderStocks
                        let selling = validR1.insiderStockSells / validR1.insiderStocks
                        var text = "Buying: " + (percentFormatter0Digits.string(from: buying as NSNumber) ?? "-")
                        text += ", selling: " + (percentFormatter0Digits.string(from: selling as NSNumber) ?? "-")
                        share?.research?.insiderBuying = text
                    }
                }
                
                if validShare.research?.competitiveEdge == nil {
                    if let score = validR1.moatScore() {
                        share?.research?.competitiveEdge = "Moat = " + (percentFormatter0Digits.string(from: score as NSNumber) ?? "-")
                    }
                }
            }
            
            if let wbValuation = validShare.wbValuation {
                
                if validShare.research?.assets == nil {
                    let lastStockPrice =  validShare.getDailyPrices()?.last?.close //stock.dailyPrices.last?.close
                    if let valid = wbValuation.bvps?.first {
                        if lastStockPrice != nil {
                            if let t$ = percentFormatter0Digits.string(from: (valid / lastStockPrice!) as NSNumber) {
                                if let t2$ = currencyFormatterGapWithPence.string(from: valid as NSNumber) {
                                    validShare.research?.assets = "Book value per share / price per share: " + t$ + " (" + t2$ + ")"
                                }
                            }
                        }
                    }

                }
                
                if validShare.research?.shareBuyBacks == nil {
                    if let retEarningsGrowths = wbValuation.equityRepurchased?.growthRates() {
                        if let meanGrowth = retEarningsGrowths.ema(periods: 7) {
                            let lastValue = wbValuation.equityRepurchased!.first!
                            let lastValue$ = lastValue > 0 ? "Retained earnings positive" : "Retained earnings negative"
                            validShare.research?.shareBuyBacks = lastValue$ + ", EMA7: " + (percentFormatter0DigitsPositive.string(from: meanGrowth as NSNumber) ?? "-")
                        }
                    }
                }
            }
 
            if validShare.research?.crisisPerformance == nil {
                validShare.research?.crisisPerformance = "2020 Corona:\n2008 Crash:\n2000 Bubble:"
            }
            validShare.save()
        }

    }
    
    func titleParameterDictionary() -> [String : String]? {
        
        guard let names = share?.research!.sections() else { return nil }
        var allNames = names
        allNames.append("industry")
        allNames.append("growthType")
        allNames.append("growthSubType")

        var sectionTitles = [String: String]()
        
        for name in allNames {
            switch name {
            case "growthPlan":
                sectionTitles[name] = "Future growth plan"
            case "futureGrowthMean":
                sectionTitles[name] = "Future mean earnings growth estimate (%)"
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
            case "growthSubType":
                sectionTitles[name] = "Growth Sub Category" // enum GrowthCategoryNames
            case "businessDescription":
                sectionTitles[name] = "Products or Services" // enum GrowthCategoryNames
            case "nextReportDate":
                sectionTitles[name] = "Date of next Financial Report"
            case "targetBuyPrice":
                sectionTitles[name] = "x - at what price would you buy?"
            default:
                print("error: default")
            }

        }
        return sectionTitles
    }
    
    func sectionTitles() -> [String] {
        
        return Array(titleDictionary!.values.sorted())
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
        case "businessDescription":
            if let valid = share?.research?.businessDescription { return [valid] }
            else { return nil }
        case "symbol":
            if let valid = share?.research?.symbol { return [valid] }
            else { return nil }
        case "growthPlan":
            if let valid = share?.research?.growthPlan { return [valid] }
            else { return nil }
        case "targetBuyPrice":
            if let price = share?.research?.intendedBuyPrice() {
                return [currencyFormatterNoGapWithPence.string(from: price as NSNumber) ?? ""] }
            else { return nil }
        case "futureGrowthMean":
            if let valid = share?.research?.futureGrowthMean {
                let valid$ = percentFormatter2Digits.string(from: valid as NSNumber) ?? ""
                return [valid$]
            }
            else { return nil }
        case "crisisPerformance":
            if let valid = share?.research?.crisisPerformance { return [valid] }
            else { return nil }
        case "companySize":
            var employees$ = String()
            if let validEmployees = share?.employees {
                employees$ = "Employees: " + (numberFormatterNoFraction.string(from: validEmployees as NSNumber) ?? "")
            }
            if let valid = share?.research?.companySize {
                return [valid + ", " + employees$]
            }
            else { return [employees$] }
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
                if let v = share?.growthSubType {
                    return [valid, v]
                }
                else {
                    return [valid]
                }
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
    
    
    func userEnteredDate(date: Date, cellPath: IndexPath) {
        
        if sectionTitles()[cellPath.section].lowercased().contains("report") {
            share?.research?.nextReportDate = date
        }
    }

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
        case "futureGrowthMean":
            let valid$ = notes.filter("-0123456789.".contains)
            share?.research?.futureGrowthMean = (Double(valid$) ?? 0.0) / 100
        case "crisisPerformance":
            share?.research?.crisisPerformance = notes
        case "companySize":
            share?.research?.companySize = notes
        case "competitors":
            share?.research?.competitors?[cellPath.row] = notes
            transferCompetitors(symbol: notes)
        case "productsNiches":
            share?.research?.productsNiches?[cellPath.row] = notes
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
        case "industry":
            share?.industry = notes
        case "growth type":
            share?.growthType = notes
        case "growthSubType":
            share?.growthSubType = notes
        case "businessDescription":
            share?.research?.businessDescription = notes
        case "targetBuyPrice":
            let number = notes.filter("-0123456789.".contains)
            share?.research?.targetBuyPrice = Double(number) ?? 0.0
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
    
    func transferCompetitors(symbol: String) {
        
        if let competitor = StocksController2.allShares()?.filter({ (share) -> Bool in
            if share.symbol == symbol { return true }
            else { return false }
        }).first {
            if competitor.research == nil {
                let newResearch = StockResearch.init(context: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)
                newResearch.symbol = competitor.symbol
                newResearch.competitors = [self.share?.symbol ?? ""]
                newResearch.save()
            }
            else {
                if competitor.research!.competitors == nil {
                    competitor.research!.competitors = [self.share?.symbol ?? ""]
                }
                else {
                    if !competitor.research!.competitors!.contains(self.share?.symbol ?? "") {
                        competitor.research!.competitors!.append(self.share?.symbol ?? "")
                    }
                }
                competitor.research?.save()
            }
            if competitor.industry == nil && self.share?.industry != nil {
                competitor.industry = self.share?.industry!
                competitor.save()
            }
        }
        
    }
}
