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
    @IBOutlet var updateIcon: UIImageView!
    @IBOutlet var actionIcon: UIImageView!
    @IBOutlet var actionLabel: UILabel!
    @IBOutlet var healthIcon: UIImageView!
    @IBOutlet var healthDateLabel: UILabel!
    var tap: UITapGestureRecognizer!
    weak var tableVC: StocksListTVC?
    
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
        
        self.healthDateLabel.text = " "
    }
    
    override func prepareForReuse() {
        self.title.text = " "
        self.title.textColor = .label
        self.detail.text = " "
        self.actionLabel.text = " "
        self.healthDateLabel.text = " "
        self.scoreIcon.isHidden = true
        actionIcon.image = nil
        healthIcon.image = nil
        updateIcon.image = nil
        reportDateLabel.backgroundColor = UIColor.clear
        healthIcon.removeGestureRecognizer(tap)
    }
    
    public func configureCell(indexPath: IndexPath, stock: Share, userRatingScore: Double?, valueRatingScore: Double?, scoreDelegate: ScoreCircleDelegate, userCommentCount: Int, viewController: StocksListTVC) {
        
        self.indexPath = indexPath
        self.stock = stock
        
        tap = UITapGestureRecognizer(target: self, action: #selector(healthTap))
        healthIcon.addGestureRecognizer(tap)
        
        if let currentPE = stock.pe_current() {
            
            if currentPE > 0 {
                title.textColor = GradientColorFinder.gradientColor(lowerIsGreen: true, min: 0, max: 40, value: currentPE, greenCutoff: 10.0, redCutOff: 40.0)
            } else if currentPE < 0 {
                title.textColor = UIColor.systemRed
            } else {
                title.textColor = UIColor.label
            }

        }
        title.text = stock.symbol

        if let lastPrice = stock.getDailyPrices()?.last {
            detail.text = timeFormatter.localizedString(for: lastPrice.tradingDate, relativeTo: Date())
        }
        
        var imminent = false
        var reportDate$ = "Report: -"
        if let valid = stock.research?.nextReportDate {
            let dateFormatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                return formatter
            }()
            if abs(valid.timeIntervalSinceNow) < 3*day { imminent = true }
            reportDate$ = "Report: " + dateFormatter.string(from: valid)
        }
        reportDateLabel.text = reportDate$
        
        if imminent {
            reportDateLabel.text = " " + reportDate$ + " "
            reportDateLabel.backgroundColor = UIColor.systemRed
        }

        setActionIcon(share: stock)
        
        let score = ((UserDefaults.standard.value(forKey: userDefaultTerms.sortParameter) as? String) ?? "userEvaluationScore") == "valueScore" ? valueRatingScore : userRatingScore
        scoreIcon.configure(score: score,delegate: scoreDelegate, path: indexPath, isUserScore: true, userCommentsCount: userCommentCount)
        
        if stock.watchStatus > 2 {
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
        
        if stock.watchStatus == 1 {
            setHealthIcon(share: stock)
        }
    }
    
    internal func setHealthIcon(share: Share) {
        
        if let healthDV = share.trend_healthScore.datedValues(dateOrder: .ascending, includeThisYear: true)?.last {
            
            healthIcon.image = UIImage(systemName: "cross.circle")
//            healthDateLabel.text = dateFormatter.string(from: healthDV.date)
            healthDateLabel.text = timeFormatter.localizedString(for: healthDV.date, relativeTo: Date())
            
            var healthColor = UIColor()
            if healthDV.value > 0.8 {
                healthColor = UIColor.systemGreen
            }
            else if healthDV.value > 0.5 {
                healthColor = UIColor.systemYellow
            }
            else {
                healthColor = UIColor.systemRed
            }
            
            if Date().timeIntervalSince(healthDV.date) > 30*24*3600 {
                healthDateLabel.textColor = UIColor.systemYellow
            }
            
            let config = UIImage.SymbolConfiguration(paletteColors: [healthColor, .label])

            healthIcon.preferredSymbolConfiguration = config
            
        }
        else {
            healthIcon.image = nil
            healthDateLabel.text = " "
        }

    }
    
    internal func setActionIcon(share: Share) {
        
        guard let latest3Crossings = share.latest3Crossings() else {
            self.actionLabel.text = " "
            return
        }
        
        var lastCrossing: LineCrossing
        var has3Signals = false
        if latest3Crossings[2] == nil {
            if latest3Crossings[1] == nil {
                lastCrossing = latest3Crossings.first!!
            }
            else {
                lastCrossing = latest3Crossings[1]!
            }
        }
        else {
            lastCrossing = latest3Crossings.last!!
            has3Signals = true
        }
        
        let actionIconTintColor = lastCrossing.signal > 0 ? UIColor.systemGreen : UIColor.systemRed
        
        var earlierSignalsSame = [Bool]()
        if has3Signals {
            earlierSignalsSame = latest3Crossings[..<2].compactMap{ $0!.signalIsBuy() }.filter { (buySignal) -> Bool in
                if buySignal == lastCrossing.signalIsBuy() { return true }
                else { return false }
            }
        }
        
        let config = UIImage.SymbolConfiguration(paletteColors: [actionIconTintColor, .label])
        
        actionIcon?.image = lastCrossing.signal > 0 ? UIImage(systemName: "cart.fill.badge.plus"):  UIImage(systemName: "cart.fill.badge.minus")
        actionIcon.preferredSymbolConfiguration = config
        
        if earlierSignalsSame.count == 2 {
            if let validDate = lastCrossing.date {
                actionLabel.text = dateFormatter.string(from: validDate)
            }
        }
        else {
            actionIcon?.image = UIImage(systemName: "hand.raised.circle")
            actionLabel.text = " "
        }
        
    }
    
    @objc func healthTap() {
        tableVC?.healthTap(indexPath: self.indexPath)
    }
    
}
