import Foundation
import SpriteKit

class GameManager {
    weak var scene: GameScene? // Referenz auf die GameScene zur Steuerung der Spielmechanik
    var isPlayerTurn: Bool = true // Gibt an, ob es der Zug des Spielers ist
    var currentPlayerIndex: Int = 0 // Verfolgt den aktuellen Spielerpanzer in der Runde
    
    init(scene: GameScene) {
        self.scene = scene
    }
    
    // Startet eine neue Runde im Spiel
    func startGame() {
        isPlayerTurn = true
        currentPlayerIndex = 0
        scene?.currentPanzer = scene?.selectedPanzers.first
        print("Spiel gestartet: Spieler ist an der Reihe")
    }
    
    // Prüft, ob das Spiel beendet ist
    func checkGameEnd() {
        print("checkGameEnd called in GameManager")
            guard let scene = scene else {
                print("checkGameEnd: Scene is nil")
                return
            }


        print("checkGameEnd: Überprüfung gestartet")
        print("Verbleibende Spielerpanzer: \(scene.selectedPanzers.count)")
        print("Verbleibende Gegnerpanzer: \(scene.enemyPanzers.count)")

        if scene.selectedPanzers.isEmpty {
            print("Spiel beendet: Alle Spielerpanzer wurden zerstört. Gegner gewinnt!")
            endGame(winner: "Enemy")
        } else if scene.enemyPanzers.isEmpty {
            print("Spiel beendet: Alle Gegnerpanzer wurden zerstört. Spieler gewinnt!")
            endGame(winner: "Player")
        } else {
            print("checkGameEnd: Spiel läuft noch weiter")
        }
    }
    
    // Funktion zum Spielende mit Gewinn- oder Verlustanzeige
    private func endGame(winner: String) {
        guard let scene = scene else {
            print("endGame: Scene is nil")
            return
        }

        print("EndGame aufgerufen. Gewinner: \(winner)")

        let imageName = winner == "Player" ? "YouWin" : "YouLose"
        print("Versuche, Bild zu laden: \(imageName)")
        
        guard let image = UIImage(named: imageName) else {
            print("Fehler: Konnte Bild \(imageName) nicht laden")
            return
        }
        
        let endImage = SKSpriteNode(texture: SKTexture(image: image))
        endImage.size = CGSize(width: 1500, height: 1500) // BildGrösse, je nach gewünschter Größe anpassen
        // Center the image on the screen
        // Zentriere das Bild relativ zum Ursprung der Szene
            endImage.position = CGPoint(x: 0, y: 100)
        endImage.zPosition = 1000
        endImage.name = "endGameImage"

        scene.addChild(endImage)
        print("EndGame-Bild zur Szene hinzugefügt und zentriert")

        // Add a tap gesture recognizer to dismiss the end game image
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissEndGameImage))
        scene.view?.addGestureRecognizer(tapGesture)
        print("Tap-Geste hinzugefügt")

        // Add a label to prompt the user to tap to continue
        let tapLabel = SKLabelNode(fontNamed: "Arial")
        tapLabel.text = "Tap to continue"
        tapLabel.fontSize = 24
        tapLabel.fontColor = .white
        tapLabel.position = CGPoint(x: scene.frame.midX, y: scene.frame.midY - endImage.size.height / 2 - 30)
        tapLabel.zPosition = 1001
        tapLabel.name = "tapLabel"
        scene.addChild(tapLabel)
        print("Tap-Label zur Szene hinzugefügt")

        // Animate the label to make it more noticeable
        let fadeAction = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.5),
            SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        ])
        tapLabel.run(SKAction.repeatForever(fadeAction))
    }

    @objc private func dismissEndGameImage() {
        guard let scene = scene else {
            print("dismissEndGameImage: Scene is nil")
            return
        }

        scene.childNode(withName: "endGameImage")?.removeFromParent()
        scene.childNode(withName: "tapLabel")?.removeFromParent()
        scene.view?.gestureRecognizers?.removeAll()

        print("End game image and tap label removed")

        // Return to SelectScreenView
        returnToSelectScreen()
    }

    private func returnToSelectScreen() {
        print("Returning to SelectScreenView")
        
        // Fade out the current scene
        let fadeOutAction = SKAction.fadeOut(withDuration: 0.5)
        scene?.run(fadeOutAction) {
            // Post notification to dismiss the game scene and return to SelectScreenView
            NotificationCenter.default.post(name: NSNotification.Name("ReturnToSelectScreenView"), object: nil)
        }
    }
    // Wechselt zum nächsten Panzer, wenn ein Spielerzug beendet ist
    func endPlayerTurn() {
        guard let scene = scene else { return }
        
        // Setze `hasFired` zurück
        scene.hasFired = false
        
        currentPlayerIndex += 1
        if currentPlayerIndex < scene.selectedPanzers.count {
            scene.currentPanzer = scene.selectedPanzers[currentPlayerIndex]
            print("Nächster Spielerpanzer ist an der Reihe")
        } else {
            // Alle Spielerpanzer waren dran, wechsle zum Gegnerzug
            isPlayerTurn = false
            currentPlayerIndex = 0
            print("Alle Spielerpanzer waren dran. Gegner ist jetzt an der Reihe")
            startEnemyTurn()
        }
        
        print("Aktueller Zustand: isPlayerTurn = \(isPlayerTurn), currentPlayerIndex = \(currentPlayerIndex)")
    }
    
    // Gegnerzüge durchführen, indem jede `EnemyAI`-Instanz eine Aktion ausführt
    private func startEnemyTurn() {
        guard let scene = scene else { return }
        
        isPlayerTurn = false
        var completedActions = 0
        let totalActions = scene.enemyAIControllers.count
        
        for enemyAI in scene.enemyAIControllers {
            enemyAI.performAction {
                completedActions += 1
                if completedActions == totalActions {
                    // Alle Gegnerzüge sind abgeschlossen
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.endEnemyTurn()
                    }
                }
            }
        }
    }
    
    // Gegnerzug beenden und zum Spieler zurückkehren
    private func endEnemyTurn() {
        guard let scene = scene else { return }
        
        // Setze `hasFired` zurück
        scene.hasFired = false
        
        isPlayerTurn = true
        currentPlayerIndex = 0
        scene.currentPanzer = scene.selectedPanzers.first
        print("Gegnerzug beendet. Spieler ist jetzt an der Reihe")
        print("Spielerzug beendet, Wechsel zu Gegnerzug: isPlayerTurn = \(isPlayerTurn)")
    }
}
