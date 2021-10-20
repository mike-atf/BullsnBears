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
    @IBOutlet var reportDateLabel: UILabel!
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
        self.title.textColor = .label
        self.detail.text = " "
        self.ratingCircle.isHidden = true
        actionView.resetForReuse()
        valueCircle.isHidden = true
    }
    
    public func configureCell(indexPath: IndexPath, stock: Share, userRatingScore: Double?, valueRatingScore: Double?, scoreDelegate: ScoreCircleDelegate, userCommentCount: Int) {
        
        self.indexPath = indexPath
        self.stock = stock
        
//        var value$ = ""
        if stock.peRatio != Double() {
//            value$ = numberFormatterNoFraction.string(from: stock.peRatio as NSNumber) ?? ""
            title.textColor = GradientColorFinder.gradientColor(lowerIsGreen: true, min: 0, max: 40, value: stock.peRatio, greenCutoff: 10.0, redCutOff: 40.0)
        }
        title.text = stock.symbol //! + "(" + value$ + ")"

        if let lastPrice = stock.getDailyPrices()?.last {
            detail.text = timeFormatter.localizedString(for: lastPrice.tradingDate, relativeTo: Date())
        }
        
        var reportDate$ = "Report: -"
        if let valid = stock.research?.nextReportDate {
            let dateFormatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                return formatter
            }()
            reportDate$ = "Report: " + dateFormatter.string(from: valid)
        }
        reportDateLabel.text = reportDate$

        
        actionView.configure(share: stock)
        ratingCircle.configure(score: userRatingScore,delegate: scoreDelegate, path: indexPath, isUserScore: true, userCommentsCount: userCommentCount)
        valueCircle.configure(score: valueRatingScore, delegate: scoreDelegate, path: indexPath, isUserScore: false, userCommentsCount: 1)
    }
}
