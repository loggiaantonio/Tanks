import SwiftUI
import SpriteKit

struct GameView: View {
    let selectedPanzers: [String] // Panzer, die aus dem SelectScreen übergeben wurden
    let selectedMap: String       // Gewählte Map, die übergeben wurde
    @Environment(\.presentationMode) var presentationMode // Präsentationsmodus-Umgebung für das Zurücknavigieren

    var body: some View {
        SpriteView(mapName: selectedMap, selectedPanzerNames: selectedPanzers)
            .edgesIgnoringSafeArea(.all) // Die Ansicht über den gesamten Bildschirm ziehen
            .onAppear {
                // Observer hinzufügen, um den Back-Button in der GameScene zu erkennen
                NotificationCenter.default.addObserver(forName: NSNotification.Name("DismissGameScene"), object: nil, queue: .main) { _ in
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
            .onDisappear {
                // Entferne den Observer, wenn die Ansicht geschlossen wird, um Speicherlecks zu vermeiden
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name("DismissGameScene"), object: nil)
            }
    }
}
