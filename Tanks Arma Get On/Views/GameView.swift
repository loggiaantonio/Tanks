import SwiftUI
import SpriteKit

struct GameView: View {
    let selectedPanzers: [String] // Panzer, die aus dem SelectScreen übergeben wurden
    let selectedMap: String       // Gewählte Map, die übergeben wurde
    
    var body: some View {
        SpriteView(mapName: selectedMap, selectedPanzers: selectedPanzers)
            .edgesIgnoringSafeArea(.all) // Die Ansicht über den gesamten Bildschirm ziehen
    }
}
