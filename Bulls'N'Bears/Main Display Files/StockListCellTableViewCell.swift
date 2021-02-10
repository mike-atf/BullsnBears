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
    
//    let timeFormatter: DateComponentsFormatter = {
//        let formatter = DateComponentsFormatter()
//        formatter.allowedUnits = [.day]
//        formatter.unitsStyle = .full
//        formatter.zeroFormattingBehavior = .pad
//        formatter.maximumUnitCount = 3
//        formatter.includesApproximationPhrase = false
//        return formatter
//    }()
    
    let timeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .numeric
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
        
    override func awakeFromNib() {
        super.awakeFromNib()
        valuationButton.titleLabel?.numberOfLines = 0
    }
    
    public func configureCell(indexPath: IndexPath, delegate: StockListCellDelegate, stock: Stock) {
        self.indexPath = indexPath
        self.stock = stock
        self.cellDelegate = delegate
        
        title.text = stock.symbol
//        let timeSinceLastStockDate = Date().timeIntervalSince(stock.dailyPrices.last!.tradingDate)
        detail.text = timeFormatter.localizedString(for: stock.dailyPrices.last!.tradingDate, relativeTo: Date())
        
    }
    
    @IBAction func valuationButtonAction(_ sender: UIButton) {
        cellDelegate.valuationButtonPressed(indexpath: self.indexPath)
    }
}
