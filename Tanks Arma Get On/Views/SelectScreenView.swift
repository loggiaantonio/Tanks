import SwiftUI

struct SelectScreenView: View {
    @State private var selectedPanzers: [String] = [] // Liste der ausgewählten Panzer
    @State private var animateTitle = false // Animation für den Titel
    @State private var showInfoAlert = false // State für das Anzeigen des Info-Dialogs

    let panzerOptions = [
        "tanks_tankGreen1", "tanks_tankGreen2", "tanks_tankGreen3", "tanks_tankGreen5",
        "tanks_tankDesert2", "tanks_tankDesert3", "tanks_tankDesert4", "tanks_tankDesert5"
    ]
    
    private let threeColumnGrid = [
        GridItem(.flexible(minimum: 40), spacing: -350),
        GridItem(.flexible(minimum: 40), spacing: -350),
        GridItem(.flexible(minimum: 40), spacing: -350)
    ]
    
    var body: some View {
        NavigationView{
            ZStack {
                // Hintergrundbild, das den Bildschirm füllt
                Image("militaryBg")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea() // Hintergrund ignoriert die Safe Area und füllt den ganzen Bildschirm
                
                GeometryReader { geometry in
                VStack {
                    
                    VStack {
                            // WOW-Effekt für den Titel "Choose 4 Tanks!"
                            Text("Choose 4 Tanks!")
                            .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(animateTitle ? .yellow : .white)
                                .scaleEffect(animateTitle ? 1.2 : 1.0)
                                .onAppear {
                                    withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                                        self.animateTitle = true
                                    }
                                }
                                .padding(.top, geometry.safeAreaInsets.top + 30) // Mehr Abstand zum oberen Rand
                            
                            // Flexibleres Grid mit 4 Spalten, wenn im Querformat mehr Platz ist
                            HStack {
                                LazyVGrid(columns: threeColumnGrid, alignment: .center, spacing: 5) {
                                    ForEach(panzerOptions, id: \.self) { panzer in
                                        Button(action: {
                                            togglePanzerSelection(panzer)
                                        }) {
                                            ZStack {
                                                // Militärischer Hintergrund für jeden Panzer (Grau und Grün)
                                                LinearGradient(gradient: Gradient(colors: [Color.gray, Color.black.opacity(0.7)]),
                                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                                                .frame(width: 70, height: 70)
                                                .cornerRadius(10)
                                                
                                                Image(panzer)
                                                    .resizable()
                                                    .frame(width: 60, height: 60)
                                                    .border(selectedPanzers.contains(panzer) ? Color.white : Color.clear, width: 2)
                                            }
                                        }
                                        .disabled(selectedPanzers.count >= 4 && !selectedPanzers.contains(panzer)) // Max 4 Panzer auswählbar
                                    }
                                    
                                    // Fragezeichen für Zufallsauswahl
                                    Button(action: {
                                        selectRandomPanzers()
                                    }) {
                                        ZStack {
                                            // Militärischer Hintergrund für das Fragezeichen
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
                            }
                            
                            // Button zum Bestätigen der Auswahl, wenn 4 Panzer gewählt wurden
                            if !selectedPanzers.isEmpty {
                                NavigationLink(destination: MapSelectScreenView(selectedPanzers: selectedPanzers)) {
                                    Text("Map Choice!")
                                        .font(.title)
                                        .padding()
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                        .frame(maxWidth: 200) // Feste Breite für den Button
                                }
                        
                            }
                        }
                    }
                }
                
                // Info-Button oben rechts, über allen anderen Elementen
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
            .alert(isPresented: $showInfoAlert) {
                Alert(title: Text("Information"), message: Text("Select up to 4 tanks to continue. You can also use the random selection"), dismissButton:
                        .default(Text("OK")))
                
            }
        }
    }

    func togglePanzerSelection(_ panzer: String) {
        if selectedPanzers.contains(panzer) {
            selectedPanzers.removeAll { $0 == panzer }
        } else if selectedPanzers.count < 4 {
            selectedPanzers.append(panzer)
        }
    }

    func selectRandomPanzers() {
        selectedPanzers.removeAll()
        let shuffledPanzers = panzerOptions.shuffled()
        selectedPanzers = Array(shuffledPanzers.prefix(4))
    }
}

struct SelectScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SelectScreenView()
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
