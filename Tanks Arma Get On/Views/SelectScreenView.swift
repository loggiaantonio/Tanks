import SwiftUI
import AVFoundation

struct SelectScreenView: View {
    @State private var selectedPanzers: [String] = []
    @State private var animateTitle = false
    @State private var showInfoAlert = false
    @State private var audioPlayer: AVAudioPlayer? // AudioPlayer als State-Variable speichern
    
    let panzerOptions = [
        "tanks_tankGreen1", "tanks_tankGreen2", "tanks_tankGreen3", "tanks_tankGreen5",
        "tanks_tankDesert2", "tanks_tankDesert3", "tanks_tankDesert4", "tanks_tankDesert5"
    ]
    
    private let threeColumnGrid = [
        GridItem(.flexible(minimum: 40), spacing: 10),
        GridItem(.flexible(minimum: 40), spacing: 10),
        GridItem(.flexible(minimum: 40), spacing: 10)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Image("militaryBg")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                GeometryReader { geometry in
                    VStack(spacing: 10) {
                        
                        Text("Choose 4 Tanks!")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(animateTitle ? .yellow : .white)
                            .scaleEffect(animateTitle ? 1.2 : 1.0)
                            .onAppear {
                                animateTitle = true
                            }
                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animateTitle)
                            .padding(.top, geometry.safeAreaInsets.top + 30)
                        
                        Spacer()
                        
                        LazyVGrid(columns: threeColumnGrid, alignment: .center, spacing: 15) {
                            ForEach(panzerOptions, id: \.self) { panzer in
                                Button(action: {
                                    togglePanzerSelection(panzer)
                                    playClickSound() // Sound abspielen
                                }) {
                                    ZStack {
                                        LinearGradient(gradient: Gradient(colors: [Color.gray, Color.black.opacity(0.7)]),
                                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                                        .frame(width: 70, height: 70)
                                        .cornerRadius(10)
                                        .scaleEffect(selectedPanzers.contains(panzer) ? 1.1 : 1.0)
                                        .animation(.easeInOut(duration: 0.2), value: selectedPanzers.contains(panzer))
                                        
                                        Image(panzer)
                                            .resizable()
                                            .frame(width: 60, height: 60)
                                            .border(selectedPanzers.contains(panzer) ? Color.white : Color.clear, width: 2)
                                            .animation(.easeInOut(duration: 0.2), value: selectedPanzers.contains(panzer))
                                    }
                                }
                                .disabled(selectedPanzers.count >= 4 && !selectedPanzers.contains(panzer))
                            }
                            
                            Button(action: {
                                selectRandomPanzers()
                                playClickSound() // Sound abspielen
                            }) {
                                ZStack {
                                    LinearGradient(gradient: Gradient(colors: [Color.gray, Color.black.opacity(0.7)]),
                                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                                    .frame(width: 70, height: 70)
                                    .cornerRadius(10)
                                    
                                    Image(systemName: "questionmark")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        if selectedPanzers.count == 4 {
                            NavigationLink(destination: MapSelectScreenView(selectedPanzers: selectedPanzers)) {
                                Text("Map Choice!")
                                    .font(.title)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .frame(maxWidth: 200)
                            }
                            .simultaneousGesture(TapGesture().onEnded {
                                playClickSound() // Sound abspielen
                            })
                            .padding(.bottom, 40)
                        }
                    }
                }
                
                VStack {
                    HStack {
                        VStack {
                            NavigationLink(destination: ChuckNorrisJokeView()) {
                                Image("ChuckNorris")
                                    .resizable()
                                    .frame(width: 90, height: 70)
                                    .cornerRadius(10)
                                    .padding()
                            }
                            .simultaneousGesture(TapGesture().onEnded {
                                playClickSound2() // Sound abspielen
                            })
                            
                            NavigationLink(destination: FavoritesListView()) {
                                Image("Star")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.yellow)
                                    .padding(.bottom, 20)
                            }
                            .simultaneousGesture(TapGesture().onEnded {
                                playClickSound() // Sound abspielen
                            })
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.top, 40)
                .padding(.leading, -30)
                
                VStack {
                    HStack {
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
                .padding(.top, 40)
                .padding(.trailing, 0)
            }
            .alert(isPresented: $showInfoAlert) {
                Alert(title: Text("Information"), message: Text("Select up to 4 tanks to continue. You can also use the random selection. If you click on the Chuck Norris icon, you will see jokes every time and the star icon will contain your favorite Chuck Norris jokes!."), dismissButton:
                        .default(Text("OK")))
                
            }
        }
    }
    
    func togglePanzerSelection(_ panzer: String) {
        withAnimation(.easeInOut) {
            if selectedPanzers.contains(panzer) {
                selectedPanzers.removeAll { $0 == panzer }
            } else if selectedPanzers.count < 4 {
                selectedPanzers.append(panzer)
            }
        }
    }
    
    func selectRandomPanzers() {
        withAnimation(.easeInOut) {
            selectedPanzers.removeAll()
            let shuffledPanzers = panzerOptions.shuffled()
            selectedPanzers = Array(shuffledPanzers.prefix(4))
        }
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
    
    
    func playClickSound2() {
        guard let url = Bundle.main.url(forResource: "chuck-norris_1", withExtension: "mp3") else {
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

struct SelectScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SelectScreenView()
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
