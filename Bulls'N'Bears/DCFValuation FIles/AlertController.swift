//
//  AlertController.swift
//  Bulls'N'Bears
//
//  Created by aDav on 15/01/2021.
//

import UIKit
import UserNotificationsUI
import UserNotifications

class AlertController: NSObject {
    
    var alertViewOpen = false
    
    public func showDialog(title: String, alertMessage: String) {
        
        DispatchQueue.main.async {
            
            guard let presentingVC = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first?.rootViewController?.children.first else {
                return
            }
            
            if self.alertViewOpen {
                ErrorController.addErrorLog(errorLocation: "AlertController.showDialog can't show alert as another alert is displayed", systemError: nil, errorInfo: "alert: \(alertMessage)")
                return
            } else {
                self.alertViewOpen = true
            }
            
            let alertController = UIAlertController(title: title, message: alertMessage, preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) -> Void in
                self.alertViewOpen = false
            }))
            
            // in case the alert is called from a popover presentation controller
            if presentingVC.popoverPresentationController != nil {
                let rect = presentingVC.view.frame.insetBy(dx: presentingVC.view.frame.width / 4, dy: presentingVC.view.frame.height / 4)
                    alertController.popoverPresentationController?.sourceRect = rect
            }
            
            presentingVC.present(alertController, animated: true, completion: nil)

        }
    }

}
