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
        
        let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]
        var dateComponents = Calendar.current.dateComponents(components, from: Date())
        dateComponents.second = 0
        dateComponents.minute = 0
        dateComponents.hour = 0
        dateComponents.day = 1
        dateComponents.month = 1
        dateComponents.year = 2000
        let defaultDate = Calendar.current.date(from: dateComponents)!

        
        self.cellPath = path
        self.cellDelegate = delegate
        datePicker.date = date ?? defaultDate
    
    }
    
    @objc
    func dateChanged() {
        
        cellDelegate?.userEnteredDate(date: datePicker.date, cellPath: cellPath)
    }
    
}
