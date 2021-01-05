//
//  ValuationListViewController.swift
//  TrendMyStocks
//
//  Created by aDav on 03/01/2021.
//

import UIKit

class ValuationListViewController: UITableViewController {
    
    var valuationMethod:ValuationMethods!
    var valuation: DCFValuation?
    let sectionSubtitles = ["General","Yahoo Summary > Key Statistics", "Details > Financials > Income Statement", "", "", "Details > Financials > Balance Sheet", "Details > Financials > Cash Flow", "","Details > Analysis > Revenue estimate", ""]
    let sectionTitles = dcfValuationSectionTitles
    var rowTitles = [[String]]()
    var rowValues = [[Any]]()
    
    let yearOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = NSLocale.current
        formatter.timeZone = NSTimeZone.local
        formatter.dateFormat = "YYYY"
        return formatter
    }()


    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        
        tableView.register(UINib(nibName: "ValuationTableViewCell", bundle: nil), forCellReuseIdentifier: "valuationTableViewCell")
        
        rowTitles = buildRowTitles()
        tableView.reloadData()

    }
    
    private func buildRowTitles() -> [[String]] {
        
        var totalRevenueTitles = ["Total revenue"]
//        var totalRevenueValues = [Double]()
        
        var netIncomeTitles = ["Net income"]
//        var netIncomeValues = [Double]()
        
        var oFCFTitles = ["op. Cash flow"]
//        var oFCFValues = [Double]()
        
        var capExpendTitles = ["Capital expend."]
//        var capExpendValues = [Double]()
        
        var revPredTitles = ["Revenue estimate"]
//        var revPredValues = [Double]()
        
        var growthPredTitles = ["Sales growth"]
//        var growthPredValues = [Double]()

        var count = 0
        for i in stride(from: 4, to: 0, by: -1) {
            let date = (valuation?.creationDate ?? Date()).addingTimeInterval(Double(i * -1) * 366 * 24 * 3600)
            let year$ = yearOnlyFormatter.string(from: date)
            
            var newTitle = totalRevenueTitles.first! + " " + year$
            totalRevenueTitles.insert(newTitle, at: 1)
//            totalRevenueValues.append(valuation?.tRevenueActual![i] ?? Double())
            
            newTitle = netIncomeTitles.first! + " " + year$
            netIncomeTitles.insert(newTitle, at: 1)
//            netIncomeValues.append(valuation?.netIncome![i] ?? Double())

            newTitle = oFCFTitles.first! + " " + year$
            oFCFTitles.insert(newTitle, at: 1)
//            netIncomeValues.append(valuation?.netIncome![i] ?? Double())

            newTitle = capExpendTitles.first! + " " + year$
            capExpendTitles.insert(newTitle, at: 1)
            
            count += 1
        }
        
        for i in 0..<2 {
            let date = (valuation?.creationDate ?? Date()).addingTimeInterval(Double(i) * 366 * 24 * 3600)
            let year$ = yearOnlyFormatter.string(from: date)
            
            var newTitle = revPredTitles.first! + " " + year$
            revPredTitles.append(newTitle)
            newTitle = growthPredTitles.first! + " " + year$
            growthPredTitles.append(newTitle)

        }
        totalRevenueTitles.removeFirst()
        netIncomeTitles.removeFirst()
        oFCFTitles.removeFirst()
        capExpendTitles.removeFirst()
        revPredTitles.removeFirst()
        growthPredTitles.removeFirst()
        
        let generalSectionTitles = ["Date", "US 10y Treasure Bond rate", "Perpetual growth rate", "Exp. LT Market return"]
        let keyStatsTitles = ["Market cap", "beta"]
        let singleIncomeSectionTitles = ["Interest expense","Pre-Tax income","Income tax expend."]
        let balanceSheetSectionTitles = ["Current debt","Long term debt"]
        
        var incomeSection1Titles = [String]()
        var incomeSection2Titles = [String]()
        var incomeSection3Titles = [String]()
        var cashFlowSection1Titles = [String]()
        var cashFlowSection2Titles = [String]()
        var predictionSection1Titles = [String]()
        var predictionSection2Titles = [String]()

        incomeSection1Titles.append(contentsOf: totalRevenueTitles)
        incomeSection2Titles.append(contentsOf: netIncomeTitles)
        incomeSection3Titles.append(contentsOf: singleIncomeSectionTitles)
        
        cashFlowSection1Titles.append(contentsOf: oFCFTitles)
        cashFlowSection2Titles.append(contentsOf: capExpendTitles)
        
        predictionSection1Titles.append(contentsOf: revPredTitles)
        predictionSection2Titles.append(contentsOf: growthPredTitles)
        
        return [generalSectionTitles ,keyStatsTitles, incomeSection1Titles, incomeSection2Titles, incomeSection3Titles, balanceSheetSectionTitles, cashFlowSection1Titles, cashFlowSection2Titles, predictionSection1Titles,predictionSection2Titles]

    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

        return sectionTitles.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if rowTitles.count > section {
            return rowTitles[section].count
        }
        else {
            return 0
        }
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "valuationTableViewCell", for: indexPath) as! ValuationTableViewCell

        if indexPath == IndexPath(item: 2, section: 8) {
            print()
        }
        
        cell.configure(title: rowTitles[indexPath.section][indexPath.row], detail: "D", value: valuation?.returnValuationListItem(indexPath: indexPath) ,delegate: self, indexPath: indexPath)

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if [3,4,7,9].contains(section) { return 10 }
        else {  return (UIDevice().userInterfaceIdiom == .pad) ? 60 : 50 }
       
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = UIView()
        let height: CGFloat = (UIDevice().userInterfaceIdiom == .pad) ? 90 : 50
        header.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: height)
        
        let largeFontSize: CGFloat = (UIDevice().userInterfaceIdiom == .pad) ? 22 : 20
        let smallFontSize: CGFloat = (UIDevice().userInterfaceIdiom == .pad) ? 18 : 14
        
        let titleLabel: UILabel = {
            let label = UILabel()
            let fontSize = largeFontSize
            label.font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
            label.textAlignment = .left
            label.textColor = UIColor.systemOrange
            label.text = sectionTitles[section]
            return label
        }()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
                
        header.addSubview(titleLabel)
        
        let subTitle: UILabel = {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: smallFontSize, weight: .regular)
            label.textColor = UIColor.label
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.8
            label.text = sectionSubtitles[section]
            return label
        }()
        
        subTitle.translatesAutoresizingMaskIntoConstraints = false
        
        header.addSubview(subTitle)
        
        
        let margins = header.layoutMarginsGuide
        
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.topAnchor.constraint(equalTo: margins.topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 10).isActive = true
        titleLabel.trailingAnchor.constraint(greaterThanOrEqualTo: subTitle.leadingAnchor, constant: 10).isActive = true
        
        subTitle.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: 5).isActive = true
        subTitle.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
        subTitle.trailingAnchor.constraint(greaterThanOrEqualTo: titleLabel.leadingAnchor, constant: 10).isActive = true
        
        if section == 0 || section == sectionTitles.count - 1 {
            let saveButton = UIButton()
            saveButton.setBackgroundImage(UIImage(systemName: "square.and.arrow.down"), for: .normal)
            saveButton.addTarget(self, action: #selector(saveValuation), for: .touchUpInside)
            saveButton.translatesAutoresizingMaskIntoConstraints = false
            header.addSubview(saveButton)

            saveButton.centerYAnchor.constraint(equalTo: margins.centerYAnchor).isActive = true
            saveButton.trailingAnchor.constraint(equalTo: margins.trailingAnchor).isActive = true
            saveButton.heightAnchor.constraint(equalTo: margins.heightAnchor, multiplier: 0.75).isActive = true
            saveButton.widthAnchor.constraint(equalTo: saveButton.heightAnchor).isActive = true
        }

        return header
        
    }
    
    @objc
    func saveValuation() {
        
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

extension ValuationListViewController: CellTextFieldDelegate {
    
    func userAddedText(textField: UITextField, path: IndexPath) {
        print("text entry complete")
    }
    
    
}
