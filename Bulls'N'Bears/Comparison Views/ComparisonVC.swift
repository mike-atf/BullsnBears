//
//  ComparisonVC.swift
//  Bulls'N'Bears
//
//  Created by aDav on 28/04/2021.
//

import UIKit

class ComparisonVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    

    @IBOutlet var horizontalScrollView: UIScrollView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var toolBarView: UIView!
    
    
    var controller: ComparisonController!
    var shares: [Share]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        controller = ComparisonController(shares: shares, viewController: self)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return controller.rowTitles().count
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        controller.rowTitles()[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "comparisonCell", for: indexPath) as! ComparisonCell
        
        cell.configure(controller: controller, cellPath: indexPath)
        
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        controller.titleForSection(section: section)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath == IndexPath(row: 1, section: 0) { return 200 }
        else { return 44 }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
