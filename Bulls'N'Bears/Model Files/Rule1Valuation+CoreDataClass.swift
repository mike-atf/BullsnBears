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
        opcs = [Double]()
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
        adjGrowthEstimates = [Double]()
        opCashFlow = Double()
        netIncome = Double()
        adjFuturePE = Double()
        
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
        years.append(opcs?.count ?? 0)
        years.append(revenue?.count ?? 0)

        return years.min() ?? 0
    }
    
    func getDataFromDCFValuation(dcfValuation: DCFValuation?) {
        
        guard let valuation = dcfValuation else {
            return
        }
        
        var count = 0
        for sales in valuation.tRevenueActual ?? [] {
            self.revenue?.insert(sales, at: count)
            count += 1
        }
                
        count = 0
        for sales in valuation.tFCFo ?? [] {
            self.opcs?.insert(sales, at: count)
            count += 1
        }
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
        
        let moatArrays = [bvps, eps, revenue, opcs]
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
        
        guard sumValidRates > 0 else {
            return nil
        }
        
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
        
        return Double(ratesHigher10) / Double(sumValidRates)
    }
    
    func futureGrowthEstimate() -> Double? {
        
        guard let endValue = bvps?.first else { return nil }
        
        var bvpsGrowthRates = [Double]()
        for yearsBack in 1..<(bvps?.count ?? 0) {
            bvpsGrowthRates.append(compoundGrowthRate(endValue: endValue, startValue: bvps![yearsBack], years: Double(yearsBack)))
        }
        let lowBVPSGrowth = bvpsGrowthRates.mean()
        
        let analystPredictedGrowth = adjGrowthEstimates?.mean() ?? growthEstimates?.mean()
        return analystPredictedGrowth != nil ? analystPredictedGrowth! : lowBVPSGrowth
    }
    
    func futureEPS(futureGrowth: Double) -> Double? {
 
        guard let currentEPS = eps?.first else { return nil }
        return futureValue(present: currentEPS, growth: futureGrowth, years: 10.0)
    }
    
    func futurePER(futureGrowth: Double) -> Double? {
        
        var averageHxPER: Double?
        if (hxPE?.count ?? 0) > 0 {
            averageHxPER = hxPE!.mean()!
        }
        
        if adjFuturePE != Double() { return adjFuturePE }
        else {
            return averageHxPER != nil ? [(futureGrowth*2*100),averageHxPER!].min()! : (futureGrowth*2*100)
        }
    }
    
    func stickerPrice() -> Double? {
        

        guard bvps?.count ?? 0 > 1 else { return nil }
        
        guard let futureGrowth = futureGrowthEstimate() else {
            return nil
        }
         
        guard let epsIn10Years = futureEPS(futureGrowth: futureGrowth) else {
            return nil
        }
        
        guard let futurePER = futurePER(futureGrowth: futureGrowth) else {
            return nil
        }

        let acceptedFuturePER = adjFuturePE != Double() ? adjFuturePE : futurePER
        
        let futureStockPrice = epsIn10Years * acceptedFuturePER
        let stickerPrice = presentValue(growth: 0.15, years: 10, endValue: futureStockPrice)
        
        return stickerPrice
    }

}
