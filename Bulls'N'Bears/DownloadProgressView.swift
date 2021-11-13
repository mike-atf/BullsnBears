//
//  DownloadProgressView.swift
//  Bulls'N'Bears
//
//  Created by aDav on 07/02/2021.
//

import UIKit

protocol ProgressViewDelegate: AnyObject {
    func progressUpdate(allTasks: Int, completedTasks: Int)
    func cancelRequested()
    func downloadComplete()
    func downloadError(error: String)
}

class DownloadProgressView: UIView {

    @IBOutlet var title: UILabel!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var progressView: UIProgressView!
    
    var delegate: ProgressViewDelegate?
    
    class func instanceFromNib() -> DownloadProgressView {
            let view = UINib(nibName: "DownloadProgressView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! DownloadProgressView
            return view
    }
    
    func updateProgress(tasks: Int, completed: Int) {
        
        DispatchQueue.main.async {
            self.progressView.setProgress(Float(completed) / Float(tasks), animated: true)
                if completed >= tasks {
                    self.delegate?.downloadComplete()
                }
        }
    }
            
    @IBAction func cancelAction(_ sender: UIButton) {
        
        DispatchQueue.main.async {
            self.delegate?.cancelRequested()
        }
    }
    
}
