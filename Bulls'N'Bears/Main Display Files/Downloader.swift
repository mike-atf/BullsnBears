//
//  Downloader.swift
//  Bulls'N'Bears
//
//  Created by aDav on 04/11/2021.
//

import Foundation

class Downloader {
    
    class func downloadData(url: URL) async throws -> String {
        
        let request = URLRequest(url: url)
            
        let (data,urlResponse) = try await URLSession.shared.data(for: request)
        var htmlText = String()
        
        if let response = urlResponse as? HTTPURLResponse {
            if response.statusCode == 200 {
                if response.mimeType == "text/html" {
                    htmlText = String(data: data, encoding: .utf8) ?? ""
                }
                else {
                    throw DownloadAndAnalysisError.mimeType
                }
            }
            else {
                print("url error, code \(response.statusCode)")
                throw DownloadAndAnalysisError.urlError
            }
        }
        
        return htmlText
    }

}
