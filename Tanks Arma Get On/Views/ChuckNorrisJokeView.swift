import SwiftUI

struct ChuckNorrisJokeView: View {
    @ObservedObject var viewModel = ChuckNorrisViewModel()
    @State private var animateText = false // Für die Textanimation
    
    var body: some View {
        ZStack {
            // Hintergrundfarbe mit einem Farbverlauf, der sanft animiert wird
            LinearGradient(gradient: Gradient(colors: [Color.white, Color.black]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                if let joke = viewModel.joke {
                    // Zeigt das Icon, wenn eine URL vorhanden ist
                    if let iconURL = joke.icon_url, let url = URL(string: iconURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView() // Ladeanzeige, wenn das Bild noch geladen wird
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100) // Größe des Icons
                                    .cornerRadius(10)
                            case .failure:
                                Image(systemName: "xmark.circle") // Fallback, wenn das Bild nicht geladen werden kann
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
                    
                    // Einfacher Animationseffekt für den Witztext
                    Text(joke.value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .multilineTextAlignment(.center)
                        .scaleEffect(animateText ? 1.1 : 1.0) // Leichtes Vergrößern und Verkleinern
                        .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animateText)
                        .onAppear {
                            animateText = true // Startet die Animation beim Erscheinen
                        }
                } else {
                    // Einfache Ladeanzeige mit rotierenden Punkten
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5) // Vergrößert die Ladeanzeige
                        .padding()
                    Text("Loading joke...")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                }
            }
        }
        .onAppear {
            viewModel.fetchJoke()
        }
        .navigationTitle("Chuck Norris Jokes")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ChuckNorrisJokeView_Previews: PreviewProvider {
    static var previews: some View {
        ChuckNorrisJokeView()
    }
}
