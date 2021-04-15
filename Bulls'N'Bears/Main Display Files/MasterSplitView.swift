//
//  MasterSplitView.swift
//  TrendMyStocks
//
//  Created by aDav on 01/12/2020.
//

import UIKit

class MasterSplitView: UISplitViewController, UISplitViewControllerDelegate {
    
    var listView: StocksListTVC?
    var detailView: StockChartVC?

    override func viewDidLoad() {
        super.viewDidLoad()

        
        preferredDisplayMode = .oneBesideSecondary
        delegate = self
        
        let minimumWidth = min(view.bounds.width, view.bounds.height)
        self.minimumPrimaryColumnWidth = minimumWidth * 0.55
        self.maximumPrimaryColumnWidth = minimumWidth

        
        for vc in viewControllers {
            if let lv = vc as? StocksListTVC {
                listView = lv
            }
            else if let dv = vc as? StockChartVC {
                detailView = dv
            }
        }
                
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        
        if UIDevice().userInterfaceIdiom == .phone {
            if (UIDevice.current.orientation == .portrait) {
                    return true
            }
            else {
                return false
            }
        }
        else { return false }
    }
}

extension MasterSplitView {
  func openRemoteDocument(_ inboundURL: URL, importIfNeeded: Bool) {
    listView?.openDocumentBrowser(with: inboundURL, importIfNeeded: importIfNeeded)
  }
}
