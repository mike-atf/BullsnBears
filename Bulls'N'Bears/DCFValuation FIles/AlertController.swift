//
//  AlertController.swift
//  Bulls'N'Bears
//
//  Created by aDav on 15/01/2021.
//

import UIKit
import UserNotificationsUI
import UserNotifications

protocol AlertViewDelegate {
    func alertWasDismissed()
}

class AlertController: NSObject {
    
    var alertViewOpen = false
    var delegate: AlertViewDelegate?
    
    class func shared() -> AlertController {
        return alertController
    }

    
    public func showDialog(title: String, alertMessage: String, viewController: UIViewController? = nil, delegate: AlertViewDelegate? = nil) {
        
        self.delegate = delegate
        
        DispatchQueue.main.async {
            
            let windowScene = (UIApplication.shared.connectedScenes.first as? UIWindowScene)
            let sceneDelegate = windowScene?.delegate as? SceneDelegate
            let presentingVC = viewController ?? sceneDelegate?.window?.rootViewController
//
//            let presentingVC = viewController ?? UIApplication.shared.windows.filter({ $0.isKeyWindow }).first?.rootViewController?.children.first
            
            guard presentingVC != nil else {
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
                self.delegate?.alertWasDismissed()
                self.delegate = nil
            }))
            
            // in case the alert is called from a popover presentation controller
            if presentingVC?.popoverPresentationController != nil {
                let rect = presentingVC!.view.frame.insetBy(dx: presentingVC!.view.frame.width / 4, dy: presentingVC!.view.frame.height / 4)
                    alertController.popoverPresentationController?.sourceRect = rect
            }
            else if let nav = presentingVC as? UINavigationController {
                nav.pushViewController(alertController, animated: true)
                return
            }
            
            presentingVC?.present(alertController, animated: true, completion: nil)

        }
    }

}
