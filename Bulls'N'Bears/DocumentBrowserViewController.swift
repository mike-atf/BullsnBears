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
        
    }
    
    
    // MARK: UIDocumentBrowserViewControllerDelegate
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
        
        guard let sourceURL = documentURLs.first else { return }
        
        if sourceURL.startAccessingSecurityScopedResource() {
            let localURL = copyFileToDocumentDirectory(url: sourceURL)
            sourceURL.stopAccessingSecurityScopedResource()
            
            if let validStockList = stockListVC {
                if let validUrl = localURL {
                    validStockList.addShare(fileURL: validUrl)
                }
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func copyFileToDocumentDirectory(url: URL) -> URL? {
        
        let appDocumentPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if let documentFolder = appDocumentPaths.first {
            let copyFilePath = documentFolder + "/" + url.lastPathComponent

            if FileManager.default.fileExists(atPath: copyFilePath) {
                do {
                    //remove any existing file
                    try FileManager.default.removeItem(atPath: copyFilePath)
                } catch let error {
                    ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "File removing error")
                }
            }
            
            let copyToURL = URL(fileURLWithPath: copyFilePath)
            do {
                // dont use 'fileURL.startAccessingSecurityScopedResource()' on App sandbox /Documents folder as access is always granted and the access request will alwys return false
                try FileManager.default.copyItem(at: url, to: copyToURL)
                return copyToURL
            } catch let error {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "File copying error")
            }
        }
        return nil
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        
        if let validStockList = stockListVC {
            validStockList.addShare(fileURL: sourceURL)
            self.dismiss(animated: true, completion: nil)
        }

    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "can't import file")
        
    }
    
}

extension DocumentBrowserViewController {
    
    func openRemoteDocument(_ inboundURL: URL, importIfNeeded: Bool) {
        self.revealDocument(at: inboundURL, importIfNeeded: importIfNeeded) { (url, error) in
            if let error = error {
                ErrorController.addErrorLog(errorLocation: #file + "." + #function, systemError: error, errorInfo: "File import failure error")
            } else if let url = url {
              
                if let validStockList = self.stockListVC {
                    validStockList.addShare(fileURL: url)
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
}
