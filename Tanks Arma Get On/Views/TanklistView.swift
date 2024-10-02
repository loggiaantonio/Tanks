import SwiftUI

struct TankListView: View {
    @ObservedObject var viewModel = TankViewModel()

    @State private var animateTitle = false // Für die Animation des Titels

    var body: some View {
        NavigationView {
            ZStack {
                // Hintergrund mit Farbverlauf
                LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.black]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                // Liste der Panzer
                List(viewModel.tanks) { tank in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            // Bild des Panzers
                            if let imageUrl = tank.image, let url = URL(string: imageUrl) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(10)
                                        .shadow(radius: 5)
                                } placeholder: {
                                    Color.gray
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(10)
                                }
                            }

                            // Name, Kategorie und Waffe
                            VStack(alignment: .leading) {
                                Text(tank.name)
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(.white)

                                if let category = tank.category {
                                    Text("Kategorie: \(category)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }

                                if let weapon = tank.weapon {
                                    Text("Waffe: \(weapon)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.black.opacity(0.8))
                                .shadow(radius: 10)
                        )
                    }
                    .padding(.vertical, 8)
                }
                .onAppear {
                    viewModel.fetchTanks()
                }
                .listStyle(InsetGroupedListStyle())
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        // Animierter Titel in der Mitte
                        Text("Informationen")
                            .font(.largeTitle)
                            .bold()
                            .scaleEffect(animateTitle ? 1.2 : 1)
                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animateTitle) // Hier ist die Animation korrekt
                            .onAppear {
                                animateTitle = true
                            }
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

#Preview {
    TankListView()
}
