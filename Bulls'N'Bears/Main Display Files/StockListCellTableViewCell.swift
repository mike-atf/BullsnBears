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
    @IBOutlet var scoreIcon: ScoreCircle!
    @IBOutlet var actionView: BuySellView!
    @IBOutlet var updateIcon: UIImageView!
    
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
        self.scoreIcon.isHidden = true
        actionView.resetForReuse()
        updateIcon.image = nil
//        updateIcon.tintColor = UIColor.systemRed
    }
    
    public func configureCell(indexPath: IndexPath, stock: Share, userRatingScore: Double?, valueRatingScore: Double?, scoreDelegate: ScoreCircleDelegate, userCommentCount: Int) {
        
        self.indexPath = indexPath
        self.stock = stock
        
        if stock.peRatio != Double() {
            title.textColor = GradientColorFinder.gradientColor(lowerIsGreen: true, min: 0, max: 40, value: stock.peRatio, greenCutoff: 10.0, redCutOff: 40.0)
        }
        title.text = stock.symbol

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
        scoreIcon.configure(score: score,delegate: scoreDelegate, path: indexPath, isUserScore: true, userCommentsCount: userCommentCount)
        
        if stock.watchStatus > 1 {
            updateIcon.image = nil
            updateIcon.tintColor = UIColor.systemRed
            return
        }
        
        if let lastUpdateDate = stock.lastLivePriceDate {
            if Date().timeIntervalSince(lastUpdateDate) < 3600 {
                updateIcon.image = UIImage(systemName: "checkmark.circle.fill")
                updateIcon.tintColor = UIColor.systemGreen
            } else {
                updateIcon.image = UIImage(systemName: "xmark.circle.fill")
                updateIcon.tintColor = UIColor.systemRed
            }
        } else {
            updateIcon.image = nil
            updateIcon.tintColor = UIColor.systemRed
        }
    }
}
