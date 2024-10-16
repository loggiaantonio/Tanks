import SwiftUI

struct MapSelectScreenView: View {
    let selectedPanzers: [String]
    @State private var selectedMap: String = "Map1"
    let availableMaps = ["Map1", "Map2", "Map3", "Map4"]
    @State private var showInfoAlert = false
    @State private var animateTitle = false

    var body: some View {
        ZStack {
            // Hintergrundbild, das den Bildschirm füllt
            Image("militaryBg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            GeometryReader { geometry in
                VStack() {
                    // Titel oben anzeigen
                    Text("Map Choice!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(animateTitle ? .yellow : .white)
                        .scaleEffect(animateTitle ? 1.2 : 1.0)
                        .onAppear {
                            // Animation nur für den Titel "Map Choice!"
                            animateTitle = true
                        }
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animateTitle)
                        .padding(.top, geometry.safeAreaInsets.top + 30)

                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            ForEach(availableMaps, id: \.self) { map in
                                ZStack {
                                    if selectedMap == map {
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.yellow, lineWidth: 5)
                                            .frame(width: geometry.size.width / 2.5 - 20, height: geometry.size.height / 4 - 20)
                                            .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                                    }

                                    Button(action: {
                                        selectedMap = map
                                    }) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.black.opacity(0.5))
                                                .frame(width: geometry.size.width / 2.5 - 20, height: geometry.size.height / 4 - 20)

                                            Image(map)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: geometry.size.width / 2.6 - 20, height: geometry.size.height / 4.1 - 20)
                                                .cornerRadius(10)
                                                .padding(5) // Abstand zwischen Bild und Umrandung
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .animation(.easeInOut, value: selectedMap)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    if !selectedPanzers.isEmpty {
                       
                        NavigationLink(destination: GameView(selectedPanzers: selectedPanzers, selectedMap: selectedMap)) {
                            Text("Get Start")
                                .font(.title)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 3)
                        }
                        .padding(.bottom, 35)

                    }
                }
                .padding(.horizontal, 20)

                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            showInfoAlert.toggle()
                        }) {
                            Image(systemName: "info.circle")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                    Spacer()
                }
                .padding(.top, 40)
                .padding(.trailing, 20)
            }
        }
        .alert(isPresented: $showInfoAlert) {
            Alert(title: Text("Information"), message: Text("Select a map to start the game. Each map offers different challenges!"), dismissButton: .default(Text("OK")))
        }
    }
}

// Vorschau der MapSelectScreenView
struct MapSelectScreenView_Previews: PreviewProvider {
    static var previews: some View {
        MapSelectScreenView(selectedPanzers: ["Panzer1", "Panzer2"])
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
