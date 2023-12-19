//
//  ValueListTVC.swift
//  Bulls'N'Bears
//
//  Created by aDav on 16/02/2021.
//

import UIKit

class ValueListTVC: UITableViewController {

    var values: [[Double]?]?
    var datedValues: [[DatedValue]]? // are in time-ASCENDING order
    var higherGrowthIsBetter = true
    var sectionTitles = ["Your Rating (keep tapping the stars)"]
    var rowTitles = [String]()
    var formatter: NumberFormatter!
    var controller: WBValuationController!
    var correlationToDisplay: Double?
    var trendToDisplay: Double?
    var mostRecentYear: Int!
    var proportions: [Double]?
    var proportionsDV: [DatedValue]?
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
        

        if proportionsDV == nil { // may already have been set in prepare func in WBV TVC
            
            if datedValues?.count ?? 0 == 1 {
                proportionsDV = datedValues?[0].growthRates(dateOrder: .ascending)// Calculator.ratesOfGrowthWithDate(datedValues: datedValues![0])
            }
            else if datedValues?.count ?? 0 == 2 {
                proportionsDV = datedValues.proportions()
            }
        }
   }
        
    override func viewDidDisappear(_ animated: Bool) {
                 
        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshWBValuationTVCRow"), object: indexPath, userInfo: nil)
    }
           
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count// + 1 //+ 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 { return 1 }
        else { return 2 }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "valueListRatingCell", for: indexPath) as! ValueListRatingCell
            let parameter = sectionTitles[1] // [2] ! careful. This assumes the first two sectionsTitles are '["Your Rating (keep tapping the stars)","Newest available data from"]' to which the parameter and more are appended in WBValuationController prepareForSegue()
            let userEvaluation = controller.returnUserEvaluation(for: parameter)
            cell.configure(rating: userEvaluation?.userRating(), ratingUpdateDelegate: controller, parameter: userEvaluation?.wbvParameter ?? "missing", reverseRatingOrder: !higherGrowthIsBetter)
            return cell
        }
//        else if indexPath.section == 1 {
//            let cell = tableView.dequeueReusableCell(withIdentifier: "valueListTextEntryCell", for: indexPath) as! ValueListTextEntryCell
//            let parameter = sectionTitles[2] // ! careful. This assumes the first two sectionsTitles are '["Your Rating (keep tapping the stars)","Newest available data from"]' to which the parameter and more are appended in WBValuationController prepareForSegue()
//            let userEvaluation = controller.returnUserEvaluation(for: parameter)
//            let text = controller.latestDataDate() != nil ? dateFormatter.string(from: controller.latestDataDate()!) : "NA"
//
//            cell.configure(text: text, delegate: controller, wbvParameter: userEvaluation?.wbvParameter ?? "missing")
//
//            return cell
//        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "valueListCell2", for: indexPath) as! ValueListCell
                        
            if indexPath.row == 0 {
                // chart of values
//                let barChartValues = (values?.count ?? 0 > 1) ? proportions : values?[indexPath.section-2]
//                let valuesAreProportions = (values?.count ?? 0 > 1)
                
                //NEW
                let barChartDVs = (datedValues?.count ?? 0 > 1) ? proportionsDV : datedValues?[indexPath.section-1] // -2
                let dvsAreProportions = (datedValues?.count ?? 0 > 1)
                
//                cell.configure(values: barChartValues, biggerIsBetter: higherGrowthIsBetter ,rightTitle: cellLegendTitles.first, valuesAreGrowth: false, valuesAreProportions: dvsAreProportions, latestDataDate: controller.latestDataDate(),altLatestDate: controller.valuationDate())
                
                cell.configureForDV(values: barChartDVs, biggerIsBetter: higherGrowthIsBetter, rightTitle: cellLegendTitles.first, valuesAreGrowth: false, valuesAreProportions: dvsAreProportions)
            }
            else if indexPath.row == 1 {
                // chart of growth
//                let trendLineChartValues = (values?.count ?? 0 > 1) ? Calculator.growthRatesYoY(values: proportions) : proportions // Calculator.compoundGrowthRates(values: proportions)
                let rowtitle = "Growth rate of " + cellLegendTitles.first!
                
    //                let trendLineDVs = (datedValues?.count ?? 0 > 1) ? Calculator.ratesOfGrowthWithDate(datedValues: (proportionsDV ?? [DatedValue]())) : proportionsDV
                let trendLineDVs = proportionsDV
                
//                cell.configure(values: trendLineChartValues, biggerIsBetter: higherGrowthIsBetter ,rightTitle: rowtitle, valuesAreGrowth: true, latestDataDate: controller.latestDataDate(), altLatestDate: controller.valuationDate())
                
                cell.configureForDV(values: trendLineDVs ,biggerIsBetter: higherGrowthIsBetter, rightTitle: rowtitle, valuesAreGrowth: true)
            }
            
            return cell
        }
        
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 { return 100 }
//        else if indexPath.section == 1 { return 50 }
        else { return 200 }
    }

}

