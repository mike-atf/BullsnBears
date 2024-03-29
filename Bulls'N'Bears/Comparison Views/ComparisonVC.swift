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
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var shareNamesView: UIView!
    
    
    var controller: ComparisonController!
    var shares: [Share]?
    var shareNameLabels: [UILabel]?
    var popOverControllers:[TBYChartViewController]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        controller = ComparisonController(shares: shares, viewController: self)
        
        let margins = shareNamesView.safeAreaLayoutGuide
        var previousLabel: UILabel?
        var count: CGFloat = 0.0
        for share in shares ?? [] {
            let label: UILabel = {
                let label = UILabel()
                label.translatesAutoresizingMaskIntoConstraints = false
                label.font = UIFont.preferredFont(forTextStyle: .title3)
                label.text = share.symbol
                label.sizeToFit()
                return label
            }()
            shareNamesView.addSubview(label)
            shareNameLabels?.append(label)
            
            label.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 480 + 150*count).isActive = true
            label.centerYAnchor.constraint(equalTo: margins.centerYAnchor).isActive = true
            if previousLabel != nil {
                previousLabel?.trailingAnchor.constraint(equalTo: label.leadingAnchor, constant: 10).isActive = true
            }
            previousLabel = label
            count += 1.0
        }
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
        if indexPath == IndexPath(row: 0, section: 0) { return 200 }
        else { return 90 }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: false)
        
        if indexPath.section > 2 {
            let cell = tableView.cellForRow(at: indexPath) as! ComparisonCell
            
            cell.cellShowsCharts.toggle()
            cell.configure(controller: controller, cellPath: indexPath)
        }
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
