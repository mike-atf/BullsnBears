//
//  WBVRatingButton.swift
//  Bulls'N'Bears
//
//  Created by aDav on 03/03/2021.
//

import UIKit

protocol RatingButtonDelegate: NSObject {
    func updateRating(rating:Int, parameter: String)
}

class WBVRatingButton: UIView {
    
    @IBOutlet var stackView: UIStackView!
    
    var rating: Int?
    var wbvParameter: String!
    var delegate: RatingButtonDelegate!
    var oneTapRecognizer: UITapGestureRecognizer!
    var allStars:[UIImageView]!
    var starColor: UIColor!
    var higherIsBetter: Bool!
    weak var cell: ValueListRatingCell?
    var userInteracted = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        oneTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(singleTap))
        addGestureRecognizer(oneTapRecognizer)
        
        rating = 0
        
        allStars = [UIImageView]()
        
        starColor = UIColor.systemGray
        updateStackView()

    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        oneTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(singleTap))
        addGestureRecognizer(oneTapRecognizer)
        
        rating = 0
        
        allStars = [UIImageView]()
        
        starColor = UIColor.systemGray
        higherIsBetter = true
        updateStackView()

    }

    
    func configure(rating: Int?, delegate: RatingButtonDelegate, parameter: String, cell: ValueListRatingCell) {
        
        self.rating = rating
        self.delegate = delegate
        self.wbvParameter = parameter
        self.cell = cell
        
        higherIsBetter = WBVParameters().isHigherBetter(for: parameter)

        starColor = GradientColorFinder.cleanRatingColor(for: rating ?? 0, higherIsBetter: higherIsBetter)// GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 10, value: Double(rating))
        setNeedsDisplay()
    }
    

    override func draw(_ rect: CGRect) {
        
        updateStackView()
    
        for star in allStars {
            stackView.addArrangedSubview(star)
        }
    }
    
    @objc
    func singleTap() {
        
        userInteracted = true
        
        var validRating = self.rating ?? 0
        
        validRating += 1
        if validRating > 10 {
            validRating -= 11
        }

        starColor = GradientColorFinder.cleanRatingColor(for: validRating, higherIsBetter: higherIsBetter) // GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 10, value: Double(rating), greenCutoff: 9, redCutOff: 1)
        delegate.updateRating(rating: validRating, parameter: wbvParameter)
        self.setNeedsDisplay()
        cell?.updateText(rating: validRating)
        
        self.rating = validRating
    }
        
    private func updateStackView() {
        
        for star in allStars {
            star.removeFromSuperview()
        }
        allStars.removeAll()

        for _ in 0..<(self.rating ?? 0) {
            let view = UIImageView(image: UIImage.init(systemName: "star.fill")!)
            view.tintColor = starColor
            allStars.append(view)
        }
        
        for _ in (self.rating ?? 0)..<10 {
            let view = UIImageView(image: UIImage.init(systemName: "star")!)
            view.tintColor = UIColor.systemGray
            allStars.append(view)
        }
        
    }


}
