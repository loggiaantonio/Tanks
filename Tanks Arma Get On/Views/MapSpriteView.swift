import SwiftUI
import SpriteKit

struct MapSpriteView: UIViewRepresentable {
    
    let mapName: String // Die ausgewählte Map
    
    func makeUIView(context: Context) -> SKView {
        let skView = SKView()
        
        // Lade die Szene für das tatsächliche Spiel
        if let scene = GameScene(fileNamed: "GameScene") {
            scene.scaleMode = .aspectFill // Heranzoomen und auf die tatsächliche Größe anpassen
            skView.presentScene(scene)
        }
        
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
        
        return skView
    }
    
    func updateUIView(_ uiView: SKView, context: Context) {
        // Aktualisiere die Ansicht, falls nötig
    }
}

#Preview {
    MapSpriteView(mapName: "Map1") // Beispielhafte Map in der Vorschau
        .frame(width: 300, height: 300) // Vorschau-Größe festlegen
}
