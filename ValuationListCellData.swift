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
