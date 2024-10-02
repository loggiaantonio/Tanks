//
//  SpriteView.swift
//  Tanks Arma Get On
//
//  Created by Antonio Loggia on 24.09.24.
//

import SwiftUI
import SpriteKit

struct SpriteView: UIViewRepresentable {
    let mapName: String // Die ausgewählte Map

    func makeUIView(context: Context) -> SKView {
        let skView = SKView()

        // Lade die Szene für die Map-Anzeige
        let scene: SKScene
        if mapName == "Map1" {
            scene = GameScene(fileNamed: "GameScene")! // Lade die "GameScene" aus der GameScene.sks-Datei
        } else {
            // Leere Szene, falls keine Map gefunden wurde
            scene = SKScene(size: CGSize(width: 1024, height: 768))
            scene.backgroundColor = .black
        }

        scene.scaleMode = .aspectFill
        skView.presentScene(scene)

        skView.ignoresSiblingOrder = true
        skView.showsFPS = false
        skView.showsNodeCount = false

        return skView
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        // Falls sich die Map-Auswahl ändert, könnte hier die neue Szene geladen werden
    }
}
