//
//  ResearchTVC.swift
//  Bulls'N'Bears
//
//  Created by aDav on 29/03/2021.
//

import UIKit

class ResearchTVC: UITableViewController {
        
    var share: Share?
    var research: StockResearch?
    var sectionTitles: [String]?
    var controller: ResearchController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "ResearchCell", bundle: nil), forCellReuseIdentifier: "researchCell")
        self.title = "\(share?.name_short ?? "missing") research"
        
        controller =  ResearchController(share: share, researchList: self)
        
        research = share?.research
        sectionTitles = controller?.sectionTitles()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

        return sectionTitles?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if (sectionTitles?[section] ?? "").contains("news") {
            return research?.news?.count ?? 0
        }
        else if (sectionTitles?[section] ?? "").contains("Competitors") {
            return research?.competitors?.count ?? 0
        }
        else if (sectionTitles?[section] ?? "").contains("products") {
            return research?.productsNiches?.count ?? 0
        }
        else {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
//        if (sectionTitles?[indexPath.section] ?? "").contains("Growth Category") {
//
//            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryOptionsCell", for: indexPath) as! UITableViewCell
//
//        } else {
        
            let cell = tableView.dequeueReusableCell(withIdentifier: "researchCell", for: indexPath) as! ResearchCell

            cell.configure(delegate: controller, path: indexPath)

            return cell
//        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.section == 0 {
            return 70
        }
        else if indexPath.section == 1	 {
            return 44
        }
        else if indexPath.section == 2 {
            return 44
        }
        else if indexPath.section == 3 {
            return 44
        }
        else if indexPath.section == 4 {
            return 70
        }
        else if indexPath.section == 5 {
            return 44
        }
        else if indexPath.section == 6 {
            return 44
        }
        else if indexPath.section == 7 {
            return 44
        }
        else if indexPath.section == 8 {
            return 44
        }
        else if indexPath.section == 9 {
            return 70
        }
        else if indexPath.section == 10 {
            return 100
        }
        else if indexPath.section == 11 {
            return 70
        }
        else if indexPath.section == 12 {
            return 120
        }
        else {
            return 100
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = UIView()
        let height: CGFloat = (UIDevice().userInterfaceIdiom == .pad) ? 100 : 60
        header.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: height)
        
        let largeFontSize: CGFloat = (UIDevice().userInterfaceIdiom == .pad) ? 22 : 20
        
        let titleLabel: UILabel = {
            let label = UILabel()
            let fontSize = largeFontSize
            label.font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
            label.text = sectionTitles?[section] ?? ""
            return label
        }()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        header.addSubview(titleLabel)
                                        
        let margins = header.layoutMarginsGuide
        
        titleLabel.centerYAnchor.constraint(equalTo: margins.centerYAnchor).isActive = true
        titleLabel.heightAnchor.constraint(equalTo: margins.heightAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: margins.trailingAnchor, constant: 50).isActive = true
             
        if titleLabel.text!.contains("news") || titleLabel.text!.contains("Competitors") || titleLabel.text!.contains("products") {
            let infoButton = UIButton()
            infoButton.setBackgroundImage(UIImage(systemName: "plus.circle"), for: .normal)
            infoButton.tag = section
            infoButton.tintColor = UIColor.systemOrange
            infoButton.addTarget(self, action: #selector(addNews(button:)), for: .touchUpInside)
            infoButton.translatesAutoresizingMaskIntoConstraints = false
            header.addSubview(infoButton)

            infoButton.centerYAnchor.constraint(equalTo: margins.centerYAnchor).isActive = true
            infoButton.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 20).isActive = true
            infoButton.heightAnchor.constraint(equalTo: margins.heightAnchor, multiplier: 1).isActive = true
            infoButton.widthAnchor.constraint(equalTo: infoButton.heightAnchor).isActive = true
        }
        return header
    }

    @objc
    func addNews(button: UIButton) {
        
        let section = button.tag
        let title = sectionTitles?[section] ?? ""
        
        if title.contains("news") {
            let news = CompanyNews.init(context: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)
            news.creationDate = Date()
            research?.addToNews(news)
            news.save()
            tableView.reloadSections([section], with: .automatic)
        }
        else if title.contains("Competitors") {
            if research?.competitors == nil {
                research?.competitors = [String()]
            }
            else {
                research?.competitors?.append(String())
            }
            research?.save()
            tableView.reloadSections([section], with: .automatic)
        }
        else if title.contains("products") {
            if research?.productsNiches == nil {
                research?.productsNiches = [String()]
            }
            else {
                research?.productsNiches?.append(String())
            }
            research?.save()
            tableView.reloadSections([section], with: .automatic)
        }
        
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let title = sectionTitles?[indexPath.section] ?? ""
        
        guard title.contains("news") || title.contains("Competitors") || title.contains("products") else { return nil }
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete")
        { (action, view, bool) in
            
            self.controller?.deleteObject(cellPath: indexPath)
            tableView.reloadSections([indexPath.section], with: .automatic)
        }
            
        let swipeActions = UISwipeActionsConfiguration(actions: [deleteAction])
    
        return swipeActions

    }
        
}
