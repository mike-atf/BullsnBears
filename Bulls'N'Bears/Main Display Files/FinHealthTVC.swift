//
//  FinHealthTVC.swift
//  Bulls'N'Bears
//
//  Created by aDav on 02/10/2022.
//

import UIKit

class FinHealthTVC: UITableViewController {
    
    var controller: FinHealthController!
    var share: Share?
    var sectionTitles = ["Key values", "Profitability", "Efficiency", "Liquidity", "Solvency"]
    var sectionSubtitles = ["",
                            "A larger net margin, especially compared to industry peers, means a greater margin of financial safety, and also indicates a company is in a better financial position to commit capital to growth and expansion.",
                            " Operating margin considers a company's basic operational profit margin after deducting the variable costs of producing and marketing the company's products or services. Crucially, it indicates how well the company's management is able to control costs." ,
                            "Quick ratio indicates the company’s ability to instantly use its assets that can be converted quickly to cash to pay down its current liabilities, it is also called the acid test ratio.\nThe current ratio is a liquidity ratio that measures a company’s ability to pay short-term obligations or those due within one year.",
                            "Solvency is a company's ability to meet its debt obligations on an ongoing basis, not just over the short term. Solvency ratios calculate a company's long-term debt in relation to its assets or equity."]

    override func viewDidLoad() {
        super.viewDidLoad()

        controller = FinHealthController(share: share, finHealthTVC: self)
        
        tableView.register(UINib(nibName: "FinHealthCell", bundle: nil), forCellReuseIdentifier: "finHealthCell")

    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

        return 5
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if section == 0 {
            return 5
        } else if section == 1 {
            return 1
        } else if section == 2 {
            return 1
        } else if section == 3 {
            return 2
        } else if section == 4 {
            return 1
        } else {
            return 0
        }

    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "finHealthCell", for: indexPath) as! FinHealthCell

        let chartData = controller.dataForPath(indexPath: indexPath)
        cell.configure(path: indexPath, primaryData: chartData)

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
    
//    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        return sectionTitles[section]
//    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = UIView()
        let height: CGFloat = (UIDevice().userInterfaceIdiom == .pad) ? 40 : 50
        header.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: height)
        
        let largeFontSize: CGFloat = (UIDevice().userInterfaceIdiom == .pad) ? 18 : 18
//        let smallFontSize: CGFloat = (UIDevice().userInterfaceIdiom == .pad) ? 12 : 12
        
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

        let margins = header.layoutMarginsGuide
        
//        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.topAnchor.constraint(equalTo: margins.topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(greaterThanOrEqualTo: margins.trailingAnchor).isActive = true
        
        if section > 0 {
            var config = UIButton.Configuration.borderless()
                config.image = UIImage(systemName: "info.circle")
            
            let infoButton = UIButton(configuration: config, primaryAction: nil)
            infoButton.tag = section
            infoButton.addTarget(self, action: #selector(showSectionInfo(button:)), for: .touchUpInside)
            
            infoButton.translatesAutoresizingMaskIntoConstraints = false
            header.addSubview(infoButton)

            infoButton.centerYAnchor.constraint(equalTo: margins.centerYAnchor).isActive = true
            infoButton.trailingAnchor.constraint(equalTo: margins.trailingAnchor).isActive = true
        }

        return header
    }
    
    @objc
    func showSectionInfo(button: UIButton) {
        
        if let infoView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ValuationErrorsTVC") as? ValuationErrorsTVC {
            
            infoView.modalPresentationStyle = .popover
            infoView.preferredContentSize = CGSize(width: self.view.frame.width * 0.75, height: self.view.frame.height * 0.2)

            let popUpController = infoView.popoverPresentationController
            popUpController!.permittedArrowDirections = .any
            popUpController!.sourceView = button
            infoView.loadViewIfNeeded()
            
            infoView.errors = [sectionSubtitles[button.tag]]
            infoView.firstCellHeight = infoView.preferredContentSize.height
            
            present(infoView, animated: true, completion:  nil)
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
