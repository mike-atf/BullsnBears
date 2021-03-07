//
//  WBValuationCell.swift
//  Bulls'N'Bears
//
//  Created by aDav on 16/02/2021.
//

import UIKit

protocol WBValuationCellDelegate: NSObject {
    func infoButtonAction(errors: [String]?, sender: UIButton)
    
}

class WBValuationCell: UITableViewCell {

    @IBOutlet var title: UILabel!
    @IBOutlet var detail: UILabel!
    @IBOutlet var infoButton: UIButton!
    @IBOutlet var starView: UIImageView!
    @IBOutlet var trendIcon: TrendIconView!
    @IBOutlet var ratingLabel: UILabel!
    
    var errors: [String]?
    weak var delegate: WBValuationCellDelegate?
    var ratingLabelColor = UIColor.label
        
    override func prepareForReuse() {
        self.title.text = ""
        self.detail.text = ""
        self.errors = nil
        self.infoButton.isHidden = false
        self.starView.isHidden = true
        self.ratingLabel.isHidden = true
        self.trendIcon.isHidden = true
        self.ratingLabel.textColor = UIColor.label
    }
    
    public func configure(title: String, detail: String, detailColor: UIColor?=nil, errors: [String]?, delegate: WBValuationCellDelegate, userEvaluation: UserEvaluation?, correlation: Correlation?) {
        self.title.text = title
        self.detail.text = detail
        self.detail.textColor = detailColor ?? UIColor.label
        self.delegate = delegate
        self.errors = errors
        
        if errors != nil {
            if errors?.count ?? 0 > 0 {
                infoButton.isHidden = false
            } else {
                infoButton.isHidden = true
            }
        }
        else {
            infoButton.isHidden = true
        }
        
        if let valid = userEvaluation {

            if let validRating = valid.userRating() {
                if validRating > 3 {
                    self.ratingLabel.textColor = UIColor.black
                }
                
                starView.isHidden = false
                starView.tintColor = valid.ratingColor()
                ratingLabel.isHidden = false
                ratingLabel.text = numberFormatterNoFraction.string(from: (valid.userRating() ?? 0) as NSNumber)
            }
            else {
                starView.isHidden = true
                self.ratingLabel.isHidden = true
            }
        } else {
            starView.isHidden = true
            self.ratingLabel.isHidden = true
        }
        
        if let valid = correlation {
            trendIcon.isHidden = false
            trendIcon.configure(correlation: valid)
        }
        else {
            trendIcon.isHidden = true
        }
    }
    
    @IBAction func infoButtonAction(_ sender: UIButton) {
        delegate?.infoButtonAction(errors: self.errors, sender: sender)
    }
    
}
