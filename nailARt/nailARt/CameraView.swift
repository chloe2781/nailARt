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
    

    
    func showPoints(_ points: [CGPoint], color: UIColor) {
        // Clear previous points
        clearPoints()

        // draw rectangles at the specified points. later: adjust sizing versus hand distance
        for point in points {
            let rectangleLayer = CALayer()
            let rectangleSize = CGSize(width: nailWidth, height: nailHeight)
            rectangleLayer.bounds = CGRect(origin: .zero, size: rectangleSize)
            rectangleLayer.position = point
            rectangleLayer.cornerRadius = 10
            rectangleLayer.backgroundColor = UIColor.black.cgColor
            layer.addSublayer(rectangleLayer)
            drawnLayers.append(rectangleLayer)
        }
    }

    
    func clearPoints() {
        for layer in drawnLayers {
            layer.removeFromSuperlayer()
        }
        drawnLayers.removeAll()
    }
}
