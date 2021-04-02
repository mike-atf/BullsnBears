//
//  GrowthCategory.swift
//  Bulls'N'Bears
//
//  Created by aDav on 26/03/2021.
//

import Foundation

enum GrowthCategoryNames {
    case slowGrowthSpeed
    case mediumGrowthSpeed
    case fastGrowthSpeed
    case cyclical
    case assetFocus
    case turnAround
}

struct GrowthCategory {
    var category: GrowthCategoryNames!
    
    init(category: GrowthCategoryNames) {
        self.category = category
    }
    
    public func explanation() -> String {
        
        var text = String()
        
        switch self.category {
        case .slowGrowthSpeed:
            text = "'sluggard'\ngrowth <6%, P/E <10\nGrows just a little more than GDP. Should pay considerable and regular dividend (= main investment reason)\nDoes it pay a steady dividend rate? Does the rate drop or was dividend stopped during recent downturns?"
        case .mediumGrowthSpeed:
            text = "'stalwart'\ngrowth 10-12%, P/E <15\nLongterm investment option, may provide little more return than bonds or savings account.\nDon't buy when overpriced\nBe prepared to sell when price has gone up well (e.g. 30-50% in two years) as it may not rise more in the long-term and is likely to drop again.\nRelatively safe during market downturns unless yuo bought it when overpriced"
        case .fastGrowthSpeed:
            text = "'fast grower'\ngrowth 20+ %, P/E 15+\nUsually small, aggressive new companies. These are risky, particular if the company is under-financed\nRisk of eventually momentum which will turn it into slow grower. That would drop the stock price significantly\nCheck balance sheet, ensure profit margin is high\nIs the stock price worth the anticipated earnings growth? Check and monitor P/E ratio"
        case .cyclical:
            text = "'cyclical'\n Cyclical stock prices rise and fall in not easily predictable ways between expanding and contracting markets\nExamples are cars, airlines, tires, steel, chemicals, defense. Cyclicals can be large companies\n The stock price depends on the general economic situation\nIt's essential to buy during/ at the end of downturns"
        case .assetFocus:
            text = "asset focus\nScrutinise for little noticed valuable assets in balance sheets: cash, real estate, commodities in the ground, patents, tax-loss carry forward, air / landing right, TV / media rights or contracts, subscriber numbers\nBeware that asset prices listed in the Balance sheet may not well match real market value if sold now\nSubtract liabilities and check book value per share against share price."
        case .turnAround:
            text = "turn around\nNot growing any more, compnay had recent crash or just survived bankruptcy, e.g. a cyclical that went all the way down.\nRecovery can be indepedent of general market situation\nBe careful if there is a risk of mass litigation/ damages/ or unpredictable liabiities\nSpin-off company of a major company? Or other way round?\nRestructuring to become profitable again (de-diworsification)?"
        default:
            text = "unidentified"
        }
        
        return text
    }
}
