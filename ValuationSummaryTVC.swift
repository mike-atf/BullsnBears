//
//  ValuationSummaryTVC.swift
//  Bulls'N'Bears
//
//  Created by aDav on 02/02/2021.
//

import UIKit

protocol ValuationSummaryDelegate: AnyObject {
    func valuationSummaryComplete(toDismiss: ValuationSummaryTVC?)
}

class ValuationSummaryTVC: UITableViewController {

    var sectionHeaderTitles = ["Valuation Summary", "Resulting Sticker price"]
    var sectionHeaderSubTitles = ["Adjust numbers if necessary", "(non-editable)"]
    var sectionsRowTitles = [["Future growth", "Future PE ratio"],["Sticker price"]]
    var share: Share!
    weak var delegate: ValuationSummaryDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "ValuationSummaryCell", bundle: nil), forCellReuseIdentifier: "valuationSummaryCell")

    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

        return sectionsRowTitles.count
    
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return sectionsRowTitles[section].count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "valuationSummaryCell", for: indexPath) as! ValuationSummaryCell

        
        var value: Double?
        var format: ValuationCellValueFormat!
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                value = share.rule1Valuation?.adjGrowthEstimates?.mean() ?? share.rule1Valuation?.growthEstimates?.mean()
                format = .percent
            }
            else if indexPath.row == 1 {
                
                let dataArrays = [share.rule1Valuation?.bvps ?? [], share.rule1Valuation?.eps ?? []]
                let (cleanedArrays, _) = ValuationDataCleaner.cleanValuationData(dataArrays: dataArrays, method: .rule1)
                
                if let futureGrowth = share.rule1Valuation?.futureGrowthEstimate(cleanedBVPS: cleanedArrays[0]) {
                    value = share.rule1Valuation?.futurePER(futureGrowth: futureGrowth)
                    format = .numberWithDecimals
                }
            }
        } else if let r1v = share.rule1Valuation {
            (value,_) = r1v.stickerPrice()
            format = .currency
        }
        
        cell.configure(title: sectionsRowTitles[indexPath.section][indexPath.row], value: value, format: format ,indexPath: indexPath, delegate: self)

        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 70
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
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
            label.text = sectionHeaderTitles[section]
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
            label.text = sectionHeaderSubTitles[section]
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
            let saveButton = UIButton()
            saveButton.setBackgroundImage(UIImage(systemName: "square.and.arrow.down"), for: .normal)
            saveButton.addTarget(self, action: #selector(completeValuation), for: .touchUpInside)
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
    func completeValuation() {

//        self.share.rule1Valuation?.save()

        // NEW
            for row in 0..<self.sectionsRowTitles.count {
                if let cell = self.tableView.cellForRow(at: IndexPath(row: row, section: 0)) as? ValuationSummaryCell {
                    cell.cellDelegate = nil
                }
            }
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? ValuationSummaryCell {
                cell.cellDelegate = nil
            }

            delegate?.valuationSummaryComplete(toDismiss: self)
    }

}

extension ValuationSummaryTVC: ValSummaryCellDelegate {
    
    func valueWasChanged(futurePER: Double?, futureGrowth: Double?) {
        
        guard futurePER != nil || futureGrowth != nil else {
            return
        }
        
        if let valid = futurePER {
            share.rule1Valuation?.adjFuturePE = valid
        }
        else if let valid = futureGrowth {
            share.rule1Valuation?.adjGrowthEstimates = [valid,valid]
        }
        
        self.tableView.reloadSections([1], with: .none)
    }
    
    
}
