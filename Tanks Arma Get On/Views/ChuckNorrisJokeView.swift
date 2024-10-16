import SwiftUI

struct ChuckNorrisJokeView: View {
    @ObservedObject var viewModel = ChuckNorrisViewModel()
    @State private var animateText = false
    @State private var backgroundColor = Color.white
    @Environment(\.managedObjectContext) private var viewContext // Core Data Kontext
    @State private var showToast = false // Toast-Status
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [backgroundColor, Color.black]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                if let joke = viewModel.joke {
                    if let iconURL = joke.icon_url, let url = URL(string: iconURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .cornerRadius(10)
                            case .failure:
                                Image(systemName: "xmark.circle")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.red)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .padding()
                    }
                    
                    // Witz, Favoriten-Stern und Neu laden Symbol
                    VStack {
                        Text(joke.value)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .multilineTextAlignment(.center)
                            .scaleEffect(animateText ? 1.1 : 1.0)
                            .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animateText)
                            .onAppear {
                                animateText = true
                            }
                        
                        HStack {
                            // Button zum Favorisieren des Witzes
                            Button(action: {
                                addFavorite(joke: joke) // Favorisieren des Witzes
                            }) {
                                Image(systemName: "star.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.yellow)
                            }
                            .padding()
                            
                            // Button zum Neuladen des Witzes
                            Button(action: {
                                viewModel.fetchJoke() // Neuen Witz abrufen
                            }) {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.blue)
                            }
                            .padding()
                        }
                    }
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                        .padding()
                    Text("Loading joke...")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                }
            }
            
            // Toast-Benachrichtigung
            if showToast {
                VStack {
                    Spacer()
                    Text("Joke saved to favorites!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                        .padding(.bottom, 50)
                }
                .transition(.slide)
                .animation(.easeInOut)
            }
        }
        .onAppear {
            viewModel.fetchJoke()
        }
        .navigationTitle("Chuck Norris Jokes")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Funktion, um Witze zu favorisieren und in Core Data zu speichern
    private func addFavorite(joke: ChuckNorrisJoke) {
        let newFavorite = FavoriteJoke(context: viewContext)
        newFavorite.id = joke.id
        newFavorite.value = joke.value
        newFavorite.iconURL = joke.icon_url
        
        do {
            try viewContext.save()
            showToastMessage() // Zeige Toast nach dem Speichern
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    // Funktion zum Anzeigen der Toast-Nachricht
    private func showToastMessage() {
        showToast = true
        
        // Toast nach 2 Sekunden wieder ausblenden
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showToast = false
            }
        }
    }
}

struct ChuckNorrisJokeView_Previews: PreviewProvider {
    static var previews: some View {
        ChuckNorrisJokeView()
    }
}
