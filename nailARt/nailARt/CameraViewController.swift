//
//  CameraViewController.swift
//  nailARt
//
//  Created by Elizabeth Commisso on 2/25/24.
//

import UIKit
import AVFoundation
import Vision

class CameraViewController: UIViewController {
    
    private var cameraView: CameraView {
        guard let cameraView = view as? CameraView else {
            fatalError("The view is not of type CameraView.")
        }
        return cameraView
    }
    
    private let videoDataOutputQueue = DispatchQueue(label: "CameraFeedDataOutput", qos: .userInteractive)
    private var cameraFeedSession: AVCaptureSession?
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    
    //    private var evidenceBuffer = [HandGestureProcessor.PointsPair]()
    
    
    //    private var gestureProcessor = HandGestureProcessor()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        handPoseRequest.maximumHandCount = 2
        // Add state change handler to hand gesture processor.
        //        gestureProcessor.didChangeStateClosure = { [weak self] state in
        //            self?.handleGestureStateChange(state: state)
        //        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        do {
            if cameraFeedSession == nil {
                cameraView.previewLayer.videoGravity = .resizeAspectFill
                try setupAVSession()
                cameraView.previewLayer.session = cameraFeedSession
            }
            cameraFeedSession?.startRunning()
        } catch {
            AppError.display(error, inViewController: self)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        cameraFeedSession?.stopRunning()
        super.viewWillDisappear(animated)
    }
    
    func setupAVSession() throws {
        // Select a back facing camera, make an input. maybe change to have it be able to flip cam later?
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw AppError.captureSessionSetup(reason: "Could not find a back facing camera.")
        }
        
        guard let deviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            throw AppError.captureSessionSetup(reason: "Could not create video device input.")
        }
        
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSession.Preset.high
        
        // Add a video input.
        guard session.canAddInput(deviceInput) else {
            throw AppError.captureSessionSetup(reason: "Could not add video device input to the session")
        }
        session.addInput(deviceInput)
        
        let dataOutput = AVCaptureVideoDataOutput()
        if session.canAddOutput(dataOutput) {
            session.addOutput(dataOutput)
            // Add a video data output.
            dataOutput.alwaysDiscardsLateVideoFrames = true
            dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            dataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            throw AppError.captureSessionSetup(reason: "Could not add video data output to the session")
        }
        session.commitConfiguration()
        cameraFeedSession = session
    }
    
    func processPoints(indexTip: CGPoint?) {
        // Check that we have the point
        guard let indexPoint = indexTip else {
//            // If there were no observations for more than 2 seconds reset gesture processor.
//            if Date().timeIntervalSince(lastObservationTimestamp) > 2 {
//                gestureProcessor.reset()
//            }
            // cameraView.showPoints([], color: .clear)
            return
        }
        
        // Draw a black dot on the index finger tip
        cameraView.drawDot(at: indexPoint, color: .black)

        // Print the coordinates
        print("Index Finger Tip Coordinates: \(indexPoint)")
        
        // Convert point from AVFoundation coordinates to UIKit coordinates.
        let previewLayer = cameraView.previewLayer
        let indexPointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: indexPoint)
        
        // Process new points
//        gestureProcessor.processPointsPair((thumbPointConverted, indexPointConverted))
        
    }
    
}


extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        var indexTip: CGPoint?
        
        defer {
            DispatchQueue.main.sync {
                self.processPoints(indexTip: indexTip)
            }
        }

        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        do {
            // Perform VNDetectHumanHandPoseRequest
            try handler.perform([handPoseRequest])
            // Continue only when a hand was detected in the frame.
            // Since we set the maximumHandCount property of the request to 1, there will be at most one observation.
            guard let observation = handPoseRequest.results?.first else {
                return
            }
            // Get points for index finger.
            let indexFingerPoints = try observation.recognizedPoints(.indexFinger)
            // Look for tip points.
            guard let indexTipPoint = indexFingerPoints[.indexTip] else {
                return
            }
            // Ignore low confidence points.
            guard indexTipPoint.confidence > 0.3 else {
                return
            }
            // Convert points from Vision coordinates to AVFoundation coordinates.
            indexTip = CGPoint(x: indexTipPoint.location.x, y: 1 - indexTipPoint.location.y)
        } catch {
            cameraFeedSession?.stopRunning()
            let error = AppError.visionError(error: error)
            DispatchQueue.main.async {
                error.displayInViewController(self)
            }
        }
    }
}



