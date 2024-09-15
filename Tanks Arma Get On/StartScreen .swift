import SwiftUI

struct StartView: View {
    var body: some View {
        ZStack {
            // Hintergrundbild
            Image("background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea() // Ignoriert den Safe Area für das Hintergrundbild
            
            // Halbtransparente schwarze Ebene, um den Hintergrund abzudunkeln
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            // Information Button oben rechts
            Button(action: {
                print("Information button pressed")
            }) {
                Image("information button")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 400, height: 400)
            }
            .position(x: UIScreen.main.bounds.width - 50, y: 70) // Manuelle Positionierung oben rechts
            
            // Logo, Play Button und Quit Button manuell positioniert
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(height: 250)
                .position(x: UIScreen.main.bounds.width / 2, y: 400) // Logo in der Mitte des Bildschirms

            Button(action: {
                print("Play button pressed")
            }) {
                Image("play button")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 800)
                    .ignoresSafeArea()
            }
            .position(x: UIScreen.main.bounds.width / 2, y: 600) // Play Button manuell positioniert

            Button(action: {
                print("Quit button pressed")
            }) {
                Image("quit button")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .ignoresSafeArea()
            }
            .position(x: UIScreen.main.bounds.width / 2, y: 750) // Quit Button manuell positioniert
        }
    }
}

#Preview {
    StartView()
}
