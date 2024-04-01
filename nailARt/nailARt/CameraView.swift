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
    
    var nailWidth: CGFloat = 25
    var nailHeight: CGFloat = 40


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

        // draw rectangles at the specified points
        for point in points {
            let rotatedRect = rotatedRectangle(at: point, size: CGSize(width: nailWidth, height: nailHeight), rotationAngle: rotationAngle)
            let rectangleLayer = CALayer()
            rectangleLayer.bounds = CGRect(origin: .zero, size: rotatedRect.size)
            rectangleLayer.position = rotatedRect.origin
            rectangleLayer.setAffineTransform(CGAffineTransform(rotationAngle: rotationAngle))
            rectangleLayer.cornerRadius = 10
            rectangleLayer.backgroundColor = UIColor.black.cgColor
            layer.addSublayer(rectangleLayer)
            drawnLayers.append(rectangleLayer)
        }
    }

    private func rotatedRectangle(at origin: CGPoint, size: CGSize, rotationAngle: CGFloat) -> CGRect {
        let center = CGPoint(x: origin.x + size.width / 2, y: origin.y + size.height / 2)
        let rotatedCenter = center.applying(CGAffineTransform(rotationAngle: rotationAngle))
        return CGRect(x: rotatedCenter.x - size.width / 2, y: rotatedCenter.y - size.height / 2, width: size.width, height: size.height)
    }
    
    func clearPoints() {
        for layer in drawnLayers {
            layer.removeFromSuperlayer()
        }
        drawnLayers.removeAll()
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
