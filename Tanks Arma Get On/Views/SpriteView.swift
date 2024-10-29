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
    let selectedPanzerNames: [String] // Liste der Panzer-Namen

    func makeUIView(context: Context) -> SKView {
        let skView = SKView()

        // Lade die Szene aus der .sks-Datei
        if let scene = GameScene(fileNamed: "GameScene") {
            
            // Erstelle Panzer-Objekte aus den Namen
            var selectedPanzers: [Panzer] = []
            for panzerName in selectedPanzerNames {
                let panzer = Panzer(imageNamed: panzerName, isEnemy: false) // Erstelle ein Panzer-Objekt
                panzer.name = panzerName // Setze den Namen des Panzers
                selectedPanzers.append(panzer) // Füge den Panzer zur Liste hinzu
            }
            
            // Weise die Panzer-Objekte der Szene zu
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
