//
//  CSVImporter.swift
//  TrendMyStocks
//
//  Created by aDav on 01/12/2020.
//

import UIKit


class CSVImporter: NSObject {
    
    class func openCSVFile(url: URL? = nil, fileName: String) -> String? {
        
        if let fileURL = url {
            // dont use 'fileURL.startAccessingSecurityScopedResource()' on App sandbox /Documents folder as access is always granted and the access request will alwys return false
            do {
                
                let content = try String(contentsOf: fileURL, encoding: .utf8)
                return content

            } catch let error {
                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "Can't read file \(fileURL)")
            }

        }
        else {
            guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: "csv") else {
                return nil
            }
            
            do {
                let content = try String(contentsOf: fileURL, encoding: .utf8)
                return content
            } catch let error {
                ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "Can't read file \(fileURL)")
            }

        }

        return nil
    }

    /// extracts pricepoint data from yahoo csv file. Going through in descending time order will stop at minDate if provided. If providing specific date will provide pricepoint for this date only
    class func extractPricePointsFromFile(url: URL?, symbol: String, minDate:Date?=nil, specificDate:Date?=nil) -> [PricePoint]? {
        
        guard let validURL = url else {
            ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "wrong/ missing url when trying to extract CSV")
            return nil
        }
        
        var lastPathComponent = String()
        if #available(iOS 16.0, *) {
            lastPathComponent = validURL.lastPathComponent.replacing(".csv", with: "")
        } else {
            if let csvRange = validURL.lastPathComponent.range(of: ".csv") {
                lastPathComponent = String(validURL.lastPathComponent[...csvRange.lowerBound])
            }
        }
        
        if let type = lastPathComponent.range(of: "_") {
            lastPathComponent = String(lastPathComponent[..<type.lowerBound])
        }

        guard symbol == String(lastPathComponent) else {
            return nil
        }
        
        var stockPrices = [PricePoint]()
        var fileContent$: String?
        var rows = [String]()
        
        fileContent$ = openCSVFile(url: validURL, fileName: "nono")

        rows = fileContent$?.components(separatedBy: NSMutableCharacterSet.newlines) ?? []
        
        if rows.count < 1 {
            ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "csvExtraction error - no file content")
            return nil
        }

        let expectedOrder = ["Date","Open","High","Low","Close","Adj Close","Volume"]
        var headerError = false
        if let headerArray = rows.first?.components(separatedBy: ",") {
            var count = 0
            headerArray.forEach { (header) in
                if header != expectedOrder[count] {
                    ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: " trying to read .csv file - header not in required format \(expectedOrder).\nInstead is \(headerArray) " )
                    headerError = true
                }
                count += 1
            }
        }
        
        if headerError {
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if let specific = specificDate {
            let firstRowArray = rows[1].components(separatedBy: ",")
            guard let date$ = firstRowArray.first else {
                return nil
            }
            guard let date = dateFormatter.date(from: date$) else {
                return nil
            }
            
            // if earliest date is after specific date the specific date can't be returned
            if date.addingTimeInterval(-week) > specific {
                return nil
            }
        }
        
        for index in 1..<rows.count { // first line has header titles, Yahoo csv files are in date ASCENDING order
            let array = rows[index].components(separatedBy: ",")
            let date$ = array[0]
            guard let date = dateFormatter.date(from: date$) else {
                ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "error converting to 'date' \(array[0])")
                continue
            }
            
            // don't add rows if date < limit; csv is in date ASCENDING order
            if let limit = minDate {
                if date < limit {
                    continue
                }
            }

            guard let open = Double(array[1]) else {
                ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "error converting to 'date' \(array[1])")
                continue
            }
            guard let high = Double(array[2]) else {
                ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "error converting to 'date' \(array[2])")
                continue
            }
            guard let low = Double(array[3]) else {
                ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "error converting to 'date' \(array[3])")
                continue
            }
            guard let close = Double(array[4]) else {
                ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "error converting to 'date' \(array[4])")
                continue
            }
            guard let volume = Double(array[6]) else {
                ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "error converting to 'date' \(array[6])")
                continue

            }
            
            if specificDate == nil {
                let newObject = PricePoint(open: open, close: close, low: low, high: high, volume: volume, date: date)
                stockPrices.append(newObject)
            } else {
                if date > specificDate! {
                    let newObject = PricePoint(open: open, close: close, low: low, high: high, volume: volume, date: date)
                    return [newObject]
                }
            }
            
        }
        

        return stockPrices
    }
    
    class func extractTBondRatesFromCSVFile(url: URL? = nil, expectedHeaderTitles: [String]) -> [DatedValue]? {
        
        guard let validURL = url else {
            ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "wrong/ missing url when trying to extract CSV")
            return nil
        }
        
        guard validURL.lastPathComponent.split(separator: ".").first != nil else {
            return nil
        }
        
        var datedValues = [DatedValue]()
        var fileContent$: String?
        var rows = [String]()
        
        fileContent$ = openCSVFile(url: validURL, fileName: "nono")

        rows = fileContent$?.components(separatedBy: NSMutableCharacterSet.newlines) ?? []
        
        if rows.count < 1 {
            ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "csvExtraction error - no file content for \(validURL)")
            return nil
        }

        let expectedOrder = expectedHeaderTitles
        var headerError = false
        if let headerArray = rows.first?.components(separatedBy: ",") {
            var count = 0
            headerArray.forEach { (header) in
                if header != expectedOrder[count] {
                    ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: " trying to read .csv file \(validURL) - header not in required format \(expectedOrder).\nInstead is \(headerArray) " )
                    headerError = true
                }
                count += 1
            }
        }
        
        if headerError { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        for index in 1..<rows.count { // first line has header titles
            let array = rows[index].components(separatedBy: ",")
            let date$ = array[0]
            guard let date = dateFormatter.date(from: date$) else {
                ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "error converting to 'date' \(array[0])")
                continue
            }
            guard let tenYrate = Double(array[11]) else {
                ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "error converting to 10 year rate \(array[11])")
                continue
            }

            
            let newObject = DatedValue(date: date, value: tenYrate)
            datedValues.append(newObject)
        }
        

        return datedValues
    }

    /*
    /// extracts pricepoint data from yahoo csv file. Going through in descending time order will stop at minDate if provided. If providing specific date will provide pricepoint for this date only
    class func extractPriceData(url: URL?, symbol: String, minDate:Date?=nil, specificDate:Date?=nil) -> [PricePoint]? {
        
        guard let validURL = url else {
            ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "wrong/ missing url when trying to extract CSV")
            return nil
        }
        
        var stockPrices = [PricePoint]()
        
        var fileContent$: String?
        var rows = [String]()
        var stockName = String()
        
        fileContent$ = openCSVFile(url: validURL, fileName: "nono")
        stockName = String(validURL.lastPathComponent.split(separator: ".").first ?? "missing")
        
        guard stockName == symbol else {
            ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "csvExtraction error \(validURL) - file stock symbol \(symbol) differs from stock symbol to update \(stockName)")
            return nil
        }

        rows = fileContent$?.components(separatedBy: NSMutableCharacterSet.newlines) ?? []
        
        if rows.count < 1 {
            ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "csvExtraction error - no file content for \(validURL)")
            return nil
        }

        let expectedOrder = ["Date","Open","High","Low","Close","Adj Close","Volume"]
        var headerError = false
        if let headerArray = rows.first?.components(separatedBy: ",") {
            var count = 0
            headerArray.forEach { (header) in
                if header != expectedOrder[count] {
                    ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: " trying to read .csv file - header not in required format \(expectedOrder).\nInstead is \(headerArray) " )
                    headerError = true
                }
                count += 1
            }
        }
        
        if headerError { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        for index in 1..<rows.count { // first line has header titles
            let array = rows[index].components(separatedBy: ",")
            let date$ = array[0]
            guard let date = dateFormatter.date(from: date$) else {
                ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "\(stockName) error converting to 'date' \(array[0])")
                continue
            }
            guard let open = Double(array[1]) else {
                ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "\(stockName) error converting to 'date' \(array[1])")
                continue
            }
            guard let high = Double(array[2]) else {
                ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "\(stockName) error converting to 'date' \(array[2])")
                continue
            }
            guard let low = Double(array[3]) else {
                ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "\(stockName) error converting to 'date' \(array[3])")
                continue
            }
            guard let close = Double(array[4]) else {
                ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "\(stockName) error converting to 'date' \(array[4])")
                continue
            }
            guard let volume = Double(array[6]) else {
                ErrorController.addInternalError(errorLocation: #function, systemError: nil, errorInfo: "\(stockName) error converting to 'date' \(array[6])")
                continue

            }
            
            if specificDate == nil {
                let newObject = PricePoint(open: open, close: close, low: low, high: high, volume: volume, date: date)
                stockPrices.append(newObject)
            } else {
                if date < specificDate! {
                    let newObject = PricePoint(open: open, close: close, low: low, high: high, volume: volume, date: date)
                    return [newObject]
                }
            }
            
            if let limit = minDate {
                if date < limit {
                    return stockPrices
                }
            }
        }
        
        return stockPrices
    }
    */
    
    /// checks that first row if csv files has the expected header elements
    class func matchesExpectedFormat(url: URL?, expectedHeaderTitles:[String]) -> Bool {
        
        guard let validURL = url else {
            return false
        }
        
        var fileContent$: String?
        var rows = [String]()
        
        fileContent$ = openCSVFile(url: validURL, fileName: "nono")

        rows = fileContent$?.components(separatedBy: NSMutableCharacterSet.newlines) ?? []
        
        if rows.count < 1 {
            return false
        }

        let expectedOrder = expectedHeaderTitles
        var headerError = false

        if let headerArray = rows.first?.components(separatedBy: ",") {
            var count = 0
            headerArray.forEach { (header) in
                if count < expectedOrder.count {
                    if header != expectedOrder[count] {
                        headerError = true
                    }
                    count += 1
                }
            }
        }
        
        if headerError {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "checking file format returned header error \(headerError)")
            return false
            
        }
        else { return true }
    }
}
