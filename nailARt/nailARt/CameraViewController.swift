/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's main view controller object.
*/

import UIKit
import AVFoundation
import Vision
import CoreMotion

class CameraViewController: UIViewController {

//    private var cameraView: CameraView { view as! CameraView }
    
    @IBOutlet var cameraView: CameraView!
    
    @IBOutlet var widthSlider: UISlider!
    
    @IBOutlet var heightSlider: UISlider!
    
    private let videoDataOutputQueue = DispatchQueue(label: "CameraFeedDataOutput", qos: .userInteractive)
    private var cameraFeedSession: AVCaptureSession?
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    
    private let drawOverlay = CAShapeLayer()
    private let drawPath = UIBezierPath()
    private var evidenceBuffer = [HandGestureProcessor.PointsSet]()
    private var lastDrawPoint: CGPoint?
    private var isFirstSegment = true
    private var lastObservationTimestamp = Date()
    
    private var gestureProcessor = HandGestureProcessor()
    
    private let motionManager = CMMotionManager()
    private var rotationAngle: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        drawOverlay.frame = view.layer.bounds
        view.layer.addSublayer(drawOverlay)
        
        // detect 2 hands
        handPoseRequest.maximumHandCount = 2
        // Add state change handler to hand gesture processor.
        gestureProcessor.didChangeStateClosure = { [weak self] state in
            self?.handleGestureStateChange(state: state)
        }
        
        setupMotionManager()
        
        // sliders
        widthSlider.value = Float(cameraView.nailWidth)
        heightSlider.value = Float(cameraView.nailHeight)
        
        // Set the minimum and maximum values for the sliders
        widthSlider.minimumValue = 100
        widthSlider.maximumValue = 400
        
        heightSlider.minimumValue = 20
        heightSlider.maximumValue = 400
        
        // action methods for slider value changes
        widthSlider.addTarget(self, action: #selector(widthSliderChanged(_:)), for: .valueChanged)
        heightSlider.addTarget(self, action: #selector(heightSliderChanged(_:)), for: .valueChanged)
        
    }
    
//    private func setupMotionManager() {
//        motionManager.deviceMotionUpdateInterval = 0.1
//        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
//            guard let motion = motion else { return }
//            let rotationAngle = self?.calculateRotationAngle(motion)
////            self?.cameraView.rotateRectangles(by: rotationAngle ?? 0.0)
//        }
//    }
//    
//    private func calculateRotationAngle(_ motion: CMDeviceMotion) -> Double {
//        // Calculate rotation angle based on motion data
//        let rotationRate = motion.rotationRate
//        let rotationAngle = atan2(rotationRate.x, rotationRate.y)
//        return rotationAngle
//    }

    func findScreenMiddlePoint() -> CGPoint {
        let screenBounds = UIScreen.main.bounds
        let screenMiddlePoint = CGPoint(x: screenBounds.midX, y: screenBounds.midY)
        return screenMiddlePoint
    }
    
    private func setupMotionManager() {
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
            guard let motion = motion else { return }
            // get the middle tip and middle MCP points -- maybe don't need?
            guard let middleTip = self?.gestureProcessor.lastProcessedPointsSet.middleTip,
                  let middleMcp = self?.gestureProcessor.lastProcessedPointsSet.middleMcp else { return }
            // get the fixed point on the screen (middle point of the device)
            let fixedPoint = self?.findScreenMiddlePoint()
            self?.rotationAngle = self?.calculateRotationAngle(middleTip: middleTip, middleMcp: middleMcp, fixedPoint: fixedPoint ?? .zero) ?? 0.0
        }
    }
    private var previousRotationAngle: CGFloat = 0.0
    
    private func calculateRotationAngle(middleTip: CGPoint, middleMcp: CGPoint, fixedPoint: CGPoint) -> CGFloat {
        let deltaX = middleMcp.x - middleTip.x
        let deltaY = middleMcp.y - middleTip.y
        
        // angle between the line and the horizontal axis
        var angle = atan2(deltaY, deltaX)
        
        // angle between the line and the line connecting the middleTip and the fixedPoint
//        let deltaXFixed = fixedPoint.x - middleTip.x
//        let deltaYFixed = fixedPoint.y - middleTip.y
//        let angleFixed = atan2(deltaYFixed, deltaXFixed)
        
        // angle between the line connecting middleTip and middleMcp and the horizontal axis
        var angleBetweenLines = angle // - angleFixed
        
        // angle = zero when the line between middleTip and middleMcp is perpendicular to the horizontal axis
        angleBetweenLines -= .pi / 2
        
        // convert to degrees
        let degrees = angleBetweenLines * CGFloat(180.0 / .pi)
        
        let adjustedAngle = -degrees
        
        print("adjusted\(adjustedAngle)")
        
        // threshold for when we change it
        let angleDifference = abs(adjustedAngle - previousRotationAngle)
        if angleDifference >= 2 {
            previousRotationAngle = adjustedAngle
            return adjustedAngle
        } else {
            return previousRotationAngle
        }
    }


    
    @objc func widthSliderChanged(_ sender: UISlider) {
            // update nail width based on slider value
            let newWidth = CGFloat(sender.value)
            cameraView.nailWidth = newWidth
            cameraView.setNeedsDisplay() // redraw the view
        }
        
    @objc func heightSliderChanged(_ sender: UISlider) {
        // update nail height based on slider value
        let newHeight = CGFloat(sender.value)
        cameraView.nailHeight = newHeight
        cameraView.setNeedsDisplay() // redraw the view
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
        motionManager.stopDeviceMotionUpdates()
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

    func processPoints(thumbTip: CGPoint?, indexTip: CGPoint?, middleTip: CGPoint?, ringTip: CGPoint?, littleTip: CGPoint?, middleMcp: CGPoint?) {
        // Check that we have both points.
        guard let thumbPoint = thumbTip, let indexPoint = indexTip, let middlePoint = middleTip, let ringPoint = ringTip, let littlePoint = littleTip, let middleMcpPoint = middleMcp else {
            // If there were no observations for more than 2 seconds reset gesture processor.
//            if Date().timeIntervalSince(lastObservationTimestamp) > 2 {
//                gestureProcessor.reset()
//            }
            // CLEARS the points when hand leaves the frame
//            cameraView.showPoints([], color: .clear, rotationAngle: 0)
            cameraView.hideNailImages()
            return
        }
        
        // Convert points from AVFoundation coordinates to UIKit coordinates.
        let previewLayer = cameraView.previewLayer
        let thumbPointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: thumbPoint)
        let indexPointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: indexPoint)
        let middlePointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: middlePoint)
        let ringPointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: ringPoint)
        let littlePointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: littlePoint)
        let middleMcpPointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: middleMcpPoint)
//        print("Index Finger Tip Coordinates: \(indexPointConverted)")
        
        // Process new points
        // changed from PointsPair to PointsSet to "process" all points. Right now, doesn't do anything
        //middleDipPointConverted
        gestureProcessor.processPointsSet((thumbPointConverted, indexPointConverted, middlePointConverted, ringPointConverted, littlePointConverted, middleMcpPointConverted))
    }
    
    private func handleGestureStateChange(state: HandGestureProcessor.State) {
        let pointsSet = gestureProcessor.lastProcessedPointsSet
        var tipsColor: UIColor
        
        tipsColor = .black
        //DISPLAYS THE SHAPE
        cameraView.showPoints([pointsSet.thumbTip, pointsSet.indexTip, pointsSet.middleTip, pointsSet.ringTip, pointsSet.littleTip], color: tipsColor,  rotationAngle: rotationAngle)
        //*************
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        var thumbTip: CGPoint?
        var indexTip: CGPoint?
        var middleTip: CGPoint?
        var ringTip: CGPoint?
        var littleTip: CGPoint?
        var middleMcp: CGPoint?
        
        defer {
            DispatchQueue.main.sync {
                self.processPoints(thumbTip: thumbTip, indexTip: indexTip, middleTip: middleTip, ringTip: ringTip, littleTip: littleTip, middleMcp: middleMcp)
            }
        }
        //, middleDip: middleDip

        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        do {
            // Perform VNDetectHumanHandPoseRequest
            try handler.perform([handPoseRequest])
            // Continue only when a hand was detected in the frame.
            // Since we set the maximumHandCount property of the request to 1, there will be at most one observation.
            guard let observation = handPoseRequest.results?.first else {
                return
            }
            // Get points for thumb and index finger.
            let thumbPoints = try observation.recognizedPoints(.thumb)
            let indexFingerPoints = try observation.recognizedPoints(.indexFinger)
            let middleFingerPoints = try observation.recognizedPoints(.middleFinger)
            let ringFingerPoints = try observation.recognizedPoints(.ringFinger)
            let littleFingerPoints = try observation.recognizedPoints(.littleFinger)
//            let wristPoint = try observation.recognizedPoint(.wrist) //DOES THIS WORK
            
            
            // Look for tip points.
            guard let thumbTipPoint = thumbPoints[.thumbTip], let indexTipPoint = indexFingerPoints[.indexTip], let middleTipPoint = middleFingerPoints[.middleTip], let ringTipPoint = ringFingerPoints[.ringTip], let littleTipPoint = littleFingerPoints[.littleTip], let middleMcpPoint = middleFingerPoints[.middleMCP] else {
                return
            }
            // try angle of this line? then move according to this angle?
            
            // Ignore low confidence points.
            guard thumbTipPoint.confidence > 0.3 && indexTipPoint.confidence > 0.3 && middleTipPoint.confidence > 0.3 && ringTipPoint.confidence > 0.3 && littleTipPoint.confidence > 0.3 && middleMcpPoint.confidence > 0.3 else {
                return
            }
            // Convert points from Vision coordinates to AVFoundation coordinates.
            thumbTip = CGPoint(x: thumbTipPoint.location.x, y: 1 - thumbTipPoint.location.y)
            indexTip = CGPoint(x: indexTipPoint.location.x, y: 1 - indexTipPoint.location.y)
            middleTip = CGPoint(x: middleTipPoint.location.x, y: 1 - middleTipPoint.location.y)
            ringTip = CGPoint(x: ringTipPoint.location.x, y: 1 - ringTipPoint.location.y)
            littleTip = CGPoint(x: littleTipPoint.location.x, y: 1 - littleTipPoint.location.y)
            middleMcp = CGPoint(x: middleMcpPoint.location.x, y: 1 - middleMcpPoint.location.y)
        } catch {
            cameraFeedSession?.stopRunning()
            let error = AppError.visionError(error: error)
            DispatchQueue.main.async {
                error.displayInViewController(self)
            }
        }
    }
}

