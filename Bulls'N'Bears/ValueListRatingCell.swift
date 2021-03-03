//
//  ValueListRatingCell.swift
//  Bulls'N'Bears
//
//  Created by aDav on 02/03/2021.
//

import UIKit

class ValueListRatingCell: UITableViewCell {
    
    @IBOutlet var ratingButton: WBVRatingButton!
    @IBOutlet var label: UILabel!
    var rating:Int!
    var wbvParameter: String!
    
    let ratingDescriptions = ["Consistent zero or negative growth, trend maintained",
        "Consistent zero or negative growth, but recent trend reversed / Inconsistent zero or negative growth",
        "Inconsistent zero or negative growth, recent trend upwards",
        "Inconsistent growth > 0, recent trend downwards",
        "Inconsistent growth > 0, recent trend maintained or higher",
        "Inconsistent growth >10% or consistent growth > 0, recent trend downwards",
        "Inconsistent growth >10% or consistent growth > 0, recent maintained or higher",
        "Inconsistent growth >15%, or consistent growth > 10%, recent trend downwards",
        "Inconsistent growth >15%, or consistent growth > 10%, recent trend maintained or higher",
        "Consistent growth >15%,  recent downward trend",
        "Consistent growth >15%,  recent trend maintained or higher"]
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(rating: Int, ratingUpdateDelegate: RatingButtonDelegate, parameter: String) {
        
        self.rating = rating
        self.wbvParameter = parameter
        
        if self.rating < 0 { self.rating = 0 }
        else if self.rating > 10 { self.rating = 10 }
        ratingButton.configure(rating: self.rating, delegate: ratingUpdateDelegate, parameter: parameter)
        label.text = ratingDescriptions[self.rating]
        
    }
    
}
