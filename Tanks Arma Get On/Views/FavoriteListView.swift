import SwiftUI
import CoreData

struct FavoritesListView: View {
    @FetchRequest(
        entity: FavoriteJoke.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \FavoriteJoke.value, ascending: true)]
    ) var favoriteJokes: FetchedResults<FavoriteJoke>
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            if favoriteJokes.isEmpty {
                Text("No favorite jokes yet.")
                    .font(.title)
                    .padding()
            } else {
                List {
                    ForEach(favoriteJokes) { favorite in
                        HStack {
                            if let iconURL = favorite.iconURL, let url = URL(string: iconURL) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 50, height: 50)
                                            .cornerRadius(10)
                                    case .failure:
                                        Image(systemName: "xmark.circle")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 50, height: 50)
                                            .foregroundColor(.red)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                            
                            Text(favorite.value ?? "Unknown Joke")
                                .font(.headline)
                        }
                    }
                    .onDelete(perform: deleteFavorites) // Swipe-to-Delete
                }
                .toolbar {
                    EditButton() // Allows the user to edit the list
                }
            }
        }
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.black]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
            .edgesIgnoringSafeArea(.all)
        )
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
        .navigationTitle("Favorite Jokes")
    }
    
    // Function to delete favorites
    private func deleteFavorites(offsets: IndexSet) {
        withAnimation {
            offsets.map { favoriteJokes[$0] }.forEach(viewContext.delete) // Delete selected favorites
            
            do {
                try viewContext.save() // Save changes to Core Data
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
