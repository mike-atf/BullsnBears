//
//  ValuationListViewController.swift
//  TrendMyStocks
//
//  Created by aDav on 03/01/2021.
//

import UIKit

class ValuationListViewController: UITableViewController {
    
    var presentingListVC: StocksListViewController!
    var sourceIndexPath: IndexPath!
    
    var valuationMethod:ValuationMethods!
    var dcfValuation: DCFValuation?
    var r1Valuation: Rule1Valuation?
    
    var sectionSubtitles: [String]?
    var sectionTitles: [String]?
    var rowTitles: [[String]]?

    var dcfHelper: DCFValuationHelper?
    var dcfController: ValuationsController?
    
    var r1vHelper: R1ValuationHelper?
    var r1VController: Rule1ValuationController?

    override func viewDidLoad() {
        super.viewDidLoad()

        // self.clearsSelectionOnViewWillAppear = false

        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        
        tableView.register(UINib(nibName: "ValuationTableViewCell", bundle: nil), forCellReuseIdentifier: "valuationTableViewCell")
        if valuationMethod == .dcf {
            dcfController = ValuationsController(listView: self)
            dcfHelper = dcfController
        } else {
            r1VController = Rule1ValuationController(listView: self)
            r1vHelper = r1VController
        }

        sectionTitles = dcfHelper?.dcfSectionTitles() ?? r1vHelper?.r1SectionTitles()
        sectionSubtitles = dcfHelper?.dcfSectionSubTitles() ?? r1vHelper?.r1SectionSubTitles()
        rowTitles = dcfHelper?.buildRowTitles() ?? r1vHelper?.buildRowTitles()
        
        tableView.reloadData()

    }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

        return sectionTitles?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if (rowTitles?.count ?? 0) > section {
            return rowTitles![section].count
        }
        else {
            return 0
        }
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "valuationTableViewCell", for: indexPath) as! ValuationTableViewCell

        if let helper = dcfHelper {
            helper.configureCell(indexPath: indexPath, cell: cell)
        } else {
            r1vHelper!.configureCell(indexPath: indexPath, cell: cell)
        }
        
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if valuationMethod == .dcf {
            if [3,4,7,9].contains(section) { return 10 }
            else {  return (UIDevice().userInterfaceIdiom == .pad) ? 70 : 60 }
        } else {
            if [0,1,6,7,8,9,10,11].contains(section) { return 70 }
            else {  return (UIDevice().userInterfaceIdiom == .pad) ? 40 : 60 }

        }
       
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
            label.text = sectionTitles?[section]
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
            label.text = sectionSubtitles?[section]
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
        
        if section == 0 || section == (sectionTitles?.count ?? 0) - 1 {
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
        dcfValuation?.save()
        self.dismiss(animated: true) {
            self.presentingListVC.valuationCompleted(indexPath: self.sourceIndexPath)
        }
    }

    
    public func helperUpdatedRows(paths: [IndexPath]) {
        
        tableView.reloadRows(at: paths, with: .automatic)
    }
    
    public func helperAskedToEnterNextTextField(targetPath: IndexPath) {
        
        let targetCell = tableView.cellForRow(at: targetPath) as! ValuationTableViewCell
//        let targetCell = tableView.dequeueReusableCell(withIdentifier: "valuationTableViewCell", for: targetPath) as! ValuationTableViewCell
        
        tableView.selectRow(at: targetPath, animated: true, scrollPosition: .none)
        
        targetCell.textField.text = "This is selected next"
        targetCell.textField.becomeFirstResponder()
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

//extension ValuationListViewController: CellTextFieldDelegate {
//    
//    func userAddedText(textField: UITextField, path: IndexPath) {
//        print("text entry complete")
//    }
//    
//    
//}
