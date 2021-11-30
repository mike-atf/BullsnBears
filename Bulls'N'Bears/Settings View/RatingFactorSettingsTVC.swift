//
//  RatingFactorSettingsTVC.swift
//  Bulls'N'Bears
//
//  Created by aDav on 28/11/2021.
//

import UIKit

class RatingFactorSettingsTVC: UITableViewController {
    
    var factorTitles = [String]()
    var originalWeights: ShareFinancialsValueWeights!
    var max: Double = 1
    var min: Double = 0
    var range: Double = 1.0
    var rootView: SettingsTVC?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "RatingFactorCell", bundle: nil), forCellReuseIdentifier: "ratingFactorCell")
        let leftButton = UIBarButtonItem(title: "Save", style: .plain,target: self, action: #selector(saveAndBackToRootView))
        let rightButton = UIBarButtonItem(title: "Cancel", style: .plain,target: self, action: #selector(cancelAndBackToRootView))
        navigationItem.leftBarButtonItem = leftButton

        self.navigationItem.leftBarButtonItem = leftButton
        self.navigationItem.rightBarButtonItem = rightButton
        
        factorTitles = valuationWeightsSingleton.propertyNameList()
        max = valuationWeightsSingleton.maxWeightValue() ?? 1.0
        min = valuationWeightsSingleton.minWeightValue() ?? 0.0
        range = max - min
        
        originalWeights = valuationWeightsSingleton
        
    }
    
    @objc
    func saveAndBackToRootView() {
        self.dismiss(animated: true) {
            valuationWeightsSingleton.saveUserDefaults()
        }
    }
    
    @objc
    func cancelAndBackToRootView() {
        self.dismiss(animated: true, completion: {
            valuationWeightsSingleton = self.originalWeights
        })
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return valuationWeightsSingleton.weightsCount()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ratingFactorCell", for: indexPath) as! RatingFactorCell
        
        let value =  valuationWeightsSingleton.value(forVariable: factorTitles[indexPath.row]) ?? 0
        cell.configure(value: value / max, title: factorTitles[indexPath.row], indexPath: indexPath, delegate: self)

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension RatingFactorSettingsTVC: RatingFactorCellDelegate {
    
    func userCompletedSetting(value: Double, path: IndexPath) {
        let factorTitle = factorTitles[path.row]
        
//        switch factorTitle {
//            case
//        }
    }
    
    
}
