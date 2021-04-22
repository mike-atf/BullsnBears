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
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "Can't read file \(fileURL)")
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
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "Can't read file \(fileURL)")
            }

        }

        return nil
    }

    /*
    class func csvExtractor(url: URL? = nil) -> Stock? {
        
        guard let validURL = url else {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "wrong/ missing url when trying to extract CSV")
            return nil
        }
        
        var stockPrices = [PricePoint]()
        
        var fileContent$: String?
        var rows = [String]()
        var stockName = String()
        
        fileContent$ = openCSVFile(url: validURL, fileName: "nono")
        stockName = String(validURL.lastPathComponent.split(separator: ".").first ?? "missing")

        rows = fileContent$?.components(separatedBy: NSMutableCharacterSet.newlines) ?? []
        
        if rows.count < 1 {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "csvExtraction error - no file content")
            return nil
        }

        let expectedOrder = ["Date","Open","High","Low","Close","Adj Close","Volume"]
        var headerError = false
        if let headerArray = rows.first?.components(separatedBy: ",") {
            var count = 0
            headerArray.forEach { (header) in
                if header != expectedOrder[count] {
                    ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: " trying to read .csv file - header not in required format \(expectedOrder).\nInstead is \(headerArray) " )
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
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "\(stockName) error converting to 'date' \(array[0])")
                continue
            }
            guard let open = Double(array[1]) else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "\(stockName) error converting to 'date' \(array[1])")
                continue
            }
            guard let high = Double(array[2]) else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "\(stockName) error converting to 'date' \(array[2])")
                continue
            }
            guard let low = Double(array[3]) else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "\(stockName) error converting to 'date' \(array[3])")
                continue
            }
            guard let close = Double(array[4]) else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "\(stockName) error converting to 'date' \(array[4])")
                continue
            }
            guard let volume = Double(array[6]) else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "\(stockName) error converting to 'date' \(array[6])")
                continue

            }
            
            let newObject = PricePoint(open: open, close: close, low: low, high: high, volume: volume, date: date)
            stockPrices.append(newObject)
        }

        return Stock(name: stockName, dailyPrices: stockPrices, fileURL: validURL, delegate: nil)
    }
    */
    
    class func extractPricePointsFromFile(url: URL? = nil, symbol: String) -> [PricePoint]? {
        
        guard let validURL = url else {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "wrong/ missing url when trying to extract CSV")
            return nil
        }
        
        guard let lastPathComponent = validURL.lastPathComponent.split(separator: ".").first else {
            return nil
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
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "csvExtraction error - no file content")
            return nil
        }

        let expectedOrder = ["Date","Open","High","Low","Close","Adj Close","Volume"]
        var headerError = false
        if let headerArray = rows.first?.components(separatedBy: ",") {
            var count = 0
            headerArray.forEach { (header) in
                if header != expectedOrder[count] {
                    ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: " trying to read .csv file - header not in required format \(expectedOrder).\nInstead is \(headerArray) " )
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
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "error converting to 'date' \(array[0])")
                continue
            }
            guard let open = Double(array[1]) else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "error converting to 'date' \(array[1])")
                continue
            }
            guard let high = Double(array[2]) else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "error converting to 'date' \(array[2])")
                continue
            }
            guard let low = Double(array[3]) else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "error converting to 'date' \(array[3])")
                continue
            }
            guard let close = Double(array[4]) else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "error converting to 'date' \(array[4])")
                continue
            }
            guard let volume = Double(array[6]) else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "error converting to 'date' \(array[6])")
                continue

            }
            
            let newObject = PricePoint(open: open, close: close, low: low, high: high, volume: volume, date: date)
            stockPrices.append(newObject)
        }
        

        return stockPrices
    }
    
    class func extractPriceData(url: URL?, symbol: String) -> [PricePoint]? {
        
        guard let validURL = url else {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "wrong/ missing url when trying to extract CSV")
            return nil
        }
        
        var stockPrices = [PricePoint]()
        
        var fileContent$: String?
        var rows = [String]()
        var stockName = String()
        
        fileContent$ = openCSVFile(url: validURL, fileName: "nono")
        stockName = String(validURL.lastPathComponent.split(separator: ".").first ?? "missing")
        
        guard stockName == symbol else {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "csvExtraction error - file stoxk  symbol  differs from stock symbol to update")
            return nil
        }

        rows = fileContent$?.components(separatedBy: NSMutableCharacterSet.newlines) ?? []
        
        if rows.count < 1 {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "csvExtraction error - no file content")
            return nil
        }

        let expectedOrder = ["Date","Open","High","Low","Close","Adj Close","Volume"]
        var headerError = false
        if let headerArray = rows.first?.components(separatedBy: ",") {
            var count = 0
            headerArray.forEach { (header) in
                if header != expectedOrder[count] {
                    ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: " trying to read .csv file - header not in required format \(expectedOrder).\nInstead is \(headerArray) " )
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
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "\(stockName) error converting to 'date' \(array[0])")
                continue
            }
            guard let open = Double(array[1]) else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "\(stockName) error converting to 'date' \(array[1])")
                continue
            }
            guard let high = Double(array[2]) else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "\(stockName) error converting to 'date' \(array[2])")
                continue
            }
            guard let low = Double(array[3]) else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "\(stockName) error converting to 'date' \(array[3])")
                continue
            }
            guard let close = Double(array[4]) else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "\(stockName) error converting to 'date' \(array[4])")
                continue
            }
            guard let volume = Double(array[6]) else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "\(stockName) error converting to 'date' \(array[6])")
                continue

            }
            
            let newObject = PricePoint(open: open, close: close, low: low, high: high, volume: volume, date: date)
            stockPrices.append(newObject)
        }
        
        return stockPrices
    }
    
    /// checks that first row if csv files has the expected header elements
    class func matchesExpectedFormat(url: URL?) -> Bool {
        
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

        let expectedOrder = ["Date","Open","High","Low","Close","Adj Close","Volume"]
        var headerError = false

        if let headerArray = rows.first?.components(separatedBy: ",") {
            var count = 0
            headerArray.forEach { (header) in
                if header != expectedOrder[count] {
                    headerError = true
                }
                count += 1
            }
        }
        
        if headerError {
            return false
            
        }
        else { return true }
    }
    
    /*
    class func webCsvExtractor(path: String? = nil) -> Stock? {
        
        guard let validPath = path else {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "wrong/ missing url when trying to extract CSV")
            return nil
        }
       
        var stockPrices = [PricePoint]()
        
        var fileContent$: String?
        var rows = [String]()

        var stockName = String()
        if let i = validPath.range(of: "download/") {
            if let qm = validPath.firstIndex(of: "?") {
                stockName = String(validPath[i.upperBound..<qm])
            }
        }
        
        if let url = URL(string: validPath) {
            do {
                fileContent$ = try String(contentsOf: url)
                // save file to Document folder
            } catch {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "can't load content from \(path ?? "nil")")
                return nil
            }
        } else {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "can't create valid URL from path \(path ?? "nil")")
            return nil

        }
        rows = fileContent$?.components(separatedBy: NSMutableCharacterSet.newlines) ?? []
        
        if rows.count < 1 {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "csvExtraction error - no file content")
            return nil
        }

        let expectedOrder = ["Date","Open","High","Low","Close","Adj Close","Volume"]
        if let headerArray = rows.first?.components(separatedBy: ",") {
            var count = 0
            headerArray.forEach { (header) in
                if header != expectedOrder[count] { print("error in order, should be \(expectedOrder) but is \(headerArray)")}
                count += 1
            }
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        for index in 1..<rows.count { // first line has header titles
            let array = rows[index].components(separatedBy: ",")
            let date$ = array[0]
            guard let date = dateFormatter.date(from: date$) else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "\(stockName) error converting to 'date' \(array[0])")
                continue
            }
            guard let open = Double(array[1]) else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "\(stockName) error converting to 'date' \(array[1])")
                continue
            }
            guard let high = Double(array[2]) else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "\(stockName) error converting to 'date' \(array[2])")
                continue
            }
            guard let low = Double(array[3]) else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "\(stockName) error converting to 'date' \(array[3])")
                continue
            }
            guard let close = Double(array[4]) else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "\(stockName) error converting to 'date' \(array[4])")
                continue
            }
            guard let volume = Double(array[6]) else {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: nil, errorInfo: "\(stockName) error converting to 'date' \(array[6])")
                continue

            }
            
            let newObject = PricePoint(open: open, close: close, low: low, high: high, volume: volume, date: date)
            stockPrices.append(newObject)
        }

        return Stock(name: stockName, dailyPrices: stockPrices, fileURL: nil, delegate: nil)
    }
    */
}
