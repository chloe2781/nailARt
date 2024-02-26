////
////  ViewController.swift
////  nailARt
////
////  Created by Elizabeth Commisso on 2/6/24.
////
//
//import UIKit
//import SceneKit
//import ARKit
//
//class ViewController: UIViewController, ARSCNViewDelegate {
//
//    @IBOutlet var sceneView: ARSCNView!
//    var leftHandNode: SCNNode?
//    var rightHandNode: SCNNode?
//    
//    var rectangleNode: SCNNode?
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        // Set the view's delegate
//        sceneView.delegate = self
//        
//        // Show statistics such as fps and timing information
//        sceneView.showsStatistics = true
//        
//        // Create a new scene
//        let scene = SCNScene()
//        
//        
//        // Create a rectangle
//        let rectangle = SCNPlane(width: 0.05, height: 0.1)
//        rectangle.materials.first?.diffuse.contents = UIColor.black
//        
//        // Create a node to hold the rectangle
//        rectangleNode = SCNNode(geometry: rectangle)
//        scene.rootNode.addChildNode(rectangleNode!)
//        
//        // Set the scene to the view
//        sceneView.scene = scene
//    }
//    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        
//        // Create a session configuration
//        let configuration = ARBodyTrackingConfiguration()
//
//        // Run the view's session
//        sceneView.session.run(configuration)
//    }
//    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        
//        // Pause the view's session
//        sceneView.session.pause()
//    }
//
//    // MARK: - ARSCNViewDelegate
//    
////    // Override to create and configure nodes for anchors added to the view's session. // removed return type for now -> SCNNode?
////    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, nodeFor anchor: ARAnchor)  {
////        
////        if anchor is ARBodyAnchor{
////            let geometory = SCNSphere(radius: 1)
////            geometory.firstMaterial?.diffuse.contents = UIColor.init(red: 175/255, green: 255/255, blue: 255/255, alpha: 200/255)
////            let sphere = SCNNode(geometry: geometory)
////
////            node.addChildNode(sphere)
////            
////        }
//////        let node = SCNNode()
//////     
//////        return sphere
////    }
//
//    //no hand tracking exists???
////    
////    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
////        if anchor is ARBodyAnchor{
////            let geometory = SCNSphere(radius: 1)
////            geometory.firstMaterial?.diffuse.contents = UIColor.init(red: 175/255, green: 255/255, blue: 255/255, alpha: 200/255)
////            let sphere = SCNNode(geometry: geometory)
////
////            node.addChildNode(sphere)
////        }
////    }
//    
////    //SOURCE: https://www.youtube.com/watch?v=f86K8h-8C9A
////    func renderer(_ renderer: SCNSceneRenderer, didUpdate anchors: [ARAnchor]) {
////        
////        for anchor in anchors {
////            if let bodyAnchor = anchor as? ARBodyAnchor {
////                print("updated body anchor")
////                
////                let skeleton = bodyAnchor.skeleton
////                
////                //model transform = every other joint is relative to the root joint
//////                let rootJointTransform = skeleton.modelTransform(for: .root)! // at the hip joint. ! = force unwrap
//////                
//////                let rootJointPosition = simd_make_float3(rootJointTransform.columns.3) // pos from root joint. transform includes pos and orientation
//////                
//////                print("root \(rootJointPosition)")
//////                
////                //if let to ensure root is not nil before unwrapping
////                if let rootJointTransform = skeleton.modelTransform(for: .root) {
////                    let rootJointPosition = simd_make_float3(rootJointTransform.columns.3) // Position from root joint. Transform includes position and orientation
////                    print("Root Joint Position: \(rootJointPosition)")
////                    
////                    sceneView.backgroundColor = UIColor.green
////                    
////                    // Now you can use rootJointPosition for further processing or updating UI elements.
////                } else {
////                    print("Root joint not found.")
////                }
////            }
////        }
////    }
////    
////    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
////        guard let bodyAnchor = anchor as? ARBodyAnchor else { return }
////
////        // Access hand joint information
////        if let leftHand = bodyAnchor.skeleton.modelTransform(for: .leftHand),
////           let rightHand = bodyAnchor.skeleton.modelTransform(for: .rightHand) {
////            
////            // Update positions of rectangles based on hand joints
//////            updateRectanglePosition(for: leftHand, on: leftHandNode!)
//////            updateRectanglePosition(for: rightHand, on: rightHandNode!)
////            
////            // Update positions of rectangles based on hand joints
////            updateRectanglePosition(for: leftHand, on: leftHandNode ?? SCNNode())
////            updateRectanglePosition(for: rightHand, on: rightHandNode ?? SCNNode())
////        }
////    }
//
//    func updateRectanglePosition(for handTransform: simd_float4x4, on node: SCNNode) {
//        // Set the node's position based on the hand joint
//        node.simdTransform = handTransform
//    }
////
//    func session(_ session: ARSession, didFailWithError error: Error) {
//        // Present an error message to the user
//        
//    }
//    
//    func sessionWasInterrupted(_ session: ARSession) {
//        // Inform the user that the session has been interrupted, for example, by presenting an overlay
//        
//    }
//    
//    func sessionInterruptionEnded(_ session: ARSession) {
//        // Reset tracking and/or remove existing anchors if consistent tracking is required
//        
//    }
//}
//
