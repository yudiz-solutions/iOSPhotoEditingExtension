//
//  EditImageVC.swift
//  PhotoEditExt
//
//  Created by Yudiz Solutions Ltd on 14/03/23.
//

import UIKit

enum PhotoEffectType: Int {
    case blur, pixelBlur, color
}


class EditImageVC: UIViewController {
    
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var scalableView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var dataImage: UIImage!//Image that comes from photos app.
    var scaleRatio: CGFloat = 1.0
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
}

//MARK: - UI Related methods
extension EditImageVC {
    
    func prepareUI() {
        ///Set image in scrollview
        imgView.image = dataImage
        imgView.isHidden = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let weakSelf = self else {return}
            weakSelf.imgView.isHidden = false
            let minScale = weakSelf.getScrollViewMinScale()
            weakSelf.scrollView.minimumZoomScale = minScale > 1 ? 1 : minScale
            weakSelf.scrollView.maximumZoomScale = (minScale > 1 ? 1 : minScale) * 2
            weakSelf.scrollView.zoomScale = minScale > 1 ? 1 : minScale
            weakSelf.imgView.contentMode = .scaleAspectFit
            var top: CGFloat?
            var left: CGFloat?
            if weakSelf.scalableView.frame.height < weakSelf.scrollView.frame.height {
                top = (weakSelf.scrollView.frame.height - weakSelf.scalableView.frame.height)/2
            }
            if weakSelf.scalableView.frame.width < weakSelf.scrollView.frame.width {
                left = (weakSelf.scrollView.frame.width - weakSelf.scalableView.frame.width)/2
            }
            weakSelf.scrollView.contentInset = UIEdgeInsets(top: top ?? 0, left: left ?? 0, bottom: top ?? 0, right: left ?? 0)
        }
    }
    
    func getScrollViewMinScale() -> CGFloat {
        let scrollViewFrame = scrollView.frame
        let scaleWidth = scrollViewFrame.size.width / scalableView.bounds.width
        let scaleHeight = scrollViewFrame.size.height / scalableView.bounds.height
        return min(scaleHeight, scaleWidth)
    }
}

//MARK: - Button Actions
extension EditImageVC {
    
    @IBAction func btnAddSelectViewTap(_ sender: UIButton) {
        ///Add selection view on image
        let minScale = getScrollViewMinScale()
        let rect = scrollView.convert(scrollView.bounds, to: scalableView)
        let tView = (Bundle.main.loadNibNamed("SelectionView", owner: nil, options: nil)?.first as! SelectionView)
        scalableView.addSubview(tView)
        tView.frame = CGRect(x: rect.midX, y: rect.midY, width: tView.bounds.width, height: tView.bounds.height)
        if minScale < 1 {
            let scaleRatio = (1 / scrollView.minimumZoomScale)
            self.scaleRatio = scaleRatio
            tView.transform = CGAffineTransform(scaleX: scaleRatio, y: scaleRatio)
        } else {
            let scalRatio = 1.0
            self.scaleRatio = scalRatio
            tView.transform = CGAffineTransform(scaleX: abs(scalRatio), y: abs(scalRatio))
        }
        tView.originalSize = tView.frame
        tView.originalBounds = tView.bounds
    }
    
    @IBAction func btnEffectsTap(_ sender: UIButton) {
        ///Add Effect in selected image portion
        let arrBlurView = scalableView.subviews.map({$0 as? SelectionView})
        arrBlurView.forEach { vblur in
            if let vBlur = vblur {
                let tZone = vBlur.superview!.convert(vBlur.frame, to: scalableView)
                var tempRect: CGRect!
                if scaleRatio == 1.0 {
                    tempRect = CGRect(x: tZone.minX + 9, y: tZone.minY + 9, width: tZone.width - 16, height: tZone.height - 16)
                } else {
                    tempRect = CGRect(x: (tZone.minX + 72), y: (tZone.minY + 72), width: tZone.width - ((scaleRatio/2) * 48), height: tZone.height - ((scaleRatio/2) * 48))
                }
                if let resultImg = applyEffectInRect(rect: tempRect, withEffect: PhotoEffectType.init(rawValue: sender.tag)!) {
                    imgView.image = resultImg
                }
            }
            vblur?.removeFromSuperview()
        }
        self.dismiss(animated: true, completion: nil)
    }
}

//MARK: - ScrollView Delegate methods
extension EditImageVC: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scalableView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView.frame.height > scalableView.frame.height || scrollView.frame.width > scalableView.frame.width {
            var top: CGFloat?
            var left: CGFloat?
            if scrollView.frame.height > scalableView.frame.height {
                top = (scrollView.frame.height - scalableView.frame.height)/2
            }
            if scrollView.frame.width > scalableView.frame.width {
                left = (scrollView.frame.width - scalableView.frame.width)/2
            }
            scrollView.contentInset = UIEdgeInsets(top: top ?? 0, left: left ?? 0, bottom: top ?? 0, right: left ?? 0)
        } else {
            scrollView.contentInset = UIEdgeInsets.zero
        }
    }
    
}

//MARK: - Images blur related methods
extension EditImageVC {
    
     func getImageFromRect(rect: CGRect) -> UIImage? {
         if let cg = imgView.image?.cgImage, let mySubimage = cg.cropping(to: rect) {
             return UIImage(cgImage: mySubimage)
         }
         return nil
     }

     func addEffect(image: UIImage, withEffect effect: PhotoEffectType) -> UIImage? {
         let inputImage = UIKit.CIImage(cgImage: image.cgImage!)         
         switch effect {
         case .blur:
             if let filter = CIFilter(name: "CIGaussianBlur") {
                 filter.setValue(inputImage, forKey: kCIInputImageKey)
                 filter.setValue(20, forKey: kCIInputRadiusKey)
                 if let blurred = filter.outputImage {
                     return UIImage(ciImage: blurred)
                 }
             }
         case .pixelBlur:
             if let filter = CIFilter(name: "CIPixellate") {
                 filter.setValuesForKeys([kCIInputImageKey: inputImage, "inputScale":100.0])
                 if let blurred = filter.outputImage {
                     return UIImage(ciImage: blurred)
                 }
             }
         case .color:
             if let sepiaFilter = CIFilter(name:"CIEdges") {
                 sepiaFilter.setValue(inputImage, forKey: kCIInputImageKey)
                 sepiaFilter.setValue(12, forKey: kCIInputIntensityKey)
                 if let spial = sepiaFilter.outputImage {
                     return UIImage(ciImage: spial)
                 }
             }
         }
         return nil
     }

     func drawImageInRect(inputImage: UIImage, inRect imageRect: CGRect) -> UIImage {
         UIGraphicsBeginImageContext(imgView.image!.size)
         imgView.image!.draw(in: CGRect(x: 0.0, y: 0.0, width: imgView.image!.size.width, height: imgView.image!.size.height))
         inputImage.draw(in: imageRect)
         let newImage = UIGraphicsGetImageFromCurrentImageContext()
         UIGraphicsEndImageContext()
         return newImage!
     }

     func applyEffectInRect(rect: CGRect, withEffect effect: PhotoEffectType) -> UIImage? {
         if let subImage = getImageFromRect(rect: rect),
             let blurredZone = addEffect(image: subImage,withEffect: effect) {
             return drawImageInRect(inputImage: blurredZone, inRect: rect)
         }
         return nil
     }
}
