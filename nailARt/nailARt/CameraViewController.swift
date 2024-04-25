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
            // get the middle tip and middle PIP points
            guard let middleTip = self?.gestureProcessor.lastProcessedPointsSet.middleTip,
                  let middlePip = self?.gestureProcessor.lastProcessedPointsSet.middlePip else { return }
//            // get the fixed point on the screen (middle point of the device)
//            let fixedPoint = self?.findScreenMiddlePoint()
            self?.rotationAngle = self?.calculateRotationAngle(middleTip: middleTip, middlePip: middlePip) ?? 0.0

        }
    }
    private var previousRotationAngle: CGFloat = 0.0
    
    

    private func calculateRotationAngle(middleTip: CGPoint, middlePip: CGPoint) -> CGFloat {
        let deltaX = middlePip.x - middleTip.x
        let deltaY = middlePip.y - middleTip.y
        
        // calculate the angle between the vectors formed by middleTip and middlePip
        let measured_angle = atan2(deltaY, deltaX)
        
        var angle = measured_angle - (CGFloat.pi / 2)
        
        // ensure that the angle is within the range of 0 to 2pi radians
        angle = angle.truncatingRemainder(dividingBy: 2 * CGFloat.pi)
        if angle < 0 {
            angle += 2 * CGFloat.pi
        }
        
//        print("\(angle)")
        
        // manual tuning of angle in radians (measurements correspond to unit circle we measured)
        
        let tolerance =  CGFloat.pi / 12 //15 deg
        let cardinal_tolerance = CGFloat.pi / 9 //20 deg
        
        //up
        if abs(angle - 0) <= cardinal_tolerance {
            return 0
        }
        
        //15
        if abs(angle - CGFloat.pi/12) <= tolerance {
            return CGFloat.pi/12
        }

        //30
        if abs(angle - CGFloat.pi/6) <= tolerance {
            return CGFloat.pi/6
        }

        //45 right up diagonal
        if abs(angle - CGFloat.pi/4) <= tolerance {
            return CGFloat.pi/4
        }

        //60
        if abs(angle - CGFloat.pi/3) <= tolerance {
            return CGFloat.pi/3
        }
        
        //75
        if abs(angle - 5*CGFloat.pi/12) <= tolerance {
            return 5*CGFloat.pi/12
        }

        //90 right horizontal
        if abs(angle - CGFloat.pi/2) <= cardinal_tolerance {
            return CGFloat.pi/2
        }
        
        //105
        if abs(angle - 7*CGFloat.pi/12) <= tolerance {
            return 7*CGFloat.pi/12
        }

        //120
        if abs(angle - 2*CGFloat.pi/3) <= tolerance {
            return 2*CGFloat.pi/3
        }

        //135 right down diagonal
        if abs(angle - 3*CGFloat.pi/4) <= tolerance {
            return 3*CGFloat.pi/4
        }

        //150
        if abs(angle - 5*CGFloat.pi/6) <= tolerance {
            return 5*CGFloat.pi/6
        }

        //180 down
        if abs(angle - CGFloat.pi) <= cardinal_tolerance {
            return CGFloat.pi
        }

        //210
        if abs(angle - 7*CGFloat.pi/6) <= tolerance {
            return 7*CGFloat.pi/6
        }

        //225 left down diagonal
        if abs(angle - 5*CGFloat.pi/4) <= tolerance {
            return 5*CGFloat.pi/4
        }

        //240
        if abs(angle - 4*CGFloat.pi/3) <= tolerance {
            return 4*CGFloat.pi/3
        }
        
        //255
        if abs(angle - 17*CGFloat.pi/12) <= tolerance {
            return 17*CGFloat.pi/12
        }

        //270 left horizontal
        if abs(angle - 3*CGFloat.pi/2) <= cardinal_tolerance {
            return 3*CGFloat.pi/2
        }
        
        //285
        if abs(angle - 19*CGFloat.pi/12) <= tolerance {
            return 19*CGFloat.pi/12
        }

        //300
        if abs(angle - 5*CGFloat.pi/3) <= tolerance {
            return 5*CGFloat.pi/3
        }

        //315 left up diagonal
        if abs(angle - 7*CGFloat.pi/4) <= tolerance {
            return 7*CGFloat.pi/4
        }
        
        //330
        if abs(angle - 11*CGFloat.pi/6) <= tolerance {
            return 11*CGFloat.pi/6
        }
        
        //345
        if abs(angle - 23*CGFloat.pi/12) <= tolerance {
            return 23*CGFloat.pi/12
        }
  
        
        return 0
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

    func processPoints(thumbTip: CGPoint?, indexTip: CGPoint?, middleTip: CGPoint?, ringTip: CGPoint?, littleTip: CGPoint?, middlePip: CGPoint?) {
        // Check that we have both points.
        guard let thumbPoint = thumbTip, let indexPoint = indexTip, let middlePoint = middleTip, let ringPoint = ringTip, let littlePoint = littleTip, let middlePipPoint = middlePip else {
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
        let middlePipPointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: middlePipPoint)
//        print("Index Finger Tip Coordinates: \(indexPointConverted)")
        
        // Process new points
        // changed from PointsPair to PointsSet to "process" all points. Right now, doesn't do anything
        //middleDipPointConverted
        gestureProcessor.processPointsSet((thumbPointConverted, indexPointConverted, middlePointConverted, ringPointConverted, littlePointConverted, middlePipPointConverted))
    }
    
    private func handleGestureStateChange(state: HandGestureProcessor.State) {
        let pointsSet = gestureProcessor.lastProcessedPointsSet
        var tipsColor: UIColor
        
        tipsColor = .black
        //DISPLAYS THE SHAPE
//        cameraView.showPoints([pointsSet.thumbTip, pointsSet.indexTip, pointsSet.middleTip, pointsSet.ringTip, pointsSet.littleTip], color: tipsColor,  rotationAngle: rotationAngle)
        cameraView.showPoints([pointsSet.thumbTip, pointsSet.indexTip, pointsSet.middleTip, pointsSet.ringTip, pointsSet.littleTip], color: tipsColor,  rotationAngle: rotationAngle, middleTipPoint: pointsSet.middleTip, middlePipPoint: pointsSet.middlePip)
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
        var middlePip: CGPoint?
        
        defer {
            DispatchQueue.main.sync {
                self.processPoints(thumbTip: thumbTip, indexTip: indexTip, middleTip: middleTip, ringTip: ringTip, littleTip: littleTip, middlePip: middlePip)
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
            guard let thumbTipPoint = thumbPoints[.thumbTip], let indexTipPoint = indexFingerPoints[.indexTip], let middleTipPoint = middleFingerPoints[.middleTip], let ringTipPoint = ringFingerPoints[.ringTip], let littleTipPoint = littleFingerPoints[.littleTip], let middlePipPoint = middleFingerPoints[.middlePIP] else {
                return
            }
            // try angle of this line? then move according to this angle?
            
            // Ignore low confidence points.
            guard thumbTipPoint.confidence > 0.3 && indexTipPoint.confidence > 0.3 && middleTipPoint.confidence > 0.3 && ringTipPoint.confidence > 0.3 && littleTipPoint.confidence > 0.3 && middlePipPoint.confidence > 0.3 else {
                return
            }
            // Convert points from Vision coordinates to AVFoundation coordinates.
            thumbTip = CGPoint(x: thumbTipPoint.location.x, y: 1 - thumbTipPoint.location.y)
            indexTip = CGPoint(x: indexTipPoint.location.x, y: 1 - indexTipPoint.location.y)
            middleTip = CGPoint(x: middleTipPoint.location.x, y: 1 - middleTipPoint.location.y)
            ringTip = CGPoint(x: ringTipPoint.location.x, y: 1 - ringTipPoint.location.y)
            littleTip = CGPoint(x: littleTipPoint.location.x, y: 1 - littleTipPoint.location.y)
            middlePip = CGPoint(x: middlePipPoint.location.x, y: 1 - middlePipPoint.location.y)
        } catch {
            cameraFeedSession?.stopRunning()
            let error = AppError.visionError(error: error)
            DispatchQueue.main.async {
                error.displayInViewController(self)
            }
        }
    }
}

