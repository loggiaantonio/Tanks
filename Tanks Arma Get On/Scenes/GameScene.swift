import SpriteKit





// Definiere die Kollisionskategorien
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
            
            cameraNode.setScale(6.5)
        } else {
            print("Fehler: Kamera nicht gefunden!")
        }
        
        // Füge nur die Zoom-Geste hinzu
        view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:))))
        
        // Setze das contactDelegate, um Kollisionen zu überwachen
        physicsWorld.contactDelegate = self
        
        // Hier die gesamte Knoten-Hierarchie drucken
        printNodeHierarchy(node: self)
        
        // Szene aus der GameScene.sks laden
        loadTileMaps()
        
        // Zeige den ersten Panzer an
        showNextPanzer()
        
        // Automatische Platzierung der Feind-Panzer
        placeEnemyPanzers()
        
        // Zeigt die Tiles (Kacheln) in der Map an!
        view.showsPhysics = true
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
    }    // Zeige den nächsten Panzer, falls es noch Panzer gibt
    func showNextPanzer() {
        if currentPanzerIndex < selectedPanzers.count {
            let panzerName = selectedPanzers[currentPanzerIndex]
            print("showNextPanzer: Zeige Panzer \(panzerName) an")
            
            let panzer = SKSpriteNode(imageNamed: panzerName)
            //panzer.isPlaced = false
            
            // Setze die genaue Größe der Panzer (z.B. 50x50 Pixel)
            panzer.size = CGSize(width: 70, height: 70) // Panzerskalierung auf eine kleinere Größe
            panzer.position = CGPoint(x: 0, y: 0) // Startposition in der Mitte
            panzer.zPosition = 0 // Über der Map
            
            // Setze Lebenspunkte für den eigenen Panzer
                   panzer.healthPoints = 150
                   panzer.addHealthBar(isEnemy: false) // Spieler-Panzer (Güner Lebensbalken)
            
            // Aktuellen Panzer speichern
            currentPanzer = panzer
            
            // Füge den Panzer der Szene hinzu
            addChild(panzer)
            print("showNextPanzer: Panzer wurde hinzugefügt")
        } else {
            print("showNextPanzer: Keine weiteren Panzer zu platzieren")
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
        
        // Nächsten Panzer anzeigen, wenn einer verfügbar ist
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
        
        for (index, enemyName) in enemyPanzers.enumerated() {
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
    
    // Hilfsfunktion zum Drucken der Knoten-Hierarchie
    func printNodeHierarchy(node: SKNode, indent: String = "") {
        print("\(indent)\(node.name ?? "Unnamed Node") -> \(node)")
        for child in node.children {
            printNodeHierarchy(node: child, indent: indent + "  ")
        }
    }
    
    // Pinch-Geste zum Zoomen
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
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view)

        if gesture.state == .changed {
            // Konvertiere die Translation von View-Koordinaten in Szenen-Koordinaten
            let translationInScene = CGPoint(x: translation.x, y: -translation.y) // Negatives Y, um die richtige Richtung zu erhalten
            let sceneTranslation = convert(translationInScene, from: gesture.view!)
            
            // Berechne neue Position der Kamera
            let newCameraPosition = CGPoint(
                x: cameraNode.position.x + sceneTranslation.x,
                y: cameraNode.position.y + sceneTranslation.y
            )
            
            // Begrenze die Position der Kamera, falls notwendig
            if let grassTileMap = grassTileMap {
                let cameraRect = calculateCameraRect()
                let mapWidth = grassTileMap.mapSize.width
                let mapHeight = grassTileMap.mapSize.height

                // Berechne die minimalen und maximalen X- und Y-Werte für die Kamera
                let minX = cameraRect.width / 2
                let maxX = mapWidth - cameraRect.width / 2
                let minY = cameraRect.height / 2
                let maxY = mapHeight - cameraRect.height / 2

                // Begrenze die neue Position der Kamera
                let clampedX = newCameraPosition.x.clamped(to: minX...maxX)
                let clampedY = newCameraPosition.y.clamped(to: minY...maxY)

                // Setze die neue, begrenzte Position der Kamera
                cameraNode.position = CGPoint(x: clampedX, y: clampedY)
            } else {
                // Falls keine TileMap gefunden wurde, bewege die Kamera ohne Begrenzung
                cameraNode.position = newCameraPosition
            }

            // Setze die Translation zurück, um Überschneidungen zu vermeiden
            gesture.setTranslation(.zero, in: gesture.view)
        }

        // Nach Abschluss der Geste die letzte Position speichern
        if gesture.state == .ended {
            lastPanTranslation = CGPoint.zero
        }
    }
    // Hilfsfunktion zum Berechnen des Kamerarechtecks (optional, falls benötigt)
    func calculateCameraRect() -> CGRect {
        let cameraViewWidth = self.size.width / cameraNode.xScale
        let cameraViewHeight = self.size.height / cameraNode.yScale
        return CGRect(x: cameraNode.position.x - cameraViewWidth,
                      y: cameraNode.position.y - cameraViewHeight,
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
            userData = NSMutableDictionary()
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
