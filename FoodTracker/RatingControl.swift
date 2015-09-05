//
//  RatingControl.swift
//  FoodTracker
//
//  Created by Jason Smith on 9/5/2558 BE.
//
//

import UIKit

class RatingControl: UIView {
    // MARK: Properties
    
    var spacing = 5
    var starCount = 5
    var ratingButtons = [UIButton]()
    var rating = 0 {
        didSet {
            print("New rating: \(rating)")
            setNeedsLayout()
        }
    }
    
    // MARK: Initialization
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let empty  = UIImage(named: "emptyStar")
        let filled = UIImage(named: "filledStar")
        
        for _ in 0..<starCount {
            let button = UIButton()
            
            button.setImage(empty, forState: .Normal)
            button.setImage(filled, forState: .Selected)
            button.setImage(filled, forState: [.Highlighted, .Selected])
            
            button.adjustsImageWhenHighlighted = false
            
            button.addTarget(self, action: "ratingButtonTapped:", forControlEvents: .TouchDown)
            ratingButtons += [button]
            addSubview(button)
        }
        
        print("Finished RatingControl init")
    }
    
    override func layoutSubviews() {
        // Set the button's width and height to a square the size of the frame.
        let buttonSize = Int(frame.size.height)
        
        var buttonFrame = CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize)
        for (i, button) in ratingButtons.enumerate() {
            buttonFrame.origin.x = CGFloat(i * (buttonSize + spacing))
            button.frame = buttonFrame
        }
        updateButtonSelectionStates()
    }
    
    // MARK: Button Action
    
    func ratingButtonTapped(button: UIButton) {
        print("Button pressed")
        rating = ratingButtons.indexOf(button)! + 1
        updateButtonSelectionStates()
    }
    
    func updateButtonSelectionStates() {
        for (i, button) in ratingButtons.enumerate() {
            button.selected = (i < rating)
        }
    }
}
