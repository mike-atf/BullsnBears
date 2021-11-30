//
//  SettingsCell.swift
//  Bulls'N'Bears
//
//  Created by aDav on 28/11/2021.
//

import UIKit

class SettingsCell: UITableViewCell {

    @IBOutlet var title: UILabel!
    @IBOutlet var detail: UILabel!
    @IBOutlet var inconView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        self.accessoryType = .none
        self.title.text = " "
        self.detail.text = " "
    }
    
    func configure(title: String, detail: String?, accessory: Bool) {
        self.title.text = title
        self.detail.text = detail
        if accessory {
            self.accessoryType = .disclosureIndicator
        }
    }
}
