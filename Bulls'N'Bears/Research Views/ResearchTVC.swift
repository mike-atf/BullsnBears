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
    
    var progressView: DownloadProgressView?
    var allDownloadTasks = 0
    var completedDownloadTasks = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "ResearchCell", bundle: nil), forCellReuseIdentifier: "researchCell")
        tableView.register(UINib(nibName: "DateSelectionCell", bundle: nil), forCellReuseIdentifier: "dateSelectionCell")
        
        controller =  ResearchController(share: share, researchList: self)
        
        research = share?.research
        
        let latestChangeDate = dateFormatter.string(from: research?.creationDate ?? Date())
        self.title = "\(share?.name_short ?? "missing") - Research (" + latestChangeDate + ")"

        sectionTitles = controller?.sectionTitles()
        
        var downloadButtonConfiguration = UIButton.Configuration.filled()
        downloadButtonConfiguration.title = "Refresh data"
        downloadButtonConfiguration.buttonSize = .small
        downloadButtonConfiguration.titleAlignment = .center
        downloadButtonConfiguration.cornerStyle = .small
        let db = UIButton(configuration: downloadButtonConfiguration, primaryAction: UIAction() {_ in
//            self.downloadButtonConfiguration.showsActivityIndicator = true
            self.downloadResearchData()
        })
        
        let downloadButton = UIBarButtonItem(customView: db)
        self.navigationItem.rightBarButtonItem = downloadButton

    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

        return sectionTitles?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if (sectionTitles?[section] ?? "").contains("news") {
            return research?.news?.count ?? 0
        }
        else if (sectionTitles?[section] ?? "").contains("products") {
            return research?.productsNiches?.count ?? 0
        }
        else if (sectionTitles?[section] ?? "").contains("share prices") {
            return 3
        }
        else {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if (sectionTitles?[indexPath.section] ?? "").lowercased().contains("date") {
            let cell = tableView.dequeueReusableCell(withIdentifier: "dateSelectionCell", for: indexPath) as! DateSelectionCell

            cell.configure(date: research?.nextReportDate, path: indexPath, delegate: controller)

            return cell

        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "researchCell", for: indexPath) as! ResearchCell

            cell.configure(delegate: controller, path: indexPath)

            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if sectionTitles![indexPath.section].contains("description") {
            return 150
        } else if sectionTitles![indexPath.section].contains("Assets") {
            return 44
        } else if sectionTitles![indexPath.section].contains("Size") {
            return 44
        } else if sectionTitles![indexPath.section].contains("Date") {
            return 60
        } else if sectionTitles![indexPath.section].contains("Industry") {
            return 44
        } else if sectionTitles![indexPath.section].contains("products") {
            return 70
        } else if sectionTitles![indexPath.section].contains("Insider") {
            return 44
        } else if sectionTitles![indexPath.section].contains("news") {
            return 60
        } else if sectionTitles![indexPath.section].contains("mean earnings") {
            return 44
        } else if sectionTitles![indexPath.section].contains("earnings range") {
            return 120
        } else if sectionTitles![indexPath.section].contains("share prices") {
            return 44
        } else if sectionTitles![indexPath.section].contains("outlook") {
            return 150
        } else if sectionTitles![indexPath.section].contains("would you buy") {
            return 44
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
            label.textColor = UIColor.systemOrange
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
    
    func downloadResearchData() {
        
        progressView = DownloadProgressView.instanceFromNib()
        progressView?.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(progressView!)
        
        let margins = view.layoutMarginsGuide

        progressView?.widthAnchor.constraint(equalTo: margins.widthAnchor, multiplier: 0.8).isActive = true
        progressView?.centerXAnchor.constraint(equalTo: margins.centerXAnchor).isActive = true
        progressView?.heightAnchor.constraint(equalTo: margins.heightAnchor, multiplier: 0.2).isActive = true
        progressView?.centerYAnchor.constraint(equalTo: margins.centerYAnchor).isActive = true

        progressView?.delegate = self
        progressView?.title.text = "Downloading..."
                
        guard let symbol = share?.symbol else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo:  "research data download reauested for \(String(describing: share)) but symbol not available")
            return
 
        }
        guard let shortName = share?.name_short else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "research data download reauested for \(symbol) but short name not available")
            return
        }
        guard let shareID = share?.objectID else {
            ErrorController.addInternalError(errorLocation: #function, errorInfo: "research data download reauested for \(symbol) but objectID for share not available")
            return

        }
        
        let downloadJob = DownloadOptions.researchDataOnly
        
        Task {
            progressView?.delegate?.allTasks = MacrotrendsScraper.countOfRowsToDownload(option: downloadJob) + YahooPageScraper.countOfRowsToDownload(option: downloadJob)
            
                do {
     
                    // TODO: non-US stocks  needs review
                    if symbol.contains(".") {
                        
                        await YahooPageScraper.dataDownloadAnalyseSave(symbol: symbol, shortName: shortName, shareID: shareID, option: downloadJob, progressDelegate: self, downloadRedirectDelegate: nil)
                        
                        try Task.checkCancellation()

                        await MacrotrendsScraper.dataDownloadAnalyseSave(shareSymbol: symbol, shortName: shortName, shareID: shareID, downloadOption: downloadJob, downloadRedirectDelegate: nil)

                    }
                    // US stocks
                    else {

                        await YahooPageScraper.dataDownloadAnalyseSave(symbol: symbol, shortName: shortName, shareID: shareID, option: downloadJob, progressDelegate: self, downloadRedirectDelegate: nil)
                        
                        try Task.checkCancellation()

                        await MacrotrendsScraper.dataDownloadAnalyseSave(shareSymbol: symbol, shortName: shortName, shareID: shareID, downloadOption: downloadJob, progressDelegate: self ,downloadRedirectDelegate: nil)

                    }
                } catch {
                    ErrorController.addInternalError(errorLocation: #function, systemError: error ,errorInfo: "research data download for \(symbol) failed.")
                    progressView?.delegate?.downloadError(error: error.localizedDescription)
                }
                
            NotificationCenter.default.removeObserver(self)
            progressView?.delegate?.downloadComplete()
        }
        
    }
        
}

extension ResearchTVC: ProgressViewDelegate {
    
    func progressUpdate(allTasks: Int, completedTasks: Int) {
        self.allDownloadTasks = allTasks
        self.completedDownloadTasks = completedTasks
        progressView?.updateProgress(tasks: allTasks, completed: completedTasks)
    }
    
    func cancelRequested() {
        allTasks = 0
        self.progressView?.removeFromSuperview()
    }
    
    func downloadComplete() {
        self.progressView?.removeFromSuperview()
    }
    
    func downloadError(error: String) {
        self.progressView?.removeFromSuperview()
    }
    
    func taskCompleted() {
        self.progressView?.delegate?.completedTasks += 1
        
        if self.progressView?.delegate?.completedTasks ?? 0 >= self.progressView?.delegate?.allTasks ?? 0 {
            self.progressView?.delegate?.downloadComplete()
        }
        
        progressView?.updateProgress(tasks: allDownloadTasks, completed: completedDownloadTasks)
    }
    
    var allTasks: Int {
        get {
            self.allDownloadTasks
        }
        set (newValue) {
            self.allDownloadTasks = newValue
        }
    }
    
    var completedTasks: Int {
        get {
            self.completedDownloadTasks
        }
        set (newValue) {
            self.completedDownloadTasks = newValue
        }
    }
    
    
}
