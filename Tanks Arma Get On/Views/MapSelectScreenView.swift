import SwiftUI
import AVFoundation

struct MapSelectScreenView: View {
    let selectedPanzers: [String]
    @State private var selectedMap: String = "Map1"
    let availableMaps = ["Map1", "Map2", "Map3", "Map4"]
    @State private var showInfoAlert = false
    @State private var animateTitle = false
    @State private var audioPlayer: AVAudioPlayer? // AudioPlayer als State-Variable speichern
    @Environment(\.presentationMode) var presentationMode // For dismissing the view
    
    var body: some View {
        ZStack {
            // Background image that fills the screen
            Image("militaryBg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            GeometryReader { geometry in
                VStack {
                    // Display title at the top
                    Text("Map Choice!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(animateTitle ? .yellow : .white)
                        .scaleEffect(animateTitle ? 1.2 : 1.0)
                        .onAppear {
                            // Animation for the "Map Choice!" title
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
                                        playClickSound() // Sound abspielen
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
                                                .padding(5) // Padding between image and border
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
                        NavigationLink(destination: GameView(selectedPanzers: selectedPanzers, selectedMap: selectedMap)
                                        .navigationBarBackButtonHidden(true)) { // Hide the back button for GameView
                            Text("Get Start")
                                .font(.title)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 3)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            playClickSound() // Sound abspielen
                        })
                        .padding(.bottom, 35)
                    }
                }
                .padding(.horizontal, 20)

                VStack {
                    HStack {
                        // Custom back button
                        Button(action: {
                            self.presentationMode.wrappedValue.dismiss()
                            playClickSound() // Sound abspielen
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.blue)
                                Text("Back")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.leading, 20)
                        .padding(.top, 10)
                        Spacer()
                        
                        Button(action: {
                            showInfoAlert.toggle()
                            playClickSound() // Sound abspielen
                        }) {
                            Image("Info")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                    Spacer()
                }
                .padding(.top, 20) // Adjust this value to move the entire row higher
            }
        }
        .alert(isPresented: $showInfoAlert) {
            Alert(title: Text("Information"), message: Text("Select a map to start the game. Each map offers different challenges!"), dismissButton: .default(Text("OK")))
        }
        .navigationBarBackButtonHidden(true) // Hide default back button
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func playClickSound() {
        guard let url = Bundle.main.url(forResource: "Click", withExtension: "mp3") else {
            print("Error: Sound file not found.")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = 0.2 // Lautstärke auf 20% gesetzt

            audioPlayer?.play()
        } catch {
            print("Error: Could not play sound file.")
        }
    }
}

// Preview for MapSelectScreenView
struct MapSelectScreenView_Previews: PreviewProvider {
    static var previews: some View {
        MapSelectScreenView(selectedPanzers: ["Panzer1", "Panzer2"])
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
