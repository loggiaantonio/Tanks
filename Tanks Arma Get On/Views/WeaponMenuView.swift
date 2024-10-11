import SwiftUI

struct WeaponMenuView: View {
    let weapons: [Weapon]
    var onSelectWeapon: (Weapon) -> Void // Callback für die Waffenauswahl
    @State private var selectedWeapon: Weapon? // Markiert die ausgewählte Waffe

    var body: some View {
        VStack {
           

            // Horizontale ScrollView für Waffenanzeige
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) { // Abstand zwischen den Waffen
                    ForEach(weapons, id: \.name) { weapon in
                        VStack {
                            // Waffenbild
                            Image(weapon.image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30) // Kleinere Bildgröße
                                .padding()
                                .background(selectedWeapon == weapon ? Color.green : Color.gray.opacity(0.2)) // Hintergrundfarbe basierend auf der Auswahl
                                .cornerRadius(10)

                            // Munitionsanzeige
                            Text("x\(weapon.ammoCount)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .onTapGesture {
                            selectedWeapon = weapon
                            onSelectWeapon(weapon) // Callback bei Auswahl
                        }
                    }
                }
                .padding()
            }
        }
        .frame(height: 90) // Höhe des Menüs
        .background(Color.black.opacity(0.8))
        .cornerRadius(15)
        .padding()
    }
}

struct WeaponMenuView_Previews: PreviewProvider {
    static var previews: some View {
        WeaponMenuView(weapons: [
            Weapon(name: "Bullet1", image: "tank_bullet1", damage: 10, ammoCount: 10),
            Weapon(name: "Bullet2", image: "tank_bullet2", damage: 20, ammoCount: 8),
            Weapon(name: "Bullet3", image: "tank_bullet3", damage: 30, ammoCount: 6),
            Weapon(name: "Bullet4", image: "tank_bullet4", damage: 40, ammoCount: 4),
            Weapon(name: "Bullet5", image: "tank_bullet5", damage: 50, ammoCount: 2),
            Weapon(name: "Bullet6", image: "tank_bullet6", damage: 60, ammoCount: 1)
        ], onSelectWeapon: { _ in })
    }
}
