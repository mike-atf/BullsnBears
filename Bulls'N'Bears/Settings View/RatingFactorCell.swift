//
//  RatingFactorCell.swift
//  Bulls'N'Bears
//
//  Created by aDav on 28/11/2021.
//

import UIKit

protocol RatingFactorCellDelegate {
    func userCompletedSetting(value: Double, path: IndexPath)
}

class RatingFactorCell: UITableViewCell {

    @IBOutlet var title: UILabel!
    @IBOutlet var detail: UILabel!
    @IBOutlet var slider: UISlider!
    var indexPath: IndexPath!
    var cellDelegate: RatingFactorCellDelegate!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        self.slider.setValue(0, animated: false)
        self.detail.text = " "
        self.title.text = " "
    }
    
    func configure(value: Double?, title: String, indexPath: IndexPath, delegate: RatingFactorCellDelegate) {
        
        self.title.text = title
        if let valid = value {
            self.slider.value = Float(valid)
            self.detail.text = numberFormatterWith1Digit.string(from: valid as NSNumber)
        }
        self.cellDelegate = delegate
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        self.detail.text = numberFormatterWith1Digit.string(from: NSNumber(value: sender.value))
    }
    
    @IBAction func sliderValueSet(_ sender: UISlider) {
        cellDelegate.userCompletedSetting(value: Double(sender.value), path: self.indexPath)
    }
}
