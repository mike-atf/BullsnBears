//
//  DateSelectionCell.swift
//  DateSelectionCell
//
//  Created by aDav on 22/09/2021.
//

import UIKit

class DateSelectionCell: UITableViewCell {

    @IBOutlet var datePicker: UIDatePicker!
    var cellPath: IndexPath!
    var cellDelegate: ResearchCellDelegate!

    override func awakeFromNib() {
        super.awakeFromNib()
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        datePicker.contentHorizontalAlignment = .leading
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(date: Date?, path: IndexPath, delegate: ResearchCellDelegate?) {
        
        self.cellPath = path
        self.cellDelegate = delegate
        if let valid = date {
            datePicker.date = valid
        }
    
    }
    
    @objc
    func dateChanged() {
        
        cellDelegate?.userEnteredDate(date: datePicker.date, cellPath: cellPath)
    }
    
}
