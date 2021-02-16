//
//  WBValuationTVC.swift
//  Bulls'N'Bears
//
//  Created by aDav on 15/02/2021.
//

import UIKit

class WBValuationTVC: UITableViewController {

    var downloadButton: UIBarButtonItem!
    var controller: WBValuationController!
    var stock: Stock!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        downloadButton = UIBarButtonItem(image: UIImage(systemName: "icloud.and.arrow.down.fill"), style: .plain, target: self, action: #selector(startDownload))
         self.navigationItem.rightBarButtonItem = downloadButton
        
        self.navigationController?.title = stock.name_short
        tableView.register(UINib(nibName: "WBValuationCell", bundle: nil), forCellReuseIdentifier: "wbValuationCell")
        
        controller = WBValuationController(stock: stock)

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

        let (value$, errors) = controller.value$(path: indexPath)
        
        cell.configure(title: controller.rowTitle(path: indexPath), detail: value$, infoText: errors)
        
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
