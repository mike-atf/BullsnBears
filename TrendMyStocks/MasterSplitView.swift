//
//  MasterSplitView.swift
//  TrendMyStocks
//
//  Created by aDav on 01/12/2020.
//

import UIKit

class MasterSplitView: UISplitViewController, UISplitViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        preferredDisplayMode = .oneBesideSecondary
        delegate = self
                
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
