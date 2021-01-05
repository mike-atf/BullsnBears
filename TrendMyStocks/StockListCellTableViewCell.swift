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
        formatter.includesApproximationPhrase = true
        return formatter
    }()

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    public func configureCell(indexPath: IndexPath, delegate: StockListCellDelegate, stock: Stock, valuation: DCFValuation?) {
        self.indexPath = indexPath
        self.stock = stock
        self.cellDelegate = delegate
        
        title.text = stock.name
        let timeSinceLastStockDate = Date().timeIntervalSince(stock.dailyPrices.last!.tradingDate)
        detail.text = timeFormatter.string(from: timeSinceLastStockDate)
        if let validValuation = valuation {
            valuationButton.setBackgroundImage(nil, for: .normal)
            valuationButton.setTitle(validValuation.returnIvalue(), for: .normal)
        }

    }
    
    @IBAction func valuationButtonAction(_ sender: UIButton) {
        cellDelegate.valuationButtonPressed(indexpath: self.indexPath)
    }
}
