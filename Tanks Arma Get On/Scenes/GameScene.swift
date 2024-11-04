import SpriteKit
import SwiftUI



// Definiere die Kollisionskategorien
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
    
    var selectedPanzers: [Panzer] = [] {
        didSet {
            print("selectedPanzers updated. Count: \(selectedPanzers.count)")
            gameManager?.checkGameEnd()
        }
    }
    var currentPanzerIndex = 0 // Index des aktuell zu platzierenden Panzers
    var currentPanzer: Panzer? // Der Panzer, der gerade platziert wird
    
    var gameStarted = false // Spielstatus: ob das Spiel gestartet hat
    
    var leftButton: SKSpriteNode!
    var rightButton: SKSpriteNode!
    var upButton: SKSpriteNode!
    var downButton: SKSpriteNode!
    
    var isMovingLeft = false
    var isMovingRight = false
    
    var powerBar: SKSpriteNode!
    
    var backButton: SKSpriteNode!
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
    var isAiming = false // Neue Eigenschaft zum Überprüfen, ob gezielt wird
    
    
    var bullet: SKSpriteNode? // Das Projektil (die Kugel)
    
    var enemyPanzers: [String] = ["Enemy1", "Enemy2", "Enemy3", "Enemy4"] {
        didSet {
            print("enemyPanzers updated. Count: \(enemyPanzers.count)")
            gameManager?.checkGameEnd()
        }
    }
    var currentTurnIndex = 0 // Der Index, der zwischen Spieler- und Gegnerpanzern wechselt
    
    var hasFired = false // Variable zum Überprüfen, ob bereits geschossen wurde
    
    var currentWeapon: Weapon?
    
    var gameManager: GameManager!

    
    var enemyAIControllers: [EnemyAI] = [] // Liste der Gegner-KI-Instanzen
    
    var isPlacingPhase = true // Platzierungsphase aktivieren
    
    var playerPanzerLabel: SKLabelNode!
    var enemyPanzerLabel: SKLabelNode!
    

    // Sound actions
    var moveSound: SKAction!
    var shotSound: SKAction!
    var bulletHitSound: SKAction!
    var explosionSound: SKAction!
    
    func setCurrentWeapon(_ weapon: Weapon) {
        self.currentWeapon = weapon
        print("Waffe \(weapon.name) ausgewählt und in GameScene gespeichert.")
    }
    
    func moveTankLeft() {
        isAiming = false // Beende das Zielen beim Bewegen
        aimLine?.isHidden = true // Verstecke die Ziellinie
        currentPanzer?.position.x -= 2
        if currentPanzer?.xScale != -1 {
            currentPanzer?.xScale = -1
        }
        currentPanzer?.run(moveSound) // Play move sound
    }
    
    func moveTankRight() {
        isAiming = false // Beende das Zielen beim Bewegen
        aimLine?.isHidden = true // Verstecke die Ziellinie
        currentPanzer?.position.x += 2
        if currentPanzer?.xScale != 1 {
            currentPanzer?.xScale = 1
        }
        currentPanzer?.run(moveSound) // Play move sound
    }
    
    
    
    func endTurnAndManageNextAction() {
        // Setze `hasFired` für alle Spielerpanzer zurück, damit sie im nächsten Zug feuern können
        for panzer in selectedPanzers {
            panzer.hasFired = false
        }
        
        hasFired = false  // Zum Rücksetzen für den aktiven Panzer
        
        // Logik zum Wechseln des Zuges
        currentTurnIndex += 1
        
        if currentTurnIndex >= (selectedPanzers.count + enemyPanzers.count) {
            currentTurnIndex = 0
        }
        
        // Entscheide, ob Spieler oder Gegner an der Reihe ist
        if currentTurnIndex < selectedPanzers.count {
            // Spielerzug
            currentPanzer = selectedPanzers[currentTurnIndex]
            showArrowAboveCurrentPanzer()
        } else {
            // Gegnerzug
            let enemyIndex = currentTurnIndex - selectedPanzers.count
            if enemyIndex < enemyPanzers.count {
                if let enemyPanzerNode = childNode(withName: enemyPanzers[enemyIndex]) as? Panzer {
                    currentPanzer = enemyPanzerNode
                    let enemyAI = EnemyAI(enemyPanzer: enemyPanzerNode, scene: self)
                    enemyAI.performAction {
                        self.endTurnAndManageNextAction()
                    }
                }
            }
        }
    }
    
    func showEndScreen(winner: String) {
        let endScreenImage = SKSpriteNode(imageNamed: winner == "Player" ? "YouWin" : "YouLose")
        endScreenImage.size = CGSize(width: self.size.width / 3, height: self.size.height / 3)
        endScreenImage.position = CGPoint(x: 0, y: 0) // In der Mitte des Bildschirms
        endScreenImage.zPosition = 20 // Über allen anderen Elementen
        addChild(endScreenImage)
    }
    
    
    
    
    func showReloadPrompt() {
        // Erstelle eine Alert-Controller-Instanz
        let alertController = UIAlertController(title: "Reload", message: "Do you want to restart the game? Yes or No?", preferredStyle: .alert)
        
        // "Yes"-Aktion für den Neustart
        let yesAction = UIAlertAction(title: "Yes", style: .default) { _ in
            self.resetGame()
        }
        
        // "No"-Aktion, um das Spiel fortzusetzen
        let noAction = UIAlertAction(title: "No", style: .cancel) { _ in
            // Hier kannst du das Spiel ohne Änderungen fortsetzen lassen
            print("Continuing the game")
        }
        
        // Aktionen zum Alert-Controller hinzufügen
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        
        // Präsentiere den Alert-Controller
        if let viewController = self.view?.window?.rootViewController {
            viewController.present(alertController, animated: true, completion: nil)
        }
    }
    
    func resetGame() {
        // Setze den Spielstatus zurück
        self.removeAllChildren()
        self.removeAllActions()
        
        // Falls nötig, setze alle relevanten Variablen und das Spiellayout zurück
        gameStarted = false
        currentTurnIndex = 0
        hasFired = false
        currentPanzer = nil
        currentPanzerIndex = 0
        selectedPanzers.removeAll()
        enemyPanzers.removeAll()
        enemyAIControllers.removeAll()
        
        // Rufe die Setup-Methoden erneut auf, um das Spiel neu zu laden
        loadTileMaps()
        showNextPanzer()
        placeEnemyPanzers()
        
        print("Das Spiel wurde neu gestartet")
    }
    
    
    
    func updateAimLine() {
        guard isAiming, let currentPanzer = currentPanzer else {
            aimLine?.isHidden = true // Verstecke die Ziellinie, wenn nicht gezielt wird
            return
        }

        aimLine?.isHidden = false // Zeige die Ziellinie an, wenn gezielt wird

        if aimLine == nil {
            aimLine = SKShapeNode()
            aimLine?.strokeColor = .red
            aimLine?.lineWidth = 2
            aimLine?.zPosition = 2
            addChild(aimLine!)
        }

        // Berechne die Länge der Ziellinie basierend auf der Powerbar
        let powerFactor = powerBar.size.height / 100.0
        let aimLength = maxPower * powerFactor

        // Passe den Zielwinkel an die Blickrichtung des Panzers an
        let adjustedAngle = currentPanzer.xScale == -1 ? .pi - aimAngle : aimAngle

        // Berechne das Ende des Zielstrahls basierend auf dem angepassten Winkel
        let dx = aimLength * cos(adjustedAngle)
        let dy = aimLength * sin(adjustedAngle)

        // Startpunkt des Strahls (Position des aktuellen Panzers)
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
        isAiming = true // Aktiviert das Zielen
        aimAngle += 0.1 // Erhöhe den Winkel

        // Begrenze den Winkel auf maximal 140 Grad (etwa 2.44 Rad)
        if aimAngle > 2.44 { aimAngle = 2.44 }
        
        print("aimTankUp: Neuer aimAngle ist \(aimAngle)")
        updateAimLine()
    }

    func aimTankDown() {
        isAiming = true // Aktiviert das Zielen
        aimAngle -= 0.1 // Verringere den Winkel

        // Begrenze den Winkel auf minimal -140 Grad (etwa -2.44 Rad)
        if aimAngle < -2.44 { aimAngle = -2.44 }
        
        print("aimTankDown: Neuer aimAngle ist \(aimAngle)")
        updateAimLine()
    }
    
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        print("didMove: Szene wurde geladen")
        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        
        
        // Fügt den Pan-Gesten-Recognizer hinzu
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(panGesture)
        
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

        // Labels zur Anzeige der Anzahl der Panzer hinzufügen
        setupPanzerLabels()

        
        // Szene aus der GameScene.sks laden
        loadTileMaps()
        
        // Diese Zeile fügt die DeathTiles-Physik hinzu
        setupDeathTilesPhysics()

        
        // Zeige den ersten Panzer an
        showNextPanzer()
        
        // Automatische Platzierung der Feind-Panzer
        placeEnemyPanzers()
        
        // Zeigt die Tiles (Kacheln) in der Map an!
        view.showsPhysics = false
        
        // fügt die Directionen
        addMovementButtons()
        
        // Add power bar
        addPowerBar()
        
        // Add bomb icon
        addBombIcon()
        
        addBackButton()
        
        // Load sounds
        moveSound = SKAction.playSoundFileNamed("TankMove.mp3", waitForCompletion: false)
        shotSound = SKAction.playSoundFileNamed("shot.mp3", waitForCompletion: false)
        bulletHitSound = SKAction.playSoundFileNamed("bulletHit.wav", waitForCompletion: false)
        explosionSound = SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false)
        
        // Initialisiere den GameManager und übergebe die Szene
        gameManager = GameManager(scene: self)
        
        // Starte das Spiel über den GameManager
        gameManager?.startGame()
        
    }
    
    // Pan-Geste zum Verschieben der Kamera
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view)
        
        // Berechne die neue Kameraposition basierend auf der Pan-Translation
        let newX = cameraNode.position.x - translation.x / cameraNode.xScale
        let newY = cameraNode.position.y + translation.y / cameraNode.yScale
        cameraNode.position = CGPoint(x: newX, y: newY)
        
        // Setze die Translation zurück, damit die Bewegung kontinuierlich ist
        gesture.setTranslation(.zero, in: gesture.view)
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
    
    func setupPanzerLabels() {
        guard let cameraNode = camera else { return }

        playerPanzerLabel = SKLabelNode(text: "\(selectedPanzers.count)")
        playerPanzerLabel.fontSize = 24
        playerPanzerLabel.fontName = "Arial-BoldMT"
        playerPanzerLabel.fontColor = .green
        playerPanzerLabel.position = CGPoint(x: -self.size.width / 2 + 50, y: self.size.height / 2 - 50)
        playerPanzerLabel.zPosition = 10
        cameraNode.addChild(playerPanzerLabel)
        
        enemyPanzerLabel = SKLabelNode(text: "\(enemyPanzers.count)")
        enemyPanzerLabel.fontSize = 24
        enemyPanzerLabel.fontName = "Arial-BoldMT"
        enemyPanzerLabel.fontColor = .red
        enemyPanzerLabel.position = CGPoint(x: -self.size.width / 2 + 100, y: self.size.height / 2 - 50)
        enemyPanzerLabel.zPosition = 10
        cameraNode.addChild(enemyPanzerLabel)
    }
    
    func updatePanzerCountLabels() {
        playerPanzerLabel.text = "\(selectedPanzers.count)"
        enemyPanzerLabel.text = "\(enemyPanzers.count)"
    }
    
    func panzerDestroyed(isPlayerPanzer: Bool) {
        if isPlayerPanzer {
            if let index = selectedPanzers.firstIndex(where: { $0.healthPoints <= 0 }) {
                selectedPanzers.remove(at: index)
            }
        } else {
            if let index = enemyPanzers.firstIndex(where: {
                guard let enemyPanzerNode = childNode(withName: $0) as? Panzer else { return false }
                return enemyPanzerNode.healthPoints <= 0
            }) {
                enemyPanzers.remove(at: index)
            }
        }
        updatePanzerCountLabels() // Labels aktualisieren
        
        // Prüfen, ob das Spiel beendet ist
        gameManager?.checkGameEnd()
    }
   
    
    func addBackButton() {
        
        guard let view = self.view else { return }
        
        let screenWidth = view.bounds.width
        let screenHeight = view.bounds.height
        
        backButton = SKSpriteNode(imageNamed: "BackButton")
        backButton.size = CGSize(width: 75, height: 75) // Kleinere Größe
        backButton.position = CGPoint(x: -screenWidth/2 + 300, y: -screenHeight/2 + 130)
        backButton.name = "backButton"
        backButton.zPosition = 10
        cameraNode.addChild(backButton)
    }
    
    func addMovementButtons() {
        // Die Bildschirmgröße bestimmen, basierend auf der Größe des view
        guard let view = self.view else { return }
        
        let screenWidth = view.bounds.width
        let screenHeight = view.bounds.height
        
        // Links button
        leftButton = SKSpriteNode(imageNamed: "leftButton")
        leftButton.size = CGSize(width: 100, height: 100)
        leftButton.position = CGPoint(x: -screenWidth/2 - 355, y: -screenHeight/2 - 88) // Unten links
        leftButton.name = "leftButton"
        leftButton.zPosition = 10
        cameraNode.addChild(leftButton)
        
        // Rechts button
        rightButton = SKSpriteNode(imageNamed: "rightButton")
        rightButton.size = CGSize(width: 100, height: 100)
        rightButton.position = CGPoint(x: -screenWidth/2 - 240, y: -screenHeight/2 - 86) // Unten links, aber weiter rechts
        rightButton.name = "rightButton"
        rightButton.zPosition = 10
        cameraNode.addChild(rightButton)
        
        // Oben button
        upButton = SKSpriteNode(imageNamed: "upButton")
        upButton.size = CGSize(width: 100, height: 100)
        upButton.position = CGPoint(x: -screenWidth/2 - 300, y: -screenHeight/2 - 30) // Über den Buttons links/rechts
        upButton.name = "upButton"
        upButton.zPosition = 10
        cameraNode.addChild(upButton)
        
        // Unten button
        downButton = SKSpriteNode(imageNamed: "downButton")
        downButton.size = CGSize(width: 100, height: 100)
        downButton.position = CGPoint(x: -screenWidth/2 - 295, y: -screenHeight/2 - 145) // Unter dem Up-Button
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
        let touchedNode = atPoint(location)
        
        
        // 2. Überprüfen, ob der Back-Button angetippt wurde
        if touchedNode.name == "backButton" {
            // Rückkehr zur vorherigen Ansicht
            NotificationCenter.default.post(name: NSNotification.Name("DismissGameScene"), object: nil)
        }
        // Prüfen, welcher Knoten berührt wurde
        for node in nodesAtLocation {
            if node.name == "leftButton" {
                isMovingLeft = true
            } else if node.name == "rightButton" {
                isMovingRight = true
            } else if node.name == "upButton" {
                aimTankUp()
            } else if node.name == "downButton" {
                aimTankDown()
            } else if node.name == "shootButton" {
                shoot()
            }
        }
    }
    
    func shoot() {
        isAiming = false // Beende das Zielen nach dem Schießen
        aimLine?.isHidden = true // Verstecke die Ziellinie
        // Überprüfen, ob bereits geschossen wurde, um Mehrfachauslösung zu verhindern
        guard hasFired == false else {
            print("Es wurde bereits geschossen! Warte auf die nächste Runde.")
            return
        }
        
        // Überprüfen, ob ein aktueller Panzer und eine Waffe vorhanden sind
        guard let currentPanzer = currentPanzer, let currentWeapon = currentWeapon else {
            print("Kein Panzer oder keine Waffe ausgewählt.")
            return
        }
        
        // Setze `hasFired` auf true, um zu verhindern, dass mehrmals geschossen wird
        hasFired = true
        
        // Panzer feuert die ausgewählte Waffe ab
        print("Schießen mit Waffe: \(currentWeapon.name)")
        currentPanzer.shootWeapon(named: currentWeapon.name, angle: aimAngle)

        // Schuss abgeschlossen, Zugwechsel einleiten
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // 1 Sekunde Verzögerung für die Animation
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
        
        
        // Wechsel zum nächsten Panzer oder führe Aktionen für den aktuellen Panzer aus
        endTurnAndManageNextAction()
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
        isPlacingPhase = false // Platzierungsphase beenden
        print("Das Spiel hat begonnen")
        
    }
    
    // Methode zum Respawnen eines zerstörten Panzers in der Platzierungsphase
    func respawnPanzer(_ panzer: Panzer) {
        guard isPlacingPhase else { return }

        print("Respawn für \(panzer.name ?? "Panzer") während der Platzierungsphase")

        var placed = false
        var attempts = 0
        while !placed && attempts < 20 { // Erhöhe die Versuche, um sicherzustellen, dass eine passende Position gefunden wird
            attempts += 1
            let randomX = CGFloat.random(in: -self.size.width/2...self.size.width/2)
            let randomY = CGFloat.random(in: -self.size.height/2...self.size.height/2)
            let randomPosition = CGPoint(x: randomX, y: randomY)

            if let grassTileMap = grassTileMap {
                let column = grassTileMap.tileColumnIndex(fromPosition: randomPosition)
                let row = grassTileMap.tileRowIndex(fromPosition: randomPosition)

                if let tileDefinition = grassTileMap.tileDefinition(atColumn: column, row: row),
                   let isSolid = tileDefinition.userData?.value(forKey: "solid") as? Bool, isSolid,
                   tileDefinition.userData?.value(forKey: "name") as? String != "death" { // Vermeide DeathTiles

                    panzer.position = grassTileMap.centerOfTile(atColumn: column, row: row)
                    addChild(panzer)
                    placed = true
                    print("\(panzer.name ?? "Panzer") wurde neu platziert bei \(panzer.position)")
                }
            }
        }

        if !placed {
            print("Konnte keine passende Position für \(panzer.name ?? "Panzer") finden")
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
        guard let grassTileMap = grassTileMap else {
            print("setupGrassTilesPhysics: Fehler - GrassTiles ist nil")
            return
        }
        
        for row in 0..<grassTileMap.numberOfRows {
            for column in 0..<grassTileMap.numberOfColumns {
                if let tileDefinition = grassTileMap.tileDefinition(atColumn: column, row: row),
                   let isSolid = tileDefinition.userData?.value(forKey: "solid") as? Bool, isSolid {
                    
                    let tileSize = grassTileMap.tileSize
                    let tilePosition = grassTileMap.centerOfTile(atColumn: column, row: row)
                    
                    let path = CGMutablePath()
                    path.addRect(CGRect(x: -tileSize.width / 2, y: -tileSize.height / 2, width: tileSize.width, height: tileSize.height))
                    
                    let physicsBody = SKPhysicsBody(polygonFrom: path)
                    physicsBody.isDynamic = false
                    physicsBody.categoryBitMask = CollisionCategory.grassTile
                    physicsBody.contactTestBitMask = CollisionCategory.bullet
                    
                    let tileNode = SKShapeNode(path: path)
                    tileNode.position = tilePosition
                    tileNode.zPosition = -0.1
                    tileNode.fillColor = .clear
                    tileNode.strokeColor = .clear
                    tileNode.physicsBody = physicsBody
                    
                    addChild(tileNode)
                }
            }
        }
    }
    
    func setupDeathTilesPhysics() {
        guard let deathTileMap = childNode(withName: "DeathTiles") as? SKTileMapNode else {
            print("setupDeathTilesPhysics: Fehler - DeathTiles ist nil")
            return
        }

        // Definiere eine Bedingung, um nur bestimmte Bereiche der DeathTiles zu berücksichtigen (z. B. die unteren Reihen)
        let rowsToConsider = 0..<deathTileMap.numberOfRows // Passe den Bereich an, falls nötig

        for row in rowsToConsider {
            for column in 0..<deathTileMap.numberOfColumns {
                if let tileDefinition = deathTileMap.tileDefinition(atColumn: column, row: row) {
                    // Prüfe, ob die Kachel eine DeathTile ist (falls sie eine bestimmte Bedingung erfüllen soll)
                    if let tileName = tileDefinition.userData?.value(forKey: "name") as? String, tileName == "death" {
                        let tileSize = deathTileMap.tileSize
                        let tilePosition = deathTileMap.centerOfTile(atColumn: column, row: row)

                        let path = CGMutablePath()
                        path.addRect(CGRect(x: -tileSize.width / 2, y: -tileSize.height / 2, width: tileSize.width, height: tileSize.height))

                        let physicsBody = SKPhysicsBody(polygonFrom: path)
                        physicsBody.isDynamic = false
                        physicsBody.categoryBitMask = CollisionCategory.grassTile // Verwende eine separate Kategorie, falls nötig
                        physicsBody.contactTestBitMask = CollisionCategory.panzer | CollisionCategory.enemyPanzer
                        physicsBody.collisionBitMask = CollisionCategory.panzer | CollisionCategory.enemyPanzer
                        physicsBody.affectedByGravity = false

                        let deathTileNode = SKShapeNode(path: path)
                        deathTileNode.position = tilePosition
                        deathTileNode.zPosition = -0.1
                        deathTileNode.fillColor = .clear
                        deathTileNode.strokeColor = .clear
                        deathTileNode.physicsBody = physicsBody

                        addChild(deathTileNode)
                        print("setupDeathTilesPhysics: DeathTile bei Position \(tilePosition) mit Physik hinzugefügt")
                    }
                }
            }
        }
    }
    // Zeige den nächsten Panzer, falls es noch Panzer gibt
    func showNextPanzer() {
        if currentPanzerIndex < selectedPanzers.count {
            let panzer = selectedPanzers[currentPanzerIndex] // Hole das Panzer-Objekt
            print("showNextPanzer: Zeige Panzer \(panzer.name ?? "") an") // Verwende den Namen des Panzer-Objekts, falls vorhanden
            
            // Stelle sicher, dass der Panzer noch keinen `parent` hat, bevor er hinzugefügt wird
            if panzer.parent == nil {
                panzer.size = CGSize(width: 70, height: 70) // Panzerskalierung auf eine kleinere Größe
                panzer.position = CGPoint(x: -50, y: -50) // Startposition in der Mitte
                panzer.zPosition = 0 // Über der Map
                addChild(panzer) // Füge den Panzer nur hinzu, wenn er keinen parent hat
                print("showNextPanzer: Panzer wurde hinzugefügt")
            } else {
                print("showNextPanzer: Panzer ist bereits in der Szene, kein erneutes Hinzufügen")
            }
            
            currentPanzer = panzer
            showArrowAboveCurrentPanzer()
        } else {
            // Wenn alle Panzer platziert sind, beginne das Spiel
            startGame()
        }
    }
    
    // When the tank moves, the arrow should move with it
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        
        if isMovingLeft {
            moveTankLeft()
        } else if isMovingRight {
            moveTankRight()
        }
        
        guard let currentPanzer = currentPanzer, let currentArrow = currentArrow else { return }
        
        // Calculate the new position of the arrow, slightly above the tank
        let arrowOffset: CGFloat = currentPanzer.size.height / 2 + 20 // Adjust this value for more or less space above the tank
        
        // Update the arrow's position to stay above the tank
        currentArrow.position = CGPoint(
            x: currentPanzer.position.x,
            y: currentPanzer.position.y + arrowOffset
        )
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let view = self.view else { return }
        let location = touch.location(in: self)
        let nodesAtLocation = nodes(at: location)
        
        for node in nodesAtLocation {
            if node.name == "leftButton" {
                isMovingLeft = false
            } else if node.name == "rightButton" {
                isMovingRight = false
            }
        }
        
        // Überprüfen, ob das Spiel bereits begonnen hat
        if gameStarted {
            
            // Überprüfen, ob der shootButton gedrückt wurde
            for node in nodesAtLocation {
                if node.name == "shootButton" {
                    // Schießen, wenn eine Waffe ausgewählt ist
                    if let currentWeapon = currentWeapon {
                        currentPanzer?.shootWeapon(named: currentWeapon.name, angle: aimAngle)
                    } else {
                        print("Bitte eine Waffe auswählen, bevor geschossen wird.")
                    }
                    return
                }
                
                // Überprüfen, ob der aktuelle Panzer angetippt wurde, um das Waffenmenü anzuzeigen
                if let panzer = node as? Panzer, panzer == currentPanzer {
                    panzer.showWeaponMenu(in: view) // Entfernen Sie `scene: self`
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
            panzer.physicsBody?.allowsRotation = false // Rotation deaktivieren, damit der Panzer aufrecht bleibt
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

        var placedEnemyCount = 0

        // Definiere die Begrenzungen für die Platzierung als CGFloat
           let xRange: ClosedRange<CGFloat> = -640.0...800.0  // Passe diese Werte basierend auf deinen Punkten an
           let yRange: ClosedRange<CGFloat> = -240.0...750.0      // Passe diese Werte basierend auf deinen Punkten an


        while placedEnemyCount < 4 {
            for enemyName in enemyPanzers {
                var placed = false
                var attempts = 0

                while !placed && attempts < 20 {
                    attempts += 1
                    let randomX = CGFloat.random(in: xRange)
                    let randomY = CGFloat.random(in: yRange)
                    let randomPosition = CGPoint(x: randomX, y: randomY)

                    let column = grassTileMap.tileColumnIndex(fromPosition: randomPosition)
                    let row = grassTileMap.tileRowIndex(fromPosition: randomPosition)

                    if let tileDefinition = grassTileMap.tileDefinition(atColumn: column, row: row),
                       let isSolid = tileDefinition.userData?.value(forKey: "solid") as? Bool, isSolid,
                       tileDefinition.userData?.value(forKey: "name") as? String != "death" {  // Vermeide DeathTiles
                        
                        let enemyPanzer = Panzer(imageNamed: enemyName, isEnemy: true)
                        enemyPanzer.size = CGSize(width: 70, height: 70)
                        enemyPanzer.position = grassTileMap.centerOfTile(atColumn: column, row: row)

                        enemyPanzer.physicsBody = SKPhysicsBody(rectangleOf: enemyPanzer.size)
                        enemyPanzer.physicsBody?.isDynamic = true
                        enemyPanzer.physicsBody?.allowsRotation = false

                        enemyPanzer.physicsBody?.categoryBitMask = CollisionCategory.enemyPanzer
                        enemyPanzer.physicsBody?.collisionBitMask = CollisionCategory.bullet | CollisionCategory.grassTile
                        enemyPanzer.physicsBody?.contactTestBitMask = CollisionCategory.bullet
                        enemyPanzer.physicsBody?.restitution = 0.0

                        enemyPanzer.name = enemyName
                        addChild(enemyPanzer)
                        print("placeEnemyPanzers: Feind-Panzer \(enemyName) an Position \(enemyPanzer.position) platziert")

                        let enemyAI = EnemyAI(enemyPanzer: enemyPanzer, scene: self)
                        enemyAIControllers.append(enemyAI)

                        placed = true
                        placedEnemyCount += 1
                    } else {
                        print("placeEnemyPanzers: Keine solide Kachel oder DeathTile bei Position \(randomPosition), neuer Versuch")
                    }
                }

                if placedEnemyCount >= 4 {
                    break
                }

                if !placed {
                    print("placeEnemyPanzers: Konnte keine passende Position für Feind-Panzer \(enemyName) finden")
                }
            }
        }

        print("placeEnemyPanzers: Alle 4 Feind-Panzer erfolgreich platziert.")
    
        startPlayerPlacement()
    }
    
    func startPlayerPlacement() {
        print("startPlayerPlacement: Beginn der Platzierung für Spielerpanzer")

        isPlacingPhase = true
        currentPanzerIndex = 0 // Start mit dem ersten Spielerpanzer
        showNextPanzer() // Zeigt den ersten Spielerpanzer zur Platzierung an
    }
    
    
    // Kollisionserkennung
    func didBegin(_ contact: SKPhysicsContact) {
        print("Kollision erkannt")

        let bodyA = contact.bodyA
        let bodyB = contact.bodyB

        // Bestimme die Bullet und das Ziel-Node
        let bulletNode = (bodyA.categoryBitMask == CollisionCategory.bullet ? bodyA.node : (bodyB.categoryBitMask == CollisionCategory.bullet ? bodyB.node : nil))
        let targetNode = (bulletNode == bodyA.node) ? bodyB.node : bodyA.node

        // Überprüfen, ob eine Bullet beteiligt ist und das Ziel vorhanden ist
        if let bulletNode = bulletNode, let targetNode = targetNode {
            
            // Überprüfe, ob das Ziel der Absender der Bullet ist, um Selbsttreffer zu vermeiden
            if let bulletOwner = bulletNode.userData?.value(forKey: "owner") as? Panzer, bulletOwner == targetNode as? Panzer {
                print("Panzer hat seine eigene Bullet getroffen – Kollision ignoriert.")
                return
            }

            // Entferne die Bullet sofort, um Mehrfachkollisionen zu vermeiden
            bulletNode.removeFromParent()
            
            // Überprüfen, ob das Ziel ein Panzer ist
            if let targetPanzer = targetNode as? Panzer,
               let damage = bulletNode.userData?.value(forKey: "damage") as? Int {
                print("Treffer auf Panzer erkannt. Schaden: \(damage)")

                // Wende den Schaden auf den Panzer an
                targetPanzer.applyDamage(damage)

                // Treffer-Effekte und Schimmer-Effekt zur Anzeige des Treffers
                targetPanzer.run(SKAction.playSoundFileNamed("bulletHit.wav", waitForCompletion: false))

                let shimmerEffect = SKAction.sequence([
                    SKAction.group([
                        SKAction.scale(to: 1.1, duration: 0.1),
                        SKAction.colorize(with: .yellow, colorBlendFactor: 0.5, duration: 0.1)
                    ]),
                    SKAction.wait(forDuration: 0.1),
                    SKAction.group([
                        SKAction.scale(to: 1.0, duration: 0.1),
                        SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.1)
                    ])
                ])
                targetPanzer.run(shimmerEffect)
            }
            
            // Treffer auf ein Gras-Tile
            else if targetNode.physicsBody?.categoryBitMask == CollisionCategory.grassTile {
                print("Treffer auf Gras-Tile erkannt")

                if let tileUserData = targetNode.userData,
                   tileUserData.value(forKey: "solid") as? Bool == true {
                    print("Gras-Tile mit `solid` markiert getroffen!")

                    // Position der Kollision für die Explosion ermitteln
                    let collisionPosition = targetNode.position
                    showExplosion(at: collisionPosition)
                    removeGrassTile(at: collisionPosition)
                } else {
                    print("Gras-Tile getroffen, aber nicht als `solid` markiert.")
                }
                // Check for game end after applying damage or destroying a tank
                gameManager?.checkGameEnd()
            }
            
            // Kollision mit einem DeathTile überprüfen
            else if let panzerNode = targetNode as? Panzer {
                if let tileUserData = (bodyA.node?.userData ?? bodyB.node?.userData),
                   tileUserData.value(forKey: "name") as? String == "death" {
                    print("Panzer \(panzerNode.name ?? "Unknown") hat ein DeathTile getroffen und wird zerstört.")

                    // Panzer zerstören und entfernen
                    panzerNode.removeFromParent()

                    if isPlacingPhase {
                        // Respawn-Logik für Platzierungsphase
                        respawnPanzer(panzerNode)
                    } else {
                        // Entferne Panzer aus den Listen und aktualisiere das Spiel
                        if panzerNode.isEnemy {
                            enemyPanzers.removeAll { $0 == panzerNode.name }
                        } else {
                            selectedPanzers.removeAll { $0 == panzerNode }
                        }
                        updatePanzerCountLabels()
                        gameManager?.checkGameEnd()
                    }
                }
            }
        }
    }
    // Explosion anzeigen
    func showExplosion(at position: CGPoint) {
        let explosion = SKSpriteNode(imageNamed: "tank_explosion2") // Nutze das Bild für die Explosion
        explosion.position = position
        explosion.zPosition = 10
        explosion.size = CGSize(width: 60, height: 60)
        addChild(explosion)
        
        // Entferne die Explosion nach kurzer Zeit
        let removeAction = SKAction.sequence([SKAction.wait(forDuration: 0.5), SKAction.removeFromParent()])
        explosion.run(removeAction)
        explosion.run(explosionSound) // Spiele den Explosionssound
    }
    
    func removeGrassTile(at position: CGPoint) {
        guard let grassTileMap = grassTileMap else { return }
        
        let column = grassTileMap.tileColumnIndex(fromPosition: position)
        let row = grassTileMap.tileRowIndex(fromPosition: position)
        
        // Entferne das Gras-Tile, falls es vorhanden ist
        if let tileDefinition = grassTileMap.tileDefinition(atColumn: column, row: row) {
            grassTileMap.setTileGroup(nil, forColumn: column, row: row)
            print("removeGrassTile: Gras-Tile an Position \(position) entfernt")
        } else {
            print("removeGrassTile: Kein Tile an Position \(position) gefunden oder Tile nicht `solid1`")
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

