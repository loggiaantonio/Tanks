import SwiftUI

struct WeaponMenuView: View {
    let weapons: [Weapon]
    var onSelectWeapon: (Weapon) -> Void // Callback für die Waffenauswahl
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack {
            Text("Choose Your Weapon")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(weapons, id: \.name) { weapon in
                    VStack {
                        Image(weapon.image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .padding()
                        
                        Text("x\(weapon.ammoCount)")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .onTapGesture {
                        onSelectWeapon(weapon)
                    }
                }
            }
            .padding()
        }
        .background(Color.black.opacity(0.8))
        .cornerRadius(15)
        .padding()
    }
}

struct WeaponMenuView_Previews: PreviewProvider {
    static var previews: some View {
        WeaponMenuView(weapons: [
            Weapon(name: "Bullet1", image: "tank_bullet1", damage: 10, ammoCount: 10),
            Weapon(name: "Bullet2", image: "tank_bullet2", damage: 20, ammoCount: 8)
        ], onSelectWeapon: { _ in })
    }
}
