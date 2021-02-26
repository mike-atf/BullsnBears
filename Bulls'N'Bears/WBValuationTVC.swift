//
//  WBValuationTVC.swift
//  Bulls'N'Bears
//
//  Created by aDav on 15/02/2021.
//

import UIKit

protocol WBValuationListDelegate: NSObject {
    func sendArrayForDisplay(array: [Double]?)
    func removeValueChart()
}

class WBValuationTVC: UITableViewController, ProgressViewDelegate {

    var downloadButton: UIBarButtonItem!
    var controller: WBValuationController!
    var stock: Stock!
    var progressView: DownloadProgressView?
    weak var chartDelegate: WBValuationListDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        downloadButton = UIBarButtonItem(image: UIImage(systemName: "icloud.and.arrow.down.fill"), style: .plain, target: self, action: #selector(startDownload))
         self.navigationItem.rightBarButtonItem = downloadButton
        
        self.navigationController?.title = stock.name_short
        tableView.register(UINib(nibName: "WBValuationCell", bundle: nil), forCellReuseIdentifier: "wbValuationCell")
        
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return controller.sectionTitles.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return controller.rowTitles[section].count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "wbValuationCell", for: indexPath) as! WBValuationCell

        let (value$, color, errors) = controller.value$(path: indexPath)
        
        cell.configure(title: controller.rowTitle(path: indexPath), detail: value$, detailColor: color,errors: errors, delegate: self)
        
        if indexPath.section == 0 {
            cell.accessoryType = .none
        }
        else {
            cell.accessoryType = .disclosureIndicator
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = UIView()
        let height: CGFloat = (UIDevice().userInterfaceIdiom == .pad) ? 60 : 50
        header.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: height)
        
        let (title, subtitle) = controller.sectionHeaderText(section: section)
        
        let largeFontSize: CGFloat = (UIDevice().userInterfaceIdiom == .pad) ? 22 : 20
        let smallFontSize: CGFloat = (UIDevice().userInterfaceIdiom == .pad) ? 16 : 12
        
        let titleLabel: UILabel = {
            let label = UILabel()
            let fontSize = largeFontSize
            label.font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
            label.textAlignment = .left
            label.textColor = UIColor.systemOrange
            label.text = title
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
            label.text = subtitle
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
        
//        if section == 0 {
//            let donwloadButton = UIButton()
//            donwloadButton.setBackgroundImage(UIImage(systemName: "icloud.and.arrow.down.fill"), for: .normal)
//            donwloadButton.addTarget(self, action: #selector(downloadValuationData), for: .touchUpInside)
//            donwloadButton.translatesAutoresizingMaskIntoConstraints = false
//            header.addSubview(donwloadButton)
//
//            donwloadButton.centerYAnchor.constraint(equalTo: margins.centerYAnchor).isActive = true
//            donwloadButton.trailingAnchor.constraint(equalTo: margins.trailingAnchor).isActive = true
//            donwloadButton.heightAnchor.constraint(equalTo: margins.heightAnchor, multiplier: 0.6).isActive = true
//            donwloadButton.widthAnchor.constraint(equalTo: donwloadButton.heightAnchor).isActive = true
//
//        }
        
//        if section == (sectionTitles?.count ?? 0) - 1 {
//            let saveButton = UIButton()
//            saveButton.setBackgroundImage(UIImage(systemName: "square.and.arrow.down"), for: .normal)
//            saveButton.addTarget(self, action: #selector(saveValuation), for: .touchUpInside)
//            saveButton.translatesAutoresizingMaskIntoConstraints = false
//            header.addSubview(saveButton)
//
//            saveButton.centerYAnchor.constraint(equalTo: margins.centerYAnchor).isActive = true
//            saveButton.trailingAnchor.constraint(equalTo: margins.trailingAnchor).isActive = true
//            saveButton.heightAnchor.constraint(equalTo: margins.heightAnchor, multiplier: 0.6).isActive = true
//            saveButton.widthAnchor.constraint(equalTo: saveButton.heightAnchor).isActive = true
//        }

        return header
        
    }
    
    @objc
    func startDownload() {
                
        progressView = DownloadProgressView.instanceFromNib()
        progressView?.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(progressView!)
        
        let margins = view.layoutMarginsGuide

        progressView?.widthAnchor.constraint(equalTo: margins.widthAnchor, multiplier: 0.8).isActive = true
        progressView?.centerXAnchor.constraint(equalTo: margins.centerXAnchor).isActive = true
        progressView?.heightAnchor.constraint(equalTo: margins.heightAnchor, multiplier: 0.2).isActive = true
        progressView?.centerYAnchor.constraint(equalTo: margins.centerYAnchor).isActive = true

        progressView?.delegate = self
        progressView?.title.text = "Trying public data acquisition..."

        controller.downloadWBValuationData()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        performSegue(withIdentifier: "valueListSegue", sender: nil)
        tableView.deselectRow(at: indexPath, animated: true)
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


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
           
        guard let selectedPath = self.tableView.indexPathForSelectedRow else {
            return
        }
        
        // section one has P/E, EPS and beta - no details to show
        guard selectedPath.section > 0 else {
            return
        }
        
        
        if let destination = segue.destination as? ValueListTVC {
            
            destination.loadViewIfNeeded()
            destination.controller = controller
            destination.sectionTitles.append(contentsOf: controller.valueListTVCSectionTitles[selectedPath.section-1][selectedPath.row])
            var arrays: [[Double]?]?
            
            if selectedPath.section == 1 {
                if selectedPath.row == 0 {
                    arrays = [controller.valuation?.eps ?? []]
                    destination.values = arrays
//                    destination.sectionTitles.append(contentsOf: ["EPS"])
                    destination.formatter = currencyFormatterGapWithPence
                    destination.gradingLimits = [10.0, 40.0]
                }

                if selectedPath.row == 1 {
                    arrays = [controller.valuation?.grossProfit ?? [], controller.valuation?.revenue ?? []]
                    destination.values = arrays
//                    destination.sectionTitles.append(contentsOf: ["Gross profit (% of revenue)", "Revenue"])
                    destination.formatter = currencyFormatterGapNoPence
                    let (margins, errors) = controller.valuation!.grossProfitMargins()
                    destination.proportions = margins
                    destination.gradingLimits = [0.4,0.2]
                }
                else if selectedPath.row == 2 {
                    arrays = [controller.valuation?.sgaExpense ?? [], controller.valuation?.grossProfit ?? []]
                    destination.values = arrays
//                    destination.sectionTitles.append(contentsOf: ["SGA (% of profit)", "Profit"])
                    destination.formatter = currencyFormatterGapNoPence
                    let (margins, errors) = controller.valuation!.sgaProportion()
                    destination.proportions = margins
                    destination.gradingLimits = [0.3,0.9]
                }
                else if selectedPath.row == 3 {
                    arrays = [controller.valuation?.rAndDexpense ?? [], controller.valuation?.grossProfit ?? []]
                    destination.values = arrays
//                    destination.sectionTitles.append(contentsOf: ["R&D (% of profit)", "Profit"])
                    destination.formatter = currencyFormatterGapNoPence
                    let (margins, errors) = controller.valuation!.rAndDProportion()
                    destination.proportions = margins
                    destination.gradingLimits = nil
                }
                else if selectedPath.row == 4 {
                    arrays = [controller.valuation?.netEarnings ?? [], controller.valuation?.revenue ?? []]
                    destination.values = arrays
//                    destination.sectionTitles.append(contentsOf: ["net income (% of revenue)", "Revenue"])
                    destination.formatter = currencyFormatterGapNoPence
                    let (margins, errors) = controller.valuation!.netIncomeProportion()
                    destination.proportions = margins
                    destination.gradingLimits = [0.2,0.1]
                }
                
            }
            else if selectedPath.section == 2 {
                if selectedPath.row == 0 {
                    arrays = [controller.valuation?.debtLT ?? [], controller.valuation?.netEarnings ?? []]
                    destination.values = arrays
//                    destination.sectionTitles.append(contentsOf: ["LT debt (% of net income)", "Net income"])
                    destination.formatter = currencyFormatterGapNoPence
                    let (margins, errors) = controller.valuation!.longtermDebtProportion()
                    destination.proportions = margins
                    destination.gradingLimits = [3.0,4.0]
                }
                else if selectedPath.row == 1 {
                    let (shEquityWithRetEarnings, _) = controller.valuation!.addElements(array1: controller.valuation?.shareholdersEquity ?? [], array2: controller.valuation!.equityRepurchased ?? [])
                    arrays = [controller.valuation?.debtLT ?? [], shEquityWithRetEarnings]
                    destination.values = arrays
//                    destination.sectionTitles.append(contentsOf: ["LT debt (% of sh. equity + rt. earnings)", "Sh. equity + rt. earnings"])
                    destination.formatter = currencyFormatterGapNoPence

                }
                else if selectedPath.row == 2 {
                    arrays = [controller.valuation?.equityRepurchased ?? []]
                    destination.values = arrays
//                    destination.sectionTitles.append(contentsOf: ["Retained earnings"])
                    destination.formatter = currencyFormatterGapNoPence
                }
                else if selectedPath.row == 3 {
                    arrays = [controller.valuation?.roe ?? []]
                    destination.values = arrays
//                    destination.sectionTitles.append(contentsOf: ["Return on equity"])
                    destination.formatter = percentFormatter0Digits
                }
                else if selectedPath.row == 4 {
                    arrays = [controller.valuation?.roa ?? []]
                    destination.values = arrays
//                    destination.sectionTitles.append(contentsOf: ["Return on assets"])
                    destination.formatter = percentFormatter0Digits
                }
            }
            
//            destination.refreshTableView()
        }
        
    }

    
    func progressUpdate(allTasks: Int, completedTasks: Int) {
        self.progressView?.updateProgress(tasks: allTasks, completed: completedTasks)
    }
    
    func cancelRequested() {
        controller.stopDownload()
    }
    
    func downloadComplete() {
        self.progressView?.delegate = nil
        progressView?.removeFromSuperview()
        progressView = nil
        
        controller.valuation?.save()
        
        print()
        print("valuation saved 3x")
        print(controller.valuation)
        print()
        
        tableView.reloadSections([1,2], with: .automatic)
    }


}

extension WBValuationTVC: StockKeyratioDownloadDelegate, WBValuationCellDelegate {
    
    func keyratioDownloadComplete(errors: [String]) {
        DispatchQueue.main.async {
            self.tableView.reloadSections([0], with: .automatic)

        }
    }
    
    func infoButtonAction(errors: [String]?, sender: UIButton) {
        
        if let errorsView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ValuationErrorsTVC") as? ValuationErrorsTVC {
            
            errorsView.modalPresentationStyle = .popover
            errorsView.preferredContentSize = CGSize(width: self.view.frame.width * 0.75, height: self.view.frame.height * 0.25)

            let popUpController = errorsView.popoverPresentationController
            popUpController!.permittedArrowDirections = .any
            popUpController!.sourceView = sender
            errorsView.loadViewIfNeeded()
            
            errorsView.errors = errors ?? ["no errors occurred"]
            
            present(errorsView, animated: true, completion:  nil)
        }
    }

    
}

