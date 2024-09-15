//
//  ContentView.swift
//  Tanks Arma Get On
//
//  Created by Antonio Loggia on 02.09.24.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    var body: some View {
        // SpriteView ist eine SwiftUI-Komponente, die eine SpriteKit-Szene einbettet
        SpriteView(scene: makeGameScene())
            .edgesIgnoringSafeArea(.all) // Stellt sicher, dass die Szene den gesamten Bildschirm einnimmt
    }
    
    // Funktion zur Erstellung der GameScene
    func makeGameScene() -> SKScene {
        let scene = GameScene(size: CGSize(width: 300, height: 600)) // Größe der Szene definieren
        scene.scaleMode = .resizeFill // Szene füllt den gesamten verfügbaren Bereich
        return scene
    }
}

#Preview {
    ContentView()
}
