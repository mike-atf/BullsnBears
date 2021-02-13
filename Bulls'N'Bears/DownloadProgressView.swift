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
}

class DownloadProgressView: UIView {

    @IBOutlet var title: UILabel!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var progressView: UIProgressView!
    
    var delegate: ProgressViewDelegate?
    
    class func instanceFromNib() -> DownloadProgressView {
            let view = UINib(nibName: "DownloadProgressView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! DownloadProgressView
//            view.backgroundColor = UIColor.systemBackground
            return view
    }
    
    func updateProgress(tasks: Int, completed: Int) {
        
        progressView.setProgress(Float(completed) / Float(tasks), animated: true)
            if completed >= tasks {
                delegate?.downloadComplete()
            }
//        setNeedsDisplay()
    }
            
    @IBAction func cancelAction(_ sender: UIButton) {
        delegate?.cancelRequested()
    }
    
}
