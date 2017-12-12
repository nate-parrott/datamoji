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

class EmotionFilter2 : FaceFilter {
    var geometry: ARSCNFaceGeometry!
    var faceNode: SCNNode!
    var happinessText: SCNNode!
    var demographicText: SCNNode!
    var lastTextUpdate = Date.timeIntervalSinceReferenceDate + 5
    
    override func setup() {
        super.setup()
        geometry = ARSCNFaceGeometry(device: sceneView.device!)
        faceNode = SCNNode(geometry: geometry)
        geometry.firstMaterial!.fillMode = .lines
        geometry.firstMaterial!.diffuse.contents = UIColor(red: 1, green: 0.8, blue: 1, alpha: 0.9)
        anchorNode.addChildNode(faceNode)
        
        let headContent = SCNScene(named: "ship.scn", inDirectory: "art.scnassets", options: nil)!.rootNode.childNode(withName: "head", recursively: true)!
        happinessText = headContent.childNode(withName: "happiness", recursively: true)! as! SCNNode
        demographicText = headContent.childNode(withName: "demographic", recursively: true)! as! SCNNode
        anchorNode.addChildNode(headContent)
    }
    
    override func update(anchor: ARFaceAnchor) {
        geometry.update(from: anchor.geometry)
        let clamped: (CGFloat) -> CGFloat = { min(1, max(0, $0)) }
        let smile = anchor.getBlendShape(.mouthSmileLeft) + anchor.getBlendShape(.mouthSmileRight)
        let frown = anchor.getBlendShape(.mouthFrownLeft) + anchor.getBlendShape(.mouthFrownRight)
        let happiness = smile - frown
        // frown: <0; happy: 1
        let happinessScaled = Int((happiness - 0.5) * 2 * 100)
        if (Date.timeIntervalSinceReferenceDate - lastTextUpdate) > 0.1 {
            lastTextUpdate = Date.timeIntervalSinceReferenceDate
            (happinessText.geometry! as! SCNText).string = "HAPPINESS:\n\(happinessScaled)"
            // print("Hp: \(happiness)")
            let possibleDemographicStrings: [String] = ["MALE\n27", "TRACKING\nERROR", "MALE\n22", "MALE\n24", "MALE\n26", "MALE\n23"]
            (demographicText.geometry as! SCNText).string = possibleDemographicStrings[Int(arc4random() % UInt32(possibleDemographicStrings.count))]
        }
    }
    
    override func configureCamera(_ camera: SCNCamera) {
        super.configureCamera(camera)
        DispatchQueue.main.async {
            camera.colorGrading.contents = UIImage(named: "cg3.png")!
        }
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

