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
        
        // Wähle die Waffe für den feindlichen Panzer
        var selectedWeapon = enemyPanzer.availableWeapons[1] // Beispiel: Bullet2 verwenden, anpassbar
        
        // Setze das Bild der Flug-Bullet basierend auf der ausgewählten Waffe
        let bulletImageName = "\(selectedWeapon.name)Fly" // Beispiel: "Bullet2Fly"
        let bullet = SKSpriteNode(imageNamed: bulletImageName)
        bullet.size = CGSize(width: 50, height: 20)
        bullet.position = CGPoint(x: enemyPanzer.position.x, y: enemyPanzer.position.y + enemyPanzer.size.height / 2)
        bullet.zPosition = 10
        bullet.alpha = 1.0 // Sicherstellen, dass die Bullet sichtbar ist

        print("Enemy Bullet erstellt und abgefeuert: \(bulletImageName)")

        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody?.isDynamic = true
        bullet.physicsBody?.categoryBitMask = CollisionCategory.bullet
        bullet.physicsBody?.collisionBitMask = CollisionCategory.grassTile | CollisionCategory.panzer
        bullet.physicsBody?.contactTestBitMask = CollisionCategory.grassTile | CollisionCategory.panzer
        bullet.physicsBody?.usesPreciseCollisionDetection = true

        // Füge die Bullet zur Szene hinzu
        scene?.addChild(bullet)
        
        // Rotation und Winkel der Bullet einstellen
        let adjustedAngle = enemyPanzer.xScale == -1 ? .pi - angle : angle
        bullet.zRotation = adjustedAngle

        let speed: CGFloat = 200.0 * enemyPanzer.powerFactor
        let impulseVector = CGVector(dx: speed * cos(adjustedAngle), dy: speed * sin(adjustedAngle))
        bullet.physicsBody?.applyImpulse(impulseVector)

        print("Enemy schießt mit Waffe: \(selectedWeapon.name) mit Winkel: \(adjustedAngle), dx: \(impulseVector.dx), dy: \(impulseVector.dy)")

        // Schuss-Sound abspielen und Munitionsverbrauch für die Waffe verringern
        selectedWeapon.ammoCount -= 1
        bullet.run(enemyPanzer.shotSound)
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
