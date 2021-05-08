//
//  ComparisonCell.swift
//  Bulls'N'Bears
//
//  Created by aDav on 28/04/2021.
//

import UIKit

class ComparisonCell: UITableViewCell {

    @IBOutlet var rowTitleLabel: UILabel!
    
    var valueLabels: [UILabel]?
    var textViews: [UITextView]?
    var trendIcons: [TrendIconView2]?
    var controller: ComparisonController!
    
    let columnWidth: CGFloat = 200
    let firstColumnInset: CGFloat = 300
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }
    
    override func prepareForReuse() {
        rowTitleLabel.text = "Row title"
        for label in valueLabels ?? [] {
            label.removeFromSuperview()
        }
        for view in textViews ?? [] {
            view.removeFromSuperview()
        }
        for view in trendIcons ?? [] {
            view.removeFromSuperview()
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    func configure(controller: ComparisonController, cellPath: IndexPath) {
        self.controller = controller
        rowTitleLabel.text = controller.titleForRow(for: cellPath)

        if cellPath == IndexPath(row: 0, section: 0) {
            createTextView(cellPath: cellPath)
        }
        else if cellPath.section < 3 {
            createLabels(cellPath: cellPath)
        }
        else {
            createIconCellContent(cellPath: cellPath)
        }
    }
    
    private func createLabels(cellPath: IndexPath) {
        
        let strings = controller.rowTexts(forPath: cellPath)
        valueLabels = [UILabel]()

        var count: CGFloat = 0
        let margins = contentView.layoutMarginsGuide
        
        var previousLabel: UILabel?
        for string in strings {
            
            let label: UILabel = {
                let label = UILabel()
                label.translatesAutoresizingMaskIntoConstraints = false
                label.font = UIFont.preferredFont(forTextStyle: .body)
                label.text = string
                label.sizeToFit()
                return label
            }()
            self.contentView.addSubview(label)
            valueLabels?.append(label)
            
            label.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: firstColumnInset + columnWidth*count).isActive = true
            label.centerYAnchor.constraint(equalTo: margins.centerYAnchor).isActive = true
            if previousLabel != nil {
                previousLabel?.trailingAnchor.constraint(equalTo: label.leadingAnchor, constant: 10).isActive = true
            }
            previousLabel = label
            count += 1
        }

    }
    
    private func createTextView(cellPath: IndexPath) {
        
        let strings = controller.rowTexts(forPath: cellPath)
        textViews = [UITextView]()

        var count: CGFloat = 0
        let margins = contentView.layoutMarginsGuide
        
        for string in strings {
            
            let textView: UITextView = {
                let view = UITextView()
                view.translatesAutoresizingMaskIntoConstraints = false
                view.font = UIFont.systemFont(ofSize: 12)
                view.text = string
                view.sizeToFit()
                view.showsHorizontalScrollIndicator = false
                return view
            }()
            self.contentView.addSubview(textView)
            textViews?.append(textView)
            
            textView.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: firstColumnInset + columnWidth * count).isActive = true
            textView.topAnchor.constraint(equalTo: margins.topAnchor).isActive = true
            textView.bottomAnchor.constraint(equalTo: margins.bottomAnchor).isActive = true
            textView.widthAnchor.constraint(equalToConstant: 140).isActive = true
            count += 1
        }

    }
    
    private func createIconCellContent(cellPath: IndexPath) {
        
        let strings = controller.rowTexts(forPath: cellPath)
        let (correlations, values) = controller.fundamentals(forPath: cellPath)
        trendIcons = [TrendIconView2]()
        valueLabels = [UILabel]()

        var count: CGFloat = 0
        let margins = contentView.layoutMarginsGuide
        
        for string in strings {
            
            let iconView = TrendIconView2(frame: CGRect.zero)
            iconView.translatesAutoresizingMaskIntoConstraints = false
            self.contentView.addSubview(iconView)
            trendIcons?.append(iconView)
            
            iconView.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: firstColumnInset + columnWidth * count).isActive = true
            iconView.centerYAnchor.constraint(equalTo: margins.centerYAnchor).isActive = true
            iconView.heightAnchor.constraint(equalTo: margins.heightAnchor, multiplier: 1.0).isActive = true
            iconView.widthAnchor.constraint(equalTo: iconView.heightAnchor).isActive = true
            
            var correlation: Correlation?
            var iconValues: [Double]?
            if correlations?.count ?? 0 > Int(count) {
                correlation = correlations?[Int(count)]
            }
            if values?.count ?? 0 > Int(count) {
                iconValues = values?[Int(count)]
            }
            iconView.configure(correlation: correlation, wbParameters: iconValues)

            let label: UILabel = {
                let label = UILabel()
                label.translatesAutoresizingMaskIntoConstraints = false
                label.font = UIFont.preferredFont(forTextStyle: .body)
                label.text = string
                label.sizeToFit()
                return label
            }()
            self.contentView.addSubview(label)
            valueLabels?.append(label)
            
            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 5).isActive = true
            label.centerYAnchor.constraint(equalTo: margins.centerYAnchor).isActive = true
            label.widthAnchor.constraint(equalToConstant: 75).isActive = true
            count += 1
        }

    }

}
