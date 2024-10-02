//
//  SpriteView.swift
//  Tanks Arma Get On
//
//  Created by Antonio Loggia on 26.09.24.
//


import SwiftUI  // Importiere SwiftUI für die SwiftUI-Komponenten
import SpriteKit // Importiere SpriteKit für die GameScene und SKView

struct SpriteView: UIViewRepresentable {
    let mapName: String
    let selectedPanzers: [String]

    func makeUIView(context: Context) -> SKView {
        let skView = SKView()

        // Lade die Szene aus der .sks-Datei
        if let scene = GameScene(fileNamed: "GameScene") {
            scene.selectedPanzers = selectedPanzers
            scene.scaleMode = .aspectFill
            skView.presentScene(scene)
        }
        
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
        
        return skView
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        // Reagiere auf Änderungen in der View, wenn nötig
    }
}
