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
    
    let ratingDescriptions = ["Consistent zero or negative growth",
                              "Inconsistent growth <= 0%, or \nConsistent growth <= 0%, recent trend up,",
                              "Inconsistent growth <= 0%, recent trend up",
                              "Inconsistent growth 0-10%\nrecent trend down",
                              "Inconsistent growth 0-10%\nrecent trend stable or up",
                              "Consistent growth 0-10% or \nInconsistent growth 10-15% recently down",
                              "Consistent growth 0-10% or\nInconsistent growth 10-15% recently up",
                              "Consistent growth 10-15% or\nInconsistent growth >15% recently down",
                              "Consistent growth 10-15% or \nInconsistent growth >15% recently up",
                              "Consistent growth >15%\nrecently down",
                              "Consistent growth >15%"
                      ]
    
    let reverseRatingDescriptions = ["Consistent cost reduction >15%",
        "Consistent cost reduction >15%\nrecently dropping",
        "Inconsistent cost reduction >15% or\nConsistent reduction 10-15%",
        "Inconsistent cost reduction 10-15%, or\nConsistent reduction 0-10%, trend stable",
        "Inconsistent cost reduction 0-10%\nrecently stable or rising",
        "Inconsistent cost reduction 0-10%\nrecently dropping",
        "Inconsistent cost rise 0-10%\nrecently dropping",
        "Inconsistent cost rise 0-10% \nrecently increasing",
        "Inconsistent cost rise 10-15% \nrecently dropping",
        "Consistent cost rise 0-10% or\nInconsistent rise 10-15%, recently increasing",
        "Consistent cost rise 10-15% or\nInconsistent rise >15%, recently increasing",
        "Consistent cost rise >15%"]

    var ratingsDescriptionsUsed = [String]()
        
    func configure(rating: Int, ratingUpdateDelegate: RatingButtonDelegate, parameter: String, reverseRatingOrder: Bool?=false) {
        
        self.rating = rating
        self.wbvParameter = parameter
                
        if self.rating < 0 { self.rating = 0 }
        else if self.rating > 10 { self.rating = 10 }
        ratingButton.configure(rating: self.rating, delegate: ratingUpdateDelegate, parameter: parameter, cell: self)
        
        self.ratingsDescriptionsUsed = (reverseRatingOrder ?? false) ? reverseRatingDescriptions.reversed() : ratingDescriptions
        label.text = "\(rating)/10 - " + ratingsDescriptionsUsed[self.rating]

    }
    
    func updateText(rating: Int) {
        self.rating = rating
        label.text = "\(rating)/10 - " + ratingsDescriptionsUsed[self.rating]
    }
    
}
