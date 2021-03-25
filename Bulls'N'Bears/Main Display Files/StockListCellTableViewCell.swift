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
    @IBOutlet var actionView: BuySellView!
    
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
    
    public func configureCell(indexPath: IndexPath, stock: Share, userRatingData: RatingCircleData?, valueRatingData: RatingCircleData?, scoreDelegate: ScoreCircleDelegate) {
        self.indexPath = indexPath
        self.stock = stock
        
        title.text = stock.symbol
        if let lastPrice = stock.getDailyPrices()?.last {
            detail.text = timeFormatter.localizedString(for: lastPrice.tradingDate, relativeTo: Date())
        }
        
        actionView.configure(share: stock)
        ratingCircle.configure(ratingStruct: userRatingData, delegate: scoreDelegate, path: indexPath, isUserScore: true)
        valueCircle.configure(ratingStruct: valueRatingData, delegate: scoreDelegate, path: indexPath, isUserScore: false)
    }
}
