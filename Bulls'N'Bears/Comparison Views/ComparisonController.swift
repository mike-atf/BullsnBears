//
//  ComparisonController.swift
//  Bulls'N'Bears
//
//  Created by aDav on 28/04/2021.
//

import Foundation

class ComparisonController {
    
    var shares: [Share]?
    var controlledView: ComparisonVC
    
    
    init(shares: [Share]?, viewController: ComparisonVC) {
        
        self.shares = shares
        self.controlledView = viewController
    }
    
    func rowTitles() -> [[String]]{
        
        let titleStructure = [["Shares","Why to buy"],
                                ["Personal rating score", "Fundamentals score", "Compet. strength" ,"GB Valuation" ,"DCF Valuation", "Intrinsic value"],
                                ["PE ratio", "Lynch score", "Book value / share price"],
                                ["Ret. earnings", "Revenue", "Net income", "Op. Cash flow", "Profit margin", "EPS"],
                                ["ROI", "ROE", "ROA"],
                                ["LT Debt / net income", "LT Debt / adj equity", "cap. exp.", "SGA / revenue", "R&D / profit"]]
        
        return titleStructure
        
    }
    
    func titleForRow(for path: IndexPath) -> String {
        
        let titles = rowTitles()
        return titles[path.section][path.row]
    }
    
    
    
    /*
     tableStructure:
     == section 0
     0 titles / symbols
     1 research.buy story
     == section 1
     0 user rating score
     1 fundamentals score
     2 moat score
     3 GB valuation
     4 DCF Valuation
     5 intrinsic WB value
     == section 2
     0 PE ratios
     1 Lynch score
     2 Book value/share price
     == section 3
     0 ret. earnings
     1 sales
     2 net income
     3 OCF
     4 profit margin
     5 EPS
     == section 4
     0 ROI
     1 ROE
     2 ROA
     == section 5
     0 debt / net income
     1 debt / adj equity
     2 capEx
     3 SGA / revenue
     4 RD / profit growth
     
     */
    

    
}
