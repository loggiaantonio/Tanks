import SwiftUI
import CoreData

struct FavoritesListView: View {
    @FetchRequest(
        entity: FavoriteJoke.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \FavoriteJoke.value, ascending: true)]
    ) var favoriteJokes: FetchedResults<FavoriteJoke>
    
    @Environment(\.managedObjectContext) private var viewContext
    
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
                    EditButton() // Ermöglicht dem Benutzer, die Liste zu bearbeiten (zum Beispiel um mehrere Einträge zu löschen)
                }
            }
        }
        .navigationTitle("Favorite Jokes")
    }
    
    // Funktion zum Löschen von Favoriten
    private func deleteFavorites(offsets: IndexSet) {
        withAnimation {
            offsets.map { favoriteJokes[$0] }.forEach(viewContext.delete) // Löschen der ausgewählten Favoriten
            
            do {
                try viewContext.save() // Änderungen in Core Data speichern
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

