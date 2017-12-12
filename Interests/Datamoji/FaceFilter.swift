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
    
    func configureCamera(_ camera: SCNCamera) {
        
    }
}

class InterestsFilter : FaceFilter {
    var faceNode: SCNNode!
    var head: SCNNode!
    var morpher: SCNMorpher!
    
    override func setup() {
        super.setup()
        head = SCNScene(named: "brandman3fixed.scn", inDirectory: "art.scnassets", options: nil)!.rootNode.childNode(withName: "brandman", recursively: true)!
        head.rotation = SCNVector4(1, 0, 0, 0)
        // head.scale = SCNVector3(1/3000, 1/3000, 1/3000)
        head.centerAndNormalize(scale: 0.29)
        head.position.y += 0.04
        head.position.z -= 0.04
        morpher = head.morpher!
        anchorNode.addChildNode(head)
        morpher.unifiesNormals = true
    }
    
    override func update(anchor: ARFaceAnchor) {
        super.update(anchor: anchor)
        morpher.setWeight(anchor.getBlendShape(.jawOpen) * 2, forTargetNamed: "jawOpen")
        morpher.setWeight(anchor.getBlendShape(.mouthClose), forTargetNamed: "mouthClose")
        morpher.setWeight(anchor.getBlendShape(.eyeBlinkRight), forTargetNamed: "eyeBlinkRight")
        morpher.setWeight(anchor.getBlendShape(.eyeBlinkLeft), forTargetNamed: "eyeBlinkLeft")
        morpher.setWeight(anchor.getBlendShape(.jawForward), forTargetNamed: "jawForward")
        morpher.setWeight(anchor.getBlendShape(.mouthSmileLeft) * 2 - 0.7, forTargetNamed: "mouthSmileLeft")
        morpher.setWeight(anchor.getBlendShape(.mouthSmileRight) * 2 - 0.7, forTargetNamed: "mouthSmileRight")
        morpher.setWeight(anchor.getBlendShape(.mouthPucker) * 2, forTargetNamed: "mouthPucker")
    }
}


extension ARFaceAnchor {
    func getBlendShape(_ loc: ARFaceAnchor.BlendShapeLocation) -> CGFloat {
        return CGFloat(blendShapes[loc]?.floatValue ?? 0)
    }
}

class EmotionFilter : FaceFilter {
    var geometry: ARSCNFaceGeometry!
    var faceNode: SCNNode!
    override func setup() {
        super.setup()
        geometry = ARSCNFaceGeometry(device: sceneView.device!)
        faceNode = SCNNode(geometry: geometry)
        geometry.firstMaterial!.lightingModel = .physicallyBased
        geometry.firstMaterial!.diffuse.contents = UIColor(red: 0.896, green: 0.649, blue: 0.615, alpha: 1)
        faceNode.opacity = 0
        anchorNode.addChildNode(faceNode)
    }
    
    func projectBoundingBoxPoint(pt: SCNVector3, node: SCNNode) -> SCNVector3 {
        return sceneView.projectPoint(sceneView.scene.rootNode.convertPosition(pt, from: node))
    }
    
    override func update(anchor: ARFaceAnchor) {
        geometry.update(from: anchor.geometry)
        let coord1 = projectBoundingBoxPoint(pt: faceNode.boundingBox.min, node: faceNode)
        let coord2 = projectBoundingBoxPoint(pt: faceNode.boundingBox.max, node: faceNode)
        let minX = CGFloat(min(coord1.x, coord2.x))
        let minY = CGFloat(min(coord1.y, coord2.y))
        let maxX = CGFloat(max(coord1.x, coord2.x))
        let maxY = CGFloat(max(coord1.y, coord2.y))
        DispatchQueue.main.async {
            self.blurView.frame = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }
    }
    
    var blurView: UIView!
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

