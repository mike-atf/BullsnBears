//
//  CitationsManager.swift
//  Bulls'N'Bears
//
//  Created by aDav on 23/04/2021.
//

import Foundation

class CitationsManager {
    
    class func cite() -> String {
        
        let pL0 = "You don't have to 'kiss all the girls.' I've missed my share of tenbaggers and it hasn't kept me from beating the market"
        let pL1 = "You won't improve results by pulling out the flowers and watering the weeds"
        let pL2 = "By careful pruning and rotation based on fundamentals, you can improve your results. When stocks are out of line qwith reality and better alternatives exist, seel them and switch inot somehting else"
        let pL3 = "You dont lose anyhting by not owning a successful stock, even if it's a tenbagger"
        let pL4 = "Don't become so attached to a winner that complacency sets in ans you stop monitoring the story"
        let pL5 = "Buying s company with mediocre prospects just because the stock is cheap is a losing technique"
        let pL6 = "Selling an outstanding fast grower because its stock seems slightly overpriced is a losing technique"
        let pL7 = "Just because the price goes up doesn't mean you're right"
        let pL8 = "Just because the price goes down doesn't mean you're wrong"
        let pL9 = "stalwarts with heavy institutional ownership and lots of Wall Street coverage that have outperformed the market are are overpriced are due for a rest and decline"
        let pL10 = "Just because a company is doing poorly doesn't mean it can't do worse"
        let pL11 = "You can make serious money by compounding a series of 20-30% gains in stalwarts"
        let pL12 = "stock prices often move in opposite directions from the fundamentals but long term, the direction and sustainability of profits will prevail"
        let pL13 = "To come out ahead you don;t have to be right all the time, or even a majority of the time"
        let pL14 = "It takes years, not months, to produce big results"
        let pL15 = "Different categories of stock have different risks and rewards"
        let pL16 = "Market declines are great opporrunities to buy stocks in companies you like. Corrections [...] push outstanding companies to bargain prices"
        let pL17 = "Trying to prdict the direction of the market over one year, or even two years, is impossible"
        let pL18 = "Sometime in the next month, year or three years, the market will decline sharply"
        let pL19 = "It turns out that England had a big trade deficit, and England was thriving around it. But there's no point bringing this up. By the time I thought of it, people had forgotten about the trade deficit and started to worry about the next trade surplus"
        let pL20 = "It's that last 20% [of a typical stock move] that Wall Street studies for, clamors for and then lines up for - all the while with a sharp eye on the exits. The idea is to make a quick gain and then stampede out the door.\nSmall investors don't have to fight this mob. They can calmly walk in the entrance when there's a crowd at the exit, and walk out the exit when there's a crowd at the entrance."

        
        var allCitations = [pL0, pL1, pL2,pL3,pL4, pL5, pL6, pL7, pL8, pL9, pL10, pL11, pL12, pL13, pL14, pL15, pL16, pL17, pL18, pL19, pL20]
        
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
        var randomCitation = "\"" + allCitations[randomCitationNo] + "\""
        randomCitation += "\n\nPeter Lynch\n'One up on Wall Street'\nSimon & Schuster, 1989"
        
        UserDefaults.standard.set(randomCitation, forKey: userDefaultTerms.lastCitation)
        return randomCitation
    }
    

}
