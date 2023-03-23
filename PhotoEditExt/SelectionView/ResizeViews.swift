//
//  ResizeViews.swift
//  PhotoEditExt
//
//  Created by Yudiz Solutions Ltd on 14/03/23.
//

import UIKit

class ResizeViews: ConstrainedView {
    
    
    var isResizingLL = true
    var isResizingLeftEdge:Bool = false
    var isResizingRightEdge:Bool = false
    var isResizingTopEdge:Bool = false
    var isResizingBottomEdge:Bool = false
    
    
    var touchStart: CGPoint = CGPoint.zero
    let kResizeThumbSize: CGFloat = 22
    var originalSize: CGRect!
    var originalBounds: CGRect!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
        originalSize = self.bounds
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //
        
        if let scroolView = self.superview?.superview as? UIScrollView {
            scroolView.isScrollEnabled = false
        }
        self.touchStart = touches.first!.location(in: self)
        
        isResizingLeftEdge = (touchStart.x < kResizeThumbSize)
        isResizingTopEdge = (touchStart.y < kResizeThumbSize)
        isResizingRightEdge = (self.bounds.size.width - touchStart.x < kResizeThumbSize)
        isResizingBottomEdge = (self.bounds.size.height - touchStart.y < kResizeThumbSize)
        
        self.isResizingLL = (touchStart.x < kResizeThumbSize && self.bounds.size.height - touchStart.y < kResizeThumbSize)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touchPoint = touches.first!.location(in: self)
        let previous = touches.first!.previousLocation(in: self)
        
        let deltaWidth =  previous.x - touchPoint.x
        let deltaHeight = previous.y - touchPoint.y

        let width = self.frame.size.width;
        let height = self.frame.size.height;
        
        
        let originFrame = self.frame
        var finalFrame: CGRect = originFrame
        
        if isResizingLL {
            let distance = CGPoint(x: 1.0 - (-deltaWidth / width),
                                   y: 1.0 - (deltaHeight / height))
            
            let scale = (distance.x + distance.y) * 0.5
            
            finalFrame.size.width = width * scale
            finalFrame.size.height = height * scale
            finalFrame.origin.x = originFrame.maxX - finalFrame.size.width
        } else if isResizingBottomEdge {
            finalFrame.size.height += -deltaHeight * 2 //height * scale * 2
        } else if isResizingTopEdge{
            finalFrame.size.height += deltaHeight * 2
            finalFrame.origin.y = originFrame.maxY - finalFrame.size.height
        } else if isResizingLeftEdge{
            finalFrame.size.width += deltaWidth * 2
            finalFrame.origin.x = originFrame.maxX - finalFrame.size.width
        } else if isResizingRightEdge {
            finalFrame.size.width += -deltaWidth * 2
        } else {
            //                not dragging from a corner -- move the view
            //                If not using pan gesture then open
            let newCenter = CGPoint(x: self.center.x + touchPoint.x - touchStart.x,
                                    y: self.center.y + touchPoint.y - touchStart.y)
            
            
            if (newCenter.x + self.bounds.midX <= self.superview!.bounds.maxX + 20 && newCenter.x - self.bounds.midX >= self.superview!.bounds.minX - 20 && newCenter.y + self.bounds.midY <= self.superview!.bounds.maxY + 20 && newCenter.y - self.bounds.midY >= self.superview!.bounds.minY - 20) {
                self.center = newCenter
            }
            return
        }
        
        
        if (finalFrame.height < originalSize.height/1.2 || finalFrame.width < originalSize.width/2) {
            return
        }
        
        if (finalFrame.maxX - 20 <= self.superview!.bounds.maxX && finalFrame.minX + 20 >= self.superview!.bounds.minX && finalFrame.maxY - 20 <= self.superview!.bounds.maxY && finalFrame.minY + 20 >= self.superview!.bounds.minY) {
            self.gestureRecognizers?.forEach {
                $0.isEnabled = false
            }
            self.frame = finalFrame
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.gestureRecognizers?.forEach {
            $0.isEnabled = true
        }
        
        if let scroolView = self.superview?.superview as? UIScrollView {
            scroolView.isScrollEnabled = true
        }
    }
}

/// This View contains collection of Horizontal and Vertical constrains. Who's constant value varies by size of device screen size.
class ConstrainedView: UIView {
    
    // MARK: Outlets
    @IBOutlet var horizontalConstraints: [NSLayoutConstraint]?
    @IBOutlet var verticalConstraints: [NSLayoutConstraint]?
    
    // MARK: Awaken
    override func awakeFromNib() {
        super.awakeFromNib()
        constraintUpdate()
    }
    
    func constraintUpdate() {
        if let hConts = horizontalConstraints {
            for const in hConts {
                let v1 = const.constant
                let v2 = v1 * _widthRatio
                const.constant = v2
            }
        }
        if let vConst = verticalConstraints {
            for const in vConst {
                let v1 = const.constant
                let v2 = v1 * _heightRatio
                const.constant = v2
            }
        }
    }
}

let _heightRatio : CGFloat = {
    let ratio = screenSize.height / 667
    return ratio
}()

let _widthRatio : CGFloat = {
    let ratio = screenSize.width / 375
    return ratio
}()

let screenSize     = UIScreen.main.bounds.size
let screenFrame    = UIScreen.main.bounds
