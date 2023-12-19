//
//  ErrorLogListCell.swift
//  Bulls'N'Bears
//
//  Created by aDav on 11/01/2021.
//

import UIKit

class ErrorLogListCell: UITableViewCell {

    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var sysErrLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
