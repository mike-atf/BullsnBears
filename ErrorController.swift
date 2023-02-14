//
//  ErrorController.swift
//  Bulls'N'Bears
//
//  Created by aDav on 09/01/2021.
//

import Foundation
import UserNotifications

protocol ErrorControllerDelegate {
    func activateErrorButton()
    func deactivateErrorButton()
}

struct InternalError: Error {
        
    var location = String()
    var systemError: Error?
    var errorInfo = String()
    var errorType: InternalErrorType?
    
    init(location: String = String(), systemError: Error? = nil, errorInfo: String = String(), errorType: InternalErrorType? = nil) {
        self.location = location
        self.systemError = systemError
        self.errorInfo = errorInfo
        self.errorType = errorType
    }
    
    func errorDescription() -> String {
        
        var description = String()
        
        if let downloadError = systemError as? InternalErrorType {
            switch downloadError {
            case .mimeType:
                description = "mime type error"
            case .downloadedFileURLinvalid:
                description = "invalid file url (\(errorInfo))"
            case .emptyWebpageText:
                description = "empty webpage text received"
            case .htmlTableTitleNotFound:
                description = "title of table \(errorInfo) not found"
            case .htmlTableTextNotExtracted:
                description = "no text extracted from table (\(errorInfo))"
            case .fileFormatNotCSV:
                description = "downloaded file is not .csv (\(errorInfo))"
            case .urlError:
                description = "invalid file url (\(errorInfo))"
            default:
                description = systemError?.localizedDescription ?? "no description"

            }
        }
        
        return description

    }
}


class ErrorController {
    
    static func addInternalError(errorLocation: String, systemError: Error? = nil, errorInfo: String? = nil, type: InternalErrorType?=nil) {
        
        if errorLog == nil {
            errorLog = [InternalError]()
        }
        
        let newError = InternalError(location: errorLocation, systemError: systemError, errorInfo: errorInfo ?? "no info")
        errorLog?.append(newError)
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "NewErrorLogged"), object: nil, userInfo: nil)
        
        print()
        print("=================================")
        print("ERROR in \(errorLocation): \(errorInfo ?? ""), description: \(systemError?.localizedDescription ?? "")")
        print("=================================")
        print()
    }
    

}

enum InternalErrorType: Error {
    case missingPricePointsInShareCreation
    case noValidBackgroundMOC
    case noShareFetched
    case urlPathError
    case mocReadError
    case mimeType
    case urlError
    case emptyWebpageText
    case htmlTableTitleNotFound
    case htmlTableEndNotFound
    case htmTablelHeaderStartNotFound
    case htmlTableHeaderEndNotFound
    case htmlTableRowEndNotFound
    case htmlTableRowStartIndexNotFound
    case htmlTableBodyStartIndexNotFound
    case htmlTableBodyEndIndexNotFound
    case htmlTableSequenceStartNotFound
    case urlInvalid
    case shareSymbolMissing
    case shareShortNameMissing
    case shareWBValuationMissing
    case noBackgroundShareWithSymbol
    case htmlSectionTitleNotFound
    case htmlRowStartIndexNotFound
    case htmlRowEndIndexNotFound
    case contentStartSequenceNotFound
    case contentEndSequenceNotFound
    case noBackgroundMOC
    case htmlTableTextNotExtracted
    case fileFormatNotCSV
    case couldNotFindCompanyProfileData
    case generalDownloadError
    case statusCodeError
    case downloadedFileURLinvalid
}

enum RunTimeError: Error {
    case specificError(description: String)
}


