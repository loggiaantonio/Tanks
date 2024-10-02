import SwiftUI

struct ContentView: View {
    var body: some View {
       GameView(selectedPanzers: ["Panzer1", "Panzer2"], selectedMap: "Map1")
            .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    ContentView()
}

