//
//  GameScene.swift
//  Tanks Arma Get On
//
//  Created by Antonio Loggia on 02.09.24.
//

import Foundation
import SpriteKit

class GameScene: SKScene {

    var tankTextures: [SKTexture] = []
    var tank: SKSpriteNode!

    override func didMove(to view: SKView) {
        backgroundColor = .blue
        
        // Spritesheet laden
       _ = SKTexture(imageNamed: "tanks_tankGreen2.png")
        if let path = Bundle.main.path(forResource: "tanks_tankGreen2", ofType: "png"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {

            // XML-Dokument parsen
            let parser = XMLParser(data: data)
            parser.delegate = self
            parser.parse()
            
            // Beispiel: Einen Tank aus dem Spritesheet anzeigen
            if let tankTexture = tankTextures.first {
                tank = SKSpriteNode(texture: tankTexture)
                tank.position = CGPoint(x: size.width / 2, y: size.height / 2)
                addChild(tank)
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Beispiel für Bewegung: Tank bewegt sich nach links oder rechts bei Berührung
        if let touch = touches.first {
            let location = touch.location(in: self)
            let moveAction: SKAction

            if location.x < size.width / 2 {
                moveAction = SKAction.moveBy(x: -50, y: 0, duration: 0.5)
            } else {
                moveAction = SKAction.moveBy(x: 50, y: 0, duration: 0.5)
            }

            tank.run(moveAction)
        }
    }
}

// MARK: - XMLParserDelegate
extension GameScene: XMLParserDelegate {

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        // Extrahiere die Sprite-Informationen aus dem XML
        if elementName == "SubTexture" {
            if let xString = attributeDict["x"],
               let yString = attributeDict["y"],
               let widthString = attributeDict["width"],
               let heightString = attributeDict["height"],
               let x = Double(xString),
               let y = Double(yString),
               let width = Double(widthString),
               let height = Double(heightString) {
                
                let textureRect = CGRect(
                    x: CGFloat(x) / 1024.0, // Normalisieren der Werte
                    y: CGFloat(y) / 1024.0,
                    width: CGFloat(width) / 1024.0,
                    height: CGFloat(height) / 1024.0
                )
                let texture = SKTexture(rect: textureRect, in: SKTexture(imageNamed: "tanks_spritesheetDefault.png"))
                tankTextures.append(texture)
            }
        }
    }
}
