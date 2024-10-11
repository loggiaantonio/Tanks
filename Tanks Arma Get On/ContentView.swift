import SwiftUI

struct ContentView: View {
    @State private var showWeaponMenu = false
    @State private var selectedWeapon: Weapon?

    var body: some View {
        ZStack {
            GameSceneView(showWeaponMenu: $showWeaponMenu, selectedWeapon: $selectedWeapon)
                .edgesIgnoringSafeArea(.all)
            
            if showWeaponMenu {
                WeaponMenuView(weapons: [
                    Weapon(name: "Bullet1", image: "tank_bullet1", damage: 10, ammoCount: 10),
                    Weapon(name: "Bullet2", image: "tank_bullet2", damage: 20, ammoCount: 8),
                    Weapon(name: "Bullet3", image: "tank_bullet3", damage: 30, ammoCount: 6),
                    Weapon(name: "Bullet4", image: "tank_bullet4", damage: 40, ammoCount: 4),
                    Weapon(name: "Bullet5", image: "tank_bullet5", damage: 50, ammoCount: 2),
                    Weapon(name: "Bullet6", image: "tank_bullet6", damage: 60, ammoCount: 1)
                ], onSelectWeapon: { weapon in
                    selectedWeapon = weapon
                    NotificationCenter.default.post(name: NSNotification.Name("HideWeaponMenu"), object: nil)
                    print("Selected Weapon: \(weapon.name)")
                    print("Displaying WeaponMenuView") // Debug-Ausgabe
                })
                .transition(.move(edge: .bottom))
            }
        }
    }
}

#Preview {
    ContentView()
}

