import SwiftUI
import SpriteKit

class Panzer: SKSpriteNode {
    var healthPoints: Int
    var isEnemy: Bool
    var moveSound: SKAction
    var shotSound: SKAction
    var bulletHitSound: SKAction
    var explosionSound: SKAction
    
    // Waffenmenü View-Controller, um die Anzeige zu steuern
    var weaponMenuViewController: UIViewController?
    
    // Eigenschaften für Schießen und Zielen
    var hasFired = false
    var aimAngle: CGFloat = 0.0 // Standardwert für Zielwinkel
    var powerFactor: CGFloat = 1.0 // Standardwert für Schusskraft
    
    // Waffenliste, die diesem Panzer zur Verfügung steht
    var availableWeapons: [Weapon] = [
        Weapon(name: "Bullet1", image: "tank_bullet1", damage: 10, ammoCount: 10),
        Weapon(name: "Bullet2", image: "tank_bullet2", damage: 20, ammoCount: 8),
        Weapon(name: "Bullet3", image: "tank_bullet3", damage: 30, ammoCount: 6),
        Weapon(name: "Bullet4", image: "tank_bullet4", damage: 40, ammoCount: 4),
        Weapon(name: "Bullet5", image: "tank_bullet5", damage: 50, ammoCount: 2),
        Weapon(name: "Bullet6", image: "tank_bullet6", damage: 60, ammoCount: 1)
    ]
    
    init(imageNamed: String, isEnemy: Bool) {
        self.healthPoints = isEnemy ? 100 : 150
        self.isEnemy = isEnemy
        self.moveSound = SKAction.playSoundFileNamed("TankMove.mp3", waitForCompletion: false)
        self.shotSound = SKAction.playSoundFileNamed("shot.mp3", waitForCompletion: false)
        self.bulletHitSound = SKAction.playSoundFileNamed("bulletHit.wav", waitForCompletion: false)
        self.explosionSound = SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false)
        
        let texture = SKTexture(imageNamed: imageNamed)
        super.init(texture: texture, color: .clear, size: CGSize(width: 70, height: 70))
        
        self.name = imageNamed
        setupPhysics()
        addHealthLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupPhysics() {
        self.physicsBody = SKPhysicsBody(rectangleOf: self.size, center: CGPoint(x: 0, y: self.size.height / 4))
        self.physicsBody?.isDynamic = true
        self.physicsBody?.categoryBitMask = isEnemy ? CollisionCategory.enemyPanzer : CollisionCategory.panzer
        self.physicsBody?.collisionBitMask = CollisionCategory.grassTile
        self.physicsBody?.contactTestBitMask = CollisionCategory.bullet | CollisionCategory.grassTile
        self.physicsBody?.restitution = 0.0
    }
    
    
    func showWeaponMenu(in view: SKView) {
        // Casten Sie scene auf GameScene
        guard let gameScene = self.scene as? GameScene else {
            print("Fehler: Scene ist nicht vom Typ GameScene.")
            return
        }

        let weaponMenu = WeaponMenuView(weapons: availableWeapons) { selectedWeapon in
            gameScene.setCurrentWeapon(selectedWeapon) // Waffe in der GameScene setzen
            self.hideWeaponMenu()
        }

        let hostingController = UIHostingController(rootView: weaponMenu)
        hostingController.view.backgroundColor = UIColor.clear // Transparenter Hintergrund
        
        // Setze das Menü über den Panzer, zentriert und festgesetzt
        hostingController.view.frame = CGRect(
            x: view.bounds.width / 4,
            y: view.bounds.height / 2 - 75,
            width: view.bounds.width / 2,
            height: 75
        )
        hostingController.view.layer.zPosition = 1000
        
        view.addSubview(hostingController.view)
        weaponMenuViewController = hostingController
    }

    func hideWeaponMenu() {
        weaponMenuViewController?.view.removeFromSuperview()
        weaponMenuViewController = nil
    }

    func shootWeapon(named weaponName: String, angle: CGFloat) {
        if hasFired {
            print("Es wurde bereits geschossen! Warte auf die nächste Runde.")
            return
        }
        hasFired = true

        guard var selectedWeapon = findWeaponByName(weaponName) else {
            print("Waffe nicht gefunden!")
            return
        }

        let bulletImageName = "\(selectedWeapon.name)Fly"
        let bullet = SKSpriteNode(imageNamed: bulletImageName)
        bullet.size = CGSize(width: 50, height: 20)
        bullet.position = CGPoint(x: self.position.x, y: self.position.y + self.size.height / 2)

        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody?.isDynamic = true
        bullet.physicsBody?.categoryBitMask = CollisionCategory.bullet
        bullet.physicsBody?.collisionBitMask = CollisionCategory.grassTile | CollisionCategory.enemyPanzer
        bullet.physicsBody?.contactTestBitMask = CollisionCategory.enemyPanzer | CollisionCategory.grassTile
        bullet.physicsBody?.usesPreciseCollisionDetection = true

        self.parent?.addChild(bullet)

        // Berechne `adjustedAngle` abhängig von der Blickrichtung des Panzers
        let adjustedAngle = self.xScale == -1 ? .pi - angle : angle

        // Setze die Rotation der Bullet, um visuell die Richtung anzuzeigen
        bullet.zRotation = adjustedAngle

        // Berechne die Geschwindigkeit in die entsprechende Richtung
        let speed: CGFloat = 200.0 * powerFactor
        let dx = speed * cos(adjustedAngle)
        let dy = speed * sin(adjustedAngle)

        // Wende den Impuls auf die Bullet an
        bullet.physicsBody?.applyImpulse(CGVector(dx: dx, dy: dy))

        print("Schießen mit Waffe: \(selectedWeapon.name) mit Winkel: \(adjustedAngle), dx: \(dx), dy: \(dy)")

        selectedWeapon.ammoCount -= 1

        bullet.run(shotSound)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.endTurn()
        }
    }
    private func findWeaponByName(_ name: String) -> Weapon? {
        return availableWeapons.first { $0.name == name }
    }

    private func endTurn() {
        print("Zug beendet für \(self.name ?? "Panzer")")
    }
    
    func moveLeft() {
        self.position.x -= 10
        self.xScale = -1
        self.run(moveSound)
    }
    
    func moveRight() {
        self.position.x += 10
        self.xScale = 1
        self.run(moveSound)
    }
    
    func applyDamage(_ damage: Int) {
        healthPoints -= damage
        updateHealthLabel()
        
        if healthPoints <= 0 {
            destroy()
        }
    }

    func destroy() {
        self.run(explosionSound)
        self.removeFromParent()
        
        if let gameScene = self.scene as? GameScene, gameScene.isPlacingPhase {
            // Neu platzieren, falls wir uns in der Platzierungsphase befinden
            gameScene.respawnPanzer(self)
        } else {
            print("\(self.name ?? "Panzer") wurde zerstört und wird nicht respawned, da das Spiel bereits gestartet ist.")
        }
    
    }
    
    private func addHealthLabel() {
        let healthLabel = SKLabelNode(text: "\(healthPoints)")
        healthLabel.fontSize = 16
        healthLabel.fontName = "Arial-BoldMT"
        healthLabel.fontColor = isEnemy ? .red : .green
        healthLabel.position = CGPoint(x: 0, y: self.size.height / 2 + 20)
        healthLabel.zPosition = 5
        healthLabel.name = "healthLabel"
        
        self.addChild(healthLabel)
    }
    
    private func updateHealthLabel() {
        guard let healthLabel = self.childNode(withName: "healthLabel") as? SKLabelNode else { return }
        healthLabel.text = "\(healthPoints)"
    }
}
