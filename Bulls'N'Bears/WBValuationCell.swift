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
    
    var errors: [String]?
    weak var delegate: WBValuationCellDelegate?
        
    override func prepareForReuse() {
        self.title.text = ""
        self.detail.text = ""
        self.errors = nil
        self.infoButton.isHidden = false
    }
    
    public func configure(title: String, detail: String, detailColor: UIColor?=nil, errors: [String]?, delegate: WBValuationCellDelegate) {
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
        
        
    }
    
    @IBAction func infoButtonAction(_ sender: UIButton) {
        delegate?.infoButtonAction(errors: self.errors, sender: sender)
    }
    
}
