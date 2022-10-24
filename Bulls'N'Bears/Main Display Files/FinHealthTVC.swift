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
    var spinner: UIActivityIndicatorView?
    var downloadComplete = false
    var sectionTitles = ["Health score ","Key values", "Profitability", "Efficiency", "Liquidity", "Solvency"]
    var sectionSubtitles = ["","",
                            "A larger net margin, especially compared to industry peers, means a greater margin of financial safety, and also indicates a company is in a better financial position to commit capital to growth and expansion.",
                            " Operating margin considers a company's basic operational profit margin after deducting the variable costs of producing and marketing the company's products or services. Crucially, it indicates how well the company's management is able to control costs." ,
                            "Quick ratio = 'Quick assets' / Current liabiities.\n\nThis indicates the company’s ability to instantly use its assets that can be converted quickly to cash to pay down its current liabilities, it is also called the Acid Test ratio.\n\nCurrent ratio = 'Current assets' / Current liabiities.\n\nThis is a liquidity ratio that measures a company’s ability to pay short-term obligations or those due within one year.",
                            "Solvency is a company's ability to meet its debt obligations on an ongoing basis, not just over the short term. Solvency ratios calculate a company's long-term debt in relation to its assets or equity.\n\nA lower D/E ratio means more of a company's operations are being financed by shareholders rather than by creditors. This is a plus since shareholders do not charge interest.\n\nD/E ratios vary widely between industries. However, regardless of the specific nature of a business, a downward trend over time in the D/E ratio is a good indicator a company is on increasingly solid financial ground.\n\n If a company has a negative D/E ratio, this means it has negative shareholder equity. The company’s liabilities exceed its assets. In most cases, this would be considered a sign of high risk and an incentive to seek bankruptcy protection."]

    override func viewDidLoad() {
        super.viewDidLoad()

        controller = FinHealthController(share: share, finHealthTVC: self)
        
        tableView.register(UINib(nibName: "FinHealthCell", bundle: nil), forCellReuseIdentifier: "finHealthCell")
        
        let nameButton = UIBarButtonItem(title: (share?.symbol ?? "") + " Financial Health", style: .plain, target: nil, action: nil)
        self.navigationItem.rightBarButtonItem = nameButton
        
        spinner = UIActivityIndicatorView()
    }
   
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

        return 6
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if section == 0 {
            return 0
        } else if section == 1 {
            return 5
        } else if section == 2 {
            return 1
        } else if section == 3 {
            return 1
        } else if section == 4 {
            return 2
        } else if section == 5 {
            return 1
        } else {
            return 0
        }

    }
        
    func stopActivityView() {
        downloadComplete = true
        spinner?.stopAnimating()
        spinner?.removeFromSuperview()
        spinner = nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "finHealthCell", for: indexPath) as! FinHealthCell

        var minimumChartTime: TimeInterval?
        
        if indexPath.section - 1 > 0 {
            minimumChartTime = 2 * year
        } else {
            minimumChartTime = month
        }
        
        let chartData = controller.dataForPath(indexPath: indexPath)
        cell.configure(path: indexPath, primaryData: chartData, chartMinimumTime: minimumChartTime)

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = UIView()
        let height: CGFloat = (UIDevice().userInterfaceIdiom == .pad) ? 40 : 50
        header.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: height)
        
        let largeFontSize: CGFloat = (UIDevice().userInterfaceIdiom == .pad) ? 18 : 18
        
        var title = sectionTitles[section]
        if section == 0 {
            title = sectionTitles[section] + ": " + controller.returnHealthScore$()
        }
        
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

        let margins = header.layoutMarginsGuide
        
        titleLabel.topAnchor.constraint(equalTo: margins.topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(greaterThanOrEqualTo: margins.trailingAnchor).isActive = true

        if section > 1 {
            
            var config = UIButton.Configuration.borderless()
                config.image = UIImage(systemName: "info.circle")
            
            let infoButton = UIButton(configuration: config, primaryAction: nil)
            infoButton.tag = section
            infoButton.addTarget(self, action: #selector(showSectionInfo(button:)), for: .touchUpInside)
            
            infoButton.translatesAutoresizingMaskIntoConstraints = false
            header.addSubview(infoButton)

            infoButton.centerYAnchor.constraint(equalTo: margins.centerYAnchor).isActive = true
            infoButton.trailingAnchor.constraint(equalTo: margins.trailingAnchor).isActive = true
        } else {
            
            if !downloadComplete {
                spinner?.style = .medium
                spinner?.color = UIColor.label
                spinner?.translatesAutoresizingMaskIntoConstraints = false
                header.addSubview(spinner!)
                
                spinner?.topAnchor.constraint(equalTo: margins.topAnchor).isActive = true
                spinner?.bottomAnchor.constraint(equalTo: margins.bottomAnchor).isActive = true
                spinner?.widthAnchor.constraint(equalTo: spinner!.widthAnchor).isActive = true
                spinner?.centerXAnchor.constraint(equalTo: margins.centerXAnchor).isActive = true
                
                spinner?.startAnimating()
            }
        }

        return header
    }
    
    @objc
    func showSectionInfo(button: UIButton) {
        
        if let infoView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ValuationErrorsTVC") as? ValuationErrorsTVC {
            
            infoView.modalPresentationStyle = .popover
            infoView.preferredContentSize = CGSize(width: self.view.frame.width * 0.75, height: self.view.frame.height * 0.3)

            let popUpController = infoView.popoverPresentationController
            popUpController!.permittedArrowDirections = .any
            popUpController!.sourceView = button
            infoView.loadViewIfNeeded()
            
            infoView.errors = [sectionSubtitles[button.tag]]
            infoView.firstCellHeight = infoView.preferredContentSize.height
            
            present(infoView, animated: true, completion:  nil)
        }

    }

}
