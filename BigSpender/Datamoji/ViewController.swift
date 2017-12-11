//
//  ViewController.swift
//  Datamoji
//
//  Created by Nate Parrott on 12/10/17.
//  Copyright © 2017 Nate Parrott. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var console: ConsoleTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        // sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        sceneView.automaticallyUpdatesLighting = true
        scene.lightingEnvironment.contents = UIImage(named: "env.jpg")!
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.scene.physicsWorld.speed = 1
        // sceneView.debugOptions.formUnion(.showPhysicsShapes)
        // sceneView.debugOptions.formUnion(.showPhysicsFields)
        
//        console.addLine("Initializing...")
//        console.addLine("Computing political\npreferences...")
//        console.addLine("Location:\nProvidence, RI")
//        console.addLine("News affinities:")
//        console.addLine("MSNBC + 20%")
//        console.addLine("Fox -11%")
//        console.addLine("CNN +18%")
//        console.addLine("Breitbart -11%")
//        console.addLine("NYTimes: +22%")
//        console.addLine("WSJ: +2%")
//        console.addLine("Collecting relevant sources...")
//        console.addLine("\n\n\n")
//        console.addLine("Predicting political preferences...")
//        console.addLine("Collecting relevant sources...")
//        console.addLine("Curating content...")
//        console.addLinesToClearScreen()
        
//        console.emptyCallback = {
//            self.console.emptyCallback = nil
//            self.faceFilter!.setup()
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        
        // Run the view's session
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let faceAnchor = anchor as? ARFaceAnchor {
            faceFilter = GlassesFilter(anchor: faceAnchor, anchorNode: node, sceneNode: sceneView.scene.rootNode, sceneView: sceneView)
            faceFilter!.setup()
        }
    }
    
    var faceFilter: FaceFilter?
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let faceAnchor = anchor as? ARFaceAnchor {
            faceFilter?.update(anchor: faceAnchor)
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
