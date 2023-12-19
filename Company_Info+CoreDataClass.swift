//
//  Company_Info+CoreDataClass.swift
//  Bulls'N'Bears
//
//  Created by aDav on 08/01/2023.
//
//

import Foundation
import CoreData

enum CompanyInfoParameters {
    case employees
    case industry
    case sector
    case businessDescription
}


@objc(Company_Info)
public class Company_Info: NSManagedObject, Codable {
    
    // MARK: - coding
    
    enum CodingKeys: CodingKey {
        case employees
        case industry
        case sector
        case businessDescription
        case share
        case shareSymbol
   }
    
    required convenience public init(from decoder: Decoder) throws {
        
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
            throw DecoderConfigurationError.missingManagedObjectContext
        }
        
        self.init(context: context)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.employees = try container.decodeIfPresent(Data.self, forKey: .employees)
        self.industry = try container.decodeIfPresent(String.self, forKey: .industry)
        self.sector = try container.decodeIfPresent(String.self, forKey: .sector)
        self.businessDescription = try container.decodeIfPresent(String.self, forKey: .businessDescription)
//        self.share = try container.decodeIfPresent(Share.self, forKey: .share)
//        self.shareSymbol = try container.decode(String.self, forKey: .shareSymbol)

    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(employees, forKey: .employees)
        try container.encodeIfPresent(industry, forKey: .industry)
        try container.encodeIfPresent(sector, forKey: .sector)
        try container.encodeIfPresent(businessDescription, forKey: .businessDescription)
//        try container.encodeIfPresent(share, forKey: .share)
//        try container.encode(shareSymbol!, forKey: .shareSymbol)

    }
    
    func getValues(parameter: CompanyInfoParameters) -> Labelled_DatedValues? {
        
        let label = "Employees"
        let datedValues = employees.datedValues(dateOrder: .ascending)
        
        if let dv = datedValues {
            return Labelled_DatedValues(label:label, datedValues: dv)
        } else {
            return nil
        }
    }

}
