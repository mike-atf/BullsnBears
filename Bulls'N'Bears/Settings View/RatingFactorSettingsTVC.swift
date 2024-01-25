//
//  RatingFactorSettingsTVC.swift
//  Bulls'N'Bears
//
//  Created by aDav on 28/11/2021.
//

import UIKit

class RatingFactorSettingsTVC: UITableViewController {
    
    var factorTitles = [String]()
    var originalWeights: Financial_Valuation_Factors!
    var max: Double = 1
    var min: Double = 0
    var range: Double = 1.0
    var rootView: SettingsTVC?
    var combinedValue: Double!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "RatingFactorCell", bundle: nil), forCellReuseIdentifier: "ratingFactorCell")
        let leftButton = UIBarButtonItem(title: "Save", style: .plain,target: self, action: #selector(saveAndBackToRootView))
        let rightButton = UIBarButtonItem(title: "Cancel", style: .plain,target: self, action: #selector(cancelAndBackToRootView))
        navigationItem.leftBarButtonItem = leftButton

        self.navigationItem.leftBarButtonItem = leftButton
        self.navigationItem.rightBarButtonItem = rightButton
        
        factorTitles = valuationFactors.propertyNameList()
        max = valuationFactors.maxWeightValue() ?? 1.0
        min = valuationFactors.minWeightValue() ?? 0.0
        range = max - min
        
        originalWeights = valuationFactors
        combinedValue =  valuationFactors.weightsSum()
        
    }
    
    @objc
    func saveAndBackToRootView() {
        self.dismiss(animated: true) {
            
            UserDefaults.standard.set(valuationFactors.propertyDictionary, forKey: userDefaultTerms.valuationFactorWeights)

//            valuationFactors.saveUserDefaults()
            let notification = Notification(name: Notification.Name(rawValue: "userChangedValuationWeights"), object: nil, userInfo: nil)
            NotificationCenter.default.post(notification)
        }
    }
    
    @objc
    func cancelAndBackToRootView() {
        self.dismiss(animated: true, completion: {
            valuationFactors = self.originalWeights
        })
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return factorTitles.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ratingFactorCell", for: indexPath) as! RatingFactorCell
        
        let value = valuationFactors.getValue(forVariable: factorTitles[indexPath.row])
        cell.configure(value: value, totalValue: combinedValue, title: factorTitles[indexPath.row], indexPath: indexPath, delegate: self)

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }

}

extension RatingFactorSettingsTVC: RatingFactorCellDelegate {
    
    func userChangedSetting(value: Double, path: IndexPath) {
//        valuationFactors.setValue(value: value, parameter: factorTitles[path.row])
        valuationFactors.propertyDictionary[factorTitles[path.row]] = value
        
        if let cell = tableView.cellForRow(at: IndexPath(row: path.row, section: 0)) as? RatingFactorCell {
            cell.adjustValue(value: value)
        }
    }    
    
}
