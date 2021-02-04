//
//  StockListCellTableViewCell.swift
//  TrendMyStocks
//
//  Created by aDav on 02/01/2021.
//

import UIKit

protocol StockListCellDelegate {
    func valuationButtonPressed(indexpath: IndexPath)
}

class StockListCellTableViewCell: UITableViewCell {

    @IBOutlet var title: UILabel!
    @IBOutlet var detail: UILabel!
    @IBOutlet var valuationButton: UIButton!
    
    var indexPath: IndexPath!
    var cellDelegate: StockListCellDelegate!
    var stock: Stock!
    
    let timeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day]
        formatter.unitsStyle = .brief
        formatter.zeroFormattingBehavior = .pad
        formatter.maximumUnitCount = 3
        formatter.includesApproximationPhrase = false
        return formatter
    }()
        
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        valuationButton.titleLabel?.numberOfLines = 0

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    public func configureCell(indexPath: IndexPath, delegate: StockListCellDelegate, stock: Stock) {
        self.indexPath = indexPath
        self.stock = stock
        self.cellDelegate = delegate
        
        title.text = stock.symbol
        let timeSinceLastStockDate = Date().timeIntervalSince(stock.dailyPrices.last!.tradingDate)
        detail.text = timeFormatter.string(from: timeSinceLastStockDate)
        
//        var buttonTitle: String?
        
//        if let validValuation = valuation {
//            if let intrinsicValue = validValuation.returnIValue() {
//                buttonTitle = "DCF -NA-"
//                if intrinsicValue > 0 {
//                    let iv$ = currencyFormatterNoGapNoPence.string(from: intrinsicValue as NSNumber) ?? "-"
//                    buttonTitle = "DCF: " + iv$
//                }
//            }
//        }
        
//        var r1Title = "R1: "
//        if let validValuation = r1Valuation {
//            if let stickerPrice = validValuation.stickerPrice() {
//                if stickerPrice > 0 {
//                    r1Title += (currencyFormatterNoGapNoPence.string(from: stickerPrice as NSNumber) ?? "--")
//                }
//                else { r1Title += "-NA-"}
//            }
//            if let score = validValuation.moatScore() {
//                if !score.isNaN {
//                    let n$ = percentFormatter0Digits.string(from: score as NSNumber) ?? ""
//                    r1Title = r1Title + " (moat: " + n$ + ")"
//                }
//            }
//            if buttonTitle == nil {
//                buttonTitle = r1Title
//            }
//            else {
//                buttonTitle! = buttonTitle! + "\n" + r1Title
//            }
//        }
//
//        if let validTitle = buttonTitle {
//            valuationButton.setImage(nil, for: .normal)
//            valuationButton.setTitle(validTitle, for: .normal)
//        }

    }
    
    @IBAction func valuationButtonAction(_ sender: UIButton) {
        cellDelegate.valuationButtonPressed(indexpath: self.indexPath)
    }
}
