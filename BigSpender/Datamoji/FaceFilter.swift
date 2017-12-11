//
//  FaceFilter.swift
//  Datamoji
//
//  Created by Nate Parrott on 12/10/17.
//  Copyright © 2017 Nate Parrott. All rights reserved.
//

import Foundation
import ARKit
import SceneKit
import CoreImage

class FaceFilter {
    init(anchor: ARFaceAnchor, anchorNode: SCNNode, sceneNode: SCNNode, sceneView: ARSCNView) {
        self.anchor = anchor
        self.anchorNode = anchorNode
        self.sceneNode = sceneNode
        self.sceneView = sceneView
    }
    let anchor: ARFaceAnchor
    let anchorNode: SCNNode
    let sceneNode: SCNNode
    weak var sceneView: ARSCNView!
    
    func setup() {
        // add content to the sceneNode and anchorNode
    }
    
    func update(anchor: ARFaceAnchor) {
        
    }
}

class GlassesFilter : FaceFilter {
    var geometry: ARSCNFaceGeometry!
    override func setup() {
        super.setup()
        geometry = ARSCNFaceGeometry(device: sceneView.device!, fillMesh: true)
        let node = SCNNode(geometry: geometry)
        geometry.firstMaterial!.colorBufferWriteMask = []
        node.renderingOrder = -1
        anchorNode.addChildNode(node)
        
        let glasses = SCNScene(named: "glasses.scn", inDirectory: "art.scnassets", options:nil)!.rootNode.childNode(withName: "glasses", recursively: true)!
        glasses.centerAndNormalize(scale: 0.155)
        let glassesContainer = SCNNode()
        glassesContainer.addChildNode(glasses)
        glassesContainer.position = SCNVector3(0, 0.02, 0.014)
        
        anchorNode.addChildNode(glassesContainer)
    }
}

class TestFilter : FaceFilter {
    var geometry: ARSCNFaceGeometry!
    override func setup() {
        super.setup()
        geometry = ARSCNFaceGeometry(device: sceneView.device!)
        let node = SCNNode(geometry: geometry)
        geometry.firstMaterial!.lightingModel = .physicallyBased
        anchorNode.addChildNode(node)
    }
    
    override func update(anchor: ARFaceAnchor) {
        geometry.update(from: anchor.geometry)
    }
}

class BubbleFilter : FaceFilter {
    let deflectedBitMask: Int = 1
    let attractedBitMask: Int = 2
    
    var bubble: SCNNode!
    
    override func setup() {
        super.setup()
        
        // setup gravity:
        
        sceneView.scene.physicsWorld.gravity = SCNVector3()
        
        let gravity = SCNPhysicsField.linearGravity()
        gravity.direction = SCNVector3(0, -9.8 * 0.7, 0)
        gravity.categoryBitMask = deflectedBitMask
        let gravNode = SCNNode()
        gravNode.physicsField = gravity
        sceneNode.addChildNode(gravNode)
        
        // setup bubble geometry:
        
        let bubbleGeo = SCNSphere(radius: 0.132)
        bubbleGeo.firstMaterial!.configureAsBubble(color: UIColor(red: 0.5, green: 0.7, blue: 1, alpha: 1))
        bubble = SCNNode(geometry: bubbleGeo)
        bubble.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: bubbleGeo, options: nil))
        bubble.position = SCNVector3(0, 0.032, 0)
        anchorNode.addChildNode(bubble)
        
        // setup attractive forces:
        
        bubble.physicsField = SCNPhysicsField.spring()
        bubble.physicsField!.categoryBitMask = attractedBitMask
        bubble.physicsField!.strength = 70
        
        let dragNode = SCNNode()
        bubble.addChildNode(dragNode)
        let drag = SCNPhysicsField.drag()
        drag.strength = 5
        // drag.categoryBitMask = attractedBitMask
        dragNode.physicsField = drag
        
//        let vortexNode = SCNNode()
//        bubble.addChildNode(vortexNode)
//        let vortex = SCNPhysicsField.vortex()
//        vortexNode.physicsField = vortex
//        vortex.categoryBitMask = attractedBitMask
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.loop()
        }
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            var bubbleCenter = bubble.convertPosition(SCNVector3(0, 0, 0), to: self.anchorNode)
//            bubbleCenter.y += 0.5
//
//            let b = self.createNewsBubble(text: "CNN", color: UIColor.red, deflected: false)
//            b.position = bubbleCenter
//            self.anchorNode.addChildNode(b)
//
//            bubbleCenter.x += 0.02
//            let b2 = self.createNewsBubble(text: "FOX", color: UIColor.blue, deflected: true)
//            b2.position = bubbleCenter
//            self.anchorNode.addChildNode(b2)
//
//            print("CREATED!")
//        }
    }
    
    struct NewsOrg {
        let name: String
        let color: UIColor
        let deflect: Bool
    }
    let newsOrgs: [NewsOrg] = [
        // NewsOrg(name: "CNN", color: UIColor.red, deflect: false),
        NewsOrg(name: "FOX", color: UIColor.blue, deflect: true),
        NewsOrg(name: "Breitbart", color: UIColor.orange, deflect: true),
        // NewsOrg(name: "NYTimes", color: UIColor.gray, deflect: false),
        // NewsOrg(name: "MSNBC", color: UIColor.purple, deflect: false),
        // NewsOrg(name: "WaPo", color: UIColor.white, deflect: false),
        NewsOrg(name: "Daily\nCaller", color: UIColor.red, deflect: true),
        NewsOrg(name: "NY Post", color: UIColor.blue, deflect: true)
    ]
    
    func loop() {
        let org = newsOrgs[Int(Float.random * Float(newsOrgs.count))]
        
        var bubbleCenter = bubble.presentation.convertPosition(SCNVector3((Float.random * 2 - 1) * 0.05, 0, 0.04), to: sceneNode)
        bubbleCenter.y += 1
        // bubbleCenter.x += (Float.random * 2 - 1) * 0.1
        // bubbleCenter.z += (Float.random * 2 - 1) * 0.1
        bubbleCenter = self.sceneNode.convertPosition(bubbleCenter, to: anchorNode.presentation)

        let b = self.createNewsBubble(text: org.name, color: org.color, deflected: org.deflect)
        b.position = bubbleCenter
        self.anchorNode.addChildNode(b)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            b.removeFromParentNode()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.loop()
        }
    }
    
    func createNewsBubble(text: String, color: UIColor, deflected: Bool) -> SCNNode {
        let bubbleGeo = SCNSphere(radius: 0.04)
        bubbleGeo.firstMaterial!.configureAsBubble(color: color)
        let bubble = SCNNode(geometry: bubbleGeo)
        bubble.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: bubbleGeo, options: nil))
        bubble.physicsBody!.categoryBitMask = deflected ? deflectedBitMask : attractedBitMask
        bubble.physicsBody!.collisionBitMask = deflected ? deflectedBitMask : attractedBitMask
        
        let textGeo = SCNText(string: text, extrusionDepth: 1)
        textGeo.firstMaterial!.lightingModel = .physicallyBased
        textGeo.firstMaterial!.diffuse.contents = color
        textGeo.firstMaterial!.emission.contents = UIColor(white: 1, alpha: 1)
        textGeo.firstMaterial!.metalness.contents = 0.7
        textGeo.firstMaterial!.roughness.contents = 0.2
        let text = SCNNode(geometry: textGeo)
        text.centerAndNormalize(scale: 0.06)
        bubble.addChildNode(text)
        
        return bubble
    }
    
    override func update(anchor: ARFaceAnchor) {
        super.update(anchor: anchor)
    }
}

extension SCNMaterial {
    func configureAsBubble(color: UIColor) {
        lightingModel = .physicallyBased
        metalness.contents = 0.2
        roughness.contents = 0
        diffuse.contents = color
        transparency = 0.33
        isDoubleSided = false
    }
}

extension Float {
    /// Returns a random floating point number between 0.0 and 1.0, inclusive.
    static var random: Float {
        return Float(arc4random()) / 0xFFFFFFFF
    }
}

extension SCNNode {
    func centerAndNormalize(scale: Float) {
        let bbox = boundingBox
        let cx = (bbox.max.x + bbox.min.x)/2
        let cy = (bbox.max.y + bbox.min.y)/2
        let cz = (bbox.max.z + bbox.min.z)/2
        let realScale = 1.0 / max(bbox.max.x - bbox.min.x, bbox.max.y - bbox.min.y, bbox.max.z - bbox.min.z) * scale
        self.scale = SCNVector3(realScale, realScale, realScale)
        position = SCNVector3(-cx * realScale, -cy * realScale, -cz * realScale)
    }
}

// CIFilter(name: "CIPixellate", withInputParameters: [kCIInputScaleKey: 30])!

class EmotionFilter : FaceFilter {
    
}
