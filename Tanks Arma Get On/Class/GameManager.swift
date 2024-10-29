//
//  GameManager.swift
//  Tanks Arma Get On
//
//  Created by Antonio Loggia on 29.10.24.


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
        guard let scene = scene else { return }
        
        if scene.selectedPanzers.isEmpty {
            print("Spiel beendet: Alle Spielerpanzer wurden zerstört. Gegner gewinnt!")
            endGame(winner: "Enemy")
        } else if scene.enemyPanzers.isEmpty {
            print("Spiel beendet: Alle Gegnerpanzer wurden zerstört. Spieler gewinnt!")
            endGame(winner: "Player")
        }
    }
    
    // Funktion zum Spielende
    private func endGame(winner: String) {
        print("Das Spiel ist vorbei! Gewinner: \(winner)")
        // Füge hier eine Endbildschirm- oder Menülogik ein
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

