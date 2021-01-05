//
//  DCFValuation+CoreDataClass.swift
//  TrendMyStocks
//
//  Created by aDav on 02/01/2021.
//
//

import Foundation
import CoreData

@objc(DCFValuation)
public class DCFValuation: NSManagedObject {
    
    let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.currencySymbol = "$"
        formatter.numberStyle = NumberFormatter.Style.currency
        return formatter
    }()

    let reviewYears = 4
    let predictionYears = 2
    
    override public func awakeFromInsert() {
        tFCFo = [Double]()
        capExpend = [Double]()
        netIncome = [Double]()
        tRevenueActual = [Double]()
        tRevenuePred = [Double]()
        revGrowthPred = [Double]()
        revGrowthPredAdj = [Double]()
        
        for _ in 0..<reviewYears {
            tRevenueActual?.append(Double())
            tFCFo?.append(Double())
            capExpend?.append(Double())
            netIncome?.append(Double())
        }
        
        for _ in 0..<predictionYears {
            revGrowthPred?.append(Double())
            tRevenuePred?.append(Double())
        }
        
        expenseInterest = Double()
        debtST = Double()
        debtLT = Double()
        incomePreTax = Double()
        expenseIncomeTax = Double()
        marketCap = Double()
        beta = Double()
        sharesOutstanding = Double()
        
        company = String()
        creationDate = Date()
    }
    
    static func create(company: String, in managedObjectContext: NSManagedObjectContext) {
        let newValuation = self.init(context: managedObjectContext)
        newValuation.company = company

        do {
            try  managedObjectContext.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
        
    static func save(in context: NSManagedObjectContext) {
        
        do {
            try  context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error in SiteDetails.save function \(nserror), \(nserror.userInfo)")
        }

    }
    
    func delete(from managedObjectContext: NSManagedObjectContext) {
       
        managedObjectContext.delete(self)
 
        do {
            try managedObjectContext.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

    public func returnIvalue() -> String? {
        var intrinsicValue: Double?
        
        if let value = intrinsicValue {
            return currencyFormatter.string(from: value as NSNumber)
        }
        else {
            return nil
        }
    }
    
    public func returnValuationListItem(indexPath: IndexPath) -> Any {
        
        switch indexPath.section {
        case 0:
            // 'General
            switch indexPath.row {
            case 0:
                return creationDate!
            case 1:
                return UserDefaults.standard.value(forKey: "10YUSTreasuryBondRate") as! Double
            case 2:
                return UserDefaults.standard.value(forKey: "PerpetualGrowthRate") as! Double
            case 3:
                return UserDefaults.standard.value(forKey: "LongTermMarketReturn") as! Double
            default:
                print("undefined indexpath \(indexPath) in DCFValuation.returnValuationListItem")
            }
        case 1:
            // 'Key Statistics
            switch indexPath.row {
            case 0:
                return marketCap
            case 1:
                return beta
            default:
                print("undefined indexpath \(indexPath) in DCFValuation.returnValuationListItem")
            }
        case 2:
            // 'Income Statement S1 - Revenue
            return tRevenueActual![indexPath.row]
        case 3:
            // 'Income Statement S2 - net income
            return netIncome![indexPath.row]
        case 4:
            // 'Income Statement S3 - 
            switch indexPath.row {
            case 0:
                return expenseInterest
            case 1:
                return incomePreTax
            case 2:
                return expenseIncomeTax
            default:
                print("undefined indexpath \(indexPath) in DCFValuation.returnValuationListItem")
            }
        case 5:
            // 'balance sheet'
            switch indexPath.row {
            case 0:
                return debtST
            case 1:
                return debtLT
            default:
                print("undefined indexpath \(indexPath) in DCFValuation.returnValuationListItem")
            }
        case 6:
            // 'Cash Flow S1
            return tFCFo![indexPath.row]
        case 7:
            // 'Cash Flow S2
        return capExpend![indexPath.row]
        case 8:
            // 'Prediction S1
            return tRevenuePred![indexPath.row]
       case 9:
            // 'Prediction S2
            return revGrowthPred![indexPath.row]
        default:
            print("undefined indexpath \(indexPath) in DCFValuation.returnValuationListItem")
        }
        
        return "error"
        
    }


}
