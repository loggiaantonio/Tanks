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
    var lastCameraScale: CGFloat = 1.0 // Letzter Zoom-Faktor der Kamera
    var lastPanTranslation: CGPoint = .zero // Letzter Versatz beim Panning

    override func didMove(to view: SKView) {
        print("didMove: Szene wurde geladen")

        // Verwende die Kamera aus der Szene, falls vorhanden
        if let cameraFromScene = childNode(withName: "camera") as? SKCameraNode {
            cameraNode = cameraFromScene
            self.camera = cameraNode
            
            cameraNode.setScale(6.5)
        } else {
            print("Fehler: Kamera nicht gefunden!")
        }

        // Füge die Gesten für das Zoomen und Schwenken hinzu
        view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:))))
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))

        // Setze das contactDelegate, um Kollisionen zu überwachen
        physicsWorld.contactDelegate = self

        // Hier die gesamte Knoten-Hierarchie drucken
        printNodeHierarchy(node: self)

        // Szene aus der GameScene.sks laden
        loadTileMaps()

        // Zeige den ersten Panzer an
        showNextPanzer()
    }

    // Lade die Tilemaps, ohne sie erneut zur Szene hinzuzufügen
    func loadTileMaps() {
        print("loadTileMaps: Versuche, Tilemaps zu laden")

        // Versuche, die FirstTiles zu laden
               if let firstMap = childNode(withName: "FirstTiles") as? SKTileMapNode {
                   print("loadTileMaps: FirstTiles gefunden")
                   firstTileMap = firstMap
                   firstTileMap?.zPosition = -2 // Ganz unten, unter allen anderen
               } else {
                   print("loadTileMaps: Fehler - FirstTiles nicht gefunden")
               }
        
        // Versuche, die BackgroundTiles zu laden
        if let backgroundMap = childNode(withName: "BackgroundTiles") as? SKTileMapNode {
            print("loadTileMaps: BackgroundTiles gefunden")
            backgroundTileMap = backgroundMap
            backgroundTileMap?.zPosition = -1 // Hinter allen anderen Elementen
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
        guard let tileMap = grassTileMap else {
            print("setupGrassTilesPhysics: Fehler - GrassTiles ist nil")
            return
        }

        // Gehe durch alle Tiles in der Grass-Tilemap
        for row in 0..<tileMap.numberOfRows {
            for column in 0..<tileMap.numberOfColumns {
                if let tileDefinition = tileMap.tileDefinition(atColumn: column, row: row) {
                    // Prüfen, ob das Tile den Bool-Wert "solid" hat
                    if tileDefinition.userData?.value(forKey: "solid") is Bool {
                        print("setupGrassTilesPhysics: Kachel mit Kollision gefunden bei (\(row), \(column))")

                        // Bestimme die Position und Größe des Tiles
                        let tileSize = tileMap.tileSize
                        let tilePosition = tileMap.centerOfTile(atColumn: column, row: row)

                        // Erstelle ein unsichtbares physisches Objekt für das Tile
                        let tileNode = SKNode()
                        tileNode.position = tilePosition
                        
                        let path = CGMutablePath()
                        path.addLines(between: [
                            CGPoint(x: -tileSize.width / 2, y: -tileSize.height / 2),
                            CGPoint(x: tileSize.width / 2, y: -tileSize.height / 2),
                            CGPoint(x: tileSize.width / 2, y: tileSize.height / 2),
                            CGPoint(x: -tileSize.width / 2, y: tileSize.height / 2),
                        ])
                        path.closeSubpath()
                        
                        //Erstelle das Phisik-Poligon
                        tileNode.physicsBody = SKPhysicsBody(polygonFrom: path)
                        tileNode.physicsBody?.isDynamic = false // Die Kachel bewegt sich nicht
                        tileNode.physicsBody?.categoryBitMask = CollisionCategory.grassTile // Kategorie für Kollision
                        tileNode.physicsBody?.collisionBitMask = CollisionCategory.panzer // Kollision mit Panzern

                       // Füge das Tile-Node der Szene hinzu
                        addChild(tileNode)
                    }
                }
            }
        }
        print("setupGrassTilesPhysics: Alle Kollisionen hinzugefügt")
    }

    // Zeige den nächsten Panzer, falls es noch Panzer gibt
    func showNextPanzer() {
        if currentPanzerIndex < selectedPanzers.count {
            let panzerName = selectedPanzers[currentPanzerIndex]
            print("showNextPanzer: Zeige Panzer \(panzerName) an")

            let panzer = SKSpriteNode(imageNamed: panzerName)

            // Setze die genaue Größe der Panzer (z.B. 50x50 Pixel)
            panzer.size = CGSize(width: 150, height: 150) // Panzerskalierung auf eine kleinere Größe
            panzer.position = CGPoint(x: size.width / 2, y: size.height / 2) // Startposition in der Mitte
            panzer.zPosition = 1 // Über der Map

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

        // Hole die Position der Berührung
        let location = touch.location(in: self)
        print("touchesEnded: Berührung bei Position \(location) erkannt")

        // Finde die Kachel, auf der der Panzer platziert werden soll
        let column = grassTileMap.tileColumnIndex(fromPosition: location)
        let row = grassTileMap.tileRowIndex(fromPosition: location)
        let tileCenter = grassTileMap.centerOfTile(atColumn: column, row: row)

        // Bewege den Panzer zur Mitte der gefundenen Kachel
        panzer.position = tileCenter

        // Füge Physik zum Panzer hinzu, damit er interagieren kann
        panzer.physicsBody = SKPhysicsBody(rectangleOf: panzer.size)
        panzer.physicsBody?.isDynamic = true // Panzer reagiert auf Physik
        panzer.physicsBody?.categoryBitMask = CollisionCategory.panzer
        panzer.physicsBody?.collisionBitMask = CollisionCategory.grassTile
        panzer.physicsBody?.contactTestBitMask = CollisionCategory.grassTile
        panzer.physicsBody?.restitution = 0.0 // Kein Abprallen

        print("touchesEnded: Panzer an Position \(panzer.position) platziert und Physik hinzugefügt")

        // Nächsten Panzer anzeigen, wenn einer verfügbar ist
        currentPanzerIndex += 1
        showNextPanzer()
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
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            let scale = gesture.scale
            let newScale = lastCameraScale / scale

            // Begrenze das Zoomen auf einen bestimmten Bereich
            cameraNode.setScale(newScale.clamped(to: 2...10.0))
        } else if gesture.state == .ended {
            lastCameraScale = cameraNode.xScale // Speichere den aktuellen Zoom-Faktor
        }
    }

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view)

        if gesture.state == .changed {
            let moveX = -translation.x
            let moveY = translation.y

            // Berechne neue Position der Kamera
            let newCameraPosition = CGPoint(
                x: cameraNode.position.x + moveX,
                y: cameraNode.position.y + moveY
            )

            // Begrenze die Position der Kamera auf den Bereich der grassTileMap
            if let grassTileMap = grassTileMap {
                let cameraRect = calculateCameraRect()

                // Holen der Kachelkartegröße
                let mapWidth = grassTileMap.mapSize.width
                let mapHeight = grassTileMap.mapSize.height

                // Berechne die minimalen und maximalen X- und Y-Werte, die die Kamera haben darf
                let minX = cameraRect.width / 2
                let maxX = mapWidth - cameraRect.width / 2
                let minY = cameraRect.height / 2
                let maxY = mapHeight - cameraRect.height / 2

                // Begrenze die neue Position auf die berechneten Minimal- und Maximalwerte
                let clampedX = newCameraPosition.x.clamped(to: minX...maxX)
                let clampedY = newCameraPosition.y.clamped(to: minY...maxY)

                // Setze die neue Position der Kamera
                cameraNode.position = CGPoint(x: clampedX, y: clampedY)
            } else {
                // Falls keine TileMap gefunden wurde, bewege die Kamera ohne Begrenzung
                cameraNode.position = newCameraPosition
            }
        }

        // Nach Abschluss der Geste die letzte Position speichern
        if gesture.state == .ended {
            lastPanTranslation = CGPoint.zero
        }
    }
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
