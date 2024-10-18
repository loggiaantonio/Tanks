import SwiftUI

struct ChuckNorrisJokeView: View {
    @ObservedObject var viewModel = ChuckNorrisViewModel()
    @State private var animateText = false
    @State private var backgroundColor = Color.white
    @Environment(\.managedObjectContext) private var viewContext // Core Data context
    @Environment(\.presentationMode) var presentationMode // Presentation mode for dismissing the view
    @State private var showToast = false // Toast status
    
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
                    
                    // Joke, favorite star, and reload icon
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
                            // Button to add the joke to favorites
                            Button(action: {
                                addFavorite(joke: joke) // Add joke to favorites
                            }) {
                                Image("Star")
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.yellow)
                            }
                            .padding()
                            
                            // Button to fetch a new joke
                            Button(action: {
                                viewModel.fetchJoke() // Fetch new joke
                            }) {
                                Image("Reload")
                                    .resizable()
                                    .frame(width: 60, height: 60)
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
            
            // Toast notification
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
        .navigationBarBackButtonHidden(true) // Hide the default back button
        .navigationBarItems(leading: Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                    .foregroundColor(.blue)
                Text("Back")
                    .foregroundColor(.blue)
            }
        })
    }
    
    // Function to add jokes to favorites and save to Core Data
    private func addFavorite(joke: ChuckNorrisJoke) {
        let newFavorite = FavoriteJoke(context: viewContext)
        newFavorite.id = joke.id
        newFavorite.value = joke.value
        newFavorite.iconURL = joke.icon_url
        
        do {
            try viewContext.save()
            showToastMessage() // Show toast after saving
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    // Function to show toast message
    private func showToastMessage() {
        showToast = true
        
        // Hide toast after 2 seconds
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
