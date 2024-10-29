//
//  EnemyAi.swift
//  Tanks Arma Get On
//
//  Created by Antonio Loggia on 29.10.24.


import SpriteKit

// EnemyAI-Klasse für die Gegnerlogik
class EnemyAI {
    var enemyPanzer: Panzer
    weak var scene: GameScene?
    
    init(enemyPanzer: Panzer, scene: GameScene) {
        self.enemyPanzer = enemyPanzer
        self.scene = scene
    }
    
    func chooseTarget() -> Panzer? {
        guard let playerPanzers = scene?.selectedPanzers, !playerPanzers.isEmpty else {
            return nil
        }
        
        return playerPanzers.min(by: { distance(to: $0) < distance(to: $1) })
    }
    
    private func distance(to target: Panzer) -> CGFloat {
        return hypot(enemyPanzer.position.x - target.position.x, enemyPanzer.position.y - target.position.y)
    }
    
    func moveRandomly() {
        let randomDirection = Bool.random() ? enemyPanzer.moveLeft : enemyPanzer.moveRight
        randomDirection()
    }
    
    func shootAtTarget() {
        guard let target = chooseTarget() else { return }
        
        // Berechnung des Schusswinkels und der Stärke
        let dx = target.position.x - enemyPanzer.position.x
        let dy = target.position.y - enemyPanzer.position.y
        let angle = atan2(dy, dx)
        
        // Setze eine angemessene Stärke für den Schuss
        let power: CGFloat = 100.0
        let impulse = CGVector(dx: power * cos(angle), dy: power * sin(angle))
        
        // Erstelle und konfiguriere das Projektil
        let bullet = SKSpriteNode(imageNamed: "tank_bullet2Fly")
        bullet.size = CGSize(width: 50, height: 20)
        bullet.position = enemyPanzer.position
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody?.isDynamic = true
        bullet.physicsBody?.categoryBitMask = CollisionCategory.bullet
        bullet.physicsBody?.collisionBitMask = CollisionCategory.grassTile | CollisionCategory.panzer
        bullet.physicsBody?.contactTestBitMask = CollisionCategory.panzer
        bullet.physicsBody?.usesPreciseCollisionDetection = true
        
        // Füge die Kugel zur Szene hinzu und wende den Impuls an
        scene?.addChild(bullet)
        bullet.physicsBody?.applyImpulse(impulse)
        
        // Schuss-Sound abspielen (falls verfügbar)
        bullet.run(SKAction.playSoundFileNamed("shot.mp3", waitForCompletion: false))
    }
    
    func performAction(completion: @escaping () -> Void) {
        moveRandomly()
        shootAtTarget()
        
        // Verzögere die Benachrichtigung, bis die Aktion abgeschlossen ist
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            completion() // Stelle sicher, dass der Abschluss-Handler nach der Aktion aufgerufen wird
        }
    }

    
}
