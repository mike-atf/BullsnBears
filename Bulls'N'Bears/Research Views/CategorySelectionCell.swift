//
//  CategorySelectionCell.swift
//  Bulls'N'Bears
//
//  Created by aDav on 18/05/2021.
//

import UIKit

class CategorySelectionCell: UITableViewCell {

    @IBOutlet var categoriesView: SortView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
