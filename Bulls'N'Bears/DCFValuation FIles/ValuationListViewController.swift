//
//  ValuationListViewController.swift
//  TrendMyStocks
//
//  Created by aDav on 03/01/2021.
//

import UIKit

protocol ValuationListDelegate: AnyObject {
    func valuationComplete(listView: ValuationListViewController, r1Valuation: Rule1Valuation?)
}

class ValuationListViewController: UITableViewController, AlertViewDelegate {
    
    var delegate: ValuationListDelegate?
    var sourceIndexPath: IndexPath!
//    var stock: Stock!
    var share: Share!
    var valuationMethod: ValuationMethods!
    var sectionSubtitles: [String]?
    var sectionTitles: [String]?
    var rowTitles: [[String]]?

    var valuationController: CombinedValuationController!
    weak var helper: CombinedValuationController!
    var progressView: DownloadProgressView?
    
    var showDownloadCompleteMessage = false // used because asking alertConotrller to show message in 'dataUpdated' right after reloadData causes 'table view or one of its superviews has not been added to a window' error, assuming that reloading rows still takes place while the alertView is in front. so instead show this when the viewDidLayouSubviews, using this bool
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "ValuationTableViewCell", bundle: nil), forCellReuseIdentifier: "valuationTableViewCell")

        valuationController = CombinedValuationController(share: share, valuationMethod: valuationMethod, listView: self)
        self.helper = valuationController
        
        sectionTitles = helper.sectionTitles()
        sectionSubtitles = helper.sectionSubTitles()
        rowTitles = helper.rowTitles()

        NotificationCenter.default.addObserver(self, selector: #selector(dataUpdated), name: NSNotification.Name(rawValue: "UpdateValuationData"), object: nil)
        
        tableView.reloadData()

    }
    // MARK: - Table view data source
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        if showDownloadCompleteMessage {
            var title = String()
            var message = String()
            if valuationMethod == .dcf {
                title = "Stock valuation data downloaded successfully from Yahoo"
                message = "Check the numbers, and adapt the two 'adjusted sales growth predictions' at the bottom of this list.\n\nSave after adjusting, using the blue button at the bottom!"
            } else {
                title = "Stock valuation data downloaded successfully from MacroTrends and Yahoo"
                message = "Check the numbers and adapt the two 'adjusted sales growth predictions' at the bottom of this list.\n\nSave after adjusting, using the blue button at the bottom!"
            }
            AlertController.shared().showDialog(title: title, alertMessage: message, viewController: self)
            showDownloadCompleteMessage = false
        }
    }

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

        
        let info = helper.cellInfo(indexPath: indexPath)
        cell.configure(info: info, indexPath: indexPath, method: valuationMethod, delegate: helper)
        
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if valuationMethod == .dcf {
            if [3,4,9].contains(section) { return 20 }
            else if [7].contains(section) { return 40 }
            else { return (UIDevice().userInterfaceIdiom == .pad) ? 70 : 60 }
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
        let smallFontSize: CGFloat = (UIDevice().userInterfaceIdiom == .pad) ? 16 : 12
        
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
        
        if section == 0 {
            let donwloadButton = UIButton()
            donwloadButton.setBackgroundImage(UIImage(systemName: "icloud.and.arrow.down.fill"), for: .normal)
            donwloadButton.addTarget(self, action: #selector(downloadValuationData), for: .touchUpInside)
            donwloadButton.translatesAutoresizingMaskIntoConstraints = false
            header.addSubview(donwloadButton)

            donwloadButton.centerYAnchor.constraint(equalTo: margins.centerYAnchor).isActive = true
            donwloadButton.trailingAnchor.constraint(equalTo: margins.trailingAnchor).isActive = true
            donwloadButton.heightAnchor.constraint(equalTo: margins.heightAnchor, multiplier: 0.6).isActive = true
            donwloadButton.widthAnchor.constraint(equalTo: donwloadButton.heightAnchor).isActive = true

        }
        
        if section == (sectionTitles?.count ?? 0) - 1 {
            let saveButton = UIButton()
            saveButton.setBackgroundImage(UIImage(systemName: "square.and.arrow.down"), for: .normal)
            saveButton.addTarget(self, action: #selector(saveValuation), for: .touchUpInside)
            saveButton.translatesAutoresizingMaskIntoConstraints = false
            header.addSubview(saveButton)

            saveButton.centerYAnchor.constraint(equalTo: margins.centerYAnchor).isActive = true
            saveButton.trailingAnchor.constraint(equalTo: margins.trailingAnchor).isActive = true
            saveButton.heightAnchor.constraint(equalTo: margins.heightAnchor, multiplier: 0.6).isActive = true
            saveButton.widthAnchor.constraint(equalTo: saveButton.heightAnchor).isActive = true
        }

        return header
        
    }
    
    @objc
    func saveValuation() {
        
        // after 'save' button tapped in Val List VC
        
        if let alerts = helper.saveValuation() {
            var message = alerts.first!
            for i in 1..<alerts.count {
                message = message + "\n\n" + alerts[i]
            }
            AlertController.shared().showDialog(title: "Caution" , alertMessage: message, viewController: self ,delegate: self)
        } else {
            // important - these will otherwise stay in memory
            if let analyser = self.valuationController.webAnalyser {
                NotificationCenter.default.removeObserver(analyser)
                NotificationCenter.default.removeObserver(self)
            }

            self.valuationController.removeObjectsFromMemory()
            
            if valuationMethod == .rule1 {
                delegate?.valuationComplete(listView: self, r1Valuation: share.rule1Valuation)
            }
            else {
                delegate?.valuationComplete(listView: self, r1Valuation: nil)
            }
        }
    }
    
    @objc
    func downloadValuationData(_ button: UIButton) {
        
        button.isEnabled = false
        
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
                
        helper.startDataDownload()
        
    }
    
    func alertWasDismissed() {
        
        delegate?.valuationComplete(listView: self, r1Valuation: valuationController.valuation as? Rule1Valuation)
    }
    
    public func helperUpdatedRows(paths: [IndexPath]) {
        
        tableView.reloadRows(at: paths, with: .none)
    }
    
    public func helperAskedToEnterNextTextField(targetPath: IndexPath) {
        
        if let targetCell = tableView.cellForRow(at: targetPath) as? ValuationTableViewCell {
            targetCell.enterTextField()
        }
        else if let targetCell = tableView.dequeueReusableCell(withIdentifier: "valuationTableViewCell", for: targetPath) as? ValuationTableViewCell {
            targetCell.enterTextField()

        }
    }
    
    @objc
    func dataUpdated(_ notification: Notification) {
                
        self.valuationController.webAnalyser = nil
        
        if (sectionTitles?.count ?? 0) > 0 {
            tableView.reloadData()
        }
        
        if let errorList = notification.object as? [String] {
            
            if errorList.count > 0 {
                var message = errorList.first!
                for error in errorList {
                    message += "\n " + error
                }
                AlertController.shared().showDialog(title: "Some data search errors occurred", alertMessage: message, viewController: self)
            }
            else {
                showDownloadCompleteMessage = true
            }
        }
    }
}


extension ValuationListViewController: ProgressViewDelegate {
    
    func downloadError(error: String) {
        self.progressView?.updateProgress(tasks: 1, completed: 1)
        self.progressView?.title.text = error
        self.progressView?.cancelButton.setTitle("OK", for: .normal)
    }
    
    
    func cancelRequested() {
        downloadComplete()
        helper.stopDownload()
    }
        
    func progressUpdate(allTasks: Int, completedTasks: Int) {
        self.progressView?.updateProgress(tasks: allTasks, completed: completedTasks)
    }
    
    func downloadComplete() {
        
        // progressView calls this on it's own once completedTasks >= tasks
        self.progressView?.delegate = nil
        progressView?.removeFromSuperview()
        progressView = nil
    }
    
    
}

