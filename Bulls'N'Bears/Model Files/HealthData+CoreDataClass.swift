//
//  HealthData+CoreDataClass.swift
//  Bulls'N'Bears
//
//  Created by aDev on 13/12/2023.
//
//

import Foundation
import CoreData

@objc(HealthData)
public class HealthData: NSManagedObject, Codable {
    
    // MARK: - coding
    
    enum CodingKeys: CodingKey {
        case profitability
        case efficiency
        case quickRatio
        case currentRatio
        case solvency
        case share
        case shareSymbol
    }
    
    required convenience public init(from decoder: Decoder) throws {
        
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
            throw DecoderConfigurationError.missingManagedObjectContext
        }
        
        self.init(context: context)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.profitability = try container.decodeIfPresent(Data.self, forKey: .profitability)
        self.efficiency = try container.decodeIfPresent(Data.self, forKey: .efficiency)
        self.quickRatio = try container.decodeIfPresent(Data.self, forKey: .quickRatio)
        self.currentRatio = try container.decodeIfPresent(Data.self, forKey: .currentRatio)
        self.solvency = try container.decodeIfPresent(Data.self, forKey: .solvency)
//        self.share = try container.decodeIfPresent(Share.self, forKey: .share)
//        self.shareSymbol = try container.decode(String.self, forKey: .shareSymbol)

    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(profitability, forKey: .profitability)
        try container.encodeIfPresent(efficiency, forKey: .efficiency)
        try container.encodeIfPresent(quickRatio, forKey: .quickRatio)
        try container.encodeIfPresent(currentRatio, forKey: .currentRatio)
        try container.encodeIfPresent(solvency, forKey: .solvency)
//        try container.encodeIfPresent(share, forKey: .share)
//        try container.encode(shareSymbol!, forKey: .shareSymbol)

    }

    //MARK: - save
    
    func save() {
    
        let context = self.managedObjectContext
        if context?.hasChanges ?? false {
            context?.perform {
                do {
                    try context?.save()
                } catch {
                    alertController.showDialog(title: "Fatal error", alertMessage: "The App can't save data due to \(error.localizedDescription)\nPlease quit and re-launch", viewController: nil, delegate: nil)
                }

            }
        }
    }

}
