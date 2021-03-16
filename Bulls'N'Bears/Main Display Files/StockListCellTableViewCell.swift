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
    @IBOutlet var ratingCircle: ScoreCircle!
    @IBOutlet var valueCircle: ScoreCircle!
    
    var indexPath: IndexPath!
    var stock: Share!
    
    let timeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .numeric
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
        
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        self.title.text = " "
        self.detail.text = " "
        self.ratingCircle.isHidden = true
        valueCircle.isHidden = true
    }
    
    public func configureCell(indexPath: IndexPath, stock: Share, userRatingData: RatingCircleData?, valueRatingData: RatingCircleData?) {
        self.indexPath = indexPath
        self.stock = stock
        
        title.text = stock.symbol
        print("cell title for path \(indexPath) set to \(stock.symbol!)")
        if let lastPrice = stock.getDailyPrices()?.last {
            detail.text = timeFormatter.localizedString(for: lastPrice.tradingDate, relativeTo: Date())
        }
        
        ratingCircle.configure(ratingStruct: userRatingData)
        valueCircle.configure(ratingStruct: valueRatingData)
    }
}
