//
//  ImportManager.swift
//  Bulls'N'Bears
//
//  Created by aDev on 14/12/2023.
//

import Foundation
import UIKit

class ImportManager {
        
    init(fileURL: URL) {
        
        let windowScene = (UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let sceneDelegate = windowScene?.delegate as? SceneDelegate
        let presentingVC = sceneDelegate?.window?.rootViewController
        
        guard presentingVC != nil else {
            AlertController.shared().showDialog(title: "Import attempt failed", alertMessage: "there is no visible view to present the import dialog")
            return
        }

        let importDialog = UIAlertController(title: "Import archive", message: "Warning: will replace any existing data. A safety backup will be made before the replacement", preferredStyle: .actionSheet)
        
        importDialog.addAction(UIAlertAction(title: "Proceed", style: .destructive, handler: { (_) -> Void in
            Task {
                await self.installBackupData(fileURL: fileURL)
            }
        }))
        
        importDialog.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (_) -> Void in
            return
        }))
        
        let popUpController = importDialog.popoverPresentationController
        popUpController!.permittedArrowDirections = .unknown

        let rect = presentingVC!.view.frame.insetBy(dx: presentingVC!.view.frame.width / 2, dy: presentingVC!.view.frame.height / 2)
        importDialog.popoverPresentationController?.sourceRect = rect
        importDialog.popoverPresentationController?.sourceView = presentingVC!.view

        presentingVC!.present(importDialog, animated: true)

    }
    
    // MARK: - File import
    
    private func installBackupData(fileURL: URL) async {
        
        print("restore from backup...")
        var safetyBackup: URL?
        do {
            //1. create local backup
            safetyBackup = await BackupManager.backupData()
            
            //2. delete current data
            try await BackupManager.deleteAllData()
            
            //3. restore data
            try await BackupManager.restoreData(fromURL: fileURL)
            DispatchQueue.main.async {
                AlertController.shared().showDialog(title: "Restore from imported archive completed successfully", alertMessage: "")
            }
            return
        } catch {
            DispatchQueue.main.async {
                AlertController.shared().showDialog(title: "Re-installing data from imported Archive failed", alertMessage: "\(error.localizedDescription)\nWill tryto regenerate original data from safety backup")
            }
        }
        
        do {
            try await BackupManager.restoreData(fromURL: safetyBackup)
        } catch {
            print("+++++++++++++++")
            print("Restore from safety backup failed \(error.localizedDescription)")
            DispatchQueue.main.async {
                AlertController.shared().showDialog(title: "Restore from safety backup failed", alertMessage: "\(error.localizedDescription)")
            }

        }

        
    }

}
