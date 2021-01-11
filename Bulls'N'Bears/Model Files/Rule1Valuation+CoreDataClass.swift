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
        
//        for _ in 0..<reviewYears {
//            bvps?.append(Double())
//            eps?.append(Double())
//            revenue?.append(Double())
//            oFCF?.append(Double())
////            roic?.append(Double()) //excluded so no detail % is shown in ValuationListCell when no value has been entered
//        }
//
//        for _ in 0..<2 {
//            growthEstimates?.append(Double())
//            adjGrowthEstimates?.append(Double())
//            hxPE?.append(Double())
//        }
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
    
    
    internal func compoundGrowthRate(endValue: Double, startValue: Double, years: Double) -> Double {
        
        return (pow((endValue / startValue) , (1/years)) - 1)
    }

    internal func futureValue(present: Double, growth: Double, years: Double) -> Double {
        return present * pow((1+growth), years)
    }
    
    internal func presentValue(growth: Double, years: Double, endValue: Double) -> Double {
        return endValue * (1 / pow(1+growth, years))
    }
    
    /// 0-1
    func moatScore() -> Double? {
        
        let moatArrays = [bvps, eps, revenue, oFCF]
        var moatGrowthRates = [[Double]]()
        
        var sumValidRates = 0
        for moatArray in moatArrays {
            var moatGrowthArray = [Double]()
            if let endValue = moatArray?.first {
                for yearBack in 1..<(moatArray?.count ?? 0) {
                    if let startValue = moatArray?[yearBack] {
                        moatGrowthArray.append(compoundGrowthRate(endValue: endValue, startValue: startValue, years: Double(yearBack)))
                        sumValidRates += 1
                    }
                    else {
                        moatGrowthArray.append(Double())
                    }
                }
            }
            moatGrowthRates.append(moatGrowthArray)
        }
        
        sumValidRates += roic?.compactMap{ $0 }.count ?? 0
        print("total valid moat growth rates \(sumValidRates)")
        
        var ratesHigher10 = 0
        for growthRateArray in moatGrowthRates {
            ratesHigher10 += growthRateArray.filter({ (rate) -> Bool in
                if rate < 0.1 { return false }
                else { return true }
            }).count
        }
        
        ratesHigher10 += roic?.compactMap{ $0 }.filter({ (rate) -> Bool in
            if rate < 0.1 { return false }
            else { return true }
        }).count ?? 0
        
        print("moat growth rates > 10% \(ratesHigher10)")
        
        return Double(ratesHigher10) / Double(sumValidRates)
    }
    
    func stickerPrice() -> Double? {
        
        let cautionScore = 0.33 // 0-1
        
        guard let currentEPS = eps?.first else { return nil }
        guard let endValue = bvps?.first else { return nil }
        guard bvps?.count ?? 0 > 1 else { return nil }
        
        print(eps ?? [])
        print(bvps ?? [])
        
        var bvpsGrowthRates = [Double]()
        for yearsBack in 1..<(bvps?.count ?? 0) {
            bvpsGrowthRates.append(compoundGrowthRate(endValue: endValue, startValue: bvps![yearsBack], years: Double(yearsBack)))
        }
        let lowBVPSGrowth = bvpsGrowthRates.min()! + cautionScore * (bvpsGrowthRates.max()! - bvpsGrowthRates.min()!)
        var analystPredictedGrowth: Double?
        if adjGrowthEstimates?.count ?? 0 > 0 {
            analystPredictedGrowth = adjGrowthEstimates!.compactMap{ $0 }.reduce(0, +) / Double(adjGrowthEstimates!.compactMap{ $0 }.count)
        }
        let growthEstimate = analystPredictedGrowth != nil ? [lowBVPSGrowth,analystPredictedGrowth!].min()! : lowBVPSGrowth
         
        let epsIn10Years = futureValue(present: currentEPS, growth: growthEstimate, years: 10.0)
        var averageHxPER: Double?
        if (hxPE?.count ?? 0) > 0 {
            averageHxPER = hxPE!.reduce(0, +) / Double(hxPE!.count)
        }
        
        let conservativePER = averageHxPER != nil ? [(growthEstimate*2*100),averageHxPER!].min()! : (growthEstimate*2)
        
        let futureStockPrice = epsIn10Years*conservativePER
        let stickerPrice = presentValue(growth: 0.15, years: 10, endValue: futureStockPrice)
        
        return stickerPrice
    }

}
