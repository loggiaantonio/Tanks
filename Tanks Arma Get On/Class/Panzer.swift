import SwiftUI
import SpriteKit

class Panzer: SKSpriteNode {
    var healthPoints: Int
    var isEnemy: Bool
    var moveSound: SKAction
    var shotSound: SKAction
    var bulletHitSound: SKAction
    var explosionSound: SKAction
    
    var weaponMenuViewController: UIViewController?
    var hasFired = false
    var aimAngle: CGFloat = 0.0
    var powerFactor: CGFloat = 1.0
    
    var availableWeapons: [Weapon] = [
        Weapon(name: "Bullet1", image: "tank_bullet1", damage: 10, ammoCount: 10),
        Weapon(name: "Bullet2", image: "tank_bullet2", damage: 20, ammoCount: 8),
        Weapon(name: "Bullet3", image: "tank_bullet3", damage: 30, ammoCount: 6),
        Weapon(name: "Bullet4", image: "tank_bullet4", damage: 40, ammoCount: 4),
        Weapon(name: "Bullet5", image: "tank_bullet5", damage: 50, ammoCount: 2),
        Weapon(name: "Bullet6", image: "tank_bullet6", damage: 60, ammoCount: 1)
    ]
    
    init(imageNamed: String, isEnemy: Bool) {
        self.healthPoints = isEnemy ? 10 : 150
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
        self.physicsBody?.affectedByGravity = true
        self.physicsBody?.mass = 10.0
        self.physicsBody?.density = 1.0
        self.physicsBody?.restitution = 0.0
        self.physicsBody?.categoryBitMask = isEnemy ? CollisionCategory.enemyPanzer : CollisionCategory.panzer
        self.physicsBody?.collisionBitMask = CollisionCategory.grassTile | CollisionCategory.bullet
        self.physicsBody?.contactTestBitMask = CollisionCategory.bullet | CollisionCategory.grassTile
    }
    
    func applyDamage(_ damage: Int) {
        healthPoints -= damage
        updateHealthLabel()
        print("Panzer \(self.name ?? "Unknown") hat \(damage) Schaden erhalten. Verbleibende HP: \(healthPoints)")

        let shimmerEffect = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.1, duration: 0.1),
                SKAction.colorize(with: .red, colorBlendFactor: 0.5, duration: 0.1)
            ]),
            SKAction.wait(forDuration: 0.1),
            SKAction.group([
                SKAction.scale(to: 1.0, duration: 0.1),
                SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.1)
            ])
        ])
        self.run(shimmerEffect)

        if healthPoints <= 0 {
                print("Panzer \(self.name ?? "Unknown") wurde zerstört")
                destroy()
            }

            // Check for game end after applying damage
            if let gameScene = self.scene as? GameScene {
                if let gameManager = gameScene.gameManager {
                    print("Rufe checkGameEnd nach Schadensanwendung auf")
                    gameManager.checkGameEnd()
                } else {
                    print("Fehler: gameManager ist nil in GameScene")
                }
            } else {
                print("Fehler: Konnte GameScene nicht finden")
            }
        }
    
    func destroy() {
        self.run(explosionSound)

        if let gameScene = self.scene as? GameScene {
            gameScene.showExplosion(at: self.position)
            
            if isEnemy {
                gameScene.enemyPanzers.removeAll { $0 == self.name }
                print("Enemy Panzer \(self.name ?? "unbekannt") entfernt. Verbleibende Gegner: \(gameScene.enemyPanzers.count)")
            } else {
                gameScene.selectedPanzers.removeAll { $0 == self }
                print("Spieler Panzer \(self.name ?? "unbekannt") entfernt. Verbleibende Spieler: \(gameScene.selectedPanzers.count)")
            }

            gameScene.updatePanzerCountLabels()
            
            // Check for game end after destroying a tank
            print("Rufe checkGameEnd nach Zerstörung eines Panzers auf")
            gameScene.gameManager?.checkGameEnd()
        } else {
            print("Konnte Panzer nicht aus Arrays entfernen: gameScene ist nil")
        }

        self.removeFromParent()
        }

    func showExplosion() {
        let explosion = SKSpriteNode(imageNamed: "tank_explosion4")
        explosion.position = self.position
        explosion.zPosition = 10
        explosion.size = CGSize(width: 100, height: 100)
        self.parent?.addChild(explosion)

        let removeExplosion = SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.removeFromParent()
        ])
        explosion.run(removeExplosion)
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
    
    func showWeaponMenu(in view: SKView) {
        guard let gameScene = self.scene as? GameScene else {
            print("Fehler: Scene ist nicht vom Typ GameScene.")
            return
        }

        let weaponMenu = WeaponMenuView(weapons: availableWeapons) { selectedWeapon in
            gameScene.setCurrentWeapon(selectedWeapon)
            self.hideWeaponMenu()
        }

        let hostingController = UIHostingController(rootView: weaponMenu)
        hostingController.view.backgroundColor = UIColor.clear
        
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
        bullet.zPosition = 10

        print("Bullet erstellt und abgefeuert: \(bulletImageName)")

        bullet.userData = ["damage": selectedWeapon.damage]
        
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody?.isDynamic = true
        bullet.physicsBody?.categoryBitMask = CollisionCategory.bullet
        bullet.physicsBody?.collisionBitMask = CollisionCategory.grassTile | CollisionCategory.panzer
        bullet.physicsBody?.contactTestBitMask = CollisionCategory.grassTile |  CollisionCategory.enemyPanzer
        bullet.physicsBody?.usesPreciseCollisionDetection = true

        self.parent?.addChild(bullet)
        if let scene = self.scene as? GameScene {
            scene.bullet = bullet
        }

        let adjustedAngle = self.xScale == -1 ? .pi - angle : angle
        bullet.zRotation = adjustedAngle

        let speed: CGFloat = 200.0 * powerFactor
        let dx = speed * cos(adjustedAngle)
        let dy = speed * sin(adjustedAngle)

        bullet.physicsBody?.applyImpulse(CGVector(dx: dx, dy: dy))

        print("Schießen mit Waffe: \(selectedWeapon.name) mit Winkel: \(adjustedAngle), dx: \(dx), dy: \(dy)")
        
        selectedWeapon.ammoCount -= 1
        bullet.run(shotSound)
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
}
