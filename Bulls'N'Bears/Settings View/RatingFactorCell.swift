//
//  RatingFactorCell.swift
//  Bulls'N'Bears
//
//  Created by aDav on 28/11/2021.
//

import UIKit

protocol RatingFactorCellDelegate {
//    func userCompletedSetting(value: Double, path: IndexPath)
    func userChangedSetting(value: Double, path: IndexPath)
}

class RatingFactorCell: UITableViewCell {

    @IBOutlet var title: UILabel!
    @IBOutlet var detail: UILabel!
    @IBOutlet var slider: UISlider!
    
    var indexPath: IndexPath?
    var cellDelegate: RatingFactorCellDelegate!
    var value: Double?
    
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
        self.indexPath = nil
    }
    
    func configure(value: Double?, totalValue: Double, title: String, indexPath: IndexPath, delegate: RatingFactorCellDelegate) {
        
        self.title.text = title
        self.value = value
        self.indexPath = indexPath
        if let valid = value {
            self.slider.value = Float(valid)
            if valid > 0 {
                self.detail.text = numberFormatterWith1Digit.string(from: valid as NSNumber)
            }
            else {
                self.detail.text = "Off"
            }
        }
        self.cellDelegate = delegate
    }
    
    func adjustValue(value: Double) {
        
        self.value = value
        if value > 0 {
            self.detail.text = numberFormatterWith1Digit.string(from: value as NSNumber)
        }
        else {
            self.detail.text = "Off"
        }

    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
//        self.detail.text = numberFormatter2Decimals.string(from: NSNumber(value: sender.value))
        cellDelegate.userChangedSetting(value: Double(sender.value), path: self.indexPath!)
    }
}
