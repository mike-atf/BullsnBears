//
//  ValueListTVC.swift
//  Bulls'N'Bears
//
//  Created by aDav on 16/02/2021.
//

import UIKit

class ValueListTVC: UITableViewController {

    var values: [[Double]?]?
    var higherGrowthIsBetter = true
    var sectionTitles = ["Your Rating (keep tapping the stars)","Your evaluation notes"]
    var rowTitles = [String]()
    var formatter: NumberFormatter!
    var controller: WBValuationController!
    var correlationToDisplay: Double?
    var trendToDisplay: Double?
    var mostRecentYear: Int!
    var proportions: [Double]?
    var gapErrors: [String]?
    var cellLegendTitles = [String]()
    var indexPath: IndexPath!
    
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
        
       proportions = controller.valueListTVCProportions(values: values)
   }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        if let textcell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? ValueListTextEntryCell {
            let parameter = textcell.wbvParameter ?? ""
            controller.userEnteredNotes(notes: textcell.textView.text, parameter: parameter)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
                 
        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshWBValuationTVCRow"), object: indexPath, userInfo: nil)
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
            let parameter = sectionTitles[2] // ! careful. This assumes the first two sectionsTitles are '["Your Rating (keep tapping the stars)","Your evaluation notes"]' to which the parameter and more are appended in WBValuationController prepareForSegue()
            let userEvaluation = controller.returnUserEvaluation(for: parameter)
            cell.configure(rating: userEvaluation?.userRating(), ratingUpdateDelegate: controller, parameter: userEvaluation?.wbvParameter ?? "missing", reverseRatingOrder: !higherGrowthIsBetter)
            return cell
        }
        else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "valueListTextEntryCell", for: indexPath) as! ValueListTextEntryCell
            let parameter = sectionTitles[2] // ! careful. This assumes the first two sectionsTitles are '["Your Rating (keep tapping the stars)","Your evaluation notes"]' to which the parameter and more are appended in WBValuationController prepareForSegue()
            let userEvaluation = controller.returnUserEvaluation(for: parameter)
            var text: String?
            if let comment = userEvaluation?.comment {
                text = comment + " (" + dateFormatter.string(from: userEvaluation?.date ?? Date()) + ")"
            }
            
            cell.configure(text: text, delegate: controller, wbvParameter: userEvaluation?.wbvParameter ?? "missing")
            
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
        if indexPath.section == 0 { return 100 }
        else if indexPath.section == 1 { return 120 }
        else { return 300 }
    }

}
