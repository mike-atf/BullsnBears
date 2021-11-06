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

class ErrorController {
    
    static func addErrorLog(errorLocation: String, systemError: Error? = nil, errorInfo: String? = nil) {
        
        if errorLog == nil {
            errorLog = [ErrorLog]()
        }
        
        let newError = ErrorLog.init(location: errorLocation, systemMessage: systemError, errorInfo: errorInfo ?? "no info")
        errorLog?.append(newError)
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "NewErrorLogged"), object: nil, userInfo: nil)
    }
    

}
