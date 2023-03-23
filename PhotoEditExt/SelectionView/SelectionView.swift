//
//  BlurSelectionView.swift
//  PhotoEditExt
//
//  Created by Yudiz Solutions Ltd on 14/03/23.
//

import UIKit

class SelectionView: ResizeViews {
    
    @IBOutlet weak var imgView: UIImageView!
    
    var lastRotation : CGFloat = 0.0
    
    override func awakeFromNib() {
        prepareViewUI()
    }
}

//MARK: - UI Related methods
extension SelectionView {
    
    func prepareViewUI() {
        originalSize = self.bounds
        
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(didPinch(_:)))
        self.addGestureRecognizer(pinchGestureRecognizer)
    }
    
    @objc private func didPinch(_ sender: UIPinchGestureRecognizer) {
        let pinchScale: CGFloat = sender.scale
        
        
        if (self.bounds.size.height * pinchScale >= originalBounds.height && self.bounds.size.width * pinchScale >= originalBounds.width) && (self.bounds.size.height * pinchScale < self.superview!.frame.height && self.bounds.size.width * pinchScale < self.superview!.frame.width) {
            self.bounds.size.height *= pinchScale
            self.bounds.size.width *= pinchScale
        }
        sender.scale = 1.0
        
        switch sender.state {
        case .ended, .cancelled, .failed:
            self.gestureRecognizers?.forEach {
                $0.isEnabled = true
            }
            
            if let scroolView = self.superview?.superview as? UIScrollView {
                scroolView.isScrollEnabled = true
            }
        default:
            break
        }
    }
    
    func rotation(from transform: CGAffineTransform) -> Double {
        return atan2(Double(transform.b), Double(transform.a))
    }
}

//MARK: - Button Actions
extension SelectionView {
    
    @IBAction func btnCloseTap(_ sender: UIButton) {
        self.removeFromSuperview()
    }
}
