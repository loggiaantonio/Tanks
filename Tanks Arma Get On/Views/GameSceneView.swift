import SwiftUI
import SpriteKit

// UIViewRepresentable zur Darstellung von SpriteKit-Szenen in SwiftUI
struct GameSceneView: UIViewRepresentable {
    @Binding var showWeaponMenu: Bool
    @Binding var selectedWeapon: Weapon?

    // Coordinator für die Verwaltung des NotificationCenters
    class Coordinator: NSObject {
        var parent: GameSceneView
        
        init(parent: GameSceneView) {
            self.parent = parent
        }

        @objc func showWeaponMenu() {
            print("Notification received: ShowWeaponMenu") // Debug-Ausgabe
            parent.showWeaponMenu = true
        }
        
        @objc func hideWeaponMenu() {
            print("Notification received: HideWeaponMenu") // Debug-Ausgabe
            parent.showWeaponMenu = false
        }
    }

    // Erstellen des Coordinators
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> SKView {
        let skView = SKView()
        
        let scene = GameScene(size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)
        
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
        
        // Observer für das Weapon Menu hinzufügen
        let coordinator = context.coordinator
        NotificationCenter.default.addObserver(coordinator, selector: #selector(Coordinator.showWeaponMenu), name: NSNotification.Name("ShowWeaponMenu"), object: nil)
        NotificationCenter.default.addObserver(coordinator, selector: #selector(Coordinator.hideWeaponMenu), name: NSNotification.Name("HideWeaponMenu"), object: nil)

        return skView
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        // Hier können bei Bedarf Änderungen vorgenommen werden
    }
    
    // Observer beim Deinitialisieren der View entfernen
    static func dismantleUIView(_ uiView: SKView, coordinator: Coordinator) {
        NotificationCenter.default.removeObserver(coordinator, name: NSNotification.Name("ShowWeaponMenu"), object: nil)
        NotificationCenter.default.removeObserver(coordinator, name: NSNotification.Name("HideWeaponMenu"), object: nil)
    }
}
// Die SwiftUI Preview für die GameSceneView
struct GameSceneView_Previews: PreviewProvider {
    static var previews: some View {
        // Dummydaten, um die Preview darzustellen
        GameSceneView(showWeaponMenu: .constant(false), selectedWeapon: .constant(nil))
            .edgesIgnoringSafeArea(.all)
    }
}
