//
//  BattleScene.swift
//  Tanks Arma Get On
//
//  Created by Antonio Loggia on 16.09.24.
//

/*import Foundation
import SpriteKit

class BattleScene: SKScene, SKPhysicsContactDelegate {
    var playerTank: SKSpriteNode!
    var enemyTank: SKSpriteNode!
    var background: SKSpriteNode!
    
    // Definieren von Kategorie-Bits
    let tankCategory: UInt32 = 0x1 << 0 // 1
    let terrainCategory: UInt32 = 0x1 << 1 // 2
    
    override func didMove(to view: SKView) {
        // Physik für die Szene aktivieren
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -9.8) // Schwerkraft für die Panzer
        self.physicsWorld.contactDelegate = self // Setze die Szene als Kontakt-Delegat
        
        // Terrain (Map) hinzufügen
        background = SKSpriteNode(imageNamed: "map1")
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.zPosition = -1
        background.size = self.size
        addChild(background)
        
        // Physikalischer Körper für das Terrain (statisch, bewegt sich nicht)
        background.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame) // Terrain ist ein Rand um die Szene
        background.physicsBody?.categoryBitMask = terrainCategory
        background.physicsBody?.collisionBitMask = tankCategory
        
        // Spielerpanzer hinzufügen
        playerTank = SKSpriteNode(imageNamed: "playerTank")
        playerTank.position = CGPoint(x: size.width * 0.2, y: size.height / 2)
        playerTank.zPosition = 1
        addChild(playerTank)
        
        // Physikalischer Körper für den Panzer
        playerTank.physicsBody = SKPhysicsBody(rectangleOf: playerTank.size)
        playerTank.physicsBody?.isDynamic = true // Dynamisch, kann sich bewegen
        playerTank.physicsBody?.affectedByGravity = true
        playerTank.physicsBody?.categoryBitMask = tankCategory
        playerTank.physicsBody?.collisionBitMask = terrainCategory
        playerTank.physicsBody?.contactTestBitMask = terrainCategory
        
        // Gegnerpanzer hinzufügen
        enemyTank = SKSpriteNode(imageNamed: "enemyTank")
        enemyTank.position = CGPoint(x: size.width * 0.8, y: size.height / 2)
        enemyTank.zPosition = 1
        addChild(enemyTank)
        
        // Physikalischer Körper für den Gegnerpanzer
        enemyTank.physicsBody = SKPhysicsBody(rectangleOf: enemyTank.size)
        enemyTank.physicsBody?.isDynamic = true
        enemyTank.physicsBody?.affectedByGravity = true
        enemyTank.physicsBody?.categoryBitMask = tankCategory
        enemyTank.physicsBody?.collisionBitMask = terrainCategory
        enemyTank.physicsBody?.contactTestBitMask = terrainCategory
    }
    
    // Kontakt zwischen Objekten erkennen
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        if collision == tankCategory | terrainCategory {
            print("Panzer hat das Terrain berührt!")
            // Hier kannst du die Logik hinzufügen, was passiert, wenn der Panzer das Terrain berührt
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Bewegung des Spielerpanzers
        let moveAction = SKAction.move(to: location, duration: 1.0)
        playerTank.run(moveAction)
    }
}*/
