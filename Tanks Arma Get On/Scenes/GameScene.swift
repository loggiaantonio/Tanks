import SpriteKit

// Definiere die Kollisionskategorien (wie gehabt)
struct CollisionCategory {
    static let grassTile: UInt32 = 0x1 << 0 // 1
    static let panzer: UInt32 = 0x1 << 1 // 2
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
    
    // Kamera Zoom und Pan Variablen
    var lastCameraScale: CGFloat = 0 // Letzter Zoom-Faktor der Kamera
    var lastPanTranslation: CGPoint = .zero // Letzter Versatz beim Panning
    
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

    func addPauseButton() {
        pauseButton = SKSpriteNode(imageNamed: "PauseIcon")
        pauseButton.size = CGSize(width: 200, height: 200) // Kleinere Größe
        pauseButton.position = CGPoint(x: self.size.width/2 + 800, y: self.size.height/2 - 30)
        pauseButton.name = "pauseButton"
        pauseButton.zPosition = 10
        addChild(pauseButton)
    }
    
    func addMovementButtons() {
        // Links button
        leftButton = SKSpriteNode(imageNamed: "leftButton")
        leftButton.size = CGSize(width: 200, height: 200) // Kleinere Größe
        leftButton.position = CGPoint(x: -self.size.width/2 - 800, y: -self.size.height/2 + 525)
        leftButton.name = "leftButton"
        leftButton.zPosition = 10
        addChild(leftButton)
        
        // Rechts button
        rightButton = SKSpriteNode(imageNamed: "rightButton")
        rightButton.size = CGSize(width: 200, height: 200) // Kleinere Größe
        rightButton.position = CGPoint(x: -self.size.width/2 - 510, y: -self.size.height/2 + 525)
        rightButton.name = "rightButton"
        rightButton.zPosition = 10
        addChild(rightButton)
        
        // Oben button
        upButton = SKSpriteNode(imageNamed: "upButton")
        upButton.size = CGSize(width: 200, height: 200) // Kleinere Größe
        upButton.position = CGPoint(x: -self.size.width/2 - 650 , y: -self.size.height/2 + 650)
        upButton.name = "upButton"
        upButton.zPosition = 10
        addChild(upButton)
        
        // Unten button
        downButton = SKSpriteNode(imageNamed: "downButton")
        downButton.size = CGSize(width: 200, height: 200) // Kleinere Größe
        downButton.position = CGPoint(x: -self.size.width/2 - 650, y: -self.size.height/2 + 400)
        downButton.name = "downButton"
        downButton.zPosition = 10
        addChild(downButton)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodesAtLocation = nodes(at: location)
        
        for node in nodesAtLocation {
            if node.name == "bombIcon" {
                showWeaponMenu()}
                    else if node.name == "leftButton" {
                        moveTankLeft()
                    } else if node.name == "rightButton" {
                        moveTankRight()
                    } else if node.name == "upButton" {
                        aimTankUp()
                    } else if node.name == "downButton" {
                        aimTankDown()
                    } else if node.name == "pauseButton" {
                        pauseGame()
                    }
                }
            }
        
        func moveTankLeft() {
            currentPanzer?.position.x -= 10
        }
        
        func moveTankRight() {
            currentPanzer?.position.x += 10
        }
        
        func aimTankUp() {
            // Implement tank aiming logic here (e.g., adjust the tank's turret angle)
        }
        
        func aimTankDown() {
            // Implement tank aiming logic here (e.g., adjust the tank's turret angle)
        }
        
    func showWeaponMenu() {
           // Trigger weapon menu here
           NotificationCenter.default.post(name: NSNotification.Name("ShowWeaponMenu"), object: nil)
           print("Weapon menu triggered")
       }
   
    
    func addPowerBar() {
        powerBar = SKSpriteNode(color: .red, size: CGSize(width: 80, height: 600))
        powerBar.position = CGPoint(x: self.size.width/2 + 800, y: -80)
        powerBar.zPosition = 10
        addChild(powerBar)
    }
        
    func addBombIcon() {
        let bombIcon = SKSpriteNode(imageNamed: "BombIcon")
        bombIcon.size = CGSize(width: 250, height: 250) // Kleinere Größe
        bombIcon.position = CGPoint(x: self.size.width/2 + 550, y: -self.size.height/2 + 500)
        bombIcon.name = "bombIcon"
        bombIcon.zPosition = 10
        addChild(bombIcon)
    }
    
    func pauseGame() {
            // Pause the game and start the timer
            self.isPaused = true
            
            decisionTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
                self?.resumeGame()
            }
            
            print("Game paused, player has 30 seconds to decide.")
        }
        
        func resumeGame() {
            self.isPaused = false
            decisionTimer?.invalidate()
            decisionTimer = nil
            
            print("Game resumed.")
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
                endTurnAndShowWeaponMenu()
            }
        }
    
        
        
        func endTurnAndShowWeaponMenu() {
            // Hier kannst du die Logik zur Beendigung eines Zugs einfügen
            // Zeige das Waffenmenü an, indem du einen SwiftUI-Binding-State triggert
            NotificationCenter.default.post(name: NSNotification.Name("ShowWeaponMenu"), object: nil)
            print("ShowWeaponMenu Notification sent")
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
            guard let grassTileMap = grassTileMap else {
                print("setupGrassTilesPhysics: Fehler - GrassTiles ist nil")
                return
            }
            
            // Iteriere über alle Kacheln in der Grass-Tilemap
            for row in 0..<grassTileMap.numberOfRows {
                for column in 0..<grassTileMap.numberOfColumns {
                    if let tileDefinition = grassTileMap.tileDefinition(atColumn: column, row: row) {
                        // Prüfe, ob die Kachel als "solid" markiert ist (falls benötigt)
                        if let isSolid = tileDefinition.userData?.value(forKey: "solid") as? Bool, isSolid {
                            let tileSize = grassTileMap.tileSize
                            let tilePosition = grassTileMap.centerOfTile(atColumn: column, row: row)
                            
                            // Erstelle einen Physics-Körper, der genau der Form der Kachel entspricht
                            let path = CGMutablePath()
                            path.addRect(CGRect(x: -tileSize.width / 2, y: -tileSize.height / 2, width: tileSize.width, height: tileSize.height))
                            
                            let physicsBody = SKPhysicsBody(polygonFrom: path)
                            physicsBody.isDynamic = false // Die Kachel ist statisch
                            physicsBody.categoryBitMask = CollisionCategory.grassTile
                            physicsBody.collisionBitMask = CollisionCategory.panzer // Passe an deine Bedürfnisse an
                            physicsBody.contactTestBitMask = CollisionCategory.panzer
                            
                            // Erstelle einen ShapeNode, um den Physics-Körper darzustellen (optional)
                            let tileNode = SKShapeNode(path: path)
                            tileNode.position = tilePosition
                            tileNode.zPosition = -0.1 // Leicht unter der visuellen Kachel
                            tileNode.fillColor = .clear // Mache den ShapeNode unsichtbar
                            
                            tileNode.physicsBody = physicsBody
                            
                            // Füge den Tile-Node zur Szene hinzu (optional, nur für Debugging)
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
            } else {
                // Wenn alle Panzer platziert sind, beginne das Spiel
                startGame()
            }
        }
        
        
        // Berühre den Bildschirm, um den Panzer zu platzieren
        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first, let panzer = currentPanzer, let grassTileMap = grassTileMap else {
                print("touchesEnded: Fehler - Kein Panzer, keine Kachel oder keine Berührung erkannt")
                return
            }
            
            // Prüfe, ob der Panzer bereits platziert wurde
            if panzer.isPlaced {
                print("touchesEnded: Panzer ist bereits platziert, ignoriere Berührung")
                return
            }
            
            // Hole die Position der Berührung
            let location = touch.location(in: self)
            print("touchesEnded: Berührung bei Position \(location) erkannt")
            
            // Finde die Kachel, auf der der Panzer platziert werden soll
            let column = grassTileMap.tileColumnIndex(fromPosition: location)
            let row = grassTileMap.tileRowIndex(fromPosition: location)
            let tileCenter = grassTileMap.centerOfTile(atColumn: column, row: row)
            
            // Setze den Panzer an die Kachel-Position
            let adjustPosition = CGPoint(x: tileCenter.x, y: tileCenter.y)
            panzer.position = adjustPosition
            
            // Füge Physik zum Panzer hinzu, damit er interagieren kann
            panzer.physicsBody = SKPhysicsBody(rectangleOf: panzer.size, center: CGPoint(x: 0, y: panzer.size.height / 4))
            panzer.physicsBody?.isDynamic = true // Panzer reagiert auf Physik
            panzer.physicsBody?.categoryBitMask = CollisionCategory.panzer
            panzer.physicsBody?.collisionBitMask = CollisionCategory.grassTile
            panzer.physicsBody?.contactTestBitMask = CollisionCategory.grassTile
            panzer.physicsBody?.restitution = 0.0 // Kein Abprallen
            
            // Markiere den Panzer als platziert
            panzer.isPlaced = true
            
            print("touchesEnded: Panzer an Position \(panzer.position) platziert und Physik hinzugefügt")
            
            // Nächsten Panzer anzeigen oder das Spiel starten, wenn dies der letzte Panzer war
            currentPanzerIndex += 1
            showNextPanzer()
        }
        
        // Füge eine Liste von Feind-Panzern hinzu
        let enemyPanzers = ["Enemy1", "Enemy2", "Enemy3", "Enemy4"]
        
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
                        enemyPanzer.physicsBody?.categoryBitMask = CollisionCategory.panzer
                        enemyPanzer.physicsBody?.collisionBitMask = CollisionCategory.grassTile
                        enemyPanzer.physicsBody?.contactTestBitMask = CollisionCategory.grassTile
                        enemyPanzer.physicsBody?.restitution = 0.0
                        
                        // Setze Lebenspunkte für den Feind
                        enemyPanzer.healthPoints = 100
                        enemyPanzer.addHealthBar(isEnemy: true) // Feind-Panzer (roter Lebensbalken)
                        
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
        
        // Methode zur Überwachung von Kollisionen
        func didBegin(_ contact: SKPhysicsContact) {
            let bodyA = contact.bodyA
            let bodyB = contact.bodyB
            
            if bodyA.categoryBitMask == CollisionCategory.grassTile && bodyB.categoryBitMask == CollisionCategory.panzer {
                print("Panzer kollidiert mit GrassTiles")
            } else if bodyB.categoryBitMask == CollisionCategory.grassTile && bodyA.categoryBitMask == CollisionCategory.panzer {
                print("Panzer kollidiert mit GrassTiles")
            }
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
        
        func updateHealthBar() {
            guard let healthBar = self.childNode(withName: "healthBar") as? SKSpriteNode else { return }
            let maxHealth: CGFloat = 100.0
            let healthPercentage = CGFloat(healthPoints) / maxHealth
            healthBar.size.width = 50 * healthPercentage // Aktualisiere die Breite des Balkens entsprechend den Lebenspunkten
        }
        
        
    }
