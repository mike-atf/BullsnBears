//
//  RimmedLabel.swift
//  Bulls'N'Bears
//
//  Created by aDav on 13/04/2021.
//

import UIKit

protocol SortLabelDelegate {
    func userSelectedLabel()
}

class RimmedLabel: UIView {

    var label: UILabel?
    var tap: UITapGestureRecognizer!
    var delegate: SortLabelDelegate?
    
    func configure(text: String?, delegate: SortLabelDelegate) {
        
        self.delegate = delegate
        
        label = UILabel(frame: CGRect.zero)
        label?.text = text
        label?.sizeToFit()
        label?.translatesAutoresizingMaskIntoConstraints = false
                
        addSubview(label!)
        
        self.heightAnchor.constraint(equalTo: label!.heightAnchor).isActive = true
        self.widthAnchor.constraint(equalTo: label!.widthAnchor,constant: 20).isActive = true
        label?.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        label?.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        tap = UITapGestureRecognizer(target: self, action: #selector(userTap))
        addGestureRecognizer(tap)
        
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        
        let currentSortParameter = (UserDefaults.standard.value(forKey: userDefaultTerms.sortParameter) as? String) ?? "userEvaluationScore"

        let path = UIBezierPath(roundedRect: rect.insetBy(dx: 5.0, dy: 5.0), cornerRadius: 2.5)
        path.lineWidth = 2.5

        if label?.text ?? "" == currentSortParameter {
            UIColor.link.setStroke()
        }
        else {
            self.backgroundColor?.setStroke()
        }
        
        path.stroke()
    }
    
    @objc
    func userTap() {
        UserDefaults.standard.setValue(label?.text ?? "userEvaluationScore", forKey: userDefaultTerms.sortParameter)
        setNeedsDisplay()
        delegate?.userSelectedLabel()
    }

}
