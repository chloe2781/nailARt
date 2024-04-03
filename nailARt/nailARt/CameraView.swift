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
        super.layoutSublayers(of: layer) //Thread 1: EXC_BAD_ACCESS (code=1, address=0x8) when hand leaves screen/points disappear
        if layer == previewLayer {
            overlayLayer.frame = layer.bounds
        }
    }

    private func setupOverlay() {
        previewLayer.addSublayer(overlayLayer)
    }
    
//    func showPoints(_ points: [CGPoint], color: UIColor) {
//        pointsPath.removeAllPoints()
//        for point in points {
//            pointsPath.move(to: point)
//            pointsPath.addArc(withCenter: point, radius: 5, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
//        }
//        overlayLayer.fillColor = color.cgColor
//        CATransaction.begin()
//        CATransaction.setDisableActions(true)
//        overlayLayer.path = pointsPath.cgPath
//        CATransaction.commit()
//    }
    

    
    func showPoints(_ points: [CGPoint], color: UIColor, rotationAngle: CGFloat) {
        // Clear previous points
        clearPoints()
        
        guard let nailImage = UIImage(named: "nail9") else {
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
//                        // Calculate the origin of the frame to center the rotated nail image at the specified point
//                        let origin = CGPoint(x: point.x - rotatedNailImage.size.width / 2, y: point.y - rotatedNailImage.size.height / 2)
//                        
//                        // Create a UIImageView to hold the rotated nail image
//                        let imageView = UIImageView(image: rotatedNailImage)
//                        imageView.frame = CGRect(origin: origin, size: rotatedNailImage.size)
//
//                        // Add the UIImageView to the CameraView
//                        addSubview(imageView)
//
//                        // Store the UIImageView for later removal
//                        drawnLayers.append(imageView.layer)
            }
              
//            let rotatedRect = rotatedRectangle(at: point, size: CGSize(width: nailWidth, height: nailHeight), rotationAngle: rotationAngle)
//            let rectangleLayer = CALayer()
//            rectangleLayer.bounds = CGRect(origin: .zero, size: rotatedRect.size)
//            rectangleLayer.position = rotatedRect.origin
//            rectangleLayer.setAffineTransform(CGAffineTransform(rotationAngle: rotationAngle))
//            rectangleLayer.cornerRadius = 10
//            rectangleLayer.backgroundColor = UIColor.black.cgColor
//            layer.addSublayer(rectangleLayer)
//            drawnLayers.append(rectangleLayer)
        }
    }

    private func rotatedRectangle(at origin: CGPoint, size: CGSize, rotationAngle: CGFloat) -> CGRect {
        let center = CGPoint(x: origin.x + size.width / 2, y: origin.y + size.height / 2)
        let rotatedCenter = center.applying(CGAffineTransform(rotationAngle: rotationAngle))
        return CGRect(x: rotatedCenter.x - size.width / 2, y: rotatedCenter.y - size.height / 2, width: size.width, height: size.height)
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
    }
    
    func hideNailImages() {
        for subview in subviews {
            if let imageView = subview as? UIImageView {
                imageView.isHidden = true
            }
        }
    }
        
    
//    func rotateRectangles(by angle: Double) {
//        // Apply rotation transformation to each rectangle layer
//        for layer in drawnLayers {
//            var transform = CATransform3DIdentity
//            transform = CATransform3DTranslate(transform, layer.bounds.midX, layer.bounds.midY, 0)
//            transform = CATransform3DRotate(transform, CGFloat(angle), 0, 0, 1)
//            transform = CATransform3DTranslate(transform, -layer.bounds.midX, -layer.bounds.midY, 0)
//            layer.transform = transform
//        }
//    }
}
