//
//  ValueListTVC.swift
//  Bulls'N'Bears
//
//  Created by aDav on 16/02/2021.
//

import UIKit

class ValueListTVC: UITableViewController {

    var values: [[Double]?]?
    var sectionTitles = ["Rating","Evaluation notes"]
    var rowTitles = [String]()
    var formatter: NumberFormatter!
    weak var controller: WBValuationController!
    var correlationToDisplay: Double?
    var trendToDisplay: Double?
    var mostRecentYear: Int!
    var proportions: [Double]?
    var userEvaluation: UserEvaluation?
    var gapErrors: [String]?
    var cellLegendTitles = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "ValueListCell", bundle: nil), forCellReuseIdentifier: "valueListCell2")
        tableView.register(UINib(nibName: "ValueListRatingCell", bundle: nil), forCellReuseIdentifier: "valueListRatingCell")
        tableView.register(UINib(nibName: "ValueListTextEntryCell", bundle: nil), forCellReuseIdentifier: "valueListTextEntryCell")

        let components: Set<Calendar.Component> = [.year]
        let dateComponents = Calendar.current.dateComponents(components, from: Date())
        mostRecentYear = dateComponents.year! - 1
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if values?.count ?? 0 > 1 {
            proportions = Calculator.proportions(array1: values?.first!, array0: values?.last!)
        }
        else {
            if let array1 = values!.first {
                proportions = array1?.growthRates()
            }
        }
    }
        
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return (values?.count ?? 0) + 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
            return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "valueListRatingCell", for: indexPath) as! ValueListRatingCell
            cell.configure(rating: 0, ratingUpdateDelegate: controller, parameter: userEvaluation?.wbvParameter ?? "missing")
            return cell
        }
        else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "valueListTextEntryCell", for: indexPath) as! ValueListTextEntryCell

            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "valueListCell2", for: indexPath) as! ValueListCell
            if indexPath.section == 2 {

                cell.configure(values1: values?[indexPath.section-2], values2: proportions, rightTitle: cellLegendTitles[1], leftTitle: cellLegendTitles.first)
            }
            else {
                cell.configure(values1: values?[indexPath.section-2], values2: nil, rightTitle: sectionTitles.last, leftTitle: nil)
            }
            
            return cell
        }
        
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 { return 70 }
        else if indexPath.section == 1 { return 100 }
        else { return 300 }
    }

}
