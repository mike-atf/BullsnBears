//
//  CSVImporter.swift
//  TrendMyStocks
//
//  Created by aDav on 01/12/2020.
//

import Foundation


class CSVImporter: NSObject {
    
    class func openCSVFile(url: URL? = nil, fileName: String) -> String? {
        
        if let fileURL = url {

            do {
                let content = try String(contentsOf: fileURL, encoding: .utf8)
                return content
            } catch let error {
                print("Error reading file content \(error)")
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
                print("Error reading file content \(error)")
            }

        }

        return nil
    }

    class func csvExtractor(url: URL? = nil) -> Stock? {
        
        guard let validURL = url else {
            print("wrong/ missing url when trying to extract CSV")
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
            print("csvExtraction error - no file content")
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
        dateFormatter.dateFormat = "yyy-MM-dd"
        for index in 1..<rows.count { // first line has header titles
            let array = rows[index].components(separatedBy: ",")
            let date$ = array[0]
            guard let date = dateFormatter.date(from: date$) else {
                print("error converting to 'date' \(array[0])")
                continue
            }
            guard let open = Double(array[1]) else {
                print("error converting to 'open' \(array[1])")
                continue
            }
            guard let high = Double(array[2]) else {
                print("error converting to 'high' \(array[2])")
                continue
            }
            guard let low = Double(array[3]) else {
                print("error converting to 'high' \(array[3])")
                continue
            }
            guard let close = Double(array[4]) else {
                print("error converting to 'high' \(array[4])")
                continue

            }
            guard let volume = Double(array[6]) else {
                print("error converting to 'high' \(array[6])")
                continue

            }
            
            let newObject = PricePoint(open: open, close: close, low: low, high: high, volume: volume, date: date)
            stockPrices.append(newObject)
        }

        return Stock(name: stockName, dailyPrices: stockPrices, fileURL: validURL)
    }
}
