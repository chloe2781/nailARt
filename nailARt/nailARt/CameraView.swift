//
//  CameraView.swift
//  nailARt
//
//  Created by Elizabeth Commisso on 2/25/24.
//

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
    
    func drawDot(at point: CGPoint, color: UIColor) {
        let dotLayer = CALayer()
        dotLayer.bounds = CGRect(x: 0, y: 0, width: 10, height: 10)
        dotLayer.position = point
        dotLayer.cornerRadius = 5
        dotLayer.backgroundColor = color.cgColor
        overlayLayer.sublayers?.forEach { $0.removeFromSuperlayer() } // Remove previous dots
        overlayLayer.addSublayer(dotLayer)
    }
}

