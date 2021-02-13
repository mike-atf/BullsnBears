//
//  StockListCellTableViewCell.swift
//  TrendMyStocks
//
//  Created by aDav on 02/01/2021.
//

import UIKit


class StockListCellTableViewCell: UITableViewCell {

    @IBOutlet var title: UILabel!
    @IBOutlet var detail: UILabel!
    
    var indexPath: IndexPath!
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
    }
    
    public func configureCell(indexPath: IndexPath, stock: Stock) {
        self.indexPath = indexPath
        self.stock = stock
        
        title.text = stock.symbol
        detail.text = timeFormatter.localizedString(for: stock.dailyPrices.last!.tradingDate, relativeTo: Date())
        
    }
}
