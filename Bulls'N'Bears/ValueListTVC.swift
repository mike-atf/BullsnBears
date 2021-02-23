//
//  ValueListTVC.swift
//  Bulls'N'Bears
//
//  Created by aDav on 16/02/2021.
//

import UIKit

class ValueListTVC: UITableViewController {

    var values: [[Double]?]?
    var sectionTitles = ["Summary"]
    var rowTitles = [String]()
    var formatter: NumberFormatter!
    var valuation: WBValuation!
    var meanToDisplay: Double?
    var correlationToDisplay: Double?
    var trendToDisplay: Double?
    var mostRecentYear: Int!
    var proportions: [Double?]?
    var gradingLimits: [Double]? // first = good, // second = moderate // third = bad
    var gapErrors: [String]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "ValueListCell", bundle: nil), forCellReuseIdentifier: "valueListCell")
        
        let components: Set<Calendar.Component> = [.year]
        let dateComponents = Calendar.current.dateComponents(components, from: Date())
        mostRecentYear = dateComponents.year! - 1
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if values?.count ?? 0  == 2 {

            proportions = Calculator.proportions(array1: values?.first!, array0: values?.last!)

            let proportionsNoGaps = proportions?.compactMap{$0}.filter({ (element) -> Bool in
                if element != 0.0 { return true }
                else { return false }
            })

            if proportions?.count ?? 0 != proportionsNoGaps?.count ?? 0 {
                gapErrors = ["missing data were omitted. Use result with caution"]
            }
            else {
                gapErrors = nil
            }
            meanToDisplay = proportionsNoGaps?.weightedMean()
            trendToDisplay = proportions?.growthRates()?.weightedMean()
            var years = [Double]()
            var count = 0.0
            for _ in proportionsNoGaps ?? [] {
                years.append(count)
                count += 1.0
            }

            if let trend = Calculator.correlation(xArray: years, yArray: proportionsNoGaps?.reversed()) {
                correlationToDisplay = trend.r2()
            }
        }
        else if values?.count ?? 0 == 1 {
            
            let valuesWOMissing = values?.first!?.filter({ (element) -> Bool in
                if element != 0.0 { return true }
                else { return false }
            })
            
            if values?.first!?.count ?? 0 != valuesWOMissing?.count ?? 0 {
                gapErrors = ["missing data were omitted. Use result with caution"]
            }
            else {
                gapErrors = nil
            }

            meanToDisplay = valuesWOMissing?.weightedMean()
            let growthRates = valuesWOMissing?.growthRates()
            trendToDisplay = growthRates?.weightedMean()
            var years = [Double]()
            var count = 0.0
            for _ in growthRates ?? [] {
                years.append(Double(mostRecentYear) - count)
                count += 1.0
            }
 
            if let trend = Calculator.correlation(xArray: years.reversed(), yArray: growthRates?.reversed()) {
//                let endY =  trend.yIntercept + trend.incline * (count)
//                trendToDisplay =  (endY - trend.yIntercept) / abs(trend.yIntercept)
                correlationToDisplay = trend.r2() // formula for 'variance explained' =R2
            }
        }
        
        tableView.reloadSections([0], with: .automatic)
    }

    func refreshTableView() {
        self.tableView.reloadSections([1,2], with: .automatic)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return (values?.count ?? 0) + 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return 2
        } else {
            return values?[section-1]?.count ?? 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "valueListCell", for: indexPath) as! ValueListCell

        if indexPath.section == 0 {
//            if indexPath.row == 0 {
//                if values?.count ?? 0 == 2 {
//                    cell.configure(title: "Weighted growth", value: meanToDisplay, detail: "", formatter: percentFormatter0Digits)
//                }
//                else if values?.count ?? 0 == 1 {
//                    cell.configure(title: "Weighted average", value: meanToDisplay, detail: "", formatter: numberFormatterNoFraction)
//                }
//            }
//            else
            if indexPath.row == 1 {
                cell.configure(title: "R2", attributedTitle: "R2", superscriptLetterIndex: 1 ,value: correlationToDisplay, detail: "", formatter: percentFormatter0Digits)
            } else {
                cell.configure(title: "Growth trend", value: trendToDisplay, detail: "", formatter: percentFormatter2DigitsPositive)
            }
        }
        else {
            let year = mostRecentYear - indexPath.row
            var proportion: Double?
            var detail$ = " "
            
            if indexPath.section == 1 {
                if values?.count ?? 0 == 2 {
                    if values![1]![indexPath.row] > 0 {
                        proportion = values![0]![indexPath.row] / values![1]![indexPath.row]
                        if proportion != nil {
                            detail$ = percentFormatter0Digits.string(from: proportion! as NSNumber) ?? " "
                        }
                    }
                }
                else if indexPath.row + 1 < values!.first!?.count ?? 0 {
                    if values!.first!?.count ?? 0 > indexPath.row {
                        proportion = (values!.first!![indexPath.row] - values!.first!![indexPath.row+1]) / abs(values!.first!![indexPath.row+1])
                        if proportion != nil {
                            detail$ = percentFormatter0Digits.string(from: proportion! as NSNumber) ?? " "
                        }
                    }
                }
            }
            
            cell.configure(title: "\(year)", value: values?[indexPath.section-1]?[indexPath.row], detail: detail$, detailColor: detailColor(value: proportion), formatter: formatter)
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    
    private func detailColor(value: Double?) -> UIColor? {
        
        guard let validvalue = value else {
            return nil
        }
        
        guard gradingLimits != nil else {
            return nil
        }
        
        guard gradingLimits!.count == 2 else {
            return nil
        }
        
        if gradingLimits!.first! < gradingLimits!.last! {
            // smaller values are graded better
            if validvalue < gradingLimits!.first! { return UIColor(named: "Green") }
            else if validvalue > gradingLimits!.last! { return UIColor(named: "Red") }
            else { return UIColor.systemYellow }
        }
        else {
            // larger values are graded better
            if validvalue > gradingLimits!.first! { return UIColor(named: "Green") }
            else if validvalue < gradingLimits!.last! { return UIColor(named: "Red") }
            else { return UIColor.systemYellow }
        }
        
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let destination = segue.destination as? WBValuationTVC {
            destination.chartDelegate.removeValueChart()
        }
    }


}
