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
    
    var rating: Int!
    var wbvParameter: String!
    var delegate: RatingButtonDelegate!
    var oneTapRecognizer: UITapGestureRecognizer!
    var doubleTapRecognizer: UITapGestureRecognizer!
    var filledStars: [UIImage]!
    var emptyStars: [UIImage]!
    var emptyColor = UIColor.systemGray
    var allStars: [UIImageView]!
    var starColor: UIColor!
    
    func configure(rating: Int, delegate: RatingButtonDelegate, parameter: String) {
        
        self.rating = rating
        self.delegate = delegate
        self.wbvParameter = parameter
        
        oneTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(singleTap))
        doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTap))
        doubleTapRecognizer.numberOfTapsRequired = 2
        addGestureRecognizer(oneTapRecognizer)
        addGestureRecognizer(doubleTapRecognizer)
        filledStars = [UIImage]()
        emptyStars = [UIImage]()
        
        for _ in 0..<rating {
            filledStars.append(UIImage.init(systemName: "star.fill")!)
        }
        for _ in rating...10 {
            emptyStars.append(UIImage.init(systemName: "star")!)
        }
        
        allStars = [UIImageView]()
        stackView.distribution = .fillEqually
        stackView.spacing = 0.2 * stackView.frame.width / CGFloat(allStars.count)

        starColor = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 10, value: Double(rating))
    }

    override func draw(_ rect: CGRect) {
        
//
//        let starCount = CGFloat(emptyStars.count + filledStars.count)
//        let margins = layoutMarginsGuide
//        let gapWidth: CGFloat = 0.25 // of slotWidth
//        let starSlotWidth = (rect.width / CGFloat(starCount + (starCount + 1) * gapWidth))
//
//
            updateStackView()
    }
    
    @objc
    func singleTap() {
        guard rating < 11 else { return }
        
        rating += 1
        filledStars.append(UIImage.init(systemName: "star.fill")!)
        emptyStars = emptyStars.dropLast(1)
        starColor = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 10, value: Double(rating))
        delegate.updateRating(rating: rating, parameter: wbvParameter)
    }
    
    @objc
    func doubleTap() {
        guard rating > -1 else { return }
        
        rating -= 1
        emptyStars.append(UIImage.init(systemName: "star")!)
        filledStars = filledStars.dropLast(1)
        starColor = GradientColorFinder.gradientColor(lowerIsGreen: false, min: 0, max: 10, value: Double(rating))
        delegate.updateRating(rating: rating, parameter: wbvParameter)

    }
    
    private func updateStackView() {
        for star in allStars {
            star.removeFromSuperview()
        }
        allStars.removeAll()
        
        for empty in emptyStars {
            let view = UIImageView(image: empty)
            allStars.append(view)
        }
        
        for filled in filledStars {
            let view = UIImageView(image: filled)
            allStars.append(view)
        }
//
//        for star in allStars {
//            stackView.addArrangedSubview(star)
//            stackView.distribution = .fillEqually
//        }
    }


}
