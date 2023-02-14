//
//  TSScraper.swift
//  Bulls'N'Bears
//
//  Created by aDav on 13/01/2023.
//

import Foundation

class TagesschauScraper {
    
    class func rule1DownloadAndAnalyse(htmlText: String, symbol: String?, progressDelegate: ProgressViewDelegate?=nil) throws -> [Labelled_DatedValues] {
        
        let sectionHeaders = ["Gewinn und Verlustrechnung", ">Bilanz</h2>", "Wertpapierdaten"]
        // vermeide äöü in html search string
        let rowTitles = [["Umsatz","Herstellungskosten", "Forschungs- und Entwicklungskosten","Buchwert je Aktie","Verwaltungsaufwand","Sonstige betriebliche Aufwendungen"],["Summe langfristiges Fremdkapital"],["Ausstehende Aktien in Mio.","Gewinn je Aktie", "Aktuell ausstehende Aktien"]]

        var results = [Labelled_DatedValues]()
        var sga: [DatedValue]?
        var sharesOutstanding:[DatedValue]?
        do {
            // isin and currency data have to be sent via notification as there is no access to the share object in this function
            var sendDictionary = [String: String]()

            if let isin = try TagesschauScraper.extractStringFromPage(html: htmlText, searchTerm: "ISIN:") {
                sendDictionary["isin"] = isin
            }
            if let currency = try TagesschauScraper.extractStringFromPage(html: htmlText, searchTerm: "hrung:") {//Währung
                sendDictionary["currency"] = currency
            }
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: "ISIN and CURRENCY INFO"), object: symbol, userInfo: sendDictionary)
            
            var count = 0
            for header in sectionHeaders {
                for rowTitle in rowTitles[count] {
                    
                    if let ldvs = TagesschauScraper.extractDataFromPage(html: htmlText, sectionHeader: header, rowTitle: rowTitle) {
                        
                        let relabelledDatedValues = translateGermanLabelledValuesForR1(labelledDatedValues: ldvs)
                        
                        if relabelledDatedValues.label.contains("SGA"){
                            // add up different components of SGA: Werwaltungsaufwand, Herstellungskosten, sontige betriebliche Aufwendungen
                            if sga == nil {
                                sga = relabelledDatedValues.datedValues
                            } else  {
                                for i in 0..<sga!.count {
                                    sga![i].value += relabelledDatedValues.datedValues[i].value
                                }
                                // don't append to results; use the sum of sga to creat summary sga LDV
                            }
                        } else if relabelledDatedValues.label.contains("Shares") {
                            // merge '"Ausstehende Aktien in Mio." and "Aktuell ausstehende Aktien". Sometimes they complement empty columns (eg. Siemens AG). If in doubt use "Ausstehende Aktien in Mio."
                            if sharesOutstanding == nil {
                                sharesOutstanding = relabelledDatedValues.datedValues
                            } else {
                                let min = [sharesOutstanding!.count,relabelledDatedValues.datedValues.count].min() ?? 0
                                for i in 0..<min {
                                    if sharesOutstanding![i].value == 0.0 {
                                        sharesOutstanding![i].value = relabelledDatedValues.datedValues[i].value
                                    }
                                }
                            }
                            // don't append to results; use the sum of sga to creat summary sga LDV
                        } else {
                            results.append(relabelledDatedValues)
                        }
                    }
                }
                count += 1
            }
        } catch {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "extractData from Tagesschau failed for some row titles")

        }
        
        if let valid = sga {
            let sgaLDV = Labelled_DatedValues(label: "SGA", datedValues: valid)
            results.append(sgaLDV)
        }
        if let valid = sharesOutstanding {
            let sho = Labelled_DatedValues(label: "Shares outstanding", datedValues: valid)
            results.append(sho)
        }

        return results
        
    }

    
    class func extractDataFromPage(html: String, sectionHeader: String, rowTitle: String) -> Labelled_DatedValues? {
                
        let sectionEnd = "</tbody>"
//        let rowStartSeq = "<tr>"
        let rowEndSeq = "</tr>"
        
//        let columnStartSeq = "<td>"
        let columnEndSeq = "</td>"
        
//        let tableStartSeq = " <table class"
//        let tableEndSeq = "</table>"
        
        let topRowStartSeq = "<thead>"
        let topRowEndSeq = " </thead>"
        let topRowValueStartSeq = "<th>"
        
//        let valueEndSeq = "</span>"

        var values = [Double]()
        var dates: [Date?]?
        
        var labelledDatedValues: Labelled_DatedValues?
        
        guard let sectionStart = html.range(of: sectionHeader) else {
            return nil
        }
        
        guard let sectionEnd = html.range(of: sectionEnd, range: sectionStart.upperBound..<html.endIndex) else {
            return nil
        }
        
        let dateRowStart = html.range(of: topRowStartSeq, range: sectionStart.upperBound..<sectionEnd.lowerBound)
        var dateRowEnd: Range<String.Index>?
        
        // extract years data from tabel top row
        if dateRowStart != nil {
            dateRowEnd = html.range(of: topRowEndSeq, range: dateRowStart!.upperBound..<html.endIndex)
            
            if dateRowEnd != nil {
                let topRow$ = String(html[dateRowStart!.upperBound..<dateRowEnd!.lowerBound])
                let values$ = topRow$.components(separatedBy: topRowValueStartSeq)

                dates = [Date?]()
                let calendar = Calendar.current
                let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]
                var dateComponents = calendar.dateComponents(components, from: Date())
                dateComponents.second = 59
                dateComponents.minute = 59
                dateComponents.hour = 23
                dateComponents.day = 31
                dateComponents.month = 12

                for value$ in values$ {
                    
                    let data = Data(value$.utf8)
                    if let content$ = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil).string {
                        let value = content$.filter("0123456789".contains)
                        
                        if let yearValue = Int(value) {
                            if yearValue > 2000 && yearValue < 2030 {
                                dateComponents.year = yearValue
                                dates?.append(calendar.date(from: dateComponents))
                            }
                            else {
                                ErrorController.addInternalError(errorLocation: #function, errorInfo: "year date extraction error from Tagesschau data: \(value)")
                            }
                        }
                    }
                }

            }
        }

        guard let rowStart = html.range(of: rowTitle, range: (dateRowStart ?? sectionStart).upperBound..<html.endIndex) else {
            return nil
        }
        
        guard let rowEnd = html.range(of: rowEndSeq, range: rowStart.upperBound..<html.endIndex) else {
            return nil
        }

        // extract number values
        let rowText = String(html[rowStart.upperBound..<rowEnd.lowerBound])
        let values$ = rowText.components(separatedBy: columnEndSeq)
        for value$ in values$.filter({ v$ in
            if v$ == "" { return false }
            else { return true }
        }) {
 
            var column$ = value$.filter("-0123456789,%".contains)
            column$ = column$.replacingOccurrences(of: ",", with: ".")
 
            if column$ == "-" {
                values.append(0.0)
                continue
            }
            
            if !(column$.last == "%") {
                if !rowTitle.contains("je Aktie") {
                    column$ += "M"
                }
            }
            if let value = column$.textToNumber() {
                values.append(value)
            }
//            print("value found \(values.last)")
        }

        let data = Data(rowTitle.utf8)
        let label = (try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil).string) ?? "Missing row label"
        
        
        if let validDates = dates?.compactMap({ $0 }) {
            
            if validDates.count == values.count {
                var datedValues = [DatedValue]()
                for i in 0..<validDates.count {
                    datedValues.append(DatedValue(date: validDates[i], value: values[i]))
                }
                labelledDatedValues = Labelled_DatedValues(label: label, datedValues: datedValues)
            } else {
//                print("mismatch between years \(validDates) and values counts \(values)")
                var datedValues = [DatedValue]()
                for i in 0..<values.count {
                    datedValues.append(DatedValue(date: Date(), value: values[i]))
                    labelledDatedValues = Labelled_DatedValues(label: label, datedValues: datedValues)
                }
            }
        } else {
            // no year numbers found, use currnt date
            var datedValues = [DatedValue]()
            for i in 0..<values.count {
                datedValues.append(DatedValue(date: Date(), value: values[i]))
                labelledDatedValues = Labelled_DatedValues(label: label, datedValues: datedValues)
            }
         labelledDatedValues = Labelled_DatedValues(label: label, datedValues: datedValues)
//            print("no years found; ldv set at \(labelledDatedValues)")
        }

//        print()
//        print("TS R1 data for \(rowTitle):")
//        for ldv in  labelledDatedValues?.datedValues ?? [] {
//            print(ldv)
//        }
        
        return labelledDatedValues
        
    }
    
    class func extractStringFromPage(html: String, searchTerm: String) throws -> String? {
        
//        let rowStart = "<tr>"
        let valueEnd = "</span>"
        
        guard let termStart = html.range(of: searchTerm) else {
            throw InternalErrorType.htmlRowStartIndexNotFound
        }
        
        guard let termEnd = html.range(of: valueEnd, range: termStart.upperBound..<html.endIndex) else {
            throw InternalErrorType.contentEndSequenceNotFound
        }
        
        let target$ = String(html[termStart.upperBound..<termEnd.lowerBound])
        return target$.replacingOccurrences(of: " ", with: "")

    }
    
    class func translateGermanLabelledValuesForR1(labelledDatedValues: Labelled_DatedValues) -> Labelled_DatedValues {
        
        let label = labelledDatedValues.label
        
        var newLabel: String?
        
//        case "Eigenkapitalrendite":
//            print("Eigenkapitalrendite downloaded for single ROI value for WBValuation - currently unused")
        if label ==  "Umsatz" {
            newLabel = "Revenue"
        } else if label == "Gewinn je Aktie" {
            newLabel = "EPS - Earnings Per Share"
        }
//        case "Operatives Ergebnis":
//            print("Operatives Ergebnis downloaded for operatingIncome value for WBValuation - currently unused")
        else if label == "Buchwert je Aktie" {
            newLabel = "Book Value Per Share"
        }
//        else if label == "Wertminderung" {
//            newLabel = "Wertminderung" // user together with 'Summe Anlagevermögen' YoY for capEx calculation
//        }
        else if label == "Ergebnis vor Steuer:"{
            newLabel = "Net income"
        }
//        case "hnliche Aufwendungen":
//            // complete title 'Zinsen und ähnliche Aufwendungen'
//            print("'Zinsen und ähnliche Aufwendungen' downloaded for interestExpense value for WBValuation - currently unused")
//        case "Personalaufwand":
//            newLabel = "SGA1" // calculate total SGA for WBvaluation
        else if label == "Verwaltungsaufwand" {
            newLabel = "SGA2"  // calculate total SGA for WBvaluation
        }
        else if label == "Sonstige betriebliche Aufwendungen" {
            newLabel = "SGA3" // calculate total SGA for WBvaluation
        }
        else if label == "Herstellungskosten" {
            newLabel = "SGA1" // calculate total SGA for WBvaluation
        }

//        case "nderung der Finanzmittel":
//            // full title is 'Veränderung der Finanzmittel'
//            newLabel = "Operating cash flow"
//            modifiedValues = labelledValues!.values.compactMap{ $0 * 1_000_000 }
//        case "Eigene Aktien":
//            // convert from negative, then use YoY change for ret. earnings/ eqRepurchased for WBV'
//            print("'Eigene Aktien' downloaded for eqRepurchased value for WBValuation - currently unused")
        else if label.contains("Summe Anlageverm") {
            // Summe Anlagevermögen (YoY change) + Wertminderung = cepEx
            newLabel = "Summe Anlageverm"
        }
        else if label == "Summe langfristiges Fremdkapital" {
            newLabel = "Long Term Debt"
        }
        else if label.contains("Ausstehende Aktien in Mio.") {
            newLabel = "Shares outstanding"
        }
        else if label == "Aktuell ausstehende Aktien" {
            newLabel = "Current Shares outstanding"
        }
        else if label.contains("Forschung") { // not used for R1 but saved for others
            newLabel = "rdExpense"
        }
        else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "unexpected label downloaded from Tagesschau  website for \(label)")
        }
        
        if let valid = newLabel {
            return Labelled_DatedValues(label: valid, datedValues: labelledDatedValues.datedValues)
        } else {
            return labelledDatedValues
        }
    }

    class func shareAddressLineTagesschau(htmlText: String) throws -> [String]? {
        
        let sectionStartSequence = "desktopSearchResult"
        let sectionEndSequence = "Die Daten werden von der Infront Financial Technology GmbH bereitgestellt"
        let addressStartSequence = "document.location="
        let addressEndSequence = "';"
        
        var addresses = Set<String>()
        
        guard let sectionStart = htmlText.range(of: sectionStartSequence) else {
            throw InternalErrorType.contentStartSequenceNotFound
        }
        
        guard let sectionEnd = htmlText.range(of: sectionEndSequence) else {
            throw InternalErrorType.contentStartSequenceNotFound
        }
        
        let croppedHtml = String(htmlText[sectionStart.upperBound..<sectionEnd.lowerBound])
        
        guard let startPosition = croppedHtml.range(of: addressStartSequence) else {
            throw InternalErrorType.contentStartSequenceNotFound
        }
        
        guard let endPosition = croppedHtml.range(of: addressEndSequence, range: startPosition.upperBound..<croppedHtml.endIndex) else {
            throw InternalErrorType.contentEndSequenceNotFound
        }

        let address$ = String(croppedHtml[startPosition.upperBound..<endPosition.lowerBound])
        let address = address$.replacingOccurrences(of: "\'", with: "")
        addresses.insert(address)
        
        var nextEndPosition: Range<String.Index>?
        var nextStartPosition = croppedHtml.range(of: addressStartSequence,range: endPosition.upperBound..<croppedHtml.endIndex)
        if nextStartPosition != nil {
            nextEndPosition = croppedHtml.range(of: addressEndSequence,range: nextStartPosition!.upperBound..<croppedHtml.endIndex)
        }
        
        while nextEndPosition != nil {
            let address$ = String(croppedHtml[nextStartPosition!.upperBound..<nextEndPosition!.lowerBound])
            let address = address$.replacingOccurrences(of: "\'", with: "")
            addresses.insert(address)
            
            nextStartPosition = croppedHtml.range(of: addressStartSequence,range: nextEndPosition!.upperBound..<croppedHtml.endIndex)
            if nextStartPosition != nil {
                nextEndPosition = croppedHtml.range(of: addressEndSequence, range: nextStartPosition!.upperBound..<croppedHtml.endIndex)
            } else {
                nextEndPosition = nil
            }
        }
        
//        print("TS Addressen found: \(addresses)")
        
        return Array(addresses)
        
    }
        
    


}
