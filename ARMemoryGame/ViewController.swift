//
//  ViewController.swift
//  ARMemoryGame
//
//  Created by Karsen Hansen on 11/13/20.
//

import UIKit
import RealityKit
import Combine // Import combine framework for models

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let anchor = AnchorEntity(plane: .horizontal, minimumBounds: [0.2,0.2])
        arView.scene.addAnchor(anchor)
        
        var cards: [Entity] = []
        
        for _ in 1...4 {
            let box = MeshResource.generateBox(width: 0.04, height: 0.002, depth: 0.04)
            let metalMaterial = SimpleMaterial(color: .gray, isMetallic: true)
            let model = ModelEntity(mesh: box, materials: [metalMaterial])
            
            model.generateCollisionShapes(recursive: true)
            
            cards.append(model)
        }
        
        for (index, card) in cards.enumerated() {
            let x = Float(index % 2)
            let z = Float(index / 2)
            
            card.position = [x * 0.1, 0, z * 0.1]
            anchor.addChild(card)
        }
        
        var cancellable: AnyCancellable? = nil
        
        // MARK: - FIX THIS TO TAKE IN MORE MODELS & SET THEIR INDIVIDUAL SIZES
        // Load request for our models
        cancellable = ModelEntity.loadModelAsync(named: "tv_retro")
            .append(ModelEntity.loadModelAsync(named: "cup_saucer_set"))
            .collect()
            .sink(receiveCompletion: {error in
                print("Status: \(error)")
                cancellable?.cancel()
            }, receiveValue: { entities in
                var objects: [ModelEntity] = []
                entities[0].setScale(SIMD3<Float>(0.0009, 0.0009, 0.0009), relativeTo: anchor)
                entities[1].setScale(SIMD3<Float>(0.002, 0.002, 0.002), relativeTo: anchor)
//                entities[2].setScale(SIMD3<Float>(0.002, 0.002, 0.002), relativeTo: anchor)


                for entity in entities {
                    // entity.setScale(SIMD3<Float>(0.0002, 0.0002, 0.0002), relativeTo: anchor)
                    // Generate collision for pressing/interacting
                    entity.generateCollisionShapes(recursive: true)
                    for _ in 1...2 {
                        objects.append(entity.clone(recursive: true))
                    }
                }
                // Shuffle objects so pairs aren't adjacent
                objects.shuffle()
                
                // Place elements on our cards
                for (index, object) in objects.enumerated() {
                    cards[index].addChild(object)
                }
            })
    }
    
    @IBAction func onTap(_ sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: arView)
        if let card = arView.entity(at: tapLocation) {
            if card.transform.rotation.angle == .pi {
                var flipDownTransform = card.transform
                flipDownTransform.rotation = simd_quatf(angle: 0, axis: [1, 0, 0])
                card.move(to: flipDownTransform, relativeTo: card.parent, duration: 0.25, timingFunction: .easeInOut)
            } else {
                // Do not have rotation for card yet
                var flipUpTransform = card.transform
                flipUpTransform.rotation = simd_quatf(angle: .pi, axis: [1,0 ,0])
                card.move(to: flipUpTransform, relativeTo: card.parent, duration: 0.25, timingFunction: .easeInOut)
            }
        }
    }
    
}
