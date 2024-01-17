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
public class StockResearch: NSManagedObject, Codable {
    
    // MARK: - coding
    
    enum CodingKeys: CodingKey {
        case symbol
        case growthPlan
        case companySize
        case productsNiches
        case creationDate
        case assets
        case insiderBuying
        case theBuyStory
        case share
        case news
        case nextReportDate
        case targetBuyPrice
        case annualStatementOutlook
        case pricePredictions
    }
    
    required convenience public init(from decoder: Decoder) throws {
        
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
            throw DecoderConfigurationError.missingManagedObjectContext
        }
        
        self.init(context: context)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.symbol = try container.decodeIfPresent(String.self, forKey: .symbol)
        self.growthPlan = try container.decodeIfPresent(String.self, forKey: .growthPlan)
        self.companySize = try container.decodeIfPresent(String.self, forKey: .companySize)
        self.productsNiches = try container.decodeIfPresent([String].self, forKey: .productsNiches)
        self.creationDate = try container.decodeIfPresent(Date.self, forKey: .creationDate)
        self.assets = try container.decodeIfPresent(String.self, forKey: .assets)
        self.insiderBuying = try container.decodeIfPresent(String.self, forKey: .insiderBuying)
        self.theBuyStory = try container.decodeIfPresent(String.self, forKey: .theBuyStory)
        self.news = try container.decodeIfPresent(Set<CompanyNews>.self, forKey: .news)
        self.nextReportDate = try container.decodeIfPresent(Date.self, forKey: .nextReportDate)
        self.targetBuyPrice = try container.decode(Double.self, forKey: .targetBuyPrice)
        self.annualStatementOutlook = try container.decodeIfPresent(Data.self, forKey: .annualStatementOutlook)
        self.pricePredictions = try container.decodeIfPresent(Data.self, forKey: .pricePredictions)
        
        if let validNews = news {
            for element in validNews {
                element.research = self
                context.insert(element)
            }
        }
        
        
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(symbol, forKey: .symbol)
        try container.encodeIfPresent(growthPlan, forKey: .growthPlan)
        try container.encodeIfPresent(companySize, forKey: .companySize)
        try container.encodeIfPresent(productsNiches, forKey: .productsNiches)
        try container.encodeIfPresent(creationDate, forKey: .creationDate)
        try container.encodeIfPresent(assets, forKey: .assets)
        try container.encodeIfPresent(insiderBuying, forKey: .insiderBuying)
        try container.encodeIfPresent(news, forKey: .news)
        try container.encodeIfPresent(nextReportDate, forKey: .nextReportDate)
        try container.encode(targetBuyPrice, forKey: .targetBuyPrice)
        try container.encodeIfPresent(annualStatementOutlook, forKey: .annualStatementOutlook)
        try container.encodeIfPresent(pricePredictions, forKey: .pricePredictions)
        try container.encodeIfPresent(theBuyStory, forKey: .theBuyStory)
    }

    public override func awakeFromInsert() {
        self.creationDate = Date()
    }
    
    
    public func intendedBuyPrice() -> Double? {
        return (targetBuyPrice != 0.0) ? targetBuyPrice : nil
    }
    
    func save() {
        
        do {
            try self.managedObjectContext?.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error in Research.save function \(nserror), \(nserror.userInfo)")

        }
               
//         DispatchQueue.main.async {
//            do {
//                self.creationDate = Date()
//                try  (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.save()
//             } catch {
//                 let nserror = error as NSError
//                 fatalError("Unresolved error in Research.save function \(nserror), \(nserror.userInfo)")
//             }
//         }
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
    
    func returnAnnualStatementOutlook() -> DatedText? {
        
        if let valid = self.annualStatementOutlook {
            
            do {
                let unarchiver = try NSKeyedUnarchiver(forReadingFrom: valid)
                if let datedText = try unarchiver.decodeTopLevelDecodable(DatedText.self, forKey: NSKeyedArchiveRootObjectKey) {
                    return datedText
                }
            } catch {
                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "error converting PricePredictions to Data for storing")
            }
     
        }
        
        return nil
        
    }
    
    func saveAnnualStatementOutlook(datedText: DatedText?) {
        
        guard let valid =  datedText else {
            return
        }
        
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        do {
            try archiver.encodeEncodable(valid, forKey: NSKeyedArchiveRootObjectKey)
            archiver.finishEncoding()
            self.annualStatementOutlook = archiver.encodedData
        } catch {
            ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "error converting Annual Outlook Statement to Data for storing")
        }

    }


    /// entered in StockResearch in the form of DatedValues = [Date, [Double]]; Date = date of user entry, values are low, mean, high prediction
    func sharePricePredictions() -> DatedValues? {
        
        guard let predictions = self.pricePredictions else { return nil }
        
        do {
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: predictions)
            if let datedValues = try unarchiver.decodeTopLevelDecodable(DatedValues.self, forKey: NSKeyedArchiveRootObjectKey) {
                return datedValues
            }
        } catch {
            ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "error retrieving research share price predictions")
        }

        // OLD
//        if let predictions = self.pricePredictions {
//
//            do {
//                if let dict = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(predictions) as? [Double: Date] {
//                    let keys = dict.keys
//                    var values = [Double]()
//                    for key in keys {
//                        values.append(Double(key) )
//                    }
//                    let date:Date = dict.values.first!
//                    return DatedValues(date: date, values: values.sorted())
//                }
//            } catch let error {
//                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "error retrieving research share price predictions")
//            }
//        }

        return nil
    }
    
    /// entered in StockResearch in the form of DatedValues = [Date, [Double]]; Date = date of user entry, values are low, mean, high prediction
    func savePricePredictions(datedValues: DatedValues?) {
        
        guard let validValues = datedValues else {
            return
        }
        
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        do {
            try archiver.encodeEncodable(validValues, forKey: NSKeyedArchiveRootObjectKey)
            archiver.finishEncoding()
            self.pricePredictions  = archiver.encodedData
        } catch {
            ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "error converting PricePredictions to Data for storing")
        }
        
        // OLD
//        var dict = [Double: Date]()
//        for key in validValues.values {
//            dict[key] = validValues.date
//        }
//
//        do {
//            self.pricePredictions = try NSKeyedArchiver.archivedData(withRootObject: dict, requiringSecureCoding: false)
//            try self.managedObjectContext?.save()
//        } catch let error {
//            ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "error converting PricePredictions to Data for storing")
//        }
        
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
