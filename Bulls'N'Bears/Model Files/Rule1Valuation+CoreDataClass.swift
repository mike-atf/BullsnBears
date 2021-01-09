//
//  Rule1Valuation+CoreDataClass.swift
//  TrendMyStocks
//
//  Created by aDav on 02/01/2021.
//
//

import Foundation
import CoreData

@objc(Rule1Valuation)
public class Rule1Valuation: NSManagedObject {
    
    static func create(in managedObjectContext: NSManagedObjectContext) {
        let newValuation = self.init(context: managedObjectContext)
        newValuation.creationDate = Date()

        do {
            try  managedObjectContext.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    override public func awakeFromInsert() {
        
        bvps = [Double]()
        eps = [Double]()
        revenue = [Double]()
        oFCF = [Double]()
        roic = [Double]()
        debt = Double()
        hxPE = [Double]()
        growthEstimates = [Double]()
        insiderStockBuys = Double()
        insiderStockSells = Double()
        company = String()
        creationDate = Date()
        insiderStocks = Double()
        ceoRating = Double()
        
        let reviewYears = 10
        
        for _ in 0..<reviewYears {
            bvps?.append(Double())
            eps?.append(Double())
            revenue?.append(Double())
            oFCF?.append(Double())
            roic?.append(Double())
        }
        
        for _ in 0..<2 {
            growthEstimates?.append(Double())
            adjGrowthEstimates?.append(Double())
            hxPE?.append(Double())
        }
    }

    
    func save() {
        
        guard let context = managedObjectContext else {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "no moc available - can't save valuation")
            return
        }
        do {
            try  context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error in SiteDetails.save function \(nserror), \(nserror.userInfo)")
        }

    }

    func delete() {
       
        managedObjectContext?.delete(self)
 
        do {
            try managedObjectContext?.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    func historicalYearsCompleted() -> Int {
        var years = [0]
        years.append(eps?.count ?? 0)
        years.append(roic?.count ?? 0)
        years.append(bvps?.count ?? 0)
        years.append(oFCF?.count ?? 0)
        years.append(revenue?.count ?? 0)

        return years.min() ?? 0
    }
    
    /// 0-1
    func moatScore() -> Double? {
        
        return nil
    }
    
    func stickerPrice() -> Double? {
        
        return nil
    }

}
