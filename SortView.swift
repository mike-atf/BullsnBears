//
//  SortView.swift
//  Bulls'N'Bears
//
//  Created by aDav on 13/04/2021.
//

import UIKit

protocol SortDelegate {
    func sortParameterChanged()
}

class SortView: UIView {

    @IBOutlet var height: NSLayoutConstraint!
    @IBOutlet var sortButton: UIButton!
    @IBOutlet var label: UILabel?
    
    var isActive = false
    var delegate: SortDelegate?
    var contentView: UIStackView?
    var scrollView: UIScrollView?
    var sortLabels: [RimmedLabel]?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
            
    }


    @IBAction func sortButtonAction(_ sender: UIButton) {
        
        isActive.toggle()
        
        if isActive {
            
            label?.isHidden = true
            sortButton.isHidden = true
            
            sortLabels = [RimmedLabel]()
            
            contentView = UIStackView()
            contentView?.axis = .horizontal
            contentView?.distribution = .equalSpacing
            contentView?.spacing = 15

            contentView?.translatesAutoresizingMaskIntoConstraints = false

            scrollView = UIScrollView(frame: CGRect.zero)
            scrollView?.translatesAutoresizingMaskIntoConstraints = false

            addSubview(scrollView!)
            scrollView?.addSubview(contentView!)

            let margins = self.layoutMarginsGuide
            
            scrollView?.topAnchor.constraint(equalTo: margins.topAnchor).isActive = true
            scrollView?.bottomAnchor.constraint(equalTo: margins.bottomAnchor).isActive = true
            scrollView?.leadingAnchor.constraint(equalTo: margins.leadingAnchor).isActive = true
            scrollView?.trailingAnchor.constraint(equalTo: margins.trailingAnchor).isActive = true

            contentView?.topAnchor.constraint(equalTo: scrollView!.topAnchor).isActive = true
            contentView?.bottomAnchor.constraint(equalTo: scrollView!.bottomAnchor).isActive = true
            contentView?.leadingAnchor.constraint(equalTo: scrollView!.leadingAnchor, constant: 10).isActive = true
            contentView?.trailingAnchor.constraint(equalTo: scrollView!.trailingAnchor, constant: -20).isActive = true
            contentView?.heightAnchor.constraint(equalTo: scrollView!.heightAnchor).isActive = true

            for sortTerm in sharesListSortParameter.options() {

                let newLabel: RimmedLabel = {
                    let label = RimmedLabel()
                    label.configure(text: sharesListSortParameter.displayTerm(term: sortTerm), delegate: self)
                    label.translatesAutoresizingMaskIntoConstraints = false
                    return label
                }()
                contentView?.addArrangedSubview(newLabel)
                sortLabels?.append(newLabel)
            }
        }
        else {
            label?.isHidden = false
            sortButton.isHidden = false
            contentView?.removeFromSuperview()
            contentView = nil
            scrollView?.removeFromSuperview()
            scrollView = nil
        }
        
        UIView.animate(withDuration: 1.0, delay: 0.01, usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 8.0, options: .curveEaseIn,
                       animations: {
                        self.height.constant = self.isActive ? 65 : 40
        },completion: nil)   }

}

extension SortView: SortLabelDelegate {
    
    func userSelectedLabel() {
        
        for label in self.sortLabels ?? [] {
            label.setNeedsDisplay()
        }
        
        let _ = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(updateSort) , userInfo: nil, repeats: false)

    }
    
    @objc
    func updateSort() {
        let sortParameters = SharesListSortParameter()
        let displayTerm = sortParameters.displayTerm(term:(UserDefaults.standard.value(forKey: userDefaultTerms.sortParameter) as? String) ?? "userEvaluationScore")
        self.label?.text = "Sorted by " + displayTerm
        
        self.sortButtonAction(self.sortButton)
        
        self.delegate?.sortParameterChanged()

    }
    
    
}
