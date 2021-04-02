//
//  ResearchTVC.swift
//  Bulls'N'Bears
//
//  Created by aDav on 29/03/2021.
//

import UIKit

class ResearchTVC: UITableViewController {
        
    var share: Share?
    var research: StockResearch?
    var sectionTitles: [String]?
    var controller: ResearchController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "ResearchCell", bundle: nil), forCellReuseIdentifier: "researchCell")
        
        let controller =  ResearchController(share: share)
        if let titles = controller.titleDictionary {
            sectionTitles = Array(titles.values)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

        return sectionTitles?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if sectionTitles?[section] ?? "" == "news" {
            return research?.news?.count ?? 0
        } else {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "researchCell", for: indexPath) as! ResearchCell

        let parameter = controller?.parameter(title: sectionTitles?[indexPath.section] ?? "") ?? "missing"
        cell.configure(delegate: self, parameter: parameter)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles?[section] ?? ""
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

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

extension ResearchTVC: ResearchCellDelegate {
    
    func userEnteredNotes(notes: String, parameter: String) {
        
        for sectionTitle in sectionTitles ?? [] {
            if sectionTitle == parameter {
                research?.userEnteredText(text: notes, parameter: parameter)
            }
        }
    }
    
    
}
