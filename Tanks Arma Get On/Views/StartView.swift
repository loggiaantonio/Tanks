import SwiftUI
import AVFoundation

struct StartView: View {
    @State private var audioPlayer: AVAudioPlayer?

    var body: some View {
        NavigationView {
            ZStack {
                Image("background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                Color.black.opacity(0.5)
                    .ignoresSafeArea()

                // NavigationLink für den Information-Button zur TankListView
                NavigationLink(destination: TankListView()) {
                    Image("information button")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 400, height: 400)
                }
                .position(x: UIScreen.main.bounds.width - 50, y: 70)

                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 250)
                    .position(x: UIScreen.main.bounds.width / 2, y: 400)

                NavigationLink(destination: SelectScreenView()) {
                    Image("play button")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 650, height: 500)
                        .ignoresSafeArea()
                }
                .position(x: UIScreen.main.bounds.width / 2.1, y: 650)
            }
        }
        .onAppear {
            playBackgroundMusic()
        }
    }

    func playBackgroundMusic() {
        if let path = Bundle.main.path(forResource: "startScreen", ofType: "mp3") {
            let url = URL(fileURLWithPath: path)

            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.numberOfLoops = -1
                audioPlayer?.volume = 0.02
                audioPlayer?.play()
            } catch {
                print("Fehler beim Laden und Abspielen der Musik: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    StartView()
}
