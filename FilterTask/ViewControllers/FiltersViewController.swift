//
//  FiltersViewController.swift
//  FilterTask
//
//  Created by Blintsov Sergey on 08/07/2019.
//  Copyright © 2019 Sergey Blintsov. All rights reserved.
//

import UIKit
import CoreImage

class FiltersViewController: UIViewController {
    @IBOutlet weak var takenImage: UIImageView!
    @IBOutlet weak var originalFilterButton: UIButton!
    @IBOutlet weak var gaussianBlurFilterButton: UIButton!
    @IBOutlet weak var sepiaFilterButton: UIButton!
    @IBOutlet weak var medianFilterButton: UIButton!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        if let imgData = ImageModel.imageData {
            ImageModel.modifiedImage = UIImage(data: imgData)!.fixOrientation()
            takenImage.image = UIImage(data: imgData)!.fixOrientation()
        } else {
            dismiss(animated: true, completion: nil)
        }
        
        
        
        if let img = ImageModel.imageData {
            originalFilterButton.setBackgroundImage(UIImage(data: img), for: .normal)
        }
        applySepiaFilter {
            DispatchQueue.main.async {
                self.sepiaFilterButton.imageView?.contentMode = .scaleAspectFill
                self.sepiaFilterButton.setBackgroundImage(ImageModel.modifiedImage, for: .normal)
            }
        }
        applyGaussianBlurFilter {
            DispatchQueue.main.async {
                self.gaussianBlurFilterButton.imageView?.contentMode = .scaleAspectFill
                self.gaussianBlurFilterButton.setBackgroundImage(ImageModel.modifiedImage, for: .normal)
            }
        }
        applyMedianFilter {
            DispatchQueue.main.async {
                self.medianFilterButton.imageView?.contentMode = .scaleAspectFill
                self.medianFilterButton.setBackgroundImage(ImageModel.modifiedImage, for: .normal)
            }
        }
    }
    
    
    
    @IBAction func originalButtonPressed(_ sender: UIButton) {
        takenImage.image = getOriginalImage()
    }
    
    @IBAction func gaussianBlurButtonPressed(_ sender: UIButton) {
        self.applyGaussianBlurFilter {
            DispatchQueue.main.async {
                self.takenImage.image = ImageModel.modifiedImage
            }
        }
    }
    
    @IBAction func medianButtonPressed(_ sender: UIButton) {
        self.applyMedianFilter {
            DispatchQueue.main.async {
                self.takenImage.image = ImageModel.modifiedImage
            }
        }
    }
    
    @IBAction func sepiaButtonPressed(_ sender: UIButton) {
        self.applySepiaFilter {
            DispatchQueue.main.async {
                self.takenImage.image = ImageModel.modifiedImage
            }
        }
    }
    
    @IBAction func shareButtonPressed(_ sender: UIButton) {
        if let img = ImageModel.modifiedImage {
            var filesToShare = [Any]()
            filesToShare.append(img)
            let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func newPhotoButtonPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    
    
    func getOriginalImage() -> UIImage? {
        if let img = ImageModel.imageData {
            ImageModel.modifiedImage = UIImage(data: img)?.fixOrientation()
            return ImageModel.modifiedImage!
        }
        return nil
    }
    
    func applyGaussianBlurFilter(completion:@escaping () -> ()) {
        DispatchQueue.global().async {
            guard let myImageView = UIImage(data: ImageModel.imageData!)?.fixOrientation() else { return }
            guard let cg = myImageView.cgImage else { return }
            
            let beginImage = CIImage(cgImage: cg)
            let context : CIContext = CIContext(options: nil)
            let inputParams : [String : Any]? = [kCIInputImageKey : beginImage, kCIInputRadiusKey: 1.0]
            let filter : CIFilter = CIFilter(name: "CIGaussianBlur", parameters: inputParams)!
            let outputImage : CIImage? = filter.outputImage!
            
            if let outputImage = outputImage {
                let cgImage : CGImage? = context.createCGImage(outputImage, from: outputImage.extent)!
                
                if let cg = cgImage {
                    let newImage = UIImage(cgImage: cg).fixOrientation()
                    ImageModel.modifiedImage = newImage
                    completion()
                }
            }
        }
    }
    
    func applyMedianFilter(completion:@escaping () -> ()) {
        DispatchQueue.global().async {
            guard let myImageView = UIImage(data: ImageModel.imageData!)?.fixOrientation() else { return }
            guard let cg = myImageView.cgImage else { return }
            
            let beginImage = CIImage(cgImage: cg)
            let context : CIContext = CIContext(options: nil)
            let inputParams : [String : Any]? = [kCIInputImageKey : beginImage]
            let filter : CIFilter = CIFilter(name: "CIMedianFilter", parameters: inputParams)!
            let outputImage : CIImage? = filter.outputImage!
            
            if let outputImage = outputImage {
                let cgImage : CGImage? = context.createCGImage(outputImage, from: outputImage.extent)!
                
                if let cg = cgImage {
                    let newImage = UIImage(cgImage: cg).fixOrientation()
                    ImageModel.modifiedImage = newImage
                    completion()
                }
            }
        }
    }
    
    func applySepiaFilter(completion:@escaping () -> ()) {
        DispatchQueue.global().async {
            guard let myImageView = UIImage(data: ImageModel.imageData!)?.fixOrientation() else { return }
            guard let cg = myImageView.cgImage else { return }
            
            let beginImage = CIImage(cgImage: cg)
            let context : CIContext = CIContext(options: nil)
            let inputParams : [String : Any]? = [kCIInputImageKey : beginImage, kCIInputIntensityKey: 2.0]
            let filter : CIFilter = CIFilter(name: "CISepiaTone", parameters: inputParams)!
            let outputImage : CIImage? = filter.outputImage!
            
            if let outputImage = outputImage {
                let cgImage : CGImage? = context.createCGImage(outputImage, from: outputImage.extent)!
                
                if let cg = cgImage {
                    let newImage = UIImage(cgImage: cg).fixOrientation()
                    ImageModel.modifiedImage = newImage
                    completion()
                }
            }
        }
    }
}



public extension UIImage {
    /// Extension to fix orientation of an UIImage without EXIF
    func fixOrientation() -> UIImage {
        guard let cgImage = cgImage else { return self }
        if imageOrientation == .up { return self }
        var transform = CGAffineTransform.identity
        
        switch imageOrientation {
            case .down, .downMirrored:
                transform = transform.translatedBy(x: size.width, y: size.height)
                transform = transform.rotated(by: CGFloat(Float.pi))
            
            case .left, .leftMirrored:
                transform = transform.translatedBy(x: size.width, y: 0)
                transform = transform.rotated(by: CGFloat(Float.pi/2))
            
            case .right, .rightMirrored:
                transform = transform.translatedBy(x: 0, y: size.height)
                transform = transform.rotated(by: CGFloat(-Float.pi/2))
            
            case .up, .upMirrored:
                break
        }
        
        switch imageOrientation {
            case .upMirrored, .downMirrored:
                transform.translatedBy(x: size.width, y: 0)
                transform.scaledBy(x: -1, y: 1)
            
            case .leftMirrored, .rightMirrored:
                transform.translatedBy(x: size.height, y: 0)
                transform.scaledBy(x: -1, y: 1)
            
            case .up, .down, .left, .right:
                break
        }
        
        if let ctx = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: cgImage.colorSpace!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
            ctx.concatenate(transform)
            switch imageOrientation {
                case .left, .leftMirrored, .right, .rightMirrored:
                    ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
                
                default:
                    ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            }
            
            if let finalImage = ctx.makeImage() {
                return (UIImage(cgImage: finalImage))
            }
        }
        return self
    }
}
