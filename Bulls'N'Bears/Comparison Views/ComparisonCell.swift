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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        rowTitleLabel.text = "Row title"
        valueLabels?.removeAll()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(rowTitle: String, values: [Double?]) {
        
        rowTitleLabel.text = rowTitle
        
        
        for value in values {
            
        }
    }

}
