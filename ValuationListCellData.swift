//
//  ValuationListCellData.swift
//  Bulls'N'Bears
//
//  Created by aDav on 01/02/2021.
//

import UIKit

struct ValuationListCellInfo {
    
    var value$ : String?
    var title : String!
    var format : ValuationCellValueFormat!
    var cellDetailInfo : (text: String?, color: UIColor?)!
    
    init(value$: String?, title: String, format: ValuationCellValueFormat, detailInfo: (String?, UIColor?)) {
        self.value$ = value$
        self.title = title
        self.format = format
        self.cellDetailInfo = detailInfo
    }

}

struct Rule1DCFCellData {
    
    var value$ = String()
    var title$ = String()
    var detail$ = String()
    var detailColor = UIColor.label
    
    init(value$: String, title: String, detail$: String, detailColor: UIColor?=nil) {
        self.value$ = value$
        self.title$ = title
        self.detail$ = detail$
        if let c = detailColor {
            self.detailColor = c
        }
    }

}

