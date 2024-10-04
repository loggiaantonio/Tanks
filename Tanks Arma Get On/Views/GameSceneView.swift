//
//  GameSceneView.swift
//  Tanks Arma Get On
//
//  Created by Antonio Loggia on 26.09.24.
//

import SwiftUI
import SpriteKit

// UIViewRepresentable zur Darstellung von SpriteKit-Szenen in SwiftUI
struct GameSceneView: UIViewRepresentable {
    @Binding var showWeaponMenu: Bool
    @Binding var selectedWeapon: Weapon?

    func makeUIView(context: Context) -> SKView {
        let skView = SKView()
        
        let scene = GameScene(size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)
        
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("ShowWeaponMenu"), object: nil, queue: .main) { _ in
            showWeaponMenu = true
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("HideWeaponMenu"), object: nil, queue: .main) { _ in
            showWeaponMenu = false
        }
        
        return skView
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        // Änderungen handhaben, falls notwendig
    }
}
