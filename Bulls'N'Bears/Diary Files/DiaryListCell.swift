//
//  DiaryListCell.swift
//  Bulls'N'Bears
//
//  Created by aDav on 11/10/2021.
//

import UIKit

class DiaryListCell: UITableViewCell {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var transactionsCountLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    public func configure(share: Share) {
        self.titleLabel.text = share.symbol
        
        let transactionsNo = (share.transactions?.count ?? 0)
        var taText = numberFormatterWith1Digit.string(from: transactionsNo as NSNumber) ?? "-"
        let text = transactionsNo > 1 ? " transactions" : " transaction"
        taText += text
        
        transactionsCountLabel.text = taText
    }
}
