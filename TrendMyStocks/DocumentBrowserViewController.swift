//
//  DocumentBrowserViewController.swift
//  StockTrends
//
//  Created by aDav on 10/12/2020.
//

import UIKit


class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate {
    
    var stockListVC: StocksListViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        
        allowsDocumentCreation = false
        allowsPickingMultipleItems = false
        
        // Update the style of the UIDocumentBrowserViewController
        // browserUserInterfaceStyle = .dark
        // view.tintColor = .white
        
        // Specify the allowed content types of your application via the Info.plist.
        
        // Do any additional setup after loading the view.
    }
    
    
    // MARK: UIDocumentBrowserViewControllerDelegate
    
//    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
//        let newDocumentURL: URL? = nil
//
//        // Set the URL for the new document here. Optionally, you can present a template chooser before calling the importHandler.
//        // Make sure the importHandler is always called, even if the user cancels the creation request.
//        if newDocumentURL != nil {
//            importHandler(newDocumentURL, .move)
//        } else {
//            importHandler(nil, .none)
//        }
//    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
        guard let sourceURL = documentURLs.first else { return }
        
        if let validStockList = stockListVC {
            validStockList.addStock(fileURL: sourceURL)
            self.dismiss(animated: true, completion: nil)
        }

    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        
        if let validStockList = stockListVC {
            validStockList.addStock(fileURL: sourceURL)
            self.dismiss(animated: true, completion: nil)
        }

    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
    }
    
//    // MARK: Document Presentation
//
//    func presentDocument(at documentURL: URL) {
//
//        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
//        let documentViewController = storyBoard.instantiateViewController(withIdentifier: "DocumentViewController") as! DocumentViewController
//        documentViewController.document = Document(fileURL: documentURL)
//        documentViewController.modalPresentationStyle = .fullScreen
//
//        present(documentViewController, animated: true, completion: nil)
//    }
}

extension DocumentBrowserViewController {
    
    func openRemoteDocument(_ inboundURL: URL, importIfNeeded: Bool) {
        self.revealDocument(at: inboundURL, importIfNeeded: importIfNeeded) { (url, error) in
            if let error = error {
              print("import did fail - should be communicated to user - \(error)")
            } else if let url = url {
              
                if let validStockList = self.stockListVC {
                    validStockList.addStock(fileURL: url)
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
}
