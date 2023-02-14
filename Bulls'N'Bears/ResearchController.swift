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
    
    init(share: Share?, researchList: ResearchTVC?) {
        
        
        self.share = share
        self.controlledView = researchList
        let moc = share?.managedObjectContext ?? (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        if  share?.research == nil {
            share?.research = StockResearch.init(context: moc)
            share?.research?.symbol = share?.symbol
            share?.research?.save()
            share?.research?.share = share
        }
        
//        fillParameters()
        
        titleDictionary = titleParameterDictionary()
    }
    
    /*
    func fillParameters() {
        
        if let validShare = share {
            
            if let marketCap = validShare.key_stats?.marketCap.valuesOnly(dateOrdered: .ascending, withoutZeroes: true)?.last {
                
            }
            
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
                
            }
            
            if let wbValuation = validShare.wbValuation {
                
                if validShare.research?.assets == nil {
                    let lastStockPrice =  validShare.getDailyPrices()?.last?.close
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
                
            }
 
            validShare.save()
        }

    }
    */
    
    func titleParameterDictionary() -> [String : String]? {
        
        guard let names = share?.research!.sections() else { return nil }
        var allNames = names
        allNames.append("industry")

        var sectionTitles = [String: String]()
        
        for name in allNames {
            switch name {
            case "growthPlan":
                sectionTitles[name] = "Predicted earnings range"
            case "futureGrowthMean":
                sectionTitles[name] = "Estimated mean earnings growth (in %)"
            case "companySize":
                sectionTitles[name] = "Size"
            case "productsNiches":
                sectionTitles[name] = "Special products and their impact"
            case "assets":
                sectionTitles[name] = "Assets and their value"
            case "insiderBuying":
                sectionTitles[name] = "Insider buying & selling"
            case "theBuyStory":
                sectionTitles[name] = "Why do you want to own this stock?"
            case "news":
                sectionTitles[name] = "Company news"
            case "industry":
                sectionTitles[name] = "Industry"
            case "businessDescription":
                sectionTitles[name] = "Business description"
            case "nextReportDate":
                sectionTitles[name] = "Date of next Financial Report"
            case "targetBuyPrice":
                sectionTitles[name] = "At what price would you buy?"
            case "pricePredictions":
                var date$ = String()
                if let date = share?.research?.sharePricePredictions()?.date {
                    date$ = " (" + dateFormatter.string(from: date) + ")"
                }
                sectionTitles[name] = "Predicted share prices" + date$
            case "annualStatementOutlook":
                var date$ = String()
                if let date = share?.research?.returnAnnualStatementOutlook()?.date {
                    date$ = " (" + dateFormatter.string(from: date) + ")"
                }
                sectionTitles[name] = "Latest outlook from Annual Report" + date$
            default:
                print("error: default")
            }

        }
        return sectionTitles
    }
    
    func sectionTitles() -> [String] {
        
        var titles = [titleDictionary!["businessDescription"]!]
        
        titles.append(titleDictionary!["industry"]!)
        titles.append(titleDictionary!["companySize"]!)
        titles.append(titleDictionary!["productsNiches"]!)
        titles.append(titleDictionary!["assets"]!)
        titles.append(titleDictionary!["annualStatementOutlook"]!)
        titles.append(titleDictionary!["nextReportDate"]!)
        titles.append(titleDictionary!["news"]!)
        titles.append(titleDictionary!["theBuyStory"]!)
        titles.append(titleDictionary!["growthPlan"]!)
        titles.append(titleDictionary!["futureGrowthMean"]!)
        titles.append(titleDictionary!["pricePredictions"]!)
        titles.append(titleDictionary!["targetBuyPrice"]!)

        return titles
    }
        
    func values(indexPath: IndexPath) -> [String]? {
        
        guard let validDict = titleDictionary else {
            return nil
        }
        
        let title = sectionTitles()[indexPath.section]

        let parameters = Array(titleDictionary!.values.sorted())
        guard parameters.count > indexPath.section else { return nil }
        
        var parameter = String()
        for key in validDict.keys {
            if validDict[key] == title { //parameters[indexPath.section]
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
            
            if let meanGeneralGrowthDV = share?.analysis?.adjFutureGrowthRate.datedValues(dateOrder: .ascending)?.last {
                let valid$ = percentFormatter2Digits.string(from: meanGeneralGrowthDV.value as NSNumber) ?? ""
                return [valid$]
            }
            else if let meanGeneralGrowthDV = share?.analysis?.future_growthNextYear.datedValues(dateOrder: .ascending)?.last {
                let valid$ = percentFormatter2Digits.string(from: meanGeneralGrowthDV.value as NSNumber) ?? ""
                return [valid$]
            } else if let meanRevenueGrowthDV = share?.analysis?.future_revenueGrowthRate.datedValues(dateOrder: .ascending)?.last {
                let valid$ = percentFormatter2Digits.string(from: meanRevenueGrowthDV.value as NSNumber) ?? ""
                return [valid$]
            }
             
            return nil
        case "companySize":
            var employees$ = String()
            if let validEmployees = share?.employees {
                employees$ = "Employees: " + (numberFormatterNoFraction.string(from: validEmployees as NSNumber) ?? "")
            }
            if let valid = share?.key_stats?.marketCap.valuesOnly(dateOrdered: .ascending, withoutZeroes: true)?.last {
                let valid$ = valid.shortString(decimals: 2)
                return [valid$ + ", " + employees$]
            }
            else { return [employees$] }
        case "productsNiches":
            if let valid = share?.research?.productsNiches { return valid }
            else { return nil }
        case "assets":
            if let valid = share?.research?.assets { return [valid] }
            else { return nil }
        case "insiderBuying":
            if let valid = share?.research?.insiderBuying { return [valid] }
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
        case "pricePredictions":
            let pre = ["Low: ", "Mean: ", "High: "]
            if let dVs = share?.research?.sharePricePredictions() {
                var prices$ = [String]()
                var count = 0
                for price in dVs.values {
                    let text = pre[count] + (currencyFormatterNoGapWithPence.string(from: price as NSNumber) ?? "-")
                    prices$.append(text)
                    count += 1
                }
                return prices$
            }
            return pre
        case "annualStatementOutlook":
            if let valid = share?.research?.returnAnnualStatementOutlook() {
                return [valid.text]
            } else {
                return ["https://www.sec.gov/edgar.shtml"]
            }
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
        
        var parameter = sectionTitles()[cellPath.section]
        for key in validDict.keys {
            if validDict[key] == parameter { //parameters[cellPath.section]
                parameter = key
            }
        }
        
        switch parameter {
        case "symbol":
            share?.research?.symbol = notes
        case "growthPlan":
            share?.research?.growthPlan = notes
        case "futureGrowthMean":
            
            if let valid = notes.textToNumber() {
                let newDV = DatedValue(date: Date().addingTimeInterval(365*24*3600), value: valid)
                let newDV2 = DatedValue(date: Date().addingTimeInterval(2*365*24*3600), value: valid)
                share?.analysis?.adjFutureGrowthRate = [newDV,newDV2].convertToData()
            }
        case "companySize":
            if let valid = notes.textToNumber() {
                share?.key_stats?.marketCap = [DatedValue(date: Date(), value: valid)].convertToData()
            }
        case "productsNiches":
            share?.research?.productsNiches?[cellPath.row] = notes
        case "assets":
            share?.research?.assets = notes
        case "insiderBuying":
            share?.research?.insiderBuying = notes
        case "theBuyStory":
            share?.research?.theBuyStory = notes
        case "news":
            share?.research?.returnNews()![cellPath.row].newsText = notes
        case "industry":
            share?.company_info?.industry = notes
        case "businessDescription":
            share?.research?.businessDescription = notes
        case "targetBuyPrice":
            let number = notes.filter("-0123456789.".contains)
            share?.research?.targetBuyPrice = Double(number) ?? 0.0
        case "pricePredictions":
            if var predictions = share?.research?.sharePricePredictions() {
                if predictions.values.count > cellPath.row {
                    predictions.values[cellPath.row] = Double(notes.filter("-0123456789.".contains)) ?? 0
                    predictions.date = Date()
                } else {
                    predictions.values.append(Double(notes.filter("-0123456789.".contains)) ?? 0)
                }
                share?.research?.savePricePredictions(datedValues: predictions)
            } else {
                var values = [0.0,0.0,0.0]
                values[cellPath.row] = Double(notes.filter("-0123456789.".contains)) ?? 0
                let prediction = DatedValues(date: Date(), values: values)
                share?.research?.savePricePredictions(datedValues: prediction)
            }
        case "annualStatementOutlook":
            let datedText = DatedText(date: Date(), text: notes)
            share?.research?.saveAnnualStatementOutlook(datedText: datedText)

        default:
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "Research controller received unexpected user entry category \(parameter)")
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
    

}
