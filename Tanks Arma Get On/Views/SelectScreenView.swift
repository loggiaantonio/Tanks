import SwiftUI

struct SelectScreenView: View {
    @State private var selectedPanzers: [String] = [] // Liste der ausgewählten Panzer
    @State private var animateTitle = false // Animation für den Titel
    @State private var showInfoAlert = false // State für das Anzeigen des Info-Dialogs

    let panzerOptions = [
        "tanks_tankGreen1", "tanks_tankGreen2", "tanks_tankGreen3", "tanks_tankGreen5",
        "tanks_tankDesert2", "tanks_tankDesert3", "tanks_tankDesert4", "tanks_tankDesert5"
    ]
    
    // Engeres Grid mit kleineren Abständen
    private let threeColumnGrid = [
        GridItem(.flexible(minimum: 40), spacing: 10), // Abstand zwischen den Spalten reduziert
        GridItem(.flexible(minimum: 40), spacing: 10),
        GridItem(.flexible(minimum: 40), spacing: 10)
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
                    VStack(spacing: 10) {
                        
                        // WOW-Effekt für den Titel "Choose 4 Tanks!"
                        Text("Choose 4 Tanks!")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(animateTitle ? .yellow : .white)
                            .scaleEffect(animateTitle ? 1.2 : 1.0)
                            .onAppear {   // Animation nur für den Titel "Map Choice!"
                                animateTitle = true
                            }
                                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animateTitle)
                            .padding(.top, geometry.safeAreaInsets.top + 30) // Abstand zum oberen Rand vergrößert
                        
                        Spacer() // Fügt etwas Platz zwischen dem Text und den Panzern hinzu
                        
                        // Flexibleres Grid mit 3 Spalten
                        LazyVGrid(columns: threeColumnGrid, alignment: .center, spacing: 15) { // Spacing zwischen den Panzern
                            ForEach(panzerOptions, id: \.self) { panzer in
                                Button(action: {
                                    togglePanzerSelection(panzer)
                                }) {
                                    ZStack {
                                        // Militärischer Hintergrund für jeden Panzer (Grau und Grün)
                                        LinearGradient(gradient: Gradient(colors: [Color.gray, Color.black.opacity(0.7)]),
                                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                                            .frame(width: 70, height: 70) // Kleinere Größe für mehr Platz
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
                                        .frame(width: 70, height: 70) // Kleinere Größe für mehr Platz
                                        .cornerRadius(10)
                                    
                                    Image(systemName: "questionmark")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        
                        Spacer() // Fügt einen klaren Abstand zwischen den Panzern und dem Button ein
                        
                        // Button zum Bestätigen der Auswahl, wenn 4 Panzer gewählt wurden
                        if selectedPanzers.count == 4 { // Button nur anzeigen, wenn 4 Panzer gewählt sind
                            NavigationLink(destination: MapSelectScreenView(selectedPanzers: selectedPanzers)) {
                                Text("Map Choice!")
                                    .font(.title)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .frame(maxWidth: 200) // Feste Breite für den Button
                            }
                            .padding(.bottom, 40) // Abstand nach unten
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
                .padding(.trailing, 0)
            }
            .alert(isPresented: $showInfoAlert) {
                Alert(title: Text("Information"), message: Text("Select up to 4 tanks to continue. You can also use the random selection"), dismissButton:
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
}

struct SelectScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SelectScreenView()
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
