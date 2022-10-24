//
//  ErrorListVC.swift
//  Bulls'N'Bears
//
//  Created by aDav on 11/01/2021.
//

import UIKit

class ErrorListVC: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "ErrorLogListCell", bundle: nil), forCellReuseIdentifier: "errorLogListCell")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return errorLog?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "errorLogListCell", for: indexPath) as! ErrorLogListCell

        if errorLog?.count ?? 0 > indexPath.row {
            let log = errorLog![indexPath.row]
            cell.locationLabel.text = log.location
            cell.infoLabel.text = log.errorDescription()
            cell.sysErrLabel.text = log.systemError?.localizedDescription
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

}
