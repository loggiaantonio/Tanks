import SpriteKit
import SwiftUI

// Definiere die Kollisionskategorien (wie gehabt)
struct CollisionCategory {
    static let grassTile: UInt32 = 0x1 << 0 // 1
    static let panzer: UInt32 = 0x1 << 1 // 2
    static let enemyPanzer: UInt32 = 0x1 << 2 // 4
    static let bullet: UInt32 = 0x1 << 3 // 8
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    var firstTileMap: SKTileMapNode? // Neue Tilemap für den Hintergrund
    var backgroundTileMap: SKTileMapNode? // Hintergrund-Tilemap ohne Kollision
    var grassTileMap: SKTileMapNode?      // Tilemap für die Kollision
    var cameraNode: SKCameraNode! // Kamera-Node
    
    var selectedPanzers: [String] = [] // Liste der ausgewählten Panzer
    var currentPanzerIndex = 0 // Index des aktuell zu platzierenden Panzers
    var currentPanzer: SKSpriteNode? // Der Panzer, der gerade platziert wird
    
    var gameStarted = false // Spielstatus: ob das Spiel gestartet hat
    
    var leftButton: SKSpriteNode!
    var rightButton: SKSpriteNode!
    var upButton: SKSpriteNode!
    var downButton: SKSpriteNode!
    
    var powerBar: SKSpriteNode!
    
    var pauseButton: SKSpriteNode!
    var decisionTimer: Timer?
    
    // Pfeil, der anzeigt, welcher Panzer an der Reihe ist
    var currentArrow: SKSpriteNode?
    
    
    // Kamera Zoom und Pan Variablen
    var lastCameraScale: CGFloat = 0 // Letzter Zoom-Faktor der Kamera
    var lastPanTranslation: CGPoint = .zero // Letzter Versatz beim Panning
    
    
    var selectedWeapon: Weapon? // Die aktuell ausgewählte Waffe
    var weaponMenuViewController: UIViewController? // Verwaltet das SwiftUI-Waffenmenü
    
    
    var aimLine: SKShapeNode? // Der rote Strahl für das Zielen
    var aimAngle: CGFloat = 0 // Aktueller Winkel (0 = horizontal)
    var maxPower: CGFloat = 300 // Maximale Länge des Strahls basierend auf der Powerbar
    
    var bullet: SKSpriteNode? // Das Projektil (die Kugel)
    
    var enemyPanzers: [String] = ["Enemy1", "Enemy2", "Enemy3", "Enemy4"]
    var currentTurnIndex = 0 // Der Index, der zwischen Spieler- und Gegnerpanzern wechselt
    
    var hasFired = false // Variable zum Überprüfen, ob bereits geschossen wurde

    
    
    func endTurnAndManageNextAction() {
        hasFired = false

        // Hide the weapon menu before transitioning to the next turn
        hideWeaponMenu()

        // Determine if the current turn is for the player or the enemy
        if currentTurnIndex % 2 == 0 {
            // Player's turn
            if currentPanzerIndex < selectedPanzers.count {
                if let nextPanzer = childNode(withName: selectedPanzers[currentPanzerIndex]) as? SKSpriteNode {
                    currentPanzer = nextPanzer
                    showArrowAboveCurrentPanzer()
                    showWeaponMenu() // Show the weapon menu for the player's turn
                }
            }
        } else {
            // Enemy's turn
            let enemyIndex = currentPanzerIndex / 2 // Use a different index for enemy panzers
            if enemyIndex < enemyPanzers.count {
                if let enemyPanzer = childNode(withName: enemyPanzers[enemyIndex]) as? SKSpriteNode {
                    currentPanzer = enemyPanzer
                    enemyTurn() // Let the enemy fire
                }
            }
        }

        // Move to the next turn
        currentTurnIndex += 1
        if currentTurnIndex >= (selectedPanzers.count + enemyPanzers.count) {
            currentTurnIndex = 0 // Restart from the beginning
            currentPanzerIndex = 0 // Reset player index
        } else if currentTurnIndex % 2 == 0 {
            // Only increment the player's panzer index during the player's turns
            currentPanzerIndex += 1
        }
    }
    
    
    func endTurnAndSwitchToNextPanzerOrEnemy() {
        hasFired = false

        if currentTurnIndex % 2 == 0 {
            // Player turn
            if currentPanzerIndex < selectedPanzers.count {
                if let nextPanzer = childNode(withName: selectedPanzers[currentPanzerIndex]) as? SKSpriteNode {
                    currentPanzer = nextPanzer
                    showArrowAboveCurrentPanzer()
                    endTurnAndManageNextAction()// Show weapon menu for the player
                }
            }
        } else {
            // Enemy turn
            let enemyIndex = currentPanzerIndex / 2 // Use the same index for the enemy
            if enemyIndex < enemyPanzers.count {
                if let enemyPanzer = childNode(withName: enemyPanzers[enemyIndex]) as? SKSpriteNode {
                    currentPanzer = enemyPanzer
                    enemyTurn() // Enemy fires
                }
            }
        }

        // Increment the turn index and go to the next tank
        currentTurnIndex += 1
        if currentTurnIndex >= (selectedPanzers.count + enemyPanzers.count) {
            currentTurnIndex = 0 // Restart from the beginning
            currentPanzerIndex = 0 // Reset player index
        } else if currentTurnIndex % 2 == 0 {
            // Only increment `currentPanzerIndex` on player turns
            currentPanzerIndex += 1
        }
    }
    
   

    func enemyTurn() {
        // Wähle den Spieler-Panzer, auf den der Gegner schießt (nutzt denselben Index)
        if currentPanzerIndex < selectedPanzers.count {
            let targetPanzer = selectedPanzers[currentPanzerIndex]
            guard let targetPanzerNode = childNode(withName: targetPanzer) as? SKSpriteNode else {
                print("Zielpanzer nicht gefunden.")
                return
            }
            
            // Gegner zielt und schießt (wie bisher)
            let randomAngle = CGFloat.random(in: -CGFloat.pi/4...CGFloat.pi/4)
            let randomPower = CGFloat.random(in: 100...300)
            
            let bullet = SKSpriteNode(imageNamed: "tank_bullet2Fly")
            bullet.size = CGSize(width: 50, height: 20)
            bullet.position = currentPanzer?.position ?? CGPoint(x: 0, y: 0)
            
            bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
            bullet.physicsBody?.isDynamic = true
            bullet.physicsBody?.categoryBitMask = CollisionCategory.bullet
            bullet.physicsBody?.collisionBitMask = CollisionCategory.grassTile | CollisionCategory.panzer
            bullet.physicsBody?.contactTestBitMask = CollisionCategory.panzer
            bullet.physicsBody?.usesPreciseCollisionDetection = true
            
            addChild(bullet)
            
            let dx = randomPower * cos(randomAngle)
            let dy = randomPower * sin(randomAngle)
            
            bullet.physicsBody?.applyImpulse(CGVector(dx: dx, dy: dy))
            
            print("Gegner schießt auf \(targetPanzer) mit Winkel: \(randomAngle), Power: \(randomPower)")
            
            // Nach dem Schuss: Übergang zum nächsten Spieler
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.endTurnAndSwitchToNextPanzerOrEnemy()
            }
        }
    }
    // Funktion zum Wechseln zum nächsten Spieler-Panzer nach dem Gegnerzug
    func switchToNextPlayerPanzer() {
        hasFired=false

        // Schließe das Waffenmenü, bevor der nächste Panzer dran ist
        hideWeaponMenu()

        // Erhöhe den Index und wechsle zum nächsten Spieler-Panzer
        currentPanzerIndex += 1
        if currentPanzerIndex < selectedPanzers.count {
            if let nextPanzer = childNode(withName: selectedPanzers[currentPanzerIndex]) as? SKSpriteNode {
                currentPanzer = nextPanzer
                showArrowAboveCurrentPanzer()
                endTurnAndManageNextAction() // Spieler wählt Waffe und macht den Zug
            }
        } else {
            currentPanzerIndex = 0
            if let firstPanzer = childNode(withName: selectedPanzers[currentPanzerIndex]) as? SKSpriteNode {
                currentPanzer = firstPanzer
                showArrowAboveCurrentPanzer()
                endTurnAndManageNextAction()// Spieler wählt Waffe und macht den Zug
            }
        }
    }
    
    
    func updateAimLine() {
        // Wenn noch keine Ziel-Linie existiert, erstellen wir sie
        if aimLine == nil {
            aimLine = SKShapeNode()
            aimLine?.strokeColor = .red
            aimLine?.lineWidth = 2
            aimLine?.zPosition = 2
            addChild(aimLine!)
        }
        
        // Berechne die Länge basierend auf der Powerbar (maxPower)
        let powerFactor = powerBar.size.height / 100.0
        let aimLength = maxPower * powerFactor
        
        // Berechne das Ende des Zielstrahls basierend auf dem Winkel
        let dx = aimLength * cos(aimAngle)
        let dy = aimLength * sin(aimAngle)
        
        // Startpunkt des Strahls (Position des aktuellen Panzers)
        guard let currentPanzer = currentPanzer else { return }
        let startPoint = CGPoint(x: currentPanzer.position.x, y: currentPanzer.position.y + currentPanzer.size.height / 2)
        
        // Endpunkt des Strahls
        let endPoint = CGPoint(x: startPoint.x + dx, y: startPoint.y + dy)
        
        // Aktualisiere den Pfad des Strahls
        let path = CGMutablePath()
        path.move(to: startPoint)
        path.addLine(to: endPoint)
        aimLine?.path = path
    }
    
    // Funktion zum Anpassen des Zielwinkels (durch Hoch- und Runter-Tasten)
    func aimTankUp() {
        aimAngle += 0.1 // Erhöhe den Winkel
        if aimAngle > .pi / 2 { aimAngle = .pi / 2 } // Maximal 90 Grad nach oben
        updateAimLine()
    }
    
    func aimTankDown() {
        aimAngle -= 0.1 // Verringere den Winkel
        if aimAngle < -.pi / 2 { aimAngle = -.pi / 2 } // Maximal 90 Grad nach unten
        updateAimLine()
    }
    
    
    
    override func didMove(to view: SKView) {
        print("didMove: Szene wurde geladen")
        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        
        // Verwende die Kamera aus der Szene, falls vorhanden
        if let cameraFromScene = childNode(withName: "camera") as? SKCameraNode {
            cameraNode = cameraFromScene
            self.camera = cameraNode
            
            cameraNode.setScale(3.5)
        } else {
            print("Fehler: Kamera nicht gefunden!")
        }
        
        
        // Füge nur die Zoom-Geste hinzu
        view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:))))
        
        // Setze das contactDelegate, um Kollisionen zu überwachen
        physicsWorld.contactDelegate = self
        
        // Szene aus der GameScene.sks laden
        loadTileMaps()
        
        // Zeige den ersten Panzer an
        showNextPanzer()
        
        // Automatische Platzierung der Feind-Panzer
        placeEnemyPanzers()
        
        // Zeigt die Tiles (Kacheln) in der Map an!
        view.showsPhysics = true
        
        // fügt die Directionen
        addMovementButtons()
        
        // Add power bar
        addPowerBar()
        
        // Add bomb icon
        addBombIcon()
        
        addPauseButton()
        
        
    }
    
    
    
    func showWeaponMenu() {
        guard let view = self.view else { return }
        
        // Erstelle das SwiftUI-Waffenmenü mit den verschiedenen Waffen
        let weaponMenu = WeaponMenuView(weapons: [
            Weapon(name: "Bullet1", image: "tank_bullet1", damage: 10, ammoCount: 10),
            Weapon(name: "Bullet2", image: "tank_bullet2", damage: 20, ammoCount: 8),
            Weapon(name: "Bullet3", image: "tank_bullet3", damage: 30, ammoCount: 6),
            Weapon(name: "Bullet4", image: "tank_bullet4", damage: 40, ammoCount: 4),
            Weapon(name: "Bullet5", image: "tank_bullet5", damage: 50, ammoCount: 2),
            Weapon(name: "Bullet6", image: "tank_bullet6", damage: 60, ammoCount: 1)
        ]) { selectedWeapon in
            // Aktion beim Auswählen einer Waffe
            self.selectedWeapon = selectedWeapon
            print("Selected weapon: \(selectedWeapon.name)")
            
            // Menü verschwindet nach der Auswahl der Waffe
            self.hideWeaponMenu()
        }
        
        // Verwende einen UIHostingController, um das SwiftUI-View in SpriteKit anzuzeigen
        let hostingController = UIHostingController(rootView: weaponMenu)
        hostingController.view.backgroundColor = .clear // Transparenter Hintergrund
        
        // Menü anzeigen
        let menuHeight: CGFloat = 75  // Größe des Menüs
        let menuWidth: CGFloat = view.bounds.width / 2
        hostingController.view.frame = CGRect(
            x: view.bounds.width / 4,
            y: view.bounds.height / 2 - menuHeight,
            width: menuWidth,
            height: menuHeight
        )
        hostingController.view.layer.zPosition = 1000
        
        // Füge das SwiftUI-View zum SKView hinzu
        view.addSubview(hostingController.view)
        weaponMenuViewController = hostingController
    }
    
    // Waffenmenü entfernen
    func hideWeaponMenu() {
        weaponMenuViewController?.view.removeFromSuperview()
        weaponMenuViewController = nil
    }
    
    // Funktion zum Hinzufügen des Pfeils über dem aktuellen Panzer
    func showArrowAboveCurrentPanzer() {
        // Entferne vorherigen Pfeil, falls vorhanden
        currentArrow?.removeFromParent()
        
        // Stelle sicher, dass es einen aktuellen Panzer gibt
        guard let panzer = currentPanzer else { return }
        
        // Erstelle einen neuen Pfeil und positioniere ihn über dem Panzer
        currentArrow = SKSpriteNode(imageNamed: "arrowIcon") // Ersetze "arrowIcon" mit deinem Pfeil-Bild
        currentArrow?.size = CGSize(width: 50, height: 50)
        currentArrow?.position = CGPoint(x: panzer.position.x, y: panzer.position.y + panzer.size.height / 2 + 20)
        currentArrow?.zPosition = 1 // Über dem Panzer
        
        // Füge den Pfeil zur Szene hinzu
        addChild(currentArrow!)
    }
    
    func addPauseButton() {
        
        guard let view = self.view else { return }
        
        let screenWidth = view.bounds.width
        let screenHeight = view.bounds.height
        
        pauseButton = SKSpriteNode(imageNamed: "PauseIcon")
        pauseButton.size = CGSize(width: 50, height: 50) // Kleinere Größe
        pauseButton.position = CGPoint(x: -screenWidth/2 + 300, y: -screenHeight/2 + 130)
        pauseButton.name = "pauseButton"
        pauseButton.zPosition = 10
        cameraNode.addChild(pauseButton)
    }
    
    func addMovementButtons() {
        // Die Bildschirmgröße bestimmen, basierend auf der Größe des view
        guard let view = self.view else { return }
        
        let screenWidth = view.bounds.width
        let screenHeight = view.bounds.height
        
        // Links button
        leftButton = SKSpriteNode(imageNamed: "leftButton")
        leftButton.size = CGSize(width: 50, height: 50)
        leftButton.position = CGPoint(x: -screenWidth/2 - 350, y: -screenHeight/2 - 100) // Unten links
        leftButton.name = "leftButton"
        leftButton.zPosition = 10
        cameraNode.addChild(leftButton)
        
        // Rechts button
        rightButton = SKSpriteNode(imageNamed: "rightButton")
        rightButton.size = CGSize(width: 50, height: 50)
        rightButton.position = CGPoint(x: -screenWidth/2 - 250, y: -screenHeight/2 - 100) // Unten links, aber weiter rechts
        rightButton.name = "rightButton"
        rightButton.zPosition = 10
        cameraNode.addChild(rightButton)
        
        // Oben button
        upButton = SKSpriteNode(imageNamed: "upButton")
        upButton.size = CGSize(width: 50, height: 50)
        upButton.position = CGPoint(x: -screenWidth/2 - 300, y: -screenHeight/2 - 50) // Über den Buttons links/rechts
        upButton.name = "upButton"
        upButton.zPosition = 10
        cameraNode.addChild(upButton)
        
        // Unten button
        downButton = SKSpriteNode(imageNamed: "downButton")
        downButton.size = CGSize(width: 50, height: 50)
        downButton.position = CGPoint(x: -screenWidth/2 - 300, y: -screenHeight/2 - 150) // Unter dem Up-Button
        downButton.name = "downButton"
        downButton.zPosition = 10
        cameraNode.addChild(downButton)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodesAtLocation = nodes(at: location)

        // Überprüfen, ob der Touch die Powerbar betrifft
        for node in nodesAtLocation {
            if node == powerBar {
                let previousLocation = touch.previousLocation(in: self)
                let deltaY = location.y - previousLocation.y
                
                // Aktualisiere die Größe der Powerbar basierend auf der Fingerbewegung
                let newHeight = powerBar.size.height + deltaY
                let clampedHeight = newHeight.clamped(to: 10...200) // Begrenze die Höhe der Powerbar zwischen 10 und 200
                updatePowerBar(newPower: clampedHeight)
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodesAtLocation = nodes(at: location)

        // Check which node was touched
        for node in nodesAtLocation {
            if node.name == "leftButton" {
                moveTankLeft()
            } else if node.name == "rightButton" {
                moveTankRight()
            } else if node.name == "upButton" {
                aimTankUp() // Increase aim angle
            } else if node.name == "downButton" {
                aimTankDown() // Decrease aim angle
            } else if node.name == "shootButton" {
                shoot() // Trigger the shoot function
            }
        }
    }
    
    func shoot() {
        // Ensure the player hasn't already fired
        if hasFired {
            print("Es wurde bereits geschossen! Warte auf die nächste Runde.")
            return
        }
        
        hasFired = true

        // Ensure the selected weapon and current panzer are valid
        guard var selectedWeapon = selectedWeapon, let currentPanzer = currentPanzer else { return }

        // Dynamically assign the bullet image name based on the weapon name
        let bulletImageName = "\(selectedWeapon.name)Fly"

        // Create the projectile (bullet)
        bullet = SKSpriteNode(imageNamed: bulletImageName)
        bullet?.size = CGSize(width: 50, height: 20) // Set the size of the projectile
        bullet?.position = CGPoint(x: currentPanzer.position.x, y: currentPanzer.position.y + currentPanzer.size.height / 2)

        // Add physics to the bullet
        bullet?.physicsBody = SKPhysicsBody(rectangleOf: bullet!.size)
        bullet?.physicsBody?.isDynamic = true
        bullet?.physicsBody?.categoryBitMask = CollisionCategory.bullet
        bullet?.physicsBody?.collisionBitMask = CollisionCategory.grassTile | CollisionCategory.enemyPanzer
        bullet?.physicsBody?.contactTestBitMask = CollisionCategory.enemyPanzer | CollisionCategory.grassTile
        bullet?.physicsBody?.usesPreciseCollisionDetection = true

        // Add the bullet to the scene
        addChild(bullet!)

        // Berechne die Schusskraft basierend auf der Höhe der Powerbar
        let powerFactor = powerBar.size.height / 100.0
        let speed: CGFloat = 200.0 * powerFactor // Skaliere die Schussgeschwindigkeit mit der Powerbar

        // Calculate the direction based on the aimAngle
        let dx = speed * cos(aimAngle)
        let dy = speed * sin(aimAngle)

        // Apply the impulse to the bullet
        bullet?.physicsBody?.applyImpulse(CGVector(dx: dx, dy: dy))

        print("Schießen mit Waffe: \(selectedWeapon.name) mit Power: \(powerFactor)")

        // Decrease ammo count by 1
        selectedWeapon.ammoCount -= 1

        // Hide the aim line
        aimLine?.removeFromParent()
        aimLine = nil

        // Trigger turn end after the shot, with a slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.endTurnAndManageNextAction()
        }
    }
    
    
    // Funktion, um die Powerbar zu aktualisieren (falls sie dynamisch ist)
    func updatePowerBar(newPower: CGFloat) {
        powerBar.size.height = newPower
        updateAimLine() // Aktualisiere auch die Länge des Zielstrahls
    }
    
    
    // Funktion zum Beenden des Zugs
    func selectWeapon(named weaponName: String) {
        print("Waffe \(weaponName) ausgewählt!")
        
        // Entferne vorherige Auswahl-Highlights (optional)
        cameraNode.enumerateChildNodes(withName: "*") { (node, stop) in
            if let weaponButton = node as? SKSpriteNode {
                weaponButton.color = .clear // Entferne die Markierung
            }
        }
        
        // Markiere die ausgewählte Waffe
        if let selectedWeaponButton = cameraNode.childNode(withName: weaponName) as? SKSpriteNode {
            selectedWeaponButton.color = .yellow
            selectedWeaponButton.colorBlendFactor = 0.5
        }
        
        // Verstecke das Waffenmenü nach der Auswahl
        hideWeaponMenu()
        
        // Wechsel zum nächsten Panzer oder führe Aktionen für den aktuellen Panzer aus
        endTurnAndManageNextAction()
    }
    
    func moveTankLeft() {
        currentPanzer?.position.x -= 10
    }
    
    func moveTankRight() {
        currentPanzer?.position.x += 10
    }
    
    
    
    
    func addPowerBar() {
        // Die Bildschirmgröße bestimmen, basierend auf der Größe des view
        guard let view = self.view else { return }
        
        let screenWidth = view.bounds.width
        let screenHeight = view.bounds.height
        
        powerBar = SKSpriteNode(color: .red, size: CGSize(width: 20, height: 100))
        powerBar.position = CGPoint(x: screenWidth/2 + 300, y: -screenHeight/2 + 10) // Rechts, zentriert auf der y-Achse
        powerBar.zPosition = 10
        cameraNode.addChild(powerBar)
    }
    
    func addBombIcon() {
        // Die Bildschirmgröße bestimmen, basierend auf der Größe des view
        guard let view = self.view else { return }
        
        let screenWidth = view.bounds.width
        let screenHeight = view.bounds.height
        
        // Bomben-Icon erstellen (Shoot-Button)
        let bombIcon = SKSpriteNode(imageNamed: "ShootIcon")
        bombIcon.size = CGSize(width: 70, height: 70)
        bombIcon.position = CGPoint(x: screenWidth / 2 + 300, y: -screenHeight / 2 - 120) // Unten rechts
        bombIcon.name = "shootButton" // Name des Buttons, damit wir ihn erkennen
        bombIcon.zPosition = 10
        cameraNode.addChild(bombIcon)
    }
    
   
   
    // Methode: Das Spiel beginnen, nachdem alle Panzer platziert wurden
    func startGame() {
        gameStarted = true
        print("Das Spiel hat begonnen")
        
        // Zeige das Waffenmenü für den ersten Panzer an
        currentPanzerIndex = 0
        if let firstPanzerName = selectedPanzers.first,
           let firstPanzer = childNode(withName: firstPanzerName) as? SKSpriteNode {
            currentPanzer = firstPanzer
            endTurnAndManageNextAction()
        }
    }
    
    // Lade die Tilemaps, ohne sie erneut zur Szene hinzuzufügen
    func loadTileMaps() {
        print("loadTileMaps: Versuche, Tilemaps zu laden")
        
        // Versuche, die FirstTiles zu laden
        if let firstMap = childNode(withName: "FirstTiles") as? SKTileMapNode {
            print("loadTileMaps: FirstTiles gefunden")
            firstTileMap = firstMap
            firstTileMap?.zPosition = -1 // Ganz unten, unter allen anderen
        } else {
            print("loadTileMaps: Fehler - FirstTiles nicht gefunden")
        }
        
        // Versuche, die BackgroundTiles zu laden
        if let backgroundMap = childNode(withName: "WaterTiles") as? SKTileMapNode {
            print("loadTileMaps: WaterTiles gefunden")
            backgroundTileMap = backgroundMap
            backgroundTileMap?.zPosition = -2 // Hinter allen anderen Elementen
        } else {
            print("loadTileMaps: Fehler - BackgroundTiles nicht gefunden")
        }
        
        // Versuche, die GrassTiles zu laden
        if let grassMap = childNode(withName: "GrassTiles") as? SKTileMapNode {
            print("loadTileMaps: GrassTiles gefunden")
            grassTileMap = grassMap
            grassTileMap?.zPosition = 0 // Soll hinter den Panzern liegen, aber über dem Hintergrund
            setupGrassTilesPhysics() // Füge Kollisionen hinzu
        } else {
            print("loadTileMaps: Fehler - GrassTiles nicht gefunden")
        }
    }
// Füge Kollisionen für die GrassTiles hinzu
    func setupGrassTilesPhysics() {
        // Use guard let to safely unwrap grassTileMap
        guard let grassTileMap = grassTileMap else {
            print("setupGrassTilesPhysics: Fehler - GrassTiles ist nil")
            return
        }

        // Iterate over all tiles in the grass tile map
        for row in 0..<grassTileMap.numberOfRows {
            for column in 0..<grassTileMap.numberOfColumns {
                if let tileDefinition = grassTileMap.tileDefinition(atColumn: column, row: row) {
                    // Check if the tile is marked as "solid"
                    if let isSolid = tileDefinition.userData?.value(forKey: "solid") as? Bool, isSolid {
                        let tileSize = grassTileMap.tileSize
                        let tilePosition = grassTileMap.centerOfTile(atColumn: column, row: row)

                        // Create a physics body that matches the shape of the tile
                        let path = CGMutablePath()
                        path.addRect(CGRect(x: -tileSize.width / 2, y: -tileSize.height / 2, width: tileSize.width, height: tileSize.height))

                        let physicsBody = SKPhysicsBody(polygonFrom: path)
                        physicsBody.isDynamic = false // The tile is static
                        physicsBody.categoryBitMask = CollisionCategory.grassTile
                        physicsBody.collisionBitMask = CollisionCategory.panzer // Adjust based on your needs
                        physicsBody.contactTestBitMask = CollisionCategory.panzer

                        // Create a shape node to visualize the physics body (optional)
                        let tileNode = SKShapeNode(path: path)
                        tileNode.position = tilePosition
                        tileNode.zPosition = -0.1 // Slightly below the visual tile
                        tileNode.fillColor = .clear // Make the shape node invisible
                        
                        tileNode.physicsBody = physicsBody

                        // Optionally add the tile node to the scene for debugging purposes
                        addChild(tileNode)
                    }
                }
            }
        }
    }
    
    // Zeige den nächsten Panzer, falls es noch Panzer gibt
    func showNextPanzer() {
        if currentPanzerIndex < selectedPanzers.count {
            let panzerName = selectedPanzers[currentPanzerIndex]
            print("showNextPanzer: Zeige Panzer \(panzerName) an")
            
            let panzer = SKSpriteNode(imageNamed: panzerName)
            panzer.size = CGSize(width: 70, height: 70) // Panzerskalierung auf eine kleinere Größe
            panzer.position = CGPoint(x: 0, y: 0) // Startposition in der Mitte
            panzer.zPosition = 0 // Über der Map
            panzer.name = panzerName // Setze den Namen des Panzers
            
            panzer.healthPoints = 150
            panzer.addHealthBar(isEnemy: false)
            
            currentPanzer = panzer
            addChild(panzer)
            print("showNextPanzer: Panzer wurde hinzugefügt")
            showArrowAboveCurrentPanzer()
            
        } else {
            // Wenn alle Panzer platziert sind, beginne das Spiel
            startGame()
        }
    }
    
    // When the tank moves, the arrow should move with it
    override func update(_ currentTime: TimeInterval) {
        guard let currentPanzer = currentPanzer, let currentArrow = currentArrow else { return }

        // Calculate the new position of the arrow, slightly above the tank
        let arrowOffset: CGFloat = currentPanzer.size.height / 2 + 20 // Adjust this value for more or less space above the tank

        // Update the arrow's position to stay above the tank
        currentArrow.position = CGPoint(
            x: currentPanzer.position.x,
            y: currentPanzer.position.y + arrowOffset
        )
    }
    
    
    // Berühre den Bildschirm, um den Panzer zu platzieren
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodesAtLocation = nodes(at: location)
        
        // Überprüfen, ob das Spiel bereits begonnen hat
        if gameStarted {
            // Spiel hat begonnen, zeige Waffenmenü bei Tap auf einen Panzer
            for node in nodesAtLocation {
                if let panzer = node as? SKSpriteNode, panzer.name?.contains("Panzer") == true {
                    // Panzer wurde angetippt -> Waffenmenü anzeigen
                    showWeaponMenu()
                    return
                }
            }
        } else {
            // Spiel hat noch nicht begonnen -> Panzer platzieren
            guard let panzer = currentPanzer, let grassTileMap = grassTileMap else {
                print("touchesEnded: Fehler - Kein Panzer, keine Kachel oder keine Berührung erkannt")
                return
            }
            
            // Prüfen, ob der Panzer bereits platziert wurde
            if panzer.isPlaced {
                print("touchesEnded: Panzer ist bereits platziert, ignoriere Berührung")
                return
            }
            
            // Panzer platzieren
            let column = grassTileMap.tileColumnIndex(fromPosition: location)
            let row = grassTileMap.tileRowIndex(fromPosition: location)
            let tileCenter = grassTileMap.centerOfTile(atColumn: column, row: row)
            panzer.position = CGPoint(x: tileCenter.x, y: tileCenter.y)
            
            panzer.physicsBody = SKPhysicsBody(rectangleOf: panzer.size, center: CGPoint(x: 0, y: panzer.size.height / 4))
            panzer.physicsBody?.isDynamic = true
            panzer.physicsBody?.categoryBitMask = CollisionCategory.panzer
            panzer.physicsBody?.collisionBitMask = CollisionCategory.grassTile
            panzer.physicsBody?.contactTestBitMask = CollisionCategory.grassTile
            panzer.physicsBody?.restitution = 0.0
            
            panzer.isPlaced = true
            
            print("touchesEnded: Panzer an Position \(panzer.position) platziert und Physik hinzugefügt")
            
            // Nächsten Panzer anzeigen oder das Spiel starten, wenn dies der letzte Panzer war
            currentPanzerIndex += 1
            if currentPanzerIndex >= selectedPanzers.count {
                startGame()
            } else {
                showNextPanzer()
            }
        }
    }
    
    // Füge eine Liste von Feind-Panzern hinzu
    
    func placeEnemyPanzers() {
        print("placeEnemyPanzers: Feind-Panzer werden platziert")
        
        guard let grassTileMap = grassTileMap else {
            print("placeEnemyPanzers: Keine Grass-Tilemap vorhanden!")
            return
        }
        
        for (_, enemyName) in enemyPanzers.enumerated() {
            var placed = false // Überprüft, ob der Panzer platziert wurde
            var attempts = 0 // Verhindert Endlosschleifen
            
            while !placed && attempts < 10 { // Maximal 10 Versuche, um eine passende Position zu finden
                attempts += 1
                let randomX = CGFloat.random(in: -self.size.width/2...self.size.width/2)
                let randomY = CGFloat.random(in: -self.size.height/2...self.size.height/2)
                let randomPosition = CGPoint(x: randomX, y: randomY)
                
                // Finde die Kachel an der zufälligen Position
                let column = grassTileMap.tileColumnIndex(fromPosition: randomPosition)
                let row = grassTileMap.tileRowIndex(fromPosition: randomPosition)
                
                // Überprüfe, ob die Kachel solide ist
                if let tileDefinition = grassTileMap.tileDefinition(atColumn: column, row: row),
                   let isSolid = tileDefinition.userData?.value(forKey: "solid") as? Bool, isSolid {
                    
                    // Solide Kachel gefunden, platziere den Feind-Panzer
                    let enemyPanzer = SKSpriteNode(imageNamed: enemyName)
                    enemyPanzer.size = CGSize(width: 70, height: 70)
                    enemyPanzer.position = grassTileMap.centerOfTile(atColumn: column, row: row) // Setze Panzer auf die Mitte der Kachel
                    
                    // Füge Physik zum Feind-Panzer hinzu
                    enemyPanzer.physicsBody = SKPhysicsBody(rectangleOf: enemyPanzer.size, center: CGPoint(x: 0, y: enemyPanzer.size.height / 4))
                    enemyPanzer.physicsBody?.isDynamic = true
                    enemyPanzer.physicsBody?.categoryBitMask = CollisionCategory.enemyPanzer // Korrekte Kategorie für Gegner
                    enemyPanzer.physicsBody?.collisionBitMask = CollisionCategory.bullet | CollisionCategory.grassTile // Kollision mit Kugeln und Terrain
                    enemyPanzer.physicsBody?.contactTestBitMask = CollisionCategory.bullet // Nur Kugeln können treffen
                    enemyPanzer.physicsBody?.restitution = 0.0
                    
                    // Setze Lebenspunkte für den Feind
                    enemyPanzer.healthPoints = 100
                    enemyPanzer.addHealthBar(isEnemy: true) // Feind-Panzer (roter Lebensbalken)
                    
                    // Setze den Namen für den Feind, um ihn in der Kollision zu erkennen
                    enemyPanzer.name = enemyName
                    
                    // Füge den Feind-Panzer der Szene hinzu
                    addChild(enemyPanzer)
                    print("placeEnemyPanzers: Feind-Panzer \(enemyName) an Position \(enemyPanzer.position) platziert")
                    
                    placed = true // Panzer wurde erfolgreich platziert
                } else {
                    print("placeEnemyPanzers: Keine solide Kachel bei Position \(randomPosition), neuer Versuch")
                }
            }
            
            if !placed {
                print("placeEnemyPanzers: Konnte keine passende Position für Feind-Panzer \(enemyName) finden")
            }
        }
    }
    // Kollisionserkennung
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        
        // Prüfe, ob die Kugel ein Ziel (Panzer) getroffen hat
        if bodyA.node == bullet || bodyB.node == bullet {
            let targetNode = (bodyA.node == bullet) ? bodyB.node : bodyA.node
            
            // Prüfe, ob das Ziel ein Gegner ist (Kategorie: enemyPanzer)
            if let targetPanzer = targetNode as? SKSpriteNode,
               targetPanzer.physicsBody?.categoryBitMask == CollisionCategory.enemyPanzer {
                // Treffer, Schaden berechnen und Explosion anzeigen
                applyDamage(to: targetPanzer)
                
                // Kugel entfernen, nachdem sie getroffen hat
                bullet?.removeFromParent()
            } else {
                // Wenn die Kugel etwas anderes trifft (nicht den Panzer), entferne sie ohne Explosion
                bullet?.removeFromParent()
            }
            
            // Beende den Zug, nachdem die Kugel entweder getroffen hat oder verschwunden ist
            endTurnAndSwitchToNextPanzerOrEnemy()
        }
    }
    
    // Funktion zur Schadensberechnung und Zerstörung eines Panzers
    func applyDamage(to targetPanzer: SKSpriteNode) {
        guard let selectedWeapon = selectedWeapon else { return }
        
        // Reduziere die Lebenspunkte des Ziels basierend auf dem Schaden der Waffe
        targetPanzer.healthPoints -= selectedWeapon.damage
        print("Schaden: \(selectedWeapon.damage), Verbleibende HP: \(targetPanzer.healthPoints)")
        
        // Explosion anzeigen, wenn der Panzer getroffen wurde
        showExplosion(at: targetPanzer.position)
        
        // Wenn die HP des Ziels 0 oder weniger ist, entferne den Panzer
        if targetPanzer.healthPoints <= 0 {
            print("Panzer zerstört!")
            targetPanzer.removeFromParent()
            
            // Entferne den Panzer aus der Liste der ausgewählten Panzer
            if let index = selectedPanzers.firstIndex(of: targetPanzer.name ?? "") {
                selectedPanzers.remove(at: index)
            }
            
            // Rundenstatus aktualisieren
            if selectedPanzers.isEmpty {
                print("Alle Panzer des Spielers wurden zerstört. Gegner gewinnt!")
                // Hier könntest du das Spiel beenden oder eine Nachricht anzeigen
            }
        }
    }
    
    // Explosion anzeigen
    func showExplosion(at position: CGPoint) {
        let explosion = SKSpriteNode(imageNamed: "tank_explosion2") // Nutze dein Bild für die Explosion
        explosion.position = position
        explosion.zPosition = 10
        explosion.size = CGSize(width: 60, height: 60)
        addChild(explosion)
        
        // Entferne die Explosion nach einer kurzen Zeit (0.5 Sekunden)
        let removeAction = SKAction.sequence([SKAction.wait(forDuration: 0.5), SKAction.removeFromParent()])
        explosion.run(removeAction)
    }
    
    // Pinch-Geste zum Zoomen
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            let scale = gesture.scale
            let newScale = lastCameraScale / scale
            
            // Begrenze das Zoomen auf einen bestimmten Bereich
            cameraNode.setScale(newScale.clamped(to: 2...7.0))
        } else if gesture.state == .ended {
            lastCameraScale = cameraNode.xScale // Speichere den aktuellen Zoom-Faktor
        }
    }
    
    // Hilfsfunktion zum Berechnen des Kamerarechtecks (optional, falls benötigt)
    func calculateCameraRect() -> CGRect {
        let cameraViewWidth = self.size.width / cameraNode.xScale
        let cameraViewHeight = self.size.height / cameraNode.yScale
        return CGRect(x: cameraNode.position.x - cameraViewWidth / 2,
                      y: cameraNode.position.y - cameraViewHeight / 2,
                      width: cameraViewWidth,
                      height: cameraViewHeight)
    }
}

// Hilfsfunktion, um Werte auf einen bestimmten Bereich zu begrenzen (Clamp)
extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

extension SKSpriteNode {
    var isPlaced: Bool {
        get {
            return userData?["isPlaced"] as? Bool ?? false
        }
        set {
            if userData == nil {
                userData = NSMutableDictionary()
            }
            userData?["isPlaced"] = newValue
        }
    }
}
extension SKSpriteNode {
    var healthPoints: Int {
        get {
            return userData?["healthPoints"] as? Int ?? 100
        }
        set {
            if userData == nil {
                userData = NSMutableDictionary()
            }
            userData?["healthPoints"] = newValue
            updateHealthBar() // Aktualisiere den Lebensbalken, wenn sich die Lebenspunkte ändern
        }
    }
    
    func addHealthBar(isEnemy: Bool) {
        let healthBarWidth: CGFloat = 50
        let healthBarHeight: CGFloat = 5
        let healthBarBackground = SKSpriteNode(color: .black, size: CGSize(width: healthBarWidth, height: healthBarHeight))
        healthBarBackground.position = CGPoint(x: 0, y: self.size.height / 2 + 10)
        healthBarBackground.zPosition = 1
        
        let healthBar = SKSpriteNode(color: isEnemy ? .red : .green, size: CGSize(width: healthBarWidth, height: healthBarHeight))
        healthBar.name = "healthBar"
        healthBar.anchorPoint = CGPoint(x: 0.0, y: 0.5) // Setze den Ursprungspunkt links
        healthBar.position = CGPoint(x: -healthBarWidth / 2, y: 0)
        healthBar.zPosition = 2
        
        healthBarBackground.addChild(healthBar)
        self.addChild(healthBarBackground)
    }
    
    // Aktualisiere nur die Breite des Lebensbalkens
    func updateHealthBar() {
        guard let healthBar = self.childNode(withName: "healthBar") as? SKSpriteNode else { return }
        
        let maxHealth: CGFloat = 100.0
        let healthPercentage = CGFloat(healthPoints) / maxHealth
        healthBar.size.width = 50 * healthPercentage // Aktualisiere nur die Breite des Balkens entsprechend den Lebenspunkten
    }
}
