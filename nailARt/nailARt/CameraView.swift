/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The camera view shows the feed from the camera, and renders the points
     returned from VNDetectHumanHandpose observations.
*/

import UIKit
import AVFoundation

class CameraView: UIView {

    private var overlayLayer = CAShapeLayer()
    private var pointsPath = UIBezierPath()
    var drawnLayers: [CALayer] = []
    
    // image files are 2048
    var nailWidth: CGFloat = 2048 * 0.05
    var nailHeight: CGFloat = 2048 * 0.05

    var curNail: String = "nail1"

    var previewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupOverlay()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupOverlay()
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        if layer == previewLayer {
            overlayLayer.frame = layer.bounds
        }
    }

    private func setupOverlay() {
        previewLayer.addSublayer(overlayLayer)
    }
    
    func showPoints(_ points: [CGPoint], color: UIColor, rotationAngle: CGFloat, middleTipPoint: CGPoint?, middlePipPoint: CGPoint?) {
        // Clear previous points
        clearPoints()
        
        guard let nailImage = UIImage(named: curNail) else {
            print("Failed to load nail image")
            return
        }

        // draw rectangles at the specified points
        for point in points {
            if let rotatedNailImage = rotatedImage(image: nailImage, rotationAngle: rotationAngle) {
                //calculate the origin of the frame to center the nail image at the specified point

                //                    print("rotation \(rotationAngle)")
                let origin = CGPoint(x: point.x - nailWidth / 2, y: point.y - nailHeight / 2)

                // UIImageView to hold the nail image
                let imageView = UIImageView(image: nailImage)
                imageView.frame = CGRect(origin: origin, size: CGSize(width: nailWidth, height: nailHeight))

                // apply rotation transformation to the UIImageView
                imageView.transform = CGAffineTransform(rotationAngle: rotationAngle)

                // add the UIImageView to the CameraView
                addSubview(imageView)

                // store the UIImageView for later removal
                drawnLayers.append(imageView.layer)
            }
              
        }
        
        // Draw points at middle tip and middle PIP points if available
//        if let middleTip = middleTipPoint {
//            let middleTipPointView = UIView(frame: CGRect(x: middleTip.x - 2.5, y: middleTip.y - 2.5, width: 5, height: 5))
//            middleTipPointView.backgroundColor = UIColor.red
//            middleTipPointView.tag = 100 // Unique tag for middle tip point
//            addSubview(middleTipPointView)
//        }
//
//        if let middlePip = middlePipPoint {
//            let middlePipPointView = UIView(frame: CGRect(x: middlePip.x - 2.5, y: middlePip.y - 2.5, width: 5, height: 5))
//            middlePipPointView.backgroundColor = UIColor.blue
//            middlePipPointView.tag = 101 // Unique tag for middle Pip point
//            addSubview(middlePipPointView)
//        }
        
        
        
    }
    
    
    private func rotatedImage(image: UIImage, rotationAngle: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // move the origin to the center of the image so that it rotates around the center
        context.translateBy(x: image.size.width / 2, y: image.size.height / 2)
        context.rotate(by: rotationAngle)
        
        // draw the image
        image.draw(in: CGRect(x: -image.size.width / 2, y: -image.size.height / 2, width: image.size.width, height: image.size.height))
        
        // get rotated image from the context
        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return rotatedImage
    }
    
    func clearPoints() {
        for layer in drawnLayers {
            // Check if the layer's superlayer is not nil before removing it
            if layer.superlayer != nil {
                layer.removeFromSuperlayer()
            }
        }
        drawnLayers.removeAll()
        
        // Remove previously drawn middle tip and middle PIP points
         for subview in subviews {
             if subview.tag == 100 || subview.tag == 101 {
                 subview.removeFromSuperview()
             }
         }
    }
    
    func hideNailImages() {
        for subview in subviews {
            if let imageView = subview as? UIImageView {
                imageView.isHidden = true
            }
        }
    }
    
}
