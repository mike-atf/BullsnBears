//
//  CitationsManager.swift
//  Bulls'N'Bears
//
//  Created by aDav on 23/04/2021.
//

import UIKit

class CitationsManager {
    
    class func cite() -> NSMutableAttributedString {
        
        let pL0 = "You don't have to 'kiss all the girls.' I've missed my share of tenbaggers and it hasn't kept me from beating the market"
        let pL1 = "You won't improve results by pulling out the flowers and watering the weeds"
        let pL2 = "By careful pruning and rotation based on fundamentals, you can improve your results. When stocks are out of line qwith reality and better alternatives exist, seel them and switch inot somehting else"
        let pL3 = "You dont lose anything by not owning a successful stock, even if it's a tenbagger"
        let pL4 = "Don't become so attached to a winner that complacency sets in ans you stop monitoring the story"
        let pL5 = "Buying a company with mediocre prospects just because the stock is cheap is a losing technique"
        let pL6 = "Selling an outstanding fast grower because its stock seems slightly overpriced is a losing technique"
        let pL7 = "Just because the price goes up doesn't mean you're right"
        let pL8 = "Just because the price goes down doesn't mean you're wrong"
        let pL9 = "stalwarts with heavy institutional ownership and lots of Wall Street coverage that have outperformed the market and are overpriced are due for a rest and decline"
        let pL10 = "Just because a company is doing poorly doesn't mean it can't do worse"
        let pL11 = "You can make serious money by compounding a series of 20-30% gains in stalwarts"
        let pL12 = "stock prices often move in opposite directions from the fundamentals but long term, the direction and sustainability of profits will prevail"
        let pL13 = "To come out ahead you don't have to be right all the time, or even a majority of the time"
        let pL14 = "It takes years, not months, to produce big results"
        let pL15 = "Different categories of stock have different risks and rewards"
        let pL16 = "Market declines are great opportunities to buy stocks in companies you like. Corrections [...] push outstanding companies to bargain prices"
        let pL17 = "Trying to predict the direction of the market over one year, or even two years, is impossible"
        let pL18 = "Sometime in the next month, year or three years, the market will decline sharply"
        let pL19 = "It turns out that England had a big trade deficit, and England was thriving around it. But there's no point bringing this up. By the time I thought of it, people had forgotten about the trade deficit and started to worry about the next trade surplus"
        let pL20 = "It's that last 20% [of a typical stock move] that Wall Street studies for, clamors for and then lines up for - all the while with a sharp eye on the exits. The idea is to make a quick gain and then stampede out the door.\nSmall investors don't have to fight this mob. They can calmly walk in the entrance when there's a crowd at the exit, and walk out the exit when there's a crowd at the entrance."
        let pL21 = "Investing without research is like playing stud poker and never looking at the cards."
        let pL22 = "Specific products aside, big companies don't have big stock moves. In certain markets thy perform well, but you'll get your biggest moves in smaller companies"
        let pL23 = "If you can summon the courage and presence of mind to buy during [the collapses, drops, burps, hiccups and freefalls] when your stomach says 'sell', you'll find opportunities that you wouldn't have thought you'd ever see again"
        let pL24 = "... when you've found the right stock and bought it, all the evidence tells you it's going higher, and everything is working in your direction, then it's a shame if you sell"
        let pL25 = "These days if I feel there's a danger of being faked out, I try to review the reasons why I bought in the first place."

        
        var allCitations = [pL0, pL1, pL2,pL3,pL4, pL5, pL6, pL7, pL8, pL9, pL10, pL11, pL12, pL13, pL14, pL15, pL16, pL17, pL18, pL19, pL20, pL21, pL22 , pL23, pL24, pL25]
        
        if let lastCitation = UserDefaults.standard.value(forKey: userDefaultTerms.lastCitation) as? String {
            var count = 0
            for citation in allCitations {
                if citation == lastCitation {
                    allCitations.remove(at: count)
                    break
                }
                count += 1
            }
        }
        
        let citationCount = allCitations.count
        let randomCitationNo = Int.random(in: 0..<citationCount)
        let randomCitation = "\"" + allCitations[randomCitationNo] + "\""
        let tribute = "\n\nPeter Lynch\n'One up on Wall Street'\nSimon & Schuster, 1989"
        
        let font = UIFont.italicSystemFont(ofSize: 18)
        let fontColor = UIColor.label
        let paragraphStyle1 = NSMutableParagraphStyle()
        paragraphStyle1.alignment = NSTextAlignment.center

        let citationBody = NSMutableAttributedString(
            string: randomCitation,
            attributes: [ NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: fontColor,NSAttributedString.Key.paragraphStyle: paragraphStyle1]
        )
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.left
        citationBody.append(NSAttributedString(
            string: tribute,
            attributes: [ NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12), NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.foregroundColor: fontColor]))
        
        UserDefaults.standard.set(randomCitation, forKey: userDefaultTerms.lastCitation)
        return citationBody
    }
    

}
