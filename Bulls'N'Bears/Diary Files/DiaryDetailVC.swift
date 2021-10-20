//
//  DiaryDetailVC.swift
//  Bulls'N'Bears
//
//  Created by aDav on 12/10/2021.
//

import UIKit

class DiaryDetailVC: UIViewController {

    @IBOutlet var chart: ChartView!
    @IBOutlet var titleItem: UIBarButtonItem!
    @IBOutlet var scrollContentView: UIView!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var scrollContentViewHeightConstraint: NSLayoutConstraint!
    
    var share: Share?
    var transactionCards: [DiaryTransactionCard]?
    var cardInView: DiaryTransactionCard?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.delegate = self
        configure()

    }
    
    func configure() {
        loadViewIfNeeded() // leave! essential
        
        if let validChart = chart {
            if let validShare = share {
                titleItem.title = (validShare.symbol ?? "missing")
                validChart.configure(stock: validShare, withForeCast: false)
                
                guard let validTransactions = validShare.sortedTransactionsByDate(ascending: true) else {
                    return
                }
                
                transactionCards = [DiaryTransactionCard]()
                var count = 0
                
                for transaction in validTransactions {
                    let newCard = DiaryTransactionCard.instanceFromNib()
                    newCard.positionInArray = count
                    newCard.translatesAutoresizingMaskIntoConstraints = false
                    scrollContentView.addSubview(newCard)
                    
                    newCard.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor).isActive = true
                    newCard.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor).isActive = true
                    newCard.heightAnchor.constraint(equalTo: chart.heightAnchor).isActive = true
                    if count == 0 {
                        newCard.topAnchor.constraint(equalTo: scrollContentView.topAnchor).isActive = true
                    } else {
                        newCard.topAnchor.constraint(equalTo: transactionCards![count-1].bottomAnchor).isActive = true
                    }
                    
                    newCard.backgroundColor = (count%2 == 0) ? UIColor.systemBackground : UIColor.systemGray6
                    newCard.relatedChartButton = chart.purchaseButtons?.filter({ button in
                        if button.transaction.date == transaction.date { return true }
                        else { return false }
                    }).first
                    newCard.relatedChartButton?.relatedDiaryTransactionCard = newCard
                    
                    newCard.configure(transaction: transaction, buttonActivationDelegate: self)
                    transactionCards?.append(newCard)
                    count += 1
                }
                let height = transactionCards?.first?.frame.height ?? 0.0
                let totalHeight = height * CGFloat((transactionCards?.count ?? 1))
                scrollContentViewHeightConstraint.isActive = false
                scrollContentViewHeightConstraint = NSLayoutConstraint(item: scrollContentView!, attribute: .height, relatedBy: .equal, toItem: chart, attribute: .height, multiplier: CGFloat((transactionCards?.count ?? 1)), constant: 0)
                scrollContentViewHeightConstraint.isActive = true
                scrollView.contentSize = CGSize(width: scrollView.contentSize.width, height: totalHeight)
                
                cardInView = transactionCards?.first
                cardInView?.isActive = true
                cardInView?.setNeedsDisplay()
            }
        }
    }

}

extension DiaryDetailVC: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        let cardNowShown = Int(round(scrollView.contentOffset.y / scrollView.bounds.height))
        let cardScrolledTo = transactionCards![cardNowShown]
        
        if !cardScrolledTo .isEqual(cardInView) {
            // deactivate current card
            cardInView?.isActive = false
            cardInView?.setNeedsDisplay()
            
            // active new card
            cardInView = cardScrolledTo
            cardInView?.isActive = true
            cardInView?.setNeedsDisplay()
            
            cardInView?.relatedChartButton?.makeActiveButton()
        }
    }
}

extension DiaryDetailVC: CardActivatedByButtonDelegate {
    
    func hasBeenActivated(transactionCard: DiaryTransactionCard) {
//        cardInView?.isActive = false
//        cardInView?.setNeedsDisplay()
//
//        cardInView = transactionCard
//        cardInView?.setNeedsDisplay()
        
        let scrollPosition = CGFloat(transactionCard.positionInArray) * transactionCard.frame.height
        scrollView.setContentOffset(CGPoint(x: 0, y: scrollPosition), animated: true)
        
    }
}
