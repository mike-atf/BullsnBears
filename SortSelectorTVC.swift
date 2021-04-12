//
//  SortSelectorTVC.swift
//  Bulls'N'Bears
//
//  Created by aDav on 12/04/2021.
//

import UIKit

class SortSelectorTVC: UITableViewController {


    override func viewDidLoad() {
        super.viewDidLoad()

    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return sharesListSortParameter.options().count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "sortTVCCell", for: indexPath)

        if let title = cell.contentView.viewWithTag(10) as? UILabel {
            title.text = sharesListSortParameter.options()[indexPath.row]
            if title.text == (UserDefaults.standard.value(forKey: userDefaultTerms.sortParameter) as! String) {
                cell.accessoryType = .checkmark
            }
            else {
                cell.accessoryType = .none
            }
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        UserDefaults.standard.set(sharesListSortParameter.options()[indexPath.row], forKey: userDefaultTerms.sortParameter)
        tableView.reloadData()
//        self.dismiss(animated: true, completion: nil)
        
    }

}
