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
    }
    
    public func configureCell(indexPath: IndexPath, stock: Share, userRatingScore: Double?, valueRatingScore: Double?, scoreDelegate: ScoreCircleDelegate, userCommentCount: Int) {
        
        self.indexPath = indexPath
        self.stock = stock
        
        if stock.peRatio != Double() {
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
        let score = ((UserDefaults.standard.value(forKey: userDefaultTerms.sortParameter) as? String) ?? "userEvaluationScore") == "valueScore" ? valueRatingScore : userRatingScore
        ratingCircle.configure(score: score,delegate: scoreDelegate, path: indexPath, isUserScore: true, userCommentsCount: userCommentCount)
    }
}
