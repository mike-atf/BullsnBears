//
//  ValuationErrorsTVC.swift
//  Bulls'N'Bears
//
//  Created by aDav on 13/02/2021.
//

import UIKit

class ValuationErrorsTVC: UITableViewController {

    var errors = [String]()
    var sectionHeaderTexts: [String]?
    var firstCellHeight: CGFloat?
    var otherCellHeight: CGFloat?
    var otherCellsFontSize: CGFloat = 15

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.estimatedRowHeight = 70.0
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return errors.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "valuationErrorListCell", for: indexPath)

        if (firstCellHeight != nil) && indexPath.row == 0 {
            if let label = cell.viewWithTag(10) as? UILabel {
                label.numberOfLines = 0
                label.text = errors[indexPath.row]
                
                if let label = cell.viewWithTag(20) as? UILabel {
                    label.numberOfLines = 0
                    label.text = ""
                }

                return cell
            }
        }
        else {
        
            let details = errors[indexPath.row].split(separator: ":")
            
            if let label = cell.viewWithTag(10) as? UILabel {
                label.numberOfLines = 0
//                label.font = UIFont.systemFont(ofSize: otherCellsFontSize)
                label.text = String(details.first ?? "")
            }
            if details.count > 1 {
                if let label = cell.viewWithTag(20) as? UILabel {
                    label.numberOfLines = 0
//                    label.font = UIFont.systemFont(ofSize: otherCellsFontSize)
                    label.text = String(details.last ?? "")
                }
            }
            else {
                if let label = cell.viewWithTag(20) as? UILabel {
                    label.numberOfLines = 0
//                    label.font = UIFont.systemFont(ofSize: otherCellsFontSize)
                    label.text = ""
                }
            }
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard let validHeaders = sectionHeaderTexts else { return nil }
        guard validHeaders.count > section else { return nil }
        
        let header = UIView()
        let height: CGFloat = 40
        header.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: height)
        
        let largeFontSize: CGFloat = (UIDevice().userInterfaceIdiom == .pad) ? 18 : 18
        
        let titleLabel: UILabel = {
            let label = UILabel()
            let fontSize = largeFontSize
            label.font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
            label.textAlignment = .left
            label.textColor = UIColor.systemOrange
            label.text = validHeaders[section]
            label.numberOfLines = 0
            return label
        }()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
                
        header.addSubview(titleLabel)

        let margins = header.layoutMarginsGuide
        
        titleLabel.topAnchor.constraint(equalTo: margins.topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(greaterThanOrEqualTo: margins.trailingAnchor).isActive = true
        
        return header
    }


//    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        if let height = firstCellHeight {
//            if indexPath.row == 0 {
//                return height
//            }
//            else { return otherCellHeight ?? 50 }
//        }
//        else { return otherCellHeight ?? 50 }
//    }
//    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        return "There were problems with the calculation"
//    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
