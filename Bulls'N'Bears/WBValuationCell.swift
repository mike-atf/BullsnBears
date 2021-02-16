//
//  WBValuationCell.swift
//  Bulls'N'Bears
//
//  Created by aDav on 16/02/2021.
//

import UIKit

class WBValuationCell: UITableViewCell {

    @IBOutlet var title: UILabel!
    @IBOutlet var detail: UILabel!
    @IBOutlet var infoButton: UIButton!
    
    var infoText: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        self.title.text = ""
        self.detail.text = ""
        self.infoText = nil
        self.infoButton.isHidden = false
    }
    
    public func configure(title: String, detail: String, infoText: [String]?) {
        self.title.text = title
        self.detail.text = detail
        
        if let errors = infoText {
//            infoButton.setImage(UIImage(systemName: "exclamationmark.triangle"), for: .normal)
//            infoButton.tintColor = UIColor.systemYellow
            self.infoText = String()
            for text in errors {
                self.infoText! += text + "\n"
            }
        }
        else {
            infoButton.isHidden = true
        }
        
        
    }
    
    @IBAction func infoButtonAction(_ sender: Any) {
        
    }
    
}
