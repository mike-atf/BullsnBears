//
//  CitationsManager.swift
//  Bulls'N'Bears
//
//  Created by aDav on 23/04/2021.
//

import UIKit
import CoreData

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

        let pL1_0 = "Hold no more stocks than you can remain informed on"
        let pL1_1 = "You want to see first that sales and earnings per share are moving forward at an acceptable rate, and second, that you can buy the stock at a reasonable price"
        let pL1_2 = "Buy or do not buy the stock on the basis of whether or not growth meets your objectives and whether the price is reasonable"
        let pL1_3 = "Understanding the reasons for past sales growth will help you form a good judgement as to the likelihood of past growth rates continuing"
        let pL1_4 = "The key to make money in stocks is not to get scared out of them. This point cannot be overemphasized."
        let pL1_5 = "The story of the 40 [stock market] declines continues to comfort me during gloomy periods when you and I have another chance in a long string of chances to buy great stocks at bargain prices."


        let wb0 = "Warren [Buffett] realized ... that if a company's competitive advantage could be maintained for a long period of time - if it was 'durable' - then the underlying value of the business would continue to increase year after year"
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
        let wb11 = "Companies with gross profit margins of 40% or better tend to be companies with some sort of durable competitive advantage...\nAny gross profit margin of 20% and below is usually a good indicator of a fiercely competitive industry."
        let wb12 = "Warren [Buffett] knows that when we look for companies with a durable competitive advantage, 'consistency' is the name of the game"
        let wb13 = "Companies that don't have a durable competitive advantage suffer from intense competition and show wild variation in SGA costs as a percentage of gross profit"
        let wb14 = "...the lower the company's SGA expenses, the better. If they can stay consistently low, all the better. [...] anything under 30% is considered fantastic."
        let wb15 = "...the lower the company's SGA expenses, the better. If they can stay consistently low, all the better. [...] anything under 30% is considered fantastic."
        let wb16 = "...the economics of companies with low SGA expenses can be destroyed by expensive research and development costs, high capital expenditure and/ or lots of debt."
        let wb17 = "Companies that have to spend heavily on R&D have an inherent flaw in their competitive advantage, that will always put their long-term economics at risk..."
        let wb18 = "... if a company is showing a net earnings history of more than 20% on total revenues, there is a real good chance that it is benefiting from some kind of long-term competitive advantage."
        
        let jm1 = "Holding cash is uncomfortable, but not as uncomfortable as doing something stupid."
        let jm2 = "Investing should be more like watching paint dry or watching grass grow. If you want excitement, take $800 and go to Las Vegas..."
        let jm3 = "... in some bizarre mental world, people believe that a loss isn't a loss until they realize it. This belief tends to investors holding onto their losing stocks and selling their winning stocks - known as the disposition effect."
        let jm4 = "Stop losses may be a useful form of pre-commitment that help alleviate the disposition effect in markets that witness momentum."
        let jm5 = "If I have done my homework, and selected stocks that I think represent good value over the long term, why on earth would I want to sit and watch their performance day by day. [...] positions that should perform well in the long term [...] certainly aren't guaranteed to do so without short-term losses."
        let jm6 = "...the Magic Formula portfolio fared poorly relative to the market average in 5 out of every 12 months tested. For full year periods the ... portfolio failed to beat the market average once every four years."
        let jm7 = "Investing is simple but not easy. That is to say, it should be simple to understand how investing works effectively: You buy assets for less than their intrinsic value and then sell when they are trading at or above their fair value (Warren Buffett)."
        let jm8 = "Investors should learn to follow the seven P's-: Perfect planning and preparation prevent piss poor performance. That is to say, we should do our investment research when we are in a cold, rational state-and when nothing much is happening in the markets--and then pre-commit to following our own analysis and prepared action steps"
        let jm9 = "The time of maximum pessimism is the best time to buy, and the time of maximum optimism is the best time to sell. (Sir John Templeton)"
        let jm10 = "Sir John [Templeton] knew that on the day the market or stock was down say 40% he wouldn't have the discipline to execute a buy. But, by placing buy orders well below the market price, it becomes easier to buy when faced with despondent selling. This is a simple but highly effective way of removing emotion from the situation."
        let jm11 = "…fear causes people to ignore bargains when they are available in the market, especially if they have previously suffered a loss. The longer they find themselves in this position, the worse their decision-making appears to become."
        let jm12 = "There is only one cure for terminal paralysis: you absolutely must have a battle plan for reinvestment and stick to it. Since every action must overcome paralysis, what I recommend is a few large steps, not many small ones. A single giant step at the low would be nice, but without holding a signed contract with the devil, several big moves would be safer."
        let jm13 = "… be aware that the market does not turn when it sees light at the end of the tunnel.  It turns when all looks black, but just a subtle shade less black than the day before. Therefore, an investor should put money to work amidst the throes of a bear market, appreciating that things will likely get worse before they get better."
        let jm14 = "One of our strategies for maintaining rational thinking at all times is to attempt to avoid the extreme stresses that lead to poor decision-making. We have often described our techniques for accomplishing this: \n * willingness to hold cash in the absence of compelling investment opportunity\n * a strong sell discipline\n* significant hedging activity\n* and avoidance of recourse leverage,among others."
        let jm15 = "Observation over many years has taught us that the chief losses to investors come from the purchase of low-quality securities at times of favorable business conditions. The purchasers view the current good earnings as equivalent to 'earning power' and assume that prosperity is synonymous with safety."
        let jm16 = "Indeed, most of the best investors appear to ask themselves a very different default question from the rest of us. Many of these investors generally run concentrated portfolios, with the default question being 'Why should I own this investment?' Whereas for fund managers who are obsessed with tracking error and career risk, the default question changes to 'Why shouldn't I own this stock?' This subtle distinction in default questions can have a dramatic impact upon performance."
        
        let bg1 = "In searching for value and avoiding glamour, it is the cheapest of the cheap you want to embrace and the most expensive you want to avoid."
        let bg2 = "...it is often the firms that ranked lowest on the measures - low returns on capital or narrow profit margins - that have tended to generate the highest future market returns."
        let bg3 = "Portfolios of ugly, disappointing, obscure (small) and boring (e.g. low growth) stocks repeatedly generated higher returns than both market ... and, more strikingly, portfolios of attractive, highly profitable, well-known (big) and glamorous (e.g. fast growing) stocks."
        let bg4 = "...it is the extremely unappealing portfolios - three years of disappointing returns - that produce the best results."
        let bg5 = "The uglier, more boring, more obscure, more disappointing, and thetefore usually the cheaper the stock, the better the returns have been."
        let bg6 = "...If offered a portfolio of stocks two-thirds of which may go bankrupt, most investors will recoil in horror before considering the potentially enormous gains from the one-third that do survive - gains large enough to make the whole investment highly profitable."
        let bg7 = "The shares of companies too small for big funds are always available on sale."
        let bg8 = "Spin-offs are a wonderful opportunity for investors who are not constrained by questions of market capitalisation."
        
        let al1 = "Emotions have no place in investing.\nYou are generally better off doing the opposite of what you 'feel' you should be doing"
        let al2 = "'Market timing' is impossible - managing risk exposure is logical and possible.\nInvestment is about discipline and patience. Lacking either one can be destructive to your investment goals"
        let al3 = "No investment strategy works all the time. The trick is knowing the difference between a bad investment strategy and one temporarily out of favor"

        
        let plCitations = [pL0, pL1, pL2,pL3,pL4, pL5, pL6, pL7, pL8, pL9, pL10, pL11, pL12, pL13, pL14, pL15, pL16, pL17, pL18, pL19, pL20, pL21, pL22 , pL23, pL24, pL25, pL26, pL27, pL28]
        let pl1Citations = [pL1_0, pL1_1, pL1_2, pL1_3, pL1_4, pL1_5]
        let wbCitations = [wb0, wb1, wb2,wb3,wb4,wb5,wb6,wb7,wb8,wb9, wb10,wb11,wb12, wb13, wb14, wb15, wb16, wb17, wb18]
        let jmCitations = [jm1,jm2, jm3, jm4, jm5, jm6, jm7, jm8, jm9, jm10,jm11,jm12,jm13,jm14,jm15, jm16]
        let bgCitations = [bg1, bg2, bg3, bg4, bg5, bg6, bg7, bg8]
        let alCitations = [al1, al2, al3]

        //
        var userCitations = [String]()
        let reqeust = NSFetchRequest<ShareTransaction>(entityName: "ShareTransaction")
        reqeust.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        let moc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        do {
            let transactions = try moc.fetch(reqeust)
            for ta in transactions {
                if let lessonLearnt = ta.lessonsLearnt {
                    userCitations.append(lessonLearnt)
                }
            }
        } catch {
            ErrorController.addInternalError(errorLocation: #function, systemError: error, errorInfo: "can't fetch share transactions")
        }
        
        var allCitations = plCitations
        allCitations.append(contentsOf: wbCitations)
        allCitations.append(contentsOf: pl1Citations)
        allCitations.append(contentsOf: jmCitations)
        allCitations.append(contentsOf: bgCitations)
        allCitations.append(contentsOf: alCitations)
        allCitations.append(contentsOf: userCitations)

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
        let tributeJM = "\n\nJames Mortimer\n'The Little Book of Behavioural Investing'\nJohn Wiley & Sons Ltd,  2010"
        let tributeBG = "\n\nBruce Greenwald\n'Value Investing (2nd Ed)\nJohn Wiley & Sons Ltd,  2021"
        let tributeAL = "\n\nSeeking Alpha\n'2023"
        let tributeUser = "\n\nYou, in your Lessons from Buying or Selling"

        var tribute = String()
        
        let step1Count = plCitations.count
        let step2Count = step1Count + pl1Citations.count
        let step3Count = step2Count + wbCitations.count
        let step4Count = step3Count + jmCitations.count
        let step5Count = step4Count + bgCitations.count
        let step6Count = step5Count + alCitations.count
//        let step6Count = step5Count + userCitations.count

        
        switch randomCitationNo {
        case 0..<step1Count:
            tribute = tributePL
        case step1Count..<step2Count:
            tribute = tributeWB
        case step2Count..<step3Count:
            tribute = tributePL2
        case step3Count..<step4Count:
            tribute = tributeJM
        case step4Count..<step5Count:
            tribute = tributeBG
        case step5Count..<step6Count:
            tribute = tributeAL
        case step6Count...:
            tribute = tributeUser
        default:
            tribute = "missing"
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
