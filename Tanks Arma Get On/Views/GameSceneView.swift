//
//  GameSceneView.swift
//  Tanks Arma Get On
//
//  Created by Antonio Loggia on 26.09.24.
//

import SwiftUI
import SpriteKit

// UIViewRepresentable zur Darstellung von SpriteKit-Szenen in SwiftUI
struct GameSceneView: UIViewRepresentable {
    
    func makeUIView(context: Context) -> SKView {
        let skView = SKView()
        
        // Initialisiere die Szene mit der Bildschirmgröße
        let scene = GameScene(size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        
        scene.scaleMode = .aspectFill // Fülle den gesamten Bereich aus
        skView.presentScene(scene) // Zeige die Szene an
        
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true // Zeige die FPS an, um die Leistung zu prüfen
        skView.showsNodeCount = true // Zeige die Anzahl der Knoten in der Szene an
        
        return skView
    }
    
    func updateUIView(_ uiView: SKView, context: Context) {
        // Handle Änderungen, wenn nötig (z. B. Szene aktualisieren)
    }
}

#Preview {
    GameSceneView()
        .edgesIgnoringSafeArea(.all) // Vorschau über den gesamten Bildschirm
}
