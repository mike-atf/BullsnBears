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
public class Company_Info: NSManagedObject {
    
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
