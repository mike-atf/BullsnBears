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
    var controller: ComparisonController!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        rowTitleLabel.text = "Row title"
        for label in valueLabels ?? [] {
            label.removeFromSuperview()
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(controller: ComparisonController, cellPath: IndexPath) {
        
        rowTitleLabel.text = controller.titleForRow(for: cellPath)
        
        let strings = controller.rowTexts(forPath: cellPath)
        valueLabels = [UILabel]()

        var count: CGFloat = 0
        var previousLabel: UILabel?
        for string in strings {
            
            let label: UILabel = {
                let label = UILabel()
                label.translatesAutoresizingMaskIntoConstraints = false
                label.font = UIFont.preferredFont(forTextStyle: .body)
                if cellPath == IndexPath(row: 1, section: 0) {
                    label.numberOfLines = 0
                }
                label.text = string
                label.sizeToFit()
                return label
            }()
            self.contentView.addSubview(label)
            valueLabels?.append(label)
            
            let margins = contentView.layoutMarginsGuide
            
            label.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 300 + 150*count).isActive = true
            label.centerYAnchor.constraint(equalTo: margins.centerYAnchor).isActive = true
            if previousLabel != nil {
                previousLabel?.trailingAnchor.constraint(equalTo: label.leadingAnchor, constant: 10).isActive = true
            }
            previousLabel = label
            count += 1
        }
        
        
    }

}
