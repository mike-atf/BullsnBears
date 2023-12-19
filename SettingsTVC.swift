//
//  SettingsTVC.swift
//  Bulls'N'Bears
//
//  Created by aDav on 28/11/2021.
//

import UIKit
import UniformTypeIdentifiers

class SettingsTVC: UITableViewController {
    
    var settingsSectionTitles: [String]!
    var settingsRowTitles: [[String]]!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        tableView.register(UINib(nibName: "SettingsCell", bundle: nil), forCellReuseIdentifier: "settingsCell")
        
        settingsSectionTitles = ["Version","Internal settings","Backup", "Import"]
        settingsRowTitles = [["Build no."],["Rating score weighing factors"],["Export archive"],["Import archive"]]

    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

        return settingsSectionTitles.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return settingsRowTitles[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath) as! SettingsCell

        let title = settingsRowTitles[indexPath.section][indexPath.row]
        var detail: String?
        var accessory = true
        if indexPath.section == 0 {
            detail = appBuild
            accessory = false
        }
        
        cell.configure(title: title, detail: detail,accessory: accessory, path: indexPath)


        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            performSegue(withIdentifier: "ratingFactorsSegue", sender: nil)
        } else if indexPath.section == 2 {
            tableView.deselectRow(at: indexPath, animated: true)
            exportBackup()
        }
        else if indexPath.section == 3 {
            tableView.deselectRow(at: indexPath, animated: true)
            openImportView()
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }

    func exportBackup() {
        
        Task {
            if let backupURL = await BackupManager.backupData() {
                
                DispatchQueue.main.async {
                    let exportView = UIActivityViewController(activityItems: [backupURL], applicationActivities: nil)
                    exportView.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
                        
                        self.dismiss(animated: true)
                    }

                    let popUpController = exportView.popoverPresentationController
                    popUpController?.sourceView = self.view
                    
                    self.present(exportView, animated: true)

                }
            }
            else {
                print("backup not completed")
            }
        }
    }
    
    func openImportView() {
        
        let archive = UTType(exportedAs: "co.uk.apptoolfactory.bullsnbears.document.bbf", conformingTo: .data)
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [archive], asCopy: true)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .automatic
        
        self.present(documentPicker, animated: true)
    }

}


extension SettingsTVC: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {

        let _ = ImportManager(fileURL: urls.first!)
        self.dismiss(animated: true)
    }
    
}
