//
//  Diary_StocksListVC.swift
//  Bulls'N'Bears
//
//  Created by aDav on 10/10/2021.
//

import UIKit
import CoreData

class Diary_StocksListVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    
    var controller: StocksController2 = {
        
        let request = NSFetchRequest<Share>(entityName: "Share")

        let transactionsPredicate = NSPredicate(format: "transactions.@count > 0")
    
        request.predicate = transactionsPredicate
        request.sortDescriptors = [NSSortDescriptor(key: "watchStatus", ascending: true)]
        
        let sL = StocksController2(fetchRequest: request, managedObjectContext: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext, sectionNameKeyPath: "watchStatus", cacheName: nil)
        
        do {
            try sL.performFetch()
        } catch let error as NSError {
            ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "can't fetch files")
        }
        return sL
    }()

    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "DiaryListCell", bundle: nil), forCellReuseIdentifier: "diaryListCell")
        
        if controller.fetchedObjects?.count ?? 0 > 0 {
            tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
            performSegue(withIdentifier: "showDiaryDetailSegue", sender: nil)
            tableView.deselectRow(at: IndexPath(row: 0, section: 0), animated: false)
        }


    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        splitViewController?.dismiss(animated: true, completion: nil)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return controller.sections?.count ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return controller.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "diaryListCell", for: indexPath) as! DiaryListCell
        
        cell.configure(share: controller.object(at: indexPath))
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        performSegue(withIdentifier: "showDiaryDetailSegue", sender: nil)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionTitles = ["Watch list", "Stocks owned", "Archived stocks"]
        
        return sectionTitles[section]
    }



    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
           guard let indexPath = tableView.indexPathForSelectedRow else { return }
        
            if let detailView = segue.destination as? DiaryDetailVC {
               
                detailView.share = controller.object(at: indexPath)
                
            }
            else if let navView = segue.destination as? UINavigationController {
                if let detailView = navView.topViewController as? DiaryDetailVC {
                        
                    detailView.share = controller.object(at: indexPath)
                }
            }
    }

}
