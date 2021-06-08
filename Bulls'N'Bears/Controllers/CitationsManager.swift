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
        let pL2 = "By careful pruning and rotation based on fundamentals, you can improve your results. When stocks are out of line with reality and better alternatives exist, sell them and switch into something else"
        let pL3 = "You don't lose anything by not owning a successful stock, even if it's a tenbagger"
        let pL4 = "Don't become so attached to a winner that complacency sets in and you stop monitoring the story"
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
        let pL22 = "Specific products aside, big companies don't have big stock moves. In certain markets they perform well, but you'll get your biggest moves in smaller companies"
        let pL23 = "If you can summon the courage and presence of mind to buy during [the collapses, drops, burps, hiccups and freefalls] when your stomach says 'sell', you'll find opportunities that you wouldn't have thought you'd ever see again"
        let pL24 = "... when you've found the right stock and bought it, all the evidence tells you it's going higher, and everything is working in your direction, then it's a shame if you sell"
        let pL25 = "These days if I feel there's a danger of being faked out, I try to review the reasons why I bought in the first place."
        let pL26 = "How many people know what the Fed does?...23 % of the US population thought the Federal Reserve was an Indian reservation, 25% thought it was a wildlife preserve, and 51% thought it was a brand of whiskey"
        let pL27 = "ultimately the earnings will decide the fate of a stock."
        let pL28 = "There are three phases to a growth company's life: the start-up phase..., the rapid expansion phase..., and the saturation phase...\nThe second phase is the safest phase, and also where the most money is made"

        let pL1_0 = "Hold no more stocks than you can remained informed on"
        let pL1_1 = "You want to see first that sales and earnings per share are moving forward at an acceptable rate, and second, that you can buy the stock at a reasonable price"
        let pL1_2 = "Buy or do not buy the stock on the basis of whether or not growth meets your objectives and whether the price is reasonable"
        let pL1_3 = "Understanding the reasons for past sales growth will help you form a good judgement as to the likelihood of past growth rates continuing"
        let pL1_4 = "The key to make money in stocks is not to get scared out of them. This point cannot be overemphasized."
        let pL1_5 = "The story of the 40 [stock market] declines continues to comfort me during gloomy periods when you and I have another chance in a long string of chances to buy great stocks at bargain prices."


        let wb0 = "Warren [Buffett] realized ... that if a company's competitive advantage could be maintained for a long period of time - if it was 'durable' - then the underlying vaue of the business would continue to increase year after year"
        let wb1 = "Because these businesses [with durable competitive advantage] had such incredible business economics working in their favor, there was zero chance of them ever going into bankruptcy."
        let wb2 = "the longer [Warren Buffett] held on to these positions, the more time he had to profit from these businesses' great underlying economics."
        let wb3 = "[Warren Buffett] realized that he no longer had to wait for Wall Street to serve up a bargain price. He could pay a fair price for one of these super businesses and still come out ahead, provided he held the investment long enough"
        let wb4 = "Warren has figured out that these super companies come in three basic business models: They sell either a unique product or a unique service, or they are the low-cost buyer and seller of a product or service that the public consistently needs"
        let wb5 = "Warren [Buffett] has learned that it is the 'durability' of the competitive advantage that creates all the wealth"
        let wb6 = "when Warren [Buffett] is looking at a company's financial statement, he is looking for consistency"
        let wb7 = "All publicly traded companies must file quarterly financial statements with the SEC; these are known as 8Qs.\nAlso filed with the SEC is a document called the 10K, which is the company's annual report"
        let wb8 = "Warren [Buffett] has read thousands of 10K's over the years, as they do the best job of reporting the numbers without all the fluff that can get stuffed into a shareholder's annual report"
        let wb9 = "To Warren [Buffett], the source of the earnings is always more important than the earnings themselves"
        let wb10 = "Warren [Buffett] knows that one of the great secrets to making more money is spending less money"
        let wb11 = "Companies with gross profit margins of 40% or better tend to be compnanies with some sort of durable competitive advantage...\nAny gross profit margin of 20% and below is usually a good indicator of a fiercely competitive industry."
        let wb12 = "Warren [Buffett] knows that when we look for companies with a durable competitive advantage, 'consistency' is the name of the game"
        let wb13 = "Companies that don't have a durable competitive advantage suffer from intense competition and show wild variation in SGA costs as a percentage of gross profit"
        let wb14 = "...the lower the company's SGA expenses, the better. If they can stay consistently low, all the better. [...] anything under 30% is considered fantastic."
        let wb15 = "...the lower the company's SGA expenses, the better. If they can stay consistently low, all the better. [...] anything under 30% is considered fantastic."
        let wb16 = "...the economics of companies with low SGA expenses can be destroyed by expensive research and development costs, high capital expenditure and/ or lots of debt."
        let wb17 = "Companies that have to spend heavily on R&D have an inherent flaw in their competitive advantage, that will always put their long-term economics at risk..."
        let wb18 = "... if a company is showing a net earnings history of more than 20% on total revenues, there is a real good chance that it is benefiting from some kind of long-term competitive advantage."

        let plCitatations = [pL0, pL1, pL2,pL3,pL4, pL5, pL6, pL7, pL8, pL9, pL10, pL11, pL12, pL13, pL14, pL15, pL16, pL17, pL18, pL19, pL20, pL21, pL22 , pL23, pL24, pL25, pL26, pL27, pL28]
        let pl1Citatations = [pL1_0, pL1_1, pL1_2, pL1_3, pL1_4, pL1_5]
        let wbCitations = [wb0, wb1, wb2,wb3,wb4,wb5,wb6,wb7,wb8,wb9, wb10,wb11,wb12, wb13, wb14, wb15, wb16, wb17, wb18]
        
        var allCitations = plCitatations
        allCitations.append(contentsOf: wbCitations)
        allCitations.append(contentsOf: pl1Citatations)

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
        let tributePL = "\n\nPeter Lynch\n'One up on Wall Street'\nSimon & Schuster, 1989"
        let tributePL2 = "\n\nPeter Lynch w John Rothchild\n'Beating The Street'\nSimon & Schuster"
        let tributeWB = "\n\nMary Buffett and David Clark\n'Warren Buffett and the Interpretation of Financial Statements'\nSimon & Schuster, 2008"

        var tribute = String()
        
        if randomCitationNo < plCitatations.count {
            tribute = tributePL
        } else if randomCitationNo < (plCitatations.count + wbCitations.count) {
            tribute = tributeWB
        }
        else {
            tribute = tributePL2
        }
        
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
